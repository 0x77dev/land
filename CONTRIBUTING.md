---
alwaysApply: true
---

# Contributing

This repository uses [Snowfall Lib] to manage Nix configurations
for NixOS and Darwin systems.

## Structure

The repository follows [Snowfall Lib]'s conventional directory structure:

```tree
nix/
├── lib/              # Custom library functions
├── modules/          # NixOS and Darwin modules
│   ├── darwin/       # Darwin-specific modules
│   └── nixos/        # NixOS-specific modules
├── overlays/         # Package overlays
├── packages/         # Custom packages
├── shells/           # Development shells
└── systems/          # System configurations
    └── aarch64-darwin/
    └── [arch]/
```

## Channels

This flake uses two nixpkgs channels:

- **nixpkgs** (nixos-25.05): Stable channel for primary packages
- **unstable** (nixpkgs-unstable): Rolling release for bleeding-edge packages

## Overlays

### Unstable Overlay

Packages from the unstable channel should be added to
`nix/overlays/unstable/default.nix` using the `inherit` keyword:

```nix
{ channels, ... }:
final: prev:
{
  inherit (channels.unstable)
    ghostty
    # Add more unstable packages here
    ;
}
```

This makes unstable packages available throughout the configuration
via `pkgs.ghostty` without explicitly prefixing with a namespace.

### Custom Overlays

Create new overlays in `nix/overlays/<name>/default.nix`.
Each overlay follows the pattern:

```nix
{ channels, ... }:
final: prev:
{
  # Your overlay definitions
}
```

## Modules

Modules are automatically loaded based on the platform:

- Darwin modules: `nix/modules/darwin/<name>/default.nix`
- NixOS modules: `nix/modules/nixos/<name>/default.nix`

All modules are automatically applied to matching system types.

## Library Functions

Custom library functions should be placed in `nix/lib/`
and will be available under the `land` namespace as `lib.land.<function-name>`.

## Adding Packages

1. For custom packages, create a directory in `nix/packages/<name>/default.nix`
2. For packages from unstable, add them to the unstable overlay
3. Packages are automatically exported and available in all configurations

## Verified Auto-Updates

Verifies commit signatures before updating system. Stages updates for next boot.

### Configuration

```nix
# Minimal configuration (uses defaults from lib.land.shared.verified-auto-update)
services.verified-auto-update.enable = true;

# Custom configuration (override defaults if needed)
services.verified-auto-update = {
  enable = true;
  flakeUrl = "github:your-org/your-repo";  # Optional: override default
  allowedGpgKey = "YOUR_GPG_KEY";  # Optional: override default
  allowedWorkflowRepository = "your-org/your-repo";  # Optional: override default

  # Darwin: override schedule (default: 3 AM, 9 AM, 3 PM, 9 PM)
  schedule = [{ Hour = 3; Minute = 0; }];

  # NixOS: override schedule (default: "*-*-* 03,09,15,21:00:00")
  schedule = "03:00";
  randomizedDelaySec = "1h";
};
```

Defaults are configured in `nix/lib/shared/verified-auto-update/default.nix`.

### Testing

```bash
FLAKE_URL="github:0x77dev/land" \
ALLOWED_WORKFLOW_REPOSITORY="0x77dev/land" \
DRY_RUN="true" \
nix run .#verify-and-update
```

### Monitoring

- **Darwin:** `tail -f /var/log/verified-auto-update.log`
- **NixOS:** `journalctl -u verified-auto-update -f`

## Secrets Management

