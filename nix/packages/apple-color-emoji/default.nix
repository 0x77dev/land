{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
  ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "apple-color-emoji";
  version = "macos-26-20260722-484daf4e";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${version}/AppleColorEmoji-Linux.ttf";
    hash = "sha256-43x69iZaxKCvbVe8ZehhCad22ZZug0MzRVf2PaSCUW8=";
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
