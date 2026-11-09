{ lib, pkgs, ... }:
let
  tools = {
    fortls = "${pkgs.fortls}/bin/fortls";
    clangd = "${pkgs.clang-tools}/bin/clangd";
    pyright = "${pkgs.pyright}/bin/pyright-langserver";
    rustAnalyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
    rustSrc = "${pkgs.rustPlatform.rustLibSrc}";
    zls = "${pkgs.zls}/bin/zls";
    zig = "${pkgs.zig}/bin/zig";
    typescript = "${pkgs.typescript-language-server}/bin/typescript-language-server";
  };
in
{
  # Doom itself and packages.el stay user-owned; language modules are reproducible.
  home.packages = with pkgs; [
    zig
    zls
    typescript-language-server
  ];
  home.file.".doom.d/init.el".source = ./doom/init.el;
  home.file.".doom.d/config.el".source = ./doom/config.el;
  home.file.".doom.d/languages.el".text = lib.replaceStrings (map (name: "@${name}@") (
    builtins.attrNames tools
  )) (builtins.attrValues tools) (builtins.readFile ./doom/languages.el);
  home.file.".doom.d/themes/desktop-theme.el".source = ./doom/themes/desktop-theme.el;
}
