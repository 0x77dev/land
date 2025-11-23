{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.cluster.incus;
  netCfg = config.modules.network.incus;
in
{
  options = {
    modules.cluster.incus = {
      enable = lib.mkEnableOption "Incus Cluster Member";
    };

    modules.network.incus = {
      enable = lib.mkEnableOption "Incus bridge networks";

      sourceInterface = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Source interface for public bridge (e.g., bond0)";
        example = "bond0";
      };

      publicBridge = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "incuspublic";
          description = "Name of the public bridge (bridged to LAN)";
        };

        mtu = lib.mkOption {
          type = lib.types.int;
          default = 1500;
          description = "MTU for the public bridge";
        };
      };

      isolatedBridge = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "incusisolated";
          description = "Name of the isolated bridge (local NAT only)";
        };

        address = lib.mkOption {
          type = lib.types.str;
          default = "10.0.200.1/24";
          description = "IPv4 address for isolated bridge (CIDR notation)";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = "isolated.incus";
          description = "Domain name for DHCP clients";
        };

        mtu = lib.mkOption {
          type = lib.types.int;
          default = 1500;
          description = "MTU for the isolated bridge";
        };
      };

      ovnPrivate = {
        enable = lib.mkEnableOption "OVN private network for cluster-wide instances";

        name = lib.mkOption {
          type = lib.types.str;
          default = "incusprivate";
          description = "Name of the OVN private network";
        };

        subnet = lib.mkOption {
          type = lib.types.str;
          default = "172.16.0.0/24";
          description = "IPv4 subnet for OVN private network (CIDR notation)";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = "private.incus";
          description = "Domain name for DHCP clients";
        };

        mtu = lib.mkOption {
          type = lib.types.int;
          default = 1442;
          description = "MTU for OVN (default allows Geneve tunnels)";
        };

        enableNAT = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable NAT for OVN network";
        };
      };
    };
  };

  config = lib.mkMerge [
    # Incus cluster configuration
    (lib.mkIf cfg.enable {
      virtualisation.incus = {
        enable = true;
        softDaemonRestart = true;
        ui.enable = true;
        # For clustering with OVN: preseed must be null for manual init
        preseed = null;
      };

      boot.kernelModules = [
        "vhost_vsock"
        "openvswitch" # Required for OVN
      ];

      networking.nftables.enable = true;

      # OVN packages
      environment.systemPackages = with pkgs; [
        incus-lts
        openvswitch # OVN switch
        ovn # OVN controller and northbound/southbound daemons
      ];

      networking.firewall = {
        allowedTCPPorts = [
          8443 # Incus cluster
          6641 # OVN northbound DB
          6642 # OVN southbound DB
        ];
        allowedUDPPorts = [
          6081 # Geneve tunnels for OVN
        ];
        trustedInterfaces = [
          "incusbr0"
          netCfg.publicBridge.name
          netCfg.isolatedBridge.name
        ];
      };

      users.users.mykhailo.extraGroups = [ "incus-admin" ];

      boot.kernel.sysctl = {
        "net.core.netdev_max_backlog" = 182757;
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      # Enable Open vSwitch (required for OVN)
      virtualisation.vswitch = {
        enable = true;
        package = pkgs.openvswitch;
      };

      # Enable OVN Controller if OVN private network is enabled
      systemd.services = lib.mkIf netCfg.ovnPrivate.enable {
        ovn-controller = {
          description = "Open Virtual Network Controller";
          after = [
            "network.target"
            "ovs-vswitchd.service"
            "ovsdb-server.service"
          ];
          requires = [
            "ovs-vswitchd.service"
            "ovsdb-server.service"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.ovn}/bin/ovn-controller unix:/var/run/openvswitch/db.sock";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    })

    # Incus network bridges configuration
    (lib.mkIf (netCfg.enable && cfg.enable) {
      assertions = [
        {
          assertion = netCfg.sourceInterface != null;
          message = "modules.network.incus.sourceInterface must be set when incus networks are enabled";
        }
      ];

      systemd.network = {
        netdevs = {
          # Public bridge (bridged to LAN)
          "10-${netCfg.publicBridge.name}" = {
            netdevConfig = {
              Name = netCfg.publicBridge.name;
              Kind = "bridge";
            };
            extraConfig = ''
              [Bridge]
              STP=no
              VLANFiltering=no
            '';
          };

          # Isolated bridge (local NAT only - NOT cluster-wide)
          "10-${netCfg.isolatedBridge.name}" = {
            netdevConfig = {
              Name = netCfg.isolatedBridge.name;
              Kind = "bridge";
            };
            extraConfig = ''
              [Bridge]
              STP=no
              VLANFiltering=no
            '';
          };
        };

        networks = {
          # Configure public bridge - attach to source interface
          "30-${netCfg.publicBridge.name}" = {
            matchConfig.Name = netCfg.publicBridge.name;
            bridge = [ netCfg.sourceInterface ];
            networkConfig = {
              LinkLocalAddressing = "no";
              LLDP = true;
              EmitLLDP = "customer-bridge";
              IPv6AcceptRA = false;
            };
            linkConfig = {
              MTUBytes = toString netCfg.publicBridge.mtu;
            };
          };

          # Attach source interface to public bridge
          "40-${netCfg.sourceInterface}-bridge" = {
            matchConfig.Name = netCfg.sourceInterface;
            networkConfig = {
              Bridge = netCfg.publicBridge.name;
              LinkLocalAddressing = "no";
            };
          };

          # Configure isolated bridge with NAT (local only)
          "30-${netCfg.isolatedBridge.name}" = {
            matchConfig.Name = netCfg.isolatedBridge.name;
            address = [ netCfg.isolatedBridge.address ];
            networkConfig = {
              DHCPServer = true;
              IPMasquerade = "ipv4";
              IPv6SendRA = false;
            };
            dhcpServerConfig = {
              PoolOffset = 50;
              PoolSize = 200;
              EmitDNS = true;
              DNS = "_server_address";
            };
            linkConfig = {
              MTUBytes = toString netCfg.isolatedBridge.mtu;
            };
          };
        };
      };

      # Additional firewall rules for bridges
      networking.firewall = {
        allowedTCPPorts = [
          53 # DNS
          67 # DHCP
        ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
        ];
        trustedInterfaces = [
          netCfg.publicBridge.name
          netCfg.isolatedBridge.name
        ];
      };
    })

    # OVN private network configuration (cluster-wide)
    (lib.mkIf (netCfg.ovnPrivate.enable && cfg.enable) {
      # OVN requires the public bridge as uplink
      assertions = [
        {
          assertion = netCfg.enable;
          message = "modules.network.incus.enable must be true when using OVN";
        }
      ];

      # OVN packages and services are configured above
      # Preseed remains null - OVN network must be created manually after cluster init
      # See docs/incus/ovn-setup.md for initialization instructions

      # Ensure OVN geneve port is open
      networking.firewall.allowedUDPPorts = [ 6081 ];
    })
  ];
}
