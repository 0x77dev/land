# nix-rendezvous SSH Cache Container

This container provides a Nix binary cache and remote build service via SSH for the nix-rendezvous infrastructure.

## Features

- Serves as a Nix binary cache via SSH (no HTTP for security)
- Enables remote builds via SSH
- Runs in a Proxmox LXC container
- Uses authorized keys from `helpers/openssh-authorized-keys.json`
- Automatic garbage collection and store optimization

## Building

Build the container with:

```bash
nix build .#packages.x86_64-linux.proxmox-lxc-cache
```

This will create a tarball that can be imported into Proxmox.

## Deploying to Proxmox

1. Copy the tarball to your Proxmox host:
   ```bash
   scp result root@proxmox:/var/lib/vz/template/cache/nix-rendezvous.tar.xz
   ```

2. Create a new LXC container:
   ```bash
   pct create 100 /var/lib/vz/template/cache/nix-rendezvous.tar.xz \
     --hostname nix-rendezvous \
     --cores 4 \
     --memory 4096 \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --unprivileged 1
   ```

3. Start the container:
   ```bash
   pct start 100
   ```

## Configuration

### Using as a Binary Cache (SSH Substituter)

Add the following to your `/etc/nix/nix.conf` on the client machine:

```
substituters = ssh-ng://builder@nix-rendezvous
trusted-public-keys = land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA=
```

For NixOS systems, add this to your configuration:

```nix
nix.settings = {
  substituters = [ "ssh-ng://builder@nix-rendezvous" ];
  trusted-public-keys = [ "land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA=" ];
};
```

### Using as a Remote Builder

Add the following to your SSH config on the client machine:

```
Host nix-rendezvous
  HostName <container-ip-address>
  User builder
  IdentityFile ~/.ssh/id_ed25519
```

Add the following to your `/etc/nix/nix.conf` on the client machine:

```
builders = ssh://builder@nix-rendezvous x86_64-linux
```

For NixOS systems, add this to your configuration:

```nix
nix = {
  buildMachines = [{
    hostName = "nix-rendezvous";
    system = "x86_64-linux";
    maxJobs = 4;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
  }];
  distributedBuilds = true;
};
```

## Security

- The container uses SSH key authentication only
- SSH keys are loaded from `helpers/openssh-authorized-keys.json`
- Root login is disabled
- Only SSH port is exposed
- SSH connections for nix-store are restricted with the `command=` prefix
- No HTTP exposure of the Nix store for improved security

## Maintenance

### Updating SSH Keys

To add or update SSH authorized keys, modify the `helpers/openssh-authorized-keys.json` file and rebuild the container.

### Garbage Collection

The container automatically runs garbage collection to delete store paths older than 31 days. You can manually trigger garbage collection with:

```bash
ssh builder@nix-rendezvous "nix-collect-garbage --delete-older-than 30d"
```

### Store Optimization

The store is automatically optimized to deduplicate identical files. You can manually trigger optimization with:

```bash
ssh builder@nix-rendezvous "nix-store --optimize"
```

## Troubleshooting

If you encounter issues with substitutions or remote builds:

1. Check SSH connection:
   ```bash
   ssh builder@nix-rendezvous
   ```

2. Verify SSH substituter works:
   ```bash
   ssh builder@nix-rendezvous nix-store --serve --write
   ```

3. Test a build:
   ```bash
   nix build --builders 'ssh://builder@nix-rendezvous' nixpkgs#hello
   ```

4. Check container system logs:
   ```bash
   pct enter 100
   journalctl -u nix-daemon -f
   ```

5. Verify your SSH key is properly authorized in the container:
   ```bash
   pct enter 100
   cat /home/builder/.ssh/authorized_keys
   ``` 