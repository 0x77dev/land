{ channels, ... }:
_final: prev:
let
  isZnver4 =
    prev.stdenv.hostPlatform.system == "x86_64-linux"
    && (prev.stdenv.hostPlatform.gcc.arch or null) == "znver4";
  unstable =
    if isZnver4 && prev ? landNativeChannels then
      prev.landNativeChannels.unstable
    else
      channels.unstable;

  # Muscle's package set is marked znver4 by its custom system builder. Its two
  # RTX 6000 Ada GPUs are both sm_89, so use nixpkgs' single-architecture CUDA
  # variant there; other hosts retain the broad, cache-friendly package set.
  cudaPackageSet =
    if isZnver4 then unstable.pkgsForCudaArch.sm_89.cudaPackages_12_9 else unstable.cudaPackages_12_9;
in
{
  inherit (unstable)
    bun
    code-cursor
    code-cursor-fhs
    ghostty
    ghostty-bin
    # Keep Muscle's gaming compositor, HDR WSI layer, Vulkan diagnostics, and
    # performance overlay on the latest compatible patch releases.
    gamescope
    gamescope-wsi
    mangohud
    vulkan-tools
    httpie
    nodejs_24
    oha
    oxfmt
    oxlint
    tsgolint
    prek
    nixd
    talosctl
    nix-output-monitor
    ollama
    wlx-overlay-s
    alvr
    monado
    # NVIDIA userspace tooling (driver kernel modules stay matched to each
    # host's kernel — see the host configs).
    nvtopPackages
    nvidia-container-toolkit
    fish
    netdata
    _1password-gui
    _1password-cli
    ;

  # Single source of truth for the CUDA toolkit version across every host.
  # Pinned to 12.9 (from unstable): first release to add the GB10 `sm_121`
  # target (12.8 only added consumer Blackwell `sm_120`), while staying on the
  # 12.x line for broad ecosystem compatibility (PyTorch/JAX cu12x) over the
  # bleeding-edge 13.x sets. `pkgs.cudatoolkit` and `pkgs.cudaPackages` both
  # resolve here, keeping muscle and spark on the same toolkit version while
  # allowing Muscle's device code to target only Ada sm_89.
  cudaPackages = cudaPackageSet;
  inherit (cudaPackageSet) cudatoolkit;
}
