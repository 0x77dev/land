{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.cluster.incus;
in
{
  options = {
    modules.cluster.incus = {
      enable = lib.mkEnableOption "Incus Cluster Member";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.incus = {
      enable = true;
      softDaemonRestart = true;
      ui.enable = true;
      # For clustering: preseed must be null for manual init
      preseed = null;
    };

    boot.kernelModules = [ "vhost_vsock" ];
    networking.nftables.enable = true;

    networking.firewall = {
      allowedTCPPorts = [ 8443 ];
      trustedInterfaces = [ "incusbr0" ];
    };

    users.users.mykhailo.extraGroups = [ "incus-admin" ];
    environment.systemPackages = [ pkgs.incus-lts ];

    boot.kernel.sysctl = {
      "net.core.netdev_max_backlog" = 182757;
    };
  };
}
