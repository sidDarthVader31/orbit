# Presentation FAQ — skill vs Orbit

## 15-second answer

A **skill** is a playbook (static instructions). **Orbit** is an **agentic system**: goal-driven loop (plan → tools → observe → update state → repeat) plus config, guardrails, durable run artifacts, and a scorecard. Skills are the policy layer inside Cursor; they are not the whole product.

## Table

| | Skill alone | Orbit |
|---|---|---|
| Input | Ad-hoc chat | Ticket key as goal |
| Org policy | Often hardcoded prose | First-run config |
| Control flow | Hope model follows | `run.json` phases + budgets |
| Memory | Chat scrollback | distill/brief/log/scorecard |
| Testing | Assumed or forgotten | Config + runbook test strategy |
| Cost | Easy to thrash context | Two-pass distill + caps |
| Judgment | Vibes | Scorecard |

## Analogy

| Piece | Metaphor |
|---|---|
| Skill | Handbook |
| Config | Your team’s local rules |
| Cursor Agent | Worker who can act |
| MCP/git | Access badges |
| run.json | This run’s workflow board |
| Scorecard | QA sheet |

## Anticipated questions

**Q: You still use skills?**  
Yes — as portable policy for Cursor. Orbit also ships schemas, scripts, config, and run contracts.

**Q: Where is the while-loop?**  
Cursor Agent is the loop runtime. Orbit constrains it with phases, config, and tools.

**Q: Why not a long prompt?**  
Prompts aren’t plug-and-play config, durable resume, idempotent PRs, or an eval surface for others.
