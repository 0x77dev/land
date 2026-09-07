{
  buildNpmPackage,
  esbuild,
  pkgs,
}:
buildNpmPackage {
  pname = "omp-langfuse";
  version = "1.1.0";

  src = ./.;
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-dWaflTdCUzkHjRQfbYMClMfbjO1k5FqxuGMMv75Zc9Y=";
  npmFlags = [ "--legacy-peer-deps" ];

  dontNpmBuild = true;

  nativeBuildInputs = [ esbuild ];

  installPhase = ''
    runHook preInstall

    plugin=$out/lib/omp-plugins/pi-langfuse
    source=$PWD/pi-langfuse-patched
    cp -r node_modules/pi-langfuse "$source"
    chmod -R u+w "$source"
    patch -d "$source" -p1 < pi-langfuse-batching.patch

    mkdir -p "$plugin"
    esbuild "$source/index.ts" \
      --bundle \
      --platform=node \
      --format=esm \
      --target=node22 \
      --outfile="$plugin/index.js"
    cat > "$plugin/package.json" <<'EOF'
    {
      "name": "land-omp-langfuse",
      "private": true,
      "type": "module",
      "omp": {
        "extensions": ["./index.js"]
      },
      "pi": {
        "extensions": ["./index.js"]
      }
    }
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Bundled, size-bounded pi-langfuse extension for Pi and Oh My Pi";
    inherit (pkgs.llm-agents.omp.meta) platforms;
  };
}