This repository uses [sops-nix](https://github.com/Mic92/sops-nix)
for declarative secret management.

### Quick Start

sops-nix automatically uses SSH host keys - no manual key generation needed!

1. **Get your system's SSH host keys** (as age format):

```bash
# For potato (Darwin - local)
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# For muscle (NixOS - remote)
nix-shell -p ssh-to-age --run 'ssh-keyscan muscle.local | ssh-to-age'

# Or if using IP address
nix-shell -p ssh-to-age --run 'ssh-keyscan 192.168.1.100 | ssh-to-age'

   # Or via SSH
   nix-shell -p ssh-to-age --run \
     "ssh muscle 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age"
```

1. **Update `.sops.yaml`** with the age public keys from step 1:

   ```yaml
   keys:
     # Admin GPG key
     - &admin_mykhailo C33BFD3230B660CF147762D2BF5C81B531164955

     # System SSH host keys converted to age
     - &potato age1xxx...  # Replace with actual key from step 1
     - &muscle age1yyy...  # Replace with actual key from step 1

   creation_rules:
     - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
       key_groups:
       - pgp:
         - *admin_mykhailo
         age:
         - *potato
         - *muscle
   ```

   **Note:** Don't include a `-` before `age` under `key_groups`,
   otherwise sops will require multiple keys (Shamir secret sharing) to
   decrypt.

1. **Create and edit secrets**:

   ```bash
   # Create a new secret file
   nix-shell -p sops --run "sops secrets/example.yaml"

   # Update keys when adding new hosts
   nix-shell -p sops --run "sops updatekeys secrets/example.yaml"
   ```

1. **Use secrets in configuration**:

```nix
{
  # System-level secrets (SSH host keys used automatically)
  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets.example-key = {
    owner = "myuser";
    mode = "0400";
  };

  # Use in services
  systemd.services.myservice.serviceConfig.EnvironmentFile = config.sops.secrets.example-key.path;
}
```

### Home Manager Secrets

Secrets can also be managed per-user via home-manager (uses system SSH keys automatically):

```nix
{
  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets.personal-token = {
    path = "%r/personal-token"; # %r = runtime directory
  };
}
```

### Best Practices

- Store secrets in `secrets/` directory at repository root
- Use SSH host keys (automatic, no manual setup required!)
- Use GPG for admin/personal keys
- Rotate secrets regularly
- Use different secret files for different environments/hosts
- Keep `.sops.yaml` in version control
- Never commit unencrypted secrets
- Use templates for config files that need embedded secrets
- A git hook (`trufflehog`) scans for accidentally committed secrets

## Documentation Standards

### Single Source of Truth

**Never duplicate information.** Each piece of information must exist in
exactly one canonical location:

- **README.md** - Project overview, quick start, philosophy
- **CONTRIBUTING.md** - Development workflow, structure, contribution guidelines
- **Code comments** - Implementation details, "why" not "how"
- **Module files** - Self-documenting through clear names and structure

### Documentation Update Requirements

**All changes that affect user-facing behavior MUST update documentation before merge:**

1. **Code changes** - Update affected documentation in the same commit
2. **New features** - Add to README.md features list if user-visible
3. **Structure changes** - Update CONTRIBUTING.md structure section
4. **New dependencies** - Document in README.md Technology Stack
5. **Breaking changes** - Update Quick Start section with migration notes

**Violation of this requirement will result in PR rejection.**

### Minimalism Principle

Documentation should be:

- **Essential only** - If users can figure it out from code/types,
  don't document it
- **Actionable** - Every sentence must serve a purpose
- **Tested** - All commands and examples must be verified before commit
- **Current** - Delete outdated docs immediately, don't mark as deprecated

### When to Document

Document when:

- Behavior is non-obvious from code
- Design decisions need rationale
- External integrations require setup
- Security implications exist

Don't document:

- Self-evident code (well-named functions don't need comments)
- Temporary workarounds (fix the code instead)
- Implementation details that change frequently
- Information derivable from types or signatures

## Code Style

See [nixpkgs formatting guidelines][nixpkgs-style] for comprehensive
style rules.

Project-specific requirements:

- 2-space indentation (enforced by `nixfmt-rfc-style`)
- Verb-first function naming: `mkPackage`, `buildConfig`
- Use `lib.land` namespace for custom functions
- Modules named by concern, not implementation

[Snowfall Lib]: /.cursor/rules/snowfall.mdc
[nixpkgs-style]: https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md
