---
type: always_apply
---

# land AI guidance

- Follow repository guidance from `README.md`, `CONTRIBUTING.md`, and
  `.cursor/rules/*.mdc`.
- Treat `flake.nix`, `nix/**/*.nix`, and checked-in config files as the
  source of truth.
- Prefer Snowfall Lib and Home Manager conventions over ad hoc installers
  or one-off shell setup.
- Keep changes small, typed, and verifiable; run `nix fmt`, targeted
  checks, and `nix flake check` when changes warrant it.
- Never commit, rewrite history, or bypass safety checks unless explicitly asked.
