{
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
    hostName = "beefy";
    domain = "0x77.computer";
  };

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/Users/${userName}";

      config = {
        modules.home = {
          ai.enable = true;
          cloud.enable = true;
          fonts.enable = true;
          ghostty.enable = true;
          git.enable = true;
          ide.enable = true;
          media.enable = true;
          mobile.enable = true;
          network.enable = true;
          nix.enable = true;
          p2p.enable = true;
          reverse-engineering.enable = true;
          comms.enable = true;
          security-tools.enable = true;
          shell.enable = true;
          ssh.enable = true;
          gpg.enable = true;
        };
      };
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

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    # TODO: extraConfig is not in 25.05 yet
    # extraConfig = {
    #   PermitRootLogin = "no";
    #   # NOTE: don't do PasswordAuthentication = false; it will prevent remote FileVault unlock
    #   AllowAgentForwarding = true;
    #   StreamLocalBindUnlink = true;
    # };
  };

  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables.SSH_AUTH_SOCK =
    "/Users/${userName}/.gnupg/S.gpg-agent.ssh";

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "muscle";
        protocol = "ssh-ng";
        sshUser = userName;
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU1BM3dYNWtSSm9OdHhZK3ByMmNjTjdZZXJTRVB2Si81Y0s3emRRMldwcHYK";
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

  programs.ssh.knownHosts.muscle = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA3wX5kRJoNtxY+pr2ccN7YerSEPvJ/5cK7zdQ2Wppv";
    extraHostNames = [
      "muscle.0x77.computer"
      "muscle.osv.computer"
    ];
  };
}
