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
    # Window management is split three ways, with no two mechanisms grabbing
    # the same chord: gTile owns the Rectangle/Raycast keyboard layer
    # (Ctrl+Alt), Tiling Shell owns the pointer (edge snapping, snap-layout
    # picker, FancyZones-style per-monitor layouts), and GNOME keeps
    # maximize/restore, monitors and workspaces.
    home.packages = [
      pkgs.gnomeExtensions.tiling-shell
      pkgs.gnomeExtensions.gtile
    ];

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
        enabled-extensions = [
          "tilingshell@ferrarodomenico.com"
          "gTile@vibou"
        ]
        ++ cfg.extensions;
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

        # GNOME shipped workspace switching on Ctrl+Alt+arrows and window
        # moving on Shift+Ctrl+Alt+arrows, which shadowed every tiling
        # shortcut on that layer. Workspaces keep their Super chords only;
        # up/down are dropped because the workspace layout is horizontal.
        switch-to-workspace-left = [
          "<Super>Page_Up"
          "<Super><Alt>Left"
        ];
        switch-to-workspace-right = [
          "<Super>Page_Down"
          "<Super><Alt>Right"
        ];
        switch-to-workspace-up = [ ];
        switch-to-workspace-down = [ ];
        move-to-workspace-left = [
          "<Shift><Super>Page_Up"
          "<Shift><Super><Alt>Left"
        ];
        move-to-workspace-right = [
          "<Shift><Super>Page_Down"
          "<Shift><Super><Alt>Right"
        ];
        move-to-workspace-up = [ ];
        move-to-workspace-down = [ ];

        # Rectangle's Maximize, Restore and Maximize Height. These are real
        # window states rather than a full-area tile, so Restore returns the
        # window to the geometry it had before Maximize.
        maximize = [
          "<Control><Alt>Return"
          "<Super>Up"
        ];
        unmaximize = [
          "<Control><Alt>BackSpace"
          "<Super>Down"
        ];
        maximize-vertically = [ "<Shift><Control><Alt>Up" ];

        # Throw windows across monitors (ultrawide <-> portrait); the
        # Ctrl+Alt+Super pair mirrors Move to Next/Previous Display.
        move-to-monitor-left = [
          "<Shift><Super>Left"
          "<Control><Alt><Super>Left"
        ];
        move-to-monitor-right = [
          "<Shift><Super>Right"
          "<Control><Alt><Super>Right"
        ];
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
        binding = "<Super>Return";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voxtype" = {
        name = "Voice dictation";
        command = "${config.home.profileDirectory}/bin/voxtype record toggle";
        binding = "XF86VoiceCommand";
      };

      # Tiling Shell keeps the pointer: drag to the top edge for the
      # snap-layout picker, screen edges for halves/quarters, snap assist
      # suggests windows for the remaining space. Its keyboard layer stays
      # off on purpose - enabling it makes the extension blank GNOME's own
      # maximize/unmaximize and mutter's toggle-tiled keybindings
      # (keybindings.js `_overrideNatives`), which the Rectangle layer needs.
      # `overridden-settings` is pinned empty so a stale restore cannot write
      # those GNOME defaults back over this configuration.
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
          enable-move-keybindings = false;
          overridden-settings = "{}";
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

      # Rectangle/Raycast keyboard layer, ported chord for chord from the
      # macOS setup. gTile places the focused window from an absolute grid
      # spec: "<cols>x<rows> <left>:<top> <right>:<bottom>", 1-indexed and
      # inclusive over the monitor work area. Comma-separated variants cycle
      # when the same chord is pressed again inside gTile's two-second window
      # (v65 hard-codes that lifetime and ignores `max-timeout`).
      "org/gnome/shell/extensions/gtile" =
        let
          placements = {
            "<Control><Alt>Left" = "2x1 1:1 1:1"; # Left half
            "<Control><Alt>Right" = "2x1 2:1 2:1"; # Right half
            "<Control><Alt>Up" = "1x2 1:1 1:1"; # Top half
            "<Control><Alt>Down" = "1x2 1:2 1:2"; # Bottom half
            "<Control><Alt>u" = "2x2 1:1 1:1"; # Top left quarter
            "<Control><Alt>i" = "2x2 2:1 2:1"; # Top right quarter
            "<Control><Alt>j" = "2x2 1:2 1:2"; # Bottom left quarter
            "<Control><Alt>k" = "2x2 2:2 2:2"; # Bottom right quarter
            "<Control><Alt>d" = "3x1 1:1 1:1"; # First third
            "<Control><Alt>f" = "3x1 2:1 2:1"; # Center third
            "<Control><Alt>g" = "3x1 3:1 3:1"; # Last third
            "<Control><Alt>e" = "3x1 1:1 2:1"; # First two thirds
            "<Control><Alt>t" = "3x1 2:1 3:1"; # Last two thirds
            "<Control><Alt>1" = "4x1 1:1 1:1"; # First fourth
            "<Control><Alt>2" = "4x1 2:1 2:1"; # Second fourth
            "<Control><Alt>3" = "4x1 3:1 3:1"; # Third fourth
            "<Control><Alt>4" = "4x1 4:1 4:1"; # Last fourth
            "<Control><Alt>5" = "4x1 2:1 3:1"; # Center half
            # Center: two thirds, then half, then four fifths.
            "<Control><Alt>c" = "6x6 2:2 5:5,4x4 2:2 3:3,10x10 2:2 9:9";
          };

          chords = attrNames placements;

          # Slot N drives both `resize<N>` (the geometry) and
          # `preset-resize-<N>` (the chord that applies it).
          presets = listToAttrs (
            concatLists (
              imap1 (index: chord: [
                (nameValuePair "resize${toString index}" placements.${chord})
                (nameValuePair "preset-resize-${toString index}" [ chord ])
              ]) chords
            )
          );

          # gTile ships 30 slots pre-bound to Super+modifier+numpad; release
          # the ones this configuration does not use.
          spareSlots = genAttrs (map (index: "preset-resize-${toString index}") (
            range (length chords + 1) 30
          )) (_: [ ]);
        in
        presets
        // spareSlots
        // {
          # Presets act on the focused window without opening the grid, and
          # target the monitor the window is on rather than the pointer's.
          global-presets = true;
          target-presets-to-monitor-of-mouse = false;
          # A full-area preset stays a plain resize: GNOME owns the maximized
          # state so Ctrl+Alt+Backspace can restore out of it.
          auto-maximize = false;
          # Tiling Shell already carries a tiling indicator in the panel.
          show-icon = false;

          # Rectangle's Make Larger / Make Smaller. gTile moves one edge per
          # press by a single line of the active grid - the first entry below
          # until the overlay cycles it - so Ctrl+Alt is width and
          # Shift+Ctrl+Alt is height.
          grid-sizes = "8x6,6x4,4x4";
          moveresize-enabled = true;
          action-expand-right = [ "<Control><Alt>equal" ];
          action-contract-right = [ "<Control><Alt>minus" ];
          action-expand-bottom = [ "<Shift><Control><Alt>equal" ];
          action-contract-bottom = [ "<Shift><Control><Alt>minus" ];
          action-expand-left = [ ];
          action-expand-top = [ ];
          # Ctrl+Alt+h/j/k/l by default, which collides with the quarters.
          action-contract-left = [ ];
          action-contract-top = [ ];

          # The interactive grid overlay, moved off Super+Return (Ghostty).
          show-toggle-tiling = [ "<Control><Super>g" ];
          snap-to-neighbors = [ ];
          move-next-monitor = [ ];
        };
    };
  };
}
