{
  inputs,
  stdenv,
  ...
}:
let
  system = stdenv.hostPlatform.system;
  upstream = inputs.voxtype.packages.${system};
in
if system != "x86_64-linux" then
  upstream.default
else
  let
    voxtypePkgs = import inputs.voxtype.inputs.nixpkgs { inherit system; };
    vulkanBuildInputs = with voxtypePkgs; [
      shaderc
      vulkan-headers
      vulkan-loader
    ];
    features = [
      # Whisper is unconditional; this selects its Vulkan backend.
      "gpu-vulkan"
      "parakeet-load-dynamic"
      "parakeet-cuda"
      "moonshine-cuda"
      "cohere-cuda"
    ];
    full = upstream.voxtype-onnx-cuda-unwrapped.overrideAttrs (old: {
      pname = "voxtype-full";
      buildFeatures = features;
      cargoBuildFeatures = features;
      cargoCheckFeatures = features;
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ vulkanBuildInputs;
      buildInputs = (old.buildInputs or [ ]) ++ vulkanBuildInputs;
      preBuild = (old.preBuild or "") + ''
        export VULKAN_SDK="${voxtypePkgs.vulkan-loader}"
        export Vulkan_INCLUDE_DIR="${voxtypePkgs.vulkan-headers}/include"
        export Vulkan_LIBRARY="${voxtypePkgs.vulkan-loader}/lib/libvulkan.so"
      '';
    });
  in
  upstream.onnx-cuda.overrideAttrs (old: {
    name = "voxtype-full-${full.version}";
    paths = [
      full
      upstream.osd-gtk4
    ];
    passthru = (old.passthru or { }) // {
      compiledFeatures = features;
      sourceRevision = inputs.voxtype.rev;
      upstreamVersion = full.version;
    };
    meta = old.meta // {
      description = "Voxtype with GPU Whisper, Parakeet, Moonshine, and Cohere";
    };
  })
