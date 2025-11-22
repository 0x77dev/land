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
    virtualisation.incus-cluster = {
      enable = true;
      usePreseed = true; # Use preseed for initial storage/network/profile setup
    };
  };

  networking = {
    hostName = "tomato";
    domain = "0x77.computer";
    hostId = "442cbd39";
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

  # OpenSSH
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
