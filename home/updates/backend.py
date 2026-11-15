"""Prepare updates without changing the checkout or the running system."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def atomic_write(path, data):
    path = Path(path)
    fd, temporary = tempfile.mkstemp(prefix=".os-update-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


class Updater:
    def __init__(self, config, state, report=lambda phase, line: None):
        self.config = config
        self.source = Path(config["source"])
        self.state = Path(state)
        self.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.report = report
        self.manifest = self.state / "candidate.json"
        self.candidate = None
        if self.manifest.exists():
            try:
                candidate = json.loads(self.manifest.read_text())
                if Path(candidate["system"]).is_dir() and Path(candidate["snapshot"]).is_dir():
                    self.candidate = candidate
            except (ValueError, KeyError, OSError):
                pass

    def save(self):
        atomic_write(self.manifest, json.dumps(self.candidate, indent=2).encode())

    def emit(self, phase, line):
        with (self.state / "update.log").open("a") as log:
            log.write(line + "\n")
        self.report(phase, line)

    def run(self, command, phase):
        self.emit(phase, "$ " + " ".join(map(str, command)))
        with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True, bufsize=1) as process:
            for line in process.stdout:
                self.emit(phase, line.rstrip())
            if process.wait():
                raise RuntimeError(f"{phase} failed. See the log below.")

    def lock(self):
        lock = (self.state / "operation.lock").open("w")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            lock.close()
            raise RuntimeError("Another OS update is already running.") from None
        return lock

    def prepare(self, update_inputs):
        with self.lock():
            self._prepare(update_inputs)

    def _prepare(self, update_inputs):
        if not (self.source / "flake.nix").is_file():
            raise RuntimeError(f"Configuration checkout not found: {self.source}")
        original_lock = digest(self.source / "flake.lock")
        folder = Path(tempfile.mkdtemp(prefix="candidate-", dir=self.state))
        snapshot = folder / "source"
        try:
            self.emit("Preparing", "Copying the current checkout, including uncommitted files.")
            shutil.copytree(self.source, snapshot, ignore=shutil.ignore_patterns(
                ".git", ".direnv", "__pycache__", "result", "result-*", "*.log"))
            if digest(snapshot / "flake.lock") != original_lock:
                raise RuntimeError("The lock file changed while copying. Please prepare again.")
            flake = f"path:{snapshot}"
            nix = self.config["nix"]
            if update_inputs:
                self.run([nix, "flake", "update", "--flake", flake], "Updating inputs")
            self.run([nix, "build", f"{flake}#nixosConfigurations.{self.config['host']}.config.system.build.toplevel",
                      "--no-update-lock-file", "--out-link", str(folder / "result"), "--print-build-logs"], "Building")
            target = (folder / "result").resolve(strict=True)
            self.run([nix, "store", "diff-closures", "/run/booted-system", str(target)], "Review package changes")
            previous = self.candidate
            self.candidate = {"snapshot": str(snapshot), "system": str(target),
                              "original_lock": original_lock, "update_inputs": update_inputs,
                              "phase": "prepared"}
            self.save()
            # Keep the newest candidate rooted in the store, and discard its predecessor.
            if previous and Path(previous["snapshot"]).parent != folder:
                old = Path(previous["snapshot"]).parent
                if old.parent == self.state and old.name.startswith("candidate-"):
                    shutil.rmtree(old, ignore_errors=True)
        except BaseException:
            if not self.candidate or self.candidate.get("snapshot") != str(snapshot):
                shutil.rmtree(folder, ignore_errors=True)
            raise

    def install(self):
        with self.lock():
            candidate = self.candidate
            if not candidate or candidate["phase"] != "prepared":
                raise RuntimeError("Prepare a configuration before installing.")
            lockfile = self.source / "flake.lock"
            if digest(lockfile) != candidate["original_lock"]:
                raise RuntimeError("The checkout's lock file changed. Prepare again before installing.")
            self.run([self.config["pkexec"], self.config["installer"], candidate["system"]], "Installing for next boot")
            # Record installation immediately, even if saving the checkout lock subsequently fails.
            candidate["phase"] = "installed"
            self.save()
            if candidate["update_inputs"]:
                if digest(lockfile) != candidate["original_lock"]:
                    self.emit("Installed", "The lock file changed during installation; the prepared lock was preserved in " + candidate["snapshot"])
                    return
                try:
                    atomic_write(self.state / "flake.lock.before-update", lockfile.read_bytes())
                    atomic_write(lockfile, (Path(candidate["snapshot"]) / "flake.lock").read_bytes())
                except OSError as error:
                    raise RuntimeError(f"System installed, but saving flake.lock failed: {error}. The prepared lock is in {candidate['snapshot']}") from error
            self.emit("Installed", "Ready for the next boot. Your current desktop remains running.")
