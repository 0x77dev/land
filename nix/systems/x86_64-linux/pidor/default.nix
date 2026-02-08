{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.11";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    time-client.enable = true;
  };

  virtualisation.incus.agent.enable = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.fish;
  };

  networking = {
    hostName = "pidor";
    domain = "0x77.computer";
    useDHCP = true;
    firewall.enable = false;
  };

  # Hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      intel-gpu-tools
      libvdpau-va-gl
      intel-compute-runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    enable32Bit = true;
  };

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
    home.config = {
      modules.home = {
        # OpenClaw
        openclaw = {
          enable = true;
        };

        # Shell & tools
        shell.enable = true;
        git.enable = true;
        nix.enable = true;
        ssh.enable = true;
        gpg.enable = true;
        security-tools.enable = true;

        # Utilities
        cloud.enable = true;
        media.enable = true;
        network.enable = true;
        p2p.enable = true;
      };
    };
  };
}
