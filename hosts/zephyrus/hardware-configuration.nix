# Install-time template. Replace the UUID placeholders with the UUIDs for the
# encrypted root and EFI system partitions created during installation.
{ ... }:

{
  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/REPLACE_WITH_LUKS_UUID";

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
