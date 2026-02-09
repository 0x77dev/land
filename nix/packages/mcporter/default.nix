{
  lib,
  stdenv,
  fetchurl,
  nodejs_24,
  makeWrapper,
}:

let
  version = "0.7.3";
in
stdenv.mkDerivation {
  pname = "mcporter";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/mcporter/-/mcporter-${version}.tgz";
    hash = "sha256-zTxBHWrceM0I8dVHWZYQaJ9fFaTD4x+B6ifaCaTZHHo=";
  };

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = ''
    mkdir -p source
    tar xzf $src --strip-components=1 -C source
  '';

  installPhase = ''
    mkdir -p $out/lib/mcporter $out/bin
    cp -r source/dist source/node_modules source/package.json $out/lib/mcporter/
    makeWrapper ${nodejs_24}/bin/node $out/bin/mcporter \
      --add-flags "$out/lib/mcporter/dist/cli.js"
  '';

  meta = {
    description = "TypeScript runtime and CLI for Model Context Protocol servers";
    homepage = "https://github.com/steipete/mcporter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "mcporter";
  };
}
