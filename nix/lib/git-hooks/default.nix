{
  inputs,
  ...
}:
let
  common = {
    excludes = [
      ".*\\.lock\\.nix$"
      ".*\\.lock$"
      "secrets.*\.(yaml|json|env|ini)$"
      ".sops.yaml$"
      "peering/*.json$"
    ];
  };

  config = {
    nixfmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    cspell.enable = true;
    markdownlint.enable = true;
    mdsh.enable = true;
    shellcheck.enable = true;
    actionlint.enable = true;
    editorconfig-checker.enable = true;
  };

  hooks = builtins.mapAttrs (
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
      inherit hooks src;
      package = pkgs.prek;
    };
in
{
  inherit hooks mkRun;
}
