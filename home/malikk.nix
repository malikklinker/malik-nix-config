{ config, inputs, pkgs, ... }:

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
  imports = [ ./theme.nix ];

  home.username = "malikk";
  home.homeDirectory = "/home/malikk";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.fish.enable = true;

  programs.codexDesktopLinux.enable = true;

  xdg.configFile."niri/config.kdl".text = builtins.replaceStrings
    [ "@themePath@" ] [ "${config.xdg.stateHome}/desktop-theme/niri.kdl" ]
    (builtins.readFile ./niri/config.kdl);
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
        type = "builtin";
        source = "nixos";
        color = {
          "1" = "magenta";
          "2" = "blue";
          "3" = "red";
          "4" = "magenta";
        };
        padding.right = 2;
      };
      display = {
        separator = " 󰁔 ";
        color.keys = "magenta";
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
      theme = "desktop";
      hotreload_theme = true;
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
      name = "desktop";
      style = ''@import url("file://${config.xdg.stateHome}/desktop-theme/walker.css");'';
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
