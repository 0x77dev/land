# YubiKey PAM operations

`muscle` accepts a registered YubiKey as an alternative to the local password
for GDM login, screen unlock, and `sudo`. Authentication requires the FIDO2 PIN
but not a touch. PAM checks silently for a registered authenticator and prompts
for its PIN; if authentication is unavailable or fails, the normal password
prompt remains available.

The credential mapping is host-local and must not be committed. PAM reads it as
root from `/etc/u2f-mappings` using the host-specific relying-party ID
`pam://muscle`.

## Enrollment

Set and verify the local account password before activating this configuration.
Keep an authenticated root shell open while testing so a bad mapping cannot
remove the recovery path.

Set a FIDO2 PIN if the key does not already have one:

```bash
ykman fido access change-pin
```

Register the key with PIN verification and user presence disabled:

```bash
nix shell nixpkgs#pam_u2f -c sh -c \
  'pamu2fcfg -u mykhailo -o pam://muscle -N -P' > /tmp/u2f-mappings
sudo install -o root -g root -m 0600 /tmp/u2f-mappings /etc/u2f-mappings
rm -f /tmp/u2f-mappings
```

To register a backup key, generate only its credential and append it to the
existing user line:

```bash
nix shell nixpkgs#pam_u2f -c sh -c \
  'pamu2fcfg -u mykhailo -o pam://muscle -N -P -n' > /tmp/u2f-credential
sudo sh -c '
  mapping=$(cat /etc/u2f-mappings)
  credential=$(cat /tmp/u2f-credential)
  umask 077
  printf "%s:%s\n" "$mapping" "$credential" > /etc/u2f-mappings.new
  mv /etc/u2f-mappings.new /etc/u2f-mappings
'
rm -f /tmp/u2f-credential
```

Confirm that the file remains a root-owned regular file:

```bash
sudo stat -c '%U:%G:%a %F' /etc/u2f-mappings
```

The expected result is `root:root:600 regular file`.

## Validation

Test both branches before closing the root shell:

```bash
sudo -k
sudo true
sudo -k
```

The first run should accept the FIDO2 PIN without requiring a touch. For the
second run, remove the YubiKey and verify that the account password succeeds.
Then lock the GNOME session and test both paths there.

GNOME Keyring remains password-encrypted. Password login supplies the account
password to `pam_gnome_keyring` and unlocks the Login keyring automatically.
FIDO2 authentication supplies a signed assertion, not that password, so GNOME
will request the keyring password once after a YubiKey-authenticated login. Do
not set an empty keyring password or inject a disk-unlock secret to suppress
that prompt.

## Recovery

If token authentication fails, use the local account password. From an
authenticated root shell, disable the integration by reverting
`modules.yubikey-pam.enable`, or replace a bad mapping atomically:

```bash
sudo install -o root -g root -m 0600 /tmp/u2f-mappings /etc/u2f-mappings
```
