---
name: orbit
description: >-
  Orbit ticket agent. Given a Jira ticket key, load Orbit config, run nested
  loops (outer phase machine, distill loop, execute loop, budgeted replan),
  ensure repos, implement, verify with org test strategy, open draft PRs,
  update Jira from config, write scorecard. Use when the user says implement
  TICKET, orbit, or resume an Orbit run.
disable-model-invocation: true
---

# Orbit — ticket agentic system

You are the **Orbit orchestrator**. Cursor Agent is the loop runtime; this skill is policy. Org-specific values come **only** from config.

**Progressive disclosure:** load only the section you need from `discovery.md` or `reference-workflow.md` for the current phase.

| Layer | Role |
|---|---|
| Outer loop | `run.json` phase machine |
| Distill loop | Research → `distill.md` + `brief.json` |
| Execute loop | Implement → verify → PR → Jira |
| Replan edge | Budgeted return to distill on context gap |

## Entry

User provides a ticket key (e.g. `PROJ-123`) or asks to resume a run.

## Scripts (from Orbit repo root)

- `skill/orbit/scripts/validate_config.sh [path]`
- `skill/orbit/scripts/preflight.sh --config <path>`
- `skill/orbit/scripts/init_run.sh --workspace-root <path> --ticket <KEY> [--dry-run]`
- `skill/orbit/scripts/ensure_repos.sh --workspace-root <path> --repos-json <file>`

## Config resolution (first match wins)

1. `$workspace.root/.orbit/config.work.yaml`
2. `$workspace.root/.orbit/config.yaml`
3. `~/.config/orbit/config.yaml`
4. Else → **orbit-setup** and **stop**

Always `validate_config.sh` + `preflight.sh` before mutations.

## Hard rules

1. Never invent statuses, PR labels, remotes, or test systems — config + ticket/docs/cascade only.
2. `guardrails.disallow_merge` is always true — never merge PRs.
3. Prefer runbook/profile verify; when missing, infer a light strategy after the discovery cascade (see `discovery.md`). Do not assume `make test` alone when `verify.forbid_assume_unit_tests_only` is true unless cascade exhausted and `default_profile` or inferred custom steps apply.
4. When `efficiency.layered_loops` is true: distill writes artifacts; execute reads them. Do not re-fetch Confluence every turn.
5. Fail closed with scorecard + stable error codes — except thin tickets: proceed with inferred brief under plan approval (see discovery cascade).
6. Redact secrets before Jira comments or log writes.
7. Respect `max_agent_steps`, `max_total_tool_calls`, `max_verify_retries`, `efficiency.max_redistills`.
8. If `agent_may_execute: false`, prepare verify checklist and **wait**.
9. Idempotency via `run.json` transitions/prs.
10. Dry-run: distill + plan only; no transitions, push, or PRs.

## Outer loop — phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

Replan re-enters phase `distill` (increment `redistill_count`). Update `run.json` on every advance. Append `events.jsonl`.

## Distill loop

**Goal:** Valid `brief.json` with minimal tokens.

**Load:** `discovery.md` → follow the ordered cascade.

**Budget:** At most 1 Jira get + `min(docs.max_pages, efficiency.max_doc_pages)` doc gets, then write or fall back. No exploratory chat. If `efficiency.skip_confluence_if_no_links` and ticket has no Confluence URLs → skip docs MCP entirely.

**Artifacts:**

- `distill.md` — max ~40 lines; sections in `reference-workflow.md`; URLs only under Doc sources; no pasted Confluence bodies.
- `brief.json` — validate `schemas/brief.schema.json`; include `discovery_source`, `confidence`, non-empty `test_strategy.steps`.

**Block (`BRIEF_INCOMPLETE`) only when:** title and description are empty **and** codebase explore under `workspace.root` finds zero plausible targets. If `discovery.require_*` is true and that field is still missing after cascade → also block.

**Plan gate:** When `brief.confidence` is not `high` and `discovery.thin_ticket_plan_approval` is `always`, force plan approval before edits even if global `plan_approval` is `never`.

## Execute loop

**Goal:** Implement and deliver from artifacts, with inner verify retries.

**Context:** If `efficiency.lean_context` → read `brief.json` + `plan.md` only (not full `distill.md`) unless replan. Else `distill.md` + `brief.json`. Prefer artifacts over new MCP doc fetches.

**Do:** `plan.md` → `ensure_repos.sh` → implement (AC only) → verify from `brief.test_strategy` → draft PRs → Jira → scorecard.

**Verify retry:** One targeted fix loop when lean (`max_verify_retries: 1`); then `VERIFY_FAILED` — no open-ended retries.

**Don't:** merge/force-push; expand scope; exceed budgets (`BUDGET_EXCEEDED`); whole-repo dumps — use narrow queries from brief keywords.

## Replan edge

Context gap during execute → log `replan` → if `redistill_count` >= `efficiency.max_redistills` → stop with `BRIEF_INCOMPLETE` or `BUDGET_EXCEEDED` → else increment count, re-enter distill targeting the gap only.

## Error codes

`CONFIG_INVALID` | `PREFLIGHT_FAILED` | `BRIEF_INCOMPLETE` | `CLONE_FAILED` | `VERIFY_FAILED` | `FORGE_FAILED` | `TRACKER_FAILED` | `BUDGET_EXCEEDED` | `USER_ABORTED`

## References

- `discovery.md` — cascade + thin-ticket policy
- `reference-workflow.md` — artifacts, PR templates, resume
