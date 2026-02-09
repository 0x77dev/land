{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
}:

buildNpmPackage rec {
  pname = "mcporter";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "steipete";
    repo = "mcporter";
    rev = "v${version}";
    hash = "sha256-x/2Ln6kohj59RSJgctWlYKckmGbWjY2ryPaLhoj0Q48=";
  };

  npmDepsHash = lib.fakeHash;

  nodejs = nodejs_24;

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  meta = {
    description = "TypeScript runtime and CLI for Model Context Protocol servers";
    homepage = "https://github.com/steipete/mcporter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "mcporter";
  };
}
