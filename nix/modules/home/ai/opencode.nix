{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.ai;

  mutableOpenCodeFiles = lib.filterAttrs (
    name: file: file.enable && lib.hasPrefix "opencode/" name && !file.recursive
  ) config.xdg.configFile;

  materializeFileCalls = lib.concatMapStringsSep "\n" (file: ''
    materialize_opencode_file ${lib.escapeShellArg "${config.home.homeDirectory}/${file.target}"}
  '') (lib.attrValues mutableOpenCodeFiles);

  coreutils = "${pkgs.coreutils}/bin";
in
{
  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.llm-agents.opencode;

      settings = {
        disabled_providers = [ "opencode" ];
        plugin = [ "@simonwjackson/opencode-direnv" ];
        snapshot = false;
        share = "disabled";

        experimental.openTelemetry = false;
        permission.skill."*" = "allow";

        model = "openai/gpt-5.6-sol";
        small_model = "openai/gpt-5.6-luna";

        provider.openai.models."gpt-5.6-sol".options = {
          reasoningEffort = "medium";
          serviceTier = "priority";
        };
        provider.openai.models."gpt-5.6-luna".options.reasoningEffort = "low";
      };

      context = ''
        # Mykhailo's engineering defaults

        Read and follow each repository's own `AGENTS.md`, `CONTRIBUTING.md`,
        `README.md`, and local rule files first. Treat them as the source of
        truth for that repo's domain, workflows, and locked decisions.

        Prefer declarative, reproducible, Nix-native solutions. Use flake dev
        shells, `direnv exec . <command>`, or `nix develop -c <command>` so
        local work, agents, and CI use the same toolchain. Do not install ad hoc
        host dependencies when a flake package or temporary Nix shell can provide
        the tool.

        Keep changes small, explicit, reversible, and well-named. Optimize for
        boring control flow, durable contracts, strong reviewability, and stable
        source-of-truth boundaries over cleverness, hidden magic, or scattered
        compatibility shims.

        Infer from existing structure before adding new surface area. Keep
        `flake.nix` thin, put real logic in dedicated files, prefer explicit
        function arguments and standard helpers, and keep overlays, shell glue,
        generated state, and compatibility projections narrow and obvious.

        Preserve project ownership boundaries. Do not grow unrelated monorepo
        surface area, duplicate vendor-owned behavior, or maintain parallel state
        for concepts another system already owns. Put durable conventions in the
        canonical docs, not only in comments, tickets, or PR discussion.

        Validate with the project's closest checks before declaring done: format,
        lint, typecheck, tests, `nix build`, `nix flake check`, or project-specific
        doctor commands as appropriate. When something fails, report the exact
        command and error instead of replacing evidence with a vague roadmap.

        Keep secrets, research artifacts, generated state, and harness-local files
        out of commits unless explicitly requested. Do not commit, rewrite
        history, add AI authorship trailers, or publish external comments without
        explicit human instruction.
      '';
    };

    home.activation.materializeOpenCodeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      materialize_opencode_file() {
        local target="$1"
        local backup_path=""
        local link_target
        local temp_file

        if [[ -n "''${HOME_MANAGER_BACKUP_EXT:-}" ]]; then
          backup_path="$target.$HOME_MANAGER_BACKUP_EXT"
        fi

        if [[ -L "$target" && -n "$backup_path" && -e "$backup_path" ]]; then
          if [[ -v DRY_RUN ]]; then
            verboseEcho "Would restore mutable OpenCode config $target from $backup_path"
            return 0
          fi

          ${coreutils}/rm -f "$target"
          ${coreutils}/mv "$backup_path" "$target"
          return 0
        fi

        if [[ ! -L "$target" ]]; then
          return 0
        fi

        link_target="$(${coreutils}/readlink "$target")"

        if [[ "$link_target" != /nix/store/* ]]; then
          return 0
        fi

        if [[ -v DRY_RUN ]]; then
          verboseEcho "Would materialize OpenCode config $target"
          return 0
        fi

        temp_file="$(${coreutils}/mktemp "$HOME/.hm-opencode-config.XXXXXX")"
        ${coreutils}/cat "$target" > "$temp_file"
        ${coreutils}/chmod 0644 "$temp_file"
        ${coreutils}/rm -f "$target"
        ${coreutils}/mv "$temp_file" "$target"
      }

      ${materializeFileCalls}
    '';
  };
}
