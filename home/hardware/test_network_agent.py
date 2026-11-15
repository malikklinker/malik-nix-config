"""Offline checks for certificate validation and interactive pairing decisions."""

import tempfile
import unittest
from unittest.mock import Mock, patch

import network_agent as agent


class EnterpriseTests(unittest.TestCase):
    def setUp(self):
        self.ca = tempfile.NamedTemporaryFile()
        self.addCleanup(self.ca.close)
        self.data = {
            "ssid": "eduroam",
            "identity": "student@example.edu",
            "domain": "radius.example.edu",
            "ca": self.ca.name,
            "password": "test-only-password",
            "eap": "peap",
            "phase2": "mschapv2",
        }

    def test_verified_peap_profile(self):
        settings = agent.enterprise_settings(self.data)
        auth = settings["802-1x"]
        self.assertEqual(auth["domain-suffix-match"], "radius.example.edu")
        self.assertEqual(
            bytes(auth["ca-cert"]), ("file://" + self.ca.name + "\0").encode()
        )
        self.assertEqual(list(auth["eap"]), ["peap"])
        self.assertEqual(auth["password-flags"], 0)
        self.assertEqual(bytes(settings["802-11-wireless"]["ssid"]), b"eduroam")

    def test_ttls_pap(self):
        settings = agent.enterprise_settings(
            {**self.data, "eap": "ttls", "phase2": "pap"}
        )
        self.assertEqual(settings["802-1x"]["phase2-auth"], "pap")

    def test_incomplete_or_unverified_profiles_rejected(self):
        for change in (
            {"domain": ""},
            {"domain": "https://example.edu"},
            {"ca": "/missing/ca.pem"},
            {"identity": ""},
            {"password": ""},
            {"eap": "tls"},
            {"eap": "peap", "phase2": "pap"},
            {"ssid": "é" * 17},
        ):
            with self.subTest(change=change), self.assertRaises((ValueError, OSError)):
                agent.enterprise_settings({**self.data, **change})

    def test_invalid_settings_do_not_contact_networkmanager(self):
        with patch.object(agent.dbus, "SystemBus") as bus:
            with self.assertRaises(ValueError):
                agent.enterprise({**self.data, "domain": ""})
            bus.assert_not_called()


class PairingTests(unittest.TestCase):
    def setUp(self):
        # Exercise agent callbacks without registering a real system-bus object.
        self.agent = object.__new__(agent.Agent)
        self.agent.pending = None
        self.success, self.failure = Mock(), Mock()

    def respond(self, kind, value="", accept=True):
        self.agent.pending = (kind, self.success, self.failure)
        self.agent.respond({"accept": accept, "value": value})
        self.assertIsNone(self.agent.pending)

    def test_confirmation_requires_explicit_acceptance(self):
        self.respond("confirm", accept=False)
        self.success.assert_not_called()
        self.assertIsInstance(self.failure.call_args.args[0], agent.Rejected)

    def test_confirmation_accepted(self):
        self.respond("confirm")
        self.success.assert_called_once_with()
        self.failure.assert_not_called()

    def test_numeric_passkey_preserves_leading_zero_value(self):
        self.respond("passkey", "001234")
        self.success.assert_called_once_with(1234)

    def test_invalid_passkey_is_rejected(self):
        self.respond("passkey", "1234567")
        self.failure.assert_called_once()
        self.success.assert_not_called()

    def test_legacy_pin(self):
        self.respond("pin", "AB1234")
        self.success.assert_called_once_with("AB1234")

    def test_displayed_confirmation_is_zero_padded(self):
        with patch.object(agent, "emit") as emit:
            self.agent.RequestConfirmation("/device", 1234, self.success, self.failure)
            emit.assert_called_once_with(type="confirm", code="001234")
        self.success.assert_not_called()

    def test_bluez_cancel_rejects_pending_request(self):
        self.agent.pending = ("pin", self.success, self.failure)
        with patch.object(agent, "emit"):
            self.agent.Cancel()
        self.failure.assert_called_once()
        self.assertIsNone(self.agent.pending)


if __name__ == "__main__":
    unittest.main()
