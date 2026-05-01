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
- Before acting, state the intended outcome, choose the lightest sufficient
  tool/model path, and preserve freedom to use a better strategy than the
  user-suggested mechanics when evidence supports it.
- When suggesting or choosing tools, include both the concrete tool and the
  strategic reason it unlocks progress; avoid model/tool bloat when a cheap
  search or local read is enough.
- Keep changes small, typed, and verifiable; run `nix fmt`, targeted
  checks, and `nix flake check` when changes warrant it.
- Never commit, rewrite history, or bypass safety checks unless explicitly asked.
