# Release checklist

Before tagging a public release:

## Packaging

- [ ] LICENSE present
- [ ] CHANGELOG updated
- [ ] `configVersion` documented
- [ ] `./scripts/install_skills.sh` works on a clean machine
- [ ] No employer data in tree or git history
- [ ] `.gitignore` covers work configs, runs, `.env`

## Quality

- [ ] CI green (schema validate + shellcheck)
- [ ] Example configs validate
- [ ] Synthetic fixture documented
- [ ] Dry-run manual checklist passed once

## Docs

- [ ] README prerequisites + limitations honest
- [ ] configuration.md matches schema
- [ ] SECURITY.md / SUPPORT.md present

## Work validation (private)

- [ ] At least one accepted real draft PR using private config
- [ ] Failure codes observed and sane

Then: `git tag v0.1.0 && git push origin v0.1.0`
