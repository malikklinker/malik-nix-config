{ config, pkgs, ... }:
let
  python = pkgs.python3.withPackages (p: [ p.pygobject3 ]);
  installerSource = pkgs.replaceVars ./updates/install.py {
    nixEnv = "${pkgs.nix}/bin/nix-env";
  };
  installer = pkgs.writeShellApplication {
    name = "os-update-install";
    runtimeInputs = [ pkgs.python3 pkgs.systemd ];
    text = ''
      exec systemd-inhibit --what=shutdown:sleep --mode=block \
        --who="OS Updates" --why="Installing a NixOS boot generation" \
        python3 ${installerSource} "$@"
    '';
  };
  settings = pkgs.writeText "os-update-settings.json" (builtins.toJSON {
    source = "${config.home.homeDirectory}/malik-nix-config";
    host = "zephyrus";
    nix = "${pkgs.nix}/bin/nix";
    pkexec = "/run/wrappers/bin/pkexec";
    installer = "${installer}/bin/os-update-install";
    systemctl = "${pkgs.systemd}/bin/systemctl";
  });
  updater = pkgs.stdenvNoCC.mkDerivation {
    pname = "os-update";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.makeWrapper pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk3 ];
    installPhase = ''
      mkdir -p "$out/bin" "$out/lib/os-update"
      cp ${./updates/app.py} "$out/lib/os-update/app.py"
      cp ${./updates/backend.py} "$out/lib/os-update/backend.py"
      makeWrapper ${python}/bin/python3 "$out/bin/os-update" \
        --add-flags "$out/lib/os-update/app.py --config ${settings}"
      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/os-update.desktop" <<EOF
      [Desktop Entry]
      Type=Application
      Name=OS Updates
      Comment=Build, review, and install NixOS updates for the next boot
      Exec=$out/bin/os-update
      Icon=system-software-update
      Terminal=false
      Categories=System;Settings;
      EOF
    '';
  };
in
{
  home.packages = [ updater ];
}
