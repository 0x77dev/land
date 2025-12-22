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
    cluster.incus.enable = true;
    observability.enable = true;
  };

  virtualisation.docker = {
    storageDriver = "zfs";
    liveRestore = true;
    autoPrune.enable = true;
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
    time-client = {
      enable = true;
      ptp = {
        enable = true;
        interface = "enp2s0f0np0"; # First 10GbE NIC (bonded, but PTP uses physical)
        timestamping = "software"; # Match timey's software timestamping
      };
    };
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
        StreamLocalBindUnlink = true;
      };
    };
  };

  system.stateVersion = "25.11";

  documentation.nixos.enable = false;
}
