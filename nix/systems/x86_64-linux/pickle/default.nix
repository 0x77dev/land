{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules = {
    hardware.ms-01.enable = true;
    network.bonding.enable = true;
    network.incus = {
      enable = true;
      sourceInterface = "bond0";
      ovnPrivate.enable = true; # Enable cluster-wide OVN private network
    };
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    cluster.incus.enable = true;
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

  security.sudo.wheelNeedsPassword = false;

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "networkmanager"
      "docker"
      "incus"
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
        AllowAgentForwarding = true;
      };
    };
  };

  system.stateVersion = "25.05";
}
