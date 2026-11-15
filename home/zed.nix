{ config, userPkgs, ... }:
let
  pkgs = userPkgs;
in
{
  imports = [
    ./zed/fortran.nix
    ./zed/icons.nix
  ];

  programs.zed-editor = {
    enable = true;
    # The application and language tools follow the shared user package policy.
    package = pkgs.zed-editor;
    extensions = [
      "nix"
      "lua"
      "toml"
    ];
    # Keep settings writable so the theme selector and settings UI work.
    userSettings = builtins.fromJSON (builtins.readFile ./zed/settings.json) // {
      lsp = {
        nil.binary = {
          path = "${pkgs.nil}/bin/nil";
          arguments = [ ];
        };
        rust-analyzer.binary = {
          path = "${pkgs.rust-analyzer}/bin/rust-analyzer";
          arguments = [ ];
        };
        clangd.binary = {
          path = "${pkgs.clang-tools}/bin/clangd";
          arguments = [ "--background-index" ];
        };
      };
      languages.Nix = {
        language_servers = [
          "nil"
          "!nixd"
        ];
        formatter = {
          external = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
            arguments = [ ];
          };
        };
      };
    };
    userKeymaps = builtins.fromJSON (builtins.readFile ./zed/keymap.json);
  };

  # theme-set generates this alongside the terminal and desktop colors.
  xdg.configFile."zed/themes/desktop.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/desktop-theme/zed.json";
}
