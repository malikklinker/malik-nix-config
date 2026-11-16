"""Private stdin/stdout bridge for enterprise Wi-Fi and interactive BlueZ pairing."""

import getpass
import json
from pathlib import Path
import re
import sys
import threading
import uuid

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BLUEZ = "org.bluez"
NM = "org.freedesktop.NetworkManager"
AGENT = "/org/desktop/PairingAgent"


def emit(**message):
    print(json.dumps(message), flush=True)


def enterprise_settings(data):
    """Validate before making any changes; never allow unverified enterprise TLS."""
    for key in ("ssid", "identity", "domain", "ca", "password"):
        if not isinstance(data.get(key), str) or not data[key].strip():
            raise ValueError(f"{key} is required")
    if len(data["ssid"].encode()) > 32:
        raise ValueError("SSID is too long")
    if not re.fullmatch(r"[A-Za-z0-9.-]+", data["domain"]) or "." not in data["domain"]:
        raise ValueError(
            "Enter the authentication server domain supplied by your institution"
        )
    ca = Path(data["ca"]).expanduser().resolve(strict=True)
    if not ca.is_file():
        raise ValueError("CA certificate must be a file")
    eap, phase2 = data.get("eap"), data.get("phase2")
    if eap not in ("peap", "ttls") or phase2 not in (
        ("mschapv2",) if eap == "peap" else ("pap", "mschapv2", "mschap", "chap")
    ):
        raise ValueError("Unsupported EAP or inner authentication method")
    return {
        "connection": {
            "id": f"{data['ssid']} (panel)",
            "uuid": str(uuid.uuid4()),
            "type": "802-11-wireless",
            "permissions": dbus.Array([f"user:{getpass.getuser()}:"], signature="s"),
            "autoconnect": True,
        },
        "802-11-wireless": {
            "ssid": dbus.ByteArray(data["ssid"].encode()),
            "mode": "infrastructure",
        },
        "802-11-wireless-security": {"key-mgmt": "wpa-eap"},
        "802-1x": {
            "eap": dbus.Array([eap], signature="s"),
            "identity": data["identity"],
            "anonymous-identity": data.get("anonymous", ""),
            "password": data["password"],
            "password-flags": dbus.UInt32(0),
            "phase2-auth": phase2,
            "domain-suffix-match": data["domain"],
            "ca-cert": dbus.ByteArray((ca.as_uri() + "\0").encode()),
        },
        "ipv4": {"method": "auto"},
        "ipv6": {"method": "auto"},
    }


def enterprise(data):
    settings = enterprise_settings(data)
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object(NM, "/org/freedesktop/NetworkManager"), NM)
    devices = []
    for path in manager.GetDevices():
        props = dbus.Interface(
            bus.get_object(NM, path), "org.freedesktop.DBus.Properties"
        )
        if props.Get(NM + ".Device", "DeviceType") == 2:
            devices.append((path, str(props.Get(NM + ".Device", "Interface"))))
    if not devices:
        raise ValueError("No Wi-Fi adapter is available")
    device = next(
        (path for path, name in devices if name == data.get("device")), devices[0][0]
    )
    store = dbus.Interface(
        bus.get_object(NM, "/org/freedesktop/NetworkManager/Settings"), NM + ".Settings"
    )
    for path in store.ListConnections():
        profile = dbus.Interface(bus.get_object(NM, path), NM + ".Settings.Connection")
        existing = profile.GetSettings()
        connection = existing.get("connection", {})
        if connection.get("id") == settings["connection"]["id"] and list(
            connection.get("permissions", [])
        ) == list(settings["connection"]["permissions"]):
            settings["connection"]["uuid"] = connection["uuid"]
            profile.Update(settings)
            manager.ActivateConnection(path, device, "/", timeout=30)
            return
    manager.AddAndActivateConnection(settings, device, "/", timeout=30)


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


