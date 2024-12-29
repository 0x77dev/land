{ pkgs, ... }:

let
  version = "0.4.0";
  sha256 = "6ee9128e3c3ae1024bcc98b47a4b1a8dfb268e5e017023b5aacf32dafda5faac";
in
{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname = "worklouder-input-app";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/focusense/wl-input-releases/releases/download/v${version}/input-${version}-mac.zip";
        inherit sha256;
      };
      sourceRoot = ".";
      phases = [ "unpackPhase" "installPhase" ];
      unpackPhase = ''
        ${pkgs.unzip}/bin/unzip $src
      '';
      installPhase = ''
        mkdir -p $out/Applications
        cp -r input.app $out/Applications/
      '';
    })
  ];
}
