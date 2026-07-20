{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
  fonts = config.modules.home.fonts.presentation;
  batteryExtension = pkgs.gnomeExtensions.bluetooth-battery-meter;
  kdeConnect = pkgs.kdePackages.kdeconnect-kde;
  cohereModel = pkgs.${namespace}.voxtype-model-cohere-fp16;
  vadModel = pkgs.${namespace}.voxtype-model-silero-vad;
  vicinaePackage = pkgs.${namespace}.vicinae;
  voxtypePackage = pkgs.${namespace}.voxtype;
  astraGpus =
    map
      (domain: {
        inherit domain;
        bus = "00";
        slot = "0";
        vendorId = "10de";
        productId = "26b1";
      })
      [
        "0000:c1"
        "0000:e1"
      ];
  vicinaeSettings = {
    "$schema" = "https://vicinae.com/schemas/config.json";
    font = {
      rendering = "native";
      normal = {
        family = fonts.roles.body.family;
        size = fonts.roles.body.size;
      };
    };
    theme = {
      light.name = "libadwaita-light";
      dark.name = "libadwaita-dark";
    };
    providers = {
      "@ShyAssassin/store.vicinae.vscode-recents" = {
        preferences = {
          vscodeFlavour = "Cursor";
          windowPreference = "Default";
        };
        entrypoints.open-recents.alias = "code";
      };
      "@aiotter/store.raycast.nixpkgs-search".entrypoints.index.alias = "nix";
    };
  };
  vicinaeSettingsFile = (pkgs.formats.json { }).generate "vicinae-settings.json" vicinaeSettings;
in
{
  assertions = [
    {
      assertion =
        batteryExtension.extensionUuid == "Bluetooth-Battery-Meter@maniacx.github.com"
        && batteryExtension.version == "45";
      message = "Bluetooth Battery Meter changed; re-audit its GNOME metadata and schema.";
    }
    {
      assertion =
        voxtypePackage.upstreamVersion == "0.7.5"
        && voxtypePackage.sourceRevision == "f97276661d9b723aa3236f03879650a2a06c3ec3";
      message = "Voxtype source changed; re-audit the emitted config schema before updating this pin.";
    }
  ];

  home = shared.home // {
    packages = with pkgs; [
      batteryExtension
      telegram-desktop
      spotify
      zoom-us
    ];

    # Consistent cursor everywhere, including Xwayland and Qt apps that read
    # XCURSOR_* instead of dconf.
    pointerCursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  modules.home = shared.modules.home // {
    ai.enable = true;
    browser = {
      enable = true;
      # Chromium 150 compiles its experimental Rust JPEG XL decoder but leaves
      # the runtime feature disabled by default.
      commandLineArgs = [ "--enable-features=JXLImageFormat,WaylandWindowDecorations" ];
    };
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    gnome-control-surfaces.enable = true;
    gnome = {
      enable = true;
      extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        batteryExtension.extensionUuid
        "monitor@astraext.github.io"
        "tailscale@joaophi.github.com" # Tailscale in quick settings
      ];
    };
    git.enable = true;
    ide.enable = true;
    manufacturing.enable = true;
    media.enable = true;
    network.enable = true;
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security-tools.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "${fonts.roles.body.family} ${fonts.roles.body.style}";
      size = fonts.roles.body.size;
    };
    theme.name = "Adwaita";
    iconTheme.name = "Adwaita";
    colorScheme = "dark";

    # Libadwaita follows the color-scheme setting; do not inject GTK 4 CSS.
    gtk4.theme = null;
  };

  programs = {
    home-manager.enable = true;

    # Screen recording / streaming with PipeWire capture.
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    };

    # Raycast-style launcher on Super+Space (keybinding lives in the gnome
    # module). The systemd user service keeps the daemon warm.
    vicinae = {
      enable = true;
      package = vicinaePackage;
      settings = vicinaeSettings;
      systemd = {
        enable = true;
        environment.VICINAE_OVERRIDES = toString vicinaeSettingsFile;
      };
    };

    # Local, GPU-accelerated dictation. GNOME owns the Voice Command key
    # binding; the resident daemon receives one state-aware toggle command.
    voxtype = {
      enable = true;
      package = voxtypePackage;
      service.enable = true;
      settings = {
        # The pinned Home Manager module's engine enum predates Cohere;
        # freeform settings are merged last into the generated TOML.
        engine = "cohere";
        state_file = "auto";
        hotkey.enabled = false;
        cohere = {
          model = "${cohereModel}";
          language = "en";
          on_demand_loading = false;
        };
        parakeet.model = "parakeet-tdt-0.6b-v3";
        moonshine = {
          model = "moonshine-base";
          quantized = false;
        };
        whisper = {
          model = "large-v3";
          language = "auto";
          flash_attention = true;
        };
        vad = {
          enabled = true;
          backend = "whisper";
          model = "${vadModel}/ggml-silero-vad.bin";
          threshold = 0.5;
          min_speech_duration_ms = 100;
        };
        osd = {
          enabled = true;
          frontend = "gtk4";
        };
        output = {
          mode = "type";
          driver_order = [
            "ydotool"
            "clipboard"
          ];
          wait_for_modifier_release = false;
        };
        output.notification.on_transcription = true;
      };
    };
  };

  # Home Manager owns package installation, graphical-session lifecycle, and
  # the non-Plasma tray indicator. GNOME supplies the AppIndicator shell host
  # and the system Qt policy supplies its Adwaita appearance.
  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = kdeConnect;
  };

  systemd.user.services = {
    voxtype.Service.Environment = "CUDA_VISIBLE_DEVICES=GPU-3b81ccee-ecb5-5617-58da-0ac7d35dd001";

    # Add confinement to Home Manager's upstream units rather than maintaining
    # parallel service definitions. File sharing still has normal home access.
    kdeconnect.Service = {
      Restart = lib.mkForce "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK" # Qt monitors interface changes for LAN discovery.
      ];
      UMask = "0077";
    };

    kdeconnect-indicator.Service = {
      Restart = lib.mkForce "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      RestrictSUIDSGID = true;
      LockPersonality = true;
      UMask = "0077";
    };

    # Solaar must stay resident to restore Logitech settings after reconnects.
    # Keep its management tray icon, but let GNOME's battery extension own the
    # battery presentation instead of showing a second generic battery icon.
    solaar = {
      Unit = {
        Description = "Solaar Logitech device manager";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.solaar} --window=hide --battery-icons=solaar";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Replace an older manually started daemon so declarative overrides are
    # effective without rewriting Vicinae's mutable settings.json.
    vicinae.Service.ExecStart = lib.mkForce "${lib.getExe vicinaePackage} server --replace";
  };

  # Appearance, kept declarative. Cursor/icon themes are pinned because the
  # prior KDE install left `breeze` in dconf, which renders broken in GNOME.
  dconf.settings =
    let
      wallpaper = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-l.jxl";
        primary-color = "#86b6ef";
        secondary-color = "#000000";
      };
    in
    {
      "org/gnome/desktop/interface" = {
        accent-color = "blue";
        font-name = "${fonts.roles.body.family} ${fonts.roles.body.style} ${toString fonts.roles.body.size}";
        document-font-name = "${fonts.roles.document.family} ${fonts.roles.document.style} ${toString fonts.roles.document.size}";
        monospace-font-name = "${fonts.roles.monospace.family} ${fonts.roles.monospace.style} ${toString fonts.roles.monospace.size}";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        text-scaling-factor = 1.05;
      };

      "org/gnome/shell/extensions/Bluetooth-Battery-Meter" = {
        enable-battery-level-text = true;
        enable-upower-level-icon = true;
      };

      "org/gnome/desktop/background" = wallpaper // {
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-d.jxl";
      };

      "org/gnome/desktop/screensaver" = wallpaper;

      "org/gnome/shell/extensions/astra-monitor" = {
        monitors-order = builtins.toJSON [
          "processor"
          "gpu"
          "memory"
          "network"
          "sensors"
          "storage"
        ];
        headers-height-override = 0;
        explicit-zero = true;

        processor-update = 1.5;
        processor-header-show = true;
        processor-header-percentage = true;
        processor-header-graph = false;
        processor-header-bars = false;
        processor-header-bars-core = false;
        processor-header-frequency = false;

        gpu-update = 2.0;
        gpu-main = builtins.toJSON (builtins.head astraGpus);
        gpu-data = builtins.toJSON (map (gpu: gpu // { monitor = true; }) astraGpus);
        gpu-header-show = true;
        gpu-header-activity-bar = false;
        gpu-header-activity-graph = false;
        gpu-header-activity-percentage = true;
        gpu-header-memory-bar = false;
        gpu-header-memory-graph = false;
        gpu-header-memory-percentage = false;

        memory-update = 2.0;
        memory-used = "total-available";
        memory-header-show = true;
        memory-header-percentage = true;
        memory-header-value = false;
        memory-header-free = false;
        memory-header-graph = false;
        memory-header-bars = false;

        storage-update = 2.0;
        storage-ignored-regex = "(?:loop|zram|ram).*";
        storage-header-show = true;
        storage-header-percentage = false;
        storage-header-value = false;
        storage-header-free = false;
        storage-header-bars = false;
        storage-header-io-bars = false;
        storage-header-graph = false;
        storage-header-io = false;

        network-update = 1.5;
        network-io-unit = "KiB/s";
        network-ignored-regex = "(?:lo|docker.*|veth.*|virbr.*|br-.*)";
        network-source-public-ipv4 = "";
        network-source-public-ipv6 = "";
        network-header-show = true;
        network-header-bars = false;
        network-header-graph = false;
        network-header-io = true;
        network-header-io-layout = "vertical";
        network-header-io-figures = 3;

        sensors-update = 3.0;
        sensors-source = "hwmon";
        sensors-header-show = true;
        sensors-header-sensor1-show = true;
        sensors-header-sensor1 = builtins.toJSON {
          service = "hwmon";
          path = [
            "k10temp-{$14b0}"
            "Tctl"
            "input"
          ];
        };
        sensors-header-sensor1-digits = 0;
        sensors-header-sensor2-show = false;
      };
    };
}
