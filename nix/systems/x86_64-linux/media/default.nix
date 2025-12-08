# Before using this configuration, you MUST read and understand the NOTICE file
# in this directory. By using this software, you agree to be bound by its terms.
# See: ./NOTICE for complete legal disclaimer and terms of use.
{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Media root directory - all media content lives here
  mediaRoot = "/data";
  mediaUser = "media";
  mediaGroup = "media";
  domain = "media.0x77.computer";
  vpnUpstream = "192.168.15.1";

  # Servarr services running in VPN namespace
  serrarvServices = [
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

  # Generate nginx vhost for a Servarr service
  mkSerrarvVhost =
    { name, port }:
    {
      name = "${name}.${domain}";
      value = {
        locations."/" = {
          proxyPass = "http://${vpnUpstream}:${toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_redirect off;
          '';
        };
      };
    };
in
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.11";

  # Sops secrets configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "aria2/rpc_token" = { };
    };
  };

  # Cloudflare Warp VPN
  services.wgcf = {
    enable = true;
    accessibleFrom = [ "192.168.0.0/16" ];
    portMappings = [
      {
        from = 8989;
        to = 8989;
      } # Sonarr
      {
        from = 7878;
        to = 7878;
      } # Radarr
      {
        from = 8686;
        to = 8686;
      } # Lidarr
      {
        from = 9696;
        to = 9696;
      } # Prowlarr
      {
        from = 8787;
        to = 8787;
      } # Readarr
      {
        from = 6969;
        to = 6969;
      } # Whisparr
      {
        from = 6800;
        to = 6800;
      } # Aria2 RPC
      {
        from = 8191;
        to = 8191;
      } # FlareSolverr
    ];
  };

  # Services configuration
  services = {
    jellyfin = {
      enable = true;
    };

    # Aria2 downloader
    aria2 = {
      enable = true;
      openPorts = true;
      rpcSecretFile = config.sops.secrets."aria2/rpc_token".path;
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
        rpc-allow-origin-all = true;

        # BitTorrent
        bt-max-peers = 0;
        listen-port = "50101-50109";
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

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Samba share for media
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "media";
          "netbios name" = "media";
          security = "user";
          "map to guest" = "Bad User";
          # Performance tuning
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
          "read raw" = "yes";
          "write raw" = "yes";
          "use sendfile" = "yes";
          "aio read size" = "16384";
          "aio write size" = "16384";
          "min receivefile size" = "16384";
        };
        data = {
          path = mediaRoot;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = mediaUser;
          "force group" = mediaGroup;
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      };
    };

    # Windows network discovery
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    # mDNS/Bonjour discovery (macOS/Linux)
    avahi = {
      enable = true;
      openFirewall = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    # Nginx reverse proxy for all services
    nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      clientMaxBodySize = "0"; # Unlimited for large media uploads

      virtualHosts = builtins.listToAttrs (
        # Servarr services (DRY generation)
        (map mkSerrarvVhost serrarvServices)
        ++ [
          # AriaNg web UI for aria2
          {
            name = "aria2.${domain}";
            value = {
              locations."/" = {
                root = "${pkgs.ariang}/share/ariang";
                index = "index.html";
              };
              locations."/jsonrpc" = {
                proxyPass = "http://${vpnUpstream}:6800/jsonrpc";
                extraConfig = ''
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_redirect off;
                '';
              };
            };
          }

          # Jellyfin media server
          {
            name = "jellyfin.${domain}";
            value = {
              extraConfig = ''
                client_max_body_size 20M;
              '';
              locations."/" = {
                proxyPass = "http://127.0.0.1:8096";
                extraConfig = ''
                  proxy_set_header X-Forwarded-Protocol $scheme;
                  proxy_set_header X-Forwarded-Host $http_host;
                  proxy_buffering off;
                '';
              };
              locations."/socket" = {
                proxyPass = "http://127.0.0.1:8096";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header X-Forwarded-Protocol $scheme;
                  proxy_set_header X-Forwarded-Host $http_host;
                '';
              };
            };
          }
        ]
      );
    };
  };

  virtualisation.incus.agent.enable = true;

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

  security.sudo.wheelNeedsPassword = false;

  users = {
    users = {
      mykhailo = {
        isNormalUser = true;
        description = "Mykhailo Marynenko";
        extraGroups = [
          "wheel"
          "networkmanager"
          mediaGroup
        ];
        shell = pkgs.fish;
      };
      media = {
        isSystemUser = true;
        group = "media";
        uid = 994;
      };
    };

    groups.media = {
      gid = 994;
    };
  };

  # Additional media tools
  environment.systemPackages = with pkgs; [
    ffmpeg
    aria2
  ];

  # Networking
  networking = {
    hostName = "media";
    domain = "0x77.computer";
    useDHCP = true;
    firewall.enable = false;
  };

  # User configuration
  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  # Hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
}
