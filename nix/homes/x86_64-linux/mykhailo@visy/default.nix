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

  # Minimal home config: shell, git, ssh, gpg, nix tools - NO secrets
  modules.home = shared.modules.home // {
    secrets.backend = "disabled"; # No personal secrets
    git.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg.enable = true;
    nix.enable = true;
  };
}
