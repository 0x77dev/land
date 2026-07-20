{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
  opencodeWebEnvFile = "${config.xdg.configHome}/opencode/web.env";
  opencodeWebArgs = [
    "--hostname"
    "0.0.0.0"
    "--port"
    "4096"
  ];
  opencodeWebPath = lib.concatStringsSep ":" [
    "${config.home.profileDirectory}/bin"
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
    "/run/current-system/sw/bin"
    "/run/wrappers/bin"
  ];
  generateOpencodeWebPassword = pkgs.writeShellScript "opencode-web-password" ''
    set -eu

    env_file=${lib.escapeShellArg opencodeWebEnvFile}
    install -d -m 0700 "$(dirname "$env_file")"

    if [ -s "$env_file" ] && grep -q '^OPENCODE_SERVER_PASSWORD=.' "$env_file"; then
      exit 0
    fi

    password="$(${pkgs.openssl}/bin/openssl rand -base64 36 | tr -d '\n')"
    temp_file="$(${pkgs.coreutils}/bin/mktemp "$env_file.XXXXXX")"

    {
      printf '%s\n' 'OPENCODE_SERVER_USERNAME=opencode'
      printf 'OPENCODE_SERVER_PASSWORD=%s\n' "$password"
    } > "$temp_file"

    chmod 0600 "$temp_file"
    mv "$temp_file" "$env_file"
  '';
  startOpencodeWeb = pkgs.writeShellScript "opencode-web-start" ''
    set -eu

    export PATH=${lib.escapeShellArg opencodeWebPath}:$PATH

    if [ -r ${lib.escapeShellArg "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"} ]; then
      . ${lib.escapeShellArg "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"}
    fi

    exec ${lib.getExe config.programs.opencode.package} serve ${lib.escapeShellArgs opencodeWebArgs}
  '';
in
{
  inherit (shared) home;

  modules.home = shared.modules.home // {
    ai.enable = true;
    browser.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    git.enable = true;
    ide.enable = true;
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
      pinentryPackage = pkgs.pinentry-qt;
    };
  };

  programs = {
    home-manager.enable = true;
    opencode.web = {
      enable = true;
      environmentFile = opencodeWebEnvFile;
      extraArgs = opencodeWebArgs;
    };
  };

  systemd.user.services = {
    opencode-web = {
      Unit = {
        Requires = [ "opencode-web-password.service" ];
        After = [ "opencode-web-password.service" ];
      };

      Service.ExecStart = lib.mkForce startOpencodeWeb;
    };

    opencode-web-password = {
      Unit.Description = "Generate OpenCode web credentials";
      Service = {
        Type = "oneshot";
        ExecStart = generateOpencodeWebPassword;
      };
    };
  };

  # GNOME reads cursor/icon themes from dconf; the prior KDE install left
  # `breeze` set there, which is gone now and renders broken. Pin Adwaita.
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = "Adwaita";
    icon-theme = "Adwaita";
  };
}
