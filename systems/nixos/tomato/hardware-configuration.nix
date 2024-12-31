{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "rpool/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "rpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/1F38-8495";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };


  fileSystems."/data" =
    {
      device = "rpool/data";
      fsType = "zfs";
    };

  fileSystems."/data/docker" =
    {
      device = "rpool/data/docker";
      fsType = "zfs";
    };

  fileSystems."/data/postgresql" =
    {
      device = "rpool/data/postgresql";
      fsType = "zfs";
    };

  fileSystems."/data/kubo" =
    {
      device = "rpool/data/kubo";
      fsType = "zfs";
    };

  fileSystems."/data/media" =
    {
      device = "rpool/data/media";
      fsType = "zfs";
    };

  fileSystems."/data/share" =
    {
      device = "rpool/data/share";
      fsType = "zfs";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp87s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp90s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp91s0.useDHCP = lib.mkDefault true;
  networking.hostId = "442cbd39";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
