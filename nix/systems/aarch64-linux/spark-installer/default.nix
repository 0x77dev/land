{ modulesPath, config, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];

  modules.installer.enable = true;

  boot = {
    # NVIDIA DGX Spark (GB10): without `arm64.nobti` the stock arm64 kernel
    # panics on boot (NVIDIA's documented workaround, also used by Talos).
    kernelParams = [ "arm64.nobti" ];
    blacklistedKernelModules = [ "nouveau" ];

    # The Spark's USB 3.0 controller is a platform (ARM64 device-tree) xHCI, not
    # PCI, and `enableAllHardware` doesn't cover it — so the installer can't read
    # the boot medium without these. Mirrors graham33/nixos-dgx-spark.
    initrd = {
      systemd.enable = true;
      kernelModules = [
        "xhci_plat_hcd"
        "uas"
        "usbhid"
        "hid_generic"
        "sd_mod"
        "nvme"
      ];
    };
  };

  hardware = {
    # GPU driver in the live environment (e.g. for `nvidia-smi` hardware checks).
    # Open modules only (required on Blackwell); no `cudaSupport`, so no CUDA
    # world-rebuild — just the driver against the stock kernel.
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  system.stateVersion = "25.11";
}
