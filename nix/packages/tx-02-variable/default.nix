{
  lib,
  namespace,
  stdenvNoCC,
  fetchurl,
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

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/share/fonts/opentype ${builtins.elemAt srcs 0}
    install -Dm644 -t $out/share/fonts/truetype ${builtins.elemAt srcs 1}
    install -Dm644 -t $out/share/fonts/woff2 ${builtins.elemAt srcs 2}

    runHook postInstall
  '';

  meta = with lib; {
    description = "TX-02 Berkeley Mono™ Typeface - Variable Font Family";
    longDescription = ''
      TX-02 Berkeley Mono™ Variable Font (Version 2.003)
      645 glyphs with variable weight, width, and slant axes.

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
