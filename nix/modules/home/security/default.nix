{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    _1password-gui
    _1password-cli
    yubikey-personalization
    yubikey-manager
    sops
    age
    ssh-to-age
  ];

  # Configure sops-nix for home-manager
  sops = {
    # Use age with GPG key
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Default sops file (can be overridden per-secret)
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
  };
}
