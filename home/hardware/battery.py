"""Desktop battery warnings; UPower owns the system's critical action."""

import subprocess
import time


def warning_level(on_battery, percentage):
    if not on_battery:
        return 0
    return 3 if percentage <= 10 else 2 if percentage <= 15 else 1 if percentage <= 25 else 0


def main():
    import dbus

    bus = dbus.SystemBus()
    previous = 0
    while True:
        # Resolve each time so restarting UPower does not leave stale proxies.
        power = dbus.Interface(bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower"),
                               "org.freedesktop.DBus.Properties")
        battery = dbus.Interface(bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower/devices/DisplayDevice"),
                                 "org.freedesktop.DBus.Properties")
        percentage = float(battery.Get("org.freedesktop.UPower.Device", "Percentage"))
        level = warning_level(bool(power.Get("org.freedesktop.UPower", "OnBattery")), percentage)
        if level > previous:
            title = ["", "Battery low", "Battery critical", "Hibernating soon"][level]
            result = subprocess.run([
                "notify-send", "--app-name=Battery", "--urgency=critical", "--expire-time=0",
                "--hint=string:x-canonical-private-synchronous:battery",
                title, f"{percentage:.0f}% remaining. Connect the charger. Automatic hibernation at 10%.",
            ], check=False, timeout=10)
            if result.returncode == 0:
                previous = level
        elif level == 0:
            previous = 0
        time.sleep(30)


if __name__ == "__main__":
    main()
