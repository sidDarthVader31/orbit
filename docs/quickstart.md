# Quickstart

1. Clone Orbit and run `./scripts/install_skills.sh`
2. Ensure Jira + Confluence MCP work in Cursor
3. `pip install pyyaml jsonschema`
4. In Agent: `orbit-setup`
5. Optional: copy an example config and edit
6. `implement PROJ-123` with the **orbit** skill
7. Open the printed `scorecard.md` path and judge the run

## First successful dry-run

1. Set `guardrails.dry_run: true`
2. Run a well-documented ticket
3. Confirm distill-loop output (`distill.md`) has AC, repos, and test strategy
4. Confirm no Jira transitions / PRs occurred
