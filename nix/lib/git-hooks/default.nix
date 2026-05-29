{
  lib,
  inputs,
  namespace,
  ...
}:
let
  common = {
    excludes = [
      ".*\\.lock\\.nix$"
      ".*\\.lock$"
      "peering/*.json$"
      # Vendored upstream artifacts: machine-generated kernel config and
      # patches. Excluded from linters/spell-check, as upstream does.
      "nix/modules/nixos/hardware/dgx-spark/nvidia-dgx-spark-.*\\.nix$"
      ".*\\.patch$"
    ];
  };

  # Linters and checkers. Formatting is delegated to the shared treefmt
  # config (single source of truth), wired in as the `treefmt` hook below.
  baseConfig = {
    deadnix.enable = true;
    statix.enable = true;
    cspell.enable = true;
    markdownlint.enable = true;
    mdsh.enable = true;
    shellcheck.enable = true;
    actionlint.enable = true;
    editorconfig-checker.enable = true;
  };

  mkHooks =
    pkgs:
    let
      treefmtWrapper = (lib.${namespace}.treefmt.mkEval pkgs).config.build.wrapper;

      config = baseConfig // {
        treefmt = {
          enable = true;
          packageOverrides.treefmt = treefmtWrapper;
        };
      };
    in
    builtins.mapAttrs (
      _name: value:
      if builtins.isAttrs value then
        common // value // { excludes = (common.excludes or [ ]) ++ (value.excludes or [ ]); }
      else
        common // { enable = value; }
    ) config;

  mkRun =
    {
      system,
      src,
      pkgs,
    }:
    inputs.git-hooks.lib.${system}.run {
      hooks = mkHooks pkgs;
      inherit src;
      package = pkgs.prek;
    };
in
{
  inherit mkRun;
}
