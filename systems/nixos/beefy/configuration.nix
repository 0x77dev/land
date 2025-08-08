{ inputs, config, pkgs, lib, ... }:
{
  imports = [
    # Apple Silicon module is added via flake.nix; do not import here
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  nixpkgs.config.allowUnfree = true;

  # Hostname and networking
  networking.hostName = "beefy";

  # Bootloader per Asahi guidance
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Enable x86_64 emulation and cross builds
  nix.settings = {
    extra-substituters = "https://cache.lix.systems";
    extra-trusted-public-keys = "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=";
    experimental-features = [ "nix-command" "flakes" ];
    extra-platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Display and desktop
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Wi-Fi via iwd
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  # Optional: Asahi GPU/audio setup
  hardware.asahi = {
    useExperimentalGPUDriver = lib.mkDefault true;
    experimentalGPUInstallMode = lib.mkDefault "replace";
    setupAsahiSound = lib.mkDefault true;
    firmwareDirectory = lib.mkDefault "/boot/asahi";
  };

  # Base packages
  environment.systemPackages = with pkgs; [ vim wget git ];

  # Useful tools
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # User account
  users.users = {
    mykhailo = {
      isNormalUser = true;
      initialPassword = "roflcopter";
      createHome = true;
      extraGroups = [ "wheel" ];
    };
  };

  # Firewall
  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}


