{
  lib,
  pkgs,
  config,
  ...
}:
let
  userName = "0x77";
in
{
  system.stateVersion = "25.05";
  networking.hostName = lib.mkDefault "muscle-wsl";

  wsl = {
    enable = true;
    defaultUser = userName;
    interop.register = true;

    wslConf = {
      automount.root = "/mnt";
      network.hostname = "muscle-wsl";
    };
  };

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";

    LD_LIBRARY_PATH = lib.concatStringsSep ":" [
      "/usr/lib/wsl/lib"
      "${pkgs.linuxPackages.nvidia_x11}/lib"
      "${pkgs.ncurses5}/lib"
    ];

    MESA_D3D12_DEFAULT_ADAPTER_NAME = "NVIDIA";
  };

  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = false;
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;

    daemon.settings = {
      features.cdi = true;
      cdi-spec-dirs = [ "/etc/cdi" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /etc/cdi 0755 root root"
  ];

  systemd.services.nvidia-cdi-generator = {
    description = "Generate NVIDIA CDI specification for containers";
    wantedBy = [ "docker.service" ];
    after = [ "docker.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nvidia-docker}/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --nvidia-ctk-path=${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk";
    };
  };

  snowfallorg.users.${userName} = {
    create = true;
    admin = true;

    home = {
      enable = true;
      path = "/home/${userName}";
      config = { };
    };
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    cudatoolkit
    nvidia-docker
    nvidia-container-toolkit
    docker
    docker-compose
    git
    vim
    wget
    curl
    htop
    ncdu
    nettools
    bind
  ];

  services = {
    xserver.videoDrivers = [ "nvidia" ];
    openssh = {
      enable = true;
      settings.StreamLocalBindUnlink = "yes";
    };
    pcscd.enable = true;
    verified-auto-update.enable = true;
  };

  programs.fish.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      11434
      8080
      8888
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
