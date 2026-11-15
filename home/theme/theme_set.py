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
    # Helix reloads configuration and its selected theme on SIGUSR1.
    run(["pkill", "-USR1", "-u", str(os.getuid()), "-x", r"(hx|\.hx-wrapped)"])
    # Hardware sync is optional: an unavailable ASUS daemon must not prevent
    # the rest of the desktop from changing palette.
    result = run(["desktop-hardware", "sync"])
    if result is not None and result.returncode:
        print(result.stderr.strip(), file=sys.stderr)
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        run(["hyprctl", "reload", "config-only"])
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


def zed_theme(theme):
    """A flat editor theme using the same semantic colors as the desktop."""
    c, p = theme["colors"], theme["palette"]
    style = {}
    for role, keys in {
        "background": [
            "background",
            "editor.background",
            "editor.gutter.background",
            "toolbar.background",
            "tab.active_background",
            "terminal.background",
        ],
        "surface": [
            "surface.background",
            "elevated_surface.background",
            "panel.background",
            "title_bar.background",
            "title_bar.inactive_background",
            "status_bar.background",
            "tab_bar.background",
            "tab.inactive_background",
            "editor.active_line.background",
            "editor.subheader.background",
        ],
        "overlay": [
            "border",
            "border.variant",
            "element.hover",
            "element.selected",
            "ghost_element.hover",
            "ghost_element.selected",
            "editor.highlighted_line.background",
        ],
        "text": [
            "text",
            "icon",
            "editor.foreground",
            "editor.active_line_number",
            "terminal.foreground",
        ],
        "subtext": ["text.muted", "icon.muted"],
        "muted": [
            "text.placeholder",
            "text.disabled",
            "icon.disabled",
            "editor.line_number",
            "editor.invisible",
            "editor.wrap_guide",
        ],
        "accent": ["border.focused", "text.accent", "icon.accent", "border.selected"],
        "red": ["error"],
        "yellow": ["warning"],
        "green": ["success"],
        "blue": ["info"],
    }.items():
        style.update({key: c[role] for key in keys})
    # Zed's fallback status colors are saturated ANSI colors, not colors from
    # the active theme. Define every status, including Git's separate tokens.
    for role, statuses in {
        "red": ["deleted", "error"],
        "yellow": ["conflict", "modified", "warning"],
        "green": ["created", "success"],
        "accent": ["info", "renamed"],
        "subtext": ["hint", "unreachable"],
        "muted": ["hidden", "ignored", "predictive"],
    }.items():
        for status in statuses:
            style[status] = c[role]
            style[f"{status}.background"] = c[role] + "18"
            style[f"{status}.border"] = c[role] + "50"
    style.update(
        {
            "version_control.added": c["green"],
            "version_control.modified": c["yellow"],
            "version_control.deleted": c["red"],
            "version_control.word_added": c["green"] + "30",
            "version_control.word_deleted": c["red"] + "30",
            "version_control.conflict_marker.ours": c["green"] + "20",
            "version_control.conflict_marker.theirs": c["blue"] + "20",
            "border.disabled": c["surface"],
            "border.transparent": "#00000000",
            "element.background": c["surface"],
            "element.active": c["overlay"],
            "element.disabled": c["surface"],
            "ghost_element.background": "#00000000",
            "ghost_element.active": c["overlay"],
            "ghost_element.disabled": "#00000000",
            "icon.placeholder": c["muted"],
            "drop_target.background": c["accent"] + "30",
            "panel.focused_border": c["overlay"],
            "pane.focused_border": c["overlay"],
            "scrollbar.thumb.background": c["muted"] + "60",
            "scrollbar.thumb.hover_background": c["muted"] + "90",
            "scrollbar.thumb.border": "#00000000",
            "scrollbar.track.background": "#00000000",
            "scrollbar.track.border": "#00000000",
            "editor.hover_line_number": c["subtext"],
            "editor.indent_guide": c["overlay"],
            "editor.indent_guide_active": c["muted"],
            "editor.active_wrap_guide": c["overlay"],
            "editor.document_highlight.read_background": c["accent"] + "20",
            "editor.document_highlight.write_background": c["secondary"] + "25",
            "editor.document_highlight.bracket_background": c["accent"] + "25",
            "search.active_match_background": c["secondary"] + "40",
            "link_text.hover": c["accent"],
            "terminal.bright_foreground": p["base07"],
            "terminal.dim_foreground": c["muted"],
            "accents": [
                c[key]
                for key in ["accent", "secondary", "cyan", "green", "yellow", "red"]
            ],
        }
    )
    style["search.match_background"] = c["accent"] + "40"
    style["players"] = [
        {
            "cursor": c["accent"],
            "background": c["accent"],
            "selection": c["accent"] + "40",
        }
    ]
    for name, base in {
        "black": "base00",
        "red": "base08",
        "green": "base0B",
        "yellow": "base0A",
        "blue": "base0D",
        "magenta": "base0E",
        "cyan": "base0C",
        "white": "base05",
    }.items():
        style[f"terminal.ansi.{name}"] = p[base]
        style[f"terminal.ansi.bright_{name}"] = p["base03" if name == "black" else base]
        style[f"terminal.ansi.dim_{name}"] = p[base]
    style["terminal.ansi.bright_white"] = p["base07"]
    syntax = {}
    for base, captures in {
        "base03": ["comment", "comment.doc"],
        "base05": [
            "variable",
            "property",
            "punctuation",
            "punctuation.bracket",
            "punctuation.delimiter",
        ],
        "base08": ["tag", "variable.special"],
        "base09": ["number", "boolean", "constant"],
        "base0A": ["type", "constructor"],
        "base0B": ["string", "string.special"],
        "base0C": ["operator", "string.escape"],
        "base0D": ["function", "function.method"],
        "base0E": ["keyword", "attribute"],
    }.items():
        syntax.update({capture: {"color": p[base]} for capture in captures})
    syntax["comment"]["font_style"] = "italic"
    # Match desktop-syntax.lua, including its restrained Midnight Blue roles.
    roles = {
        "text": c["text"],
        "punctuation": c["subtext"],
        "keyword": p["base0E"],
        "function": p["base0D"],
        "type": p["base0A"],
        "constant": p["base09"],
        "string": p["base0B"],
        "special": p["base0C"],
    }
    if theme["slug"] == "midnight-blue":
        roles.update(
            keyword=c["accent"],
            function=c["accent"],
            type=c["secondary"],
            constant=c["secondary"],
            string=c["cyan"],
            special=c["secondary"],
        )
    for role, captures in {
        "text": [
            "primary",
            "embedded",
            "variable",
            "variable.parameter",
            "variable.member",
            "property",
            "namespace",
        ],
        "punctuation": [
            "operator",
            "punctuation",
            "punctuation.bracket",
            "punctuation.delimiter",
            "punctuation.list_marker",
            "punctuation.markup",
        ],
        "keyword": [
            "keyword",
            "keyword.conditional",
            "keyword.operator",
            "keyword.import",
            "keyword.exception",
            "preproc",
            "label",
        ],
        "function": [
            "function",
            "function.call",
            "function.builtin",
            "function.method",
            "constructor",
            "title",
        ],
        "type": ["type", "type.builtin", "attribute", "tag", "enum"],
        "constant": [
            "constant",
            "constant.builtin",
            "number",
            "number.float",
            "boolean",
            "variable.special",
            "variable.parameter.builtin",
        ],
        "string": [
            "string",
            "string.special",
            "string.special.path",
            "string.special.url",
            "string.regex",
            "link_uri",
        ],
        "special": ["string.escape", "punctuation.special", "link_text", "emphasis"],
    }.items():
        syntax.update({capture: {"color": roles[role]} for capture in captures})
    syntax["hint"] = {"color": c["subtext"]}
    syntax["predictive"] = {"color": c["muted"], "font_style": "italic"}
    syntax["emphasis.strong"] = {"color": c["text"], "font_weight": 700}
    style["syntax"] = syntax
    return {
        "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
        "name": "Desktop",
        "author": "Malik",
        "themes": [{"name": "Desktop", "appearance": theme["variant"], "style": style}],
    }


