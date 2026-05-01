{ channels, ... }:
_final: prev: {
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

  opencode = channels.unstable.opencode.overrideAttrs (
    prevAttrs:
    let
      version = "1.14.25";
      src = prev.fetchFromGitHub {
        owner = "anomalyco";
        repo = "opencode";
        tag = "v${version}";
        hash = "sha256-v1aaq4HWAJ5wZm9bUeaRkyKr0iYjdOhigr/I31wwhEk=";
      };
    in
    {
      inherit version src;

      node_modules = prevAttrs.node_modules.overrideAttrs {
        inherit version src;
        outputHash = "sha256-r0UCWhxIB4q4Te+LpXNcfexjfmI4Th2swfWOL3cUp3g=";
      };

      env = (prevAttrs.env or { }) // {
        OPENCODE_VERSION = version;
      };
    }
  );
}
