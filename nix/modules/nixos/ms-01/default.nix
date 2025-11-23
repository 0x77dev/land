{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  options.modules.hardware.ms-01 = {
    enable = lib.mkEnableOption "Minisforum MS-01 Hardware Support";
  };

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = lib.mkIf config.modules.hardware.ms-01.enable {
    boot = {
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];
        kernelModules = [ ];
      };
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Hardware acceleration for Intel iGPU
    # MS-01 has Intel 12th/13th gen processors with integrated graphics
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # VAAPI driver for modern Intel GPUs (Broadwell+)
        intel-vaapi-driver # Older VAAPI driver (for compatibility)
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL support
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
        intel-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ];
      enable32Bit = true;
    };
  };
}
