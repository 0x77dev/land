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
