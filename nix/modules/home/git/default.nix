{
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  credentialHelper = if isDarwin then "osxkeychain" else "cache --timeout=7200";
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    delta.enable = true;
    lfs.enable = true;
    signing = {
      key = "C33BFD3230B660CF147762D2BF5C81B531164955";
      signByDefault = true;
    };
    userName = "Mykhailo Marynenko";
    userEmail = "mykhailo@0x77.dev";
    extraConfig = {
      commit.gpgsign = true;
      tag.gpgsign = true;
      push.gpgSign = "if-asked";
      gpg.program = "${pkgs.gnupg}/bin/gpg";
      gpg.format = "openpgp";
      user.useConfigOnly = true;
      init.defaultBranch = "main";
      protocol.version = 2;
      diff.algorithm = "histogram";
      fetch = {
        prune = true;
        pruneTags = true;
        writeCommitGraph = true;
        fsckObjects = true;
        parallel = 4;
      };
      transfer.fsckObjects = true;
      receive.fsckObjects = true;
      gc = {
        writeCommitGraph = true;
        auto = 256;
      };
      maintenance = {
        auto = 256;
        strategy = "incremental";
      };
      rebase.autoStash = true;
      pull = {
        rebase = true;
        ff = "only";
      };
      core = {
        untrackedCache = true;
        compression = 2;
      };
      index.threads = 0;
      credential.useHttpPath = true;
    }
    // {
      credential.helper = credentialHelper;
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "code --wait";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
