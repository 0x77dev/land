{ ... }: {
  system.defaults.dock = {
    # Arrange items in dock
    persistent-apps = [
      "/Applications/Arc.app"
      "/Applications/Slack.app"
      "/Applications/Telegram.app"
      "/System/Applications/Messages.app"
      "/Applications/Things3.app"
      "/Applications/Linear.app"
      "/Applications/Craft.app"
      "/Applications/Notion Calendar.app"
      "/Applications/Setapp/Spark Mail.app"
      "/Applications/Cursor.app"
      "/Users/0x77/Applications/Home Manager Apps/Ghostty.app"
      "/Applications/Spotify.app"
      "/System/Applications/System Settings.app"
    ];

    # Dock settings
    orientation = "bottom";
    tilesize = 48;
    autohide = true;
    show-recents = true;
    minimize-to-application = false;
  };
}
