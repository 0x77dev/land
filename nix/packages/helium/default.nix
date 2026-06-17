{
  lib,
  namespace,
  pkgs,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  _7zz,
  # Command-line flags always passed to Helium. Declared so home-manager's
  # `programs.chromium` can drive it via `package.override { commandLineArgs = ...; }`.
  commandLineArgs ? "",
  ...
}:

let
  pname = "helium";

  # renovate: datasource=github-releases depName=helium packageName=imputnet/helium-linux versioning=loose
  version = "0.13.3.1";

  linuxBase = "https://github.com/imputnet/helium-linux/releases/download/${version}";
  macosBase = "https://github.com/imputnet/helium-macos/releases/download/${version}";

  # Per-system release artifacts. `passthru.sources` re-exports this so the
  # `nix-rehash` script (driven by the Renovate digest workflow) can refresh
  # every platform digest after a version bump, without a build.
  sources = {
    x86_64-linux = {
      url = "${linuxBase}/helium-${version}-x86_64_linux.tar.xz";
      hash = "sha256-tfiy1MkxXq9vOjp57R3ykHjleG0Viz/C2ttwXbHnPwA=";
    };
    aarch64-linux = {
      url = "${linuxBase}/helium-${version}-arm64_linux.tar.xz";
      hash = "sha256-q6cCrvDh9eYQZwCLArKXZDpYkl0Zzi2g9gp9l+G+QIA=";
    };
    x86_64-darwin = {
      url = "${macosBase}/helium_${version}_x86_64-macos.dmg";
      hash = "sha256-iJSV5S9LM7Vvpn4g2cdHzgJAqUjBvUfu+izUh5N3mKI=";
    };
    aarch64-darwin = {
      url = "${macosBase}/helium_${version}_arm64-macos.dmg";
      hash = "sha256-uws6OUTyV6/Ejo1FqFnpNSG3tTUGFMNelrex2m1Ymd0=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "helium: unsupported system ${stdenv.hostPlatform.system}");
  src = fetchurl { inherit (source) url hash; };

  meta = {
    description = "Private, open-source Chromium fork by imputnet";
    homepage = "https://helium.computer/";
    downloadPage = "https://github.com/imputnet/helium-chromium";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "helium";
    platforms = builtins.attrNames sources;
  };

  passthru = { inherit sources version; };

  # Linux runtime library closure (mirrors the chromium binary closure).
  # Pulled from `pkgs` lazily so Darwin evaluation never references libraries
  # that only exist on Linux.
  deps = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    icu
    libcap
    libdrm
    libGL
    libglvnd
    libkrb5
    libpng
    # cspell:words libx libxcomposite libxcursor libxdamage libxext libxfixes libxi libxrandr libxrender libxtst
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libgbm
    libpulseaudio
    libva
    nspr
    nss
    pango
    pciutils
    pipewire
    qt6.qtbase
    qt6.qtwayland
    systemd
    util-linux
    vulkan-loader
    wayland
  ];

  linux = stdenv.mkDerivation (finalAttrs: {
    inherit
      pname
      version
      src
      meta
      passthru
      ;

    strictDeps = false;

    nativeBuildInputs = [
      makeWrapper
      pkgs.patchelf
    ];

    rpath = lib.makeLibraryPath deps;

    unpackPhase = ''
      runHook preUnpack
      tar xf "$src" --strip-components=1
      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      libdir=$out/share/helium
      mkdir -p "$libdir" $out/bin

      cp -a . "$libdir"
      # Tarball ships some assets read-only; patchelf needs them writable.
      chmod -R u+w "$libdir"

      # Prefer the system Vulkan loader so hardware Vulkan can find its ICDs.
      rm -f "$libdir/libvulkan.so.1"
      ln -s "${lib.getLib pkgs.vulkan-loader}/lib/libvulkan.so.1" "$libdir/libvulkan.so.1"

      # Patch the dynamically-linked ELF binaries. `chrome` is a symlink to
      # `helium`, so skip symlinks to avoid double-patching.
      for elf in helium chrome chromedriver helium_crashpad_handler; do
        [ -f "$libdir/$elf" ] && [ ! -L "$libdir/$elf" ] || continue
        patchelf \
          --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
          --set-rpath "$libdir:${finalAttrs.rpath}" \
          "$libdir/$elf"
      done

      # The bundled GL/ANGLE/swiftshader libraries need the same search path.
      # Skip symlinks (e.g. the store-backed libvulkan.so.1) which are read-only.
      for so in "$libdir"/*.so "$libdir"/*.so.*; do
        [ -f "$so" ] && [ ! -L "$so" ] || continue
        patchelf --set-rpath "$libdir:${finalAttrs.rpath}" "$so"
      done

      makeWrapper "$libdir/helium" "$out/bin/helium" \
        --prefix LD_LIBRARY_PATH : "$libdir:${finalAttrs.rpath}" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.pciutils ]}" \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt6.qtbase}/lib/qt-6/plugins" \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt6.qtwayland}/lib/qt-6/plugins" \
        --suffix XDG_DATA_DIRS : "${pkgs.addDriverRunpath.driverLink}/share" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        ${lib.optionalString (commandLineArgs != "") "--add-flags ${lib.escapeShellArg commandLineArgs}"}

      install -Dm644 "$libdir/helium.desktop" "$out/share/applications/helium.desktop"
      substituteInPlace "$out/share/applications/helium.desktop" \
        --replace-quiet "Exec=helium" "Exec=$out/bin/helium"
      install -Dm644 "$libdir/product_logo_256.png" \
        "$out/share/icons/hicolor/256x256/apps/helium.png"

      runHook postInstall
    '';
  });

  darwin = stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      meta
      passthru
      ;

    sourceRoot = ".";
    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    nativeBuildInputs = [
      _7zz
      makeWrapper
    ];

    # The macOS release ships as an APFS dmg, which `undmg` cannot read; 7-Zip
    # extracts the bundle directly.
    unpackPhase = ''
      runHook preUnpack
      7zz x "$src" -y >/dev/null
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications" "$out/bin"
      cp -a "Helium.app" "$out/Applications/"

      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium" \
        ${lib.optionalString (commandLineArgs != "") "--add-flags ${lib.escapeShellArg commandLineArgs}"}

      runHook postInstall
    '';
  };
in
if stdenv.hostPlatform.isDarwin then darwin else linux
