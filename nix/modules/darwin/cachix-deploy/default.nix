{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.cachix-deploy;
  defaultTokenDirectory = "/var/db/cachix-deploy";
in
{
  options.modules.cachix-deploy = {
    enable = lib.mkEnableOption "Cachix Deploy system agent";

    agentName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = config.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Stable, unique Cachix Deploy agent name.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "${defaultTokenDirectory}/agent.token";
      description = "Absolute host-local path to the root-owned agent token.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.match "[a-z0-9][a-z0-9._-]*" cfg.agentName != null;
        message = "modules.cachix-deploy.agentName must use lowercase letters, digits, dots, underscores, or hyphens";
      }
      {
        assertion =
          lib.hasPrefix "/" cfg.tokenFile
          && !(lib.hasPrefix "${builtins.storeDir}/" cfg.tokenFile)
          && builtins.match ".*[[:space:]].*" cfg.tokenFile == null;
        message = "modules.cachix-deploy.tokenFile must be an absolute, whitespace-free path outside the Nix store";
      }
    ];

    services.cachix-agent = {
      enable = true;
      name = cfg.agentName;
      credentialsFile = cfg.tokenFile;
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      /usr/bin/install -d -o root -g wheel -m 0700 ${defaultTokenDirectory}
    '';

    # The upstream module provides the launchd job. Avoid sourcing the token
    # file as shell code, validate it first, and select nix-darwin's real
    # system profile explicitly.
    launchd.daemons.cachix-agent = {
      script = lib.mkForce ''
        token_file=${lib.escapeShellArg cfg.tokenFile}

        if [ ! -e "$token_file" ]; then
          exit 0
        fi

        if [ ! -f "$token_file" ] || [ -L "$token_file" ]; then
          echo "Cachix Deploy token must be a regular file" >&2
          exit 1
        fi

        if [ "$(/usr/bin/stat -f '%Su:%Sg:%Sp' "$token_file")" != "root:wheel:-rw-------" ]; then
          echo "Cachix Deploy token must be a root:wheel 0600 regular file" >&2
          exit 1
        fi

        /usr/bin/awk '
          NR == 1 && $0 ~ /^CACHIX_AGENT_TOKEN=[^[:space:]]+$/ {
            valid = 1
            next
          }
          {
            valid = 0
            exit
          }
          END {
            exit valid ? 0 : 1
          }
        ' "$token_file" || {
          echo "Cachix Deploy token file must contain exactly one CACHIX_AGENT_TOKEN assignment" >&2
          exit 1
        }

        token_line="$(/usr/bin/awk 'NR == 1 { print; exit }' "$token_file")"
        export CACHIX_AGENT_TOKEN="''${token_line#CACHIX_AGENT_TOKEN=}"

        exec ${lib.getExe pkgs.cachix} deploy agent ${lib.escapeShellArg cfg.agentName} system-profiles/system
      '';

      serviceConfig = {
        KeepAlive = lib.mkForce {
          SuccessfulExit = false;
        };
        ThrottleInterval = 30;
        Umask = 63;
      };
    };
  };
}
