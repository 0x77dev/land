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
    backend = mkOption {
      type = types.enum [
        "disabled"
        "age"
        "gpg"
      ];
      default = "disabled";
      description = ''
        Secret management backend to use.
        - "disabled": No secret management (default)
        - "age": Use age encryption (generates key automatically)
        - "gpg": Use GPG encryption (uses existing GPG keys)
      '';
    };
  };

  config = mkIf (cfg.backend != "disabled") (mkMerge [
    # Common configuration for both backends
    {
      sops = {
        defaultSopsFile = ./secrets.yaml;

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

      home.packages = with pkgs; [ sops ];
    }

    # Age-specific configuration
    (mkIf (cfg.backend == "age") {
      sops = {
        # Use age key file for home-manager
        # SSH host keys require root access which home-manager doesn't have
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        # Automatically generate the age key if it doesn't exist
        age.generateKey = true;
      };

      home.packages = with pkgs; [ age ];
    })

    # GPG-specific configuration
    (mkIf (cfg.backend == "gpg") {
      sops = {
        gnupg.home = "${config.home.homeDirectory}/.gnupg";
        gnupg.sshKeyPaths = [ ]; # Don't try to use SSH keys
      };

      home.packages = with pkgs; [ gnupg ];
    })
  ]);
}
