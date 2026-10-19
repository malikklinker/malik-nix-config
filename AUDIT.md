# Configuration audit — 2026-10-18

Reviewed the flake and lockfile, host and hardware modules, desktop and NVIDIA
modules, Home Manager applications/services, Quickshell panel, and Neovim config.
Compared disk and GPU settings with this running laptop. Changes are built but
not installed: `sudo` requires an interactive password. See README for the boot
generation installation command.

## Findings addressed

| Area | Finding | Change |
| --- | --- | --- |
| Boot/root | Placeholder LUKS UUID, mapper root, wrong ext4 filesystem, and placeholder EFI UUID could prevent boot. The actual root partition is unencrypted Btrfs. | Imported this machine's generated hardware config, including real root/EFI/swap UUIDs, home/nix subvolumes, initrd drivers, and host platform. No LUKS mapping remains. |
| Login | Tuigreet defaulted to Hyprland; a remembered selection could also override a new default. | Default to `niri-session`, remove session remembering, and explicitly expose installed Wayland sessions in F3. |
| Aquamarine device selection | The PCI by-path string contains colons, which Aquamarine parses as device separators. | Create `/dev/dri/amd-igpu` with a PCI-matched udev rule; export it before compositor startup. |
| Atomic modesetting | User reports a prior workaround for the startup hang. | Set `AQ_NO_ATOMIC=1` temporarily. This is a recovery workaround, not proof of the hang's cause. |
| Hyprland config | Home Manager's 26.05 default generated invalid Lua calls from Hyprlang settings, including `hl.$mod(...)`. | Explicitly generate Hyprlang; the installed Hyprland validator accepts it. |
| Niri usability | No tracked config; compositor defaults did not match installed launcher/terminal. | Add Kitty/Walker/lock, window/workspace, screenshot, and audio bindings. |
| Shared desktop | Panel was attached only to Hyprland and labelled it unconditionally. | Attach panel to the graphical session and use the actual desktop name. |
| Authentication/notifications | No configured graphical PolicyKit agent; Mako launched only in Hyprland. | Enable the PolicyKit agent and D-Bus activated Mako for either compositor. |
| Screen locking | Merely installing swaylock does not express its Home Manager integration. | Enable its module; verified that NixOS supplies the swaylock PAM service. |
| Service lifecycle | Walker, Elephant, and panel could outlive logout with stale session state. | Tie their lifetimes to `graphical-session.target`; enable NetworkManager applet service. |
| X11 applications | Niri needs xwayland-satellite for integrated X11 support. | Install xwayland-satellite, which Niri starts on demand. |
| Documentation | README described encryption installation and Hyprland default rather than this installation. | Replace with machine-specific apply/recovery steps and current session controls. |

## Validation

- Complete `nixosConfigurations.zephyrus.config.system.build.toplevel` build passed,
  including the final shared-service changes. Output is linked at
  `/tmp/zephyrus-system`.
- Evaluated assertions: none failed; configuration warnings: none.
- Niri 26.04 `validate` accepted the new KDL config.
- Hyprland 0.55.4 `--verify-config` accepted the generated Hyprlang config.
- Built udev rules passed the builder's validation (48 files, zero failures).
- Generated fstab matches installed root/EFI/home/nix/swap devices; evaluated
  `boot.initrd.luks.devices` is empty. No partition operations were performed.
- Sysfs confirms NVIDIA at `0000:64:00.0`, AMD at `0000:65:00.0`, and a connected
  internal panel on AMD. Existing PRIME IDs (decimal 100/101) match.
- Linux 6.18.56 and NVIDIA build successfully in the pinned package set.
- `git diff --check` passed.

## Remaining runtime checks and limitations

1. Install the built generation and boot it. Actual initrd/greeter/Niri startup
   cannot be established by evaluation or a build. The current running generation
   is the older Plasma configuration and has not been changed.
2. Try Hyprland from F3 after logging out of Niri. The device-list bug and config
   syntax bug are fixed, but the reported “creating async resource gatherer” hang
   has not been reproduced or confirmed resolved on the physical GPU. If it
   persists, collect the full Hyprland log and kernel journal, not just its last
   line. Previous-boot journal search did not recover the relevant failure.
3. Test suspend/resume, audio, brightness, Wi-Fi/Bluetooth, notifications,
   PolicyKit dialogs, lock/unlock, launcher providers, screen sharing, external
   monitors, and `nvidia-offload prismlauncher` in the new session. AMD-only
   Hyprland may not expose external outputs physically wired to NVIDIA.
4. After stable Hyprland operation, test removing only `AQ_NO_ATOMIC`. Upstream
   discourages disabling atomic modesetting as a permanent default. Restore
   Hyprland as the greeter default only after it works reliably.
5. Automatic idle lock/suspend is not configured. Super+L locks manually. The
   hardware root and swap are unencrypted, matching the requested setup.
6. Git/network are needed for LazyVim's first plugin download. Its plugin lockfile
   lives in user state, so plugins are not reproduced by the Nix flake. The
   flake inputs themselves are pinned; the third-party Codex desktop input is
   included in the successful build but its upstream implementation was not
   independently security-audited.
7. Keep the Linux 6.18 pin until testing a newer NVIDIA/kernel pair. Weekly GC
   removes generations older than 14 days; keep a known working boot generation
   available while testing.

## References

- [Aquamarine environment variables](https://github.com/hyprwm/aquamarine/blob/main/docs/env.md)
- [Upstream report of colon-containing DRM paths](https://github.com/hyprwm/aquamarine/issues/167)
- [Aquamarine atomic modesetting warning](https://wiki.hypr.land/0.52.0/Hypr-Ecosystem/aquamarine/)

Module defaults and Niri session/Xwayland behavior were checked against the
locally cached sources/documentation from the pinned flake inputs.
