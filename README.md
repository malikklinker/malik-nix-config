# NixOS Zephyrus configuration

Personal NixOS and Home Manager configuration for an ASUS Zephyrus laptop:
Hyprland, a Quickshell panel, shared desktop palettes, and a custom SDDM/GRUB
theme, plus development tools and laptop controls.

**Using this on another machine:** this is a working personal configuration,
not a general installer. Replace the hardware configuration and review the
disk UUIDs in `hosts/zephyrus/hardware-configuration.nix`, `modules/power.nix`,
and `modules/bootloader.nix` before applying it. Adapt the username, home paths,
GPU configuration, and timezone to your system. The disk layout is unencrypted;
do not copy it as an encryption setup. Never put passwords, tokens, Wi-Fi
profiles, or private keys in this checkout: flake sources can enter the Nix
store. There is no repository-wide license file; individual license declarations
and the licenses of upstream packages and assets still apply.

SDDM with KWin Wayland and a custom Midnight Blue theme is the default
login screen. Hyprland (UWSM-managed) is the desktop session.
Session remembering is disabled. The former `zephyrus-sddm` output is an alias
for the main `zephyrus` configuration.

The greeter matches GRUB's Midnight Blue mountain backdrop, with a large clock,
blue and lavender accents, and a translucent sign-in panel. JetBrains Mono fonts
are bundled with the theme. Password entry is focused initially; Enter signs in,
Escape clears the password, and Tab moves between controls. The session picker
offers the installed Hyprland session entries. Caps Lock and failed authentication are shown in place;
restart and power-off buttons ask for confirmation. Theme sources live in
`modules/sddm/`, packaged by `modules/greeter-sddm.nix`.

Fish is Malik's login shell, with Home Manager supplying its aliases and setup.
New logins and terminals use Fish after the system configuration is applied.
Fish uses its bundled Scales prompt and runs Fastfetch as the greeting in
interactive terminals, with a custom starry-sky ASCII scene.
Noninteractive commands stay quiet.

Git's global settings are writable in `~/.gitconfig`, so commands such as
`git config --global user.name "Your Name"` work normally. Home Manager creates
this file only when it is absent and preserves it across rebuilds. Declarative
Git settings still come from the managed `~/.config/git/config`, including the
default identity `Malik Klinker <235598266+malikklinker@users.noreply.github.com>`.

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
working generation available in the boot menu for recovery. After login, later
updates can use `nixos-rebuild switch` with the same flake argument.

## Boot menu

GRUB uses a custom Midnight Blue theme with the desktop's mountain wallpaper,
JetBrains Mono, and blue/lavender accents. The menu stays visible for five
seconds; any navigation key interrupts the countdown. Older NixOS generations
are available in the generation submenu (up to ten retained menu entries).
The theme lives in `modules/grub/theme.txt`; bootloader settings and font
generation live in `modules/bootloader.nix`.

The next `nixos-rebuild boot` installs GRUB as the EFI bootloader. The existing
systemd-boot EFI executable and its entries stay on the EFI partition; select
**Previous systemd-boot menu** in GRUB to use them, or select **Linux Boot
Manager** from the laptop's firmware boot menu if GRUB itself fails to open.
These existing entries are a migration fallback and are not updated by future
GRUB rebuilds. **UEFI firmware settings** opens the firmware setup screen.
The boot menu palette is fixed at build time; `theme-set` changes the desktop.

## OS updates

Open Quickshell's **power menu → OS Updates…**, launch **OS Updates** from Walker,
or run `os-update`. **Apply local changes** builds this
checkout with its existing package pins, including new and uncommitted files.
**Prepare OS update** refreshes all flake inputs in a separate snapshot before
building. The live log shows each phase and a package comparison with the booted
system. Neither action installs anything by itself.

After reviewing the build, select **Install for next boot** and authenticate in
the administrator dialog. Installation uses the already-built snapshot; it does
not restart the current desktop or display manager. The updater then asks whether
to restart now or later. Save your work before accepting. Older boot generations
remain available in GRUB; a failed bootloader installation attempts to restore
the previous boot profile and bootloader configuration.

