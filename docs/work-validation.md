# Work validation

Validate Orbit privately at work **without** committing employer data to the public repo.

## Protocol

1. `orbit-setup` with real board status names + PR template + verify profile
2. Keep secrets in MCP/`gh` auth only — never in git
3. Dry-run 3 tickets (bug, feature, chore)
4. Full run on one low-risk ticket → draft PR → fill scorecard
5. Track: brief-block rate, verify outcomes, accept / accept_with_edits / reject
6. Iterate config/skills; then consider tagging a release

## Data boundary

| Allowed in public git | Private only |
|---|---|
| Synthetic fixtures | Real tickets, Confluence, remotes |
| Example configs | `config.work.yaml` |
| Docs / schemas | Scorecards with internal URLs |

## Success bar before calling it “working”

- Dry-run useful on most sampled tickets
- At least one human-accepted draft PR (`accept` or `accept_with_edits`)
