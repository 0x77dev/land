{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.modules.home.ai;
  mutableConfigTargets =
    let
      inherit (config.xdg) configHome;
    in
    [
      "${configHome}/opencode/config.json"
      "${configHome}/opencode/AGENTS.md"
      "${configHome}/opencode/oh-my-openagent.json"
    ];
in
{
  imports = [
    ./mcp.nix
    ./opencode.nix
    ./shell
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    services.ollama.enable = true;

    home = {
      sessionVariables = {
        OMO_SEND_ANONYMOUS_TELEMETRY = "0";
        OMO_DISABLE_POSTHOG = "1";
        OTEL_SDK_DISABLED = "true";
      };

      packages = with pkgs.${namespace}; [
        unifi-network-mcp
        unifi-access-mcp
        unifi-protect-mcp
        unifi-mcp-relay
      ];

      # The Home Manager program modules generate store-backed config files.
      # Materialize them after activation so the CLIs can update their own state.
      activation.materializeAiConfigs = {
        after = [ "linkGeneration" ];
        before = [ ];
        data = ''
          materialize_file() {
            local target="$1"
            local backup_path="$1.backup"
            local temp_file

            if [[ ! -L "$target" ]]; then
              return 0
            fi

            if [[ -v DRY_RUN ]]; then
              verboseEcho "Would materialize $target"
              return 0
            fi

            temp_file="$(mktemp "$HOME/.hm-ai-config.XXXXXX")"
            cat "$target" > "$temp_file"
            chmod 0644 "$temp_file"
            mv "$temp_file" "$target"
            rm -f "$backup_path"
          }
        ''
        + lib.concatMapStringsSep "\n" (target: ''
          materialize_file ${lib.escapeShellArg target}
        '') mutableConfigTargets;
      };
    };
  };
}
