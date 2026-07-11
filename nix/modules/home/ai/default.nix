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
    home.packages = with pkgs; [
      claude-code
      codex
      cursor-cli
      pi-coding-agent
    ];

    home.sessionVariables = {
      OTEL_SDK_DISABLED = "true";
    };
  };
}
