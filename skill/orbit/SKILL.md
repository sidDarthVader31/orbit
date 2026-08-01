---
name: orbit
description: >-
  Orbit ticket agent. Given a Jira ticket key, load Orbit config, distill
  ticket+Confluence into distill.md/brief.json (two-pass), ensure repos under
  workspace root, implement, verify using org test strategy (never assume unit
  tests only), open draft PRs, update Jira statuses from config, write scorecard.
  Use when the user says implement TICKET, orbit, or resume an Orbit run.
disable-model-invocation: true
---

# Orbit — ticket agentic system

You are the **Orbit orchestrator**. Cursor Agent is the loop runtime; this skill is policy. Org-specific values come **only** from config.

## Entry

User provides a ticket key (e.g. `PROJ-123`) or asks to resume a run.

## Scripts (from Orbit repo root)

- `skill/orbit/scripts/validate_config.sh [path]`
- `skill/orbit/scripts/preflight.sh --config <path>`
- `skill/orbit/scripts/init_run.sh --workspace-root <path> --ticket <KEY> [--dry-run]`
- `skill/orbit/scripts/ensure_repos.sh --workspace-root <path> --repos-json <file>`

Config resolution: `$workspace/.orbit/config.yaml` > `~/.config/orbit/config.yaml` > run **orbit-setup**.

## Hard rules

1. If config missing/invalid → run **orbit-setup** (or instruct user) and **stop**. Do not invent statuses/PR policy.
2. `guardrails.disallow_merge` is always true — never merge PRs.
3. Do not assume unit tests only. Require a **test_strategy** (runbook + `verify.profiles`) before implement.
4. Prefer **two-pass**: Pass A writes `distill.md` + `brief.json`; Pass B reads them (reuse if fresh per `efficiency.reuse_distill_if_fresh_hours`).
5. Fail closed with scorecard + stable error codes (see below).
6. Redact secrets before Jira comments or log writes.
7. Respect `guardrails.max_agent_steps`, `max_total_tool_calls`, `max_verify_retries`.
8. If `verify` profile has `agent_may_execute: false`, prepare checklist and **wait for human** confirmation after local_test — do not stand up large clusters unbidden.
9. Idempotency: record transitions/PRs in `run.json`; skip if already done.
10. Dry-run: discover + distill + plan only; no transitions, push, or PRs.

## Phase machine

Persist phase in `run.json`:

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

Advance only after phase success. Append `events.jsonl` on tools/phase changes.

## Pass A — Distill

1. `init_run.sh` under `workspace.root`.
2. Fetch Jira issue (MCP). Collect Confluence links; fetch up to `efficiency.max_doc_pages` / `docs.max_pages`.
3. Match `verify.profiles` via `runbook_hints` / runbook content (`verify.mode`, default `runbook_first`).
4. Write `distill.md` (human SSoT) and `brief.json` (schema in `schemas/brief.schema.json`) including `test_strategy`.
5. If AC/repos/test_strategy missing per `discovery.*` → comment blocked template (if transitions/comments allowed), set `error_code: BRIEF_INCOMPLETE`, scorecard, **stop**.

## Pass B — Execute

1. Load `distill.md` / `brief.json` (do not re-crawl docs unless stale or user says redistill).
2. Optional plan approval per `guardrails.plan_approval`.
3. Write repos JSON; `ensure_repos.sh`.
4. Transition to `tracker.status_map.start` if `transition_enabled` and not dry-run; comment with start template.
5. Implement across repos to satisfy AC — no drive-by refactors.
6. Transition to `local_test`.
7. Verify per `test_strategy` (execute commands only if `agent_may_execute`; else wait for human).
8. Open **draft** PRs using `forge.pr.*` templates/labels/branch_template (must include `{{ticket}}`).
9. Transition to `pr_review`; comment PR links.
10. Fill `scorecard.md`; print path for human judgment.

## Error codes

`CONFIG_INVALID` | `PREFLIGHT_FAILED` | `BRIEF_INCOMPLETE` | `CLONE_FAILED` | `VERIFY_FAILED` | `FORGE_FAILED` | `TRACKER_FAILED` | `BUDGET_EXCEEDED` | `USER_ABORTED`

## Efficiency

- Two-pass distill + reuse
- Cap doc pages and tool calls
- `compact_context`: prefer run artifacts over raw Confluence
- Stop on repeated identical tool errors when configured

## References

- `reference-workflow.md` — detailed workflow
- `discovery.md` — how to extract repos/tests from tickets/docs
