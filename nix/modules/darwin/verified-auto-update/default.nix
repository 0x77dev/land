{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:

let
  cfg = config.services.verified-auto-update;
  defaults = lib.${namespace}.shared.verified-auto-update;

  # Resolve GPG key source paths from flake root
  resolvedPublicKeys = map (key: {
    source = inputs.self + key.source;
    trust = key.trust or null;
  }) cfg.publicKeys;

  # Build GPG keyring package using shared builder
  gpgKeyring = lib.${namespace}.builders.mkGpgKeyring pkgs {
    name = "verified-auto-update-gpg-keyring";
    publicKeys = resolvedPublicKeys;
  };

  # Reference verify-and-update package from nix store
  verifyAndUpdate = pkgs.${namespace}.verify-and-update;
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

    allowedGpgKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaults.allowedGpgKeys;
      example = [ "C33BFD3230B660CF147762D2BF5C81B531164955" ];
      description = "GPG key fingerprints allowed for signature verification";
    };

    publicKeys = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Path to GPG public key file relative to flake root";
            };
            trust = lib.mkOption {
              type = lib.types.nullOr (lib.types.ints.between 1 5);
              default = null;
              description = "Trust level: 1=unknown, 2=never, 3=marginal, 4=full, 5=ultimate";
            };
          };
        }
      );
      default = defaults.publicKeys;
      example = lib.literalExpression ''
        [
          { source = "/gpg/keys/signing.asc"; trust = 5; }
        ]
      '';
      description = "GPG public keys to import with trust levels";
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
      {
        assertion = (cfg.allowedGpgKeys != [ ]) || (cfg.publicKeys != [ ]);
        message = "services.verified-auto-update requires either allowedGpgKeys or publicKeys to be set for GPG verification";
      }
    ];

    environment.systemPackages = [ verifyAndUpdate ];

    # Symlink GPG keyring from Nix store to /etc
    environment.etc."verified-auto-update/gpg-keyring" = lib.mkIf (cfg.publicKeys != [ ]) {
      source = gpgKeyring;
    };

    launchd.daemons.verified-auto-update = {
      serviceConfig = {
        # Reference packages directly from Nix store
        ProgramArguments = [ "${verifyAndUpdate}/bin/verify-and-update" ];
        StartCalendarInterval = cfg.schedule;
        StandardErrorPath = cfg.logPath;
        StandardOutPath = cfg.logPath;
        EnvironmentVariables = {
          FLAKE_URL = cfg.flakeUrl;
          ALLOWED_GPG_KEYS = lib.concatStringsSep "," cfg.allowedGpgKeys;
          # Add /run/current-system/sw/bin for darwin-rebuild
          PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        }
        // lib.optionalAttrs (cfg.publicKeys != [ ]) {
          # Reference keyring directly from Nix store
          VERIFIED_AUTO_UPDATE_GNUPGHOME = "${gpgKeyring}";
        }
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
