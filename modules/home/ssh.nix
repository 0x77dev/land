{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "tomato" = {
        hostname = "tomato";
        user = "mykhailo";
        forwardAgent = true;
      };
      "muscle" = {
        hostname = "muscle";
        user = "mykhailo";
        forwardAgent = true;
      };
    };

    extraConfig = ''
      Host *
        SetEnv TERM=xterm-256color
    '';
  };

  home.file.".config/1Password/ssh/agent.toml".source =
    assets/1password-agent.toml;
}
