{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    optional
    unique
    ;

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  commonPaths = unique (
    [
      "$HOME/go/bin"
      "$HOME/.bun/bin"
      "$HOME/.local/bin"
      "/run/current-system/sw/bin"
      "/run/wrappers/bin"
    ]
    ++ optional isDarwin "/opt/homebrew/bin"
  );

  exportedPath = concatStringsSep ":" commonPaths;

  commonAliases = {
    cd = "z";
    cdi = "zi";
  };

  commonAbbreviations = {
    g = "git";
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gst = "git status";
    gd = "git diff";
    gds = "git diff --staged";
    gf = "git fetch";
    gpl = "git pull";
    gps = "git push";
    tf = "terraform";
    of = "tofu";
    ai = "aichat";
    aie = "aichat -e";
  };
in
{
  home.sessionVariables.KEYID =
    config.programs.gpg.settings.default-key or "C33BFD3230B660CF147762D2BF5C81B531164955";

  home.packages = with pkgs; [
    aichat
    bat
    bun
    cachix
    devenv
    direnv
    fd
    figlet
    fzf
    glow
    nix-output-monitor
    starship
    yazi
    zoxide
    btop
  ];

  programs = {
    bash = {
      enable = true;
      shellAliases = commonAliases // commonAbbreviations;
      initExtra = ''
        export PATH="${exportedPath}:$PATH"
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
      '';
    };

    zsh = {
      enable = true;
      shellAliases = commonAliases // commonAbbreviations;
      initExtra = ''
        export PATH="${exportedPath}:$PATH"
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      '';
    };

    fish = {
      enable = true;
      shellAliases = commonAliases;
      shellAbbrs = commonAbbreviations;
      interactiveShellInit = ''
        set fish_greeting
        ${concatMapStringsSep "\n" (p: "fish_add_path -m ${p}") commonPaths}
        ${pkgs.zoxide}/bin/zoxide init fish | source
        if command -v conda >/dev/null 2>&1
          eval "$(conda \"shell.fish\" hook)"
        end
      '';
      plugins = [
        {
          inherit (pkgs.fishPlugins.git-abbr) src;
          name = "git-abbr";
        }
        {
          inherit (pkgs.fishPlugins.autopair) src;
          name = "autopair";
        }
        {
          inherit (pkgs.fishPlugins.fifc) src;
          name = "fifc";
        }
        {
          inherit (pkgs.fishPlugins.bass) src;
          name = "bass";
        }
        {
          inherit (pkgs.fishPlugins.z) src;
          name = "z";
        }
      ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
  };
}
