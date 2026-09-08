{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.ai;
in
{
  imports = [
    ./atuin-hooks.nix
    ./opencode.nix
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.bun
        pkgs.llm-agents.claude-code
        pkgs.llm-agents.codex
        pkgs.llm-agents.cursor-agent
        pkgs.llm-agents.omp
      ];
    };
  };
}
