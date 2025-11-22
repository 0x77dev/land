# Incus Cluster Reset and Clean Deployment

## Steps to Reset and Redeploy

### 1. Stop Incus on Both Systems

```bash
# On tomato
ssh mykhailo@tomato.0x77.computer
sudo systemctl stop incus incus-preseed incus-user

# On pickle
ssh mykhailo@pickle.0x77.computer
sudo systemctl stop incus incus-preseed incus-user
```

### 2. Remove All Incus State

```bash
# On BOTH tomato and pickle
sudo rm -rf /var/lib/incus/database
sudo rm -rf /var/lib/incus/*.crt
sudo rm -rf /var/lib/incus/*.key
sudo rm -rf /var/lib/incus/server.yaml

# Keep ZFS datasets but clear Incus metadata
# The preseed will recreate the storage pool configuration
```

### 3. Deploy Updated Configuration

```bash
# From your development machine
cd /Users/0x77/Projects/land
deploy .#tomato
deploy .#pickle
```

### 4. Verify Preseed Created Resources

```bash
# On tomato
ssh mykhailo@tomato.0x77.computer

# Check preseed service succeeded
sudo journalctl -u incus-preseed -e

# Verify resources were created
incus storage list      # Should show "default" (ZFS)
incus network list      # Should show "incusbr0" (managed bridge)
incus profile show default  # Should have root disk and eth0 network

# Repeat verification on pickle
```

### 5. Form Fresh Cluster

**On tomato - Enable clustering:**

```bash
ssh mykhailo@tomato.0x77.computer

# Convert to cluster mode
sudo incus cluster enable tomato

# Verify
sudo incus cluster list
# Should show only tomato as database-leader
```

**On tomato - Generate join token for pickle:**

```bash
sudo incus cluster add pickle
# Copy the entire token output
```

**On pickle - Join the cluster:**

```bash
ssh mykhailo@pickle.0x77.computer

sudo incus admin init
```

Answer the prompts:

```text
Would you like to use clustering? yes
What IP address or DNS name should be used? [press Enter for default]
Are you joining an existing cluster? yes
Do you have a join token? yes
Please provide join token: <paste token from tomato>
All existing data is lost when joining a cluster, continue? yes
Choose "source" property for storage pool "default": [press Enter]
Choose "zfs.pool_name" property for storage pool "default": [press Enter]
```

### 6. Verify Cluster is Healthy

```bash
# On either system
incus cluster list

# Both should show ONLINE
# +--------+-------------------------+------------------+-------+--------+
# | NAME   | URL                     | ROLES            | STATE | ...    |
# +--------+-------------------------+------------------+-------+--------+
# | tomato | https://...             | database-leader  | ONLINE| ...    |
# | pickle | https://...             | database-standby | ONLINE| ...    |
# +--------+-------------------------+------------------+-------+--------+
```

### 7. Test Container Launch

```bash
# Should work now
incus launch images:alpine/edge test1
incus list

# Test launching on specific target
incus launch images:nixos/24.05 nixos --target pickle
incus list
```

## Why This Works

1. **Clean slate:** Removing Incus state ensures no conflicts
2. **Preseed creates infrastructure:** Storage, network, profile all declarative
3. **Manual clustering:** Cluster formation happens after preseed completes
4. **No conflicts:** Fresh deployment with fresh cluster formation

## If Something Goes Wrong

### Preseed fails

```bash
# Check logs
sudo journalctl -u incus-preseed -e

# Manually trigger preseed
sudo systemctl restart incus-preseed
```

### Storage pool creation fails

The ZFS datasets already exist, which is fine. Preseed should detect them.
If it fails, the datasets are already there from previous setup.

### Cluster join fails

Make sure both systems can reach each other:

```bash
# From pickle
curl -k https://tomato.0x77.computer:8443
# Should return connection or certificate error (not timeout)

# Check bond0 has IPs
ip addr show bond0
```

## After Successful Cluster Formation

Once the cluster is healthy, you can **disable preseed** to prevent future
conflicts:

Edit both system configs to set `usePreseed = false`, then redeploy. This
prevents preseed from interfering with the running cluster during future
deployments.
