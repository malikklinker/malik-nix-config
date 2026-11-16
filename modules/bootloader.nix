{ pkgs, ... }:

let
  midnightTheme = pkgs.runCommand "grub-midnight-blue" {
    nativeBuildInputs = [ pkgs.grub2 ];
  } ''
    mkdir -p "$out"
    cp ${./grub/theme.txt} "$out/theme.txt"
    cp ${../home/wallpapers/midnight-blue.png} "$out/background.png"
    for size in 18 24 36; do
      grub-mkfont --size "$size" --output "$out/mono-$size.pf2" \
        ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf
    done
  '';
in
{
  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
    timeout = 5;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      theme = midnightTheme;
      gfxmodeEfi = "1920x1200,1920x1080,1280x800,auto";
      configurationLimit = 10;
      timeoutStyle = "menu";
      # The previous loader remains on the ESP during this migration.
      # Use its existing entries if the new GRUB generation will not boot.
      extraEntries = ''
        menuentry "Previous systemd-boot menu" {
          insmod part_gpt
          insmod fat
          search --no-floppy --fs-uuid --set=esp D970-2AC2
          chainloader ($esp)/EFI/systemd/systemd-bootx64.efi
        }
        menuentry "UEFI firmware settings" {
          fwsetup
        }
      '';
    };
  };
}
