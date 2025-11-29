{
  pkgs,
  inputs,
  # lib,
  # modulesPath,
  ...
}:
{
  imports = [
    ./disko-config.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];

  # Bootloader configuration
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
    efi.canTouchEfiVariables = false;
  };

  modules = {
    observability.enable = true;
  };

  networking = {
    hostName = "timey";
    domain = "0x77.computer";
    hostId = "e205c0de";
    useDHCP = true;
  };

  security.sudo.wheelNeedsPassword = false;

  # Users
  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home = {
      enable = true;
      config = { };
    };
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };

  # OpenSSH
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowAgentForwarding = true;
      StreamLocalBindUnlink = true;
    };
  };

  system.stateVersion = "25.05";
}
