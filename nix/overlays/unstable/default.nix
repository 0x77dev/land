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
    cudatoolkit
    cudaPackages
    fish
    netdata
    ;
}