def helix_theme(theme):
    """Flat UI and restrained syntax matching the shared desktop palette."""
    c, p = theme["colors"], theme["palette"]
    roles = {
        "keyword": p["base0E"], "function": p["base0D"],
        "type": p["base0A"], "constant": p["base09"], "string": p["base0B"],
    }
    if theme["slug"] == "midnight-blue":
        roles.update(keyword=c["accent"], function=c["accent"],
                     type=c["secondary"], constant=c["secondary"], string=c["cyan"])
    styles = {key: {"fg": value} for key, value in roles.items()}
    styles.update({
        "attribute": {"fg": c["secondary"]},
        "constructor": {"fg": roles["type"]},
        "namespace": {"fg": roles["type"]},
        "variable": {"fg": c["text"]},
        "label": {"fg": c["accent"]},
        "operator": {"fg": c["subtext"]},
        "punctuation": {"fg": c["subtext"]},
        "string.special": {"fg": c["cyan"]},
        "constant.character.escape": {"fg": c["cyan"]},
        "comment": {"fg": c["muted"], "modifiers": ["italic"]},
        "ui.background": {"bg": c["background"]},
        "ui.text": {"fg": c["text"]},
        "ui.text.focus": {"fg": c["accent"], "modifiers": ["bold"]},
        "ui.text.inactive": {"fg": c["muted"]},
        "ui.linenr": {"fg": c["muted"]},
        "ui.linenr.selected": {"fg": c["accent"]},
        "ui.gutter": {"bg": c["background"]},
        "ui.selection": {"bg": c["overlay"]},
        "ui.cursor": {"fg": c["background"], "bg": c["accent"]},
        "ui.cursor.select": {"fg": c["background"], "bg": c["secondary"]},
        "ui.cursor.insert": {"fg": c["background"], "bg": c["green"]},
        "ui.cursor.match": {"fg": c["secondary"], "modifiers": ["bold"]},
        "ui.statusline": {"fg": c["text"], "bg": c["surface"]},
        "ui.statusline.inactive": {"fg": c["muted"], "bg": c["background"]},
        "ui.statusline.normal": {"fg": c["background"], "bg": c["accent"], "modifiers": ["bold"]},
        "ui.statusline.insert": {"fg": c["background"], "bg": c["green"], "modifiers": ["bold"]},
        "ui.statusline.select": {"fg": c["background"], "bg": c["secondary"], "modifiers": ["bold"]},
        "ui.popup": {"fg": c["text"], "bg": c["surface"]},
        "ui.help": {"fg": c["text"], "bg": c["surface"]},
        "ui.menu": {"fg": c["text"], "bg": c["surface"]},
        "ui.menu.selected": {"fg": c["accent"], "bg": c["overlay"]},
        "ui.menu.scroll": {"fg": c["muted"], "bg": c["surface"]},
        "ui.window": {"fg": c["overlay"]},
        "ui.virtual": {"fg": c["muted"]},
        "ui.virtual.jump-label": {"fg": c["background"], "bg": c["secondary"], "modifiers": ["bold"]},
        "markup.heading": {"fg": c["accent"], "modifiers": ["bold"]},
        "markup.bold": {"modifiers": ["bold"]},
        "markup.italic": {"modifiers": ["italic"]},
        "markup.link.url": {"fg": c["cyan"], "modifiers": ["underlined"]},
        "markup.raw": {"fg": roles["string"]},
        "diff.plus": {"fg": c["green"]},
        "diff.delta": {"fg": c["yellow"]},
        "diff.minus": {"fg": c["red"]},
    })
    for severity, role in {"error": "red", "warning": "yellow", "info": "blue", "hint": "muted"}.items():
        styles[severity] = {"fg": c[role]}
        styles[f"diagnostic.{severity}"] = {"underline": {"color": c[role], "style": "curl"}}
    # JSON strings and inline objects are also valid TOML values here.
    def value(item):
        if isinstance(item, dict):
            return "{ " + ", ".join(f"{key} = {value(val)}" for key, val in item.items()) + " }"
        return json.dumps(item)
    return "\n".join(f'{json.dumps(key)} = {value(style)}' for key, style in styles.items()) + "\n"


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
    css = (assets / "walker.css.in").read_text()
    for role, value in colors.items():
        css = css.replace("@" + role.upper() + "@", value)
    atomic_write(state / "walker.css", css)
    pear_css = (assets / "pear.css.in").read_text()
    for role, value in colors.items():
        pear_css = pear_css.replace("@" + role.upper() + "@", value)
    pear_css = pear_css.replace("@VARIANT@", theme["variant"])
    atomic_write(state / "pear.css", pear_css)
    vivaldi_css = (assets / "vivaldi.css.in").read_text()
    for role, value in colors.items():
        vivaldi_css = vivaldi_css.replace("@" + role.upper() + "@", value)
    vivaldi_css = vivaldi_css.replace("@VARIANT@", theme["variant"])
    vivaldi_base = (assets / "vivaldi-base.css").read_text()
    atomic_write(state / "vivaldi/desktop.css", vivaldi_base + "\n" + vivaldi_css)
    atomic_write(
        state / "mako.conf",
        "\n".join(
            [
                "font=JetBrainsMono Nerd Font 11",
                f"background-color={colors['background']}",
                f"text-color={colors['text']}",
                f"border-color={colors['accent']}",
                "border-size=2",
                "border-radius=0",
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
    thunar_css = (assets / "thunar.css.in").read_text()
    for role, value in colors.items():
        thunar_css = thunar_css.replace("@" + role.upper() + "@", value)
    atomic_write(state / "gtk3.css", gtk_css + "\n" + thunar_css)
    variables = "\n".join(
        f"  --{name.replace('_', '-')}: {colors[role]};"
        for name, role in gtk_roles.items()
        if not name.startswith("theme_")
    )
    atomic_write(state / "gtk4.css", gtk_css + ":root {\n" + variables + "\n}\n")
    atomic_write(state / "zed.json", json.dumps(zed_theme(theme), indent=2) + "\n")
    atomic_write(state / "helix.toml", helix_theme(theme))
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
