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
        }
      ];
      description = "Update schedule";
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
        RunAtLoad = false;
        ProcessType = "Background";
      };
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      mkdir -p "$(dirname ${cfg.logPath})"
      chmod 755 "$(dirname ${cfg.logPath})"
    '';
  };
}
