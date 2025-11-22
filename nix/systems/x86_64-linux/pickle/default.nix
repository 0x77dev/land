{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules.hardware.ms-01.enable = true;
  modules.filesystem.zfs = {
    enable = true;
    useLatestKernel = true;
  };

  networking = {
    hostName = "pickle";
    domain = "0x77.computer";
    hostId = "c1072b21";
  };

  # Users
  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home = {
      enable = true;
      config = { };
    };
  };

  users.users.mykhailo = {
    isNormalUser = true;
    initialPassword = "wakeupneo";
    description = "Mykhailo Marynenko";
    extraGroups = [
      "networkmanager"
      "docker"
    ];
    shell = pkgs.fish;
  };

  system.stateVersion = "25.05";
}
