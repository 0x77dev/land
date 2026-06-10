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
  };

  config = lib.mkIf cfg.enable {
    # netdata 2.x ships no local dashboard unless built withCloudUi (the v3 UI),
    # otherwise :19999 only serves the API and `/` returns netdata's own 404.
    # The enclosing mkDefault pushes down to every leaf, so package stays at
    # default priority and a host may still override it.
    services.netdata = lib.mkDefault {
      enable = true;
      enableAnalyticsReporting = false;
      package = pkgs.netdata.override { withCloudUi = true; };
      config.global."default port" = toString cfg.webPort;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.webPort ];

    users.users.netdata.extraGroups =
      lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";

    systemd.services.netdata.serviceConfig = {
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";
      PrivateDevices = lib.mkForce false;
      ProtectControlGroups = lib.mkForce false;
    };
  };
}
