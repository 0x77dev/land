{ lib, pkgs, ... }:

{
  imports = [ ./common.nix ];

  boot = {
    loader.rpi = {
      variant = "5";
      bootloader = lib.mkDefault "kernelboot";
      firmwarePackage = lib.mkDefault pkgs.raspberrypifw;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_rpi5;
    initrd.availableKernelModules = [
      "nvme" # nvme drive connected with pcie
    ];
  };
}
