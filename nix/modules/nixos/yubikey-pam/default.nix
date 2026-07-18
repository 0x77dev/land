{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.yubikey-pam;
  origin = "pam://${config.networking.hostName}";
in
{
  options.modules.yubikey-pam = {
    enable = lib.mkEnableOption "YubiKey FIDO2 authentication for login and privilege elevation";

    authFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/u2f-mappings";
      description = "Root-owned host-local pam-u2f credential mapping.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.displayManager.gdm.enable;
        message = "modules.yubikey-pam requires GDM.";
      }
      {
        assertion = config.security.sudo.wheelNeedsPassword;
        message = "modules.yubikey-pam requires authenticated sudo; set security.sudo.wheelNeedsPassword = true.";
      }
    ];

    environment.systemPackages = [ pkgs.pam_u2f ];

    security.pam = {
      u2f.settings = {
        authfile = cfg.authFile;
        inherit origin;
        pinverification = 1;
        userpresence = 0;
        userverification = 0;
      };

      services = {
        # GDM delegates password login and screen unlock to this stack.
        login.u2f = {
          enable = true;
          control = "sufficient";
        };

        # Polkit agents use this stack for pkexec and desktop authorization.
        "polkit-1".u2f = {
          enable = true;
          control = "sufficient";
        };

        sudo.u2f = {
          enable = true;
          control = "sufficient";
        };
      };
    };

    # The upstream helper is isolated from hidraw devices. nixpkgs relaxes
    # this sandbox only for the global U2F switch, while this module enables
    # U2F on selected PAM services instead.
    systemd.services."polkit-agent-helper@".serviceConfig = {
      PrivateDevices = false;
      DeviceAllow = [
        "/dev/urandom r"
        "char-hidraw rw"
      ];
    };

    services.gnome.gnome-keyring.enable = true;
  };
}
