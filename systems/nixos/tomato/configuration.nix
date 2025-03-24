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

  networking.vlans = {
    vlan4 = { id = 4; interface = "enp2s0"; };
  };

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

  users.users.mykhailo = {
    isNormalUser = true;
    initialPassword = "wakeupneo";
    description = "Mykhailo Marynenko";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = builtins.fromJSON (builtins.readFile ../../../helpers/openssh-authorized-keys.json);
  };
  security.sudo.wheelNeedsPassword = false;

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
