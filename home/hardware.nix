{ pkgs, ... }:
let
  control = pkgs.writeShellApplication {
    name = "desktop-hardware";
    runtimeInputs = [
      pkgs.python3
      pkgs.brightnessctl
      pkgs.asusctl
    ];
    text = ''
      exec python3 ${./hardware/control.py} "$@"
    '';
  };
in
{
  home.packages = [ control ];
  systemd.user.services.desktop-keyboard-theme = {
    Unit = {
      Description = "Match keyboard lighting to the desktop palette";
      After = [ "desktop-theme.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${control}/bin/desktop-hardware sync";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
