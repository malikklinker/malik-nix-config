{ ... }:
{
  # Doom itself and the module/package selections stay user-owned and writable.
  home.file.".doom.d/config.el".source = ./doom/config.el;
  home.file.".doom.d/themes/desktop-theme.el".source = ./doom/themes/desktop-theme.el;
}