Successful input updates copy the new `flake.lock` back into this checkout only
if its original lock has not changed, with a backup at
`~/.local/state/os-update/flake.lock.before-update`. Builds, their GC roots,
prepared locks, and the log are kept under `~/.local/state/os-update/`; the latest
candidate can be installed after reopening the app. A failed build leaves the
checkout's pins and previously prepared candidate intact. These are manual
updates; there is no background schedule or automatic reboot.

**Preview login screen** opens the installed SDDM theme in test mode; close that
window to return to your desktop. SDDM loads the theme through an immutable store
path so new revisions cannot reuse bytecode cached for the previous revision's
`/run/current-system` URL. This matters because Nix store files have normalized
timestamps, which can otherwise let Qt display old QML after a rebuild.

The updater is initially available through the user Nix profile. After booting
the generation that installs it through Home Manager, remove that temporary copy
with `nix profile remove os-update`. Configuration lives in `home/updates.nix`,
with the application and failure-recovery checks in `home/updates/`.

## Stable system, current user tools

`packages/user.nix` is the central list of packages that follow the locked
`nixos-unstable` input. Removing a name from that list falls back to stable.
The selection is passed explicitly to Home Manager and the login shell/scientific
Python environment; it does not override the system's dependency graph.

| Track unstable | Keep stable |
| --- | --- |
| Vivaldi, Zed, Helix, Neovim, Kitty, Zoom, Pear, Zathura, Prism Launcher | Kernel 6.18, NVIDIA, Mesa (64/32-bit), firmware |
| Quickshell, Walker + Elephant, Git, Codex, Fastfetch, CLI search tools | SDDM + KWin, GRUB, screen locker; Fish for completion-generator compatibility |
| GCC/GFortran, Clang/clangd, Rust/Cargo/Clippy/rustfmt/rust-analyzer + Rust sources, Zig + ZLS | PipeWire/WirePlumber, NetworkManager, Bluetooth, power/hibernate services, system Python used by service helpers |
| Node.js, scientific Python + NumPy/SciPy/pandas/Matplotlib/SymPy, CMake/Ninja, language servers and formatters | TeX Live distribution and document tooling; `texlab` itself follows unstable |

Hyprland, its portal, and UWSM retain their existing matched unstable packages.
Compiler companions and the scientific Python environment come from the same
input so their versions and native dependencies stay aligned. Stable drivers
remain usable by newer user applications; system-wide Mesa is not replaced.

**Prepare OS update** refreshes both inputs in a snapshot. Switching a package to
unstable alone uses the already locked revision; it does not fetch a newer pin.
Use **Apply local changes** to install a policy change with the current pins.
Review temporary user-profile installs after the system generation is active:
`type -a zeditor hx` and `nix profile list` reveal copies that can shadow Home
Manager's packages. Remove the temporary `zed-editor` and `helix` profile entries
after their managed replacements are installed.

## File manager

Thunar is the default folder handler. Open it from Walker, run `thunar`, or press
**Super+E** in Hyprland. GVfs provides trash and remote filesystem support;
Tumbler generates thumbnails. The archive plugin uses File Roller to create and
extract archives, and the volume manager handles removable media.

Thunar follows `theme-set`, with a dark sidebar, subdued selections, rounded
toolbar buttons, and Papirus Dark icons. The layout uses breadcrumbs, a compact
icon grid, and a menu button instead of the menu bar (Alt reveals it).

The initial live install uses the user Nix profile. After applying the system
configuration, remove those temporary copies with
`nix profile remove thunar-with-plugins file-roller tumbler papirus-icon-theme theme-set`.

## Zoom

Zoom uses the pinned unstable package set for Linux dark-mode support (7.2+).
It is included in Home Manager. Launch **Zoom Workplace** from Walker or run
`zoom`; meeting links can open the desktop client through its `zoommtg` handler.
PipeWire and the Hyprland desktop portal provide audio and screen sharing.
Before a meeting, use Zoom's audio and video settings to check your devices.

The initial live install uses the user Nix profile so it is available without a
system rebuild. After a successful `nixos-rebuild switch` installs the Home
Manager package, remove the duplicate with `nix profile remove zoom`.

## YouTube Music

