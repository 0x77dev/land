{ channels, ... }:
_final: _prev: {
  inherit (channels.unstable)
    bun
    code-cursor
    code-cursor-fhs
    ghostty
    ghostty-bin
    httpie
    nodejs_24
    oha
    opencode
    oxfmt
    oxlint
    tsgolint
    prek
    nixd
    talosctl
    nix-output-monitor
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
  # bleeding-edge 13.x sets. This is also the current unstable default, so it
  # maximizes binary-cache hits. `pkgs.cudatoolkit` and `pkgs.cudaPackages`
  # both resolve here, keeping muscle and spark on the same version.
  cudaPackages = channels.unstable.cudaPackages_12_9;
  cudatoolkit = channels.unstable.cudaPackages_12_9.cudatoolkit;
}
