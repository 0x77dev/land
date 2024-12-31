{ ... }: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.fail2ban.enable = true;

  services.cloudflared = {
    enable = true;
  };

  services.aria2 = {
    enable = true;
    # TODO: use a better secret
    rpcSecretFile = "/etc/machine-id";
    settings = {
      enable-rpc = true;
      rpc-listen-all = true;
      dir = "/data/share/Downloads";
      max-concurrent-downloads = 16;
      max-connection-per-server = 16;
      min-split-size = "1M";
      split = 16;
      max-overall-download-limit = 0;
      max-download-limit = 0;
      max-overall-upload-limit = "1M";
      max-upload-limit = "50K";
      continue = true;
      allow-overwrite = true;
      disk-cache = "64M";
    };
  };

  systemd.services.aria2.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    # Enable both SMB and NetBIOS name services
    smbd.enable = true;
    nmbd.enable = true;

    settings = {
      global = {
        # Basic server configuration
        workgroup = "WORKGROUP";
        "server string" = "Tomato NAS";
        "server role" = "standalone server";

        # Security settings
        security = "user";
        "map to guest" = "bad user";
        "guest account" = "nobody";

        # Network access control
        "hosts allow" = "192.168.0.0/24 100.64.0.0/10"; # Local network and Tailscale
        "hosts deny" = "0.0.0.0/0"; # Deny all others
      };

      # Public share configuration
      public = {
        path = "/data/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "mykhailo";
        # Standard Unix permissions
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      # Time Machine backup share
      timemachine = {
        path = "/data/share/TimeMachine";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = "mykhailo";
        # Standard Unix permissions
        "create mask" = "0644";
        "directory mask" = "0755";
        # Apple-specific settings for Time Machine support
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
    workgroup = "WORKGROUP";
  };

  services.postgresql = {
    enable = true;
    dataDir = "/data/postgresql";
  };

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/data/media/immich";
  };

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.tautulli = {
    enable = true;
    openFirewall = true;
    port = 33000;
  };

  services.plausible = {
    enable = true;
    server = {
      listenAddress = "0.0.0.0";
      port = 8181;
      baseUrl = "https://plausible.0x77.computer";
      disableRegistration = "invite_only";
      secretKeybaseFile = "/data/.secret/plausible/secret";
    };
    adminUser = {
      name = "Mykhailo";
      email = "mykhailo@0x77.dev";
      passwordFile = "/data/.secret/plausible/admin_password";
      activate = true;
    };
    mail = {
      email = "plausible@system.0x77.dev";
      smtp = {
        hostAddr = "smtp.resend.com";
        hostPort = 465;
        enableSSL = true;
        user = "resend";
        passwordFile = "/data/.secret/resend/api_key";
      };
    };
  };
}
