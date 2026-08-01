# Contributing

Thanks for interest in Orbit.

## Development

1. Fork and clone
2. `./scripts/install_skills.sh`
3. `pip install pyyaml jsonschema`
4. Change schemas/skills/scripts/docs as needed
5. Ensure example configs still validate (CI does this)
6. Open a PR with a clear summary

## Guidelines

- No employer-specific data, remotes, or runbooks in the public repo
- Prefer config/schema changes over hardcoding policy in skills
- Keep skills explicit about fail-closed behavior
- Update `docs/` when changing user-facing contracts

## Code of conduct

Be respectful. Harassment and abuse are not tolerated.
