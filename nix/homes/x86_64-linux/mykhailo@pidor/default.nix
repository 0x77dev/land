{
  lib,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  programs.home-manager.enable = true;

  inherit (shared) home;

  modules.home = shared.modules.home // {
    secrets.backend = "age";
    openclaw.enable = true;
    cloud.enable = true;
    git.enable = true;
    media.enable = true;
    network.enable = true;
    nix.enable = true;
    p2p.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg.enable = true;
    security-tools.enable = true;
  };
}
