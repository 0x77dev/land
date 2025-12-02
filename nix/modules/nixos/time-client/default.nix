{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.services.time-client;
  ntpConfig = lib.${namespace}.shared.ntp-config;
in
{
  options.services.time-client = {
    enable = lib.mkEnableOption "NTP client using local time server";

    server = lib.mkOption {
      type = lib.types.str;
      default = "timey.0x77.computer";
      description = "Primary NTP/PTP server address";
    };

    fallbackServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ntpConfig.defaultServers;
      description = "Fallback NTP servers if primary is unavailable (non-smearing only)";
    };

    ptp = {
      enable = lib.mkEnableOption "PTP (IEEE 1588) slave for sub-microsecond sync";

      interface = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Network interface for PTP traffic (must support hardware timestamping)";
        example = "eth0";
      };

      timestamping = lib.mkOption {
        type = lib.types.enum [
          "hardware"
          "software"
        ];
        default = "hardware";
        description = "Timestamping mode (hardware for best precision)";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Base NTP configuration (always enabled)
      {
        # Disable systemd-timesyncd (doesn't support PTP, less accurate)
        # https://github.com/systemd/systemd/issues/22828
        services.timesyncd.enable = false;

        # Use chrony for better accuracy when syncing from PTP-disciplined server
        services.chrony = {
          enable = true;
          serverOption = "iburst";
          servers = [ cfg.server ] ++ cfg.fallbackServers;

          # Prefer our local PTP-synced server, allow larger initial correction
          extraConfig = ''
            # Prefer local time server (PTP-synced)
            server ${cfg.server} iburst prefer

            # Allow large initial adjustment on startup
            makestep 1.0 3
          '';
        };
      }

      # PTP slave configuration (optional, for sub-microsecond sync)
      (lib.mkIf cfg.ptp.enable {
        assertions = [
          {
            assertion = cfg.ptp.interface != "";
            message = "services.time-client.ptp.interface must be set when PTP is enabled";
          }
        ];

        environment.systemPackages = [ pkgs.linuxptp ];

        environment.etc."linuxptp/ptp4l-slave.conf".text = ''
          [global]
          slaveOnly         1
          logAnnounceInterval    1
          logSyncInterval        0
          logMinDelayReqInterval 0
          time_stamping     ${cfg.ptp.timestamping}
        '';

        # PTP slave daemon - syncs PHC from grandmaster
        systemd.services.ptp4l = {
          description = "PTP Slave Clock";
          after = [
            "network-online.target"
            "chronyd.service"
          ];
          wants = [ "network-online.target" ];
          requires = [ "sys-subsystem-net-devices-${cfg.ptp.interface}.device" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            ExecStartPre = [
              # Wait for PTP hardware clock
              "${pkgs.bash}/bin/bash -c 'until [ -e /dev/ptp0 ] || [ -e /dev/ptp1 ]; do sleep 1; done'"
              "${pkgs.coreutils}/bin/sleep 2"
            ];
            ExecStart = "${pkgs.linuxptp}/bin/ptp4l -f /etc/linuxptp/ptp4l-slave.conf -i ${cfg.ptp.interface} -s -m";
            Restart = "always";
            RestartSec = 10;
          };
        };

        # Sync system clock from NIC's PHC (disciplined by PTP grandmaster)
        systemd.services.phc2sys = {
          description = "PHC to System Clock Sync (PTP Slave)";
          after = [ "ptp4l.service" ];
          requires = [ "ptp4l.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            # -s <interface> = source PHC, -c CLOCK_REALTIME = sync system clock
            # -w = wait for ptp4l to sync first
            ExecStart = "${pkgs.linuxptp}/bin/phc2sys -s ${cfg.ptp.interface} -c CLOCK_REALTIME -O 0 -w -m";
            Restart = "always";
            RestartSec = 5;
          };
        };
      })
    ]
  );
}
