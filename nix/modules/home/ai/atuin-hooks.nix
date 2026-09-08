{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
in
{
  # NOTE: This lives in an imported child module (like opencode.nix) rather
  # than the discovered ai/default.nix: Snowfall applies discovered top-level
  # home modules with its own lib (no `lib.hm`), while imported children are
  # applied by Home Manager and receive the hm-extended lib.
  config = lib.mkIf cfg.enable {
    # Record agent-run bash commands into atuin history, tagged by author
    # (claude-code/codex); atuin's search hides them by default ($all-user)
    # and `--author '$all-agent'` surfaces them. `atuin hook install` is
    # upstream's own idempotent installer and edits mutable agent state
    # (~/.claude/settings.json, ~/.codex/hooks.json), so it runs at activation
    # rather than being templated by Nix.
    home.activation.atuinAgentHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString config.programs.atuin.enable ''
        for agent in claude-code codex; do
          run ${lib.getExe config.programs.atuin.package} hook install "$agent" \
            || verboseEcho "atuin hook install $agent failed"
        done
      ''
    );
  };
}
