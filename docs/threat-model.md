# Threat model

## Assets

- Jira/Confluence content (may include sensitive business data)
- Source repos and credentials (`gh`, MCP tokens)
- Cloud accounts implied by verify profiles (e.g. EKS)

## Actors

- User running Cursor Agent
- Ticket/runbook authors (untrusted text → prompt injection risk)
- Malicious PR content in dependencies (out of scope for v1 agent core)

## Controls

| Threat | Mitigation |
|---|---|
| Prompt injection via ticket/docs | Fail closed; guardrails override ticket text; no merge |
| Secret leakage | Redaction patterns; forbid dumping `.env` into comments |
| Arbitrary repo clone | Optional `repo_allowlist`; clone only under workspace root |
| Destructive git | No force-push; no merge; draft PR default |
| Cost blowups | `max_agent_steps`, `max_total_tool_calls`, two-pass distill |
| Heavy cluster accidents | `agent_may_execute: false` by default for helm/k8s profiles |

## Reporting

See [SECURITY.md](../SECURITY.md).
