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
      defaultSopsFile = ../../secrets/shared.yaml;
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

    # # Longhorn prerequisites
    environment.systemPackages = mkIf cfg.storageSupport.longhorn [
      pkgs.nfs-utils
      pkgs.util-linux
      pkgs.e2fsprogs
      pkgs.xfsprogs
      pkgs.openiscsi
    ];

    services.openiscsi = mkIf cfg.storageSupport.longhorn {
      enable = true;
      name = "${config.networking.hostName}-initiatorhost";
    };

    # NOTE: Instead of merging datasets here (which causes recursion), add these directly to your disko-config.nix:
    # 
    # k3s = {
    #   type = "zfs_fs";
    #   mountpoint = "/var/lib/rancher/k3s";
    #   options."com.sun:auto-snapshot" = "true";
    # };
    # 
    # longhorn = {
    #   type = "zfs_fs"; 
    #   mountpoint = "/var/lib/longhorn";
    #   options."com.sun:auto-snapshot" = "true";
    # };
  };
}
