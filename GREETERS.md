# Graphical greeter investigation — 2026-10-18

The main `zephyrus` configuration uses **SDDM with KWin on Wayland and the
Catppuccin Mocha theme with mauve accents**, from `modules/greeter-sddm.nix`.
UWSM-managed Hyprland is the default desktop session, with Niri selectable at
login. `zephyrus-sddm` is a
compatibility alias for the same configuration.

The Catppuccin theme replaces Breeze as of 2026-10-19. It uses JetBrainsMono
Nerd Font at size 12 and the theme's bundled background. The theme is installed
in both the system profile and SDDM's extra packages, alongside Qt SVG and
virtual keyboard support.

## Why SDDM first

The running installation has an active display-manager service, and its generated
`/etc/sddm.conf.d/00-nixos.conf` selects SDDM, KWin Wayland, and Breeze. This is
direct evidence that this combination can run on the laptop, although it does
not prove it will work with the changed graphics packages. GDM's past success
does not establish that another greeter will work.

SDDM can launch Niri and Hyprland Wayland sessions. Its greeter can use X11 or a
separate Wayland compositor. The greeter uses stable KWin rather than Hyprland,
so displaying the login screen does not require Aquamarine to initialize.
The initial Breeze setup needed `plasma-workspace` in SDDM's `extraPackages`
for its private QML components; Catppuccin uses its own components instead.
Session remembering is disabled; Hyprland (uwsm-managed) is the default and
both sessions remain selectable.

Upstream still labels SDDM's Wayland greeter mode experimental. The recommendation
is based on this machine's existing setup, not a blanket claim that Wayland SDDM
is the most reliable choice. It still depends on the kernel, Mesa, DRM devices,
and session handoff working together.

## Alternatives

| Option | Assessment for this machine |
| --- | --- |
| SDDM + KWin + Breeze | First trial: matches the installed greeter stack, uses a different compositor from Hyprland, and has packaged NixOS integration. |
| SDDM on X11 | Useful second trial if KWin greeter startup fails. It can still launch Wayland desktops, but adds an Xorg path and hybrid-GPU selection to troubleshoot. Not enabled in the candidate. |
| ReGreet + Cage | Smaller GTK interface retaining greetd/PAM. Cage is a separate wlroots compositor and avoids Aquamarine, but still introduces another DRM startup path; it is not automatically safer on this panel. |
| ReGreet + Niri | Uses a compositor the user has already run successfully. Needs a separate greeter-only Niri configuration, correct teardown before session launch, and input/login/logout testing. Reasonable alternative if SDDM was among the previously troublesome greeters. |
| GDM | Keep as the known-working fallback if alternatives fail, respecting the preference to avoid it initially. |

ReGreet's documented requirements include D-Bus, AccountsService, GTK, and a
Wayland compositor. Its NixOS module uses D-Bus and Cage by default, including
Cage's VT-switching option. Startup-delay workarounds are documented upstream.
There was a closed keyboard-input report against ReGreet 0.4.0; this is a test
case to cover, not proof that current ReGreet has that bug on this laptop.

## Trial and recovery

Stage the main configuration, including SDDM and Fish, for the next boot:

```sh
sudo nixos-rebuild boot --flake path:/home/malikk/malik-nix-config#zephyrus
```

This installs a boot generation; it does not restart the live login manager.
Reboot when ready, keeping the previous boot generation available in systemd-boot.
Confirm keyboard input, password failure/success, Hyprland launch, logout back to
SDDM, Niri selection, and return from suspend. Start with the internal panel;
then check a connected external monitor.

If the greeter is blank or unresponsive, use Ctrl+Alt+F3 for a console login,
or select the previous generation in systemd-boot. From the console, collect:

```sh
journalctl -b -u display-manager --no-pager
journalctl -b -k --no-pager
```

For recovery, select the previous working generation in systemd-boot. Both
flake output names now select SDDM; neither is a text-greeter fallback.
A successful build does not test physical displays or authentication.

## Sources

- [Catppuccin SDDM theme, previews, and configuration](https://github.com/catppuccin/sddm)
- [SDDM display server and session settings](https://github.com/sddm/sddm/blob/develop/data/man/sddm.conf.rst.in)
- [SDDM project](https://github.com/sddm/sddm)
- [ReGreet setup, requirements, Cage/Niri examples, and troubleshooting](https://github.com/rharish101/ReGreet/blob/main/README.md)
- [Cage compositor](https://github.com/cage-kiosk/cage)
- [Closed ReGreet keyboard report](https://github.com/rharish101/ReGreet/issues/164)

NixOS integration was also checked against the local stable SDDM and ReGreet
modules. The main configuration retains the pinned stable kernel/NVIDIA driver
and Mesa; the Hyprland compositor and portal use unstable.
