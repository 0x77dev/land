{ pkgs, ... }: {
  environment = {
    systemPackages = [
      pkgs.wget
      pkgs.curl
      pkgs.git
      pkgs.nix-ld
      pkgs.cudatoolkit
      pkgs.linuxPackages.nvidia_x11
      pkgs.libGLU
      pkgs.libGL
      pkgs.xorg.libXi
      pkgs.xorg.libXmu
      pkgs.freeglut
      pkgs.xorg.libXext
      pkgs.xorg.libX11
      pkgs.xorg.libXv
      pkgs.xorg.libXrandr
      pkgs.zlib
      pkgs.ncurses5
      pkgs.binutils
      pkgs.fish
    ];

    variables = {
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib";
      CUDA_PATH = "${pkgs.cudatoolkit}";
      EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
      EXTRA_CCFLAGS = "-I/usr/include";
    };
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };

  vscode-remote-workaround.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

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
      system-features = [ "big-parallel" "benchmark" ];
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

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = builtins.fromJSON (builtins.readFile ../../../helpers/openssh-authorized-keys.json);
  };
}
