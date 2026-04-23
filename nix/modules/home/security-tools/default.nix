{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.security-tools;
in
{
  options.modules.home.security-tools = {
    enable = mkEnableOption "security-tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      pdf-sign
      yubikey-personalization
      yubikey-manager
      sops
      age
      ssh-to-age
    ];
  };
}
