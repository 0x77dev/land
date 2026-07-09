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
    # A typography library matching (and beyond) what macOS ships: SF-class
    # UI sans, the classic book/display faces macOS is known for (via their
    # closest open counterparts), full Unicode/CJK/emoji coverage, and a deep
    # monospace bench. Same set on every host, mac and Linux alike, so
    # documents render identically. Everything is OpenType/variable-feature
    # rich for creative work.
    home.packages =
      (with pkgs.${namespace}; [ tx-02-variable ])
      # Apple Color Emoji (Linux only; macOS already has it natively).
      ++ optional pkgs.stdenv.isLinux pkgs.${namespace}.apple-color-emoji
      ++ (with pkgs; [
        # The entire Google Fonts library (thousands of families): Inter,
        # IBM Plex, Source Sans/Serif, EB Garamond, Crimson, Playfair, Lora,
        # Spectral, Work Sans, Lexend, Geist, JetBrains Mono, Fira Code, ...
        # Everything below adds only what this bundle does not carry.
        google-fonts

        # Helvetica Neue (Adobe's free LT Std release) — the macOS staple
        helvetica-neue-lt-std

        # macOS classics via their open equivalents: TeX Gyre covers
        # Palatino (Pagella), Times (Termes), Helvetica (Heros), Bookman
        # (Bonum), Century Schoolbook (Schola), Avant Garde (Adventor),
        # Zapf Chancery (Chorus), Courier (Cursor).
        gyre-fonts

        # Coverage: full Noto with CJK and color emoji
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji

        # Metric-compatible replacements for Arial/Times/Courier documents
        liberation_ttf

        # Monospace bench beyond Google Fonts (Menlo/Monaco/SF Mono class)
        hack-font
        monaspace
        commit-mono

        # Icon/symbol fonts for design mockups and terminals
        font-awesome
        nerd-fonts.symbols-only
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
        emoji = [
          "Apple Color Emoji"
          "Noto Color Emoji"
        ];
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
