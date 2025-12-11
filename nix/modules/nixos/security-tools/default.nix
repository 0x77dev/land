{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.security-tools;
  # Get all users configured via Snowfall Lib
  snowfallUsers = attrNames config.snowfallorg.users;
in
{
  options.modules.security-tools = {
    enable = mkEnableOption "security-tools";
  };

  config = mkIf cfg.enable {
    # Enable 1Password GUI and configure polkit policy owners
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = snowfallUsers;
    };

    # Enable 1Password CLI
    programs._1password = {
      enable = true;
    };
  };
}
