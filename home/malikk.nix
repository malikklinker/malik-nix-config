{
  config,
  inputs,
  lib,
  pkgs,
  userPkgs,
  ...
}:

let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Pin the artwork and hashes so rebuilds keep the same wallpaper collection.
  wallpaperBase = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/1023077979591cdeca76aae94e0359da1707a60e/landscapes";
  wallpapers = {
    midnight = ./wallpapers/midnight-blue.png;
    mountains = pkgs.fetchurl {
      name = "salty-mountains.png";
      url = "${wallpaperBase}/salty_mountains.png";
      sha256 = "18mw0g8sd3rg4b7lw9c516jwnjnsb31n7cwrzcmyddf0bq6a48fn";
    };
    yosemite = pkgs.fetchurl {
      name = "yosemite.png";
      url = "${wallpaperBase}/yosemite.png";
      sha256 = "0zyphcvh6dxbq997h716lcr2kpilp4jid9hp2sdjphpxpf824nck";
    };
    evening = pkgs.fetchurl {
      name = "evening-sky.png";
      url = "${wallpaperBase}/evening-sky.png";
      sha256 = "0kb87w736abdf794dk9fvqln56axzskxia1g6zdjrqzl7v539035";
    };
  };
  wallpaperApp = pkgs.writeShellScriptBin "wallpaper" ''
    case "''${1:-midnight}" in
      midnight) image=${wallpapers.midnight} ;;
      mountains) image=${wallpapers.mountains} ;;
      yosemite) image=${wallpapers.yosemite} ;;
      evening) image=${wallpapers.evening} ;;
      *) echo "Usage: wallpaper [midnight|mountains|yosemite|evening]" >&2; exit 2 ;;
    esac
    exec ${unstablePkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$image,cover"
  '';
  sessionApp = pkgs.writeShellScriptBin "session-app" ''
    if uwsm check is-active >/dev/null 2>&1; then
      exec uwsm app -- "$@"
    else
      exec "$@"
    fi
  '';
in

{
  imports = [
    ./theme.nix
    ./music.nix
    ./vivaldi.nix
    ./audio.nix
    ./hardware.nix
    ./updates.nix
    ./neovim.nix
    ./helix.nix
    ./zed.nix
  ];

  home.username = "malikk";
  home.homeDirectory = "/home/malikk";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  xfconf = {
    enable = true;
    settings.thunar = {
      last-view = "ThunarIconView";
      last-icon-view-zoom-level = "THUNAR_ZOOM_LEVEL_75_PERCENT";
      last-location-bar = "ThunarLocationButtons";
      last-side-pane = "THUNAR_SIDEPANE_TYPE_SHORTCUTS";
      last-separator-position = 180;
      last-menubar-visible = false;
      last-statusbar-visible = true;
      last-toolbar-items = "back:1,forward:1,open-parent:1,location-bar:1,search:1,view-switcher:1,menu:1";
      shortcuts-icon-size = "THUNAR_ICON_SIZE_24";
      misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ONLY_LOCAL";
    };
  };
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
    "x-scheme-handler/zoommtg" = [ "Zoom.desktop" ];
    "x-scheme-handler/zoomus" = [ "Zoom.desktop" ];
  };
  programs.git = {
    enable = true;
    package = userPkgs.git;
    settings.user = {
      name = "Malik Klinker";
      email = "235598266+malikklinker@users.noreply.github.com";
    };
  };
  # Git otherwise tries to write global settings to Home Manager's store symlink.
  # It reads both files, but prefers ~/.gitconfig for writes when it exists.
  home.activation.writableGitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      run ${pkgs.coreutils}/bin/install -m 600 /dev/null "$HOME/.gitconfig"
    fi
  '';
  programs.fish.enable = true;
  programs.fish.package = userPkgs.fish;
  programs.fish.interactiveShellInit = ''
    source ${userPkgs.fish}/share/fish/prompts/scales.fish
  '';
  programs.fish.functions.fish_greeting = ''
    if test -t 1; and test "$TERM" != dumb
      ${userPkgs.fastfetch}/bin/fastfetch
    end
  '';

  programs.zoxide = {
    enable = true;
    package = userPkgs.zoxide;
    enableFishIntegration = true;
  };

  programs.codexDesktopLinux.enable = true;

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    x11.enable = true;
  };
  # UWSM reads these before launching the compositor and graphical services.
  xdg.configFile."uwsm/env".text = ''
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
  '';
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = "Adwaita";
    cursor-size = 24;
  };

  home.file = pkgs.lib.mapAttrs' (
    name: source: pkgs.lib.nameValuePair "Pictures/Wallpapers/${name}.png" { inherit source; }
  ) wallpapers;

  services.hyprpaper = {
    enable = true;
    settings.splash = false;
    settings.wallpaper = [
      {
        monitor = "";
        path = "${wallpapers.midnight}";
        fit_mode = "cover";
      }
    ];
  };
  # Hyprpaper is only needed in Hyprland, and starts after UWSM imports its env.
  systemd.user.services.hyprpaper.Unit.ConditionEnvironment = pkgs.lib.mkForce [
    "WAYLAND_DISPLAY"
    "XDG_CURRENT_DESKTOP=Hyprland"
  ];

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
    package = userPkgs.kitty;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      # Do not restore a maximized window and override the compositor's tiling.
      remember_window_size = false;
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      enable_audio_bell = false;
      window_padding_width = 8;
      background_opacity = "0.94";
    };
  };

  programs.fastfetch = {
    enable = true;
    package = userPkgs.fastfetch;
    settings = {
      logo = {
        type = "data";
        source = builtins.readFile ./fastfetch/starry-sky.txt;
        color = {
          "1" = "blue";
          "2" = "magenta";
          "3" = "white";
        };
        padding.right = 2;
      };
      display = {
        separator = " 󰁔 ";
        color.keys = "blue";
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
    package = userPkgs.quickshell;
    activeConfig = "mocha";
    configs.mocha = ./quickshell;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };

  services.elephant.enable = true;
  services.elephant.package = userPkgs.elephant;

  # Wait for the compositor to publish its display environment before starting
  # launchers, and stop them on logout so the next session gets fresh values.
  systemd.user.services = {
    elephant.Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    walker = {
      Unit = {
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      # Do not launch clients until the daemon owns its application bus name.
      # Type=simple lets walker-open race the daemon and take the name first.
      Service = {
        Type = "dbus";
        BusName = "dev.benz.walker";
        RestartSec = 1;
      };
    };
    # The Walker daemon starts hidden; show the launcher once on login too.
    walker-open = {
      Unit = {
        Description = "Open Walker on desktop login";
        After = [ "graphical-session.target" "walker.service" ];
        Requires = [ "walker.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${config.services.walker.package}/bin/walker";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    quickshell.Unit.PartOf = [ "graphical-session.target" ];
  };

  services.walker = {
    enable = true;
    package = userPkgs.walker;
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
          {
            prefix = ">";
            provider = "runner";
          }
          {
            prefix = "/";
            provider = "files";
          }
          {
            prefix = "=";
            provider = "calc";
          }
        ];
      };
    };
    theme = {
      name = "desktop";
      style = ''@import url("file://${config.xdg.stateHome}/desktop-theme/walker.css");'';
    };
  };

  home.packages = with userPkgs; [
    sessionApp
    wallpaperApp
    codex
    unzip
    file-roller

    # Coding and terminal basics
    neovim
    git
    ripgrep
    fd
    fzf
    nil
    pyright
    ruff
    texlab
    # Prefer GCC for shared commands such as cc and c++.
    (lib.hiPrio gcc)
    gnumake
    lazygit
    lua-language-server
    nixfmt
    stylua
    tree-sitter
    nodejs
    openblas
    openblas.dev
    clang
    rustc
    cargo
    zig
    zls
    typescript-language-server

    # Math coursework and LaTeX
    texlive.combined.scheme-medium
    texlivePackages.latexmk
    biber
    texlivePackages.chktex
    zathura

    # Launch with `nvidia-offload prismlauncher` when you want the RTX 4070.
    prismlauncher

    # Video meetings
    zoom-us

    # Small Wayland desktop essentials
    networkmanagerapplet
    wl-clipboard
    grim
    slurp
    xdg-utils
  ];
}
