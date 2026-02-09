{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_24,
  makeWrapper,
}:

# mcporter ships a self-contained dist-bun/ bundle in the repo
# that has all deps inlined via rolldown. No node_modules needed.
stdenv.mkDerivation {
  pname = "mcporter";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "steipete";
    repo = "mcporter";
    rev = "v0.7.3";
    hash = "sha256-x/2Ln6kohj59RSJgctWlYKckmGbWjY2ryPaLhoj0Q48=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/mcporter $out/bin
    cp -r dist-bun/* $out/lib/mcporter/
    makeWrapper ${nodejs_24}/bin/node $out/bin/mcporter \
      --add-flags "$out/lib/mcporter/cli.mjs"
  '';

  meta = {
    description = "TypeScript runtime and CLI for Model Context Protocol servers";
    homepage = "https://github.com/steipete/mcporter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "mcporter";
  };
}
