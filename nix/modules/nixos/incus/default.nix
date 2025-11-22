{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.virtualisation.incus-cluster;

  # Cluster members for identification only
  clusterMembers = [
    "tomato"
    "pickle"
  ];

  isValidMember = builtins.elem config.networking.hostName clusterMembers;
in
{
  options.modules.virtualisation.incus-cluster = {
    enable = lib.mkEnableOption "Incus cluster";

    storage.zfsDataset = lib.mkOption {
      type = lib.types.str;
      default = "zroot/incus";
      description = "ZFS dataset for Incus storage pool";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isValidMember;
        message = "Hostname '${config.networking.hostName}' not in cluster members: ${lib.concatStringsSep ", " clusterMembers}";
      }
    ];

    virtualisation.incus = {
      enable = true;
      package = pkgs.incus-lts;
      ui.enable = true;

      preseed = {
        # Only preseed storage - let user configure networking and clustering manually
        storage_pools = [
          {
            name = "default";
            driver = "zfs";
            config.source = cfg.storage.zfsDataset;
          }
        ];
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
  };
}
