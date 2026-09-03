# Work validation

Validate Orbit privately at work **without** committing employer data to the public repo.

## Private config

```bash
mkdir -p "$WORKSPACE_ROOT/.orbit"
cp /path/to/orbit/configs/examples/config.work.yaml.example \
   "$WORKSPACE_ROOT/.orbit/config.work.yaml"
# edit real status names, PR template, verify.profiles (e.g. your helm/full-stack flow)
```

`config.work.yaml` is gitignored and takes precedence over `~/.config/orbit/config.yaml`.

## Protocol

1. Start with `guardrails.dry_run: true` in the work config (or use `jira-github.lean.yaml` for token savings)
2. Dry-run 3 tickets (bug, feature, chore) — inspect `distill.md` quality and `brief.discovery_source` / `confidence`
3. Thin tickets should produce inferred briefs with plan approval — not always `BRIEF_INCOMPLETE`
4. Flip dry-run off for one low-risk ticket → draft PR → fill scorecard
5. Track: brief-block rate, verify outcomes, accept / accept_with_edits / reject
6. Tighten `verify.profiles` / PR templates from failure codes — not skill hardcoding

## Data boundary

| Allowed in public git | Private only |
|---|---|
| Synthetic fixtures + `config.work.yaml.example` | Real tickets, Confluence, remotes |
| Example configs | `.orbit/config.work.yaml` |
| Docs / schemas | Scorecards with internal URLs |

## Success bar

- Dry-run useful on most sampled tickets
- At least one human-accepted draft PR (`accept` or `accept_with_edits`)
