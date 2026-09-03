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
| **Distill** | Research until `brief.json` validates or cascade exhausts (Confluence → ticket → infer → codebase) |
| **Execute** | Implement → verify with observe/retry |
| **Replan** | Budgeted return to distill on context gap (`max_redistills`) |

```text
Ticket goal
    → Outer phases
        → Distill loop → distill.md + brief.json
        → Execute loop → code / verify / PR / Jira
        → (optional) Replan → Distill again if context gap
```

Compressed memory (`distill.md` / `brief.json`) keeps the execute loop cheap. With `efficiency.lean_context`, execute reads `brief.json` + `plan.md` only unless replanning.

## Thin-ticket robustness

When Confluence/runbook is missing, Orbit does not stop at `BRIEF_INCOMPLETE` by default:

1. Infer AC from title/description (`discovery.infer_from_title`)
2. Discover repos via codebase search (`discovery.codebase_fallback`)
3. Proceed with `confidence: medium|low` and mandatory plan approval (`discovery.thin_ticket_plan_approval`)

Only block when title/description are empty **and** codebase explore finds zero plausible targets.

## Outer phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

Replan re-enters `distill` and increments `run.json.redistill_count`.

## Skill vs system

Skills (`orbit`, `orbit-setup`) are the portable policy layer for Cursor. The **system** also includes schemas, scripts, config contract, run state, efficiency rules, and scorecard.
