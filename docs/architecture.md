# Architecture

## Layers

| Layer | Orbit implementation |
|---|---|
| Goal | Jira ticket key |
| Orchestrator | Cursor Agent + `orbit` skill |
| Policy variables | `~/.config/orbit/config.yaml` (+ optional work override) |
| Tools | Jira/Confluence MCP, git/gh, shell |
| Memory | `.orbit/runs/<id>/` artifacts |
| Guardrails | Budgets, dry-run, no merge, allowlists |
| Judgment | `scorecard.md` |

## Layered loops (loop engineering)

Orbit is not a one-shot “two-pass pipeline.” It uses **nested loops**:

| Loop | Role |
|---|---|
| **Outer** | `run.json` phase machine |
| **Distill** | Research until `brief.json` validates or fail closed |
| **Execute** | Implement → verify with observe/retry |
| **Replan** | Budgeted return to distill on context gap (`max_redistills`) |

```text
Ticket goal
    → Outer phases
        → Distill loop → distill.md + brief.json
        → Execute loop → code / verify / PR / Jira
        → (optional) Replan → Distill again if context gap
```

Compressed memory (`distill.md` / `brief.json`) keeps the execute loop cheap: reload artifacts instead of re-crawling docs every turn.

## Outer phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

Replan re-enters `distill` and increments `run.json.redistill_count`.

## Skill vs system

Skills (`orbit`, `orbit-setup`) are the portable policy layer for Cursor. The **system** also includes schemas, scripts, config contract, run state, efficiency rules, and scorecard.
