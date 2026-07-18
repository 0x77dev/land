{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.comms;
  openCommand =
    if pkgs.stdenv.hostPlatform.isDarwin then
      [ "/usr/bin/open" ]
    else
      [ (lib.getExe' pkgs.xdg-utils "xdg-open") ];
in
{
  options.modules.home.comms = {
    enable = mkEnableOption "comms";
  };

  config = mkIf cfg.enable {
    programs.iamb = {
      enable = true;
      settings = {
        default_profile = "default";

        profiles.default.user_id = "@dev0x77:matrix.org";

        # iamb uses terminal colors, so Ghostty's coordinated dark/light
        # GitHub themes remain the single palette owner.
        settings = {
          external_edit_file_suffix = ".md";
          log_level = "warn";
          message_shortcode_display = false;
          message_user_color = true;
          open_command = openCommand;
          reaction_display = true;
          reaction_shortcode_display = false;
          read_receipt_display = true;
          read_receipt_send = true;
          request_timeout = 180;
          typing_notice_display = true;
          typing_notice_send = true;
          user_gutter_width = 24;
          username_display = "displayname";

          image_preview = {
            protocol.type = "kitty";
            size = {
              height = 18;
              width = 72;
            };
          };

          notifications = {
            enabled = true;
            show_message = true;
            via = "desktop";
          };

          sort = {
            rooms = [
              "favorite"
              "lowpriority"
              "unread"
              "recent"
              "name"
            ];
            chats = [
              "favorite"
              "unread"
              "recent"
              "name"
            ];
            dms = [
              "unread"
              "recent"
              "name"
            ];
            spaces = [
              "favorite"
              "unread"
              "name"
            ];
            members = [
              "power"
              "id"
            ];
          };
        };

        layout.style = "restore";
      };
    };

    home.packages =
      with pkgs;
      [
        irssi # IRC
        tg # Telegram
        cinny-desktop # Matrix GUI
      ]
      # discord/slack have no aarch64-linux builds; gate them to x86_64-linux and Darwin.
      ++
        lib.optionals
          (
            pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64
            || pkgs.stdenv.isDarwin && (pkgs.stdenv.isx86_64 || pkgs.stdenv.isAarch64)
          )
          [
            discord
            slack
          ];
  };
}
