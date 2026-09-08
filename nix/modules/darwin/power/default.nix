{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.darwin.power;
in
{
  imports = [ ./pmset.nix ];

  options.modules.darwin.power.alwaysOn = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Keep the Mac fully awake and available on every power source.";
  };

  config = lib.mkMerge [
    {
      system.pmset =
        if cfg.alwaysOn then
          {
            all = {
              sleep = 0;
              displaysleep = 0;
              disksleep = 0;
              womp = 1;
              powernap = 0;
              autorestart = 1;
              hibernatemode = 0;
              ttyskeepawake = 1;
              standby = 0;
              lowpowermode = 0;
              tcpkeepalive = 1;
            };
          }
        else
          {
            charger = {
              sleep = 0;
              displaysleep = 20;
              ttyskeepawake = 1;
            };
          };

      launchd.daemons.caffeinate = {
        command = if cfg.alwaysOn then "/usr/bin/caffeinate -dims" else "/usr/bin/caffeinate -s";
        serviceConfig = {
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    }

    (lib.mkIf cfg.alwaysOn {
      power = {
        restartAfterFreeze = true;
        sleep.allowSleepByPowerButton = false;
      };

      system.defaults = {
        CustomUserPreferences.NSGlobalDomain.NSAppSleepDisabled = true;
        CustomUserPreferences."com.apple.screensaver".idleTime = 0;
      };
    })
  ];
}
