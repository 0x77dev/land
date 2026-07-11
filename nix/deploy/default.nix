{
  src ? ../..,
}:
let
  flake = builtins.getFlake "path:${toString src}";
  lib = flake.inputs.nixpkgs.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  deployLib = flake.inputs.cachix-deploy-flake.lib pkgs;

  # A single system agent owns each host's integrated system + Home Manager
  # closure. vasyl is part of spark's atomic microVM closure. Installer images
  # are build artifacts, not deployment agents.
  agents = {
    beefy = flake.darwinConfigurations.beefy.system;
    ghost = flake.nixosConfigurations.ghost.config.system.build.toplevel;
    muscle = flake.nixosConfigurations.muscle.config.system.build.toplevel;
    potato = flake.darwinConfigurations.potato.system;
    spark = flake.nixosConfigurations.spark.config.system.build.toplevel;
    timey = flake.nixosConfigurations.timey.config.system.build.toplevel;
  };

  configuredAgents = [
    flake.darwinConfigurations.beefy.config.services.cachix-agent
    flake.nixosConfigurations.ghost.config.services.cachix-agent
    flake.nixosConfigurations.muscle.config.services.cachix-agent
    flake.darwinConfigurations.potato.config.services.cachix-agent
    flake.nixosConfigurations.spark.config.services.cachix-agent
    flake.nixosConfigurations.timey.config.services.cachix-agent
  ];

  # Cachix waits for each activation by default. Start with always-on potato,
  # deploy infrastructure before portable hosts, and keep muscle and spark in
  # separate stages so the paired builder/compute hosts never switch at once.
  rollout = [
    {
      name = "canary";
      agents = [ "potato" ];
    }
    {
      name = "time-infrastructure";
      agents = [ "timey" ];
    }
    {
      name = "compute-appliance";
      agents = [ "spark" ];
    }
    {
      name = "primary-workstation";
      agents = [ "muscle" ];
    }
    {
      name = "darwin-workstation";
      agents = [ "beefy" ];
    }
    {
      name = "portable-workstation";
      agents = [ "ghost" ];
    }
  ];

  agentNames = builtins.attrNames agents;
  configuredAgentNames = map (agent: agent.name) configuredAgents;
  rolloutAgentNames = lib.concatMap (group: group.agents) rollout;
  validAgents =
    lib.all (agent: agent.enable) configuredAgents
    && builtins.length configuredAgentNames == builtins.length (lib.unique configuredAgentNames)
    && builtins.sort builtins.lessThan configuredAgentNames == agentNames;
  validRollout =
    builtins.length rolloutAgentNames == builtins.length (lib.unique rolloutAgentNames)
    && builtins.sort builtins.lessThan rolloutAgentNames == agentNames;
  validDeployment = validAgents && validRollout;
in
{
  inherit agentNames;
  rollout =
    assert validDeployment;
    rollout;
  spec =
    assert validDeployment;
    deployLib.spec { inherit agents; };
}
