{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.elgato-light-control;
in
{
  options.modules.elgato-light-control.enable = lib.mkEnableOption "mDNS discovery for local Elgato light control";

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
