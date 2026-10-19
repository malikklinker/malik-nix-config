# NixOS Zephyrus configuration

Niri is the temporary default at the greetd/tuigreet login screen. Hyprland
remains installed and is the intended main desktop once GPU startup is verified.
Press F3 at login to select it manually. Session remembering is disabled for now
so an old Hyprland selection cannot override the Niri default.

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

Hyprland 0.56.2, Aquamarine 0.15.1, portal 1.4.1, and Mesa 26.2.5 now come
from a separate locked `nixpkgs-unstable` input. The rest of the system, including
Linux 6.18 and NVIDIA, remains on the existing stable pin. Matching 64-bit and
32-bit Mesa packages are used. AMD-only Hyprland may not drive connectors wired
to NVIDIA.

Aquamarine includes the HX 370 panel `max_bpc` fallback from upstream PR #316,
so `AQ_NO_ATOMIC` is no longer set. The AMD alias remains. If the new stack still
fails, log out to a text console and test `AQ_NO_ATOMIC=1 start-hyprland` to
compare; collect the full log before treating that workaround as permanent.
Hyprland now uses a validated Lua config in `home/hypr/hyprland.lua`.

Update only the graphics input with:

```sh
nix flake update nixpkgs-unstable
```

Review the resulting versions and rebuild before installing an updated pin.
The graphical greeter investigation and an optional SDDM candidate are documented
in [GREETERS.md](GREETERS.md); the main host still uses tuigreet until that
candidate has been tested.

After booting the new generation, verify:

```sh
readlink -f /dev/dri/amd-igpu
printenv AQ_DRM_DEVICES
# AQ_NO_ATOMIC should be unset:
printenv AQ_NO_ATOMIC || true
systemctl --user status niri walker elephant quickshell polkit-gnome
journalctl --user -b -u niri --no-pager
```

Test Hyprland by selecting it with F3 after logging out of Niri. If it still
hangs, return to a text console with Ctrl+Alt+F2, log in, and collect the latest
`$XDG_RUNTIME_DIR/hypr/*/hyprland.log` and `journalctl -b -k`. The last log line
alone does not identify which backend operation is blocked. Startup on the
physical GPU still needs testing; config validation cannot establish that.

Keep the laptop in Hybrid mode for NVIDIA offload, and use
`nvidia-offload prismlauncher` for the RTX. `services.asusd` provides `asusctl`;
check `asusctl armoury list` before changing model-specific GPU controls.
The kernel remains pinned to Linux 6.18 for NVIDIA build compatibility.

See [AUDIT.md](AUDIT.md) for findings and validation status.
