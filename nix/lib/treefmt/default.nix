{ inputs, ... }:
let
  # Shared treefmt configuration. Single source of truth consumed by
  # `nix fmt` (flake formatter), the dev shell, and the pre-commit
  # `treefmt` hook.
  module = {
    projectRootFile = "flake.nix";

    # Aligned with conform-nvim's formatters where sensible.
    programs = {
      nixfmt.enable = true; # nix (nixfmt-rfc-style)
      stylua.enable = true; # lua
      ruff-format.enable = true; # python
      prettier = {
        enable = true; # yaml, markdown
        includes = [
          "*.md"
          "*.yaml"
          "*.yml"
        ];
      };
    };

    settings.global.excludes = [
      "*.lock"
      "*.lock.nix"
      "*.age"
      "*.png"
      "*.jpg"
      "*.svg"
      "LICENSE"
      # Vendored, machine-generated NVIDIA DGX Spark kernel config (~2400
      # options). Kept byte-identical to upstream for verifiability.
      "nix/modules/nixos/hardware/dgx-spark/nvidia-dgx-spark-*.nix"
    ];
  };
in
{
  inherit module;

  # Build a treefmt evaluation for a given nixpkgs package set.
  # Use `(mkEval pkgs).config.build.wrapper` for the formatter package.
  mkEval = pkgs: inputs.treefmt-nix.lib.evalModule pkgs module;
}
