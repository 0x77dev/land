{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.secrets;

  # Generate export commands for all secrets dynamically
  exportAllSecrets =
    shellType:
    let
      secretNames = lib.attrNames config.sops.secrets;

      mkExport =
        if shellType == "fish" then
          (name: ''
            test -f "${config.sops.secrets.${name}.path}"; and set -gx ${name} (cat "${
              config.sops.secrets.${name}.path
            }")
          '')
        else
          (name: ''
            [ -f "${config.sops.secrets.${name}.path}" ] && export ${name}="$(cat "${
              config.sops.secrets.${name}.path
            }")"
          '');
    in
    lib.concatMapStringsSep "\n" mkExport secretNames;

in
{
  options.modules.home.secrets = {
    enable = mkEnableOption "secrets";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets.yaml;

      gnupg.home = "${config.home.homeDirectory}/.gnupg";

      secrets = {
        OSV_API_KEY = { };
        OSV_INFERENCE_ENDPOINT = { };
        OC_GOOGLE_CLOUD_PROJECT = { };
        OC_VERTEX_LOCATION = { };
      };
    };

    programs = {
      bash.initExtra = lib.mkAfter ''
        # Load sops-nix secrets
        ${exportAllSecrets "bash"}
      '';

      zsh.initContent = lib.mkAfter ''
        # Load sops-nix secrets
        ${exportAllSecrets "zsh"}
      '';

      fish.interactiveShellInit = lib.mkAfter ''
        # Load sops-nix secrets
        ${exportAllSecrets "fish"}
      '';
    };

    home.packages = with pkgs; [
      sops
      gnupg
    ];
  };
}
