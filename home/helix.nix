{ config, userPkgs, ... }:
let
  pkgs = userPkgs;
in
{
  programs.helix = {
    enable = true;
    package = pkgs.helix;
    settings = {
      theme = "desktop";
      editor = {
        line-number = "relative";
        cursorline = false;
        color-modes = true;
        bufferline = "never";
        true-color = true;
        auto-format = false;
        completion-trigger-len = 2;
        popup-border = "all";
        gutters = [
          "diagnostics"
          "spacer"
          "line-numbers"
          "spacer"
          "diff"
        ];
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        statusline = {
          left = [
            "mode"
            "spacer"
            "file-name"
            "file-modification-indicator"
          ];
          center = [ ];
          right = [
            "diagnostics"
            "spacer"
            "version-control"
            "spacer"
            "file-type"
            "spacer"
            "position"
          ];
          separator = "│";
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };
        lsp = {
          display-messages = false;
          display-inlay-hints = false;
        };
        inline-diagnostics.cursor-line = "warning";
        end-of-line-diagnostics = "disable";
        indent-guides.render = true;
        whitespace.render = "none";
        file-picker.hidden = false;
        soft-wrap.enable = true;
      };
      # Practice leaving insert mode before navigating.
      keys.insert = {
        left = "no_op";
        down = "no_op";
        up = "no_op";
        right = "no_op";
      };
      keys.normal = {
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
        space = {
          w = ":write";
          q = ":quit";
        };
      };
    };
    languages = {
      language-server = {
        nil.command = "${pkgs.nil}/bin/nil";
        pyright = {
          command = "${pkgs.pyright}/bin/pyright-langserver";
          args = [ "--stdio" ];
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };
        fortls.command = "${pkgs.fortls}/bin/fortls";
        clangd.command = "${pkgs.clang-tools}/bin/clangd";
        rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        lua-language-server.command = "${pkgs.lua-language-server}/bin/lua-language-server";
        texlab.command = "${pkgs.texlab}/bin/texlab";
        marksman.command = "${pkgs.marksman}/bin/marksman";
        taplo.command = "${pkgs.taplo}/bin/taplo";
      };
      language = [
        {
          name = "nix";
          language-servers = [ "nil" ];
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
        {
          name = "python";
          language-servers = [
            "pyright"
            "ruff"
          ];
          formatter = {
            command = "${pkgs.ruff}/bin/ruff";
            args = [
              "format"
              "--stdin-filename"
              "%{buffer_name}"
              "-"
            ];
          };
        }
        {
          name = "fortran";
          language-servers = [ "fortls" ];
          formatter.command = "${pkgs.fprettify}/bin/fprettify";
        }
        {
          name = "c";
          language-servers = [ "clangd" ];
        }
        {
          name = "cpp";
          language-servers = [ "clangd" ];
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
        }
        {
          name = "lua";
          language-servers = [ "lua-language-server" ];
          formatter.command = "${pkgs.stylua}/bin/stylua";
          formatter.args = [ "-" ];
        }
        {
          name = "latex";
          language-servers = [ "texlab" ];
        }
        {
          name = "markdown";
          language-servers = [ "marksman" ];
        }
        {
          name = "toml";
          language-servers = [ "taplo" ];
        }
      ];
    };
  };
  xdg.configFile."helix/themes/desktop.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/desktop-theme/helix.toml";
}
