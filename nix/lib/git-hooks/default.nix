{
  inputs,
  ...
}:
let
  hooks = {
    nixfmt-rfc-style.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    cspell.enable = true;
    markdownlint.enable = true;
    mdsh.enable = true;
    shellcheck.enable = true;
  };

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
