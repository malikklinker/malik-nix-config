{
  config,
  lib,
  userPkgs,
  ...
}:
let
  pkgs = userPkgs;
  upstream = pkgs.fetchurl {
    url = "https://api.zed.dev/extensions/fortran/0.0.3/download";
    hash = "sha256-GwWc7AE7PnTz/MjYdik28MlNDBkFXD8vlsoNDUEPstM=";
    name = "zed-fortran-0.0.3.tar.gz";
  };
  extension = pkgs.runCommand "zed-fortran-workbench-0.0.3" { } ''
    mkdir -p "$out"
    tar -xzf ${upstream} -C "$out"
    chmod -R u+w "$out"
    cp ${./fortran/outline.scm} "$out/languages/fortran/outline.scm"
    cp ${./fortran/textobjects.scm} "$out/languages/fortran/textobjects.scm"
    cp ${./fortran/brackets.scm} "$out/languages/fortran/brackets.scm"
    cp ${./fortran/runnables.scm} "$out/languages/fortran/runnables.scm"
    # @branch is a Neovim capture; Zed uses @outdent.
    substituteInPlace "$out/languages/fortran/indents.scm" --replace-fail '@branch' '@outdent'
    substituteInPlace "$out/languages/fortran/highlights.scm" \
      --replace-fail '@include' '@keyword.import' \
      --replace-fail '@conditional' '@keyword.conditional' \
      --replace-fail '@repeat' '@keyword.repeat' \
      --replace-fail '@parameter' '@variable.parameter'
    substituteInPlace "$out/languages/fortran/config.toml" \
      --replace-fail '"F08"]' '"F08", "for", "FOR", "ftn", "FTN", "f77", "F77", "f18", "F18", "fpp", "FPP"]'
    cat >> "$out/languages/fortran/config.toml" <<'EOF'
    tab_size = 2
    hard_tabs = false
    EOF
  '';
  taskRunner = pkgs.writeShellScript "zed-fortran-task" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.gfortran
        pkgs.fortran-fpm
        pkgs.gnumake
        pkgs.cmake
        pkgs.ninja
      ]
    }:"$PATH"
    exec ${pkgs.python3}/bin/python3 ${./fortran/tasks.py} "$@"
  '';
in
{
  programs.zed-editor = {
    extensions = [ "material-icon-theme" ];
    userSettings = {
      icon_theme = "Material Icon Theme";
      # The local, pinned fork is registered as a development extension.
      auto_update_extensions.fortran = false;
      lsp.fortls.binary = {
        path = "${pkgs.fortls}/bin/fortls";
        arguments = [
          "--lowercase_intrinsics"
          "--hover_signature"
          "--use_signature_help"
          "--enable_code_actions"
          "--disable_autoupdate"
          "--hover_language"
          "fortran"
        ];
      };
      languages.Fortran = {
        language_servers = [ "fortls" ];
        tab_size = 2;
        hard_tabs = false;
        preferred_line_length = 100;
        show_wrap_guides = true;
        show_completions_on_input = true;
        show_completion_documentation = true;
        show_signature_help_after_edits = true;
        # Keep fixed-form/legacy files safe: formatting is an explicit action.
        format_on_save = "off";
        formatter.external = {
          command = "${pkgs.fprettify}/bin/fprettify";
          arguments = [
            "--indent"
            "2"
            "--line-length"
            "100"
          ];
        };
      };
      file_types.Fortran = [
        "*.f"
        "*.F"
        "*.for"
        "*.FOR"
        "*.ftn"
        "*.FTN"
        "*.f77"
        "*.F77"
        "*.f90"
        "*.F90"
        "*.f95"
        "*.F95"
        "*.f03"
        "*.F03"
        "*.f08"
        "*.F08"
        "*.f18"
        "*.F18"
        "*.fpp"
        "*.FPP"
      ];
    };
    userTasks = map (task: task // { command = "${taskRunner}"; }) (
      builtins.fromJSON (builtins.readFile ./fortran/tasks.json)
    );
  };
  # Directory symlinks are Zed's development-extension registration mechanism.
  # Retain upstream's precompiled WASM and grammar; only override editor queries.
  xdg.dataFile."zed/extensions/installed/fortran".source = extension;
  xdg.configFile."zed/snippets/fortran.json".source = ./fortran/snippets.json;
}
