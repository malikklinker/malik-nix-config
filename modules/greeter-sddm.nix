# Main graphical login: custom Midnight Blue SDDM theme on KWin Wayland.
{ pkgs, ... }:

let
  midnightTheme = pkgs.runCommand "sddm-midnight-blue" { } ''
    theme="$out/share/sddm/themes/midnight-blue"
    mkdir -p "$theme"
    cp ${./sddm}/* "$theme/"
    cp ${../home/wallpapers/midnight-blue.png} "$theme/background.png"
    cp ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf "$theme/"
    cp ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Light.ttf "$theme/"
  '';
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
      theme = "midnight-blue";
      settings = {
        Users.RememberLastSession = false;
        # Give each revision a distinct QML URL, independent of the system symlink.
        Theme.ThemeDir = "${midnightTheme}/share/sddm/themes";
      };
      extraPackages = [
        midnightTheme
        pkgs.kdePackages.qtsvg
        pkgs.kdePackages.qtvirtualkeyboard
      ];
    };
  };
  environment.systemPackages = [ midnightTheme ];
}
