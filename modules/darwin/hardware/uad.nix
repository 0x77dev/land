{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (stdenvNoCC.mkDerivation rec {
      pname = "ua-connect";
      version = "1.6.3_3328";

      src = fetchurl {
        url = "https://builds.uaudio.com/apps/UA_Connect/UA_Connect_${builtins.replaceStrings ["."] ["_"] version}_Mac.dmg";
        hash = "sha256-oeKLjUuBuxywvbCUhnOKU3CsHoKrs2957pQDxmG7shU=";
      };

      nativeBuildInputs = [ pkgs.undmg ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/Applications
        cp -r *.app $out/Applications
        runHook postInstall
      '';

      meta = with lib; {
        description = "Manage UAD Spark plug-ins, Apollo interfaces, and more";
        homepage = "https://www.uaudio.com/ua-connect.html";
        license = licenses.unfree;
        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
        platforms = platforms.darwin;
        maintainers = [ ];
      };
    })
  ];
}
