{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.gnome;
  voxtypeEnabled = config.programs.voxtype.enable or false;

  superhumanIcon = pkgs.fetchurl {
    url = "https://superhumanstatic.com/super-funnel/main/public/images/v3/favicons/superhuman-apple-touch-icon.png";
    hash = "sha256-Qk7OlhFRLmtqqlNvZPGGvbX5LZb4Em0e2hNxdtvOESI=";
  };
in
{
  options.modules.home.gnome = {
    enable = mkEnableOption "GNOME desktop UX (dock, input sources, launcher keybindings)";

    favoriteApps = mkOption {
      type = types.listOf types.str;
      # Mirrors the macOS dock order (modules/darwin/dock), Linux subset.
      default = [
        "helium.desktop"
        "superhuman.desktop"
        "cursor.desktop"
        "com.mitchellh.ghostty.desktop"
        "slack.desktop"
        "org.telegram.desktop.desktop"
        "spotify.desktop"
        "org.gnome.Nautilus.desktop"
      ];
      description = "Ordered dash favorites, mirroring the macOS dock.";
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra GNOME Shell extension UUIDs to enable (PaperWM is always on).";
    };
  };

  config = mkIf cfg.enable {
    # Tiling Shell: Windows 11-grade snap assistant (drag to top edge for
    # the layout picker, screen edges for halves/quarters) with
    # FancyZones-style per-monitor custom layouts.
    home.packages = [ pkgs.gnomeExtensions.tiling-shell ];

    # Use the managed package path rather than relying on an ambient PATH.
    home.sessionVariables.TERMINAL = lib.getExe config.programs.ghostty.package;

    # Superhuman as a proper desktop app: Helium app-mode window, and the
    # system default mail client.
    xdg = {
      desktopEntries.superhuman = {
        name = "Superhuman";
        genericName = "Mail";
        comment = "Superhuman mail client";
        exec = "helium --app=https://mail.superhuman.com %U";
        icon = "${superhumanIcon}";
        categories = [
          "Network"
          "Email"
        ];
        mimeType = [ "x-scheme-handler/mailto" ];
        settings.StartupWMClass = "mail.superhuman.com";
      };

      mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/mailto" = "superhuman.desktop";
      };
    };

    dconf.settings = {
      "org/gnome/shell" = {
        favorite-apps = cfg.favoriteApps;
        enabled-extensions = [ "tilingshell@ferrarodomenico.com" ] ++ cfg.extensions;
      };

      # Keyboard layout priority: English (US) → Ukrainian → Russian.
      "org/gnome/desktop/input-sources" = {
        sources =
          map
            (
              l:
              lib.gvariant.mkTuple [
                "xkb"
                l
              ]
            )
            [
              "us"
              "ua"
              "ru"
            ];
      };

      # Workstation policy: never idle, suspend, hibernate, or dim from the
      # desktop. The host also disables every systemd sleep target, so both
      # layers agree.
      "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0;
      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
        power-button-action = "nothing";
      };

      # macOS-compatible muscle memory: layout switching on Ctrl+Space,
      # Super+Q closes like Cmd+Q. Super+Space belongs to the launcher.
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Control>space" ];
        switch-input-source-backward = [ "<Shift><Control>space" ];
        close = [ "<Super>q" ];
        # Throw windows across monitors (ultrawide <-> portrait).
        move-to-monitor-left = [ "<Shift><Super>Left" ];
        move-to-monitor-right = [ "<Shift><Super>Right" ];
        move-to-monitor-up = [ "<Shift><Super>Up" ];
        move-to-monitor-down = [ "<Shift><Super>Down" ];
      };

      # Screenshots on the Cmd+Shift+3/4 pattern.
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = [ "<Shift><Super>4" ];
        screenshot = [ "<Shift><Super>3" ];
      };

      # Vicinae on Super+Space, Ghostty on Ctrl+Alt+T, and Voxtype on the
      # standards-defined Voice Command media key when Voxtype is enabled.
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        ]
        ++ optional voxtypeEnabled "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voxtype/";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
        name = "Vicinae";
        # Absolute path: gsd spawns commands without the login shell PATH.
        command = "${config.home.profileDirectory}/bin/vicinae toggle";
        binding = "<Super>space";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
        name = "Terminal";
        # gsd does not launch through the login shell, so use the package path.
        command = lib.getExe config.programs.ghostty.package;
        binding = "<Control><Alt>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voxtype" = {
        name = "Voice dictation";
        command = "${config.home.profileDirectory}/bin/voxtype record toggle";
        binding = "XF86VoiceCommand";
      };

      # Windows 11-style tiling: drag to the top edge for the snap-layout
      # picker, screen edges for halves/quarters, snap assist suggests
      # windows for the remaining space. Ctrl+Alt+arrows move the focused
      # window between tiles of the active layout; Shift+Ctrl+Alt+arrows
      # span multiple tiles; Ctrl+Alt+Return untiles.
      "org/gnome/shell/extensions/tilingshell" =
        let
          mkPortraitRows =
            rowCount:
            let
              denominator = rowCount * 1.0;
            in
            {
              id = "Portrait ${toString rowCount} Rows";
              tiles = map (
                row:
                let
                  y = row / denominator;
                  nextY = (row + 1) / denominator;
                in
                {
                  x = 0;
                  inherit y;
                  width = 1;
                  height = nextY - y;
                  groups = [ ];
                }
              ) (lib.range 0 (rowCount - 1));
            };
        in
        {
          enable-tiling-system = true;
          enable-snap-assist = true;
          active-screen-edges = true;
          top-edge-maximize = false;
          enable-move-keybindings = true;
          move-window-left = [ "<Control><Alt>Left" ];
          move-window-right = [ "<Control><Alt>Right" ];
          move-window-up = [ "<Control><Alt>Up" ];
          move-window-down = [ "<Control><Alt>Down" ];
          span-window-left = [ "<Shift><Control><Alt>Left" ];
          span-window-right = [ "<Shift><Control><Alt>Right" ];
          span-window-up = [ "<Shift><Control><Alt>Up" ];
          span-window-down = [ "<Shift><Control><Alt>Down" ];
          untile-window = [ "<Control><Alt>Return" ];
          cycle-layouts = [ "<Control><Alt>l" ];
          # The top-edge Snap Assistant and panel indicator share one global
          # catalog. Tiling Shell only stores the active layout per
          # workspace/monitor, so the portrait layouts also appear in the
          # ultrawide's pickers.
          layouts-json = builtins.toJSON (
            [
              {
                id = "Halves";
                tiles = [
                  {
                    x = 0;
                    y = 0;
                    width = 0.5;
                    height = 1;
                    groups = [ 1 ];
                  }
                  {
                    x = 0.5;
                    y = 0;
                    width = 0.5;
                    height = 1;
                    groups = [ 1 ];
                  }
                ];
              }
              {
                id = "Thirds";
                tiles =
                  map
                    (i: {
                      x = i / 3.0;
                      y = 0;
                      width = 1 / 3.0;
                      height = 1;
                      groups = [ 1 ];
                    })
                    [
                      0
                      1
                      2
                    ];
              }
              {
                id = "Quarters";
                tiles =
                  map
                    (i: {
                      x = i / 4.0;
                      y = 0;
                      width = 0.25;
                      height = 1;
                      groups = [ 1 ];
                    })
                    [
                      0
                      1
                      2
                      3
                    ];
              }
              {
                id = "Center Focus";
                tiles = [
                  {
                    x = 0;
                    y = 0;
                    width = 0.25;
                    height = 1;
                    groups = [ 1 ];
                  }
                  {
                    x = 0.25;
                    y = 0;
                    width = 0.5;
                    height = 1;
                    groups = [ 1 ];
                  }
                  {
                    x = 0.75;
                    y = 0;
                    width = 0.25;
                    height = 1;
                    groups = [ 1 ];
                  }
                ];
              }
              {
                id = "Stacked Thirds";
                tiles =
                  map
                    (i: {
                      x = 0;
                      y = i / 3.0;
                      width = 1;
                      height = 1 / 3.0;
                      groups = [ 1 ];
                    })
                    [
                      0
                      1
                      2
                    ];
              }
            ]
            ++ map mkPortraitRows [
              2
              3
              4
              6
            ]
          );

          # Mutter currently indexes the primary Samsung ultrawide first and
          # the ASUS portrait display second. Tiling Shell persists only these
          # volatile indexes, not EDID or connector identity, so unplugging or
          # reordering displays can invalidate the mapping. Keep the
          # ultrawide's two workspace selections and default the portrait
          # display to 3 rows.
          selected-layouts = [
            [
              "Stacked Thirds"
              "Portrait 3 Rows"
            ]
            [
              "Stacked Thirds"
              "Portrait 3 Rows"
            ]
          ];
        };
    };
  };
}
