{ ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;

    # PRIME render offload keeps the AMD iGPU doing everyday desktop work and
    # lets selected apps use the RTX 4070. On this Zephyrus, lspci reports the
    # NVIDIA GPU at 0000:64:00.0 (PCI bus 64 is decimal 100).
    prime = {
      amdgpuBusId = "PCI:101@0:0:0";
      nvidiaBusId = "PCI:100@0:0:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };
}
