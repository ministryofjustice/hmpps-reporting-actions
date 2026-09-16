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

## Actions

| Action | Purpose |
|--------|---------|
| [`setup-node-npm`](actions/setup-node-npm) | Setup Node + npm install (`npm run setup` by default) |

## Related

- Orchestrators: `ministryofjustice/hmpps-reporting-workflows`
- CircleCI parity source for Cloud Platform apps: `ministryofjustice/hmpps-circleci-orb` (`hmpps@11`)
