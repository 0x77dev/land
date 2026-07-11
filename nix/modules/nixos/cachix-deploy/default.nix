{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.cachix-deploy;
  tokenCheck = pkgs.writeShellScript "check-cachix-agent-token" ''
    set -eu

    token_file=${lib.escapeShellArg cfg.tokenFile}

    if [ ! -f "$token_file" ] || [ -L "$token_file" ]; then
      echo "Cachix Deploy token is not provisioned at $token_file" >&2
      exit 1
    fi

    if [ "$(${pkgs.coreutils}/bin/stat -c '%U:%G:%a' "$token_file")" != "root:root:600" ]; then
      echo "Cachix Deploy token must be a root:root 0600 regular file" >&2
      exit 1
    fi

    ${pkgs.gawk}/bin/awk '
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
  '';
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
      default = "/var/lib/cachix-deploy/agent.token";
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

    # Cachix Deploy is the only unattended system deployment authority.
    system.autoUpgrade.enable = lib.mkForce false;

    services.cachix-agent = {
      enable = true;
      name = cfg.agentName;
      profile = "system";
      credentialsFile = cfg.tokenFile;
    };

    systemd = {
      paths.cachix-agent-token = {
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          PathExists = cfg.tokenFile;
          Unit = "cachix-agent.service";
        };
      };

      services.cachix-agent = {
        # The path unit starts the service when provisioning creates the token,
        # avoiding a failed unit during otherwise healthy boots.
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          EnvironmentFile = lib.mkForce "-${cfg.tokenFile}";
          ExecStartPre = [ tokenCheck ];
          RestartSec = lib.mkForce 30;
          StateDirectory = "cachix-deploy";
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
      };
    };
  };
}
