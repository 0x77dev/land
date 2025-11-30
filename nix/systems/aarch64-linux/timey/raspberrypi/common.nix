{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./bootloader.nix
    ./configtxt.nix
    ./udev.nix
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    ./configtxt-config.nix
  ];

  boot = {
    loader.rpi.enable = true;
    consoleLogLevel = lib.mkDefault 7;
    # https://github.com/raspberrypi/firmware/issues/1539#issuecomment-784498108
    # https://github.com/RPi-Distro/pi-gen/blob/master/stage1/00-boot-files/files/cmdline.txt
    kernelParams = [
      "console=serial0,115200n8"
      "console=tty1"
    ];
    initrd.availableKernelModules = [
      "xhci_pci"
      # https://github.com/NixOS/nixos-hardware/issues/631#issuecomment-1584100732
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
    ];
  };
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    raspberrypi-utils
  ];

  # workaround for "modprobe: FATAL: Module <module name> not found"
  # see https://github.com/NixOS/nixpkgs/issues/154163,
  #     https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
