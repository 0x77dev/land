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
  builders = import ./builders/default.nix { inherit lib inputs namespace; };
}
