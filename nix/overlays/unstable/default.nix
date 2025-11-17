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
    prek
    ssh-to-age
    ;
}
