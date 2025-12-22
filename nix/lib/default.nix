{
  lib,
  inputs,
  namespace,
  ...
}:
{
  maintainers = import ./maintainers { };
  shared = import ./shared { inherit lib inputs namespace; };
  git-hooks = import ./git-hooks/default.nix { inherit lib inputs namespace; };
  deployment = import ./deployment/default.nix { inherit lib inputs namespace; };
}
