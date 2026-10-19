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

## Desktop controls

Both sessions use Super+Return for Kitty, Super+Space for Walker, Super+Q to
close a window, Super+F for fullscreen, Super+V for floating, and Super+L to lock.
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
it to toggle mute. Volume follows the default audio output.

Hyprland's session is managed by UWSM; Home Manager's separate Hyprland systemd
integration is disabled. Walker and Elephant start after `graphical-session.target`
so they inherit the compositor's display environment. Starting Elephant earlier
can make app launches silently fail because its child processes have no display.

Kitty, Walker, and the desktop use Catppuccin Mocha and JetBrainsMono Nerd Font.
Run `ff` for Fastfetch. `nvim` starts LazyVim with Nix, Python, TeX, and Markdown
integrations; plugins download on first use. Coursework tools include TeX Live,
latexmk, biber, chktex, Zathura, and SymPy.

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
