# K3s Cluster module for NixOS
# Supports primary (server) and worker (agent) nodes

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.cluster;
in
{
  options.modules.cluster = {
    enable = mkEnableOption "K3s cluster with optimal settings";

    role = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "agent";
      description = "Role of this node in the cluster (server = primary, agent = worker)";
    };

    clusterInit = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node initializes a new cluster (first server node only)";
    };

    serverAddr = mkOption {
      type = types.str;
      default = "";
      example = "https://server-node:6443";
      description = "Address of a server node to join (required for worker nodes)";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--disable=traefik" "--node-ip=192.168.1.10" ];
      description = "Additional flags to pass to k3s";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the necessary firewall ports for k3s";
    };

    storageSupport = {
      longhorn = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Longhorn storage prerequisites";
      };

      nfs = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NFS storage prerequisites";
      };

      zfs = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ZFS storage prerequisites";
      };
    };

    addDiskoDatasets = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add k3s and longhorn ZFS datasets to disko configuration";
    };
  };

  config = mkIf cfg.enable {
    # K3s specific configuration
    services.k3s = {
      enable = true;
      role = cfg.role;
      clusterInit = cfg.clusterInit;
      serverAddr = cfg.serverAddr;
      tokenFile = config.sops.secrets."k3s/token".path;
      extraFlags = cfg.extraFlags;
    };

    # Sops secrets configuration
    sops = {
      defaultSopsFile = ../../../secrets/shared.yaml;
      defaultSopsFormat = "yaml";
      secrets = {
        "k3s/token" = {
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };
    };

    # Open necessary firewall ports
    networking.firewall = mkIf cfg.openFirewall {
      # Always needed
      allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      ] ++ (if cfg.role == "server" then [
        # Server node ports
        2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      ] else [ ]);

      allowedUDPPorts = [
        8472 # k3s, flannel: required if using multi-node for inter-node networking
      ];
    };

    # Sudo without password for wheel group
    security.sudo.wheelNeedsPassword = false;

    # Longhorn prerequisites
    environment.systemPackages = mkIf cfg.storageSupport.longhorn [
      pkgs.nfs-utils
      pkgs.open-iscsi
      pkgs.util-linux
      pkgs.e2fsprogs
      pkgs.xfsprogs
    ];

    services.openiscsi = mkIf cfg.storageSupport.longhorn {
      enable = true;
      name = "${config.networking.hostName}-initiatorhost";
    };

    # NFS support
    boot.supportedFilesystems = mkIf cfg.storageSupport.nfs [ "nfs" ];
    services.rpcbind.enable = mkIf cfg.storageSupport.nfs true;

    # ZFS support for containers
    boot.kernelModules = mkIf cfg.storageSupport.zfs [ "rbd" ];

    # Conditionally add disko ZFS datasets if disko is enabled and we've enabled addDiskoDatasets
    # This uses a cleaner approach to modify the ZFS datasets without overriding existing ones
    disko.devices.zpool = mkIf (cfg.addDiskoDatasets && config.disko.devices.zpool ? "zroot") {
      zroot.datasets = lib.mkMerge [
        { } # Empty set as base case
        # Add k3s dataset
        {
          "k3s" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/rancher/k3s";
            options."com.sun:auto-snapshot" = "true";
          };
        }
        # Add longhorn dataset if longhorn support is enabled
        (mkIf cfg.storageSupport.longhorn {
          "longhorn" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/longhorn";
            options."com.sun:auto-snapshot" = "true";
          };
        })
      ];
    };
  };
}
