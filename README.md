# Orbit

**Cursor-oriented, config-driven ticket agentic system.**

Give Orbit a Jira ticket key. It discovers work from Jira + linked docs, ensures repos under your workspace, implements against acceptance criteria, verifies using **your** org’s test strategy (not assumed unit tests), opens draft PRs, updates Jira statuses from **your** config, and leaves a scorecard you can judge.

> A **skill** is a playbook. **Orbit** is an agentic system: goal → plan → tools → observe → durable run state → repeat, with plug-and-play config and guardrails.

## Quickstart

### Prerequisites

- [Cursor](https://cursor.com) with Agent
- Jira + Confluence MCP configured in Cursor
- GitHub CLI (`gh`) authenticated for non-dry-run PR flows
- Python 3 + dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pyyaml jsonschema
```

### Install skills into Cursor

```bash
git clone https://github.com/sidDarthVader31/orbit.git
cd orbit
./scripts/install_skills.sh
```

### First-run setup

In Cursor Agent:

```text
orbit-setup
```

You will set workspace root, Jira status names, PR templates/labels, and how your org tests (e.g. a helm-based full-stack env). Config is written to `~/.config/orbit/config.yaml`.

### Run a ticket

```text
implement PROJ-123
```

(Use the **orbit** skill.)

Dry-run (no Jira transitions / no PRs): start from `configs/examples/jira-github.dry-run.yaml` or set `guardrails.dry_run: true`.

## What you get each run

Under `workspace.root/.orbit/runs/<ticket>-<timestamp>/`:

| Artifact | Purpose |
|---|---|
| `distill.md` | Pass A digest (reload cheaply in Pass B) |
| `brief.json` | Structured goal + test strategy |
| `run.json` | Phase state machine |
| `events.jsonl` | Structured trace |
| `scorecard.md` | Human judgment |

## Design highlights

- **No org hardcoding** — statuses, PR body/labels, verify profiles are config
- **Two-pass efficiency** — distill once; execute from artifacts (subscription-friendly)
- **Org-aware verify** — runbook-first; profiles like helm/k8s/local commands
- **Fail closed** — unclear AC/repos/test strategy → block, don’t invent
- **Never auto-merge** in v1

## Documentation

- [Architecture](docs/architecture.md)
- [Configuration](docs/configuration.md)
- [Quickstart](docs/quickstart.md)
- [Work validation](docs/work-validation.md)
- [Threat model](docs/threat-model.md)
- [Skill vs system (presentation FAQ)](docs/presentation-faq.md)
- [Release checklist](docs/release-checklist.md)

## Limitations (honest)

- v1 is **Cursor-hosted** (loop runs while an Agent chat is active) — not a background daemon
- Quality depends on ticket + runbook clarity and MCP tool quality
- Not affiliated with Atlassian, Cursor, or GitHub

## License

Apache-2.0 — see [LICENSE](LICENSE).
