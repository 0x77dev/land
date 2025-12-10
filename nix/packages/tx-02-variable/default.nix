{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
  fontforge,
  bdf2psf,
  kbd,
  python3,
}:

# TX-02 Berkeley Mono™ Typeface - Variable Font
# License: LT-02 Developer Font License (NKR8-W997-JMLM-2W57)
# Version: 2.003 (Released 2025-09-17)
# Copyright 2022-2025. All Rights Reserved.
# Intellectual Property of U.S. Graphics Company, LLC.
#
# IMPORTANT NOTICE:
# This repository does NOT contain or distribute the font files themselves.
# This file only contains metadata and URL references to fonts hosted on
# external private storage (cdn.0x77.dev). The actual font files are fetched
# at build time from private CDN and are NOT included in this repository.
#
# This package is for personal use only as permitted by the developer license.
#
# DMCA Contact: dmca@0x77.dev
# More info: https://usgraphics.com/products/berkeley-mono
let
  inherit (stdenvNoCC.hostPlatform) isLinux;
in
stdenvNoCC.mkDerivation rec {
  pname = "tx-02-variable";
  version = "2.003";

  # NOTE: These URLs point to private CDN storage
  srcs = [
    (fetchurl {
      url = "https://cdn.0x77.dev/fonts/tx-02/TX-02-Variable.otf";
      hash = "sha256-Q9Iz3zODfh4PsY5j3TT7iwTJc9Z9y+SE2GTySNMkPc0=";
    })
    (fetchurl {
      url = "https://cdn.0x77.dev/fonts/tx-02/TX-02-Variable.ttf";
      hash = "sha256-7yA9u0FEnRGnabZEYWBmjg6OqP5GB1tPStiMgNeWXF4=";
    })
    (fetchurl {
      url = "https://cdn.0x77.dev/fonts/tx-02/TX-02-Variable.woff2";
      hash = "sha256-hsuuoTHpE7nqbdGuSV6k7umhsmzzAYyAqVpWBIhhekw=";
    })
  ];

  nativeBuildInputs = lib.optionals isLinux [
    fontforge
    python3
    bdf2psf
    kbd
  ];

  dontUnpack = true;

  buildPhase = lib.optionalString isLinux ''
    runHook preBuild

    # Convert variable font to PSF console fonts using FontForge (Linux only)
    for size in 16 20 24 32; do
      echo "Converting TX-02 to PSF format (''${size}pt)..."

      # Use FontForge's native scripting language to generate BDF bitmap
      fontforge --lang=ff -c '
        Open($1);
        SelectAll();
        AutoHint();
        SetGasp('$size',1,65535,1);
        BitmapsAvail(['$size'], 1);
        BitmapsRegen(['$size']);
        Generate("font.", "bdf");
      ' "${builtins.elemAt srcs 1}" 2>&1 | grep -v "Bad device table" | grep -v "glyph named" | grep -v "Internal Error" || true

      bdffile="font-$size.bdf"

      # Verify BDF file was created
      if [ ! -f "$bdffile" ]; then
        echo "ERROR: BDF file not created for size $size"
        ls -la
        exit 1
      fi

      echo "BDF file created successfully"

      # Fix AVERAGE_WIDTH for bdf2psf compatibility
      width=$(grep AVERAGE_WIDTH "$bdffile" | cut -d ' ' -f 2)
      oldwidth="$width"
      width=$(( (((width - 1) / 10) + 1) * 10 ))
      sed -i "s/AVERAGE_WIDTH .*/AVERAGE_WIDTH $width/" "$bdffile"
      echo "AVERAGE_WIDTH corrected from $oldwidth to $width"

      # BDF -> PSF
      echo "Converting BDF to PSF..."
      bdf2psf \
        --fb "$bdffile" \
        ${bdf2psf}/share/bdf2psf/standard.equivalents \
        ${bdf2psf}/share/bdf2psf/ascii.set+${bdf2psf}/share/bdf2psf/linux.set+${bdf2psf}/share/bdf2psf/fontsets/Uni2.512 \
        512 \
        tx-02-$size.psf || {
        echo "ERROR: bdf2psf failed for size $size"
        exit 1
      }

      echo "PSF file created successfully for size $size"
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install original font files
    install -Dm644 -t $out/share/fonts/opentype ${builtins.elemAt srcs 0}
    install -Dm644 -t $out/share/fonts/truetype ${builtins.elemAt srcs 1}
    install -Dm644 -t $out/share/fonts/woff2 ${builtins.elemAt srcs 2}

    ${lib.optionalString isLinux ''
      # Install PSF console fonts (Linux only)
      # NixOS expects console fonts to be gzipped, so we only install the .gz version
      mkdir -p $out/share/consolefonts
      for size in 16 20 24 32; do
        gzip -c tx-02-''${size}.psf > $out/share/consolefonts/tx-02-''${size}.psf.gz
      done
    ''}

    runHook postInstall
  '';

  meta = with lib; {
    description = "TX-02 Berkeley Mono™ Typeface - Variable Font + Console Fonts (Linux)";
    longDescription = ''
      TX-02 Berkeley Mono™ Complete Font Package (Version 2.003)

      Includes:
      - Variable fonts: OTF, TTF, WOFF2 (645 glyphs, variable weight/width/slant)
      - Console fonts: PSF bitmap fonts (16pt, 20pt, 24pt, 32pt) - Linux only

      Desktop/Terminal Usage:
        fonts.packages = [ pkgs.${namespace}.tx-02-variable ];

      Console Usage (NixOS/Linux only):
        console.font = "tx-02-32";
        console.packages = [ pkgs.${namespace}.tx-02-variable ];

      Note: PSF console fonts are only generated on Linux platforms.
            On Darwin/macOS, only the variable fonts (OTF/TTF/WOFF2) are included.

      Copyright 2022-2025. All Rights Reserved.
      Intellectual Property of U.S. Graphics Company, LLC.
      Licensed under LT-02 Developer Font License.

      This is proprietary software and cannot be freely redistributed.

      IMPORTANT: This repository does NOT contain or distribute the font
      files themselves. This package only contains metadata and references
      to fonts hosted on external private storage. The actual font files
      are fetched at build time from private CDN (cdn.0x77.dev) and are
      NOT included in this repository.

      DMCA Contact: dmca@0x77.dev
    '';
    homepage = "https://usgraphics.com/products/berkeley-mono";
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
  };
}