Pear Desktop is installed from the pinned unstable package set. Launch **Pear
Desktop** from Walker or run `pear-desktop`, then sign in to YouTube Music.
Its custom CSS follows `theme-set`: matching surfaces, accent-colored controls,
subtle artwork rounding, and a compact scrollbar. Reload Pear with Ctrl+R after
changing palettes to load the updated CSS.

Synced lyrics, precise volume, and MPRIS controls are enabled initially. Playback
keys work in Hyprland, preferring Pear over other media players.
The in-app menu keeps settings accessible without a separate window titlebar.
Preferences remain writable; rebuilds preserve plugin choices and account data.
Application updates come through Nix.

The initial live install uses the user Nix profile so it works without sudo.
After the next successful `nixos-rebuild switch`, remove those temporary copies
with `nix profile remove pear-desktop playerctl theme-set` and remove the
temporary GC root `~/.local/state/pear-desktop-config`. Home Manager then owns
the packages and theme configuration completely.

## Performance after a drained battery

UPower requests hibernation at 10% while discharging. Desktop notifications at
25% and 15% stay visible until dismissed; a final warning appears at 10%.
Warnings reset when AC power returns or the battery recovers above 25%.
The warning service runs in both desktop sessions; UPower performs the critical
action system-wide, even without a logged-in desktop.

Resume uses the existing 33.5 GiB swap partition, with NVIDIA video memory
preservation enabled. Hibernation writes the image then powers off. After
applying this configuration, reboot once to load its resume configuration.
Save work and test `systemctl hibernate` on AC power before relying on automatic
hibernation; a successful build cannot verify a physical hibernate/resume cycle.

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

Vivaldi is the default web browser, with native Wayland support and Widevine.
Its UI uses the shared desktop palette, JetBrainsMono Nerd Font,
square controls, and an accent line on the active tab. The stylesheet is bundled
with the desktop theme assets and loaded automatically. After changing
palettes with `theme-set`, fully quit and reopen Vivaldi to refresh its colors.
LibreWolf profile data is left in place; use Vivaldi's import tools for bookmarks
if needed. Browser styling lives in `home/vivaldi/desktop.css`.

Hyprland uses Super+Return for Kitty, Super+Space for Walker, Super+Q to
close a window, Super+F for fullscreen, Super+V for floating, and Super+L to lock.
In Hyprland, Super+arrows focuses the neighboring window in that direction.
Super+Shift+S selects a screenshot region and copies it to the clipboard.

Walker supports app search, `>` for commands, `/` for files, and `=` for maths.
Elephant supplies its providers. The Quickshell panel, notifications, PolicyKit
agent, and NetworkManager applet are available in Hyprland. Run `nmtui`
for Wi-Fi or `nm-connection-editor` for connection profiles, and
`blueman-manager` for Bluetooth.
The configuration does not currently provide automatic idle locking.

The Quickshell panel has clickable workspace numbers: Hyprland keeps 1–5
visible. The current
workspace is highlighted, and occupied workspaces have brighter numbers.
Scroll over the volume indicator to adjust it in 5% steps (up to 100%), or click
it to toggle mute. Volume follows the default audio output. The keyboard volume
keys use the same 5% steps; volume-up also unmutes. The microphone mute key
toggles the default input. These keys work in Hyprland, including while
locked. The bar keeps the percentage visible when muted (with a red mute icon).

Click the sun/brightness percentage beside the volume indicator for laptop
controls. The screen slider controls the AMD panel (1–100%); keyboard lighting
snaps to the hardware's four levels: Off, Low, Medium, and High. Scroll over the sun for 5%
screen brightness steps. Screen and keyboard brightness keys work in
Hyprland, including while locked.

Wi-Fi and Bluetooth share two compact rows at the bottom of that same laptop
popup, keeping the bar unchanged. Use On/Off to toggle either radio; click the
Wi-Fi or Bluetooth name to open its own themed popup in place of laptop
controls. Back (or Escape) restores laptop controls; × dismisses the popup.
The Wi-Fi row shows the active connection name. No manager app launches when
opening either panel.

