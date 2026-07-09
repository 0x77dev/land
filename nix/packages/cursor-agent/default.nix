{
  autoPatchelfHook,
  fetchurl,
  lib,
  namespace,
  stdenv,
  zlib,
  ...
}:

stdenv.mkDerivation rec {
  pname = "cursor-agent";
  version = "2026.06.12-01-15-52-7244546";

  src = fetchurl {
    url = "https://downloads.cursor.com/lab/${version}/linux/arm64/agent-cli-package.tar.gz";
    hash = "sha256-nLb1s2WLGAkpZpN1dLeQhAk7dkj1To3ShKvU78Rf0ik=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  sourceRoot = "dist-package";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/cursor-agent" "$out/bin"
    cp -R . "$out/libexec/cursor-agent/"

    ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/cursor-agent"
    ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/agent"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cursor Agent CLI";
    homepage = "https://cursor.com/cli";
    license = licenses.unfree;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "cursor-agent";
    platforms = [ "aarch64-linux" ];
  };
}
