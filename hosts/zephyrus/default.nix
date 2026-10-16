{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # ASUS's current Armoury support requires a recent kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  users.users.malikk = {
    isNormalUser = true;
    description = "Malik";
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    # Set a login password after installation with `passwd` from a root shell.
  };

  security.sudo.wheelNeedsPassword = true;

  services.fwupd.enable = true;
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
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
  ];

  programs.firefox.enable = true;

  system.stateVersion = "26.05";
}
