_:
# Default verified auto-update configuration shared across all systems
{
  flakeUrl = "github:0x77dev/land";

  # Allowed GPG key fingerprints (primary keys only, subkeys verified automatically)
  allowedGpgKeys = [ "C33BFD3230B660CF147762D2BF5C81B531164955" ];

  # GPG public keys with trust levels (like home-manager's programs.gpg.publicKeys)
  # Trust levels: 1=unknown, 2=never, 3=marginal, 4=full, 5=ultimate
  publicKeys = [
    {
      source = "/gpg/keys/0x77dev.asc";
      trust = 5; # Ultimate trust
    }
  ];

  allowedWorkflowRepository = "0x77dev/land";
}
