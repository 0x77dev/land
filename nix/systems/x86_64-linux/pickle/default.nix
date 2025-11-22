{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules = {
    hardware.ms-01.enable = true;
    network.bonding.enable = true;
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    virtualisation.incus-cluster.enable = true;
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

  services = {
    iperf3 = {
      enable = true;
      openFirewall = true;
    };
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  system.stateVersion = "25.05";
}
