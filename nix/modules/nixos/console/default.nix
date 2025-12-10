{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
let
  cfg = config.modules.console;
in
{
  options.modules.console = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable console configuration with TX-02 font";
    };

    font = mkOption {
      type = types.str;
      default = "tx-02-32";
      description = "Console font to use (from tx-02-variable package)";
    };

    earlySetup = mkOption {
      type = types.bool;
      default = true;
      description = "Apply console font settings in initrd";
    };

    kmscon = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable kmscon virtual console with TX-02 font";
      };

      fontSize = mkOption {
        type = types.int;
        default = 14;
        description = "Font size for kmscon";
      };

      hwRender = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardware rendering for kmscon";
      };
    };
  };

  config = mkIf cfg.enable {
    console = {
      inherit (cfg) earlySetup font;
      packages = [ pkgs.${namespace}.tx-02-variable ];
    };

    services.kmscon = mkIf cfg.kmscon.enable {
      enable = true;
      inherit (cfg.kmscon) hwRender;
      fonts = [
        {
          name = "TX-02-Variable";
          package = pkgs.${namespace}.tx-02-variable;
        }
      ];
      extraConfig = ''
        font-size=${toString cfg.kmscon.fontSize}
        xkb-layout=us
      '';
    };
  };
}
