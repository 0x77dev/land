{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  # Basic system configuration
  system.stateVersion = "25.05";
  networking.hostName = "nix-rendezvous";
  time.timeZone = "America/Los_Angeles";

  nix = {
    settings = {
      trusted-users = [
        "root"
        "builder"
      ];

      trusted-substituters = [
        "root"
        "builder"
      ];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];

      sandbox = false;
      experimental-features = "nix-command flakes";

      # Build optimization
      max-jobs = "auto";
      cores = 0; # Use all available cores
      system-features = [
        "big-parallel"
        "benchmark"
      ];
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true; # Allow builders to use substitutes
      connect-timeout = 5; # Reduce connection timeout
      download-speed = 0; # No limit on download speed
      narinfo-cache-negative-ttl = 0; # Don't cache negative lookups
    };

    sshServe = {
      enable = true;
      keys = builtins.fromJSON (builtins.readFile ../../helpers/openssh-authorized-keys.json);
    };

    optimise = {
      automatic = true;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 31d";
    };
  };

  packages = with pkgs; [
    nix-output-monitor
  ];

  users.users.builder = {
    isNormalUser = true;
    initialPassword = "wakeupneo";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = builtins.fromJSON (
      builtins.readFile ../../helpers/openssh-authorized-keys.json
    );
  };

  # Container-specific settings
  modules.proxmox-lxc = {
    enable = true;
    unprivilegedContainer = true;
    networkInterface = "eth0";
    enableSerialConsole = true;
  };
}
