# Cachix Deploy operations

The flake deploys the integrated system and Home Manager closures for `beefy`,
`ghost`, `muscle`, `potato`, `spark`, and `timey`. `vasyl` remains part of
`spark`'s atomic microVM closure. Installer outputs, `timey`'s SD-image artifact,
and standalone Home Manager outputs do not run agents. NixOS agents own the
`system` profile; Darwin agents explicitly own `system-profiles/system`.

## One-time setup

1. In Cachix, create a workspace backed by the `land` cache.
2. Generate a separate agent token for each configured agent name.
3. Apply the new NixOS or nix-darwin configuration once through the existing
   local provisioning path.
4. Provision the token on each host. Do not store it in this repository.

On NixOS, install a root-only token at
`/var/lib/cachix-deploy/agent.token`:

```bash
sudo install -d -o root -g root -m 0700 /var/lib/cachix-deploy
read -r -s CACHIX_AGENT_TOKEN
printf 'CACHIX_AGENT_TOKEN=%s\n' "$CACHIX_AGENT_TOKEN" |
  sudo install -o root -g root -m 0600 /dev/stdin \
    /var/lib/cachix-deploy/agent.token
unset CACHIX_AGENT_TOKEN
sudo systemctl restart cachix-agent
```

On nix-darwin, install a root-only token at
`/var/db/cachix-deploy/agent.token`:

```bash
sudo install -d -o root -g wheel -m 0700 /var/db/cachix-deploy
read -r -s CACHIX_AGENT_TOKEN
printf 'CACHIX_AGENT_TOKEN=%s\n' "$CACHIX_AGENT_TOKEN" |
  sudo install -o root -g wheel -m 0600 /dev/stdin \
    /var/db/cachix-deploy/agent.token
unset CACHIX_AGENT_TOKEN
sudo launchctl kickstart -k system/org.nixos.cachix-agent
```

The services refuse missing, malformed, or incorrectly owned token files. They
do not block boot and retry after provisioning. Agents need outbound HTTPS and
WebSocket access to Cachix plus access to `land.cachix.org`; no inbound firewall
port is required.

Check an agent with:

```bash
# NixOS
systemctl status cachix-agent
journalctl -u cachix-agent

# nix-darwin
sudo launchctl print system/org.nixos.cachix-agent
tail -f /var/log/cachix-agent.log
```

Confirm that every configured name appears online in the workspace before the
first activation.

## GitHub setup and workflow contract

Create a protected GitHub environment named `cachix-deploy`, optionally with
required reviewers, and add:

- `CACHIX_AUTH_TOKEN`: write access to the `land` binary cache.
- `CACHIX_ACTIVATE_TOKEN`: the workspace token created by **Start a
  Deployment**.

Agent tokens never belong in GitHub Actions.

`.github/workflows/deploy.yml` accepts only the current default-branch commit
after a successful `ci` workflow triggered by a push. The `ci` workflow must
build every declared closure and push it to `land`; deployment independently
realizes the generated specification and pushes its full closure before
activation. Keep the workflow name `ci` or update the deploy trigger with it.

Manual dispatch defaults to plan-only. The plan builds the same specification,
validates its agent coverage, and prints store paths and rollout stages without
calling `cachix deploy activate`. A manual activation is restricted to the
current default-branch commit and requires a successful `ci` push run for the
same commit.

Inspect the canonical rollout without activating:

```bash
nix eval --json --file nix/deploy/default.nix rollout | jq
```

Stages run synchronously and stop on the first failure. `spark` and `muscle`
remain in separate stages.

## Rollback, reboot, and disabling

After activation, Cachix reactivates the exact previous profile if its backend
connectivity check or a configured rollback script fails. The specification
does not add a generic rollback script: these heterogeneous hosts do not share
a health check that is both meaningful and safe from false rollbacks.
Activation-command failures are reported but are not covered by that
post-activation rollback path.

For an operator rollback, revert the bad default-branch commit and let CI
produce and deploy the previous state. If remote deployment is unavailable,
use the host's normal generation rollback (`nixos-rebuild switch --rollback`
or `darwin-rebuild --rollback`) from an administrative session.

NixOS activation uses `switch`. A new kernel becomes the selected boot
generation but cannot replace the running kernel; schedule a reboot when
`/run/current-system/kernel` differs from `/run/booted-system/kernel`. Cachix
Deploy does not reboot hosts.

To disable an agent, set `modules.cachix-deploy.enable = false`, apply that
configuration, stop the old service, remove its token file, and revoke the
agent token in the Cachix workspace:

```bash
# NixOS
sudo systemctl disable --now cachix-agent
sudo rm -f /var/lib/cachix-deploy/agent.token

# nix-darwin
sudo launchctl bootout system/org.nixos.cachix-agent
sudo rm -f /var/db/cachix-deploy/agent.token
```
