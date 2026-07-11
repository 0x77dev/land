{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.vr;
in
{
  options.modules.vr = {
    enable = lib.mkEnableOption "ALVR and SteamVR host baseline";

    firewallInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "eno2np1";
      description = ''
        Dedicated interface on which to allow ALVR TCP and UDP ports 9943
        and 9944. Leave null until the interface and firewall migration are
        defined.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.steam.enable;
        message = "modules.vr requires programs.steam.enable.";
      }
      {
        assertion = config.hardware.graphics.enable32Bit;
        message = "modules.vr requires 32-bit graphics support for SteamVR.";
      }
      {
        assertion = config.services.pipewire.enable;
        message = "modules.vr requires PipeWire for game audio and microphone routing.";
      }
      {
        assertion = !config.services.monado.enable;
        message = "modules.vr uses SteamVR as the runtime; disable services.monado.";
      }
      {
        assertion = cfg.firewallInterface == null || config.networking.firewall.enable;
        message = "modules.vr.firewallInterface requires networking.firewall.enable.";
      }
    ];

    programs.alvr = {
      enable = true;
      package = pkgs.alvr;
      openFirewall = false;
    };

    environment.systemPackages = [ pkgs.vulkan-tools ];

    networking.firewall.interfaces = lib.optionalAttrs (cfg.firewallInterface != null) {
      "${cfg.firewallInterface}" = {
        allowedTCPPorts = [
          9943
          9944
        ];
        allowedUDPPorts = [
          9943
          9944
        ];
      };
    };
  };
}
