{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.services.time-server;
  dashboards = lib.${namespace}.shared.grafana-dashboards;
in
{
  options.services.time-server = {
    enable = lib.mkEnableOption "Time server with full observability stack";

    enableGrafana = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Grafana with pre-configured dashboards";
    };

    enableNetdata = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Netdata for real-time monitoring";
    };

    enablePrometheus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Prometheus for metrics collection";
    };

    grafanaPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Grafana web UI";
    };

    prometheusPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port for Prometheus";
    };

    netdataPort = lib.mkOption {
      type = lib.types.port;
      default = 19999;
      description = "Port for Netdata web UI";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for monitoring services";
    };

    instanceName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Instance name for Prometheus labels";
    };
  };

  config = lib.mkIf cfg.enable {
    # Firewall configuration
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
      lib.optional cfg.enableGrafana cfg.grafanaPort
      ++ lib.optional cfg.enablePrometheus cfg.prometheusPort
      ++ lib.optional cfg.enableNetdata cfg.netdataPort
      ++ [
        123 # NTP
        319 # PTP event
        320 # PTP general
        9100 # node_exporter
        9123 # chrony_exporter
      ]
    );

    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [
      123 # NTP
      319 # PTP event
      320 # PTP general
    ];

    services = {
      # Netdata configuration
      netdata = lib.mkIf cfg.enableNetdata {
        enable = true;
        package = lib.mkDefault (
          pkgs.netdata.override {
            withCloudUi = true;
          }
        );
        configDir."go.d/prometheus.conf" = pkgs.writeText "prometheus.conf" ''
          jobs:
            - name: prometheus
              url: http://127.0.0.1:${toString cfg.prometheusPort}/metrics
        '';
      };

      # Prometheus configuration
      prometheus = lib.mkIf cfg.enablePrometheus {
        enable = true;
        port = cfg.prometheusPort;
        globalConfig.scrape_interval = "15s";

        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "localhost:9100" ];
                labels.instance = cfg.instanceName;
              }
            ];
          }
          {
            job_name = "chrony";
            static_configs = [
              {
                targets = [ "localhost:9123" ];
                labels.instance = cfg.instanceName;
              }
            ];
          }
          {
            job_name = "gpsd";
            static_configs = [
              {
                targets = [ "localhost:9978" ];
                labels.instance = cfg.instanceName;
              }
            ];
          }
          {
            job_name = "netdata";
            metrics_path = "/api/v1/allmetrics";
            params.format = [ "prometheus" ];
            static_configs = [
              {
                targets = [ "localhost:${toString cfg.netdataPort}" ];
                labels.instance = cfg.instanceName;
              }
            ];
          }
        ];

        exporters.node = {
          enable = true;
          port = 9100;
          enabledCollectors = [ "systemd" ];
          extraFlags = [
            "--collector.ethtool"
            "--collector.softirqs"
            "--collector.tcpstat"
          ];
        };
      };

      # Grafana configuration
      grafana = lib.mkIf cfg.enableGrafana {
        enable = true;
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = cfg.grafanaPort;
          };
          "auth.anonymous" = {
            enabled = true;
            org_role = "Viewer";
          };
        };
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:${toString cfg.prometheusPort}";
              isDefault = true;
            }
          ];
          dashboards.settings.providers = [
            {
              name = "Node Exporter Full";
              options.path = dashboards.fetch {
                inherit pkgs;
                inherit (dashboards.dashboards.node-exporter-full)
                  id
                  version
                  hash
                  name
                  ;
              };
            }
            {
              name = "Chrony";
              options.path = dashboards.fetch {
                inherit pkgs;
                inherit (dashboards.dashboards.chrony)
                  id
                  version
                  hash
                  name
                  ;
              };
            }
            {
              name = "GPSD";
              options.path = dashboards.fetchUrl {
                inherit pkgs;
                inherit (dashboards.urls.gpsd-exporter) url hash;
                name = "gpsd.json";
              };
            }
          ];
        };
      };
    };
  };
}
