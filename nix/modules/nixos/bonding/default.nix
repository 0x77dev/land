{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.network.bonding;
in
{
  options.modules.network.bonding = {
    enable = lib.mkEnableOption "LACP bonding for dual 10GbE interfaces";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "enp2s0f0np0"
        "enp2s0f1np1"
      ];
      description = "List of network interfaces to bond";
    };

    bondName = lib.mkOption {
      type = lib.types.str;
      default = "bond0";
      description = "Name of the bonded interface";
    };

    vlans = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.ints.between 1 4094;
              description = "VLAN ID";
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "VLAN interface name (alias)";
            };
          };
        }
      );
      default = [ ];
      description = "List of VLANs to create on the bond interface";
      example = [
        {
          id = 4;
          name = "homelab";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    boot.kernelModules = [ "bonding" ];

    systemd.network = {
      enable = true;

      # Create the bond device and VLAN devices
      netdevs = {
        "10-${cfg.bondName}" = {
          netdevConfig = {
            Name = cfg.bondName;
            Kind = "bond";
          };
          bondConfig = {
            Mode = "802.3ad"; # LACP
            TransmitHashPolicy = "layer3+4";
            LACPTransmitRate = "fast"; # 1 second intervals
            MIIMonitorSec = "100ms";
            UpDelaySec = "200ms";
            DownDelaySec = "200ms";
          };
        };
      }
      // lib.listToAttrs (
        map (vlan: {
          name = "11-${vlan.name}";
          value = {
            netdevConfig = {
              Name = vlan.name;
              Kind = "vlan";
            };
            vlanConfig = {
              Id = vlan.id;
            };
          };
        }) cfg.vlans
      );

      # Configure the bond interface with DHCP and attach member interfaces
      networks = {
        "30-${cfg.bondName}" = {
          matchConfig.Name = cfg.bondName;
          vlan = map (vlan: vlan.name) cfg.vlans;
          networkConfig = {
            DHCP = "yes";
            IPv6AcceptRA = true;
          };
          dhcpV4Config = {
            UseDNS = true;
            UseRoutes = true;
          };
          # TODO: TxQueueLength = 10000;
        };
      }
      // lib.listToAttrs (
        lib.imap0 (i: iface: {
          name = "40-bond-member-${toString i}";
          value = {
            matchConfig.Name = iface;
            networkConfig.Bond = cfg.bondName;
            linkConfig.RequiredForOnline = "enslaved";
          };
        }) cfg.interfaces
      )
      // lib.listToAttrs (
        map (vlan: {
          name = "50-${vlan.name}";
          value = {
            matchConfig.Name = vlan.name;
            networkConfig = {
              DHCP = "yes";
              IPv6AcceptRA = true;
            };
            dhcpV4Config = {
              UseDNS = true;
              UseRoutes = true;
            };
          };
        }) cfg.vlans
      );
    };

    # Add ethtool for diagnostics
    environment.systemPackages = [ pkgs.ethtool ];
  };
}
