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
    # Note: 1Password is configured at the system level (NixOS/Darwin modules)
    # not in home-manager as the programs._1password options are system-level only

    home.packages = with pkgs; [
      yubikey-personalization
      yubikey-manager
      sops
      age
      ssh-to-age
    ];
  };
}
