---
name: orbit-setup
description: >-
  First-run and reconfiguration wizard for Orbit. Collects workspace root,
  Jira status names, PR templates/labels, and org verify profiles (e.g. helm/wok),
  then writes ~/.config/orbit/config.yaml. Use when the user says orbit-setup,
  ticket-agent setup, configure Orbit, or when orbit config is missing/invalid.
disable-model-invocation: true
---

# Orbit setup

You configure **Orbit** — a Cursor-oriented ticket agentic system. Org policy lives in config, never in skill prose.

## Goal

Produce a valid `~/.config/orbit/config.yaml` (configVersion: 1) matching `schemas/config.schema.yaml`, then stop. Do **not** implement a ticket during setup.

## Steps

1. Locate this repo (Orbit checkout). Prefer the workspace containing `schemas/config.schema.yaml`.
2. Run `skill/orbit/scripts/validate_config.sh` if a config already exists; if valid, ask whether to reconfigure or abort.
3. Ask the user **one concise batch** of questions (fill sensible defaults from `configs/examples/jira-github.basic.yaml`):

   - Workspace root (default `~/Documents/codebase`)
   - Jira status names exactly as on their board: start, local_test, pr_review, optional blocked
   - Transition statuses? (yes/no → `tracker.transition_enabled`)
   - PR: draft yes/no, labels list, title template, body template (offer default from `templates/pr-body.default.md`)
   - How does this org verify changes? Free text is OK (e.g. “helm chart wok on EKS”). Map into `verify.profiles` with `kind`, `runbook_hints`, `prerequisites`, and `agent_may_execute` (default **false** for heavy cluster bring-up).
   - Plan approval: `always` | `never` | `on_multi_repo`
   - Dry-run default?
   - Layered-loops efficiency on? (default yes → `efficiency.layered_loops`)
   - Max redistills on context gap? (default 1 → `efficiency.max_redistills`)

4. Write config to `~/.config/orbit/config.yaml` with `configVersion: 1` and `guardrails.disallow_merge: true`.
5. Optionally offer to also write `$workspace.root/.orbit/config.work.yaml` from `configs/examples/config.work.yaml.example` for private work overrides (remind: gitignored, never commit secrets).
6. Create `workspace.root` and `workspace.root/.orbit/runs` if missing.
7. Run `skill/orbit/scripts/validate_config.sh` on the written config and `preflight.sh --config ... --skip-forge` if forge auth unknown yet.
8. Tell the user:

```text
Setup complete.
- User config: ~/.config/orbit/config.yaml
- Optional private override: $workspace/.orbit/config.work.yaml
Next: implement <TICKET> using the orbit skill.
Dry-run first: set guardrails.dry_run true.
```

## Rules

- Never invent org status names or test systems — ask.
- Never embed employer secrets in the Orbit git repo.
- Work-specific overrides may go to `$workspace.root/.orbit/config.work.yaml` (gitignored pattern) — mention this for private validation.
