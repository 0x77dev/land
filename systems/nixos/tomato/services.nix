{ pkgs, ... }: {
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
    smbd.enable = true;
    nmbd.enable = true;
    securityType = "user";

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "Tomato NAS";
        "server role" = "standalone server";
        security = "user";
        "unix password sync" = "yes";
        "map to guest" = "never";
        "hosts allow" = "192.168.0.0/24 100.64.0.0/10";
        "hosts deny" = "0.0.0.0/0";

        # PAM authentication settings
        "pam password change" = "yes";
        "passdb backend" = "tdbsam";
        "obey pam restrictions" = "yes";

        # Performance optimizations
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288";
        "read raw" = "yes";
        "write raw" = "yes";
        "strict locking" = "no";
        "strict sync" = "no";
        "sync always" = "no";
        "aio read size" = "1";
        "aio write size" = "1";
        "use sendfile" = "yes";
        "min receivefile size" = "16384";
        "max xmit" = "65535";
        "large readwrite" = "yes";

        # Enable SMB3 multichannel for better performance
        "server multi channel support" = "yes";

        # macOS compatibility with optimizations
        "min protocol" = "SMB3";
        "server min protocol" = "SMB3";
        "ea support" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacPro7,1";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:nfs_aces" = "no";
      };

      public = {
        path = "/data/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "@users";
        "force user" = "mykhailo";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
      };

      timemachine = {
        comment = "Time Machine Backup";
        path = "/data/share/TimeMachine/%U";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "@users";
        "force user" = "%U";
        "force group" = "users";
        "create mask" = "0600";
        "directory mask" = "0700";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
        "kernel oplocks" = "no";
        "kernel share modes" = "no";
        "posix locking" = "no";
        "allocation roundup size" = "4096";
        "root preexec" = "${pkgs.coreutils}/bin/mkdir -p /data/share/TimeMachine/%U";
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
