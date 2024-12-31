{ pkgs, ... }: {
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
