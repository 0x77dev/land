_: _final: prev:
let
  # Build each acceleration variant by overriding the upstream package's
  # `acceleration` argument. (The previous string-patch that injected
  # `ignoreCollisions = true` is obsolete: upstream now sets it on the
  # `cudaToolkit` buildEnv itself.)
  mkOllama = acceleration: prev.ollama.override { inherit acceleration; };
in
{
  ollama = mkOllama null;
  ollama-cpu = mkOllama false;
  ollama-cuda = mkOllama "cuda";
  ollama-rocm = mkOllama "rocm";
  ollama-vulkan = mkOllama "vulkan";
}
