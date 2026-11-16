{ lib, userPkgs, ... }:
let
  pkgs = userPkgs;
  tools = {
    fortls = "${pkgs.fortls}/bin/fortls";
    clangd = "${pkgs.clang-tools}/bin/clangd";
    rustAnalyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
    rustSrc = "${pkgs.rustPlatform.rustLibSrc}";
    luaLanguageServer = "${pkgs.lua-language-server}/bin/lua-language-server";
    neocmake = "${pkgs.neocmakelsp}/bin/neocmakelsp";
    taplo = "${pkgs.taplo}/bin/taplo";
    jsonLanguageServer = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
    yamlLanguageServer = "${pkgs.yaml-language-server}/bin/yaml-language-server";
    bashLanguageServer = "${pkgs.bash-language-server}/bin/bash-language-server";
    nil = "${pkgs.nil}/bin/nil";
    pyright = "${pkgs.pyright}/bin/pyright-langserver";
    ruff = "${pkgs.ruff}/bin/ruff";
    texlab = "${pkgs.texlab}/bin/texlab";
    marksman = "${pkgs.marksman}/bin/marksman";
    fprettify = "${pkgs.fprettify}/bin/fprettify";
    clangFormat = "${pkgs.clang-tools}/bin/clang-format";
    rustfmt = "${pkgs.rustfmt}/bin/rustfmt";
    cmakeFormat = "${pkgs.cmake-format}/bin/cmake-format";
  };
in
{
  home.packages = with pkgs; [
    fortls
    gfortran
    fortran-fpm
    (writeShellScriptBin "fpm" ''
      exec ${fortran-fpm}/bin/fortran-fpm "$@"
    '')
    fprettify
    clang-tools
    rust-analyzer
    rustfmt
    clippy
    cmake
    ninja
    bear
    neocmakelsp
    cmake-format
    taplo
    vscode-langservers-extracted
    yaml-language-server
    bash-language-server
    shfmt
    shellcheck
    marksman
  ];
  xdg.configFile."nvim/lua/plugins/development.lua".text = lib.replaceStrings (map (name: "@${name}@")
    (builtins.attrNames tools)
  ) (builtins.attrValues tools) (builtins.readFile ./nvim/lua/plugins/development.lua);
  xdg.configFile."nvim/lua/plugins/quiet.lua".source = ./nvim/lua/plugins/quiet.lua;
  xdg.configFile."nvim/after/ftplugin/fortran.lua".source = ./nvim/after/ftplugin/fortran.lua;
}
