# Before using this configuration, you MUST read and understand the NOTICE file
# in the parent directory. By using this software, you agree to be bound by its
# terms. See: ../NOTICE for complete legal disclaimer and terms of use.
{ inputs, ... }:
let
  containerConfig =
    { pkgs, lib, ... }:
    let
      # Media root directory - all media content lives here
      mediaRoot = "/data";
      mediaUser = "media";
      mediaGroup = "media";
      # wgcf namespace veth address: tailscale serve proxies admin traffic
      # here directly, bypassing the wgcf accessibleFrom source filter (which
      # would blackhole 100.64.0.0/10 tailnet traffic).
      vpnUpstream = "192.168.15.1";

      # Servarr services running in the wgcf namespace — each gets its own
      # tailscale serve port (tailnet:port → vpnUpstream:port).
      servarrServices = [
        {
          name = "sonarr";
          port = 8989;
        }
        {
          name = "radarr";
          port = 7878;
        }
        {
          name = "lidarr";
          port = 8686;
        }
        {
          name = "prowlarr";
          port = 9696;
        }
        {
          name = "readarr";
          port = 8787;
        }
        {
          name = "whisparr";
          port = 6969;
        }
      ];

      # tailscale serve endpoints: one tailnet port per *user-facing* service.
      # The *arrs and aria2 live in the wgcf namespace (vpnUpstream); jellyfin
      # runs in the container root netns (localhost). FlareSolverr (8191) is
      # prowlarr-internal infra with no UI, so it is NOT exposed on the tailnet.
      serveEndpoints = {
        "tcp:8096" = "http://localhost:8096"; # Jellyfin
      }
      // builtins.listToAttrs (
        map (s: {
          name = "tcp:${toString s.port}";
          value = "http://${vpnUpstream}:${toString s.port}";
        }) servarrServices
      )
      // {
        "tcp:6800" = "http://${vpnUpstream}:6800"; # aria2 RPC
      };
    in
    {
      imports = [
        inputs.vpn-confinement.nixosModules.default
        ../../../../modules/nixos/wgcf
      ];

      system.stateVersion = "25.11";

      # The container's own iptables firewall must be off in this shared host
      # netns: it default-drops INPUT and would kill LAN samba/avahi/wsdd and
      # the host's tailnet SSH/zmx at boot. All filtering lives in the host
      # firewall (this file's outer networking.firewall block) + tailscale.
      networking.firewall.enable = false;

      # Services configuration
      services = {
        # Cloudflare Warp VPN
        wgcf = {
          enable = true;
          # Admin access to the *arr web UIs is via tailscale serve, which
          # proxies directly to the wgcf namespace veth (vpnUpstream) — no LAN
          # port mappings needed. openVPNPorts stays for aria2 inbound BT.
          openVPNPorts = map (port: {
            inherit port;
            protocol = "both";
          }) (builtins.genList (i: 50101 + i) 9);
        };

        # Jellyfin Media Server (Free Software) — replaces Plex. Dedicated
        # jellyfin user/group; native VAAPI transcoding on the MS-01 iGPU.
        jellyfin = {
          enable = true;
          openFirewall = false; # exposed via nginx + tailscale serve, not direct
          hardwareAcceleration = {
            enable = true;
            type = "vaapi";
            device = "/dev/dri/renderD128";
          };
          transcoding = {
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              mpeg2 = true;
              vc1 = true;
              vp9 = true;
            };
            hardwareEncodingCodecs = {
              hevc = true;
            };
          };
        };

        # Aria2 downloader
        aria2 = {
          enable = true;
          openPorts = true;
          # RPC secret is generated locally at boot (no external secret manager).
          rpcSecretFile = "/var/lib/aria2/rpc-secret";
          settings = {
            # Basic
            dir = "${mediaRoot}/downloads";
            continue = true;
            max-concurrent-downloads = 5;
            max-overall-download-limit = 0;
            max-download-limit = 0;

            # Advanced
            allow-overwrite = true;
            allow-piece-length-change = true;
            always-resume = true;
            async-dns = false;
            auto-file-renaming = true;
            content-disposition-default-utf8 = true;

            # Disk I/O
            file-allocation = "falloc";
            no-file-allocation-limit = "8M";
            disk-cache = "64M";

            # HTTP/FTP/SFTP
            max-connection-per-server = 16;
            min-split-size = "8M";
            split = 32;
            user-agent = "Transmission/2.77";
            enable-http-pipelining = true;

            # RPC
            enable-rpc = true;
            rpc-listen-port = 6800;
            rpc-listen-all = true;
            rpc-allow-origin-all = true;

            # BitTorrent
            bt-max-peers = 0;
            listen-port = [
              {
                from = 50101;
                to = 50109;
              }
            ];
            seed-ratio = 0;
            seed-time = 0;
            enable-dht = true;
            enable-dht6 = true;
            dht-listen-port = "50101-50109";
            enable-peer-exchange = true;
            bt-enable-lpd = true;
            peer-id-prefix = "-TR2770-";
            peer-agent = "Transmission/2.77";
            bt-seed-unverified = true;
          };
        };

        # Servarr stack
        sonarr = {
          enable = true;
          user = "media";
          group = "media";
        };

        radarr = {
          enable = true;
          user = "media";
          group = "media";
        };

        lidarr = {
          enable = true;
          user = "media";
          group = "media";
        };

        prowlarr.enable = true;

        flaresolverr.enable = true;

        readarr = {
          enable = true;
          user = "media";
          group = "media";
        };

        whisparr = {
          enable = true;
          user = "media";
          group = "media";
        };
        # All web UIs are exposed via tailscale serve (each on its own tailnet
        # port on the media-container node) — no nginx, no LAN/DNS vhosts.
        tailscale = {
          enable = true;
          interfaceName = "userspace-networking";
        };
        tailscale.serve = {
          enable = true;
          services.media.endpoints = serveEndpoints;
        };
      };

      # Create media directory structure
      # Format: "type path mode user group age argument"
      # Using 0777 for universal r/w access by all services
      systemd.tmpfiles.rules = [
        "d ${mediaRoot}           0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/downloads 0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/tv        0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/movies    0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/music     0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/books     0777 ${mediaUser} ${mediaGroup} -"
        "d ${mediaRoot}/xxx       0777 ${mediaUser} ${mediaGroup} -"
      ];

      # VPN Confinement for Servarr services
      systemd.services = {
        # Generate the aria2 RPC secret locally on first boot.
        aria2-rpc-secret = {
          wantedBy = [ "multi-user.target" ];
          before = [ "aria2.service" ];
          serviceConfig.Type = "oneshot";
          script = ''
            install -d -m 0700 /var/lib/aria2
            if [ ! -s /var/lib/aria2/rpc-secret ]; then
              ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/aria2/rpc-secret
              chmod 0600 /var/lib/aria2/rpc-secret
            fi
          '';
        };

        sonarr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        radarr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        lidarr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        prowlarr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        readarr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        whisparr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        aria2.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
        flaresolverr.vpnConfinement = {
          enable = true;
          vpnNamespace = "wgcf";
        };
      };

      users = {
        users.media = {
          isSystemUser = true;
          group = "media";
          uid = 994;
        };
        groups.media = {
          gid = 994;
        };
      };

      # Additional media tools
      environment.systemPackages = with pkgs; [
        ffmpeg
        aria2
        nvtopPackages.intel
        intel-gpu-tools
      ];

      # Hardware acceleration
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver # VAAPI driver for modern Intel GPUs (Broadwell+)
          intel-vaapi-driver # Older VAAPI driver (for compatibility)
          libva-vdpau-driver
          intel-gpu-tools
          libvdpau-va-gl
          intel-compute-runtime # OpenCL support
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          intel-media-driver
          intel-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
        ];
        enable32Bit = true;
      };

      networking.hostName = lib.mkForce "media-container";
    };
in
{
  containers.media = {
    autoStart = true;
    # /dev/net/tun + CAP_NET_ADMIN for the wgcf WireGuard namespace;
    # CAP_SYS_ADMIN so `ip netns` can create the named namespace.
    enableTun = true;
    additionalCapabilities = [
      "CAP_NET_ADMIN"
      "CAP_SYS_ADMIN"
    ];
    # Host/container uids stay 1:1 so the media uid (994) owns /data.
    privateUsers = "no";
    specialArgs = { inherit inputs; };
    bindMounts = {
      "/data" = {
        hostPath = "/data";
        isReadOnly = false;
      };
      # Intel iGPU render nodes for Jellyfin VAAPI transcoding.
      "/dev/dri" = {
        hostPath = "/dev/dri";
        isReadOnly = false;
      };
    };
    allowedDevices = [
      {
        # MS-01 iGPU is card1 (pci-0000:00:02.0), verified on the target host.
        node = "/dev/dri/card1";
        modifier = "rw";
      }
      {
        node = "/dev/dri/renderD128";
        modifier = "rw";
      }
    ];
    config = containerConfig;
  };
}
