{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  servers = builtins.fromJSON (builtins.readFile (lib.snowfall.fs.get-file "config/mcp.json"));
in
{
  config = lib.mkIf cfg.enable {
    programs.mcp = {
      enable = true;
      inherit servers;
    };
  };
}
