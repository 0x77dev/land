{
  lib,
  writeShellScriptBin,
  bun,
}:

writeShellScriptBin "mcporter" ''
  exec ${bun}/bin/bunx --bun mcporter@0.7.3 "$@"
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
