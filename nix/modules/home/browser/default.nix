{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  cfg = config.modules.home.browser;
  inherit (config.programs) chromium;
  heliumConfigDir = "net.imput.helium";
  heliumConfigHome = "${config.xdg.configHome}/${heliumConfigDir}";

  # When pairing is on, inherit whatever the user already declared for
  # home-manager's `programs.chromium` so a single config drives both browsers.
  paired = cfg.pairChromium && chromium.enable;

  args = (optionals paired chromium.commandLineArgs) ++ cfg.commandLineArgs;

  # Normalise both chromium's rich extension submodules and our plain id strings
  # into the External Extensions JSON shape Chromium reads on Linux.
  inheritedExtensions = optionals paired chromium.extensions;
  ownExtensions = map (id: {
    inherit id;
    updateUrl = "https://clients2.google.com/service/update2/crx";
    crxPath = null;
    version = null;
  }) cfg.extensions;
  extensions = inheritedExtensions ++ ownExtensions;

  finalPackage =
    if args != [ ] then
      cfg.package.override { commandLineArgs = concatStringsSep " " args; }
    else
      cfg.package;

  # Force-installed extensions land in Helium's per-user config dir. System-wide
  # Chromium conventions (policies + native messaging) are handled by the NixOS
  # `programs.helium` module.
  extensionFile = ext: {
    name = "${heliumConfigHome}/External Extensions/${ext.id}.json";
    value.text = builtins.toJSON (
      if ext.crxPath != null then
        {
          external_crx = ext.crxPath;
          external_version = ext.version;
        }
      else
        { external_update_url = ext.updateUrl; }
    );
  };
in
{
  options.modules.home.browser = {
    enable = mkEnableOption "Helium browser";

    package = mkOption {
      type = types.package;
      default = pkgs.${namespace}.helium;
      defaultText = literalExpression "pkgs.${namespace}.helium";
      description = "The Helium package to install.";
    };

    widevinePackage = mkOption {
      type = types.nullOr types.package;
      default = if pkgs.stdenv.isLinux then pkgs.widevine-cdm else null;
      defaultText = literalExpression "if pkgs.stdenv.isLinux then pkgs.widevine-cdm else null";
      description = "Widevine CDM package exposed to Helium; set to null to disable.";
    };

    pairChromium = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Inherit `commandLineArgs` and `extensions` from `programs.chromium` so a
        single chromium-style declaration configures Helium too.
      '';
    };

    commandLineArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--ozone-platform-hint=auto" ];
      description = "Extra command-line flags appended to Helium.";
    };

    extensions = mkOption {
      type = types.listOf (types.strMatching "[a-zA-Z]{32}");
      default = [ ];
      example = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
      description = "Extra Chrome Web Store extension IDs to force-install (Linux only).";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ finalPackage ];

      file = mkIf pkgs.stdenv.isLinux (listToAttrs (map extensionFile extensions));
    };

    # Helium builds Widevine in component mode, so Chromium discovers the
    # immutable CDM through its per-profile component hint.
    xdg.configFile."${heliumConfigDir}/WidevineCdm/latest-component-updated-widevine-cdm" =
      mkIf (pkgs.stdenv.isLinux && cfg.widevinePackage != null)
        {
          text = builtins.toJSON {
            Path = "${cfg.widevinePackage}/share/google/chrome/WidevineCdm";
          };
        };
  };
}
