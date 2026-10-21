"""Laptop controls shared by the panel, media keys, and palette switcher."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
SETTINGS = STATE / "desktop-hardware/settings.json"


def run(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=10)
    if result.returncode:
        detail = (result.stderr or result.stdout).strip().splitlines()
        raise RuntimeError(detail[-1] if detail else f"{args[0]} failed")


def screen_device():
    # The internal panel belongs to AMD; nvidia_0 is not its backlight.
    return next(iter(sorted(Path("/sys/class/backlight").glob("amdgpu_bl*"))), None)


def read_int(path):
    return int(path.read_text().strip())


def settings():
    try:
        return json.loads(SETTINGS.read_text())
    except FileNotFoundError:
        return {"theme_sync": True}


def save_settings(value):
    with tempfile.NamedTemporaryFile(
        mode="w", dir=SETTINGS.parent, delete=False
    ) as file:
        json.dump(value, file)
        temporary = Path(file.name)
    temporary.replace(SETTINGS)


def sync_theme():
    if not settings().get("theme_sync", True):
        return
    theme_path = STATE / "desktop-theme/theme.json"
    if not theme_path.exists():
        return
    color = json.loads(theme_path.read_text())["colors"]["accent"]
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
        raise ValueError("Invalid keyboard color in desktop palette")
    run("asusctl", "aura", "effect", "static", "-c", color[1:])


def status():
    screen = screen_device()
    keyboard = Path("/sys/class/leds/asus::kbd_backlight")
    profile = Path("/sys/firmware/acpi/platform_profile")
    return {
        "screen": round(
            100 * read_int(screen / "brightness") / read_int(screen / "max_brightness")
        )
        if screen
        else None,
        "keyboard": read_int(keyboard / "brightness") if keyboard.exists() else None,
        "profile": profile.read_text().strip() if profile.exists() else None,
        "themeSync": settings().get("theme_sync", True),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=[
            "status",
            "screen",
            "screen-up",
            "screen-down",
            "keyboard",
            "keyboard-up",
            "keyboard-down",
            "profile",
            "theme-sync",
            "sync",
        ],
    )
    parser.add_argument("value", nargs="?")
    args = parser.parse_args()
    SETTINGS.parent.mkdir(parents=True, exist_ok=True)
    # Media keys, sliders and theme changes can arrive together.
    with (SETTINGS.parent / ".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.action == "status":
            print(json.dumps(status()))
        elif args.action.startswith("screen"):
            screen = screen_device()
            if screen is None:
                raise RuntimeError("AMD panel brightness is unavailable")
            current = status()["screen"]
            value = (
                int(args.value)
                if args.action == "screen"
                else current + (5 if args.action == "screen-up" else -5)
            )
            run(
                "brightnessctl",
                "--device",
                screen.name,
                "set",
                f"{max(1, min(100, value))}%",
            )
        elif args.action.startswith("keyboard"):
            current = status()["keyboard"]
            if current is None:
                raise RuntimeError("Keyboard backlight is unavailable")
            value = (
                int(args.value)
                if args.action == "keyboard"
                else current + (1 if args.action == "keyboard-up" else -1)
            )
            run(
                "asusctl",
                "leds",
                "set",
                ["off", "low", "med", "high"][max(0, min(3, value))],
            )
        elif args.action == "profile":
            names = {
                "quiet": "Quiet",
                "balanced": "Balanced",
                "performance": "Performance",
            }
            if args.value not in names:
                raise ValueError("Choose quiet, balanced, or performance")
            run("asusctl", "profile", "set", names[args.value])
        elif args.action == "theme-sync":
            if args.value not in ("on", "off"):
                raise ValueError("Choose on or off")
            value = settings()
            value["theme_sync"] = args.value == "on"
            save_settings(value)
            sync_theme()
        elif args.action == "sync":
            sync_theme()


if __name__ == "__main__":
    try:
        main()
    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        subprocess.TimeoutExpired,
    ) as error:
        print(f"Laptop controls: {error}", file=sys.stderr)
        sys.exit(1)
