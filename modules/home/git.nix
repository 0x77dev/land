{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    delta = { enable = true; };
    lfs = { enable = true; };
    signing = {
      key = "C33BFD3230B660CF147762D2BF5C81B531164955";
      signByDefault = true;
    };
    userName = "Mykhailo Marynenko";
    userEmail = "mykhailo@0x77.dev";
  };

  programs.gh.enable = true;
  programs.gh.settings = {
    git_protocol = "ssh";
    editor = "code --wait";

    prompt = "enabled";

    aliases = {
      co = "pr checkout";
      pv = "pr view";
    };
  };
}
