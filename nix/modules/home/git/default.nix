{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.git;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  credentialHelper = if isDarwin then "osxkeychain" else "cache --timeout=7200";
in
{
  options.modules.home.git = {
    enable = mkEnableOption "git";
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        package = pkgs.gitFull;
        lfs.enable = true;
        signing = {
          key = "A6337A4AB36481FB18A4FCC5F1171FAAAA237211";
          signByDefault = true;
        };
        settings = {
          user = {
            name = "Mykhailo Marynenko";
            email = "mykhailo@0x77.dev";
            useConfigOnly = true;
          };
          commit.gpgsign = true;
          tag.gpgsign = true;
          push.gpgSign = "if-asked";
          gpg.program = "${pkgs.gnupg}/bin/gpg";
          gpg.format = "openpgp";
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
          credential = {
            useHttpPath = true;
            helper = credentialHelper;
          };
        };
      };

      delta = {
        enable = true;
        enableGitIntegration = true;
      };

      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
          aliases = {
            co = "pr checkout";
            pv = "pr view";
          };
        };
      };
    };

    home.packages = with pkgs; [
      git-crypt
    ];
  };
}
