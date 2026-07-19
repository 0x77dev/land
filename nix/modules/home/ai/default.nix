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
    ./opencode.nix
    ./shell
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs.llm-agents; [
      claude-code
      codex
      cursor-agent
      pi
    ];

    home.sessionVariables = {
      OTEL_SDK_DISABLED = "true";
    };
  };
}
