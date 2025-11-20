{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
  undmg,
  patchelf,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ua-connect";
  version = "1.8.1_3424";

  src = fetchurl {
    url = "https://builds.uaudio.com/apps/UA_Connect/UA_Connect_${
      builtins.replaceStrings [ "." ] [ "_" ] version
    }_Mac.dmg";
    hash = "sha256-Fb+fpKZLiNUhcLqa8YiElxbZMBi6PTCO+iiZnOSZzms=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    undmg
    patchelf
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r *.app $out/Applications

    # Remove quarantine attributes and immutable flags
    /usr/bin/xattr -rc $out/Applications || true
    /bin/chmod -R u+w $out/Applications
    /bin/chmod -R -N $out/Applications || true
    /usr/bin/chflags -R nouchg $out/Applications || true

    runHook postInstall
  '';

  meta = with lib; {
    description = "Manage UAD Spark plug-ins, Apollo interfaces, and more";
    homepage = "https://www.uaudio.com/ua-connect.html";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
  };
}
