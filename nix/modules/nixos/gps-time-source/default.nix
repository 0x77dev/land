{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.services.gps-time-source;
  ntpConfig = lib.${namespace}.shared.ntp-config;
in
{
  options.services.gps-time-source = {
    enable = lib.mkEnableOption "GPS/PPS time source via gpsd and chrony";

    gpsDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/ttyAMA0";
      description = "Serial device for GPS NMEA data";
    };

    ppsDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/pps0";
      description = "PPS device for precise timing";
    };

    ppsGpioPin = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "GPIO pin for PPS input (BCM numbering). Set to enable pps-gpio kernel module.";
      example = 18;
    };

    allowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "192.168.0.0/16"
        "10.0.0.0/8"
      ];
      description = "Networks allowed to query this NTP server";
    };

    ntpServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ntpConfig.defaultServers;
      description = ''
        Fallback NTP servers for when GPS/PPS is unavailable.
        Only includes servers with standard leap second handling (no smearing).
      '';
    };

    localStratum = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Stratum to advertise when not fully synchronized";
    };

    extraChronyConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for chrony";
    };
  };

  config = lib.mkIf cfg.enable {
    # Load PPS GPIO kernel module if pin is specified
    boot.kernelModules = lib.optional (cfg.ppsGpioPin != null) "pps-gpio";

    environment.systemPackages = with pkgs; [
      pps-tools
      gpsd
    ];

    services = {
      gpsd = {
        enable = true;
        devices = [
          cfg.gpsDevice
          cfg.ppsDevice
        ];
        nowait = true;
      };

      chrony = {
        enable = true;
        servers = cfg.ntpServers;
        extraConfig = ''
          # gpsd provides time via shared memory (SHM)
          # SHM 0 = NMEA time (coarse, ~ms precision) - used to validate PPS
          # SHM 1 = PPS time (precise, ~ns precision) - primary time source
          refclock SHM 0 refid GPS precision 1e-1 delay 0.2 noselect
          refclock SHM 1 refid PPS precision 1e-9 prefer

          # Allow configured networks to query this NTP server
          ${lib.concatMapStringsSep "\n" (net: "allow ${net}") cfg.allowedNetworks}

          # Serve time even when not fully synchronized
          local stratum ${toString cfg.localStratum}

          ${cfg.extraChronyConfig}
        '';
      };

      # Enable gpsd exporter for monitoring
      prometheus.exporters.gpsd = {
        enable = true;
        port = 9978;
      };

      prometheus.exporters.chrony = {
        enable = true;
        port = 9123;
      };
    };
  };
}
