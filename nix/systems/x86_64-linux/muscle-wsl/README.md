# muscle-wsl

NixOS on WSL 2 with NVIDIA GPU support.

## GPG Agent Forwarding

GPG agent forwarding is configured automatically for all SSH connections. When
you SSH from any machine with this configuration, your local GPG agent (and
YubiKey if attached) is forwarded to the remote system via the extra socket.

### Usage

From any configured system, SSH to a remote host:

```bash
ssh remote-host
```

On the remote host, GPG operations use your local GPG agent:

```bash
gpg --card-status
git commit -S -m "signed with forwarded agent"
```

### WSL Specific

Install GPG4Win on Windows and add to `%APPDATA%\gnupg\gpg-agent.conf`:

```conf
enable-ssh-support
extra-socket-path %APPDATA%\gnupg\S.gpg-agent.extra
```

Establish localhost SSH connection to activate forwarding:

```bash
ssh -N -f localhost
```

### Security

- Extra socket provides read-only access to GPG operations
- Private keys never leave the source system
- YubiKey remains on local system
- No custom binaries or kernel modifications required

References:

- <https://weisser-zwerg.dev/posts/openpgp-card-hardware-keys-remotely/>
- <https://jpmens.net/2025/04/04/forwarding-gnupg-agent-over-ssh/>
