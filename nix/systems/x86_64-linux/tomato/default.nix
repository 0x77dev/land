{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules = {
    hardware.ms-01.enable = true;
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    observability.enable = true;
  };

  virtualisation.docker = {
    storageDriver = "zfs";
    liveRestore = true;
    autoPrune.enable = true;
  };

  services = {
    time-client = {
      enable = true;
      ptp = {
        enable = true;
        interface = "enp2s0f0np0"; # First 10GbE NIC
        timestamping = "software"; # Match timey's software timestamping
      };
    };

    # Firmware updates via LVFS.
    fwupd.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        AllowAgentForwarding = true;
        StreamLocalBindUnlink = true;
      };
    };
  };

  networking = {
    hostName = "tomato";
    domain = "0x77.computer";
    hostId = "442cbd39";
    # Both 10GbE NICs configured independently via DHCP.
    useDHCP = true;
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
    ];
    shell = pkgs.fish;
  };

  system.stateVersion = "25.11";
}
