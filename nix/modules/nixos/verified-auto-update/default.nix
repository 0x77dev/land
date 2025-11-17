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
      - Persistent timer (runs missed schedules after wake/boot)
      - Multiple daily schedule times (3 AM, 9 AM, 3 PM, 9 PM)
      - Randomized delay to prevent thundering herd
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
      type = lib.types.str;
      default = "*-*-* 03,09,15,21:00:00";
      description = "Update schedule (systemd OnCalendar format, runs at 3 AM, 9 AM, 3 PM, 9 PM)";
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

    systemd = {
      services.verified-auto-update = {
        description = "Verified Automatic System Update";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        environment = {
          FLAKE_URL = cfg.flakeUrl;
          ALLOWED_GPG_KEYS = lib.concatStringsSep "," cfg.allowedGpgKeys;
        }
        // lib.optionalAttrs (cfg.publicKeys != [ ]) {
          # Reference keyring directly from Nix store
          VERIFIED_AUTO_UPDATE_GNUPGHOME = "${gpgKeyring}";
        }
        // lib.optionalAttrs (cfg.allowedWorkflowRepository != null) {
          ALLOWED_WORKFLOW_REPOSITORY = cfg.allowedWorkflowRepository;
        };

        serviceConfig = {
          Type = "oneshot";
          # Reference package directly from Nix store
          ExecStart = "${verifyAndUpdate}/bin/verify-and-update";
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
