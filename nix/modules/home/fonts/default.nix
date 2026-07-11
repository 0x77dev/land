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
  pointsForPixels = pixels: pixels * 0.75;
  presentation = rec {
    density = {
      logicalDpi = 96;
      caption = 12;
      ui = 14;
      document = 15;
      code = 16;
      terminal = 15;
      headline = 16;
      title = 20;
    };

    families = {
      ui = "SF Pro Text";
      display = "SF Pro Display";
      document = "New York Small";
      monospace = "TX-02-Variable";
      monospaceFallback = "SF Mono";
      emoji = "Apple Color Emoji";
      emojiFallback = "Noto Color Emoji";
      symbols = "Symbols Nerd Font";
      symbolsMonospace = "Symbols Nerd Font Mono";
    };

    weights = {
      regular = 400;
      medium = 500;
      semibold = 600;
      bold = 700;
    };

    roles = {
      caption = {
        family = families.ui;
        size = pointsForPixels density.caption;
        style = "Regular";
        weight = weights.regular;
      };
      control = {
        family = families.ui;
        size = pointsForPixels density.ui;
        style = "Medium";
        weight = weights.medium;
      };
      body = {
        family = families.ui;
        size = pointsForPixels density.ui;
        style = "Regular";
        weight = weights.regular;
      };
      emphasis = {
        family = families.ui;
        size = pointsForPixels density.ui;
        style = "Semibold";
        weight = weights.semibold;
      };
      headline = {
        family = families.ui;
        size = pointsForPixels density.headline;
        style = "Semibold";
        weight = weights.semibold;
      };
      title = {
        family = families.display;
        size = pointsForPixels density.title;
        style = "Semibold";
        weight = weights.semibold;
      };
      document = {
        family = families.document;
        size = pointsForPixels density.document;
        style = "Regular";
        weight = weights.regular;
      };
      monospace = {
        family = families.monospace;
        size = pointsForPixels density.code;
        style = "Medium";
        weight = weights.medium;
      };
    };

    adapters = {
      ghostty = {
        size = pointsForPixels density.terminal;
        weight = weights.medium;
        boldWeight = weights.bold;
      };
      editor = {
        size = density.code;
        weight = weights.medium;
        lineHeight = 1.5;
      };
      integratedTerminal = {
        size = density.terminal;
        weight = weights.medium;
        boldWeight = weights.bold;
        lineHeight = 1.25;
      };
    };
  };

  notoScriptFallbacks = pkgs.noto-fonts.overrideAttrs (oldAttrs: {
    pname = "noto-script-fallbacks";
    installPhase = oldAttrs.installPhase + ''
      # SF/New York cover Latin, Greek, and Cyrillic. Keep Noto only for
      # scripts they do not cover, not as a competing generic face.
      rm -f \
        "$out/share/fonts/noto/NotoMusic-Regular.otf" \
        "$out/share/fonts/noto/NotoSans-Italic.ttf" \
        "$out/share/fonts/noto/NotoSans.ttf" \
        "$out/share/fonts/noto/NotoSansMath-Regular.otf" \
        "$out/share/fonts/noto/NotoSansMono.ttf" \
        "$out/share/fonts/noto/NotoSansSymbols.ttf" \
        "$out/share/fonts/noto/NotoSansSymbols2-Regular.otf" \
        "$out/share/fonts/noto/NotoSansTest.ttf" \
        "$out/share/fonts/noto/NotoSerif-Italic.ttf" \
        "$out/share/fonts/noto/NotoSerif.ttf" \
        "$out/share/fonts/noto/NotoSerifDisplay-Italic.ttf" \
        "$out/share/fonts/noto/NotoSerifDisplay.ttf" \
        "$out/share/fonts/noto/NotoSerifTest.ttf" \
        "$out/share/fonts/noto/NotoZnamennyMusicalNotation-Regular.otf"
    '';
  });

  scriptFallbacks = [
    {
      languages = [
        "ar"
        "fa"
        "ur"
      ];
      sans = "Noto Sans Arabic";
      serif = "Noto Naskh Arabic";
    }
    {
      languages = [
        "he"
        "yi"
      ];
      sans = "Noto Sans Hebrew";
      serif = "Noto Serif Hebrew";
    }
    {
      languages = [
        "hi"
        "mr"
        "ne"
      ];
      sans = "Noto Sans Devanagari";
      serif = "Noto Serif Devanagari";
    }
    {
      languages = [ "ja" ];
      sans = "Noto Sans CJK JP";
      serif = "Noto Serif CJK JP";
      monospace = "Noto Sans Mono CJK JP";
    }
    {
      languages = [ "ko" ];
      sans = "Noto Sans CJK KR";
      serif = "Noto Serif CJK KR";
      monospace = "Noto Sans Mono CJK KR";
    }
    {
      languages = [
        "zh-cn"
        "zh-sg"
      ];
      sans = "Noto Sans CJK SC";
      serif = "Noto Serif CJK SC";
      monospace = "Noto Sans Mono CJK SC";
    }
    {
      languages = [ "zh-tw" ];
      sans = "Noto Sans CJK TC";
      serif = "Noto Serif CJK TC";
      monospace = "Noto Sans Mono CJK TC";
    }
    {
      languages = [ "zh-hk" ];
      sans = "Noto Sans CJK HK";
      serif = "Noto Serif CJK HK";
      monospace = "Noto Sans Mono CJK HK";
    }
  ];

  mkLanguageFallback = generic: family: language: ''
    <match target="pattern">
      <test name="family" compare="eq" qual="any">
        <string>${generic}</string>
      </test>
      <test name="lang" compare="contains" qual="any">
        <string>${language}</string>
      </test>
      <edit name="family" mode="prepend_first" binding="weak">
        <string>${family}</string>
      </edit>
    </match>
  '';

  mkScriptFallbacks =
    fallback:
    let
      monospace = fallback.monospace or fallback.sans;
    in
    concatMapStringsSep "\n" (
      language:
      concatStringsSep "\n" [
        (mkLanguageFallback "sans-serif" fallback.sans language)
        (mkLanguageFallback "serif" fallback.serif language)
        (mkLanguageFallback "monospace" monospace language)
      ]
    ) fallback.languages;

  mkPrimaryFamilies = generic: families: ''
    <match target="pattern">
      <test name="family" compare="eq" qual="first">
        <string>${generic}</string>
      </test>
      <edit name="family" mode="prepend_first" binding="strong">
        ${concatMapStringsSep "\n" (family: "<string>${family}</string>") families}
      </edit>
    </match>
  '';
