{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tailscale.funnel;
  tailscale = config.services.tailscale.package;

  commonArgs = [
    "--yes"
    "--bg"
    "--https=${toString cfg.httpsPort}"
  ]
  ++ lib.optional (cfg.setPath != null) "--set-path=${cfg.setPath}";

  startArgs = commonArgs ++ [ cfg.target ];
  stopArgs = commonArgs ++ [ "off" ];
in
{
  options.services.tailscale.funnel = {
    enable = lib.mkEnableOption "node-level Tailscale Funnel exposure";

    target = lib.mkOption {
      type = lib.types.str;
      example = "http://127.0.0.1:8080";
      description = ''
        Local target to expose publicly through Tailscale Funnel. This is passed
        to {command}`tailscale funnel` and may be a port, partial URL, full URL,
        path, text target, or Unix socket accepted by Tailscale.
      '';
    };

    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 443;
      example = 8443;
      description = ''
        Public HTTPS port for Funnel. Passed as {option}`--https` to
        {command}`tailscale funnel`.
      '';
    };

    setPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/webhook";
      description = ''
        Optional public path prefix to mount the target at. Passed as
        {option}`--set-path` to {command}`tailscale funnel`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "services.tailscale.funnel requires services.tailscale.enable to be true";
      }
    ];

    systemd.services.tailscale-funnel = {
      description = "Tailscale Funnel Configuration";
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
        "tailscaled-set.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe tailscale} funnel ${lib.escapeShellArgs startArgs}";
        ExecStop = "${lib.getExe tailscale} funnel ${lib.escapeShellArgs stopArgs}";
      };
    };
  };
}
