{ channels, ... }:
final: prev:
let
  isZnver4 =
    prev.stdenv.hostPlatform.system == "x86_64-linux"
    && (prev.stdenv.hostPlatform.gcc.arch or null) == "znver4";
  unstable =
    if isZnver4 && prev ? landNativeChannels then
      prev.landNativeChannels.unstable
    else
      channels.unstable;

  # Mirror nixpkgs' selectable acceleration variants while preserving this
  # overlay's stable package names. Muscle's znver4 package set also selects the
  # sm_89 package variant so Ollama embeds only native RTX 6000 Ada device code.
  # (`ignoreCollisions = true` is obsolete: upstream now sets it on the CUDA
  # package set's `cudaToolkit` buildEnv itself.)
  ollamaBase = if isZnver4 then unstable.pkgsForCudaArch.sm_89.ollama else unstable.ollama;
  mkOllama = acceleration: ollamaBase.override { inherit acceleration; };

  # Qwen3.6 can emit malformed/empty tool-call envelopes that make Ollama 0.24
  # return HTTP 500s (ollama/ollama#16383). Carry the unmerged parser fix once
  # in the CUDA package used by Spark and Muscle; pure Go patch, no vendor hash
  # change. Drop when the pinned channel contains ollama/ollama#16398.
  withQwen36ToolParserFix =
    pkg:
    pkg.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (final.fetchpatch {
          name = "ollama-qwen36-tolerate-tool-template-drift.patch";
          url = "https://github.com/ollama/ollama/commit/beed6703d8fe3795049db45863458785774ef396.patch";
          hash = "sha256-xh59I8WNHjkH2Rx1jsGl+8anjvGA/294yz5Z3dV87QY=";
        })
        (final.fetchpatch {
          name = "ollama-qwen36-skip-empty-tool-call-envelopes.patch";
          url = "https://github.com/ollama/ollama/commit/769dcb5eb7bc8707aabf5de611a1dcb05ffa3ab5.patch";
          hash = "sha256-kRSPiX+wJfv7HOKhaxP50ZHUdPIOhXbjdKp/0L8AYOU=";
        })
      ];
    });
in
{
  ollama = mkOllama null;
  ollama-cpu = mkOllama false;
  ollama-cuda = withQwen36ToolParserFix (mkOllama "cuda");
  ollama-rocm = mkOllama "rocm";
  ollama-vulkan = mkOllama "vulkan";
}
