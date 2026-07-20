{
  lib,
  pkgs,
  namespace,
  ...
}:
let
  userName = "mykhailo";
  muscle = lib.${namespace}.shared.builders.muscle;
in
{
  modules.cachix-deploy = {
    enable = true;
    agentName = "potato";
  };

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

    # Keep automatic exceptions for Apple software while requiring explicit
    # approval before downloaded applications can accept inbound traffic.
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
      blockAllIncoming = false;
      allowSigned = true;
      allowSignedApp = false;
    };
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
    buildMachines = muscle.mkMachines { sshUser = userName; };
  };

  programs.ssh.knownHosts.muscle = muscle.knownHost;
}
