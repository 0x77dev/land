{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.services.prometheus.exporters.gpsd;
in
{
  options.services.prometheus.exporters.gpsd = {
    enable = lib.mkEnableOption "the gpsd exporter for Prometheus";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9978;
      description = "Port to listen on.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address to listen on.";
    };

    gpsdAddress = lib.mkOption {
      type = lib.types.str;
      default = "localhost:2947";
      description = "Address of the gpsd server.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open port in firewall for the exporter.";
    };

    package = lib.mkPackageOption pkgs.${namespace} "gpsd-exporter" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.prometheus-gpsd-exporter = {
      description = "Prometheus GPSD Exporter";
      after = [ "network.target" ] ++ lib.optional config.services.gpsd.enable "gpsd.service";
      wants = lib.optional config.services.gpsd.enable "gpsd.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/gpsd-exporter -l ${cfg.listenAddress}:${toString cfg.port} -d ${cfg.gpsdAddress}";
        Restart = "always";
        RestartSec = 5;
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
