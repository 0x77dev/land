# Before using this configuration, you MUST read and understand the NOTICE file
# in this directory. By using this software, you agree to be bound by its terms.
# See: ./NOTICE for complete legal disclaimer and terms of use.
{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.11";

  # Sops secrets configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # WireGuard secrets
    secrets = {
      "wg/private_key" = { };
      "wg/address" = { };
      "wg/endpoint" = { };
      "wg/public_key" = { };
      "wg/dns" = { };
      "aria2/rpc_token" = { };
    };

    # Generate WireGuard config from secrets template
    templates."wg0.conf" = {
      content = ''
        [Interface]
        PrivateKey = ${config.sops.placeholder."wg/private_key"}
        Address = ${config.sops.placeholder."wg/address"}
        DNS = ${config.sops.placeholder."wg/dns"}

        [Peer]
        PublicKey = ${config.sops.placeholder."wg/public_key"}
        Endpoint = ${config.sops.placeholder."wg/endpoint"}
        AllowedIPs = 0.0.0.0/0, ::/0
        PersistentKeepalive = 25
      '';
      mode = "0600";
    };
  };

  # VPN network namespace configuration
  vpnNamespaces.media = {
    enable = true;
    wireguardConfigFile = config.sops.templates."wg0.conf".path;
    accessibleFrom = [
      "192.168.0.0/16"
    ];
    # Port mappings for Servarr services
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
        dir = "/var/lib/aria2/downloads";
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
  };

  virtualisation.incus.agent.enable = true;

  # VPN Confinement for Servarr services
  systemd.services = {
    sonarr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    radarr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    lidarr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    prowlarr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    readarr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    whisparr.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
    };
    aria2.vpnConfinement = {
      enable = true;
      vpnNamespace = "media";
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
    wireguard-tools # For VPN diagnostics
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
