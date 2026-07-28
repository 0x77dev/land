{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.ai;
  ompLangfuse = "${pkgs.land.omp-plugins}/lib/omp-plugins/pi-langfuse";
  langfuseFlushAt = "8";
  langfusePrivacyPreset = "full-debug";
  ompWithLangfuse = pkgs.writeShellApplication {
    name = "omp";
    runtimeInputs = [
      pkgs.bun
      pkgs.direnv
    ];
    text = ''
      export LANGFUSE_FLUSH_AT=${lib.escapeShellArg langfuseFlushAt}
      : "''${LANGFUSE_PRIVACY_PRESET:=${lib.escapeShellArg langfusePrivacyPreset}}"
      export LANGFUSE_PRIVACY_PRESET
      exec ${lib.getExe pkgs.llm-agents.omp} --extension ${lib.escapeShellArg ompLangfuse} "$@"
    '';
  };
in
{
  imports = [
    ./opencode.nix
    ./pi.nix
    ./shell
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.bun
        pkgs.llm-agents.claude-code
        pkgs.llm-agents.codex
        pkgs.llm-agents.cursor-agent
        pkgs.llm-agents.lean-ctx
        ompWithLangfuse
      ];

      # Bound OTel batches before Langfuse's 4.5 MiB ingestion limit; the bundled
      # extension also byte-chunks REST fallback requests and caps oversized fields.
      # The old metadata-only value was a stale imperative systemd user-environment leftover.
      # full-debug captures IO, tool IO, system prompt, and cwd; override it per invocation via env.
      sessionVariables = {
        LANGFUSE_FLUSH_AT = langfuseFlushAt;
        LANGFUSE_PRIVACY_PRESET = langfusePrivacyPreset;
      };
    };

    programs.pi-coding-agent = {
      enable = true;
      package = pkgs.land.pi-node;
      extraPackages = [
        pkgs.nodejs
        pkgs.direnv
      ];
      settings = {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.6-sol";
        defaultThinkingLevel = "medium";
        hideThinkingBlock = false;
        npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
        # Langfuse is patched and pinned in Nix; the remaining unversioned sources
        # intentionally follow Pi's updater. Pi/OMP/LeanCTX stay flake-pinned.
        packages = [
          ompLangfuse
          "npm:@davidorex/pi-context"
          "npm:@davidorex/pi-workflows"
          "npm:@vigolium/piolium"
          "npm:pi-lens"
          "npm:@ff-labs/pi-fff"
          "npm:pi-lean-ctx"
          "npm:pi-web-access"
          "npm:pi-goals"
          "npm:pi-subagents"
        ];
        theme = "dark";
      };
    };
  };
}
