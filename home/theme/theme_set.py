"""Tinty frontend and application reload adapter for the desktop's shared palette."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as file:
        temporary = Path(file.name)
        file.write(content)
    temporary.replace(path)


def run(command):
    try:
        return subprocess.run(command, capture_output=True, text=True, timeout=8)
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"Theme reload: {command[0]}: {error}", file=sys.stderr)
        return None


def reload_apps(theme):
    if os.environ.get("DESKTOP_THEME_NO_RELOAD") == "1":
        return
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        run(["hyprctl", "reload", "config-only"])
    # Niri watches the included palette file for changes.
    run(["makoctl", "reload"])
    run(["systemctl", "--user", "try-restart", "walker.service"])
    preference = "prefer-dark" if theme["variant"] == "dark" else "prefer-light"
    run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", preference])
    gtk_theme = "Adwaita-dark" if theme["variant"] == "dark" else "Adwaita"
    run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", gtk_theme])
    processes = run(["pgrep", "-u", str(os.getuid()), "-x", "kitty"])
    if processes and processes.returncode == 0:
        for pid in processes.stdout.split():
            try:
                os.kill(int(pid), signal.SIGUSR1)
            except ProcessLookupError:
                pass


def apply_theme(theme, state, assets):
    palette, colors = theme["palette"], theme["colors"]
    if not all(re.fullmatch(r"#[0-9a-fA-F]{6}", value) for value in palette.values()):
        raise ValueError("Invalid theme color")
    ansi = [
        "base00",
        "base08",
        "base0B",
        "base0A",
        "base0D",
        "base0E",
        "base0C",
        "base05",
        "base03",
        "base08",
        "base0B",
        "base0A",
        "base0D",
        "base0E",
        "base0C",
        "base07",
    ]
    kitty = [f"color{i} {palette[key]}" for i, key in enumerate(ansi)]
    kitty += [
        f"{key} {value}"
        for key, value in {
            "background": colors["background"],
            "foreground": colors["text"],
            "cursor": colors["accent"],
            "cursor_text_color": colors["background"],
            "selection_background": colors["overlay"],
            "selection_foreground": colors["text"],
            "active_tab_background": colors["accent"],
            "active_tab_foreground": colors["background"],
            "inactive_tab_background": colors["surface"],
            "inactive_tab_foreground": colors["subtext"],
        }.items()
    ]
    atomic_write(state / "kitty.conf", "\n".join(kitty) + "\n")

    def border(role):
        return f"rgba({colors[role][1:]}ff)"

    atomic_write(
        state / "hyprland.lua",
        'return { active_border = "'
        + border("accent")
        + '", inactive_border = "'
        + border("overlay")
        + '" }\n',
    )
    atomic_write(
        state / "niri.kdl",
        'layout { focus-ring { width 2; active-color "'
        + colors["accent"]
        + '"; inactive-color "'
        + colors["overlay"]
        + '"; }; }\n',
    )
    css = (assets / "walker.css.in").read_text()
    for role, value in colors.items():
        css = css.replace("@" + role.upper() + "@", value)
    atomic_write(state / "walker.css", css)
    atomic_write(
        state / "mako.conf",
        "\n".join(
            [
                "font=JetBrainsMono Nerd Font 11",
                f"background-color={colors['background']}",
                f"text-color={colors['text']}",
                f"border-color={colors['accent']}",
                "border-size=2",
                "border-radius=8",
                "padding=12",
                "default-timeout=5000",
                "[urgency=critical]",
                f"border-color={colors['red']}",
                "default-timeout=0",
                "",
            ]
        ),
    )
    gtk_roles = {
        "window_bg_color": "background",
        "window_fg_color": "text",
        "view_bg_color": "surface",
        "view_fg_color": "text",
        "theme_bg_color": "background",
        "theme_fg_color": "text",
        "theme_base_color": "surface",
        "theme_text_color": "text",
        "theme_selected_bg_color": "accent",
        "theme_selected_fg_color": "background",
        "accent_bg_color": "accent",
        "accent_fg_color": "background",
        "headerbar_bg_color": "surface",
        "headerbar_fg_color": "text",
        "card_bg_color": "surface",
        "card_fg_color": "text",
        "popover_bg_color": "surface",
        "popover_fg_color": "text",
    }
    gtk_css = (
        "\n".join(
            f"@define-color {name} {colors[role]};" for name, role in gtk_roles.items()
        )
        + "\n"
    )
    atomic_write(state / "gtk3.css", gtk_css)
    variables = "\n".join(
        f"  --{name.replace('_', '-')}: {colors[role]};"
        for name, role in gtk_roles.items()
        if not name.startswith("theme_")
    )
    atomic_write(state / "gtk4.css", gtk_css + ":root {\n" + variables + "\n}\n")
    # Publish the palette last so Quickshell and Neovim see a completed update.
    atomic_write(state / "theme.json", json.dumps(theme) + "\n")
    reload_apps(theme)


def main():
    parser = argparse.ArgumentParser(
        prog="theme-set",
        description="Apply a preset palette or open the Quickshell swatch picker",
    )
    parser.add_argument("scheme", nargs="?")
    parser.add_argument("--assets", type=Path, required=True, help=argparse.SUPPRESS)
    parser.add_argument("--tinty", required=True, help=argparse.SUPPRESS)
    parser.add_argument("--apply", type=Path, help=argparse.SUPPRESS)
    parser.add_argument(
        "--restore", action="store_true", help="reapply the saved palette"
    )
    parser.add_argument(
        "--no-reload",
        action="store_true",
        help="write colors without reloading applications",
    )
    parser.add_argument(
        "--list", action="store_true", help="list available palette names"
    )
    parser.add_argument(
        "--current", action="store_true", help="show the selected palette name"
    )
    args = parser.parse_args()
    home = Path.home()
    config = Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config")
    state = (
        Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
        / "desktop-theme"
    )
    data = (
        Path(os.environ.get("XDG_DATA_HOME") or home / ".local/share")
        / "tinted-theming/desktop"
    )
    catalog = json.loads((args.assets / "catalog.json").read_text())
    if args.no_reload:
        os.environ["DESKTOP_THEME_NO_RELOAD"] = "1"
    if args.apply:
        apply_theme(json.loads(args.apply.read_text()), state, args.assets)
        return
    if args.list:
        print("\n".join(theme["slug"] for theme in catalog))
        return
    if args.current:
        print(
            json.loads((state / "theme.json").read_text())["slug"]
            if (state / "theme.json").exists()
            else "catppuccin-mocha"
        )
        return
    if not args.scheme and not args.restore:
        result = subprocess.run(
            ["quickshell", "ipc", "-c", "mocha", "call", "theme", "openPicker"]
        )
        raise SystemExit(result.returncode)
    aliases = {
        "mocha": "catppuccin-mocha",
        "latte": "catppuccin-latte",
        "frappe": "catppuccin-frappe",
        "macchiato": "catppuccin-macchiato",
        "gruvbox": "gruvbox-dark-hard",
        "tokyo-night": "tokyo-night-dark",
    }
    state.mkdir(parents=True, exist_ok=True)
    with (state / ".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        scheme = args.scheme
        if args.restore:
            scheme = (
                json.loads((state / "theme.json").read_text())["slug"]
                if (state / "theme.json").exists()
                else "catppuccin-mocha"
            )
        scheme = aliases.get(scheme, scheme)
        selected = next(
            (theme for theme in catalog if scheme in (theme["slug"], theme["id"])), None
        )
        if selected is None:
            raise ValueError(f"Unknown theme: {scheme}. Use theme-set --list.")
        repos = data / "repos"
        repos.mkdir(parents=True, exist_ok=True)
        for name, source in [
            ("schemes", args.assets / "schemes"),
            ("desktop", args.assets / "template"),
        ]:
            link = repos / name
            if link.is_symlink():
                if link.resolve() == source.resolve():
                    continue
                link.unlink()
            elif link.exists():
                raise ValueError(f"Expected a managed repository link at {link}")
            link.symlink_to(source, target_is_directory=True)
        subprocess.run(
            [
                args.tinty,
                "--config",
                str(config / "desktop-theme/tinty.toml"),
                "--data-dir",
                str(data),
                "apply",
                selected["id"],
            ],
            check=True,
        )
        # Hooks in this Tinty version don't propagate their exit status; verify publication.
        if (
            not (state / "theme.json").exists()
            or json.loads((state / "theme.json").read_text())["id"] != selected["id"]
        ):
            raise ValueError(
                "The theme could not be applied; check the theme adapter output above."
            )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"theme-set: {error}", file=sys.stderr)
        sys.exit(1)