class Agent(dbus.service.Object):
    def __init__(self, bus, device):
        super().__init__(bus, AGENT)
        self.device = device
        self.pending = None

    def prompt(self, kind, success, failure, **details):
        if self.pending:
            self.pending[2](Rejected("Superseded pairing request"))
        self.pending = (kind, success, failure)
        emit(type=kind, **details)

    def respond(self, response):
        if not self.pending:
            return False
        kind, success, failure = self.pending
        self.pending = None
        value = response.get("value", "")
        if not response.get("accept"):
            failure(Rejected("Pairing declined"))
        elif kind == "pin" and isinstance(value, str) and 1 <= len(value) <= 16:
            success(value)
        elif kind == "passkey" and re.fullmatch(r"[0-9]{1,6}", str(value)):
            success(dbus.UInt32(int(value)))
        elif kind in ("confirm", "authorize"):
            success()
        else:
            failure(Rejected("Invalid PIN or passkey"))
        return False

    @dbus.service.method(
        BLUEZ + ".Agent1",
        in_signature="o",
        out_signature="s",
        async_callbacks=("success", "failure"),
    )
    def RequestPinCode(self, device, success, failure):
        self.prompt("pin", success, failure)

    @dbus.service.method(
        BLUEZ + ".Agent1",
        in_signature="o",
        out_signature="u",
        async_callbacks=("success", "failure"),
    )
    def RequestPasskey(self, device, success, failure):
        self.prompt("passkey", success, failure)

    @dbus.service.method(
        BLUEZ + ".Agent1",
        in_signature="ou",
        out_signature="",
        async_callbacks=("success", "failure"),
    )
    def RequestConfirmation(self, device, passkey, success, failure):
        self.prompt("confirm", success, failure, code=f"{passkey:06d}")

    @dbus.service.method(
        BLUEZ + ".Agent1",
        in_signature="o",
        out_signature="",
        async_callbacks=("success", "failure"),
    )
    def RequestAuthorization(self, device, success, failure):
        self.prompt("authorize", success, failure)

    @dbus.service.method(
        BLUEZ + ".Agent1",
        in_signature="os",
        out_signature="",
        async_callbacks=("success", "failure"),
    )
    def AuthorizeService(self, device, service, success, failure):
        self.prompt("authorize", success, failure, service=service)

    @dbus.service.method(BLUEZ + ".Agent1", in_signature="os", out_signature="")
    def DisplayPinCode(self, device, code):
        emit(type="display", code=str(code))

    @dbus.service.method(BLUEZ + ".Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, code, entered):
        emit(type="display", code=f"{code:06d}", entered=int(entered))

    @dbus.service.method(BLUEZ + ".Agent1", in_signature="", out_signature="")
    def Cancel(self):
        self.respond({"accept": False})
        emit(type="cancel")

    @dbus.service.method(BLUEZ + ".Agent1", in_signature="", out_signature="")
    def Release(self):
        self.Cancel()


def bluetooth(verb, path):
    if not re.fullmatch(r"/org/bluez/hci[0-9]+/dev_[0-9A-Fa-f_]+", path):
        raise ValueError("Invalid Bluetooth device")
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    device = dbus.Interface(bus.get_object(BLUEZ, path), BLUEZ + ".Device1")
    if verb != "pair":
        if verb == "connect":
            device.Connect(timeout=45)
        elif verb == "disconnect":
            device.Disconnect(timeout=20)
        elif verb == "forget":
            adapter = dbus.Interface(
                bus.get_object(BLUEZ, path.rsplit("/", 1)[0]), BLUEZ + ".Adapter1"
            )
            adapter.RemoveDevice(path)
        else:
            raise ValueError("Unsupported Bluetooth action")
        return
    loop = GLib.MainLoop()
    agent = Agent(bus, device)
    manager = dbus.Interface(
        bus.get_object(BLUEZ, "/org/bluez"), BLUEZ + ".AgentManager1"
    )
    manager.RegisterAgent(AGENT, "KeyboardDisplay")
    errors = []

    def failed(error):
        errors.append(str(error))
        loop.quit()

    def paired():
        # Only a device explicitly selected and successfully paired is trusted.
        try:
            dbus.Interface(
                bus.get_object(BLUEZ, path), "org.freedesktop.DBus.Properties"
            ).Set(BLUEZ + ".Device1", "Trusted", True)
            device.Connect(reply_handler=loop.quit, error_handler=failed, timeout=30)
        except dbus.DBusException as error:
            failed(error)

    def cancel():
        agent.respond({"accept": False})
        device.CancelPairing(
            reply_handler=lambda: None, error_handler=lambda error: None
        )
        failed("Pairing cancelled or timed out")
        return False

    def reader():
        for line in sys.stdin:
            try:
                response = json.loads(line)
                GLib.idle_add(
                    cancel if response.get("cancel") else agent.respond,
                    *(() if response.get("cancel") else (response,)),
                )
            except (ValueError, AttributeError):
                GLib.idle_add(cancel)
        GLib.idle_add(cancel)

    threading.Thread(target=reader, daemon=True).start()
    GLib.timeout_add_seconds(100, cancel)
    try:
        device.Pair(reply_handler=paired, error_handler=failed, timeout=95)
        loop.run()
    finally:
        manager.UnregisterAgent(AGENT)
    if errors:
        raise RuntimeError(errors[-1])


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "enterprise":
        enterprise(json.loads(sys.stdin.readline()))
    elif len(sys.argv) == 3:
        bluetooth(sys.argv[1], sys.argv[2])
    else:
        raise ValueError("Choose enterprise, pair, connect, disconnect, or forget")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never echo input JSON or settings: they contain credentials.
        print(str(error), file=sys.stderr)
        sys.exit(1)
