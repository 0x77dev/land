# Incus Cluster Setup on NixOS

## Overview

This guide covers setting up an Incus cluster on tomato and pickle after the
simplified preseed configuration (storage-only).

**Based on research:**

- [Rocky Hetherington's NixOS Incus guide](https://blog.hetherington.uk/2025/01/setting-up-incus-with-zfs-on-nixos/)
- [NixOS Wiki - Incus](https://wiki.nixos.org/wiki/Incus)
- [Incus Official Docs - Clustering](https://linuxcontainers.org/incus/docs/main/howto/cluster_form/)

## Current NixOS Configuration

The NixOS module pre-configures:

- ✅ ZFS storage pool (`zroot/incus`)
- ✅ Incus daemon enabled
- ✅ Web UI enabled
- ✅ Firewall rules (port 8443, incusbr0 trusted)
- ❌ Networks (created manually during init)
- ❌ Clustering (configured manually during init)

## Initial Setup on Tomato (Bootstrap)

```bash
ssh tomato
sudo incus admin init
```

**Answer the prompts:**

```text
Would you like to use clustering? yes
What IP address or DNS name should be used? 192.168.0.66  # tomato's IP
Are you joining an existing cluster? no
What member name should be used? tomato
Do you want to configure a new local storage pool? no  # Already configured
Do you want to configure a new remote storage pool? no
Would you like to use an existing bridge or host interface? no
Would you like to create a new Fan overlay network? no
Would you like to create a new bridge? yes
What should the new bridge be called? incusbr0
What IPv4 address should be used? 10.10.10.1/24  # Or press Enter for default
What IPv6 address should be used? none
```

**Verify:**

```bash
sudo incus cluster list
# Should show only tomato

sudo incus network list
# Should show incusbr0

sudo incus storage list
# Should show default (ZFS)
```

## Join Pickle to Cluster

### On Tomato - Generate Join Token

```bash
sudo incus cluster add pickle
```

Copy the token that's printed.

### On Pickle - Join Cluster

```bash
ssh pickle
sudo incus admin init
```

**Answer the prompts:**

```text
Would you like to use clustering? yes
What IP address or DNS name should be used? 192.168.0.X  # pickle's IP
Are you joining an existing cluster? yes
Join token: <paste token from tomato>
All existing data is lost when joining a cluster, continue? yes
Choose "zroot/incus" as source? yes
```

## Verify Cluster

```bash
# On either tomato or pickle
sudo incus cluster list
```

**Expected output:**

```text
+--------+-------------------------+-----------+--------+-------------------+
| NAME   | URL                     | ROLES     | STATE  | MESSAGE           |
+--------+-------------------------+-----------+--------+-------------------+
| tomato | https://192.168.0.66:.. | database  | ONLINE | Fully operational |
| pickle | https://192.168.0.X:... | database  | ONLINE | Fully operational |
+--------+-------------------------+-----------+--------+-------------------+
```

## Test the Cluster

```bash
# Launch a test container
incus launch images:alpine/edge test1

# Check it's running
incus list

# Launch on specific node
incus launch images:nixos/24.05 nixos-test --target pickle

# Verify both nodes have containers
incus list

# Access web UI
# https://tomato.0x77.computer:8443 or https://<tomato-ip>:8443
```

## Common Issues

### "Network doesn't exist" during init

This is expected - you're creating it during init. Answer "yes" to create a
new bridge.

### Cluster members can't communicate

- Verify bond0 has IPs on both systems: `ip addr show bond0`
- Check firewall allows 8443: `sudo ss -tlnp | grep 8443`
- Verify nftables is enabled: `sudo nft list ruleset | grep incusbr0`

### Storage pool not found during join

The join process should detect the ZFS dataset automatically. If not, specify
`zroot/incus` when prompted.

## Advanced: Using Hostnames

If you've configured DNS records or DHCP reservations:

```bash
# During init, use hostname instead of IP
What IP address or DNS name should be used? tomato.0x77.computer
```

This makes cluster more resilient to IP changes.

## Useful Commands

```bash
# View cluster status
incus cluster list

# View cluster members details
incus cluster show tomato

# List all storage pools
incus storage list

# List all networks
incus network list

# View network details
incus network show incusbr0

# List profiles
incus profile list

# Show default profile
incus profile show default
```

## Resources

- [Incus Official Docs](https://linuxcontainers.org/incus/docs/)
- [NixOS Wiki - Incus](https://wiki.nixos.org/wiki/Incus)
- [Rocky's NixOS Incus Guide](https://blog.hetherington.uk/2025/01/setting-up-incus-with-zfs-on-nixos/)
