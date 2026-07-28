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
  };

  config = mkIf cfg.enable {
    # macOS has no logind/linger concern: launchd does not reap user daemons on SSH
    # logout. The Home Manager module hardens ZMX_DIR under the XDG state directory,
    # away from macOS periodic TMPDIR cleanup. Keep this package in the base sshd
    # PATH so `ssh <host> zmx ...` and `RemoteCommand zmx attach` work without the
    # per-user profile.
    environment.systemPackages = [ pkgs.zmx ];
  };
}
