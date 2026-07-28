{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.zmx;
in
{
  options.modules.zmx = {
    enable = mkEnableOption "zmx session persistence";

    users = mkOption {
      type = types.listOf types.str;
      default = [ "mykhailo" ];
      description = "Users whose systemd user managers should persist for detached zmx sessions.";
    };
  };

  config = mkIf cfg.enable {
    # System-wide install keeps `RemoteCommand zmx attach` working for inbound SSH even
    # before or without the user's home-manager profile.
    environment.systemPackages = [ pkgs.zmx ];

    # zmx daemons are plain user processes with sockets under /run/user/<uid>/zmx;
    # without lingering, logind tears down the user runtime dir and slice when the
    # last SSH session ends, killing detached sessions.
    users.users = lib.genAttrs cfg.users (_: {
      linger = true;
    });
  };
}
