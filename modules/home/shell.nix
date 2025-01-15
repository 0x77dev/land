{ pkgs, ... }:

let
  commonAliases = {
    aria2p = "aria2p -s aria2";
    pbdownload = ''aria2p -s aria2 add "$(pbpaste)"'';
  };

  commonAbbrs = {
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
  };

  commonPaths = [
    "$HOME/go/bin"
    "$HOME/.bun/bin"
    "$HOME/.local/bin"
    "/opt/homebrew/bin"
    "/run/current-system/sw/bin"
    "/run/wrappers/bin"
  ];

  commonFunctions = ''
    secret () {
      output=~/"$1".$(date +%s).enc
      gpg --encrypt --armor --output $output \
        -r $KEYID "$1" && echo "$1 -> $output"
    }

    reveal () {
      output=$(echo "$1" | rev | cut -c16- | rev)
      gpg --decrypt --output $output "$1" && \
        echo "$1 -> $output"
    }
  '';
in
{
  home.packages = with pkgs; [
    fzf
    btop
    bat
    fd
    zoxide
    starship
    devenv
    direnv
  ];

  programs.bash = {
    enable = true;
    shellAliases = commonAliases // commonAbbrs;
    initExtra = ''
      ${commonFunctions}
      export PATH="${builtins.concatStringsSep ":" commonPaths}:$PATH"
    '';
  };

  programs.zsh = {
    enable = true;
    shellAliases = commonAliases // commonAbbrs;
    initExtra = ''
      ${commonFunctions}
      export PATH="${builtins.concatStringsSep ":" commonPaths}:$PATH"
    '';
  };

  programs.fish = {
    enable = true;
    shellAliases = commonAliases;
    shellAbbrs = commonAbbrs;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      # Add all common paths
      ${builtins.concatStringsSep "\n"
      (map (p: "fish_add_path -m ${p}") commonPaths)}

      if command -v conda >/dev/null 2>&1
        eval "$(conda "shell.fish" hook)"
      end

      function secret
        set output ~/$argv[1].(date +%s).enc
        gpg --encrypt --armor --output $output \
          -r $KEYID $argv[1] && echo "$argv[1] -> $output"
      end

      function reveal
        set output (echo $argv[1] | rev | cut -c16- | rev)
        gpg --decrypt --output $output $argv[1] && \
          echo "$argv[1] -> $output"
      end
    '';
    plugins = [
      {
        name = "git-abbr";
        src = pkgs.fishPlugins.git-abbr.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "fifc";
        src = pkgs.fishPlugins.fifc.src;
      }
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
