# NixOS Modules

This directory contains NixOS modules that can be imported and used in your system configuration.

## Available Modules

### VSCode Server

A module for setting up VSCode Remote Server with optimized settings:

```nix
{
  imports = [ ./modules/nixos ];
  modules.vscode-server.enable = true;
}
```

### K3s Cluster

A module for setting up a K3s Kubernetes cluster:

```nix
{
  imports = [ ./modules/nixos ];

  # Primary node example
  modules.cluster = {
    enable = true;
    role = "server";
    clusterInit = true;
  };

  # Worker node example
  modules.cluster = {
    enable = true;
    role = "agent";
    serverAddr = "https://primary-node:6443";
  };
}
```

See the [main README](../README.md) for more detailed documentation on the cluster module.

## Structure

Each module follows a consistent pattern:

- Each module has its own `.nix` file
- All modules are exported through `default.nix`
- Configuration options are namespaced under `modules.<module-name>`

## Adding a New Module

To add a new module:

1. Create a new file `your-module.nix`
2. Use the other modules as templates
3. Import it in `default.nix`
4. Document it in this README
