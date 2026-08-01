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
| `docs` | Confluence follow limits |
| `forge` | GitHub PR draft/labels/title/body/branch templates |
| `discovery` | Required AC/repos/test strategy |
| `verify` | Org test **profiles** (helm/k8s/local/…) |
| `efficiency` | Layered loops, redistill budget, freshness, doc caps |
| `guardrails` | Step/tool budgets, dry-run, plan approval, redaction |

## Efficiency

| Key | Meaning |
|---|---|
| `layered_loops` | Prefer distill artifacts then execute (default true) |
| `max_redistills` | Max replan returns to distill on context gap (default 1) |
| `reuse_distill_if_fresh_hours` | Skip distill if fresh artifacts exist |
| `max_doc_pages` | Cap Confluence fetches in distill |
| `compact_context` | Prefer run artifacts over re-fetching raw docs |

## Verify profiles

Example (illustrative):

```yaml
verify:
  mode: runbook_first
  forbid_assume_unit_tests_only: true
  profiles:
    wok:
      kind: helm
      runbook_hints: ["wok", "helm", "namespace"]
      prerequisites: ["VPN", "kubecontext"]
      agent_may_execute: false
      success_signals: ["pods ready", "smoke checks"]
```

`agent_may_execute: false` means Orbit prepares steps and waits for you to run heavy environments.

## Examples

- [`configs/examples/jira-github.basic.yaml`](../configs/examples/jira-github.basic.yaml)
- [`configs/examples/jira-github.draft-pr-rich.yaml`](../configs/examples/jira-github.draft-pr-rich.yaml)
- [`configs/examples/jira-github.dry-run.yaml`](../configs/examples/jira-github.dry-run.yaml)
- [`configs/examples/config.work.yaml.example`](../configs/examples/config.work.yaml.example)

## Work overrides

Keep private work config out of git:

```text
$workspace.root/.orbit/config.work.yaml
```

Ignored via `**/.orbit/config.work.yaml` and `**/config.work.yaml`.
