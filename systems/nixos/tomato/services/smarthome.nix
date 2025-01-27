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
      "energy"
      "history"
      "logbook"
      "counter" # Required for some automations
      "file_upload" # Required for some UI functions
      "folder_watcher" # Useful for monitoring config changes
      "hardware" # Better hardware support
      "local_ip" # Required for network detection
      "logger" # Better logging support
      "notify" # Required for notifications
      "person" # Required for presence detection
      "systemmonitor" # System monitoring
      "auth"
      "config"
      "file_upload"
      "image"
      "logger"
      "map"
      "person"
      "safe_mode"
      "usb"
      "websocket_api"

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
      };

      # Default Configuration
      default_config = { };

      # HTTP Configuration
      http = {
        server_host = [ "0.0.0.0" "::" ];
        server_port = 9123;
        use_x_forwarded_for = true;
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

      logger = {
        default = "info";
        logs = {
          "homeassistant.components.zha" = "debug";
          "homeassistant.components.mqtt" = "debug";
          "homeassistant.components.bluetooth" = "debug";
        };
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
        birth_message = {
          topic = "homeassistant/status";
          payload = "online";
        };
        will_message = {
          topic = "homeassistant/status";
          payload = "offline";
        };
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

      backup = {
        auto_purge = true;
        backup_path = "/var/lib/hass/backups";
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
      govee-ble
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
      python-otbr-api
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
      pyatv # ATV
      samsungctl
      samsungtvws
      aranet4
      # For Twitter integration
      tweepy

      # For Telegram integration
      python-telegram-bot

      # For YouTube integration
      google-api-python-client
      oauth2client

      # For Xiaomi integrations
      python-miio
      xiaomi-ble

      # For Govee integration
      govee-api-laggat

      # For OpenAI integration
      openai

      # For Transmission integration
      transmissionrpc

      # For Withings integration
      withings-api

      # For UniFi Protect
      pyunifiprotect

      # For ONVIF
      onvif-zeep

      # For Tautulli
      pytautulli

      # For Plex
      plexapi

      # For Tailscale
      tailscale

      # For Netdata
      netdata

      # For media support
      mutagen # Audio metadata
      pillow # Image processing

      # For TTS/STT
      gtts # Google TTS

      # Network and device tracking
      requests # HTTP requests
      netaddr # Network address manipulation
      pyroute2 # Linux networking

      # Additional utilities
      yarl # URL parsing
      async_timeout # Async timeout
      astral # Sun calculations
      python-socketio # Socket.IO support
      xmltodict # XML parsing
      voluptuous # Config validation
      PyJWT # JWT support
      asyncio_mqtt # MQTT async support
      aiodiscover # Network discovery
      ifaddr # Interface addresses
      pyserial # Serial port support
      pyserial-asyncio # Async serial support
      typing-extensions # Type hints
      wakeonlan # Wake on LAN
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
    "d /var/lib/hass/www 0755 hass hass"
    "d /var/lib/hass/custom_components 0755 hass hass"
    "d /var/lib/hass/themes 0755 hass hass"
  ];
  systemd.services.home-assistant = {
    wants = [ "network-online.target" "postgresql.service" "mosquitto.service" ];
    after = [ "network-online.target" "postgresql.service" "mosquitto.service" ];
  };
}
