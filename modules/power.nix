{ ... }:
{
  # Dedicated swap partition; no Btrfs swap-file offset is needed.
  boot.resumeDevice = "/dev/disk/by-uuid/2761c6aa-f0a9-4425-b3d1-ce7a8ac04bb6";
  services.upower = {
    enable = true;
    usePercentageForPolicy = true;
    percentageLow = 25;
    percentageCritical = 15;
    percentageAction = 10;
    criticalPowerAction = "Hibernate";
  };
  # Power off after writing the image instead of relying on firmware sleep.
  systemd.sleep.settings.Sleep.HibernateMode = "shutdown";
  # Preserve offloaded applications' video memory over hibernation.
  hardware.nvidia.powerManagement.enable = true;
}
