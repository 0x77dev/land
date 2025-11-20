{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.security;
in
{
  options.modules.home.security = {
    enable = mkEnableOption "security";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      _1password-gui
      _1password-cli
      yubikey-personalization
      yubikey-manager
      sops
      age
      ssh-to-age
    ];
  };
}
