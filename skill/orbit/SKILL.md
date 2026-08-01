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

## Config resolution (first match wins)

1. `$workspace.root/.orbit/config.work.yaml` (private work — preferred when present)
2. `$workspace.root/.orbit/config.yaml`
3. `~/.config/orbit/config.yaml`
4. Else → **orbit-setup** and **stop**

Always `validate_config.sh` + `preflight.sh` before mutations.

## Hard rules

1. Never invent statuses, PR labels, remotes, or test systems — config + ticket/docs only.
2. `guardrails.disallow_merge` is always true — never merge PRs.
3. Do not assume unit tests only. Require **test_strategy** before implement.
4. **Two-pass**: Pass A writes artifacts; Pass B reads them. Do not re-fetch Confluence every turn.
5. Fail closed with scorecard + stable error codes.
6. Redact secrets before Jira comments or log writes.
7. Respect `max_agent_steps`, `max_total_tool_calls`, `max_verify_retries`.
8. If `agent_may_execute: false`, prepare verify checklist and **wait** — do not bring up clusters unbidden.
9. Idempotency via `run.json` transitions/prs.
10. Dry-run: distill + plan only; no transitions, push, or PRs.

## Phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done|blocked|failed
```

Update `run.json` phase on every advance. Append `events.jsonl` for tools/phase changes.

---

## Pass A — Distill (tight checklist)

**Goal:** One cheap, complete SSoT for Pass B. Minimize tokens: summarize, don’t dump pages.

### Do

1. `init_run.sh --workspace-root <root> --ticket <KEY> [--dry-run]`
2. If a fresh run for this ticket exists within `efficiency.reuse_distill_if_fresh_hours` and user did not say `redistill` → **reuse** that `distill.md` / `brief.json` and skip to Pass B.
3. Fetch Jira issue once (summary, description, AC field if configured, comments, links).
4. Collect Confluence URLs; fetch at most `min(docs.max_pages, efficiency.max_doc_pages)`.
5. Match `verify.profiles` using `runbook_hints` + runbook text (`verify.mode`).
6. Write **`distill.md`** with exactly these sections (keep short):

```markdown
# Distill — {{ticket}}
## Summary
## Acceptance criteria (checklist)
## Repos (name + remote or path)
## Doc sources (URLs only)
## Test strategy
### profile / kind
### prerequisites
### steps (ordered)
### success signals
### agent_may_execute
## PR notes
## Open questions
## Confidence: high|medium|low
```

7. Write **`brief.json`** validating `schemas/brief.schema.json` — must include non-empty `test_strategy.steps` and `success_signals`.
8. Set phase `brief_validate`. If `discovery.require_*` fails → `BRIEF_INCOMPLETE`, blocked comment (template), scorecard, **stop**.

### Don’t

- Paste full Confluence HTML into distill
- Invent remotes or helm/k8s steps not in docs/config
- Start coding in Pass A
- Call the same failing tool more than twice when `stop_on_repeated_tool_error`

---

## Pass B — Execute (tight checklist)

**Goal:** Implement and deliver using **only** `distill.md` + `brief.json` (+ `plan.md`).

### Do

1. Re-read `distill.md` and `brief.json`. Prefer them over new MCP doc fetches (`compact_context`).
2. Write `plan.md` (file-level steps). If `plan_approval` requires it → show plan and **wait**.
3. Emit `repos.json` from brief; run `ensure_repos.sh`. On failure → `CLONE_FAILED`.
4. If not dry-run and `transition_enabled`: transition to `status_map.start` once; record in `run.json.transitions`.
5. **Implement** only what AC requires across listed repos. No drive-by refactors. Commit on ticket branches using `forge.branch_template` (must contain `{{ticket}}`).
6. Transition to `status_map.local_test` (once).
7. **Verify** strictly from `brief.test_strategy`:
   - If `agent_may_execute: true` → run steps; retry up to `max_verify_retries`
   - If `false` → write a concrete checklist into `log.md` / Jira comment and set `status: waiting_human` until user confirms success signals
8. Open **draft** PRs with rendered `forge.pr.*` templates; record URLs in `run.json.prs` (skip if already present).
9. Transition to `status_map.pr_review`; comment `pr_ready` template.
10. Fill `scorecard.md`; print absolute path; set phase `done`.

### Don’t

- Re-distill unless stale or user requests
- Merge, force-push, or delete branches
- Expand scope beyond AC / distill
- Exceed tool-call budgets — stop with `BUDGET_EXCEEDED`

---

## Error codes

`CONFIG_INVALID` | `PREFLIGHT_FAILED` | `BRIEF_INCOMPLETE` | `CLONE_FAILED` | `VERIFY_FAILED` | `FORGE_FAILED` | `TRACKER_FAILED` | `BUDGET_EXCEEDED` | `USER_ABORTED`

## References

- `reference-workflow.md`
- `discovery.md`
