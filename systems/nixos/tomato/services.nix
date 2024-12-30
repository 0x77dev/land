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

  services.aria2 = {
    enable = true;
    # TODO: use a better secret
    rpcSecretFile = "/etc/machine-id";
    settings = {
      enable-rpc = true;
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
    openFirewall = true;
    mediaLocation = "/data/media/immich";
  };
}