in
{
  options.modules.home.fonts = {
    enable = mkEnableOption "fonts";

    presentation = mkOption {
      type = types.attrs;
      readOnly = true;
      default = presentation;
      description = ''
        Semantic typography roles and unit-specific application adapters.
        Toolkits own widget-level hierarchy; these values only establish the
        shared family, weight, and scale rhythm.
      '';
    };

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
    home.packages = [
      notoScriptFallbacks
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
      pkgs.noto-fonts-color-emoji
      pkgs.nerd-fonts.symbols-only
      pkgs.${namespace}.tx-02-variable
    ]
    ++ optionals pkgs.stdenv.isLinux (
      with pkgs.${namespace};
      [
        apple-fonts
        apple-color-emoji
      ]
    );

    # The profile path is stable across generations, so Fontconfig can retain
    # entries for removed packages unless its per-user cache is refreshed.
    home.activation.refreshFontCache = {
      after = [ "installPackages" ];
      before = [ ];
      data = ''
        verboseEcho "Rebuilding the user font cache"
        run --silence ${pkgs.fontconfig}/bin/fc-cache -r
      '';
    };

    fonts.fontconfig = {
      enable = true;
      antialiasing = true;
      hinting = "slight";
      subpixelRendering = "none";

      defaultFonts = {
        sansSerif = [
          cfg.presentation.families.ui
          cfg.presentation.families.symbols
        ];
        serif = [
          cfg.presentation.families.document
          cfg.presentation.families.symbols
        ];
        monospace = [
          cfg.presentation.families.monospace
          cfg.presentation.families.monospaceFallback
          cfg.presentation.families.symbolsMonospace
        ];
        emoji = [
          cfg.presentation.families.emoji
          cfg.presentation.families.emojiFallback
        ];
      };

      configFile.apple-presentation = {
        enable = true;
        # Run after distro aliases so non-Latin and emoji defaults cannot
        # reorder the semantic families declared here.
        priority = 99;
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <match target="pattern">
              <test name="lang" compare="contains" qual="any">
                <string>und-zsye</string>
              </test>
              <edit name="family" mode="prepend_first" binding="strong">
                <string>${cfg.presentation.families.emoji}</string>
              </edit>
            </match>

            ${concatMapStringsSep "\n" mkScriptFallbacks scriptFallbacks}

            <!-- Cursor/Electron requests system-ui first on Linux. -->
            ${mkPrimaryFamilies "system-ui" [
              cfg.presentation.families.ui
              cfg.presentation.families.symbols
            ]}
          </fontconfig>
        '';
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
