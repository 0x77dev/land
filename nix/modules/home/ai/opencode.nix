{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";

  rawSettings = builtins.fromJSON (builtins.readFile (configDir + "/opencode.json"));
  mattpocockSkills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "5fed805a92ddf70dedf1f32c6aadb2a08aaf4d9c";
    hash = "sha256-97nxvHWZVvWq3HpLjrDUe8bPIo/6RVeeZmrlq42bEww=";
  };

  mattPocockOpenCodeSkills = {
    diagnose = mattpocockSkills + "/skills/engineering/diagnose";
    grill-with-docs = mattpocockSkills + "/skills/engineering/grill-with-docs";
    triage = mattpocockSkills + "/skills/engineering/triage";
    improve-codebase-architecture =
      mattpocockSkills + "/skills/engineering/improve-codebase-architecture";
    setup-matt-pocock-skills = mattpocockSkills + "/skills/engineering/setup-matt-pocock-skills";
    tdd = mattpocockSkills + "/skills/engineering/tdd";
    to-issues = mattpocockSkills + "/skills/engineering/to-issues";
    to-prd = mattpocockSkills + "/skills/engineering/to-prd";
    zoom-out = mattpocockSkills + "/skills/engineering/zoom-out";

    caveman = mattpocockSkills + "/skills/productivity/caveman";
    grill-me = mattpocockSkills + "/skills/productivity/grill-me";
    write-a-skill = mattpocockSkills + "/skills/productivity/write-a-skill";
  };

  opencodeSkills = lib.mapAttrs' (
    name: source:
    lib.nameValuePair "opencode/skills/${name}" {
      inherit source;
      recursive = true;
    }
  ) mattPocockOpenCodeSkills;
in
{
  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = removeAttrs rawSettings [ "$schema" ];
      rules = configDir + "/ai/AGENTS.md";
    };

    xdg.configFile = opencodeSkills // {
      "opencode/oh-my-openagent.json".source = configDir + "/oh-my-opencode.json";
    };
  };
}
