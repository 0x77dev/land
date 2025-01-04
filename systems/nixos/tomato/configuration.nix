# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ inputs, config, lib, pkgs, ... }:

{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
      ./hardware-configuration.nix
      ./environment.nix
      ./security.nix
      ./programs.nix
      ./services
      ./virtualisation.nix
    ];

  sops = {
    defaultSopsFile = ../../../secrets/shared.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "aria2/rpc-secret" = { };
      "resend/api-key" = { };
      "plausible/admin-password" = { };
      "plausible/secret" = { };
      "cloudflared/tunnel-credentials" = {
        owner = "cloudflared";
        group = "cloudflared";
        mode = "0440";
      };
      "cloudflared/cert.pem" = {
        owner = "cloudflared";
        group = "cloudflared";
        mode = "0440";
        path = "/home/cloudflared/.cloudflared/cert.pem";
      };
      "github-runner/token" = {
        owner = "github-runner";
        group = "github-runner";
        mode = "0440";
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  networking.hostName = "tomato";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = builtins.fromJSON (builtins.readFile ../../../helpers/openssh-authorized-keys.json);
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # User permissions
      trusted-users = [ "root" "mykhailo" ];
      trusted-substituters = [ "root" "mykhailo" ];

      # Binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://land.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA="
      ];

      # Build optimization
      max-jobs = "auto";
      cores = 0; # Use all available cores
      system-features = [ "big-parallel" "benchmark" ];
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true; # Allow builders to use substitutes
      connect-timeout = 5; # Reduce connection timeout
      download-speed = 0; # No limit on download speed
      narinfo-cache-negative-ttl = 0; # Don't cache negative lookups
    };

    # Garbage collection
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };

    # Store optimization
    optimise = {
      automatic = true;
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
      intel-media-sdk
    ];
  };

  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = "/data/.secret/vpn/wg.conf";
    accessibleFrom = [
      "192.168.0.0/24"
      "100.64.0.0/10"
      "127.0.0.1/32"
    ];
    portMappings = [
      { from = 9091; to = 9091; }
    ];
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 19999 139 445 2283 80 443 8181 32400 5001 8501 4001 6800 9091 ];
  networking.firewall.allowedUDPPorts = [ 137 138 80 443 4001 ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
