{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.dgx-spark;
in
{
  options.hardware.dgx-spark.enable = lib.mkEnableOption "NVIDIA DGX Spark (GB10) hardware support";

  config = lib.mkIf cfg.enable {
    # Every DGX Spark has a single internal NVMe — use it whole: a 1G ESP plus
    # an XFS root spanning the rest. disko generates `fileSystems` from this.
    disko.devices.disk.nvme0 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
            };
          };
        };
      };
    };

    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = true;
      # GB10 reports compute capability sm_121 (12.1); 12.0 is included for
      # broader Blackwell-family (sm_120) compatibility.
      cudaCapabilities = [
        "12.0"
        "12.1"
      ];
    };

    # No custom kernel: recent mainline supports the DGX Spark, with the GPU
    # provided by the out-of-tree NVIDIA driver below (the same combination
    # Talos uses). The repo-wide latest-kernel default applies.
    boot = {
      # GB10/arm64 requires disabling Branch Target Identification, or the
      # system crashes / CUDA libraries fail to load.
      kernelParams = [ "arm64.nobti" ];

      kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      blacklistedKernelModules = [ "nouveau" ];

      # There's no generated hardware-configuration.nix, so the initrd must be
      # told how to reach the NVMe root: `nvme` for the disk, plus the Spark's
      # platform (ARM64 device-tree) xHCI for USB keyboards in early boot.
      # Without `nvme` here stage-1 can't mount root and init panics.
      initrd = {
        systemd.enable = true;
        availableKernelModules = [
          "nvme"
          "xhci_plat_hcd"
          "usbhid"
          "uas"
          "sd_mod"
          "usb_storage"
        ];
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      nvidia = {
        modesetting.enable = true;
        # Blackwell only supports the open kernel modules.
        open = true;
        nvidiaPersistenced = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.production;
      };
      nvidia-container-toolkit.enable = true;
    };

    services = {
      xserver.videoDrivers = [ "nvidia" ];

      # Firmware updates via LVFS. NVIDIA publishes DGX Spark firmware there.
      fwupd.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia
      iperf3
      ethtool
      rdma-core
    ];
  };
}
