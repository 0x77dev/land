{ lib, ... }:
let
  # muscle (Threadripper 7985WX) is the lab's biggest CPU — the preferred
  # remote builder, including aarch64-linux via binfmt for large parallel jobs.
  hostName = "muscle.osv.computer";

  # Plain form for `programs.ssh.knownHosts`.
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMA3wX5kRJoNtxY+pr2ccN7YerSEPvJ/5cK7zdQ2Wppv";
  # Base64 form for `nix.buildMachines.*.publicHostKey`.
  publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU1BM3dYNWtSSm9OdHhZK3ByMmNjTjdZZXJTRVB2Si81Y0s3emRRMldwcHYK"; # gitleaks:allow -- public SSH host key
in
{
  muscle = {
    inherit hostName publicKey publicHostKey;

    knownHost = {
      inherit publicKey;
      extraHostNames = [
        hostName
        "10.10.0.48"
        "muscle"
        "muscle.0x77.computer"
      ];
    };

    # `nix.buildMachines` entries targeting muscle (x86_64 native + aarch64 via
    # binfmt). `sshUser` is required. Darwin hosts authenticate via the
    # nix-daemon's SSH agent; NixOS hosts must pass `sshKey` (a path to a key
    # authorized for `sshUser` on muscle).
    mkMachines =
      {
        sshUser,
        sshKey ? null,
        maxJobs ? 16,
      }:
      let
        base = {
          inherit hostName sshUser publicHostKey;
          protocol = "ssh-ng";
        }
        // lib.optionalAttrs (sshKey != null) { inherit sshKey; };
      in
      [
        (
          base
          // {
            systems = [ "x86_64-linux" ];
            inherit maxJobs;
            speedFactor = 8;
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
        )
        (
          base
          // {
            systems = [ "aarch64-linux" ];
            inherit maxJobs;
            speedFactor = 4;
            supportedFeatures = [ "big-parallel" ];
          }
        )
      ];
  };
}
