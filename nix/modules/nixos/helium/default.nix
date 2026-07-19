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
  onePasswordOrigins = [
    "hjlinigoblmkhjejkmbegnoaljkphmgo"
    "gejiddohjgogedgjnonbofjigllpkmbf"
    "khgocmkkpikpnmmkgmdnfckapcdkgfaf"
    "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
    "dppgmdbiimibapkepcbdbmkaabgiofem"
  ];

  # Helium ships uBlock Origin as a component extension; forcing the Web Store
  # copy through Chromium policy would create a second, conflicting instance.
  ublockOriginExtensionId = "cjpalhdlnbpafiamejdnhcphjbkeiagm";

  # https://github.com/refined-github/refined-github#install
  refinedGitHubExtensionId = "hlepfoohegkhhmjieoechaddaejaokhf";
  # https://chromewebstore.google.com/detail/superhuman-mail/dcgcnpooblobhncpnddnhoendgbnglpn
  superhumanExtensionId = "dcgcnpooblobhncpnddnhoendgbnglpn";
  # Linux-only: its native-messaging host is supplied by the Vicinae package.
  # https://chromewebstore.google.com/detail/vicinae-integration/kcmipingpfbohfjckomimmahknoddnke
  vicinaeExtensionId = "kcmipingpfbohfjckomimmahknoddnke";

  onePasswordNativeMessagingHost = {
    name = "com.1password.1password";
    description = "1Password BrowserSupport";
    path = "/run/wrappers/bin/1Password-BrowserSupport";
    type = "stdio";
    allowed_origins = map (id: "chrome-extension://${id}/") onePasswordOrigins;
  };

  # NixOS does not get Vicinae's packaged system manifests; Helium reads the
  # same /etc/chromium native-messaging path as Chromium.
  # https://docs.vicinae.com/browser-extension
  vicinaeNativeMessagingHost = package: {
    name = "com.vicinae.vicinae";
    description = "Vicinae Native Messaging Host";
    path = "${package}/libexec/vicinae/vicinae-browser-link";
    type = "stdio";
    allowed_origins = [ "chrome-extension://${vicinaeExtensionId}/" ];
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
        Enable Chromium's system policy plumbing for Helium. Helium reads the
        same `/etc/chromium` policy and native-messaging paths as Chromium, so
        this lets `programs.chromium` remain the single declaration point.
      '';
    };

    enable1PasswordIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Register 1Password's Chromium native-messaging host for Helium and add
        Helium to 1Password's custom browser allowlist when 1Password GUI is
        enabled.
      '';
    };

    vicinaePackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "inputs.vicinae.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = ''
        When set, register Vicinae's Chromium native-messaging host under
        `/etc/chromium` so Helium can talk to the launcher. Force-install the
        store extension via `programs.chromium.extensions` (id
        `${vicinaeExtensionId}`).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ cfg.package ];
      programs.chromium = mkIf cfg.pairChromium {
        enable = mkDefault true;
        extensions = [
          refinedGitHubExtensionId
          superhumanExtensionId
        ]
        ++ optional (cfg.vicinaePackage != null) vicinaeExtensionId;
      };

      assertions = [
        {
          assertion = !cfg.pairChromium || !elem ublockOriginExtensionId config.programs.chromium.extensions;
          message = "Helium bundles uBlock Origin; do not force-install the duplicate Chromium extension.";
        }
      ];
    }

    (mkIf (cfg.enable1PasswordIntegration && config.programs._1password-gui.enable) {
      environment.etc = {
        "chromium/native-messaging-hosts/com.1password.1password.json" = {
          text = builtins.toJSON onePasswordNativeMessagingHost;
        };

        "1password/custom_allowed_browsers" = {
          text = mkAfter "helium\n";
          mode = "0755";
        };
      };
    })

    (mkIf (cfg.vicinaePackage != null) {
      environment.etc."chromium/native-messaging-hosts/com.vicinae.vicinae.json".text = builtins.toJSON (
        vicinaeNativeMessagingHost cfg.vicinaePackage
      );
    })
  ]);
}
