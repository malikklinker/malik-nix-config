# NixOS Zephyrus configuration

SDDM with KWin Wayland and Catppuccin Mocha (mauve accents) is the default
login screen. Hyprland (UWSM-managed) is the default desktop session; Niri
remains selectable.
Session remembering is disabled. The former `zephyrus-sddm` output is an alias
for the main `zephyrus` configuration.

The Catppuccin theme is installed with SDDM's Qt SVG and virtual keyboard
dependencies. The greeter uses JetBrainsMono Nerd Font at size 12.

Fish is Malik's login shell, with Home Manager supplying its aliases and setup.
New logins and terminals use Fish after the system configuration is applied.
Fish uses its bundled Scales prompt and runs Fastfetch as the greeting in
interactive terminals, with a custom starry-sky ASCII scene.
Noninteractive commands stay quiet.

## Apply on this laptop

The hardware configuration matches the existing **unencrypted Btrfs** root,
`home` and `nix` subvolumes, FAT32 EFI partition, and swap partition. It uses the
UUIDs from `/etc/nixos/hardware-configuration.nix`. It contains no LUKS mapping.
Do not format or decrypt anything: the installed disk is already unencrypted.
Regenerate the hardware configuration if installing on another disk or machine.

From this checkout, build and install a generation for the next boot:

```sh
sudo nixos-rebuild boot --flake path:/home/malikk/malik-nix-config#zephyrus
```

The explicit `path:` includes new files even before they are added to Git.
Reboot when ready; `boot` leaves the running desktop alone. Keep the previous
working generation available in systemd-boot for recovery. After login, later
updates can use `nixos-rebuild switch` with the same flake argument.

## Performance after a drained battery

On October 21, the CPU stayed near 600 MHz under load after the battery died,
including during a 2 minute 6 second boot. Temperatures were cool and memory
and disk space were available. Reconnecting the charger after a 10 second
disconnect restored boosting to 5.15 GHz; the same one-million-iteration
PBKDF2-SHA256 probe fell from 5.52 seconds to 0.103 seconds. Cycling the firmware
profile alone had not cleared the clamp. If this recurs, reconnect the charger
and check CPU frequency under load before changing graphics settings.

The configuration creates `/etc/asusd` before services start, as the ASUS
daemon's sandbox requires that directory even without configured RON files.
Home Manager preserves colliding files with `.before-home-manager` backups
(numbered if needed), so existing desktop settings do not prevent activation.
Boot time after restoring CPU speed still needs a subsequent boot measurement.

## Desktop controls

Doom Emacs uses the desktop's selected palette, JetBrainsMono Nerd Font,
a constellation dashboard, relative line numbers, and styled Org headings.
Palette changes from `theme-set` appear in Emacs within three seconds.
Home Manager manages `~/.doom.d/config.el` and its custom theme; edit their
sources in `home/doom/`. Doom's `init.el` and `packages.el` stay writable.
Appearance changes need an Emacs restart or `M-x doom/reload`, with no
`doom sync` required. Use `SPC f f` to open a file, `SPC p p` for a project,
`SPC h` for help, and `SPC :` to run a command.

Both sessions use Super+Return for Kitty, Super+Space for Walker, Super+Q to
close a window, Super+F for fullscreen, Super+V for floating, and Super+L to lock.
In Hyprland, Super+arrows focuses the neighboring window in that direction.
Super+Shift+S selects a screenshot region and copies it to the clipboard.
In Niri, use Super+arrows to focus, Super+Shift+arrows to move, Super+1–5 for
workspaces, Super+Shift+1–5 to move columns between workspaces, Print for a
screenshot, Super+Shift+E to log out, and Super+Shift+/ for the shortcut overlay.
Niri workspaces are dynamic: unused higher indices select the last empty one.

Walker supports app search, `>` for commands, `/` for files, and `=` for maths.
Elephant supplies its providers. The Quickshell panel, notifications, PolicyKit
agent, and NetworkManager applet are available across both sessions. Run `nmtui`
for Wi-Fi or `nm-connection-editor` for connection profiles, and
`blueman-manager` for Bluetooth. Niri uses xwayland-satellite for X11 apps.
The configuration does not currently provide automatic idle locking.

