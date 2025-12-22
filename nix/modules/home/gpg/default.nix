{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.gpg;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  options.modules.home.gpg = {
    enable = mkEnableOption "gpg";

    pinentryPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      defaultText = literalExpression "if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses";
      example = literalExpression "pkgs.pinentry-qt";
      description = ''
        Override the pinentry package for GPG password prompts.

        If null, uses platform defaults:
        - macOS: pinentry_mac (native keychain integration)
        - Linux: pinentry-curses (terminal-based)

        Common options:
        - pinentry-qt: Qt/KDE integration (recommended for KDE Plasma)
        - pinentry-gnome3: GNOME integration
        - pinentry-gtk2: GTK2 integration
        - pinentry-curses: Terminal-based (lightweight)
        - pinentry-tty: Minimal TTY version

        Note: For KDE Plasma systems, consider enabling programs.gnupg.agent
        at the system level instead, which auto-selects pinentry-qt.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      publicKeys = [
        {
          source = inputs.self + "/gpg/keys/0x77dev.asc";
          trust = 5;
        }
      ];
      settings = {
        default-key = "A6337A4AB36481FB18A4FCC5F1171FAAAA237211";
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";
        charset = "utf-8";
        trust-model = "tofu+pgp";
        auto-key-locate = "wkd cert pka ldap hkps://keys.openpgp.org";
        fixed-list-mode = true;
        no-comments = true;
        no-emit-version = true;
        no-greeting = true;
        keyid-format = "0xlong";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        with-fingerprint = true;
        require-cross-certification = true;
        no-symkey-cache = true;
        armor = true;
        use-agent = true;
        throw-keyids = true;
        auto-key-retrieve = true;
      };
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      pinentry.package =
        if cfg.pinentryPackage != null then
          cfg.pinentryPackage
        else
          (if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses);
      defaultCacheTtl = 3600;
      defaultCacheTtlSsh = 3600;
      maxCacheTtl = 7200;
      maxCacheTtlSsh = 7200;
      sshKeys = [ "BFBFB340E3611C2A" ];
      extraConfig = ''
        enable-ssh-support
        no-allow-external-cache
        allow-loopback-pinentry
      '';
    };

    home.sessionVariables = {
      GPG_TTY = ''$(tty)'';
      SSH_AUTH_SOCK = ''$(gpgconf --list-dirs agent-ssh-socket)'';
    };
  };
}
