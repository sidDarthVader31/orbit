# Architecture

## Layers

| Layer | Orbit implementation |
|---|---|
| Goal | Jira ticket key |
| Orchestrator | Cursor Agent + `orbit` skill |
| Policy variables | `~/.config/orbit/config.yaml` |
| Tools | Jira/Confluence MCP, git/gh, shell |
| Memory | `.orbit/runs/<id>/` artifacts |
| Guardrails | Budgets, dry-run, no merge, allowlists |
| Judgment | `scorecard.md` |

## Two-pass loop

```text
Pass A (distill):  ticket + docs → distill.md + brief.json
Pass B (execute):  load artifacts → repos → code → verify → PR → Jira → scorecard
```

## Phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

## Skill vs system

Skills (`orbit`, `orbit-setup`) are the portable policy layer for Cursor. The **system** also includes schemas, scripts, config contract, run state, efficiency rules, and scorecard. See [presentation-faq.md](presentation-faq.md).
