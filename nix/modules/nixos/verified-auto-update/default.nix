{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.services.verified-auto-update;
in
{
  options.services.verified-auto-update = {
    enable = lib.mkEnableOption "verified automatic system updates";

    flakeUrl = lib.mkOption {
      type = lib.types.str;
      example = "github:0x77dev/land";
      description = "Flake URL to update from";
    };

    allowedGpgKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "C33BFD3230B660CF147762D2BF5C81B531164955";
      description = "GPG key fingerprint (required for GPG signatures)";
    };

    allowedWorkflowRepository = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0x77dev/land";
      description = "GitHub repository to enforce (recommended)";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "Update schedule (systemd OnCalendar)";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "1h";
      description = "Random delay";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.flakeUrl != "";
        message = "services.verified-auto-update.flakeUrl must be set";
      }
    ];

    environment.systemPackages = [ pkgs.${namespace}.verify-and-update ];

    systemd = {
      services.verified-auto-update = {
        description = "Verified Automatic System Update";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        environment = {
          FLAKE_URL = cfg.flakeUrl;
        }
        // lib.optionalAttrs (cfg.allowedGpgKey != null) { ALLOWED_GPG_KEY = cfg.allowedGpgKey; }
        // lib.optionalAttrs (cfg.allowedWorkflowRepository != null) {
          ALLOWED_WORKFLOW_REPOSITORY = cfg.allowedWorkflowRepository;
        };

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.${namespace}.verify-and-update}/bin/verify-and-update";
          User = "root";
          StandardOutput = "journal";
          StandardError = "journal";
        };

        unitConfig.OnFailure = "verified-auto-update-failure.service";
      };

      timers.verified-auto-update = {
        description = "Timer for Verified Automatic System Update";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          RandomizedDelaySec = cfg.randomizedDelaySec;
        };
      };

      services.verified-auto-update-failure = {
        description = "Verified Auto-Update Failure Notification";

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/echo 'Verified auto-update failed! Check: journalctl -u verified-auto-update'";
          StandardOutput = "journal";
        };
      };
    };
  };
}
