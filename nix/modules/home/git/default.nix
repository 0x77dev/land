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
  # Single identity source shared with everything else that names Mykhailo.
  maintainer = lib.land.maintainers.mykhailo;
in
{
  options.modules.home.git = {
    enable = mkEnableOption "git";

    signing = mkOption {
      type = types.bool;
      default = true;
      description = "Sign commits and tags with the YubiKey-backed key.";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        package = pkgs.gitFull;
        lfs.enable = true;
        signing = mkIf cfg.signing {
          key = maintainer.gpgKey;
          signByDefault = true;
        };
        settings = {
          user = {
            inherit (maintainer) name email;
            useConfigOnly = true;
          };
          commit.gpgsign = cfg.signing;
          tag.gpgsign = cfg.signing;
          push.gpgSign = mkIf cfg.signing "if-asked";
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

      # Same identity and YubiKey-backed key as git. Signing happens at push
      # time (sign-on-push), not on every rewrite: jj rewrites commits
      # constantly and a hardware prompt per rewrite would be unusable.
      jujutsu = {
        enable = true;
        settings = {
          user = {
            inherit (maintainer) name email;
          };
          signing = mkIf cfg.signing {
            behavior = "drop";
            backend = "gpg";
            key = maintainer.gpgKey;
            backends.gpg.program = "${pkgs.gnupg}/bin/gpg";
          };
          git.sign-on-push = cfg.signing;
          ui.default-command = "log";
        };
      };
    };

    home.packages = with pkgs; [
      git-crypt
    ];
  };
}
