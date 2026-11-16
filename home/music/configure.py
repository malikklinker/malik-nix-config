"""Seed Pear's writable preferences while preserving existing settings."""

import argparse
import json
import os
from pathlib import Path
import tempfile


def configure(path, theme):
    settings = json.loads(path.read_text()) if path.exists() else {}
    options = settings.setdefault("options", {})
    themes = options.setdefault("themes", [])
    if theme not in themes:
        themes.append(theme)
    # Nix owns application updates.
    options["autoUpdates"] = False
    for key, value in {"hideMenu": True, "resumeOnStart": False}.items():
        options.setdefault(key, value)
    plugins = settings.setdefault("plugins", {})
    for name in ("shortcuts", "synced-lyrics", "precise-volume"):
        plugins.setdefault(name, {}).setdefault("enabled", True)
    plugins.setdefault("in-app-menu", {}).setdefault("enabled", True)
    plugins["in-app-menu"].setdefault("hideDOMWindowControls", True)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as file:
        os.chmod(file.name, 0o600)
        json.dump(settings, file, indent=2)
        file.write("\n")
    Path(file.name).replace(path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--theme", required=True)
    args = parser.parse_args()
    configure(args.config, args.theme)
