{
  lib,
  writeShellScriptBin,
  nodejs_24,
}:

# mcporter via npx -- avoids complex pnpm build packaging.
# npx caches the package after first run.
writeShellScriptBin "mcporter" ''
  exec ${nodejs_24}/bin/npx --yes mcporter@0.7.3 "$@"
''
// {
  meta = {
    description = "TypeScript runtime and CLI for Model Context Protocol servers";
    homepage = "https://github.com/steipete/mcporter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "mcporter";
  };
}
