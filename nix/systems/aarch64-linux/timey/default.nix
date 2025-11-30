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
    inputs.nixos-raspberrypi.lib.inject-overlays
    ./raspberrypi/rpi5-base.nix
    ./raspberrypi/rpi5-page-size-16k.nix
    ./raspberrypi/usb-gadget-ethernet.nix
  ];

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
