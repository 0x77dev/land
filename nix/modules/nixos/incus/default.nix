{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.modules.cluster.incus = {
    enable = lib.mkEnableOption "Incus Cluster Member";
  };

  config = lib.mkIf config.modules.cluster.incus.enable {
    virtualisation.incus = {
      enable = true;
      softDaemonRestart = true;
      ui.enable = true;
      preseed = {
        config = {
          "core.https_address" = ":8443";
        };
      };
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
      # Increase the network bandwidth (NOTE: add txqueuelen 10000 for each interface)
      "net.core.netdev_max_backlog" = 182757;
    };
  };
}
