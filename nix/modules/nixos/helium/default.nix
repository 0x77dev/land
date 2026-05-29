{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
let
  cfg = config.programs.helium;
  inherit (config.programs) chromium;

  pair = cfg.pairChromium && chromium.enable;

  # Recreated from the upstream `programs.chromium` policy module so the same
  # managed-policy declaration applies to Helium. Helium is a Chromium fork and
  # reads enterprise policies from /etc/helium/policies/managed.
  defaultProfile = filterAttrs (_: v: v != null) {
    HomepageLocation = chromium.homepageLocation;
    DefaultSearchProviderEnabled = chromium.defaultSearchProviderEnabled;
    DefaultSearchProviderSearchURL = chromium.defaultSearchProviderSearchURL;
    DefaultSearchProviderSuggestURL = chromium.defaultSearchProviderSuggestURL;
    ExtensionInstallForcelist = chromium.extensions;
  };
in
{
  options.programs.helium = {
    enable = mkEnableOption "Helium browser";

    package = mkOption {
      type = types.package;
      default = pkgs.${namespace}.helium;
      defaultText = literalExpression "pkgs.${namespace}.helium";
      description = "The Helium package to install system-wide.";
    };

    pairChromium = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Mirror the managed policies declared via `programs.chromium`
        (extensions force-list, search provider, `extraOpts`, `initialPrefs`)
        into Helium's policy directory, so one declaration configures both.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { environment.systemPackages = [ cfg.package ]; }

    (mkIf pair {
      environment.etc = {
        "helium/policies/managed/default.json" = mkIf (defaultProfile != { }) {
          text = builtins.toJSON defaultProfile;
        };
        "helium/policies/managed/extra.json" = mkIf (chromium.extraOpts != { }) {
          text = builtins.toJSON chromium.extraOpts;
        };
        "helium/initial_preferences" = mkIf (chromium.initialPrefs != { }) {
          text = builtins.toJSON chromium.initialPrefs;
        };
      };
    })
  ]);
}
