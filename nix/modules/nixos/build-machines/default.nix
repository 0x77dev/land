{
  lib,
  namespace,
  config,
  ...
}:
let
  buildersLib = lib.${namespace}.builders;
  hostName = config.networking.hostName or null;
  sshUser =
    if config ? snowfallorg && config.snowfallorg ? user && config.snowfallorg.user ? name then
      config.snowfallorg.user.name
    else if config ? snowfallorg && config.snowfallorg ? users && config.snowfallorg.users != { } then
      lib.head (lib.attrNames config.snowfallorg.users)
    else
      "root";

  machines = buildersLib.mkDefaultBuildMachines { inherit hostName sshUser; };
in
if machines == [ ] then
  { }
else
  {
    nix.buildMachines = lib.mkDefault machines;
  }
