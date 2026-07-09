{
  pkgs,
  namespace,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.fonts;
in
{
  options.modules.home.fonts = {
    enable = mkEnableOption "fonts";

    figma-agent = mkOption {
      type = types.bool;
      default = pkgs.stdenv.isLinux;
      description = ''
        Run figma-agent so Figma in the browser can use all locally
        installed fonts (the Linux equivalent of Figma's font helper).
      '';
    };
  };

  config = mkIf cfg.enable {
    # A typography set comparable to what macOS ships out of the box:
    # UI sans (Inter ≈ SF Pro), workhorse serif/sans superfamilies, wide
    # Unicode/CJK coverage, color emoji, and quality monospace — all with
    # variable/OpenType features for creative work.
    home.packages =
      (with pkgs.${namespace}; [ tx-02-variable ])
      ++ (with pkgs; [
        # UI / neo-grotesque
        inter
        # Superfamilies (sans, serif, mono, condensed)
        ibm-plex
        source-sans
        source-serif
        roboto
        roboto-slab
        # Bookish serifs
        eb-garamond
        libre-baskerville
        crimson-pro
        # Coverage: full Noto with CJK and color emoji
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        # Metric-compatible replacements for Arial/Times/Courier documents
        liberation_ttf
        # Monospace
        jetbrains-mono
        fira-code
        hack-font
      ]);

    # Required to autoload fonts from packages
    fonts.fontconfig = {
      enable = true;
      # macOS-like rendering: rely on high-DPI + grayscale smoothing rather
      # than aggressive hinting and subpixel tricks.
      defaultFonts = {
        sansSerif = [
          "Inter"
          "Noto Sans"
        ];
        serif = [
          "Source Serif 4"
          "Noto Serif"
        ];
        monospace = [
          "TX-02"
          "JetBrains Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Local font bridge for Figma in the browser.
    systemd.user.services.figma-agent = mkIf cfg.figma-agent {
      Unit.Description = "Figma font helper (serves local fonts to figma.com)";
      Service = {
        ExecStart = getExe pkgs.figma-agent;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
