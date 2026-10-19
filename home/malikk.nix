{ inputs, pkgs, ... }:

let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sessionApp = pkgs.writeShellScriptBin "session-app" ''
    if uwsm check is-active >/dev/null 2>&1; then
      exec uwsm app -- "$@"
    else
      exec "$@"
    fi
  '';
in

{
  home.username = "malikk";
  home.homeDirectory = "/home/malikk";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.fish.enable = true;

  programs.codexDesktopLinux.enable = true;

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
  programs.swaylock.enable = true;
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
  services.network-manager-applet.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # UWSM owns session activation and imports the compositor environment.
    systemd.enable = false;
    # The NixOS module owns the matched compositor and portal packages.
    package = null;
    portalPackage = null;
    extraConfig = builtins.readFile ./hypr/hyprland.lua;
  };

  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      enable_audio_bell = false;
      window_padding_width = 8;
      background_opacity = "0.94";
    };
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "file";
        source = "${./fastfetch/cat.txt}";
        color = {
          "1" = "#cba6f7";
          "2" = "#f5c2e7";
          "3" = "#f38ba8";
          "4" = "#cba6f7";
        };
        padding.right = 2;
      };
      display = {
        separator = " 󰁔 ";
        color.keys = "#cba6f7";
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "de"
        "wm"
        "terminal"
        "break"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "break"
        "colors"
      ];
    };
  };
  home.shellAliases.ff = "fastfetch";

  # LazyVim's plugin manager downloads plugins into the user's writable data
  # directory on first launch; the tracked Lua config remains in this repo.
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
  xdg.configFile."nvim/lua/config/lazy.lua".source = ./nvim/lua/config/lazy.lua;
  xdg.configFile."nvim/lua/config/options.lua".source = ./nvim/lua/config/options.lua;
  xdg.configFile."nvim/lua/plugins/catppuccin.lua".source = ./nvim/lua/plugins/catppuccin.lua;

  programs.quickshell = {
    enable = true;
    activeConfig = "mocha";
    configs.mocha = ./quickshell;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };

  services.elephant.enable = true;

  # Wait for the compositor to publish its display environment before starting
  # launchers, and stop them on logout so the next session gets fresh values.
  systemd.user.services = {
    elephant.Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    walker.Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    quickshell.Unit.PartOf = [ "graphical-session.target" ];
  };

  services.walker = {
    enable = true;
    systemd.enable = true;
    settings = {
      app_launch_prefix = "session-app ";
      theme = "mocha";
      close_when_open = true;
      force_keyboard_focus = true;
      selection_wrap = true;
      placeholders.default = {
        input = "Search apps, files, or calculate…";
        list = "No matches";
      };
      placeholders.desktopapplications = {
        input = "Launch an app…";
        list = "No applications found";
      };
      providers = {
        default = [
          "desktopapplications"
          "calc"
          "runner"
          "files"
        ];
        empty = [ "desktopapplications" ];
        max_results = 40;
        prefixes = [
          { prefix = ">"; provider = "runner"; }
          { prefix = "/"; provider = "files"; }
          { prefix = "="; provider = "calc"; }
        ];
      };
    };
    theme = {
      name = "mocha";
      style = ''
        @define-color window_bg_color #1e1e2e;
        @define-color accent_bg_color #cba6f7;
        @define-color theme_fg_color #cdd6f4;
        @define-color error_bg_color #f38ba8;
        @define-color error_fg_color #1e1e2e;

        * {
          all: unset;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
        }

        .box-wrapper {
          background: @window_bg_color;
          color: @theme_fg_color;
          border: 2px solid @accent_bg_color;
          border-radius: 10px;
          padding: 12px;
        }

        .input {
          background: #313244;
          color: @theme_fg_color;
          caret-color: #f5c2e7;
          border: 1px solid #45475a;
          border-radius: 6px;
          padding: 10px 12px;
        }

        .list {
          color: @theme_fg_color;
        }

        .item-box {
          border-radius: 6px;
          padding: 8px;
        }

        child:selected .item-box {
          background: #45475a;
          border-left: 3px solid #f5c2e7;
        }

        .item-text {
          color: @theme_fg_color;
        }

        .item-subtext,
        .placeholder,
        .elephant-hint {
          color: #a6adc8;
        }

        scrollbar {
          opacity: 0;
        }
      '';
    };
  };

  home.packages = with pkgs; [
    sessionApp
    librewolf
    # Keep Codex current without moving the stable system package set.
    unstablePkgs.codex
    unzip

    # Coding and terminal basics
    neovim
    git
    ripgrep
    fd
    fzf
    direnv
    nixd
    nil
    pyright
    ruff
    texlab
    gcc
    gnumake
    lazygit
    lua-language-server
    nixfmt
    stylua
    tree-sitter
    nodejs

    # Math coursework and LaTeX
    texlive.combined.scheme-medium
    texlivePackages.latexmk
    biber
    texlivePackages.chktex
    zathura
    python3Packages.sympy

    # Launch with `nvidia-offload prismlauncher` when you want the RTX 4070.
    prismlauncher

    # Small Wayland desktop essentials
    xwayland-satellite
    networkmanagerapplet
    wl-clipboard
    grim
    slurp
    xdg-utils
  ];
}
