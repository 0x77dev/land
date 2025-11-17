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

  text = ''
    # shellcheck shell=bash
    # shellcheck disable=SC2310,SC2311

    set -euxo pipefail

    # Configuration
    readonly FLAKE_URL="''${FLAKE_URL:?FLAKE_URL must be set}"
    readonly ALLOWED_GPG_KEY="''${ALLOWED_GPG_KEY:-}"
    readonly ALLOWED_WORKFLOW_REPOSITORY="''${ALLOWED_WORKFLOW_REPOSITORY:-}"
    readonly DRY_RUN="''${DRY_RUN:-false}"

    log() {
      printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
    }

    verify_gitsign() {
      local -r commit="$1"
      local -a verify_args=(
        "--certificate-oidc-issuer=https://token.actions.githubusercontent.com"
      )

      log "Verifying commit $commit with gitsign (OIDC keyless)"

      # If repository validation requested, construct identity regexp
      if [[ -n "$ALLOWED_WORKFLOW_REPOSITORY" ]]; then
        # Match any workflow from the specified repository
        # Format: https://github.com/OWNER/REPO/.github/workflows/.*@refs/.*
        local identity_pattern="^https://github.com/$ALLOWED_WORKFLOW_REPOSITORY/.github/workflows/.*@refs/.*"
        verify_args+=(
          "--certificate-identity-regexp=$identity_pattern"
          "--certificate-github-workflow-repository=$ALLOWED_WORKFLOW_REPOSITORY"
        )
        log "Enforcing repository: $ALLOWED_WORKFLOW_REPOSITORY"
      else
        # Without repository restriction, match any GitHub Actions workflow
        verify_args+=(
          "--certificate-identity-regexp=^https://github.com/.*/\.github/workflows/.*@refs/.*"
        )
        log "Warning: No repository validation (set ALLOWED_WORKFLOW_REPOSITORY)"
      fi

      # Use gitsign verify with proper certificate claims validation
      if ! gitsign verify "''${verify_args[@]}" "$commit" 2>&1; then
        log "✗ Gitsign verification failed"
        return 1
      fi

      log "✓ Gitsign signature valid"
      return 0
    }

    verify_gpg() {
      local -r commit="$1"
      local output signing_key

      log "Verifying commit $commit with GPG"

      # SECURITY: Require ALLOWED_GPG_KEY to prevent keyserver poisoning attacks
      if [[ -z "$ALLOWED_GPG_KEY" ]]; then
        log "✗ ALLOWED_GPG_KEY required for GPG verification (keyserver attacks exist)"
        log "  Set ALLOWED_GPG_KEY to a trusted key fingerprint"
        return 1
      fi

      # GPG will auto-retrieve keys from keyserver if configured
      if ! output=$(git verify-commit "$commit" 2>&1); then
        log "✗ GPG verification failed: $output"
        return 1
      fi

      # Verify it matches the allowed key (use primary key fingerprint)
      signing_key=$(git log --format="%GP" -n1 "$commit")
      if [[ "$signing_key" != "$ALLOWED_GPG_KEY" ]]; then
        log "✗ Signed by unauthorized key: $signing_key (expected: $ALLOWED_GPG_KEY)"
        return 1
      fi

      log "✓ GPG signature valid (primary key: $signing_key)"
      return 0
    }

    detect_signature_type() {
      local -r commit="$1"
      local gpgsig

      # Extract gpgsig from commit to detect type
      gpgsig=$(git cat-file commit "$commit" | sed -n '/^gpgsig/,/^$/p')

      if [[ -z "$gpgsig" ]]; then
        echo "none"
      elif grep -q "BEGIN SIGNED MESSAGE" <<< "$gpgsig" || grep -q "sigstore" <<< "$gpgsig"; then
        # Gitsign uses PKCS#7/CMS format with sigstore
        echo "gitsign"
      elif grep -q "BEGIN PGP SIGNATURE" <<< "$gpgsig"; then
        # Traditional GPG signature
        echo "gpg"
      else
        echo "none"
      fi
    }

    verify_commit() {
      local -r commit="$1"
      local sig_type

      sig_type=$(detect_signature_type "$commit")

      case "$sig_type" in
        gitsign)
          log "Detected gitsign signature"
          verify_gitsign "$commit"
          ;;
        gpg)
          log "Detected GPG signature"
          verify_gpg "$commit"
          ;;
        none)
          log "✗ No signature found on commit"
          return 1
          ;;
      esac
    }

    acquire_lock() {
      local -r lockdir="/var/tmp/verify-and-update.lock"

      if ! mkdir "$lockdir" 2>/dev/null; then
        if [[ -f "$lockdir/pid" ]]; then
          local pid
          pid=$(cat "$lockdir/pid" 2>/dev/null || echo "")
          if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log "✗ Another instance (PID $pid) is running"
            return 1
          fi
        fi
        log "Removing stale lock"
        rm -rf "$lockdir"
        mkdir "$lockdir" || return 1
      fi

      echo "$$" > "$lockdir/pid" || {
        rm -rf "$lockdir"
        return 1
      }
      # shellcheck disable=SC2064
      trap "rm -rf '$lockdir'" EXIT
      log "Lock acquired"
      return 0
    }

    fetch_and_verify() {
      local tmpdir latest_commit git_url

      # Convert Nix flake URL to git URL
      if [[ "$FLAKE_URL" == github:* ]]; then
        git_url="https://github.com/''${FLAKE_URL#github:}.git"
      elif [[ "$FLAKE_URL" == git+https://* ]]; then
        git_url="''${FLAKE_URL#git+}"
      elif [[ "$FLAKE_URL" == https://* ]] || [[ "$FLAKE_URL" == git@* ]]; then
        git_url="$FLAKE_URL"
      else
        log "✗ Unsupported FLAKE_URL format: $FLAKE_URL"
        return 1
      fi

      tmpdir=$(mktemp -d)
      readonly VERIFIED_FLAKE_DIR="$tmpdir"
      # shellcheck disable=SC2064
      trap "rm -rf '$tmpdir'" EXIT

      log "Cloning $git_url..."
      git clone --depth 10 "$git_url" "$tmpdir"
      cd "$tmpdir" || return 1

      latest_commit=$(git rev-parse HEAD)
      log "Latest commit: $latest_commit ($(git log --oneline -1))"

      verify_commit "$latest_commit"
    }

    get_current_system() {
      local system_profile

      case "$(uname -s)" in
        Linux)
          system_profile="/run/current-system"
          ;;
        Darwin)
          system_profile="/nix/var/nix/profiles/system"
          ;;
        *)
          log "✗ Unsupported platform: $(uname -s)"
          return 1
          ;;
      esac

      if [[ ! -L "$system_profile" ]]; then
        log "No current system profile found at $system_profile"
        return 1
      fi

      readlink -f "$system_profile"
    }

    detect_changes() {
      local -r new_system="$1"
      local current_system diff_output

      if ! current_system=$(get_current_system); then
        log "First deployment, proceeding"
        return 0
      fi

      # Direct path comparison (cheapest check)
      if [[ "$current_system" == "$new_system" ]]; then
        log "No changes: paths identical"
        return 1
      fi

      log "Analyzing changes..."
      if diff_output=$(nix store diff-closures "$current_system" "$new_system" 2>&1); then
        if [[ -z "$diff_output" ]]; then
          log "No closure differences"
          return 1
        fi
        echo "$diff_output" | head -20
        return 0
      fi

      log "Warning: diff-closures failed, assuming changes"
      return 0
    }

    perform_update() {
      local rebuild_cmd

      case "$(uname -s)" in
        Linux)
          rebuild_cmd="nixos-rebuild"
          ;;
        Darwin)
          rebuild_cmd="darwin-rebuild"
          ;;
        *)
          log "✗ Unsupported platform: $(uname -s)"
          return 1
          ;;
      esac

      if ! command -v "$rebuild_cmd" >/dev/null 2>&1; then
        log "✗ $rebuild_cmd not found"
        return 1
      fi

      if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY_RUN: would build and boot from verified flake"
        return 0
      fi

      # SECURITY: Use the verified local clone to prevent TOCTOU attacks
      # Build from the directory we just verified, not from remote URL
      # Use ?shallow=1 to allow Nix to use the shallow clone
      local -r verified_flake="git+file://$VERIFIED_FLAKE_DIR?shallow=1"

      log "Building from verified source: $verified_flake"
      if ! "$rebuild_cmd" build --flake "$verified_flake"; then
        log "✗ Build failed"
        return 1
      fi

      local new_system
      if ! new_system=$(readlink -f ./result); then
        log "✗ Could not resolve build result"
        rm -f ./result
        return 1
      fi

      if ! detect_changes "$new_system"; then
        log "✓ Already up to date (no profile created)"
        rm -f ./result
        return 0
      fi

      # Use 'boot' instead of 'switch' for safety (atomic updates)
      # The new system will activate on next boot, preventing runtime breakage
      log "Setting new configuration as boot default..."
      if ! "$rebuild_cmd" boot --flake "$verified_flake"; then
        log "✗ Failed to set boot configuration"
        rm -f ./result
        return 1
      fi

      rm -f ./result
      log "✓ Update staged for next boot (reboot required)"
      log "  Run 'reboot' to activate new configuration"
    }

    main() {
      log "=== Verified auto-update ==="

      if ! acquire_lock; then
        exit 1
      fi

      if ! fetch_and_verify; then
        log "✗ Verification failed, aborting"
        exit 1
      fi

      perform_update
      log "=== Complete ==="
    }

    main "$@"
  '';

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
