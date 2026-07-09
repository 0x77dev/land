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
        # Match the system typography (fontconfig routes emoji to Apple
        # Color Emoji) and follow GNOME's light/dark preference.
        font.normal = {
          family = "Inter";
          size = 11;
        };
        theme = {
          light.name = "vicinae-light";
          dark.name = "vicinae-dark";
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
        font-name = "SF Pro Display 10";
        document-font-name = "SF Pro Text 10";
        monospace-font-name = "SF Mono 10";
      };

      "org/gnome/desktop/background" = wallpaper // {
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-d.jxl";
      };

      "org/gnome/desktop/screensaver" = wallpaper;
    };
}
