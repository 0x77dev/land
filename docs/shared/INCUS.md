# Incus Cluster Setup on NixOS

## Overview

Incus clustering configuration on tomato and pickle using declarative NixOS
preseed for storage/network/profiles, with manual cluster formation.

**Key Documentation:**

- [Official Incus - How to Initialize](https://linuxcontainers.org/incus/docs/main/howto/initialize/)
- [Official Incus - Form a Cluster](https://linuxcontainers.org/incus/docs/main/howto/cluster_form/)
- [NixOS Wiki - Incus](https://wiki.nixos.org/wiki/Incus)
- [Rocky's NixOS Incus Guide](https://blog.hetherington.uk/2025/01/setting-up-incus-with-zfs-on-nixos/)

## How Preseed Works on NixOS

**The NixOS Incus module uses preseed to declaratively configure:**

1. Storage pools
2. Networks
3. Profiles

**The `incus-preseed.service` systemd service:**

- Runs after `incus.service` starts
- Applies the preseed configuration via `incus admin init --preseed`
- Is idempotent (can run multiple times)
- Creates missing entities, overwrites existing ones
- **Does NOT remove entities**

**What preseed CANNOT do:**

- Configure clustering (must be done interactively)
- This is a limitation of Incus preseed, not NixOS

## Current Module Configuration

After deploying the updated module, preseed automatically configures:

- ✅ Storage pool: `default` (ZFS, using `zroot/incus`)
- ✅ Network: `incusbr0` (bridge, 10.10.10.1/24, NAT enabled)
- ✅ Profile: `default` (with root disk on `default` pool, eth0 on `incusbr0`)

## Deployment Steps

### Step 1: Deploy Updated Configuration

```bash
# Deploy to both systems
deploy .#tomato
deploy .#pickle
```

### Step 2: Verify Preseed Applied

On each system, check that preseed service succeeded:

```bash
# Check preseed service status
sudo systemctl status incus-preseed

# View preseed logs
journalctl -u incus-preseed -e

# Verify storage, network, and profile were created
incus storage list    # Should show "default" (ZFS)
incus network list    # Should show "incusbr0" (managed bridge)
incus profile show default  # Should have root disk and eth0
```

If preseed didn't run or failed, manually trigger it:

```bash
sudo systemctl restart incus-preseed
```

### Step 3: Enable Clustering on Tomato

Convert the standalone Incus installation to a cluster:

```bash
ssh tomato

# First, ensure core.https_address is set
sudo incus config set core.https_address "192.168.0.66:8443"

# Enable clustering
sudo incus cluster enable tomato

# Verify
sudo incus cluster list
# Should show tomato as database-leader
```

### Step 4: Join Pickle to Cluster

Generate join token on tomato:

```bash
ssh tomato
sudo incus cluster add pickle
# Copy the entire token output
```

On pickle, join the cluster:

```bash
ssh pickle

# Join using the token
sudo incus admin init
```

**Answer the prompts:**

```text
Would you like to use clustering? yes
What IP address or DNS name should be used? [press Enter for default]
Are you joining an existing cluster? yes
Do you have a join token? yes
Please provide join token: <paste token>
All existing data is lost when joining a cluster, continue? yes
Choose "source" property for storage pool "default": [press Enter]
Choose "zfs.pool_name" property for storage pool "default": [press Enter]
```

## Verify Cluster

```bash
# On either system
incus cluster list
```

Expected output:

```text
+--------+-----------------------------+-----------------+---------+--------+
| NAME   | URL                         | ROLES           | STATE   | MESSAGE|
+--------+-----------------------------+-----------------+---------+--------+
| tomato | https://192.168.0.66:8443   | database-leader | ONLINE  | ...    |
| pickle | https://192.168.0.X:8443    | database        | ONLINE  | ...    |
+--------+-----------------------------+-----------------+---------+--------+
```

## Test the Cluster

```bash
# Launch a container
incus launch images:alpine/edge test1

# Should work now with proper storage and network
incus list

# Launch on specific target
incus launch images:nixos/24.05 nixos-test --target pickle

# Access web UI
# https://tomato.0x77.computer:8443
```

## Troubleshooting

### Preseed Service Failed

```bash
# Check service status
sudo systemctl status incus-preseed

# View detailed logs
journalctl -u incus-preseed -e

# Manually run preseed
sudo systemctl restart incus-preseed
```

### Storage Pool Not Created

```bash
# Check if ZFS dataset exists
zfs list | grep incus

# Manually create storage pool
incus storage create default zfs source=zroot/incus
```

### Network Not Created

```bash
# Check if incusbr0 exists
ip link show incusbr0

# Manually create network
incus network create incusbr0 \
  ipv4.address=10.10.10.1/24 \
  ipv4.nat=true \
  ipv6.address=none
```

### Profile Missing Devices

```bash
# Check profile
incus profile show default

# Add missing root disk
incus profile device add default root disk path=/ pool=default

# Add missing network
incus profile device add default eth0 nic network=incusbr0
```

### "Address Already in Use" During Cluster Enable

```bash
# Check current https_address setting
incus config get core.https_address

# If it's ":8443", set to specific IP first
incus config set core.https_address "192.168.0.66:8443"

# Then enable clustering
incus cluster enable tomato
```

### Cluster Members Can't Communicate

- Verify bond0 has IPs: `ip addr show bond0`
- Check firewall allows 8443: `sudo ss -tlnp | grep 8443`
- Test connectivity: `curl -k https://tomato.0x77.computer:8443`

## Understanding the Flow

**What happens on deployment:**

1. NixOS builds the system with Incus module
2. `incus.service` starts → `incusd` daemon runs
3. `incus-preseed.service` starts → applies preseed YAML
4. Preseed creates: storage pool, network, default profile
5. Incus is now ready for use (standalone mode)

**What you do manually (one-time):**

1. On tomato: `incus cluster enable tomato` (converts to cluster)
2. On tomato: `incus cluster add pickle` (generate token)
3. On pickle: `incus admin init` (join with token)

**Why manual clustering is required:**

Per official Incus documentation, preseed cannot configure cluster formation.
The NixOS preseed handles infrastructure setup, but cluster topology requires
interactive configuration to ensure proper member initialization and token
exchange.

## Useful Commands

```bash
# Storage
incus storage list
incus storage show default
incus storage info default

# Networks
incus network list
incus network show incusbr0
incus network info incusbr0

# Profiles
incus profile list
incus profile show default

# Cluster
incus cluster list
incus cluster show tomato

# System
incus info
incus info --resources
```

## References

- [Incus Official Documentation](https://linuxcontainers.org/incus/docs/)
- [Incus Initialize (Preseed)](https://linuxcontainers.org/incus/docs/main/howto/initialize/)
- [Incus Clustering](https://linuxcontainers.org/incus/docs/main/howto/cluster_form/)
- [NixOS Wiki - Incus](https://wiki.nixos.org/wiki/Incus)
- [NixOS Incus Module Source](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/incus.nix)
- [Rocky's Guide](https://blog.hetherington.uk/2025/01/setting-up-incus-with-zfs-on-nixos/)
