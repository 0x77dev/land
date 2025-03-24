# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./disko-config.nix
      ../../../modules/nixos/cluster.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tomato";
  networking.domain = "0x77.computer";

  # Enable K3s cluster as primary server node
  modules.cluster = {
    enable = true;
    role = "server";
    clusterInit = true;
    storageSupport = {
      longhorn = true;
    };
  };

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
