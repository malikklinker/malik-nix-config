{
  config,
  lib,
  pkgs,
  ...
}:

let
  state = "${config.xdg.stateHome}/desktop-theme";
  python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
  presets = pkgs.runCommand "desktop-theme-presets" { nativeBuildInputs = [ python ]; } ''
    python ${./theme/build_presets.py} ${pkgs.base16-schemes}/share/themes "$out" ${./theme/schemes}
    cp ${./theme/walker.css.in} "$out/walker.css.in"
  '';
  themeSet = pkgs.writeShellApplication {
    name = "theme-set";
    runtimeInputs = [
      pkgs.python3
      pkgs.tinty
      pkgs.procps
      pkgs.glib
      pkgs.systemd
      pkgs.mako
      pkgs.quickshell
    ];
    text = ''
      exec python3 ${./theme/theme_set.py} --assets ${presets} --tinty ${pkgs.tinty}/bin/tinty "$@"
    '';
  };
in
{
  home.packages = [
    themeSet
    pkgs.tinty
  ];
  xdg.configFile = {
    "desktop-theme/apply".source = "${themeSet}/bin/theme-set";
    "desktop-theme/catalog.json".source = "${presets}/catalog.json";
    "desktop-theme/tinty.toml".source = (pkgs.formats.toml { }).generate "desktop-tinty.toml" {
      default-scheme = "base16-catppuccin-mocha";
      items = [
        {
          name = "desktop";
          path = "${presets}/template";
          themes-dir = "themes";
          supported-systems = [ "base16" ];
          hook = ''${themeSet}/bin/theme-set --apply "$TINTY_THEME_FILE_PATH"'';
        }
      ];
    };
    "nvim/lua/config/desktop-syntax.lua".source = ./nvim/lua/config/desktop-syntax.lua;
    "nvim/lua/config/desktop-theme.lua".source = ./nvim/lua/config/desktop-theme.lua;
    "nvim/colors/desktop.lua".source = ./nvim/colors/desktop.lua;
    "nvim/lua/plugins/desktop-theme.lua".text = ''
      return {
        {
          "nvim-mini/mini.base16",
          name = "mini.base16",
          dir = "${pkgs.vimPlugins.mini-base16}",
          priority = 1000,
          config = function() require("config.desktop-theme").setup() end,
        },
        {
          "nvim-lualine/lualine.nvim",
          opts = function(_, opts)
            opts.options.theme = require("config.desktop-theme").statusline_theme()
          end,
        },
      }
    '';
  };

  # GTK previously created these files outside Home Manager. Preserve them when
  # migrating to the managed imports, before its collision check runs.
  home.activation.backupLegacyGtkCss = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for gtkVersion in gtk-3.0 gtk-4.0; do
      gtkCss=${lib.escapeShellArg config.xdg.configHome}/"$gtkVersion"/gtk.css
      if [[ -f "$gtkCss" && ! -L "$gtkCss" ]]; then
        run ${pkgs.coreutils}/bin/mv --backup=numbered -- \
          "$gtkCss" "$gtkCss.before-desktop-theme"
      fi
    done
  '';

  home.activation.desktopTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${themeSet}/bin/theme-set --restore --no-reload
  '';
  systemd.user.services.desktop-theme = {
    Unit = {
      Description = "Restore the selected desktop palette";
      PartOf = [ "graphical-session.target" ];
      Before = [
        "quickshell.service"
        "walker.service"
      ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${themeSet}/bin/theme-set --restore --no-reload";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  gtk = {
    enable = true;
    gtk3.extraCss = ''@import url("file://${state}/gtk3.css");'';
    gtk4.extraCss = ''@import url("file://${state}/gtk4.css");'';
  };
  programs.kitty.extraConfig = "include ${state}/kitty.conf";
  services.mako.settings.include = "${state}/mako.conf";
}
