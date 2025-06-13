{ inputs, pkgs, ... }:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];

  sops.defaultSopsFile = ./secrets/shared.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/Users/0x77/.config/sops/age/keys.txt";

  nix-homebrew.user = "0x77";
  users = {
    users."0x77" = {
      home = "/Users/0x77";
      uid = 501;
      openssh.authorizedKeys.keys = builtins.fromJSON (
        builtins.readFile ../../../helpers/openssh-authorized-keys.json
      );

      shell = pkgs.fish;
    };

    knownUsers = [ "0x77" ];
  };
  system.primaryUser = "0x77";

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  environment.systemPackages = [
    pkgs.vscode
    pkgs.nil
    pkgs.nixpkgs-fmt
    pkgs.kitty
    pkgs.btop
    pkgs.eza
    pkgs.git
    pkgs.glow
    pkgs.openssl
    pkgs.git-lfs
    pkgs.git-crypt
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.zoxide
    pkgs.bat
    pkgs.direnv
    pkgs.iperf3
    pkgs.nodejs-slim
    pkgs.bun
    pkgs.aria2
    pkgs.kubo
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-platforms = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # User permissions
      trusted-users = [
        "root"
        "0x77"
      ];
      trusted-substituters = [
        "root"
        "0x77"
      ];

      # Binary caches
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

      # Sandbox settings
      sandbox = true;
      extra-sandbox-paths = [ "/nix/store" ];
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

  programs.fish.enable = true;

  system.stateVersion = 5;
}
