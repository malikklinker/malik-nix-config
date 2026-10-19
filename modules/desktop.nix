{ config, inputs, pkgs, ... }:

let
  graphicsPkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  niriPackage = pkgs.niri.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ../patches/niri-session-environment.patch ];
  });
in

{
  # Keep the login screen in a text console; the session itself is Wayland.
  services.greetd = {
    enable = true;
    settings.default_session = {
      # Do not restore a previously remembered (broken) Hyprland session.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd ${niriPackage}/bin/niri-session";
      user = "greeter";
    };
  };

  # Keep the compositor, its portal, and Mesa from the same package set.
  programs.hyprland = {
    enable = true;
    package = graphicsPkgs.hyprland;
    portalPackage = graphicsPkgs.xdg-desktop-portal-hyprland;
    withUWSM = true;
  };
  programs.uwsm.package = graphicsPkgs.uwsm;
  programs.niri = {
    enable = true;
    package = niriPackage;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.package = graphicsPkgs.mesa;
  hardware.graphics.package32 = graphicsPkgs.pkgsi686Linux.mesa;

  # AQ_DRM_DEVICES is colon-separated, so PCI by-path names cannot be used.
  # Match the AMD PCI device, never a card number that can change at boot.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:65:00.0", SYMLINK+="dri/amd-igpu"
  '';

  # Aquamarine reads this before Hyprland starts, unlike compositor config
  # directives that may only be applied after backend initialization.
  environment.sessionVariables = {
    # Pin Aquamarine to the AMD iGPU so startup does not probe the NVIDIA dGPU.
    AQ_DRM_DEVICES = "/dev/dri/amd-igpu";
    # Aquamarine >= 0.15 includes the HX 370 panel max_bpc fallback.
    # Leave atomic modesetting enabled to use and test that fix.
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
