{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.services.verified-auto-update;
  defaults = lib.${namespace}.shared.verified-auto-update;
in
{
  options.services.verified-auto-update = {
    enable = lib.mkEnableOption ''
      verified automatic system updates with GPG/gitsign verification.

      Handles missed schedules by:
      - Running on system boot/restart (RunAtLoad)
      - Multiple daily schedule times (3 AM, 9 AM, 3 PM, 9 PM)
      - Prevents duplicate runs via lock file
    '';

    flakeUrl = lib.mkOption {
      type = lib.types.str;
      default = defaults.flakeUrl;
      example = "github:0x77dev/land";
      description = "Flake URL to update from";
    };

    allowedGpgKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = defaults.allowedGpgKey;
      example = "C33BFD3230B660CF147762D2BF5C81B531164955";
      description = "GPG key fingerprint (required for GPG signatures)";
    };

    allowedWorkflowRepository = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = defaults.allowedWorkflowRepository;
      example = "0x77dev/land";
      description = "GitHub repository to enforce (recommended)";
    };

    schedule = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            Hour = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "Hour (0-23)";
            };
            Minute = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Minute (0-59)";
            };
          };
        }
      );
      default = [
        {
          Hour = 3;
          Minute = 0;
        } # 3 AM - Primary schedule (after CI)
        {
          Hour = 9;
          Minute = 0;
        } # 9 AM - Morning catchup
        {
          Hour = 15;
          Minute = 0;
        } # 3 PM - Afternoon catchup
        {
          Hour = 21;
          Minute = 0;
        } # 9 PM - Evening catchup
      ];
      description = "Update schedule (multiple times increase chances if system asleep)";
    };

    logPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/verified-auto-update.log";
      description = "Log path";
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

    launchd.daemons.verified-auto-update = {
      serviceConfig = {
        ProgramArguments = [ "${pkgs.${namespace}.verify-and-update}/bin/verify-and-update" ];
        StartCalendarInterval = cfg.schedule;
        StandardErrorPath = cfg.logPath;
        StandardOutPath = cfg.logPath;
        EnvironmentVariables = {
          FLAKE_URL = cfg.flakeUrl;
        }
        // lib.optionalAttrs (cfg.allowedGpgKey != null) { ALLOWED_GPG_KEY = cfg.allowedGpgKey; }
        // lib.optionalAttrs (cfg.allowedWorkflowRepository != null) {
          ALLOWED_WORKFLOW_REPOSITORY = cfg.allowedWorkflowRepository;
        };
        UserName = "root";
        KeepAlive = false;
        RunAtLoad = true;
        ProcessType = "Background";
      };
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      mkdir -p "$(dirname ${cfg.logPath})"
      chmod 755 "$(dirname ${cfg.logPath})"
    '';
  };
}
