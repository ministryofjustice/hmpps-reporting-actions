# hmpps-reporting-actions

Composite (and later JS) GitHub Actions for HMPPS Digital Prison Reporting.

This repo holds **step-level building blocks**. Full job pipelines and approval /
deploy orchestration live in
[`hmpps-reporting-workflows`](https://github.com/ministryofjustice/hmpps-reporting-workflows).

Consuming app repos should normally call **workflows**, not these actions
directly. Reusable workflows in `hmpps-reporting-workflows` call into this repo.

## Layout

```text
actions/<name>/action.yml   # public composite actions
docs/versioning.md          # tag / pin convention
```

## Versioning

Pin to a semver major tag (e.g. `@v1`), never `@main`. See
[`docs/versioning.md`](docs/versioning.md).

**MoJ org policy:** consuming workflows that `uses:` a composite action
from this repo must pin a **full commit SHA** (not `@v1`). Recommended form:

```yaml
uses: ministryofjustice/hmpps-reporting-actions/actions/setup-node-npm@2f0798b99b99d4b1fda8540e7dbce0ad0e9d890f # v1.0.2
```

Pushing to `main` auto-creates the next patch tags via
[`.github/workflows/release.yml`](.github/workflows/release.yml)
(`v1.0.0` + moving `v1` / `v1.0`). Use **workflow_dispatch** for minor/major.

## Actions

| Action | Purpose |
|--------|---------|
| [`setup-node-npm`](actions/setup-node-npm) | Setup Node + npm install (`npm run setup` by default) |
| [`bump-version`](actions/bump-version) | Apply version bump, commit, tag, open PR |

Used from `hmpps-reporting-workflows` (`node_validate`, `pr_checks`) and from app
stubs (`bump-version.yml`).

## Related

- Orchestrators: `ministryofjustice/hmpps-reporting-workflows`
- CircleCI parity source for Cloud Platform apps: `ministryofjustice/hmpps-circleci-orb` (`hmpps@11`)
