{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.pi-coding-agent;
  jsonFormat = pkgs.formats.json { };
  upstreamConfigDir = "${config.home.homeDirectory}/.pi/agent";
  packageWithExtraPackages =
    if cfg.package != null && cfg.extraPackages != [ ] then
      pkgs.symlinkJoin {
        inherit (cfg.package) meta;
        name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
        '';
      }
    else
      cfg.package;
in
{
  # Keep this backport authoritative if a future Home Manager update adds the
  # upstream module; remove both lines when switching to the upstream copy.
  disabledModules = [ "programs/pi-coding-agent.nix" ];

  # Backport of Home Manager's upstream Pi module. Remove this file and its
  # import once the pinned Home Manager release provides the same options.
  options.programs.pi-coding-agent = {
    enable = mkEnableOption "Pi coding agent";
    package = mkPackageOption pkgs.llm-agents "pi" { nullable = true; };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages added to Pi's PATH, including its npm package manager.";
    };

    configDir = mkOption {
      type = types.str;
      default = upstreamConfigDir;
      description = "Directory containing Pi's user configuration.";
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Declarative Pi settings written to settings.json.";
    };

    keybindings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Declarative Pi keybindings written to keybindings.json.";
    };

    models = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Declarative custom Pi model providers written to models.json.";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (packageWithExtraPackages != null) [ packageWithExtraPackages ];
      sessionVariables = mkIf (cfg.configDir != upstreamConfigDir) {
        PI_CODING_AGENT_DIR = cfg.configDir;
      };
      file = lib.mkMerge [
        (mkIf (cfg.settings != { }) {
          "${cfg.configDir}/settings.json".source =
            jsonFormat.generate "pi-coding-agent-settings.json" cfg.settings;
        })
        (mkIf (cfg.keybindings != { }) {
          "${cfg.configDir}/keybindings.json".source =
            jsonFormat.generate "pi-coding-agent-keybindings.json" cfg.keybindings;
        })
        (mkIf (cfg.models != { }) {
          "${cfg.configDir}/models.json".source =
            jsonFormat.generate "pi-coding-agent-models.json" cfg.models;
        })
      ];
    };
  };
}
