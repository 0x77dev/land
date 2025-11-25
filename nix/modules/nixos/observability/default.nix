{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.observability;
in
{
  options.modules.observability = {
    enable = lib.mkEnableOption "System observability with Netdata";

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 19999;
      description = "Port for Netdata web UI";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall port for Netdata web UI";
    };

    dataRetentionDays = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Number of days to retain metrics data";
    };

    updateInterval = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Metrics collection interval in seconds";
    };

    memoryMode = lib.mkOption {
      type = lib.types.enum [
        "ram"
        "save"
        "map"
        "dbengine"
      ];
      default = "dbengine";
      description = ''
        Memory mode for storing metrics:
        - ram: Store data in RAM only (no persistence)
        - save: Store in RAM, save to disk on shutdown
        - map: Memory-mapped files (balanced)
        - dbengine: Advanced database engine (recommended)
      '';
    };

    enableGpuMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.nvidia.modesetting.enable or false;
      description = "Enable NVIDIA GPU monitoring (auto-detected)";
    };

    enableZfsMonitoring = lib.mkOption {
      type = lib.types.bool;
      default =
        let
          fs = config.boot.supportedFilesystems or [ ];
        in
        if builtins.isList fs then
          builtins.elem "zfs" fs
        else if builtins.isAttrs fs then
          fs ? zfs
        else
          false;
      description = "Enable ZFS monitoring (auto-detected)";
    };

    enableContainerMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable container monitoring (Docker, Incus, libvirtd)";
    };

    claimTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to file containing Netdata Cloud claim token.
        If set, automatically registers the agent with Netdata Cloud.
        Get your claim token from: https://app.netdata.cloud
      '';
      example = "/run/secrets/netdata-claim-token";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure sops secrets for Netdata Cloud
    sops.secrets."netdata/claim_token" = {
      mode = "0400";
      owner = config.services.netdata.user;
      inherit (config.services.netdata) group;
      key = "netdata/claim_token";
      sopsFile = ./secrets.yaml;
    };

    services.netdata = {
      enable = true;

      # Disable anonymous analytics for privacy
      enableAnalyticsReporting = false;

      # Netdata Cloud integration - use sops secret by default, allow override
      claimTokenFile =
        if cfg.claimTokenFile != null then
          cfg.claimTokenFile
        else
          config.sops.secrets."netdata/claim_token".path;

      # Enable Python plugins for extended monitoring
      python = {
        enable = true;
        recommendedPythonPackages = true;
      };

      config = {
        global = {
          # Basic configuration
          "default port" = toString cfg.webPort;
          "update every" = toString cfg.updateInterval;
          "memory mode" = cfg.memoryMode;
          "history" = toString (cfg.dataRetentionDays * 86400); # Convert days to seconds

          # Performance tuning
          "page cache size" = "128";
          "dbengine multihost disk space" = "2048"; # 2GB for dbengine
        };

        # Web UI configuration
        web = {
          "default backend" = "threaded";
          "bind to" = "*";
          "allow connections from" =
            "localhost 10.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*";
        };

        # Plugin configuration
        plugins = {
          # Enable system plugins
          "proc" = "yes";
          "diskspace" = "yes";
          "cgroups" = "yes";
          "tc" = "yes";
          "idlejitter" = "yes";

          # Enable Python plugins
          "python.d" = "yes";

          # Enable container monitoring
          "apps" = "yes";
        };
      };
    };

    # Add GPU monitoring tools if NVIDIA GPU is detected
    environment.systemPackages = lib.optionals cfg.enableGpuMonitoring [
      pkgs.nvtopPackages.full
    ];

    # Configure firewall if enabled
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.webPort ];
    };

    # Add netdata user to necessary groups for monitoring
    users.users.netdata.extraGroups =
      lib.optionals (config.virtualisation.docker.enable or false) [ "docker" ]
      ++ lib.optionals (config.virtualisation.incus.enable or false) [ "incus-admin" ]
      ++ lib.optionals (config.virtualisation.libvirtd.enable or false) [ "libvirtd" ];

    # Ensure netdata can read system information
    systemd.services.netdata.serviceConfig = {
      # Allow netdata to monitor all processes
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";

      # Allow access to hardware information
      PrivateDevices = lib.mkForce false;

      # Allow access to cgroups for container monitoring
      ProtectControlGroups = lib.mkForce false;

      # Allow write access to /etc/netdata for claiming
      ReadWritePaths = lib.mkForce [ "/etc/netdata" ];

      # Ensure proper permissions for claiming
      ProtectSystem = lib.mkForce false;
    };
  };
}
