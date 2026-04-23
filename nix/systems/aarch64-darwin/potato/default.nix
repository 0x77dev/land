{
  lib,
  pkgs,
  ...
}:
let
  userName = "mykhailo";
in
{
  system.stateVersion = 6;
  system.primaryUser = userName;

  networking = {
    hostName = "potato";
    domain = "0x77.computer";
  };

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/Users/${userName}";
    };
  };

  # Additional user configuration for nix-darwin
  users = {
    users.${userName} = {
      name = userName;
      uid = 501;
      home = "/Users/${userName}";
      shell = pkgs.fish;
    };

    knownUsers = [ userName ];
  };

  modules.darwin.dock.enable = true;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    _1password-gui
    _1password-cli
  ];

  services = {
    openssh.enable = true;
    ipfs = {
      enable = true;
      enableGarbageCollection = true;
    };
  };

  # Keep the builder in system Nix config so the daemon can see it.
  nix = {
    distributedBuilds = lib.mkForce true;
    buildMachines = lib.mkForce [
      {
        hostName = "muscle";
        protocol = "ssh-ng";
        sshUser = userName;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        maxJobs = 1;
        speedFactor = 2;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];
  };

  # Give the daemon a system-managed host key for the remote builder.
  programs.ssh.knownHosts.muscle = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA3wX5kRJoNtxY+pr2ccN7YerSEPvJ/5cK7zdQ2Wppv";
  };
}
