{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.niri;
in
{
  options.modules.home.niri = {
    enable = mkEnableOption "Niri home configuration";

    terminal = mkOption {
      type = types.str;
      default = "ghostty";
      description = "Terminal emulator command";
    };

    launcher = mkOption {
      type = types.str;
      default = "fuzzel";
      description = "Application launcher command";
    };
  };

  config = mkIf cfg.enable {
    # Enable mako for notifications
    services.mako = {
      enable = true;
      defaultTimeout = 5000;
    };

    # Enable swayidle for idle management
    services.swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "niri msg action power-off-monitors";
        }
      ];
    };

    programs = {
      # Enable waybar for status bar
      waybar = {
        enable = true;
        systemd.enable = true;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [
            "niri/workspaces"
            "niri/window"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            "tray"
          ];
          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%Y-%m-%d %H:%M}";
          };
          cpu.format = "CPU {usage}%";
          memory.format = "RAM {}%";
          network = {
            format-wifi = "{essid} ({signalStrength}%)";
            format-ethernet = "{ifname}";
            format-disconnected = "Disconnected";
          };
          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = "Muted";
            format-icons.default = [
              ""
              ""
            ];
          };
          tray.spacing = 10;
        };
      };

      # Fuzzel launcher
      fuzzel = {
        enable = true;
        settings = {
          main = {
            inherit (cfg) terminal;
            layer = "overlay";
          };
          colors = {
            background = "1e1e2edd";
            text = "cdd6f4ff";
            selection = "585b70ff";
            selection-text = "cdd6f4ff";
            border = "b4befeff";
          };
        };
      };

      # Niri configuration using niri-flake's programs.niri.settings
      niri.settings =
        let
          inherit (cfg) terminal launcher;
        in
        {
          # Input configuration
          input = {
            keyboard.xkb.layout = "us";
            mouse.accel-speed = 0.0;
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };

          # Layout configuration
          layout = {
            gaps = 8;
            center-focused-column = "never";
            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
            ];
            default-column-width.proportion = 1.0 / 2.0;
            focus-ring.enable = false;
            border = {
              enable = true;
              width = 2;
              active.color = "#b4befe";
              inactive.color = "#585b70";
            };
          };

          # Spawn commands at startup
          spawn-at-startup = [
            { command = [ "waybar" ]; }
            { command = [ "mako" ]; }
            {
              command = [
                "systemctl"
                "--user"
                "reset-failed"
                "waybar.service"
              ];
            }
            { command = [ "xwayland-satellite" ]; }
          ];

          # Environment variables
          environment = {
            DISPLAY = ":0";
            NIXOS_OZONE_WL = "1";
          };

          # Prefer no client-side decorations
          prefer-no-csd = true;

          # Screenshot path
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

          # Hotkey overlay
          hotkey-overlay.skip-at-startup = true;

          # Key bindings
          binds = {
            # Terminal
            "Mod+Return".action.spawn = [ terminal ];

            # Launcher
            "Mod+D".action.spawn = [ launcher ];

            # Close window
            "Mod+Shift+Q".action.close-window = { };

            # Exit niri
            "Mod+Shift+E".action.quit = { };

            # Focus navigation
            "Mod+H".action.focus-column-left = { };
            "Mod+L".action.focus-column-right = { };
            "Mod+J".action.focus-window-down = { };
            "Mod+K".action.focus-window-up = { };
            "Mod+Left".action.focus-column-left = { };
            "Mod+Right".action.focus-column-right = { };
            "Mod+Down".action.focus-window-down = { };
            "Mod+Up".action.focus-window-up = { };

            # Move windows
            "Mod+Shift+H".action.move-column-left = { };
            "Mod+Shift+L".action.move-column-right = { };
            "Mod+Shift+J".action.move-window-down = { };
            "Mod+Shift+K".action.move-window-up = { };
            "Mod+Shift+Left".action.move-column-left = { };
            "Mod+Shift+Right".action.move-column-right = { };
            "Mod+Shift+Down".action.move-window-down = { };
            "Mod+Shift+Up".action.move-window-up = { };

            # Workspace navigation
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            # Move window to workspace
            "Mod+Shift+1".action.move-column-to-workspace = 1;
            "Mod+Shift+2".action.move-column-to-workspace = 2;
            "Mod+Shift+3".action.move-column-to-workspace = 3;
            "Mod+Shift+4".action.move-column-to-workspace = 4;
            "Mod+Shift+5".action.move-column-to-workspace = 5;
            "Mod+Shift+6".action.move-column-to-workspace = 6;
            "Mod+Shift+7".action.move-column-to-workspace = 7;
            "Mod+Shift+8".action.move-column-to-workspace = 8;
            "Mod+Shift+9".action.move-column-to-workspace = 9;

            # Column width
            "Mod+R".action.switch-preset-column-width = { };
            "Mod+F".action.maximize-column = { };
            "Mod+Shift+F".action.fullscreen-window = { };

            # Consume/expel windows
            "Mod+BracketLeft".action.consume-window-into-column = { };
            "Mod+BracketRight".action.expel-window-from-column = { };

            # Scrolling
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";

            # Screenshots
            "Print".action.screenshot = { };
            "Mod+Print".action.screenshot-screen = { };
            "Mod+Shift+Print".action.screenshot-window = { };

            # Screen lock
            "Mod+Alt+L".action.spawn = [
              "swaylock"
              "-f"
            ];

            # Monitor power
            "Mod+Shift+P".action.power-off-monitors = { };
          };

          # Window rules
          window-rules = [
            # Make Firefox PiP floating
            {
              matches = [
                {
                  app-id = "^firefox$";
                  title = "^Picture-in-Picture$";
                }
              ];
              open-floating = true;
            }
            # Steam windows
            {
              matches = [ { app-id = "^steam$"; } ];
              open-maximized = true;
            }
          ];
        };
    };

    # Install additional packages
    home.packages = with pkgs; [
      swaylock
      swaybg
      grim
      slurp
      wl-clipboard
      xwayland-satellite
    ];

    # Create screenshots directory
    home.file."Pictures/Screenshots/.keep".text = "";
  };
}
