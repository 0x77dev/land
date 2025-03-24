# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{ config
, pkgs
, inputs
, ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.nixos-vscode-server.nixosModules.default
    ../../../modules/nixos/vscode-server.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "muscle"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # User permissions
      trusted-users = [ "root" "mykhailo" ];
      trusted-substituters = [ "root" "mykhailo" ];

      # Binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://land.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA="
      ];

      # Build optimization
      max-jobs = "auto";
      cores = 0; # Use all available cores
      system-features = [ "big-parallel" "benchmark" "kvm" "nixos-test" ];
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true; # Allow builders to use substitutes
      connect-timeout = 5; # Reduce connection timeout
      download-speed = 0; # No limit on download speed
      narinfo-cache-negative-ttl = 0; # Don't cache negative lookups
    };

    # Garbage collection
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };

    # Store optimization
    optimise = {
      automatic = true;
    };
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Disable suspend/sleep
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable VS Code Server with optimal settings
  modules.vscode-server.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [ "wheel" "networkmanager" "docker" "dialout" "libvirtd" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = builtins.fromJSON (builtins.readFile ../../../helpers/openssh-authorized-keys.json);
  };

  # Install chromium.
  programs.chromium.enable = true;

  # virt-manager
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "mykhailo" ];
  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  # fish
  programs.fish.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnupg
    vim
    chromium
    fish
    cudaPackages.cudnn
    cudaPackages.cudatoolkit
    btop
    mangohud
    protonup
    lutris
    yubikey-personalization
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  programs.ssh.startAgent = false;
  services.pcscd.enable = true;
  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "mykhailo" ];
  };

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    daemon.settings = {
      data-root = "/data/docker";
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
