# User-facing packages may move quickly without changing the NixOS package set.
# Remove a name here to fall back to stable everywhere this package set is used.
{ pkgs, inputs }:
let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = pkgs.config.allowUnfree or false;
  };
  unstableNames = [
    # Desktop apps, editors, terminal, and launchers.
    "vivaldi"
    "zed-editor"
    "helix"
    "neovim"
    "kitty"
    "quickshell"
    "walker"
    "elephant"
    "zoom-us"
    "pear-desktop"
    "zathura"
    "prismlauncher"
    "codex"
    "fastfetch"
    # Fish stays stable: the release NixOS/HM modules use its Python completion
    # generator, which unstable Fish removed. Keep vendor/man-page completions.
    "git"
    "ripgrep"
    "fd"
    "fzf"
    "playerctl"

    # Keep compiler companions and the Rust source tree on the same input.
    "gcc"
    "gfortran"
    "gnumake"
    "clang"
    "clang-tools"
    "rustc"
    "cargo"
    "rust-analyzer"
    "rustfmt"
    "clippy"
    "rustPlatform"
    "zig"
    "zls"
    "nodejs"
    "python3"
    "openblas"
    "cmake"
    "ninja"
    "bear"
    "fortran-fpm"

    # Shared editor language servers and formatters.
    "fortls"
    "fprettify"
    "pyright"
    "ruff"
    "lua-language-server"
    "typescript-language-server"
    "texlab"
    "marksman"
    "taplo"
    "nil"
    "nixfmt"
    "stylua"
    "tree-sitter"
    "neocmakelsp"
    "cmake-format"
    "vscode-langservers-extracted"
    "yaml-language-server"
    "bash-language-server"
    "shfmt"
    "shellcheck"
  ];
in
{
  inherit unstableNames;
  # A shallow selection, not an overlay: stable services and their dependency
  # graphs never get rebuilt against these user-facing toolchains or libraries.
  packages = pkgs // pkgs.lib.genAttrs unstableNames (name: unstable.${name});
}
