# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 0.x | Best-effort while pre-1.0 |

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Email the maintainer listed on the GitHub profile for [sidDarthVader31/orbit](https://github.com/sidDarthVader31/orbit) with:

- Description and impact
- Reproduction steps
- Orbit version / commit

We will acknowledge and work on a fix before any public disclosure.

## Safe use

- Keep `guardrails.disallow_merge: true`
- Prefer `agent_may_execute: false` for cluster/helm verify profiles
- Use dry-run when evaluating new orgs/tickets
- Never commit MCP tokens, kubeconfigs, or `.env` files
