{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.11";

  # Sops secrets for OpenClaw
  # sops = {
  #   defaultSopsFile = ./secrets.yaml;
  #   age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  #   secrets = {
  #     "openclaw/telegram_token" = {
  #       owner = "mykhailo";
  #       mode = "0400";
  #     };
  #     "openclaw/anthropic_key" = {
  #       owner = "mykhailo";
  #       mode = "0400";
  #     };
  #     "openclaw/gateway_token" = {
  #       owner = "mykhailo";
  #       mode = "0400";
  #     };
  #   };
  # };

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

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
    home.config = {
      programs.openclaw = {
        enable = false;

        config = {
          gateway = {
            mode = "local";
            auth.token = "file:${config.sops.secrets."openclaw/gateway_token".path}";
          };

          channels.telegram = {
            tokenFile = config.sops.secrets."openclaw/telegram_token".path;
            allowFrom = [ ]; # TODO: add your Telegram user ID
          };

          env.vars = {
            ANTHROPIC_API_KEY = "file:${config.sops.secrets."openclaw/anthropic_key".path}";
          };
        };

        bundledPlugins = {
          summarize.enable = true;
          oracle.enable = true;
        };
      };
    };
  };
}
