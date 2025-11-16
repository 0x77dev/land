{
  lib,
  inputs,
  system,
  namespace,
  ...
}:
lib.${namespace}.git-hooks.mkRun {
  inherit system;
  src = inputs.self;
}
