{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules = {
    hardware.ms-01.enable = true;
    network.bonding = {
      enable = true;
      vlans = [
        {
          id = 4;
          name = "homelab";
        }
      ];
    };
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    cluster.incus.enable = true;
    observability.enable = true;
    builders = {
      enable = true;
      speedFactor = 2;
    };
  };

  virtualisation.docker = {
    storageDriver = "zfs";
    liveRestore = true;
    autoPrune.enable = true;
  };

  services.time-client = {
    enable = true;
    ptp = {
      enable = true;
      interface = "enp2s0f0np0"; # First 10GbE NIC (bonded, but PTP uses physical)
      timestamping = "software"; # Match timey's software timestamping
    };
  };

  networking = {
    hostName = "tomato";
    domain = "0x77.computer";
    hostId = "442cbd39";
  };

  security.sudo.wheelNeedsPassword = false;

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
    description = "Mykhailo Marynenko";
    extraGroups = [
      "networkmanager"
      "docker"
      "incus"
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
      AllowAgentForwarding = true;
      StreamLocalBindUnlink = true;
    };
  };

  system.stateVersion = "25.11";
}
