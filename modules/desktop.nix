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
    AQ_DRM_DEVICES = "/dev/dri/amd-igpu";
    NIXOS_OZONE_WL = "1";
  };

  # Stable DRM alias for the AMD iGPU at PCI 0000:65:00.0. Hyprland uses this
  # as its only compositor device; PRIME offload apps can still use the dGPU.
  services.udev.extraRules = ''
    KERNEL=="card*", KERNELS=="0000:65:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/amd-igpu"
  '';

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
