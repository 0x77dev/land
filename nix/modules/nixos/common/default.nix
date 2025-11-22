{ pkgs, lib, ... }:
{
  # Common System Configuration
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Shell
  programs.fish.enable = true;

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Common Packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    btop
    ncdu
    nettools
    bind
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings.StreamLocalBindUnlink = "yes";
  };
}
