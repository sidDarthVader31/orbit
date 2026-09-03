# Configuration reference

Orbit reads (first match wins):

1. `$workspace.root/.orbit/config.work.yaml` — private work override (gitignored)
2. `$workspace.root/.orbit/config.yaml` — workspace override
3. `~/.config/orbit/config.yaml` — user default

Schema: [`schemas/config.schema.yaml`](../schemas/config.schema.yaml) (`configVersion: 1`).

Validate:

```bash
./skill/orbit/scripts/validate_config.sh ~/.config/orbit/config.yaml
# or:
./skill/orbit/scripts/validate_config.sh "$WORKSPACE_ROOT/.orbit/config.work.yaml"
```

Private work file:

```bash
mkdir -p "$WORKSPACE_ROOT/.orbit"
cp configs/examples/config.work.yaml.example "$WORKSPACE_ROOT/.orbit/config.work.yaml"
```

## Major sections

| Section | Purpose |
|---|---|
| `workspace` | Where repos live; runs dir; clone policy |
| `tracker` | Jira provider; **status_map** names; comment templates |
| `docs` | Confluence follow limits (only fetch when URLs present) |
| `forge` | GitHub PR draft/labels/title/body/branch templates |
| `discovery` | Cascade flags, thin-ticket plan approval, optional strict `require_*` |
| `verify` | Org test **profiles** (helm/k8s/local/…) |
| `efficiency` | Layered loops, lean context, doc caps, redistill budget |
| `guardrails` | Step/tool budgets, dry-run, plan approval, redaction |

## Discovery

| Key | Default | Meaning |
|---|---|---|
| `require_ac` | `false` | Block if AC missing after cascade (set `true` for strict) |
| `require_repos` | `false` | Block if repos missing after cascade |
| `require_test_strategy` | `false` | Block if verify path missing after cascade |
| `infer_from_title` | `true` | Synthesize AC from title/description when thin |
| `codebase_fallback` | `true` | Search `workspace.root` for repos when ticket lacks them |
| `thin_ticket_plan_approval` | `always` | Force plan gate when `brief.confidence != high` |
| `ask_user_on_ambiguity` | `true` | Ask once when cascade still ambiguous |

## Efficiency

| Key | Default | Meaning |
|---|---|---|
| `layered_loops` | `true` | Prefer distill artifacts then execute |
| `max_redistills` | `1` | Max replan returns to distill (`0` in lean profile) |
| `reuse_distill_if_fresh_hours` | `24` | Skip distill if fresh artifacts exist |
| `max_doc_pages` | `3` | Cap Confluence fetches in distill |
| `compact_context` | `true` | Prefer run artifacts over re-fetching raw docs |
| `lean_context` | `true` | Execute reads `brief.json` + `plan.md` only unless replan |
| `skip_confluence_if_no_links` | `true` | Skip docs MCP when ticket has no Confluence URLs |

### Token playbook

1. Copy [`configs/examples/jira-github.lean.yaml`](../configs/examples/jira-github.lean.yaml) as a starting point
2. Use `@orbit` in Agent chat (skill does not auto-invoke)
3. Dry-run first (`guardrails.dry_run: true` or dry-run example)
4. Keep `max_redistills: 0` and tight `max_agent_steps` / `max_total_tool_calls` until comfortable

## Verify profiles

Example (illustrative):

```yaml
verify:
  mode: runbook_first
  forbid_assume_unit_tests_only: true
  default_profile: unit_local
  profiles:
    wok:
      kind: helm
      runbook_hints: ["wok", "helm", "namespace"]
      prerequisites: ["VPN", "kubecontext"]
      agent_may_execute: false
      success_signals: ["pods ready", "smoke checks"]
    unit_local:
      kind: local_commands
      commands: ["make test"]
      agent_may_execute: true
      success_signals: ["tests exit 0"]
```

After cascade exhaustion with no matching profile, Orbit may infer a light `custom` strategy (README/Makefile checks) with `agent_may_execute: false`.

`agent_may_execute: false` means Orbit prepares steps and waits for you to run heavy environments.

## Examples

- [`configs/examples/jira-github.basic.yaml`](../configs/examples/jira-github.basic.yaml)
- [`configs/examples/jira-github.lean.yaml`](../configs/examples/jira-github.lean.yaml)
- [`configs/examples/jira-github.draft-pr-rich.yaml`](../configs/examples/jira-github.draft-pr-rich.yaml)
- [`configs/examples/jira-github.dry-run.yaml`](../configs/examples/jira-github.dry-run.yaml)
- [`configs/examples/config.work.yaml.example`](../configs/examples/config.work.yaml.example)

## Work overrides

Keep private work config out of git:

```text
$workspace.root/.orbit/config.work.yaml
```

Ignored via `**/.orbit/config.work.yaml` and `**/config.work.yaml`.