The Quickshell panel has clickable workspace numbers: Hyprland keeps 1–5
visible, while Niri shows the focused output's dynamic workspaces. The current
workspace is highlighted, and occupied workspaces have brighter numbers.
Scroll over the volume indicator to adjust it in 5% steps (up to 100%), or click
it to toggle mute. Volume follows the default audio output. The keyboard volume
keys use the same 5% steps; volume-up also unmutes. The microphone mute key
toggles the default input. These keys work in Hyprland and Niri, including while
locked. The bar keeps the percentage visible when muted (with a red mute icon).

Click the sun/brightness percentage beside the volume indicator for laptop
controls. The screen slider controls the AMD panel (1–100%); keyboard lighting
snaps to the hardware's four levels: Off, Low, Medium, and High. Scroll over the sun for 5%
screen brightness steps. Screen and keyboard brightness keys work in both
Hyprland and Niri, including while locked.

“Match keyboard to theme” applies the selected palette's accent as a static
keyboard color, at login and on palette changes. It preserves the chosen
keyboard brightness, including off. The toggle persists; disabling it leaves
the current color in place so other ASUS lighting effects can be selected.
Quiet, Balanced, and Performance buttons change the current firmware power
profile. ASUS control still switches profiles on charger connection changes.
The panel reports command failures and unavailable hardware directly.
The lid's Slash lighting is disabled persistently, including boot, shutdown,
sleep, battery-warning, and lid-closed animations.

The shared CLI is `desktop-hardware`: use `status`, `screen 60`, `keyboard 2`,
`profile balanced`, `theme-sync on`, or `sync`. ASUS controls use this installed
version's syntax: `asusctl aura effect static -c 8aafd0` for color and
`asusctl leds set med` for keyboard brightness.

Hyprland's session is managed by UWSM; Home Manager's separate Hyprland systemd
integration is disabled. Walker and Elephant start after `graphical-session.target`
so they inherit the compositor's display environment. Starting Elephant earlier
can make app launches silently fail because its child processes have no display.

Catppuccin Mocha is the default desktop palette, with JetBrainsMono Nerd Font.
Click the flower icon beside the hostname in Quickshell for a searchable
popup with color swatches, or run `theme-set` to open it. Use `theme-set nord`,
`theme-set mocha`, `theme-set latte`, or another name from `theme-set --list`
to switch directly. The custom **Midnight Blue** preset (`theme-set midnight-blue`)
uses near-black surfaces with muted blue and lavender accents. `theme-set --current` prints the current selection.

