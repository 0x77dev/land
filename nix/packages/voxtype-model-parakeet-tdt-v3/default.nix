{
  fetchurl,
  lib,
  namespace,
  runCommand,
  ...
}:
lib.${namespace}.mkVoxtypeModel {
  inherit fetchurl runCommand;
  model = lib.${namespace}.voxtypeModels.parakeet-tdt-v3;
}
