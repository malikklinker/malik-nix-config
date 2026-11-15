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
  batteryWarnings = pkgs.writeShellApplication {
    name = "desktop-battery-warnings";
    runtimeInputs = [
      (pkgs.python3.withPackages (python: [ python.dbus-python ]))
      pkgs.libnotify
    ];
    text = ''
      exec python3 ${./hardware/battery.py}
    '';
  };
in
{
  home.packages = [
    control
    networkAgent
    batteryWarnings
    pkgs.geteduroam
  ];
  systemd.user.services.desktop-battery-warnings = {
    Unit = {
      Description = "Persistent low and critical battery notifications";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${batteryWarnings}/bin/desktop-battery-warnings";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
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
