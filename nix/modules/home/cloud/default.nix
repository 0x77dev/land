{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.cloud;
in
{
  options.modules.home.cloud = {
    enable = mkEnableOption "cloud";
  };

  config = mkIf cfg.enable {
    programs.awscli = {
      enable = true;
    };

    home.packages = with pkgs; [
      google-cloud-sdk
      minio-client
    ];
  };
}
