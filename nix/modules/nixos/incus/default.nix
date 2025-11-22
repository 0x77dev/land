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
        # Storage configuration
        storage_pools = [
          {
            name = "default";
            driver = "zfs";
            config.source = cfg.storage.zfsDataset;
          }
        ];

        # Network configuration
        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              "ipv4.address" = "10.10.10.1/24";
              "ipv4.nat" = "true";
              "ipv6.address" = "none";
            };
          }
        ];

        # Default profile with root disk and network
        profiles = [
          {
            name = "default";
            devices = {
              eth0 = {
                name = "eth0";
                network = "incusbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
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
