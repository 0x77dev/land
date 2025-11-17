{
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  pinentryPackage = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
in
{
  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = ./keys/0x77dev.asc;
        trust = 5;
      }
    ];
    settings = {
      default-key = "C33BFD3230B660CF147762D2BF5C81B531164955";
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
      keyserver = "hkps://keys.openpgp.org";
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
    pinentry.package = pinentryPackage;
    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
    maxCacheTtl = 7200;
    maxCacheTtlSsh = 7200;
    sshKeys = [ "989988446B6CB6CB" ];
    extraConfig = ''
      enable-ssh-support
      no-allow-external-cache
    '';
  };

  home.sessionVariables = {
    GPG_TTY = ''$(tty)'';
    SSH_AUTH_SOCK = ''$(gpgconf --list-dirs agent-ssh-socket)'';
  };
}
