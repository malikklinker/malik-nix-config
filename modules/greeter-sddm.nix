# Main graphical login: SDDM with KWin Wayland and Catppuccin, without enabling
# the Plasma desktop.
{ pkgs, ... }:

let
  catppuccinTheme = pkgs.catppuccin-sddm.override {
    flavor = "mocha";
    accent = "mauve";
    font = "JetBrainsMono Nerd Font";
    fontSize = "12";
  };
in

{
  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      theme = "catppuccin-mocha-mauve";
      settings.Users.RememberLastSession = false;
      extraPackages = [
        catppuccinTheme
        pkgs.kdePackages.qtsvg
        pkgs.kdePackages.qtvirtualkeyboard
      ];
    };
  };
  environment.systemPackages = [ catppuccinTheme ];
}
