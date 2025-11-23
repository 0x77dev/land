# Using YubiKey PIV Authentication with Incus

This command exports the PIV certificate from your YubiKey's
[slot 9a][] and adds it as a trusted certificate to the Incus server,
enabling certificate-based authentication.

YubiKey's support multiple PIV certificate slots, each designed for
different purposes. [Slot 9a][] is specifically designated for PIV
Authentication - used for system login and card/cardholder
authentication. This slot requires the user PIN for private key
operations and is ideal for authenticating to remote services like
Incus.

```bash
ykman piv certificates export 9a - \
  | ssh mykhailo@pickle incus config trust add-certificate -
```

The command breakdown:

- [`ykman piv certificates export 9a -`][ykman]: Extracts the X.509
  certificate from slot 9a and outputs to stdout (`-`)
- Pipes the certificate via SSH to the remote Incus server
- [`incus config trust add-certificate -`][incus]: Reads the certificate
  from stdin (`-`) and adds it to Incus's trusted client certificates

[slot 9a]: https://developers.yubico.com/PIV/Introduction/Certificate_slots.html
[ykman]: https://docs.yubico.com/software/yubikey/tools/ykman/PIV_Commands.html#ykman-piv-certificates-generate-options-slot-public-key
[incus]: https://linuxcontainers.org/incus/docs/main/reference/manpages/incus/config/trust/add-certificate/
