{ pkgs, ... }:

{
  # Keep the login screen in a text console; the session itself is Wayland.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd Hyprland";
      user = "greeter";
    };
  };

  programs.hyprland.enable = true;
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Aquamarine reads this before Hyprland starts, unlike compositor config
  # directives that may only be applied after backend initialization.
  environment.sessionVariables = {
    # Pin Aquamarine to the AMD iGPU so startup does not probe the NVIDIA dGPU.
    AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:65:00.0-card";
    NIXOS_OZONE_WL = "1";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.dbus.enable = true;
  programs.dconf.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;
}
