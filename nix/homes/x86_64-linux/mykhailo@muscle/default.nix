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
    secrets.backend = "disabled";
    ai.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    network.enable = true;
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg.enable = true;
  };
}
