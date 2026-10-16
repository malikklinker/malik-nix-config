{ ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;

    # PRIME render offload keeps the AMD iGPU doing everyday desktop work and
    # lets selected apps use the RTX 4070. Fill in both PCI IDs from `lspci`
    # during installation; see README.md.
    prime = {
      amdgpuBusId = "PCI:101@0:0:0";
      nvidiaBusId = "REPLACE_WITH_NVIDIA_PCI_ID";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };
}
