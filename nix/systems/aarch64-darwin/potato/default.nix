{
  lib,
  pkgs,
  ...
}:
let
  userName = "mykhailo";
in
{
  system = {
    stateVersion = 6;
    primaryUser = userName;

    defaults = {
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      CustomUserPreferences."com.apple.screensaver" = {
        idleTime = 15 * 60;
      };
    };

    activationScripts.postActivation.text = lib.mkAfter ''
      # Keep potato awake on wall power without changing battery behavior.
      /usr/bin/pmset -c sleep 0
      /usr/bin/pmset -c displaysleep 20
      /usr/bin/pmset -c ttyskeepawake 1
    '';
  };

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

  launchd.daemons.caffeinate-ac = {
    command = "/usr/bin/caffeinate -s";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
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
