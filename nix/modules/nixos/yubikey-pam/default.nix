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
    enable = lib.mkEnableOption "YubiKey FIDO2 authentication for GDM and sudo";

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

        sudo.u2f = {
          enable = true;
          control = "sufficient";
        };
      };
    };

    services.gnome.gnome-keyring.enable = true;
  };
}
