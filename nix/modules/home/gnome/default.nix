{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.gnome;

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
  };

  config = mkIf cfg.enable {
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
      "org/gnome/shell".favorite-apps = cfg.favoriteApps;

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

      # Layout switching on Ctrl+Space (macOS habit); Super+Space belongs
      # to the launcher below.
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Control>space" ];
        switch-input-source-backward = [ "<Shift><Control>space" ];
      };

      # Vicinae on Super+Space, the Cmd+Space muscle memory.
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
        name = "Vicinae";
        command = "vicinae toggle";
        binding = "<Super>space";
      };
    };
  };
}
