{
  lib,
  inputs,
  system,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.git-hooks.mkRun {
  inherit system pkgs;
  src = inputs.self;
}
