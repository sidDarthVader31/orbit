# Configuration reference

Orbit reads:

1. `$workspace.root/.orbit/config.yaml` (override)
2. `~/.config/orbit/config.yaml` (default)

Schema: [`schemas/config.schema.yaml`](../schemas/config.schema.yaml) (`configVersion: 1`).

Validate:

```bash
./skill/orbit/scripts/validate_config.sh ~/.config/orbit/config.yaml
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
| `efficiency` | Two-pass distill, freshness, doc caps |
| `guardrails` | Step/tool budgets, dry-run, plan approval, redaction |

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

## Work overrides

Keep private work config out of git:

```text
$workspace.root/.orbit/config.work.yaml
```

Documented pattern is gitignored via `**/config.work.yaml` and `**/.orbit/config.work.yaml`.
