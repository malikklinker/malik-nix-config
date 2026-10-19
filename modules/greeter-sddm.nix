# Optional graphical-login candidate. Not imported by the main host config.
# Match the working Plasma installation's SDDM/KWin/Breeze setup without
# enabling the Plasma desktop. See GREETERS.md before applying.
{ lib, pkgs, ... }:

{
  services.greetd.enable = lib.mkForce false;
  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      theme = "breeze";
      settings.Users.RememberLastSession = false;
      # Breeze needs these even when the full Plasma module is not enabled.
      extraPackages = with pkgs.kdePackages; [
        breeze-icons
        kirigami
        libplasma
        plasma5support
        qtsvg
        qtvirtualkeyboard
      ];
    };
  };
  environment.systemPackages = with pkgs.kdePackages; [
    # The Breeze SDDM theme is shipped by plasma-desktop, not plasma-workspace.
    plasma-desktop
    breeze
  ];
}
