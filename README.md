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

Pushing to `main` auto-creates the next patch tags via
[`.github/workflows/release.yml`](.github/workflows/release.yml)
(`v1.0.0` + moving `v1` / `v1.0`). Use **workflow_dispatch** for minor/major.

## Actions

| Action | Purpose |
|--------|---------|
| [`setup-node-npm`](actions/setup-node-npm) | Setup Node + npm install (`npm run setup` by default) |
| [`bump-version`](actions/bump-version) | Apply version bump, commit, tag, open PR |
| [`update-sentry-release-secret`](actions/update-sentry-release-secret) | Patch a k8s secret key (default `RELEASE_GIT_SHA`) with the deployed git SHA |

Used from `hmpps-reporting-workflows` (`node_validate`, `pr_checks`, `deploy_env`) and from app
stubs (`bump-version.yml`).

### `update-sentry-release-secret`

Assumes kubectl is already authenticated (e.g. by `deploy_env`). Does not create
the secret — Cloud Platform Terraform does not manage Sentry secrets; the secret
must already exist in the target namespace.

```yaml
- uses: ministryofjustice/hmpps-reporting-actions/actions/update-sentry-release-secret@v1
  with:
    secret-name: hmpps-digital-prison-reporting-mi-ui-sentry
    release-sha: ${{ steps.sentry-sha.outputs.sha }}
    # secret-key: RELEASE_GIT_SHA   # default
    namespace: ${{ secrets.KUBE_NAMESPACE }}
```

## Related

- Orchestrators: `ministryofjustice/hmpps-reporting-workflows`
- CircleCI parity source for Cloud Platform apps: `ministryofjustice/hmpps-circleci-orb` (`hmpps@11`)
