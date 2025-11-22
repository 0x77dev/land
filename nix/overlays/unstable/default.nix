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
    aichat
    zed-editor
    nixd
    ;

  # Override opencode to remove Darwin badPlatforms restriction
  opencode = channels.unstable.opencode.overrideAttrs (old: {
    meta = old.meta // {
      badPlatforms = [ ];
    };
  });
}
