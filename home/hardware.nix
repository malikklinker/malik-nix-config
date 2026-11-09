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
  networkAgent = pkgs.writeShellApplication {
    name = "desktop-network-agent";
    runtimeInputs = [
      (pkgs.python3.withPackages (python: [
        python.dbus-python
        python.pygobject3
      ]))
    ];
    text = ''
      exec python3 ${./hardware/network_agent.py} "$@"
    '';
  };
in
{
  home.packages = [
    control
    networkAgent
    pkgs.geteduroam
  ];
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
