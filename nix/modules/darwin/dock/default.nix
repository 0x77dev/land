{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.darwin.dock;

  userName = builtins.head (builtins.attrNames config.snowfallorg.users);
  hmApps = "/Users/${userName}/Applications/Home Manager Apps";

  lower = lib.toLower;
  caskNames = map (c: lower (c.name or c)) (config.homebrew.casks or [ ]);
  masNames = map lower (builtins.attrNames (config.homebrew.masApps or { }));
  pkgNames = map (p: lower (p.pname or "")) (
    config.home-manager.users.${userName}.home.packages or [ ]
  );
  allNames = caskNames ++ masNames ++ pkgNames;

  has = name: builtins.elem (lower name) allNames;

  appDefs = [
    {
      path = "/Applications/Helium.app";
      available = has "helium-browser";
    }
    {
      path = "/Applications/Superhuman.app";
      available = has "superhuman";
    }
    {
      path = "${hmApps}/Cursor.app";
      available = has "cursor";
    }
    {
      path = "${hmApps}/Ghostty.app";
      available = has "ghostty-bin";
    }
    {
      path = "/Applications/Notion Calendar.app";
      available = has "notion-calendar";
    }
    {
      path = "/Applications/Setapp/Craft.app";
      available = has "setapp";
    }
    {
      path = "/Applications/Slack.app";
      available = has "slack";
    }
    {
      path = "/Applications/Telegram.app";
      available = has "telegram";
    }
    {
      path = "/System/Applications/Messages.app";
      available = true;
    }
    {
      path = "/Applications/Things3.app";
      available = has "things";
    }
    {
      path = "/Applications/Spotify.app";
      available = has "spotify";
    }
  ];

  autoApps = map (a: a.path) (builtins.filter (a: a.available) appDefs);
in
{
  options.modules.darwin.dock = {
    enable = lib.mkEnableOption "managed dock layout";

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = autoApps;
      description = "Ordered list of .app paths for the dock. Auto-populated from installed casks, masApps, and packages.";
    };

    tilesize = lib.mkOption {
      type = lib.types.int;
      default = 43;
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock = {
      autohide = true;
      inherit (cfg) tilesize;
      persistent-apps = cfg.apps;
    };
  };
}
