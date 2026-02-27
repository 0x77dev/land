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
