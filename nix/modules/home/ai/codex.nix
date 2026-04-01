{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";
  baseSettings = fromTOML (builtins.readFile (configDir + "/codex/config.toml"));
  mcpServers = lib.mapAttrs (
    _: server: if server ? url then { inherit (server) url; } else server
  ) config.programs.mcp.servers;
in
{
  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
      settings = baseSettings // {
        mcp_servers = mcpServers;
      };
      custom-instructions = builtins.readFile (configDir + "/ai/AGENTS.md");
    };
  };
}
