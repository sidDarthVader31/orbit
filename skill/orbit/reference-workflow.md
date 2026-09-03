# Orbit reference workflow

## Config locations

1. `$workspace.root/.orbit/config.work.yaml` — private work override (gitignored; wins)
2. `$workspace.root/.orbit/config.yaml` — workspace override
3. `~/.config/orbit/config.yaml` — user default
4. Examples in repo `configs/examples/`

## Layered loops

| Layer | Artifact / control |
|---|---|
| Outer | `run.json` phases |
| Distill loop | `distill.md`, `brief.json` |
| Execute loop | code, verify, PRs |
| Replan | `redistill_count` vs `efficiency.max_redistills` |

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

Keep it **≤ ~40 lines**. Do not paste entire Confluence pages — summarize. URLs only under Doc sources.

## brief.json

Must validate against `schemas/brief.schema.json`. Always include `test_strategy`, `confidence`, and `discovery_source`.

## Lean context

When `efficiency.lean_context` is true, the execute loop reloads `brief.json` + `plan.md` only (not full `distill.md`) unless replanning.

## run.json

Must track `phase`, `transitions[]`, `prs[]`, `tool_calls`, `verify_retries`, `redistill_count`, `error_code`.

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
4. Re-enter distill only if older than `efficiency.reuse_distill_if_fresh_hours`, forced by user, or replan edge with remaining `max_redistills`
