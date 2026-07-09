{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
  ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "apple-color-emoji";
  version = "macos-26-20260613-f1fc560b";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${version}/AppleColorEmoji-Linux.ttf";
    hash = "sha256-uMjtl/ZCuJuko2o+CWYZ8IBdBswlrhEW5pU7mBQq4gw=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
    runHook postInstall
  '';

  meta = {
    description = "Apple Color Emoji font (CBDT build for Linux)";
    homepage = "https://github.com/samuelngs/apple-emoji-ttf";
    # Apple's emoji artwork is proprietary; personal use only.
    license = lib.licenses.unfree;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    platforms = lib.platforms.all;
  };
}
