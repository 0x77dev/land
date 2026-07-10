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
          light.name = "libadwaita-light";
          dark.name = "libadwaita-dark";
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

  # Zoom for Linux has no real dark mode. This enables its supported Qt
  # system-theme integration while keeping zoomus.conf mutable for the app.
  home.activation.zoomSystemTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_file="$HOME/.config/zoomus.conf"
    if [ -f "$config_file" ]; then
      if ${pkgs.gnugrep}/bin/grep -q '^useSystemTheme=' "$config_file"; then
        run ${pkgs.gnused}/bin/sed -i 's/^useSystemTheme=.*/useSystemTheme=true/' "$config_file"
      else
        run ${pkgs.coreutils}/bin/printf '\nuseSystemTheme=true\n' >> "$config_file"
      fi
    else
      run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config"
      run ${pkgs.coreutils}/bin/printf '[General]\nuseSystemTheme=true\n' > "$config_file"
    fi
  '';

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
        accent-color = "slate";
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
