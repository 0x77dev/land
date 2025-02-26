{ pkgs, ... }: {
  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
    claimTokenFile = "/run/secrets/netdata/claim-token";
    package = pkgs.netdata.override {
      withCloudUi = true;
      withCloud = true;
      withSystemdJournal = true;
    };
    configDir."python.d.conf" = pkgs.writeText "python.d.conf" ''
      samba: yes
      postgres: yes
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
        "CAP_DAC_READ_SEARCH"
        "CAP_SYS_PTRACE"
        "CAP_NET_RAW"
      ];
    };
  };
}
