{ pkgs, ... }:
let
  upstream = pkgs.fetchurl {
    url = "https://api.zed.dev/extensions/material-icon-theme/1.3.2/download";
    hash = "sha256-5PeeyYSpaYP7ZNe1NvKToC3AuQY1j0G16sYT1ttMvCo=";
    name = "zed-material-icon-theme-1.3.2.tar.gz";
  };
  icons = pkgs.runCommand "zed-material-icons-monochrome" { } ''
    mkdir -p "$out"
    tar -xzf ${upstream} -C "$out"
    chmod -R u+w "$out"
    ${pkgs.python3}/bin/python3 ${./monochrome_icons.py} "$out" '#8a98aa'
  '';
in
{
  # Register the pinned icon theme locally so updates retain the uniform palette.
  xdg.dataFile."zed/extensions/installed/material-icon-theme".source = icons;
  programs.zed-editor.userSettings.auto_update_extensions.material-icon-theme = false;
}
