{ pkgs, ... }: {
  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
    package = pkgs.netdata.override {
      withCloudUi = true;
    };
    configDir."python.d.conf" = pkgs.writeText "python.d.conf" ''
      samba: yes
      postgres: yes
      redis: yes
      fail2ban: yes
    '';
    configDir."go.d.conf" = pkgs.writeText "go.d.conf" ''
      clickhouse: yes
      ipfs: yes
    '';
    config = {
      # NOTE: postgres netdata user must be created and have pg_monitor privileges
      # CREATE USER netdata;
      # GRANT pg_monitor TO netdata;
      "plugin:postgres" = {
        "update every" = 10;
        "command options" = "host=/run/postgresql";
      };
      "plugin:discovery" = {
        "enable running new plugins" = "yes";
        "check for new plugins every" = 60;
      };
      "plugin:apps" = {
        "update every" = 5;
        "command options" = "without-users";
      };
      "plugin:proc" = {
        "command options" = "group services=systemd-services";
      };
      "plugin:fail2ban" = {
        "update every" = 10;
        "log file" = "/var/log/fail2ban.log";
      };
    };
    configDir."go.d/ipfs.conf" = pkgs.writeText "ipfs.conf" ''
      jobs:
        - name: local
          url: http://localhost:5001
    '';
  };

  # Configure netdata service
  systemd.services.netdata = {
    path = [
      pkgs.samba
      pkgs.postgresql
      pkgs.fail2ban
      pkgs.ipfs
      pkgs.procps
      pkgs.iproute2
      "/run/wrappers"
    ];

    serviceConfig = {
      CapabilityBoundingSet = [
        "CAP_SETGID"
        "CAP_DAC_READ_SEARCH" # For reading system files
        "CAP_SYS_PTRACE" # For process monitoring
        "CAP_NET_RAW" # For network monitoring
      ];
      SupplementaryGroups = [
        "postgres"
        "redis"
        "systemd-journal"
        "proc"
      ];
      ReadWritePaths = [
        "/var/log/fail2ban.log"
        "/var/cache/netdata"
        "/var/lib/netdata"
      ];
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = false; # Required for sudo access
    };
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
}
