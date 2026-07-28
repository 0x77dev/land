# zmx operations

[zmx](https://zmx.sh) provides persistent terminal sessions using
`libghostty-vt`. A session can detach and later attach from another client;
multiple clients can attach to the same session at once and retain native
scrollback. zmx deliberately has no windows, tabs, or splits: the OS window
manager owns layout, with one terminal window per zmx session.

The flake promotes zmx 0.6.x from `nixpkgs-unstable` through
`nix/overlays/unstable`.

## Configuration surface

Home Manager exposes `modules.home.zmx`:

- `enable`
- `package`
- `picker.enable`
- `hint.enable`
- `prompt.enable`
- `remotes.<p> = { hostname, user, forwardAgent, forwardGpg, settings; }`

`modules.zmx` on NixOS provides `enable` and `users`. Enabling it installs the
system package and keeps the listed users lingering. `modules.zmx` on
nix-darwin provides `enable`, which installs the system package.

The shared Home Manager configuration in `nix/lib/shared/home-config/default.nix`
enables zmx by default and derives these remote prefixes from
`nix/lib/shared/machines`, filtered on `sshTarget`:

- `m`: `muscle.osv.computer`
- `s`: `spark.osv.computer`
- `b`: `beefy.0x77.computer`
- `g`: `ghost.0x77.computer`
- `t`: `timey.0x77.computer`

## Daily workflow

Connect through an alias such as `m.dev`:

```bash
ssh m.dev
```

Its `RemoteCommand` is `zmx attach %k`, so this creates or attaches the
`m.dev` session on `muscle`. The SSH alias is the session name, shared by every
client machine. Open one terminal window for each session; opening the same
alias elsewhere joins it as another client.

SSH multiplexes the connection with `ControlMaster auto`,
`ControlPath ~/.ssh/cm-%C`, and `ControlPersist 10m`, so sessions share one TCP
connection. For an automatically reconnecting connection, use:

```bash
ash m.dev
```

`ash` runs `autossh -M 0 -q`. Detach with Ctrl+Backslash or by closing the
terminal window. To bypass zmx and obtain a normal shell, use the canonical
host name instead of an alias:

```bash
ssh muscle.osv.computer
```

Run `zmx-select` to select a local session through fzf. Enter attaches to or
creates the selected name, Ctrl-N creates a session from the query, and the
preview shows session history. SSH login displays a hint listing active
sessions. The prompt displays `[zmx:NAME]` inside a session through Starship's
environment-variable support, with a Bash `PS1` fallback. The package supplies
Bash, Zsh, and Fish completions.

## Persistence and forwarding

On Linux, zmx sockets live in `/run/user/<uid>/zmx`. NixOS sets
`users.users.<user>.linger` for enabled zmx users so the user manager and
runtime directory survive disconnects. On macOS, zmx uses
`ZMX_DIR=~/.local/state/zmx`; periodic `TMPDIR` cleanup would otherwise remove
idle sockets.

Generated SSH `Host` blocks set `IdentityAgent` to the YubiKey gpg-agent SSH
socket. The `m` and `b` aliases also carry the GPG `RemoteForward` pair; their
trust flags live in `nix/lib/shared/machines/default.nix`. This must be
configured on the aliases because SSH `Host` matching uses the alias, not the
canonical hostname.

## Known limits

- Upgrading across a zmx IPC change terminates running sessions.
- Nested zmx over SSH into another zmx session has unsupported cursor
  corruption.
- Re-enabling kitty keyboard mode can confuse some applications, including
  `psql`.
