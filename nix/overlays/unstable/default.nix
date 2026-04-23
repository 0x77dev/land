{ channels, ... }:
_final: _prev: {
  inherit (channels.unstable)
    _1password-gui
    _1password-cli
    bun
    code-cursor
    code-cursor-fhs
    ghostty
    ghostty-bin
    httpie
    nodejs_24
    oha
    oxfmt
    oxlint
    tsgolint
    prek
    ssh-to-age
    zed-editor
    nixd
    talosctl
    nix-output-monitor
    wlx-overlay-s
    alvr
    monado
    cudatoolkit
    cudaPackages
    direnv
    fish
    opencode
    netdata
    ;
}
