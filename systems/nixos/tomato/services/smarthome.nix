{ config, pkgs, ... }: {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Core Components
      "default_config"
      "met"
      "analytics"
      "diagnostics"
      "backup"
      "energy"
      "frontend"
      "history"
      "logbook"
      "mobile_app"
      "sun"
      "system_health"
      "webhook"
      "vacuum"
      "zone"
      "sensor"
      "proximity"
      "tag"
      "text"
      "recorder"
      "stream"
      "template"

      # Etc
      "twitter"
      "telegram"
      "youtube"
      "xiaomi"
      "xiaomi_ble"
      "xiaomi_miio"
      "govee_light_local"
      "fail2ban"
      "netdata"
      "openai_conversation"
      "assist_pipeline"
      "assist_satellite"
      "transmission"
      "withings"

      # Device Discovery & Control Protocols
      "zha" # Zigbee Home Automation
      "mqtt" # MQTT Protocol
      "bluetooth" # Bluetooth support
      "esphome" # ESPHome devices
      "homekit" # HomeKit support
      "matter" # Matter protocol
      "ssdp" # Simple Service Discovery Protocol
      "zeroconf" # Zero-configuration networking
      "dhcp" # DHCP discovery
      "tcp"

      # Media
      "cast" # Google Cast support
      "dlna_dmr" # DLNA Digital Media Renderer
      "media_source" # Media browsing
      "tts"
      "stt"
      "unifiprotect"
      "onvif"
      "tautulli"
      "plex"

      # Optimization
      "isal" # Fast zlib compression

      # Network & Device tracking
      "tailscale"
      "unifi"
      "unifi_direct"
      "bluetooth_tracker"
      "device_tracker"
      "network"
      "persistent_notification"
    ];

    config = {
      # Core Configuration
      homeassistant = {
        name = "Home";
        time_zone = config.time.timeZone;
        unit_system = "metric";
        currency = "USD";
        country = "US";
        language = "en";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
      };

      # Default Configuration
      default_config = { };

      # HTTP Configuration
      http = {
        server_host = [ "0.0.0.0" "::" ];
        server_port = 9123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

      # Database Configuration
      recorder = {
        db_url = "postgresql://@/hass";
        purge_keep_days = 14;
        commit_interval = 1;
        auto_purge = true;
        exclude = {
          entities = [
            "sensor.last_boot"
            "sensor.date"
          ];
          domains = [
            "updater"
          ];
        };
        db_max_retries = 10;
        db_retry_wait = 3;
        auto_repack = true;
        statistics_refresh_period = "1:00:00";
      };

      # MQTT Configuration
      mqtt = {
        broker = "localhost";
        port = 1883;
        discovery = true;
        discovery_prefix = "homeassistant";
      };

      # Zigbee Configuration
      zha = {
        database_path = "/var/lib/hass/zigbee.db";
        enable_quirks = true;
        zigpy_config = {
          ota = {
            otau_directory = "/var/lib/hass/otau";
            # Zigbee OTA updates from Koenkk's repo
            z2m_remote_index = "https://raw.githubusercontent.com/Koenkk/zigbee-OTA/master/index.json";
          };
        };
      };

      # HomeKit Configuration
      homekit = {
        auto_start = true;
        filter = {
          include_entities = [ ];
          include_domains = [
            "light"
            "switch"
            "media_player"
            "climate"
          ];
        };
      };

      # Matter Configuration
      matter = {
        enabled = true;
      };

      # History Configuration
      history = { };

      # Logbook Configuration
      logbook = {
        exclude = {
          domains = [
            "updater"
            "automation"
          ];
        };
      };

      # Frontend Configuration
      frontend = {
        themes = "!include_dir_merge_named themes";
      };

      # Automation & Scripts
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };

    # Python packages for additional functionality
    extraPackages = python3Packages: with python3Packages; [
      # Database
      psycopg2
      # Bluetooth
      bleak
      bleak-retry-connector
      # MQTT
      paho-mqtt
      # Optimization
      orjson
      # Zigbee
      bellows
      zigpy
      zha-quirks
      # HomeKit
      aiohomekit
      # Matter
      python-matter-server
      # Other
      netdisco
      colorlog
      # Additional useful packages
      pyudev # Better device support
      pycryptodome # Enhanced encryption support
      python-slugify # Better slug handling
      tzdata # Timezone data
      aiohttp-cors # CORS support
      pymetno # Weather data
      restrictedpython # Security
      packaging # Package version handling
      aioesphomeapi # Better ESPHome support
      zeroconf # Better mDNS support
    ];
  };

  # Enable and configure MQTT broker
  services.mosquitto = {
    enable = true;
    listeners = [{
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };

  # System group memberships for hardware access
  users.users.hass.extraGroups = [
    "dialout" # Serial devices
    "gpio" # GPIO
    "i2c" # I2C devices
    "bluetooth" # Bluetooth
  ];

  # Open required ports
  networking.firewall = {
    allowedTCPPorts = [
      # Home Assistant
      config.services.home-assistant.config.http.server_port
      1883 # MQTT
      5353 # mDNS
      51827 # HomeKit
    ];
    allowedUDPPorts = [
      5353 # mDNS
      51827 # HomeKit
    ];
  };

  # Ensure required system packages
  environment.systemPackages = with pkgs; [
    git
    bluez-tools
    openssl
    nano
    wget
    curl
  ];

  # Enable required system services for bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Allow hass to change config
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0755 hass hass"
    "f /var/lib/hass/scenes.yaml 0755 hass hass"
    "f /var/lib/hass/scripts.yaml 0755 hass hass"
  ];
}
