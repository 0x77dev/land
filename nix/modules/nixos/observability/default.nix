{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.observability;
  inherit (config.services.netdata) user group;
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

    enableGpuMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.nvidia.modesetting.enable or false;
      description = "Enable NVIDIA GPU monitoring (auto-detected)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Netdata Cloud secrets
    sops.secrets."netdata/claim_token" = {
      mode = "0400";
      owner = user;
      inherit group;
      key = "netdata/claim_token";
      sopsFile = ./secrets.yaml;
    };

    services.netdata = {
      enable = true;
      enableAnalyticsReporting = false;

      python = {
        enable = true;
        recommendedPythonPackages = true;
      };

      config = {
        global = {
          "default port" = toString cfg.webPort;
          "history" = toString (cfg.dataRetentionDays * 86400);
        };

        web.bindto = "*";

        cloud = {
          "cloud base url" = "https://app.netdata.cloud";
          enabled = "yes";
        };
      };
    };

    # Netdata Cloud token
    systemd.tmpfiles.rules = [
      "d /var/lib/netdata/cloud.d 0755 ${user} ${group} -"
      "L+ /var/lib/netdata/cloud.d/token - - - - ${config.sops.secrets."netdata/claim_token".path}"
    ];

    # GPU monitoring tools
    environment.systemPackages = lib.optional cfg.enableGpuMonitoring pkgs.nvtopPackages.full;

    # Firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.webPort ];

    # Container monitoring groups
    users.users.netdata.extraGroups =
      lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.virtualisation.incus.enable "incus-admin"
      ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";

    # Service overrides for monitoring capabilities
    systemd.services.netdata.serviceConfig = {
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";
      PrivateDevices = lib.mkForce false;
      ProtectControlGroups = lib.mkForce false;
    };
  };
}
