# Changelog

All notable changes to Orbit are documented here.

## [0.2.0] — unreleased

### Changed

- Reframed architecture from “two-pass” to **layered loops** (outer / distill / execute / replan)
- Orchestrator skill describes nested loop engineering and budgeted replan
- Config: `efficiency.two_pass` renamed to `efficiency.layered_loops`; added `efficiency.max_redistills`
- `run.json` includes `redistill_count`

### Removed

- `docs/presentation-faq.md`

## [0.1.0] — 2026-08-01

### Added

- Public scaffold: `orbit` + `orbit-setup` Cursor skills
- Config schema v1 with verify profiles, efficiency settings, guardrails
- Scripts: validate_config, preflight, init_run, ensure_repos, install_skills
- Example configs including dry-run and `config.work.yaml.example`
- Distill / execute checklists in orchestrator skill
- Docs: README architecture + usage guide, work validation, threat model
- CI workflow for example config validation + shellcheck
- Synthetic ticket fixture under `tests/fixtures/`
