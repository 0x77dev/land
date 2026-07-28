{ pkgs }:
pkgs.llm-agents.pi.overrideAttrs (oldAttrs: {
  pname = "pi-node";

  # The upstream llm-agents package compiles Pi into a Bun executable. Bun's
  # compiled-binary resolver cannot reliably load transitive dependencies from
  # external extensions. Run the published Node entry point instead so normal
  # node_modules resolution remains available.
  dontNpmBuild = true;

  postInstall = ''
    pkgdir=$out/libexec/pi

    rm -rf "$out/lib" "$out/bin"
    mkdir -p "$out/bin" "$pkgdir"
    cp -r dist docs examples node_modules package.json README.md CHANGELOG.md "$pkgdir/"

    makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/pi" \
      --add-flags "$pkgdir/dist/cli.js" \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.fd
          pkgs.ripgrep
        ]
      } \
      --set PI_PACKAGE_DIR "$pkgdir" \
      --set PI_SKIP_VERSION_CHECK 1 \
      --set PI_TELEMETRY 0
  '';

  meta = oldAttrs.meta // {
    description = "Pi coding agent using the Node entry point for extension compatibility";
  };
})