Tinty applies the bundled Base16 palettes offline; switching needs no rebuild
after the initial installation. The selection survives login and rebuilds.
Quickshell, Hyprland/Niri, Kitty, Walker, Mako, and open Neovim windows follow
the palette. Neovim also applies the palette to tabs, floating menus, and the
status line. Syntax colors share defaults across legacy highlighting, Tree-sitter,
and LSP semantic tokens. Midnight Blue uses blue keywords/functions, lavender
types/constants, cyan strings, and neutral identifiers. Red, green, and yellow
remain available for diagnostics, Git changes, and mode indicators.
Fastfetch uses the terminal's colors. GTK 3/4 receive palette CSS
and the light/dark preference; some GTK applications need reopening to pick up
changes. SDDM retains its separately configured Catppuccin Mocha login theme.
Windows, Walker, Mako notifications, and Quickshell controls use square corners.
Hyprland uses 3 px inner and 6 px outer gaps; Niri uses 6 px gaps.
Hyprland’s background logo and splash text, including Hyprpaper’s splash,
are disabled.
Hyprland uses the standard Adwaita arrow cursor at size 24. Hyprpaper displays
a dark Midnight Blue mountain wallpaper by default, alongside three pinned images from the
[Catppuccin wallpaper collection](https://github.com/zhichaoh/catppuccin-wallpapers)
available in `~/Pictures/Wallpapers`. Run `wallpaper midnight`, `wallpaper mountains`,
`wallpaper yosemite`, or `wallpaper evening` to switch for the current session;
the default returns on the next login. Running `wallpaper` alone selects Midnight Blue.

Run `ff` for Fastfetch. `nvim` starts LazyVim with Nix, Python, TeX, and
Markdown integrations; plugins download on first use. Coursework tools include TeX Live,
latexmk, biber, chktex, Zathura, and SymPy.

## Neovim development tools

Language servers and formatters are installed through Nix. Fortran uses
[fortls](https://fortls.fortran-lang.org/editor_integration.html), with GNU
Fortran, `fpm`, and `fprettify` available in the shell. C/C++ use clangd with
clangd extensions (including source/header switching on Space c h). Rust uses
Rustaceanvim, rust-analyzer, Clippy checks, rustfmt, and crates.nvim for Cargo
dependencies. Lua has lua-language-server and LazyDev for Neovim APIs.
CMake, Make, TOML, JSON, YAML, and shell files also receive appropriate syntax
support; CMake, TOML, JSON, YAML, and shell have language servers.

Use `gd` for definitions, `gr` for references, `K` for hover documentation, and
Space c a for code actions. Space c f formats manually; format on save remains
disabled. Space m g configures CMake, Space m b builds, Space m r runs, and
Space m t selects a target. CMake configuration exports `compile_commands.json`
for clangd; for Make projects, `bear -- make` can generate it instead.
Fortran projects can configure include and source paths in a `.fortls` file.
Fortran uses Neovim's built-in syntax highlighting: Tree-sitter's error recovery
can split identifiers into keyword fragments while a statement is incomplete.
The Fortran parser remains available for structural features, and fortls remains
enabled for completion, navigation, and diagnostics.

Neovim notification popups and LSP progress popups are disabled. Diagnostics
remain visible, and ordinary error messages are available through `:messages`.
Reopen Neovim to load changes; an already running editor keeps its loaded config.

## Graphics recovery and Hyprland

The AMD GPU is at PCI `0000:65:00.0`; NVIDIA is at `0000:64:00.0`. PRIME bus IDs
use decimal bus numbers 101 and 100 respectively. A udev rule exposes AMD as
`/dev/dri/amd-igpu`, independent of boot-dependent card numbering.
`AQ_DRM_DEVICES` uses this alias: PCI by-path names contain colons and cannot be
used directly in Aquamarine's colon-separated device list.

Hyprland 0.56.2, Aquamarine 0.15.1, and portal 1.4.1 come from a separate
locked `nixpkgs-unstable` input. Mesa stays on the stable system package set so
stable graphical clients do not load a driver built against unstable's newer
glibc. Matching stable 64-bit and 32-bit Mesa packages are used. The rest of the
system, including Linux 6.18 and NVIDIA, also remains on the stable pin. AMD-only
Hyprland may not drive connectors wired to NVIDIA.

Aquamarine includes the HX 370 panel `max_bpc` fallback from upstream PR #316,
so `AQ_NO_ATOMIC` is no longer set. The AMD alias remains. If the new stack still
fails, log out to a text console and test `AQ_NO_ATOMIC=1 start-hyprland` to
compare; collect the full log before treating that workaround as permanent.
Hyprland now uses a validated Lua config in `home/hypr/hyprland.lua`.

Update the unstable packages input with:

```sh
nix flake update nixpkgs-unstable
```

This moves Codex CLI as well as the Hyprland stack, so review the resulting
versions and rebuild before installing an updated pin.
The SDDM setup and greeter recovery notes are documented in
[GREETERS.md](GREETERS.md).

After booting the new generation, verify:

```sh
readlink -f /dev/dri/amd-igpu
printenv AQ_DRM_DEVICES
# AQ_NO_ATOMIC should be unset:
printenv AQ_NO_ATOMIC || true
systemctl --user status wayland-wm@hyprland.desktop walker elephant quickshell polkit-gnome
journalctl --user -b -u wayland-wm@hyprland.desktop --no-pager
```

At SDDM, confirm that Hyprland (uwsm-managed) is selected. If startup hangs,
return to a text console with Ctrl+Alt+F2, log in, and collect the latest
`$XDG_RUNTIME_DIR/hypr/*/hyprland.log` and `journalctl -b -k`. The last log line
alone does not identify which backend operation is blocked. Startup on the
physical GPU still needs testing; config validation cannot establish that.

Keep the laptop in Hybrid mode for NVIDIA offload, and use
`nvidia-offload prismlauncher` for the RTX. `services.asusd` provides `asusctl`;
check `asusctl armoury list` before changing model-specific GPU controls.
The kernel remains pinned to Linux 6.18 for NVIDIA build compatibility.

See [AUDIT.md](AUDIT.md) for findings and validation status.
