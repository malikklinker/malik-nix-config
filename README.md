# NixOS laptop configuration

Flake-based NixOS setup for the ASUS ROG Zephyrus G16 (Ryzen AI 9 HX 370,
RTX 4070). Hyprland is the intended default session; Niri is also installed.
Home Manager keeps user applications and coursework tools in the same repo.

## What's included

- AMD integrated graphics for the regular desktop, with NVIDIA PRIME render
  offload available for selected apps such as Prism Launcher. Hyprland is
  pinned to a stable udev alias for the AMD GPU, so it will not initialize the
  NVIDIA GPU as a second compositor device.
- Hyprland and Niri Wayland sessions with a minimal greetd/tuigreet login.
- NetworkManager for Wi-Fi and Blueman for Bluetooth; use `nmtui` in Kitty to
  connect to Wi-Fi and `blueman-manager` to pair Bluetooth devices. For
  eduroam, use the Linux profile generated for your institution by the
  [eduroam Configuration Assistant Tool](https://cat.eduroam.org/); it sets
  the correct certificate and server identity checks. `nm-connection-editor`
  is included for managing or troubleshooting NetworkManager profiles.
- Kitty using Catppuccin Mocha, Fastfetch with a custom Nix flake logo, Walker
  with a matching Mocha theme, a tracked LazyVim starter config, and a small
  Quickshell top bar for Hyprland.
- Prism Launcher, a medium TeX Live set, `latexmk`, `biber`, `chktex`, Zathura,
  and SymPy.
- Full-disk encryption is the recommended install choice. The hardware file is
  an install template and must be updated with the actual disk UUIDs.

Press Super+Space to open Walker. Type an app name to launch it, prefix a query
with `>` to run a command, `/` to search files, or `=` to calculate. Run `ff`
for the custom Fastfetch display. `nvim` starts the tracked LazyVim setup, with
explicit Nix, Python, TeX, and Markdown integrations; LazyVim downloads plugins
into the user's writable data directory on first launch. Kitty uses subtle
transparency with Hyprland blur, and the Kitty and Hyprland accents use
Catppuccin Mocha. The
Quickshell panel starts with Hyprland and can be edited under `home/quickshell`.

## Before installing

1. Boot the NixOS installer in UEFI mode and connect to Wi-Fi or Ethernet.
2. Identify the internal drive with `lsblk`. Back up anything you need: making
   the new partition table erases that drive.
3. Partition the internal drive as GPT with a 1 GiB EFI system partition and a
   remaining Linux partition. Format the EFI partition as FAT32. Encrypt the
   Linux partition with LUKS, open it as `/dev/mapper/cryptroot`, then format
   that mapped device as ext4. Mount it at `/mnt` and mount the EFI partition at
   `/mnt/boot`.
4. Generate the machine config with
   `sudo nixos-generate-config --root /mnt`. Copy the generated
   `/mnt/etc/nixos/hardware-configuration.nix` into
   `hosts/zephyrus/hardware-configuration.nix`. Keep the generated root and EFI
   filesystem declarations, add the LUKS mapping below, and set the root device
   to `/dev/mapper/cryptroot`:

   ```nix
   boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<LUKS-partition-UUID>";
   ```

   Find the LUKS UUID with `sudo cryptsetup luksUUID /dev/<linux-partition>`.
5. Make sure ASUS is in Hybrid mode if you want to use the RTX for selected
   apps: leave `gpu_mux_mode` at `1` (the display stays on the iGPU) and set
   `dgpu_disable` to `0`, then reboot. Check support with
   `asusctl armoury list`; not every model exposes both controls. In the
   installed NixOS system, find the AMD and NVIDIA PCI addresses with
   `lspci -D | grep -E 'VGA|3D|Display'`. Convert each address from
   `0000:BB:DD.F` to NixOS form `PCI:BB@0:DD:F`, converting the bus and device
   hex numbers to decimal. Put those values in `modules/nvidia.nix`.
6. Clone this repo into `/mnt/etc/nixos` (or copy it there), then install with
   `sudo nixos-install --flake /mnt/etc/nixos#zephyrus`. Set the root password
   when prompted. Before rebooting, set the user password with
   `sudo nixos-enter --root /mnt -c 'passwd malikk'`; then log in through the
   greetd screen after the first boot.

The machine-specific hardware file and the NVIDIA PCI ID are necessarily local
to the laptop. The placeholders are deliberate; replace them before
installing. `lspci` in the current environment shows the AMD graphics device
but not the RTX because it is currently disabled. Enable Hybrid mode and reboot
before looking up the Nvidia ID. Hyprland remains pinned to the AMD GPU in
Hybrid mode. Use `nvidia-offload prismlauncher` to start Prism with the RTX
4070; Integrated mode disables the dGPU and therefore cannot run offloaded
apps.

`services.asusd` provides the ASUS control service and CLI. For regular use,
leave the machine in Hybrid mode and let `AQ_DRM_DEVICES` keep Nvidia out of
Hyprland's compositor. If Hybrid mode still causes problems, use Integrated
mode with `asusctl armoury set dgpu_disable 1` and reboot; turn it back on with
`asusctl armoury set dgpu_disable 0` and reboot. The settings depend on what
`asusctl armoury list` reports for this exact laptop. The configuration does
not install the experimental Cardwire dGPU switcher.

## After installation

Clone or pull updates into `/etc/nixos`, then apply them with:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#zephyrus
```

Hyprland starts by default at the greetd screen. Press F3 to choose Niri;
tuigreet remembers the last selected session.
