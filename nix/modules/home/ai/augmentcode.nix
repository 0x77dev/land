{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";
  baseSettings = builtins.fromJSON (builtins.readFile (configDir + "/augmentcode/settings.json"));
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
    home.file = {
      ".augment/settings.json".text = builtins.toJSON (baseSettings // { inherit mcpServers; });
      ".augment/rules/land.md".source = configDir + "/ai/AGENTS.md";
    };
  };
}
