{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  home = shared.home // {
    packages = with pkgs; [
      telegram-desktop
      spotify
      zoom-us
    ];

    # Consistent cursor everywhere, including Xwayland and Qt apps that read
    # XCURSOR_* instead of dconf.
    pointerCursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  modules.home = shared.modules.home // {
    ai.enable = true;
    browser.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    gnome = {
      enable = true;
      extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "tailscale@joaophi.github.com" # Tailscale in quick settings
      ];
    };
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    network.enable = true;
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security-tools.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  programs = {
    home-manager.enable = true;

    # Screen recording / streaming with PipeWire capture.
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    };

    # Raycast-style launcher on Super+Space (keybinding lives in the gnome
    # module). The systemd user service keeps the daemon warm.
    vicinae = {
      enable = true;
      systemd.enable = true;
      settings = {
        # Match GNOME/macOS typography; emoji resolves through fontconfig to
        # Apple Color Emoji.
        font.normal = {
          family = "SF Pro Text";
          size = 12;
        };
        theme = {
          light.name = "adwaita-light";
          dark.name = "adwaita-dark";
        };
      };
      themes = {
        adwaita-light = {
          meta = {
            version = 1;
            name = "Adwaita Light";
            variant = "light";
            inherits = "vicinae-light";
          };
          colors = {
            core = {
              background = "#FAFAFA";
              foreground = "#2E3436";
              secondary_background = "#F6F5F4";
              border = "#DEDDDA";
              accent = "#3584E4";
            };
            accents = {
              blue = "#3584E4";
              green = "#33D17A";
              magenta = "#C061CB";
              orange = "#FF7800";
              purple = "#9141AC";
              red = "#E01B24";
              yellow = "#F6D32D";
              cyan = "#00A5A5";
            };
          };
        };
        adwaita-dark = {
          meta = {
            version = 1;
            name = "Adwaita Dark";
            variant = "dark";
            inherits = "vicinae-dark";
          };
          colors = {
            core = {
              background = "#1E1E1E";
              foreground = "#F6F5F4";
              secondary_background = "#303030";
              border = "#5E5C64";
              accent = "#78AEED";
            };
            accents = {
              blue = "#78AEED";
              green = "#57E389";
              magenta = "#DC8ADD";
              orange = "#FFBE6F";
              purple = "#C061CB";
              red = "#FF7B63";
              yellow = "#F8E45C";
              cyan = "#33C7DE";
            };
          };
        };
      };
    };

    # Push-to-talk dictation: hold ScrollLock, speak, release. Vulkan build
    # runs large-v3-turbo fast on the RTX 6000 Ada.
    voxtype = {
      enable = true;
      package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
      model.name = "large-v3-turbo";
      service.enable = true;
      settings = {
        whisper.language = "auto";
        output = {
          mode = "type";
          fallback_to_clipboard = true;
        };
        output.notification.on_transcription = true;
      };
    };
  };

  # Appearance, kept declarative. Cursor/icon themes are pinned because the
  # prior KDE install left `breeze` in dconf, which renders broken in GNOME.
  dconf.settings =
    let
      wallpaper = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-l.jxl";
        primary-color = "#86b6ef";
        secondary-color = "#000000";
      };
    in
    {
      "org/gnome/desktop/interface" = {
        cursor-theme = "Adwaita";
        icon-theme = "Adwaita";
        color-scheme = "prefer-dark";
        accent-color = "blue";
        # Apple typography, same roles as macOS.
        font-name = "SF Pro Display 12";
        document-font-name = "SF Pro Text 12";
        monospace-font-name = "TX-02-Variable 12";
      };

      "org/gnome/desktop/background" = wallpaper // {
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-d.jxl";
      };

      "org/gnome/desktop/screensaver" = wallpaper;
    };
}
