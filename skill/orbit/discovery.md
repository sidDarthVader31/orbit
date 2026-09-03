# Discovery guide

Discovery runs during the **distill loop**. Goal: enough context for `brief.json` without over-fetching docs.

## Ordered cascade (always)

Apply in order; stop enriching when a step yields usable AC/repos/strategy. Record primary source in `brief.discovery_source` (`confluence` | `ticket_body` | `inferred_title` | `codebase_fallback` | `mixed`).

### 1. Linked Confluence / runbook

- Only if ticket contains Confluence/doc URLs (or `docs.follow_links_from_ticket` finds links).
- If `efficiency.skip_confluence_if_no_links` and no URLs → **skip docs MCP entirely**.
- Fetch at most `min(docs.max_pages, efficiency.max_doc_pages)` pages.
- Summarize — never paste full page bodies into `distill.md`.

### 2. Ticket body

- Description, AC custom field (if configured), comments, attachment hints, embedded steps.
- Extract explicit repos, services, and verify hints.

### 3. Title + description inference

- When `discovery.infer_from_title` is true and AC/repos/strategy still thin:
- Synthesize a checklist AC from summary + description.
- Set `confidence: medium` or `low`.
- Mark inferred items clearly in `distill.md` (e.g. prefix `(inferred)`).

### 4. Codebase explore

- When `discovery.codebase_fallback` is true:
- Search under `workspace.root` using ticket keywords, labels, components, service names.
- Propose `repos[]` as `{ "name", "remote?", "path?" }` for `ensure_repos.sh`.
- Use narrow queries — not whole-repo dumps.

### 5. Verify strategy

1. Match `verify.profiles` via `runbook_hints` + runbook/ticket text (`verify.mode`).
2. Else use `verify.default_profile` if set.
3. Else `kind: custom` with steps like `["best-effort local checks from repo README/Makefile"]`, `agent_may_execute: false` unless a local profile exists.

`verify.forbid_assume_unit_tests_only` still applies to **rich** sources — do not default to `make test` alone when runbook hints exist. After cascade exhaustion, inferred light local strategy is allowed.

## Extracting repos

Look for:

- Explicit repo URLs or `org/name` in ticket/runbook
- Service names mapped via codebase explore
- `discovery.repo_name_hints` in config

If `guardrails.repo_allowlist` is set, refuse remotes/names outside it.

## Confidence + plan approval

| `confidence` | Meaning |
|---|---|
| `high` | Runbook/ticket had explicit AC, repos, and verify path |
| `medium` | Partial ticket + some inference or codebase match |
| `low` | Mostly inferred; thin ticket |

When `discovery.thin_ticket_plan_approval: always` and `confidence != high` → **mandatory plan approval** before code edits (safety rail for thin tickets).

## Blocking (`BRIEF_INCOMPLETE`)

**Only when:**

- Title **and** description are empty **and** codebase explore finds **zero** plausible targets, **or**
- `discovery.require_ac` / `require_repos` / `require_test_strategy` is true and that field is still missing after the full cascade.

Otherwise: write best-effort `brief.json`, set confidence, proceed under plan approval.

## test_strategy fields

| Field | Meaning |
|---|---|
| profile | Config profile name if matched |
| kind | local_commands / helm / k8s / docker_compose / remote_script / custom |
| steps | Ordered steps (from runbook or inferred) |
| prerequisites | VPN, kubecontext, AWS SSO, … |
| agent_may_execute | From profile; false for heavy envs |
| success_signals | How we know verify passed |

## Ask user

If `discovery.ask_user_on_ambiguity` and cascade still ambiguous on repo or verify path → ask once before blocking.
