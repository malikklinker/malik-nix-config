# Main graphical login: SDDM with KWin Wayland and Breeze, without enabling
# the Plasma desktop.
{ pkgs, ... }:

{
  services.displayManager = {
    defaultSession = "hyprland-uwsm";
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
        # Provides org.kde.breeze.components and the keyboard indicator imported
        # by Breeze. Installing the theme alone does not expose these to SDDM.
        plasma-workspace
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
