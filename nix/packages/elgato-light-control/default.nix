{
  fetchzip,
  glib,
  lib,
  stdenvNoCC,
}:
let
  uuid = "elgato-light-control@cluster2a.github.io";
in
stdenvNoCC.mkDerivation {
  pname = "gnome-shell-extension-elgato-light-control";
  version = "5";

  src = fetchzip {
    url = "https://extensions.gnome.org/extension-data/elgato-light-controlcluster2a.github.io.v5.shell-extension.zip";
    hash = "sha256-q7OTJbT0vH6uAcUUYZ6utIdUpccoIzYo1F7U6uHUdgw=";
    stripRoot = false;
  };

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --strict schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/gnome-shell/extensions/${uuid}"
    cp -r -T . "$out/share/gnome-shell/extensions/${uuid}"
    runHook postInstall
  '';

  passthru = {
    extensionPortalSlug = "elgato-light-control";
    extensionUuid = uuid;
    upstreamVersion = "2.1.0";
  };

  meta = {
    description = "GNOME panel controls for network Elgato Key Lights";
    homepage = "https://github.com/Cluster2a/gnome-shell-extension-elgato-light-control";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
