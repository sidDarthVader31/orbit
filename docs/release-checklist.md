# Release checklist

Before tagging a public release:

## Packaging

- [x] LICENSE present
- [x] CHANGELOG updated
- [x] `configVersion` documented
- [x] `./scripts/install_skills.sh` works
- [x] No employer data in tree (examples only)
- [x] `.gitignore` covers work configs, runs, `.env`

## Quality

- [x] Example configs validate (local + CI workflow)
- [x] Synthetic fixture documented (`tests/fixtures/synthetic-ticket/`)
- [x] Distill/execute framed as layered loops in `skill/orbit/SKILL.md`
- [x] Private work template: `configs/examples/config.work.yaml.example`
- [x] Schema/examples rename `two_pass` → `layered_loops` + `max_redistills`
- [ ] CI green on `main` after push (check Actions)
- [ ] Dry-run against a real work ticket (private; not required to cut scaffold tag)

## Docs

- [x] README: architecture, prerequisites, install, usage, work config, limitations
- [x] configuration.md matches schema + work override order
- [x] SECURITY.md / SUPPORT.md present

## Work validation (private — post-tag OK for v0.1.0 scaffold)

- [ ] At least one accepted real draft PR using `config.work.yaml`
- [ ] Failure codes observed and sane

## Tag

v0.1.0 = public scaffold release. Work-proven validation continues privately after tag.

```bash
git tag v0.1.0
git push origin v0.1.0
```
