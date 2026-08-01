# Orbit reference workflow

## Config locations

1. `$workspace.root/.orbit/config.yaml` (override)
2. `~/.config/orbit/config.yaml` (user default)
3. Examples in repo `configs/examples/`

## Distill.md contract

`distill.md` is the human-readable single source of truth for a run. Suggested sections:

```markdown
# Distill — {{ticket}}

## Summary
## Acceptance criteria
## Repos
## Doc sources
## Test strategy
### Profile / kind
### Prerequisites
### Steps
### Success signals
### Agent may execute?
## PR notes
## Open questions
## Confidence
```

Keep it short enough to reload cheaply in Pass B. Do not paste entire Confluence pages — summarize.

## brief.json

Must validate against `schemas/brief.schema.json`. Always include `test_strategy`.

## run.json

Must track `phase`, `transitions[]`, `prs[]`, `tool_calls`, `verify_retries`, `error_code`.

## Status names

Never hardcode "In Progress". Always use `config.tracker.status_map.*`.

## PR creation

Render `forge.pr.title_template` and `body_template` with at least:

- `{{ticket}}`, `{{summary}}`, `{{ticket_url}}`, `{{test_plan}}`, `{{screenshots_section}}`

Apply `forge.pr.labels` when non-empty. Prefer draft PRs when `draft: true`.

## Resume

If user provides a run id or latest run for ticket:

1. Read `run.json`
2. Skip completed phases
3. Do not duplicate PR URLs already listed
4. Re-distill only if older than `efficiency.reuse_distill_if_fresh_hours` or forced
