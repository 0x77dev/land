{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.gnome-control-surfaces;
  elgatoExtension = pkgs.${namespace}.elgato-light-control;
  elgatoExtensionUuid = "elgato-light-control@cluster2a.github.io";
  easyeffectsDefaults = (pkgs.formats.ini { }).generate "easyeffectsrc" {
    EffectsPipelines = {
      bypass = true;
      excludeMonitorStreams = true;
      processAllInputs = false;
      processAllOutputs = false;
    };
    Window = {
      autostartOnLogin = false;
      enableServiceMode = true;
      noWindowAfterStarting = true;
      showTrayIcon = false;
      xdgGlobalShortcuts = false;
    };
  };
in
{
  options.modules.home.gnome-control-surfaces.enable =
    lib.mkEnableOption "GNOME controls for network Elgato lights and PipeWire audio";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.home.gnome.enable;
        message = "GNOME control surfaces require modules.home.gnome.enable.";
      }
      {
        assertion =
          elgatoExtension.extensionUuid == elgatoExtensionUuid
          && elgatoExtension.version == "5"
          && elgatoExtension.upstreamVersion == "2.1.0";
        message = "Elgato Light Control changed; re-audit its GNOME metadata and schema.";
      }
      {
        assertion = pkgs.pwvucontrol.version == "0.5.2";
        message = "pwvucontrol changed; re-audit its published settings schema.";
      }
      {
        assertion = pkgs.easyeffects.version == "8.2.4";
        message = "EasyEffects changed; re-audit its KConfig defaults and service interface.";
      }
    ];

    modules.home.gnome.extensions = [ elgatoExtensionUuid ];

    home.packages = [
      elgatoExtension
      pkgs.pwvucontrol
    ];

    services.easyeffects = {
      enable = true;
      package = pkgs.easyeffects;
    };

    # Seed mutable, transparent defaults only on first use. EasyEffects keeps
    # the resulting file writable so deliberate UI changes can persist.
    systemd.user.tmpfiles.rules = [
      "d %h/.config/easyeffects 0700 - - -"
      "d %h/.config/easyeffects/db 0700 - - -"
      "C %h/.config/easyeffects/db/easyeffectsrc 0600 - - - ${easyeffectsDefaults}"
    ];

    systemd.user.services.easyeffects.Unit = {
      After = [
        "pipewire.service"
        "wireplumber.service"
      ];
      Wants = [
        "pipewire.service"
        "wireplumber.service"
      ];
    };

    dconf.settings = {
      "org/gnome/desktop/sound".allow-volume-above-100-percent = false;

      "com/saivert/pwvucontrol" = {
        enable-overamplification = false;
        beep-on-volume-changes = false;
      };
    };
  };
}
