{
  lib,
  namespace,
  writeShellApplication,
  git,
  gitsign,
  gnupg,
  coreutils,
  nixos-rebuild ? null,
  darwin-rebuild ? null,
}:

writeShellApplication {
  name = "verify-and-update";

  runtimeInputs = [
    git
    gitsign
    gnupg
    coreutils
  ]
  ++ lib.optional (nixos-rebuild != null) nixos-rebuild
  ++ lib.optional (darwin-rebuild != null) darwin-rebuild;

  text = builtins.readFile ./script.sh;

  meta = {
    description = "Verified system updates with commit signature validation";
    longDescription = ''
      Verifies commit signatures (gitsign/GPG) and validates repository origin
      before updating. Uses atomic boot operation and change detection.

      Environment:
      - FLAKE_URL (required)
      - ALLOWED_WORKFLOW_REPOSITORY (recommended for gitsign)
      - ALLOWED_GPG_KEY (required for GPG)
      - DRY_RUN (optional)
    '';
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    platforms = lib.platforms.unix;
    mainProgram = "verify-and-update";
  };
}
