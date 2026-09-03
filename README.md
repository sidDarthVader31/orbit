# Orbit

**Cursor-oriented, config-driven ticket agentic system.**

Give Orbit a Jira ticket key. It discovers work from Jira + linked docs, ensures repos under your workspace, implements against acceptance criteria, verifies using **your** org’s test strategy (not assumed unit tests), opens draft PRs, updates Jira statuses from **your** config, and leaves a scorecard you can judge.

> A **skill** is a playbook. **Orbit** is an agentic system: goal → plan → tools → observe → durable run state → repeat, with plug-and-play config and guardrails.

**Repo:** [github.com/sidDarthVader31/orbit](https://github.com/sidDarthVader31/orbit) · **Version:** see [`VERSION`](VERSION)

---

## Table of contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Install](#install)
4. [Configure](#configure)
5. [How to use](#how-to-use)
6. [Run artifacts](#run-artifacts)
7. [Private work config](#private-work-config)
8. [Efficiency & guardrails](#efficiency--guardrails)
9. [Documentation](#documentation)
10. [Limitations](#limitations)
11. [License](#license)

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│  Goal: Jira ticket key (e.g. PROJ-123)                        │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Orchestrator: Cursor Agent + `orbit` skill (policy)          │
│  Config: ~/.config/orbit/config.yaml (+ optional work override)│
└───────────────┬─────────────────────────┬───────────────────┘
                ▼                         ▼
        ┌───────────────┐         ┌───────────────┐
        │ Tools         │         │ Memory / run  │
        │ Jira MCP      │         │ distill.md    │
        │ Confluence MCP│         │ brief.json    │
        │ git / gh      │         │ run.json      │
        │ shell / tests │         │ scorecard.md  │
        └───────────────┘         └───────────────┘
```

### Layered loops (cost-aware)

| Loop | What happens |
|---|---|
| **Outer** | Phase machine in `run.json` |
| **Distill** | Research until `distill.md` + `brief.json` validate (cascade: Confluence → ticket → infer → codebase) |
| **Execute** | Reload artifacts → repos → implement → verify (retry) → draft PR → Jira → scorecard |
| **Replan** | On context gap, re-enter distill up to `efficiency.max_redistills` |

### Phase machine

```text
setup_check → preflight → distill → brief_validate → ensure_repos →
[plan_approval?] → tracker_start → implement → tracker_local_test →
verify → open_prs → tracker_pr_review → scorecard → done | blocked | failed
```

### Skill vs system (one line)

| Piece | Role |
|---|---|
| `orbit` / `orbit-setup` skills | Policy playbooks for Cursor |
| Config YAML | Your statuses, PR rules, verify profiles |
| Scripts + schemas | Enforceable contracts |
| Cursor Agent | The agentic **loop** runtime |
| Run folder | Durable memory + judgment |

Details: [docs/architecture.md](docs/architecture.md)

---

## Prerequisites

| Requirement | Why |
|---|---|
| [Cursor](https://cursor.com) with **Agent** | Hosts the agent loop |
| **Jira** + **Confluence** MCP enabled in Cursor | Ticket + runbook intake |
| [`gh`](https://cli.github.com/) authenticated | Clone/PR for non-dry-run (`gh auth login`) |
| Python 3 + venv deps | Config validation / preflight scripts |
| Git | Ensure/clone repos under workspace root |

```bash
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

---

## Install

```bash
git clone https://github.com/sidDarthVader31/orbit.git
cd orbit
./scripts/install_skills.sh          # symlinks into ~/.cursor/skills/
# or: ./scripts/install_skills.sh copy
```

Confirm:

```bash
ls -la ~/.cursor/skills/orbit ~/.cursor/skills/orbit-setup
```

---

## Configure

### First-run wizard (recommended)

In Cursor Agent:

```text
orbit-setup
```

You will set:

- Workspace root (where repos are cloned)
- Exact Jira status names (`start` / `local_test` / `pr_review` / optional `blocked`)
- Whether to transition tickets or comment-only
- PR draft flag, labels, title/body templates
- How your org **verifies** changes (e.g. helm full-stack env) → `verify.profiles`
- Plan approval, dry-run, layered-loops efficiency

Writes: `~/.config/orbit/config.yaml` (`configVersion: 1`).

### Or copy an example

```bash
mkdir -p ~/.config/orbit
cp configs/examples/jira-github.basic.yaml ~/.config/orbit/config.yaml
# edit status names, PR templates, verify.profiles
./skill/orbit/scripts/validate_config.sh ~/.config/orbit/config.yaml
```

| Example | Use when |
|---|---|
| [`configs/examples/jira-github.basic.yaml`](configs/examples/jira-github.basic.yaml) | Minimal Jira + GitHub (robust defaults) |
| [`configs/examples/jira-github.lean.yaml`](configs/examples/jira-github.lean.yaml) | Max token savings — tight budgets, no redistill |
| [`configs/examples/jira-github.draft-pr-rich.yaml`](configs/examples/jira-github.draft-pr-rich.yaml) | Richer PR body + sample helm-style verify profile |
| [`configs/examples/jira-github.dry-run.yaml`](configs/examples/jira-github.dry-run.yaml) | Discovery/plan only (no mutations) |
| [`configs/examples/config.work.yaml.example`](configs/examples/config.work.yaml.example) | Template for **private** work override |

Full field reference: [docs/configuration.md](docs/configuration.md)

### Config resolution order

1. `$workspace.root/.orbit/config.work.yaml` — **private work override** (gitignored)
2. `$workspace.root/.orbit/config.yaml` — workspace override
3. `~/.config/orbit/config.yaml` — user default
4. Missing/invalid → run **orbit-setup**

---

## How to use

### 1. Dry-run a ticket (recommended first)

```text
@orbit implement PROJ-123
```

Use `@orbit` (skill has `disable-model-invocation`). For lowest token use, copy [`jira-github.lean.yaml`](configs/examples/jira-github.lean.yaml) or set `guardrails.dry_run: true`.

Expect: `distill.md` / `brief.json` with AC, repos, and test strategy — **no** Jira transitions and **no** PRs.

### 2. Full run

1. Set `guardrails.dry_run: false`
2. In Agent: `implement PROJ-123` (**orbit** skill)
3. Approve plan if prompted (`plan_approval`)
4. If verify profile has `agent_may_execute: false` (e.g. heavy helm/k8s), Orbit prepares steps and **waits for you** to run the env / confirm smoke
5. Review draft PR(s); **you** merge — Orbit never merges in v1
6. Open the printed `scorecard.md` and mark accept / accept_with_edits / reject

### 3. Resume

```text
resume orbit run for PROJ-123
```

Orbit reads the latest `run.json`, skips completed phases, and avoids duplicate PRs/transitions.

### 4. Reconfigure

```text
orbit-setup
```

---

## Run artifacts

Under `workspace.root/.orbit/runs/<ticket>-<timestamp>/`:

| File | Purpose |
|---|---|
| `distill.md` | Distill-loop human digest (reload in execute loop) |
| `brief.json` | Structured goal + `test_strategy` |
| `plan.md` | Implementation plan |
| `run.json` | Phase / PR / transition state |
| `events.jsonl` | Structured trace |
| `log.md` | Narrative log |
| `scorecard.md` | Human judgment checklist |
| `VERSION` | Orbit version that created the run |

---

## Private work config

Keep employer-specific remotes, status names, and verify profiles **out of git**.

```bash
# from your workspace root (e.g. ~/Documents/codebase)
mkdir -p .orbit
cp /path/to/orbit/configs/examples/config.work.yaml.example .orbit/config.work.yaml
# edit .orbit/config.work.yaml — never commit it
```

`.gitignore` already ignores `**/.orbit/config.work.yaml` and `**/config.work.yaml`.

See [docs/work-validation.md](docs/work-validation.md).

---

## Efficiency & guardrails

| Concern | Mechanism |
|---|---|
| Fewer AI tokens | `jira-github.lean.yaml`, `efficiency.lean_context`, `skip_confluence_if_no_links`, `max_doc_pages: 3`, `max_redistills: 0` (lean), `@orbit` only |
| Thin tickets | Discovery cascade infers AC/repos; `confidence` + mandatory plan approval when not `high` |
| Hard spend caps | `guardrails.max_agent_steps`, `max_total_tool_calls`, `max_verify_retries` |
| Safety | `disallow_merge`, dry-run, repo allowlist, secret redaction, plan gate on low confidence |
| Org testing | `verify.profiles` + runbook-first; inferred light strategy only after cascade |

---

## Documentation

| Doc | Topic |
|---|---|
| [docs/quickstart.md](docs/quickstart.md) | Short path to first run |
| [docs/architecture.md](docs/architecture.md) | Layered loops + system layers |
| [docs/configuration.md](docs/configuration.md) | Full config reference |
| [docs/work-validation.md](docs/work-validation.md) | Private work testing protocol |
| [docs/threat-model.md](docs/threat-model.md) | Security assumptions |
| [docs/release-checklist.md](docs/release-checklist.md) | Cut a release |
| [SECURITY.md](SECURITY.md) / [SUPPORT.md](SUPPORT.md) | Reporting & support scope |

---

## Limitations

- v1 is **Cursor-hosted** (loop runs while an Agent chat is active) — not a background daemon
- Quality depends on ticket clarity; thin tickets are **best-effort** — human plan approval is the safety rail
- Heavy cluster verify (helm/k8s) defaults to **human-executed** steps unless you set `agent_may_execute: true`
- Not affiliated with Atlassian, Cursor, or GitHub

---

## License

Apache-2.0 — see [LICENSE](LICENSE).
