{ config, userPkgs, ... }:

let
  pkgs = userPkgs;
  # Point Vivaldi's native CSS loader at theme-set's generated stylesheet.
  # Change the packaged default, leaving writable profile preferences alone.
  browser =
    (pkgs.vivaldi.override {
      enableWidevine = true;
    }).overrideAttrs
      (old: {
        postInstall = (old.postInstall or "") + ''
          ${pkgs.python3}/bin/python3 - "$out/opt/vivaldi/resources/vivaldi/prefs_definitions.json" <<'PY'
          import json
          import sys
          from pathlib import Path
          path = Path(sys.argv[1])
          prefs = json.loads(path.read_text())
          prefs["vivaldi"]["appearance"]["css_ui_mods_directory"]["default"] = ${builtins.toJSON "${config.xdg.stateHome}/desktop-theme/vivaldi"}
          path.write_text(json.dumps(prefs))
          PY
        '';
      });
in
{
  programs.vivaldi = {
    enable = true;
    package = browser;
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--enable-features=VivaldiCssMods"
    ];
  };

  home.sessionVariables.BROWSER = "vivaldi";
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "vivaldi.desktop" ];
      "application/xhtml+xml" = [ "vivaldi.desktop" ];
      "x-scheme-handler/http" = [ "vivaldi.desktop" ];
      "x-scheme-handler/https" = [ "vivaldi.desktop" ];
    };
  };
}
