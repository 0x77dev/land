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

## Best Practices

### Nix Language

#### Avoid `rec`

Never use recursive attribute sets. They cause hard-to-debug infinite recursion errors.

```nix
# Bad
rec {
  a = 1;
  b = a + 2;
}

# Good
let
  a = 1;
in {
  inherit a;
  b = a + 2;
}
```

For self-reference, explicitly name the attribute set:

```nix
let
  argset = {
    a = 1;
    b = argset.a + 2;
  };
in
  argset
```

#### Minimize `with` Scope

Avoid `with` at top-level or with large scopes. It hinders static analysis
and makes code harder to understand.

```nix
# Bad - brings everything into scope
with pkgs;
stdenv.mkDerivation {
  buildInputs = [ openssl libX11 ];
}

# Good - explicit
stdenv.mkDerivation {
  buildInputs = [ pkgs.openssl pkgs.xorg.libX11 ];
}

# Acceptable - limited scope
stdenv.mkDerivation {
  buildInputs = [ pkgs.openssl ]
    ++ (with pkgs.xorg; [ libX11 libXrandr xinput ]);
}
```

#### Always Quote URLs

Bare URLs are deprecated and will be removed.

```nix
# Bad
src = https://example.com/file.tar.gz;

# Good
src = "https://example.com/file.tar.gz";
```

#### Use `inherit` for Clarity

Use `inherit` to reduce duplication and improve readability.

```nix
# Bad
{
  foo = pkgs.foo;
  bar = pkgs.bar;
  baz = pkgs.baz;
}

# Good
{
  inherit (pkgs) foo bar baz;
}
```

### Performance & Lazy Evaluation

#### Leverage Laziness

Nix evaluates expressions lazily. Structure code to delay expensive computations.

```nix
# Good - only evaluated if condition is true
result = if condition then expensiveComputation else default;
```

#### Avoid Unnecessary Strictness

Don't force evaluation of unused values with `builtins.seq` or `builtins.deepSeq`
unless necessary for performance profiling.

#### Minimize Thunk Chains

Deeply nested thunks can cause stack overflows. Break complex expressions
into intermediate bindings.

```nix
# Better
let
  step1 = computeFirst args;
  step2 = processData step1;
  step3 = finalTransform step2;
in
  step3
```

### Module System

#### Use mkIf for Conditional Configuration

```nix
{
  config = lib.mkIf cfg.enable {
    services.myservice = {
      # configuration
    };
  };
}
```

#### Use mkDefault for Overridable Defaults

```nix
{
  config.services.myservice.port = lib.mkDefault 8080;
}
```

#### Properly Type Options

```nix
options.myservice = {
  enable = lib.mkEnableOption "myservice";

  port = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = "Port for the service";
  };

  extraConfig = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Additional configuration";
  };
};
```

#### Use assertions for Invariants

```nix
{
  config = {
    assertions = [
      {
        assertion = cfg.enable -> cfg.dataDir != null;
        message = "dataDir must be set when service is enabled";
      }
    ];
  };
}
```

### Package & Derivation Practices

#### Use `pname` and `version`

Separate `pname` and `version` instead of combined `name`.

```nix
# Good
stdenv.mkDerivation {
  pname = "package";
  version = "1.2.3";
  src = fetchurl {
    url = "https://example.com/package-${version}.tar.gz";
    hash = "sha256-...";
  };
}
```

#### Proper Meta Attributes

```nix
meta = with lib; {
  description = "A concise description without package name";
  longDescription = ''
    Detailed multi-line description in CommonMark.
  '';
  homepage = "https://example.com";
  license = licenses.mit;
  maintainers = with maintainers; [ username ];
  platforms = platforms.unix;
};
```

#### Use `passthru` for Related Information

```nix
passthru = {
  tests = {
    simple = callPackage ./test.nix {};
  };
  updateScript = ./update.sh;
};
```

### Composition & Overrides

#### Prefer `override` for Function Arguments

```nix
# Override function arguments
myPackage.override {
  enableFeature = true;
  customDep = alternativeDep;
}
```

#### Use `overrideAttrs` for Derivation Attributes

```nix
# Modify derivation attributes
myPackage.overrideAttrs (finalAttrs: previousAttrs: {
  buildInputs = previousAttrs.buildInputs ++ [ extraDep ];
})
```

#### Use finalAttrs Pattern for Self-Reference

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "mypackage";
  version = "1.0";

  src = fetchurl {
    url = "https://example.com/${finalAttrs.pname}-${finalAttrs.version}.tar.gz";
    hash = "sha256-...";
  };
})
```

### Code Organization

#### One Concern Per Module

Keep modules focused on a single concern. Split large modules into smaller,
composable units.

#### Use Let-Bindings for Complex Expressions

```nix
let
  cfg = config.services.myservice;
  dataDir = "/var/lib/myservice";
  configFile = pkgs.writeText "config.yml" (generators.toYAML {} cfg.config);
in
{
  # Use the bindings
}
```

#### Group Related Options

```nix
options.services.myservice = {
  enable = lib.mkEnableOption "myservice";

  network = {
    port = lib.mkOption { /* ... */ };
    host = lib.mkOption { /* ... */ };
  };

  storage = {
    dataDir = lib.mkOption { /* ... */ };
    maxSize = lib.mkOption { /* ... */ };
  };
};
```

### Error Handling

#### Use Assertions with Clear Messages

```nix
assert lib.assertMsg (cfg.mode == "standalone" || cfg.peers != [])
  "Peers must be specified in distributed mode";
