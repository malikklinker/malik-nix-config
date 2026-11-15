import fcntl
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from backend import Updater
from install import install


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "checkout"
        self.source.mkdir()
        (self.source / "flake.nix").write_text("{}")
        (self.source / "flake.lock").write_text("old lock")
        (self.source / "untracked.nix").write_text("new local config")
        self.system = self.root / "built-system"
        self.system.mkdir()
        self.updater = Updater({"source": str(self.source), "host": "zephyrus", "nix": "nix",
                                "pkexec": "pkexec", "installer": "installer"}, self.root / "state")
        self.commands = []
        self.fail = None
        self.updater.run = self.fake_run

    def fake_run(self, args, phase):
        self.commands.append(args)
        if phase == self.fail:
            raise RuntimeError("simulated failure")
        if phase == "Updating inputs":
            snapshot = Path(args[-1].removeprefix("path:"))
            (snapshot / "flake.lock").write_text("new lock")
        if phase == "Building":
            Path(args[args.index("--out-link") + 1]).symlink_to(self.system)

    def test_prepare_does_not_mutate_checkout_and_includes_untracked_files(self):
        self.updater.prepare(True)
        self.assertEqual((self.source / "flake.lock").read_text(), "old lock")
        snapshot = Path(self.updater.candidate["snapshot"])
        self.assertEqual((snapshot / "flake.lock").read_text(), "new lock")
        self.assertTrue((snapshot / "untracked.nix").is_file())
        self.assertEqual(Updater(self.updater.config, self.updater.state).candidate, self.updater.candidate)

    def test_local_apply_preserves_pins(self):
        self.updater.prepare(False)
        self.assertFalse(any("update" in args for args in self.commands))
        self.updater.install()
        self.assertEqual((self.source / "flake.lock").read_text(), "old lock")

    def test_failed_build_retains_previous_candidate(self):
        self.updater.prepare(False)
        previous = dict(self.updater.candidate)
        self.fail = "Building"
        with self.assertRaises(RuntimeError):
            self.updater.prepare(True)
        self.assertEqual(self.updater.candidate, previous)
        self.assertTrue(Path(previous["snapshot"]).is_dir())
        self.assertEqual(len(list(self.updater.state.glob("candidate-*"))), 1)
        self.assertEqual((self.source / "flake.lock").read_text(), "old lock")

    def test_refuses_install_if_lock_changed(self):
        self.updater.prepare(True)
        (self.source / "flake.lock").write_text("edited elsewhere")
        with self.assertRaisesRegex(RuntimeError, "lock file changed"):
            self.updater.install()
        self.assertFalse(any(args[0] == "pkexec" for args in self.commands))

    def test_failed_authentication_or_install_does_not_save_pins(self):
        self.updater.prepare(True)
        self.fail = "Installing for next boot"
        with self.assertRaises(RuntimeError):
            self.updater.install()
        self.assertEqual((self.source / "flake.lock").read_text(), "old lock")
        self.assertEqual(self.updater.candidate["phase"], "prepared")

    def test_success_saves_pins_and_backup(self):
        self.updater.prepare(True)
        self.updater.install()
        self.assertEqual((self.source / "flake.lock").read_text(), "new lock")
        self.assertEqual((self.updater.state / "flake.lock.before-update").read_text(), "old lock")
        self.assertEqual(self.updater.candidate["phase"], "installed")
        self.assertEqual(self.commands[-1], ["pkexec", "installer", str(self.system)])

    def test_concurrent_operation_is_rejected(self):
        with self.updater.lock():
            with self.assertRaisesRegex(RuntimeError, "already running"):
                self.updater.prepare(True)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.target = Path("/nix/store/" + "a" * 32 + "-nixos-system-zephyrus-new")
        self.previous = Path("/nix/store/" + "b" * 32 + "-nixos-system-zephyrus-old")
        self.profile = Path("/profile")

    def test_installs_only_for_boot(self):
        commands = []
        with patch.object(Path, "resolve", side_effect=[self.target, self.previous]), patch.object(Path, "is_file", return_value=True):
            install(self.target, self.profile, run=commands.append)
        self.assertEqual(commands[-1], [str(self.target / "bin/switch-to-configuration"), "boot"])

    def test_install_failure_restores_previous_boot_generation(self):
        commands = []
        def run(args):
            commands.append(args)
            if args[0] == str(self.target / "bin/switch-to-configuration"):
                raise RuntimeError("bootloader failure")
        with patch.object(Path, "resolve", side_effect=[self.target, self.previous]), patch.object(Path, "is_file", return_value=True):
            with self.assertRaisesRegex(RuntimeError, "bootloader failure"):
                install(self.target, self.profile, run=run)
        self.assertEqual(commands[-2][-1], str(self.previous))
        self.assertEqual(commands[-1], [str(self.previous / "bin/switch-to-configuration"), "boot"])

    def test_rejects_mutable_paths_before_running_any_command(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                install(folder, run=lambda args: self.fail("must not run"))


if __name__ == "__main__":
    unittest.main()
