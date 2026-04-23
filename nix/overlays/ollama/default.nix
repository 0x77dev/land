{ inputs, ... }:
final: _prev:
let
  patchedOllamaPackage = builtins.toFile "ollama-package.nix" (
    builtins.replaceStrings
      [ "cudaToolkit = buildEnv {" ]
      [
        ''
          cudaToolkit = buildEnv {
            ignoreCollisions = true;''
      ]
      (builtins.readFile "${inputs.nixpkgs.outPath}/pkgs/by-name/ol/ollama/package.nix")
  );

  mkOllama = acceleration: final.callPackage patchedOllamaPackage { inherit acceleration; };
in
{
  ollama = mkOllama null;
  ollama-cpu = mkOllama false;
  ollama-cuda = mkOllama "cuda";
  ollama-rocm = mkOllama "rocm";
  ollama-vulkan = mkOllama "vulkan";
}
