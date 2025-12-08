# Cloudflare Warp VPN module using wgcf
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.wgcf;
  wgcfStateDir = "/var/lib/wgcf";
  wgcfProfilePath = "${wgcfStateDir}/wgcf-profile.conf";
in
{
  options.services.wgcf = {
    enable = lib.mkEnableOption "Cloudflare Warp VPN using wgcf";

    accessibleFrom = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.168.0.0/16" ];
      description = "Subnets that can access services in the VPN namespace";
    };

    portMappings = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.port;
              description = "Port on host";
            };
            to = lib.mkOption {
              type = lib.types.port;
              description = "Port in VPN namespace";
            };
            protocol = lib.mkOption {
              type = lib.types.enum [
                "tcp"
                "udp"
                "both"
              ];
              default = "tcp";
              description = "Transport protocol";
            };
          };
        }
      );
      default = [ ];
      description = "Port mappings from host to VPN namespace";
    };

    openVPNPorts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Port to open through VPN";
            };
            protocol = lib.mkOption {
              type = lib.types.enum [
                "tcp"
                "udp"
                "both"
              ];
              default = "tcp";
              description = "Transport protocol";
            };
          };
        }
      );
      default = [ ];
      description = "Ports accessible through VPN interface";
    };
  };

  config = lib.mkIf cfg.enable {
    # VPN network namespace
    vpnNamespaces.wgcf = {
      enable = true;
      wireguardConfigFile = wgcfProfilePath;
      inherit (cfg) accessibleFrom portMappings openVPNPorts;
    };

    # wgcf setup service
    systemd.services.wgcf-setup = {
      description = "Generate Cloudflare Warp WireGuard configuration";
      before = [ "wgcf.service" ];
      requiredBy = [ "wgcf.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "wgcf";
        WorkingDirectory = wgcfStateDir;
      };
      path = [
        pkgs.wgcf
        pkgs.gnused
      ];
      script = ''
        # Register new account if not exists
        if [ ! -f wgcf-account.toml ]; then
          wgcf register --accept-tos
        fi

        # Always regenerate profile to ensure it's current
        wgcf generate

        # Replace hostname/IPv6 endpoint with IPv4 (Cloudflare Warp IPv4 endpoint)
        sed -i 's/Endpoint = .*/Endpoint = 162.159.192.1:2408/' wgcf-profile.conf
      '';
    };

    environment.systemPackages = [
      pkgs.wgcf
      pkgs.wireguard-tools
    ];
  };
}
