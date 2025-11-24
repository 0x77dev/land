{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  programs.home-manager.enable = true;

  home = shared.home // {
    file.".local/share/monado/hand-tracking-models".source = pkgs.fetchgit {
      url = "https://gitlab.freedesktop.org/monado/utilities/hand-tracking-models";
      sha256 = "sha256-x/X4HyyHdQUxn3CdMbWj5cfLvV7UyQe1D01H93UCk+M=";
      fetchLFS = true;
    };
  };

  modules.home = shared.modules.home // {
    secrets.backend = "gpg";
    ai.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    network.enable = true;
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg.enable = true;
  };

  # OpenXR discovery
  xdg.configFile."openxr/1/active_runtime.json".source =
    "${pkgs.monado}/share/openxr/1/openxr_monado.json";

  xdg.configFile."openvr/openvrpaths.vrpath".text = builtins.toJSON {
    config = [ "${config.xdg.dataHome}/Steam/config" ];
    external_drivers = null;
    jsonid = "vrpathreg";
    log = [ "${config.xdg.dataHome}/Steam/logs" ];
    runtime = [ "${pkgs.opencomposite}/lib/opencomposite" ];
    version = 1;
  };

}
