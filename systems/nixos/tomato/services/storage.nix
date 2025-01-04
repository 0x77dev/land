{ pkgs, ... }: {
  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.transmission = {
    enable = true;
    openFirewall = true;
    performanceNetParameters = true;
    settings = {
      # Network settings
      "rpc-bind-address" = "192.168.15.1";
      "peer-port" = 51413;
      "peer-port-random-on-start" = false;
      "port-forwarding-enabled" = false;
      "encryption" = 1; # Prefer encrypted connections
      "utp-enabled" = true; # Enable µTP protocol

      # Download settings
      "download-dir" = "/data/share/Downloads";
      "incomplete-dir" = "/data/share/Downloads/.incomplete";
      "incomplete-dir-enabled" = true;
      "preallocation" = 1; # Faster allocation
      "cache-size-mb" = 256; # Increase cache size

      # Queue settings
      "queue-stalled-enabled" = true;
      "queue-stalled-minutes" = 30;
      "download-queue-size" = 10;
      "download-queue-enabled" = true;

      # Speed settings
      "speed-limit-down" = 0; # Unlimited
      "speed-limit-up" = 0; # Unlimited
      "alt-speed-enabled" = false;

      # Peer settings  
      "peer-limit-global" = 1000;
      "peer-limit-per-torrent" = 100;
      "peer-socket-tos" = "lowdelay";

      # RPC settings
      "rpc-whitelist-enabled" = false;
      "rpc-host-whitelist-enabled" = false;

      # Advanced settings
      "blocklist-enabled" = true;
      "blocklist-url" = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      "dht-enabled" = true;
      "lpd-enabled" = true;
      "pex-enabled" = true;
      "scrape-paused-torrents-enabled" = true;
      "umask" = 2;
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    smbd.enable = true;
    nmbd.enable = true;

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

        # Monitoring
        "profiling level" = "on";

        # PAM and authentication settings
        "pam password change" = "yes";
        "passdb backend" = "tdbsam";
        "obey pam restrictions" = "yes";
        "unix extensions" = "yes";
        "encrypt passwords" = "yes";
        "client ntlmv2 auth" = "yes";
        "client lanman auth" = "no";
        "client plaintext auth" = "no";
        "lanman auth" = "no";
        "ntlm auth" = "no";

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
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacPro7,1";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:nfs_aces" = "no";
        "fruit:encoding" = "native";
        "fruit:zero_file_id" = "yes";
      };

      downloads = {
        path = "/data/share/Downloads";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "@users";
        "force user" = "mykhailo";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
        "inherit acls" = "yes";
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
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
        "kernel oplocks" = "no";
        "kernel share modes" = "no";
        "posix locking" = "no";
        "allocation roundup size" = "4096";
        "root preexec" = "${pkgs.coreutils}/bin/mkdir -p /data/share/TimeMachine/%U";
        "inherit acls" = "yes";
      };

      home = {
        comment = "Home Directories";
        path = "/home/%U";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "@users";
        "force user" = "%U";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
        "inherit acls" = "yes";
      };

      photos = {
        comment = "Photos Library";
        path = "/data/media/immich";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "mykhailo";
        "force user" = "mykhailo";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "strict sync" = "no";
        "write cache size" = "1048576";
        "inherit acls" = "yes";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
    workgroup = "WORKGROUP";
  };
}
