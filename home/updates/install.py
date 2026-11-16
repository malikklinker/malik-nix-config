"""Authenticated, boot-only installation of a previously built NixOS system."""
import fcntl
import os
from pathlib import Path
import re
import subprocess
import sys

NIX_ENV = "@nixEnv@"


def install(target, profile=Path("/nix/var/nix/profiles/system"), run=subprocess.check_call):
    target = Path(target).resolve(strict=True)
    if not re.fullmatch(r"/nix/store/[a-z0-9]{32}-nixos-system-zephyrus-[^/]+", str(target)):
        raise ValueError("Expected a built Zephyrus NixOS store path")
    if not (target / "bin/switch-to-configuration").is_file():
        raise ValueError("The candidate is missing its activation script")
    previous = profile.resolve(strict=True)
    try:
        run([NIX_ENV, "--profile", str(profile), "--set", str(target)])
        run([str(target / "bin/switch-to-configuration"), "boot"])
    except BaseException:
        print("Installation failed; restoring the previous boot generation.", flush=True)
        run([NIX_ENV, "--profile", str(profile), "--set", str(previous)])
        run([str(previous / "bin/switch-to-configuration"), "boot"])
        raise


if __name__ == "__main__":
    if os.geteuid() != 0 or len(sys.argv) != 2:
        sys.exit("Run through OS Updates with administrator authentication.")
    with open("/run/lock/os-update-install.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            install(sys.argv[1])
        except Exception as error:
            sys.exit(str(error))
