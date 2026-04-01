{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
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
  };
}
