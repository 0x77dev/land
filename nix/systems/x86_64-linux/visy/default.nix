{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
  ];

  modules = {
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    observability.enable = true;
    builders.enable = false; # EXPLICITLY DISABLED - not a builder
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    liveRestore = true;
    autoPrune.enable = true;
  };

  # zswap for in-memory compressed swap
  boot.kernelParams = [ "zswap.enabled=1" ];
  zramSwap = {
    enable = true;
    memoryPercent = 50; # Use up to 50% of RAM (~7.7GB) for zram swap
  };

  networking = {
    hostName = "visy";
    domain = "0x77.computer";
    hostId = "61cc62c9"; # Generated from hostname via openssl
    useDHCP = true; # DHCP on all interfaces
  };

  # Time synchronization from local time server
  services.time-client = {
    enable = true;
    server = "timey.0x77.computer";
  };

  # SSH configuration
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

  # User configuration
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
      "wheel"
      "docker"
      "networkmanager"
    ];
    shell = pkgs.fish;
  };

  # Minimal system packages for Docker host
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    hwloc
    vim
    docker-compose
  ];

  programs.fish.enable = true;

  system.stateVersion = "25.11";
  documentation.nixos.enable = false; # Save space
}
