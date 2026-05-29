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
    # Enable 1Password GUI only on systems with a display manager + graphics,
    # and configure polkit policy owners when present.
    programs._1password-gui = {
      enable = mkDefault config.modules.graphical.enable;
      polkitPolicyOwners = snowfallUsers;
    };

    # Enable 1Password CLI
    programs._1password = {
      enable = true;
    };
  };
}
