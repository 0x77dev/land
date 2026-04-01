{ lib, ... }:
let
  runnerSystems = {
    aarch64-linux = "ubuntu-24.04-arm";
    x86_64-linux = "ubuntu-latest";
    aarch64-darwin = "macos-latest";
  };

  systemsRoot = lib.snowfall.fs.get-snowfall-file "systems";
  homesRoot = lib.snowfall.fs.get-snowfall-file "homes";

  sortAttrNames = attrs: builtins.sort builtins.lessThan (builtins.attrNames attrs);

  getDirectoryNames =
    path:
    if builtins.pathExists path then
      builtins.filter (name: (builtins.readDir path).${name} == "directory") (
        sortAttrNames (builtins.readDir path)
      )
    else
      [ ];

  quoteAttr =
    attr: if (builtins.match "[A-Za-z_][A-Za-z0-9_'-]*" attr) != null then attr else "\"${attr}\"";

  mkTarget = parts: ".#" + builtins.concatStringsSep "." (map quoteAttr parts);

  splitTarget =
    target:
    let
      parts = lib.splitString "-" target;
    in
    {
      arch = builtins.head parts;
      format = builtins.concatStringsSep "-" (builtins.tail parts);
    };

  getSystemOutputTargets =
    outputs: outputName: system:
    if !(builtins.hasAttr outputName outputs && builtins.hasAttr system outputs.${outputName}) then
      [ ]
    else
      map (
        name:
        mkTarget [
          outputName
          system
          name
        ]
      ) (sortAttrNames outputs.${outputName}.${system});

  getConfigurationHandler =
    outputName:
    if outputName == "homeConfigurations" then
      {
        evalTarget =
          name:
          mkTarget [
            outputName
            name
            "activationPackage"
            "drvPath"
          ];
        buildTarget =
          name:
          mkTarget [
            outputName
            name
            "activationPackage"
          ];
      }
    else if outputName == "darwinConfigurations" then
      {
        evalTarget =
          name:
          mkTarget [
            outputName
            name
            "system"
            "drvPath"
          ];
        buildTarget =
          name:
          mkTarget [
            outputName
            name
            "system"
          ];
      }
    else
      {
        evalTarget =
          name:
          mkTarget [
            outputName
            name
            "config"
            "system"
            "build"
            "toplevel"
            "drvPath"
          ];
        buildTarget =
          name:
          mkTarget [
            outputName
            name
            "config"
            "system"
            "build"
            "toplevel"
          ];
      };

  getDeclaredSystemConfigurations =
    let
      mkEntry =
        target: name:
        let
          parsed = splitTarget target;
          resolvedSystem =
            if parsed.format == "darwin" || parsed.format == "linux" then target else "${parsed.arch}-linux";
          outputName =
            if parsed.format == "darwin" then
              "darwinConfigurations"
            else if parsed.format == "linux" then
              "nixosConfigurations"
            else
              "${parsed.format}Configurations";
        in
        {
          inherit name outputName resolvedSystem;
        };
    in
    builtins.concatMap (
      target: map (name: mkEntry target name) (getDirectoryNames (systemsRoot + "/${target}"))
    ) (getDirectoryNames systemsRoot);

  getDeclaredHomeConfigurations = builtins.concatMap (
    target:
    map (name: {
      inherit name;
      outputName = "homeConfigurations";
      resolvedSystem = target;
    }) (getDirectoryNames (homesRoot + "/${target}"))
  ) (getDirectoryNames homesRoot);
in
{
  mkOutputs =
    { outputs }:
    let
      nativeConfigurationTargets = lib.unique (
        map (entry: (getConfigurationHandler entry.outputName).buildTarget entry.name) (
          builtins.filter (entry: builtins.hasAttr entry.outputName outputs) (
            getDeclaredSystemConfigurations ++ getDeclaredHomeConfigurations
          )
        )
      );

      nativeConfigurationEvalTargets = lib.unique (
        map (entry: (getConfigurationHandler entry.outputName).evalTarget entry.name) (
          builtins.filter (entry: builtins.hasAttr entry.outputName outputs) (
            getDeclaredSystemConfigurations ++ getDeclaredHomeConfigurations
          )
        )
      );

      getNativeConfigurationTargets =
        system:
        builtins.filter (
          target:
          builtins.elem target (
            map (entry: (getConfigurationHandler entry.outputName).buildTarget entry.name) (
              builtins.filter (entry: entry.resolvedSystem == system) (
                getDeclaredSystemConfigurations ++ getDeclaredHomeConfigurations
              )
            )
          )
        ) nativeConfigurationTargets;

      getNativeConfigurationEvaluationTargets =
        system:
        builtins.filter (
          target:
          builtins.elem target (
            map (entry: (getConfigurationHandler entry.outputName).evalTarget entry.name) (
              builtins.filter (entry: entry.resolvedSystem == system) (
                getDeclaredSystemConfigurations ++ getDeclaredHomeConfigurations
              )
            )
          )
        ) nativeConfigurationEvalTargets;

      getNativeRunnerMatrix = system: {
        name = "check / ${system}";
        os = runnerSystems.${system};
        inherit system;
        buildTargets = lib.unique (
          getSystemOutputTargets outputs "checks" system ++ getSystemOutputTargets outputs "devShells" system
        );
        evalTargets = getNativeConfigurationEvaluationTargets system;
      };

      getSecurityMatrix = system: {
        name = "vulnix / ${system}";
        os = runnerSystems.${system};
        inherit system;
        scanTargets = lib.unique (
          getSystemOutputTargets outputs "checks" system
          ++ getSystemOutputTargets outputs "devShells" system
          ++ getSystemOutputTargets outputs "packages" system
          ++ getNativeConfigurationTargets system
        );
      };
    in
    {
      githubActions = {
        ci = {
          matrix = map getNativeRunnerMatrix (sortAttrNames runnerSystems);
        };

        security = {
          matrix = map getSecurityMatrix (sortAttrNames runnerSystems);
        };
      };
    };
}
