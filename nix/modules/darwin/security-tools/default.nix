{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.security-tools;
in
{
  options.modules.security-tools = {
    enable = mkEnableOption "security-tools";
  };

  config = mkIf cfg.enable {
    # Enable 1Password GUI
    programs._1password-gui = {
      enable = true;
    };

    # Enable 1Password CLI
    programs._1password = {
      enable = true;
    };

    environment.systemPackages =
      with pkgs;
      lib.mkAfter [
        _1password-gui
        _1password-cli
      ];
  };
}
