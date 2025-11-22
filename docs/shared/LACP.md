# LACP Bonding Setup Guide

## Overview

This guide covers setting up LACP (802.3ad) bonding
on tomato and pickle with UniFi switches.

**Hardware:**

- MS-01 systems with Intel X710 dual 10GbE NICs
- UniFi switches with LACP support

**Result:**

- 20Gbps aggregate bandwidth per system
- Automatic failover if one link fails
- DHCP-based addressing

## UniFi Switch Configuration

### Prerequisites

1. Identify which switch ports connect to each system
2. Ensure cables are connected to **consecutive ports** (e.g., ports 1-2, 3-4)

### Steps

#### 1. Access UniFi Controller

- Navigate to your UniFi Network Controller
- Go to **Devices** → Select your switch

#### 2. Configure Link Aggregation for Tomato

1. In the switch details, find the ports connected to tomato
2. Select both ports (e.g., ports 1 and 2)
3. Click **Port Settings** → **Aggregate Ports**
4. Set **Aggregation Protocol** to LACP (802.3ad)
5. Create new or select existing **Link Aggregation Group (LAG)**
6. Click **Apply**

#### 3. Configure Link Aggregation for Pickle

1. Repeat the above for pickle's ports (e.g., ports 3 and 4)
2. Use the same settings: LACP (802.3ad)

#### 4. Provision Switch

- Click **Provision** or **Apply Changes**
- Wait for the switch to reconfigure (~30 seconds)

### Verification on Switch

- Ports should show as **Aggregated** in the UniFi Controller
- Port status may show "Waiting for LACP" until NixOS is deployed

## NixOS Deployment

### Phase 1: Deploy to Tomato (Test)

```bash
# From your development machine
nix develop
deploy .#tomato
```

**Expected behavior:**

- Network will disconnect briefly during switch
- System will reconnect via bond0 with new DHCP IP
- May need to update SSH known_hosts if IP changes

### Phase 2: Verify Tomato

SSH to tomato (you may need to find new IP from your router/UniFi
Controller):

```bash
# Check bond status
cat /proc/net/bonding/bond0

# Expected output:
# Bonding Mode: IEEE 802.3ad Dynamic link aggregation
# Transmit Hash Policy: layer3+4 (1)
# MII Status: up
# MII Polling Interval (ms): 100
# Up Delay (ms): 200
# Down Delay (ms): 200
# LACP rate: fast

# Check bond speed (should be 20000Mb/s)
ethtool bond0 | grep Speed
# Expected: Speed: 20000Mb/s

# Check member interfaces
ip link show type bond_slave

# Check DHCP-assigned IP
ip addr show bond0
```

### Phase 3: Deploy to Pickle

Once tomato is verified working:

```bash
deploy .#pickle
```

Repeat verification steps above.

## Troubleshooting

### Bond Not Coming Up

```bash
# Check systemd-networkd status
systemctl status systemd-networkd

# View networkd logs
journalctl -u systemd-networkd -f

# Check if bonding module is loaded
lsmod | grep bonding

# Manually check interface status
ip link show
```

### LACP Not Negotiating

**Verify switch configuration:**

- Check UniFi Controller shows ports as "Aggregated"
- Verify LACP (802.3ad) mode is selected, not static LAG

**Check cable connections:**

- Ensure both cables are connected
- Verify they're in consecutive ports on switch

**View LACP details:**

```bash
cat /proc/net/bonding/bond0
# Look for "Aggregator ID" - should be same on both slaves
```

### Network Unreachable After Deploy

If you lose connectivity:

**Console access:**

- Use IPMI/iKVM if available
- Physical console access

**Check bond status:**

```bash
ip addr show bond0
# Should have an IP address

cat /proc/net/bonding/bond0
# Both slaves should be "up"
```

**Rollback if needed:**

```bash
# From console on the affected system
nixos-rebuild switch --rollback
```

## Performance Testing

### Test Aggregate Bandwidth

```bash
# Install iperf3
nix-shell -p iperf3

# On tomato:
iperf3 -s

# On pickle:
iperf3 -c tomato.0x77.computer -P 4 -t 30

# Expected: ~18-20 Gbps aggregate
```

### Test Failover

```bash
# On one system, watch bond status:
watch -n 1 'cat /proc/net/bonding/bond0 | grep -A 5 "Slave Interface"'

# On UniFi Controller:
# - Disable one port in the LAG
# - Traffic should continue on remaining link
# - Re-enable port, should rejoin automatically
```

## Monitoring

### Ongoing Bond Health Checks

```bash
# Check bond status
cat /proc/net/bonding/bond0

# Check for interface errors
ethtool -S enp2s0f0np0 | grep -i error
ethtool -S enp2s0f1np1 | grep -i error

# Check bond interface statistics
ip -s link show bond0
```

### Add to System Monitoring

Consider adding these checks to your monitoring system:

- Bond interface up/down status
- Individual slave interface status
- LACP negotiation state
- Aggregate bandwidth utilization

## Rollback Plan

If issues occur:

**Git revert:**

```bash
git revert HEAD
deploy .#tomato
deploy .#pickle
```

**Switch will automatically fall back:**

- UniFi switch will detect LACP failure
- Individual ports will continue to work
- Remove LAG configuration from UniFi Controller

**Manual recovery:**

```bash
# On affected system via console
nixos-rebuild switch --rollback
```

## Notes

- **DHCP Reservations:** Consider creating DHCP reservations in UniFi for
  consistent IPs
- **DNS:** Update any hardcoded IP references to use hostnames
  (tomato.0x77.computer)
- **Testing:** Always test on tomato first before deploying to pickle
