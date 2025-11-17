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
}
