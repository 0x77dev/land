{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.vscode-server;
in
{
  options.modules.vscode-server = {
    enable = mkEnableOption "VS Code Server";
  };

  config = mkIf cfg.enable {
    services.vscode-server = {
      enable = true;
      nodejsPackage = pkgs.nodejs_24;
    };
  };
}