```

#### Validate Early

```nix
config = lib.mkIf cfg.enable (
  lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.database.host != "";
          message = "database.host cannot be empty";
        }
      ];
    }
    {
      # actual configuration
    }
  ]
);
```

### Reproducibility

#### Pin All Dependencies

Use flake.lock to pin dependencies. Never use `<nixpkgs>` in flakes.

#### Specify Hashes Correctly

Always use SRI hashes (sha256-...) for new code.

```nix
src = fetchurl {
  url = "https://example.com/file.tar.gz";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
};
```

#### Invalidate Hashes When Updating

Set hash to empty string to get the new hash when updating versions.

### Documentation

#### Write Clear Option Descriptions

Use imperative voice. Be concise. Don't repeat the option name.

```nix
# Bad
description = "This option enables the debug mode for myservice";

# Good
description = "Enable debug mode";
```

#### Document Complex Logic

```nix
# Calculate optimal worker count based on available cores
# Reserve 2 cores for system tasks
workerCount = lib.max 1 (config.nix.settings.cores - 2);
```

### Security

#### Use Sandboxed Builds

Enable sandbox in nix.conf (default in NixOS).

#### Minimize Build Dependencies

Only include necessary buildInputs and nativeBuildInputs.

#### Validate Untrusted Input

```nix
let
  sanitizedPath = lib.strings.escapeShellArg userProvidedPath;
in
  "echo ${sanitizedPath}"
```

### Testing & Validation

#### Verify Changes

```bash
# Quick check
nix flake check

# Comprehensive validation
nix flake check --all-systems

# Build specific outputs
nix build .#packages.aarch64-darwin.mypackage
```

#### Test in REPL

```bash
nix repl
:lf .
:p darwinConfigurations.potato.config.nix.package
```

#### Write Integration Tests

Use NixOS test framework for testing services and interactions.

### Common Pitfalls

#### Infinite Recursion

Usually caused by `rec`, improper overlay composition, or circular module dependencies.
Use `--show-trace` to debug.

#### Hash Mismatch

When updating package versions, always invalidate the hash first.

#### Type Errors

Use proper types in module options. `lib.types.str` for strings,
`lib.types.int` for integers, etc.

#### Over-using `with`

Limit `with` to small, well-defined scopes. Never use at module top-level.

#### Forgotten `inherit`

Use `inherit` to avoid duplication and reduce noise.

## Code Style

### Formatting

- Use 2-space indentation (never tabs)
- Follow RFC 166 formatting standard (nixfmt-rfc-style)
- Keep line length reasonable (no hard limit, but aim for < 100)
- Place opening braces on same line
- Use trailing semicolons consistently

### Naming Conventions

- **Functions**: Use verb-first naming (e.g., `mkPackage`, `buildConfig`)
- **Options**: Use descriptive nouns (e.g., `dataDir`, `enableFeature`)
- **Variables**: Use camelCase for locals, kebab-case for attributes
- **Builders**: Prefix with `mk` (e.g., `mkDerivation`, `mkOption`)
- **Recursive functions**: Name as `go` to signal recursion

### Indentation Rules

- Increase indentation by one level maximum per construct
- Align function arguments vertically when split across lines
- Keep attribute sets aligned

```nix
# Good
stdenv.mkDerivation {
  pname = "example";
  version = "1.0";

  buildInputs = [
    pkg1
    pkg2
  ];
}
```

### Function Signatures

```nix
# Good - clear, typed arguments
{
  lib,
  stdenv,
  fetchFromGitHub,
  enableFeature ? false,
}:

# Avoid - implicit dependencies
args: with args; <...>
```

### Attribute Set Manipulation

Use lib functions for transformations:

- `lib.mapAttrs` - Transform attribute values
- `lib.filterAttrs` - Filter attributes by predicate
- `lib.optionalAttrs` - Conditionally include attributes
- `lib.recursiveUpdate` - Deep merge attribute sets

### String Handling

- Use `${}` for interpolation
- Escape `${` as `\${` in regular strings or `''${` in indented strings
- Use indented strings for multi-line content
- Avoid string concatenation with `+`, prefer interpolation

### List Operations

- `map` for transformations
- `filter` for filtering
- `lib.foldl'` for reduction (strict, more efficient)
- `lib.concatMap` for flattening mapped results
- `lib.optional` for conditional single elements
- `lib.optionals` for conditional lists

## Design Principles

### Purity

Functions must be pure - same inputs always produce same outputs.
No side effects, no implicit dependencies.

### Composability

Design functions and modules to compose cleanly. Avoid tight coupling.
Use dependency injection via function arguments.

### Explicitness

Make dependencies and behavior explicit. Avoid magic or implicit behavior.
Code should be self-documenting.

### Minimalism

Include only what's necessary. Avoid premature abstraction.
Prefer simple, direct solutions.

### Locality of Behavior

Keep related code together. Put configuration near where it's used.
Minimize indirection.

[Snowfall Lib]: /.cursor/rules/snowfall.mdc
