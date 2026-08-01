# Discovery guide

Orbit must learn **what to build** and **how this org verifies** before the execute loop starts (during the distill loop).

## Sources (priority)

1. Jira issue fields (summary, description, AC custom field if configured, links, comments)
2. Linked Confluence / runbooks (`docs.follow_links_from_ticket`)
3. Matching `verify.profiles` via `runbook_hints`
4. Ask the user if `discovery.ask_user_on_ambiguity` and still unclear
5. **Never invent** cluster/helm workflows

## Extracting repos

Look for:

- Explicit repo URLs or `org/name` references in ticket/runbook
- Service names that map to remotes the user confirms
- Multi-repo change lists in runbooks

Write each as `{ "name", "remote?", "path?" }` for `ensure_repos.sh`.

If `guardrails.repo_allowlist` is set, refuse remotes/names outside it.

## Extracting test strategy

If `verify.forbid_assume_unit_tests_only` (default true), do **not** default to `make test` alone.

Prefer runbook sections: local testing, helm, namespace, smoke, EKS, docker-compose, etc.

Map to brief `test_strategy`:

| Field | Meaning |
|---|---|
| profile | Config profile name if matched (e.g. wok) |
| kind | local_commands / helm / k8s / docker_compose / remote_script / custom |
| steps | Ordered steps distilled from runbook |
| prerequisites | VPN, kubecontext, AWS SSO, … |
| agent_may_execute | From profile or false for heavy envs |
| success_signals | How we know verify passed |

## Blocking

If `discovery.require_test_strategy` and strategy unknown → `BRIEF_INCOMPLETE`.
If AC or repos required and missing → `BRIEF_INCOMPLETE`.
