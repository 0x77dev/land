{ ... }:

{
  system.defaults.dock = {
    # Arrange items in dock
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/Arc.app"
      "/Applications/Slack.app"
      "/Applications/Telegram.app"
      "/System/Applications/Messages.app"
      "/System/Applications/Reminders.app"
      "/Applications/Linear.app"
      "/Applications/Craft.app"
      "/Applications/Notion Calendar.app"
      "/Applications/Notion.app"
      "/Applications/Cursor.app"
      "/Applications/Nix Apps/kitty.app"
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
