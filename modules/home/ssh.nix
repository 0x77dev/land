{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
  };

  home.file.".config/1Password/ssh/agent.toml".source =
    assets/1password-agent.toml;
}
