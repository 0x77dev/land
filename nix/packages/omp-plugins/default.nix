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
  npmDepsHash = "sha256-klWrF5y3MHfYfLeGgid3tC1hyf8TlHdVNh+n4xsg3F4=";
  npmFlags = [ "--legacy-peer-deps" ];

  dontNpmBuild = true;

  nativeBuildInputs = [ esbuild ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    esbuild langfuse-batching.test.ts \
      --bundle \
      --platform=node \
      --format=esm \
      --target=node22 \
      --outfile=$TMPDIR/langfuse-batching.test.mjs
    node --test $TMPDIR/langfuse-batching.test.mjs
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    plugin=$out/lib/omp-plugins/pi-langfuse
    source=$PWD/pi-langfuse-patched
    cp -r node_modules/pi-langfuse "$source"
    chmod -R u+w "$source"
    cp langfuse-batching.ts "$source/src/land-batching.ts"
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
