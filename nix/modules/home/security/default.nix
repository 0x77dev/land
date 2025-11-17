{
  pkgs,
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
  # Uses SSH host keys automatically - no manual key generation needed!
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
  };
}
