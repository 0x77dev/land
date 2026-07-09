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

    extensions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra GNOME Shell extension UUIDs to enable (PaperWM is always on).";
    };
  };

  config = mkIf cfg.enable {
    # PaperWM: scrollable-tiling window management, managed declaratively.
    home.packages = [ pkgs.gnomeExtensions.paperwm ];

    # Ghostty is the terminal: TERMINAL for launchers/scripts that honor it.
    home.sessionVariables.TERMINAL = "ghostty";

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
        enabled-extensions = [ "paperwm@paperwm.github.com" ] ++ cfg.extensions;
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

      # macOS-compatible muscle memory: layout switching on Ctrl+Space,
      # Super+Q closes like Cmd+Q. Super+Space belongs to the launcher.
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Control>space" ];
        switch-input-source-backward = [ "<Shift><Control>space" ];
        close = [ "<Super>q" ];
      };

      # Screenshots on the Cmd+Shift+3/4 pattern.
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = [ "<Shift><Super>4" ];
        screenshot = [ "<Shift><Super>3" ];
      };

      # Vicinae on Super+Space (Cmd+Space), Ghostty on Ctrl+Alt+T.
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
        name = "Vicinae";
        command = "vicinae toggle";
        binding = "<Super>space";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
        name = "Terminal";
        command = "ghostty";
        binding = "<Control><Alt>t";
      };

      # PaperWM navigation kept close to Raycast/macOS window management:
      # Super+arrows move focus, Ctrl+Super+arrows move windows,
      # Ctrl+Alt+Return toggles full width (Raycast's maximize chord).
      "org/gnome/shell/extensions/paperwm" = {
        show-window-position-bar = false;
      };
      "org/gnome/shell/extensions/paperwm/keybindings" = {
        switch-left = [ "<Super>Left" ];
        switch-right = [ "<Super>Right" ];
        switch-up-workspace = [ "<Super>Up" ];
        switch-down-workspace = [ "<Super>Down" ];
        move-left = [ "<Control><Super>Left" ];
        move-right = [ "<Control><Super>Right" ];
        toggle-maximize-width = [ "<Control><Alt>Return" ];
      };
    };
  };
}
