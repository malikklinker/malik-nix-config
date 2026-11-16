{
  config,
  lib,
  pkgs,
  userPkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/package-policy.nix
    ../../modules/bootloader.nix
    ../../modules/desktop.nix
    ../../modules/greeter-sddm.nix
    ../../modules/nvidia.nix
    ../../modules/power.nix
  ];

  networking.hostName = "zephyrus";
  networking.networkmanager.enable = true;

  # NetworkManager handles Wi-Fi; nmtui is available from a terminal.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Required for the proprietary NVIDIA userspace driver and settings tool.
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # NVIDIA 595.71.05 does not build against Linux 7.2, which removed strncpy
  # from the kernel API. Use the current 6.18 LTS kernel until nixpkgs updates
  # the NVIDIA driver with a compatible fix.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.fish.enable = true;
  programs.fish.package = userPkgs.fish;

  users.users.malikk = {
    isNormalUser = true;
    description = "Malik";
    shell = userPkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
    ];
    # Set a login password after installation with `passwd` from a root shell.
  };

  security.sudo.wheelNeedsPassword = true;

  services.fwupd.enable = true;
  services.asusd = {
    enable = true;
  };
  # asusd's sandbox requires this writable directory even with no declarative
  # RON configuration. Otherwise it fails before it can create its defaults.
  systemd.tmpfiles.rules = [ "d /etc/asusd 0755 root root -" ];
  # Keep the lid's Slash LED bar dark, including firmware event animations.
  environment.etc."asusd/slash.ron" = {
    mode = "0644";
    text = ''
      (
          enabled: false,
          brightness: 0,
          display_interval: 0,
          display_mode: Bounce,
          show_on_boot: false,
          show_on_shutdown: false,
          show_on_sleep: false,
          show_on_battery: false,
          show_battery_warning: false,
          show_on_lid_closed: false,
      )
    '';
  };
  systemd.services.asusd.restartTriggers = [ config.environment.etc."asusd/slash.ron".source ];
  services.printing.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    pciutils
    usbutils
    (userPkgs.python3.withPackages (python: with python; [
      numpy
      matplotlib
      scipy
      pandas
      sympy
    ]))
  ];

  system.stateVersion = "26.05";
}
