{
  config,
  lib,
  userPkgs,
  ...
}:

let
  pkgs = userPkgs;
  pear = pkgs.pear-desktop;
in
{
  home.packages = [
    pear
    pkgs.playerctl
  ];

  # Electron writes preferences at runtime; keep this file writable and merge
  # our defaults without replacing account data or the user's plugin settings.
  home.activation.pearDesktop = lib.hm.dag.entryAfter [ "desktopTheme" ] ''
    run ${pkgs.python3}/bin/python3 ${./music/configure.py} \
      --config ${lib.escapeShellArg "${config.xdg.configHome}/YouTube Music/config.json"} \
      --theme ${lib.escapeShellArg "${config.xdg.stateHome}/desktop-theme/pear.css"}
  '';
}
