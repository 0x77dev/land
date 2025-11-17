{
  lib,
  inputs ? { },
  ...
}:
let
  inherit (lib)
    any
    concatMap
    filter
    groupBy
    hasSuffix
    map
    mapAttrsToList
    recursiveUpdate
    unique
    ;

  flakeRoot = inputs.self or ../../..;
  systemsRoot = flakeRoot + "/nix/systems";

  readDirNames =
    path:
    let
      entries = builtins.readDir path;
    in
    mapAttrsToList (name: type: {
      inherit name type;
      path = "${path}/${name}";
    }) entries;

  targets =
    if !builtins.pathExists systemsRoot then
      [ ]
    else
      filter (entry: entry.type == "directory") (readDirNames systemsRoot);

  rawMetadata = concatMap (
    target:
    let
      hosts = filter (entry: entry.type == "directory") (readDirNames target.path);
    in
    map (host: {
      inherit (host) name;
      inherit (target) path;
      target = target.name;
      hostPath = host.path;
    }) hosts
  ) targets;

  groupedByHost = groupBy (entry: entry.name) rawMetadata;

  hosts = mapAttrsToList (name: entries: {
    inherit name;
    targets = unique (map (entry: entry.target) entries);
    paths = map (entry: entry.hostPath) entries;
  }) groupedByHost;
in
rec {
  inherit hosts;

  # Build an isolated GPG keyring package with trust levels
  # Similar to home-manager's programs.gpg.publicKeys
  # Usage: lib.land.builders.mkGpgKeyring pkgs {
  #   name = "...";
  #   publicKeys = [
  #     { source = ./key.asc; trust = 5; }  # 5 = ultimate trust
  #   ];
  # }
  mkGpgKeyring =
    pkgs:
    {
      name ? "gpg-keyring",
      publicKeys,
    }:
    let
      importKey = key: ''
        gpg --batch --import ${key.source}
        ${lib.optionalString (key.trust or null != null) ''
          # Set trust level (1=unknown, 2=never, 3=marginal, 4=full, 5=ultimate)
          fingerprint=$(gpg --batch --with-colons --import-options show-only --import ${key.source} 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')
          if [ -n "$fingerprint" ]; then
            echo "$fingerprint:${toString key.trust}:" | gpg --batch --import-ownertrust
          fi
        ''}
      '';
    in
    pkgs.runCommand name { nativeBuildInputs = [ pkgs.gnupg ]; } ''
      export GNUPGHOME=$out
      mkdir -p $out
      chmod 700 $out

      ${lib.concatMapStrings importKey publicKeys}

      # Remove socket files (not reproducible)
      rm -f $out/S.* $out/*/S.*

      # Make keyring read-only for security
      chmod -R a-w $out
    '';

  mkDefaultBuildMachines =
    {
      hostName,
      sshUser,
      includeSelf ? false,
      extraFor ? (_: { }),
    }:
    mkBuildMachines {
      inherit hostName sshUser includeSelf;
      extraFor =
        host:
        recursiveUpdate {
          protocol = "ssh";
          supportedFeatures =
            if any (system: hasSuffix "linux" system) host.targets then
              [
                "benchmark"
                "big-parallel"
                "kvm"
              ]
            else
              [
                "benchmark"
                "big-parallel"
              ];
        } (extraFor host);
    };

  mkBuildMachines =
    {
      hostName ? null,
      sshUser,
      sshKey ? null,
      includeSelf ? false,
      extraFor ? (_host: { }),
    }:
    let
      filteredHosts = filter (host: includeSelf || hostName == null || host.name != hostName) hosts;
    in
    map (
      host:
      let
        base = {
          hostName = host.name;
          systems = host.targets;
          inherit sshUser;
        };
        withKey = if sshKey == null then base else base // { inherit sshKey; };
      in
      recursiveUpdate withKey (extraFor host)
    ) filteredHosts;
}
