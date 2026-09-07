{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
  _7zz,
  ...
}:

let
  base = "https://devimages-cdn.apple.com/design/resources/download";

  sources = {
    sf-pro = fetchurl {
      url = "${base}/SF-Pro.dmg";
      hash = "sha256-qQlPDem3idc1RO5Q/FKgiE1Kn3/PYt5Sl04yBPOnSmI=";
    };
    sf-compact = fetchurl {
      url = "${base}/SF-Compact.dmg";
      hash = "sha256-LIkAOWe+WaaGeqXeEgZjUtmmtEt4XPK5/4jvDXf/KPw=";
    };
    sf-mono = fetchurl {
      url = "${base}/SF-Mono.dmg";
      hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
    };
    new-york = fetchurl {
      url = "${base}/NY.dmg";
      hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "apple-fonts";
  version = "2026-08-30";

  dontUnpack = true;
  nativeBuildInputs = [ _7zz ];

  # Each DMG holds an installer .pkg (xar); its Payload is a gzipped cpio.
  # 7-Zip peels every layer: dmg -> pkg -> Payload -> Payload~ -> fonts.
  buildPhase = ''
    runHook preBuild
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: src: ''
        mkdir -p ${name} && pushd ${name} >/dev/null
        7zz x -y ${src} >/dev/null
        7zz x -y ./*Fonts/*.pkg >/dev/null
        7zz x -y ./*.pkg/Payload >/dev/null
        7zz x -y Payload~ >/dev/null
        popd >/dev/null
      '') sources
    )}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/opentype
    find . -name '*.otf' -exec install -m644 -t $out/share/fonts/opentype {} +
    find . -name '*.ttf' -exec sh -c 'mkdir -p $0 && install -m644 -t $0 "$@"' $out/share/fonts/truetype {} +
    runHook postInstall
  '';

  meta = {
    description = "Apple San Francisco (SF Pro, SF Compact, SF Mono) and New York fonts";
    homepage = "https://developer.apple.com/fonts/";
    # Apple's font license: usable, not redistributable.
    license = lib.licenses.unfree;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    platforms = lib.platforms.all;
  };
}
