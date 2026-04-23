{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  mutableConfigTargets =
    let
      inherit (config.home) homeDirectory;
      inherit (config.xdg) configHome;
    in
    [
      "${homeDirectory}/.claude/settings.json"
      "${homeDirectory}/.claude/CLAUDE.md"
      "${homeDirectory}/.codex/config.toml"
      "${homeDirectory}/.codex/config.yaml"
      "${homeDirectory}/.codex/AGENTS.md"
      "${configHome}/codex/config.toml"
      "${configHome}/codex/config.yaml"
      "${configHome}/codex/AGENTS.md"
      "${configHome}/opencode/config.json"
      "${configHome}/opencode/AGENTS.md"
      "${configHome}/opencode/oh-my-opencode.json"
    ];
in
{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./amp.nix
    ./augmentcode.nix
    ./mcp.nix
    ./opencode.nix
    ./shell
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    services.ollama.enable = true;

    # The Home Manager program modules generate store-backed config files.
    # Materialize them after activation so the CLIs can update their own state.
    home.activation.materializeAiConfigs = {
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
}
