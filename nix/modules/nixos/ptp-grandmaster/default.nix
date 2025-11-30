{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ptp-grandmaster;
in
{
  options.services.ptp-grandmaster = {
    enable = lib.mkEnableOption "PTP (IEEE 1588) Grandmaster Clock";

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Network interface for PTP traffic";
      example = "eth0";
    };

    priority1 = lib.mkOption {
      type = lib.types.int;
      default = 128;
      description = "PTP priority1 value (lower = higher priority)";
    };

    priority2 = lib.mkOption {
      type = lib.types.int;
      default = 128;
      description = "PTP priority2 value (lower = higher priority)";
    };

    clockClass = lib.mkOption {
      type = lib.types.int;
      default = 6;
      description = "PTP clock class (6 = GPS-synced primary reference)";
    };

    timeSource = lib.mkOption {
      type = lib.types.str;
      default = "0x10";
      description = "PTP time source (0x10 = atomic clock, 0x20 = GPS)";
    };

    timestamping = lib.mkOption {
      type = lib.types.enum [
        "hardware"
        "software"
      ];
      default = "hardware";
      description = "Timestamping mode (hardware for best precision)";
    };

    tuneCoalescing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Tune packet coalescing for nanosecond precision";
    };

    syncSystemClock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Synchronize NIC's PHC from system clock using phc2sys";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for ptp4l.conf";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.linuxptp ] ++ lib.optional cfg.tuneCoalescing pkgs.ethtool;

    environment.etc."linuxptp/ptp4l.conf".text = ''
      [global]
      serverOnly        1
      priority1         ${toString cfg.priority1}
      priority2         ${toString cfg.priority2}
      logAnnounceInterval    1
      logSyncInterval        0
      logMinDelayReqInterval 0
      time_stamping     ${cfg.timestamping}
      clockClass        ${toString cfg.clockClass}
      timeSource        ${cfg.timeSource}
      ${cfg.extraConfig}
    '';

    systemd.services.ptp4l = {
      description = "PTP Grandmaster Clock";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      requires = [ "sys-subsystem-net-devices-${cfg.interface}.device" ];
      before = [ "chronyd.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = [
          # Wait for PTP hardware clock (race condition fix)
          "${pkgs.bash}/bin/bash -c 'until [ -e /dev/ptp0 ] || [ -e /dev/ptp1 ]; do sleep 1; done'"
          "${pkgs.coreutils}/bin/sleep 2"
        ]
        ++
          lib.optional cfg.tuneCoalescing
            # Reduce packet coalescing for nanosecond precision
            "${pkgs.ethtool}/bin/ethtool -C ${cfg.interface} tx-usecs 4 rx-usecs 4";
        ExecStart = "${pkgs.linuxptp}/bin/ptp4l -f /etc/linuxptp/ptp4l.conf -i ${cfg.interface} -m";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # Synchronize NIC's PHC from system clock (disciplined by chrony/GPS)
    systemd.services.phc2sys = lib.mkIf cfg.syncSystemClock {
      description = "PHC to System Clock Sync";
      after = [ "ptp4l.service" ];
      requires = [ "ptp4l.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.linuxptp}/bin/phc2sys -s CLOCK_REALTIME -c ${cfg.interface} -O 0 --step_threshold=0.5 -m";
        Restart = "always";
        RestartSec = 5;
      };
    };

  };
}
