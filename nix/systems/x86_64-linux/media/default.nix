# Before using this configuration, you MUST read and understand the NOTICE file
# in this directory. By using this software, you agree to be bound by its terms.
# See: ./NOTICE for complete legal disclaimer and terms of use.
{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  # Media root directory - all media content lives here
  mediaRoot = "/data";
  mediaUser = "media";
  mediaGroup = "media";
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
        dir = "${mediaRoot}/downloads";
        rpc-listen-port = 6800;
        rpc-allow-origin-all = true;
        rpc-listen-all = true;

        # Performance & Speed Optimization
        max-connection-per-server = 16;
        split = 32;
        min-split-size = "1M";
        max-concurrent-downloads = 16;
        max-overall-download-limit = 0;
        max-download-limit = 0;

        # Disk I/O Optimization
        file-allocation = "falloc";
        disk-cache = "64M";

        enable-http-pipelining = true;

        # BitTorrent Optimization
        bt-max-peers = 0; # Unlimited peers
        enable-dht = true;
        enable-peer-exchange = true;
        bt-enable-lpd = true; # Local Peer Discovery
        bt-seed-unverified = true;
        seed-ratio = 2.0;
        seed-time = 60;
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
  };

  virtualisation.incus.agent.enable = true;

  # Create media directory structure
  # Format: "type path mode user group age argument"
  systemd.tmpfiles.rules = [
    "d ${mediaRoot}           0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/downloads 0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/tv        0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/movies    0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/music     0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/books     0775 ${mediaUser} ${mediaGroup} -"
    "d ${mediaRoot}/xxx       0775 ${mediaUser} ${mediaGroup} -"
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
    aria2 = {
      vpnConfinement = {
        enable = true;
        vpnNamespace = "wgcf";
      };
      # Run as media user for shared directory access
      serviceConfig = {
        User = lib.mkForce mediaUser;
        Group = lib.mkForce mediaGroup;
        DynamicUser = lib.mkForce false;
      };
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
