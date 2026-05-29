{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];

  modules.installer.enable = true;

  system.stateVersion = "25.11";
}
