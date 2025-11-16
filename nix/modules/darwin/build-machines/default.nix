{
  lib,
  namespace,
  config,
  ...
}:
let
  buildersLib = lib.${namespace}.builders;
  hostName = config.networking.hostName or null;
  sshUser = config.snowfallorg.user.name or "builder";

  machines = buildersLib.mkDefaultBuildMachines { inherit hostName sshUser; };
in
if machines == [ ] then
  { }
else
  {
    nix.buildMachines = lib.mkDefault machines;
  }
