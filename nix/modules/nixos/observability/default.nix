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

    enableGpuMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.nvidia.modesetting.enable or false;
      description = "Enable NVIDIA GPU monitoring (auto-detected)";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."netdata/claim_token" = {
      mode = "0400";
      owner = user;
      inherit group;
      sopsFile = ./secrets.yaml;
    };

    services.netdata = {
      enable = true;
      enableAnalyticsReporting = false;
      claimTokenFile = config.sops.secrets."netdata/claim_token".path;

      config.global."default port" = toString cfg.webPort;
    };

    environment.systemPackages = lib.optional cfg.enableGpuMonitoring pkgs.nvtopPackages.full;

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.webPort ];

    users.users.netdata.extraGroups =
      lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.virtualisation.incus.enable "incus-admin"
      ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";

    systemd.services.netdata.serviceConfig = {
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";
      PrivateDevices = lib.mkForce false;
      ProtectControlGroups = lib.mkForce false;
    };
  };
}
