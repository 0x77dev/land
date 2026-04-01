{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";
  mcpServers = lib.mapAttrs (
    _: server:
    if server ? url then
      {
        type = "http";
        inherit (server) url;
      }
    else
      server
  ) config.programs.mcp.servers;
in
{
  config = lib.mkIf cfg.enable {
    programs."claude-code" = {
      enable = true;
      settings = builtins.fromJSON (builtins.readFile (configDir + "/claude-code/settings.json"));
      memory.source = configDir + "/ai/AGENTS.md";
      inherit mcpServers;
    };
  };
}