The Wi-Fi popup lists nearby networks with signal strength. Select one to
connect, enter a password, disconnect or forget its saved profile (with a second
confirmation click). Saved profiles reconnect without re-entering credentials.
Selecting an enterprise network such as eduroam also exposes PEAP/TTLS,
inner authentication, identity, optional anonymous identity, CA certificate path
and authentication-server domain fields. Use the values supplied by your home
institution; the popup requires certificate and server-domain verification.
The default CA path is the system certificate bundle. Profiles and credentials
are saved by NetworkManager, with enterprise profiles restricted to your user;
passwords pass to the helper through stdin, never command arguments or this repo.
Institutions requiring client certificates, web enrolment, or other EAP methods
need an externally provisioned profile first. `geteduroam-gui` remains installed
for that optional setup, with institution instructions or
[eduroam CAT](https://cat.eduroam.org/) as alternatives. Such profiles can then
be selected in the popup.

The Bluetooth popup lists saved and discovered devices, with connected devices
first. Opening it scans for 30 seconds; Scan starts another scan. Select a device
to pair and connect, reconnect, disconnect, or forget it. PIN entry, passkey
display and code confirmation stay inside the popup. Only successfully paired
devices are trusted. Closing the popup stops discovery and cancels pending
pairing; no default system pairing agent is replaced.

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
Quickshell, Hyprland, Kitty, Walker, Mako, and open Neovim windows follow
the palette. Neovim also applies the palette to tabs, floating menus, and the
status line. Syntax colors share defaults across legacy highlighting, Tree-sitter,
and LSP semantic tokens. Midnight Blue uses blue keywords/functions, lavender
types/constants, cyan strings, and neutral identifiers. Red, green, and yellow
remain available for diagnostics, Git changes, and mode indicators.
Fastfetch uses the terminal's colors. GTK 3/4 receive palette CSS
and the light/dark preference; some GTK applications need reopening to pick up
changes. SDDM retains its separately configured Midnight Blue login theme.
Windows, Walker, Mako notifications, and Quickshell controls use square corners.
Hyprland uses 3 px inner and 6 px outer gaps.
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

## System Python

System-wide `python` and `python3` include NumPy, Matplotlib, SciPy, pandas,
and SymPy through `userPkgs.python3.withPackages` in `hosts/zephyrus/default.nix`.
This scientific environment follows unstable as one matching Python/package set;
system service helpers retain their stable Python runtimes.
Add shared Python libraries there and rebuild NixOS to install them.

## Helix

Run `hx .` to open the project picker, `hx file` to edit, or `hx --tutor`
for Helix's interactive introduction. The editor follows the shared desktop
palette, including Midnight Blue's blue/lavender syntax and cyan strings.
`theme-set` refreshes open Helix windows automatically. Appearance uses a flat
status line with mode colors, relative line numbers, soft wrapping, and subtle
indent guides. Warnings and errors appear beneath the cursor's line;
buffer tabs and inlay hints are disabled.

Nix, Python (Pyright + Ruff), Fortran, C/C++, Rust, Lua, LaTeX, Markdown,
and TOML use the Nix-managed language tools. Format on save is disabled;
use `:format` when wanted. Space f opens files, Space b switches buffers,
Space / searches the project, Space k shows hover documentation, Space a
opens code actions, Space w saves, and Space q quits. Helix selects text before
acting on it; use `hx --tutor` to learn its editing model.
Settings live in `home/helix.nix`; palette generation lives in
`home/theme/theme_set.py`.

The initial live installation uses the user Nix profile. After a successful
system switch installs the Home Manager configuration, remove the duplicate
package with `nix profile remove helix` and the temporary configuration GC root
`~/.local/state/helix-desktop-config`. The temporary `theme-set` profile package
can also be removed once Home Manager supplies the updated theme integration.

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

Neovim uses a quiet Emacs-style layout: plain line numbers, the desktop syntax palette,
and a flat status line with the file path, modified marker, filetype, and position.
Buffer tabs, indent guides, inline diagnostics, inlay hints, notification popups,
and LSP progress popups are disabled. Shift-h/Shift-l and `[b`/`]b` still switch
buffers. Diagnostics retain gutter signs and underlines; Space c d shows the
message at the cursor, and ordinary errors are available through `:messages`.
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
