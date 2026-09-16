# Versioning

`hmpps-reporting-actions` is versioned like
`hmpps-reporting-workflows`: consumers pin a **semver git tag**, never `@main`.

## Tagging convention

- Tags are plain semver: `v1`, `v1.0.0`, `v1.1.0`, `v2.0.0`.
- A **major** tag (`v1`, `v2`, …) always points at the latest release within
  that major line and is force-moved on non-breaking releases.
- A **full** tag (`v1.0.0`) is immutable.
- Recommended default: pin `@v1`.

## Breaking vs non-breaking

**Breaking** (new major): remove/rename an action path; remove/rename an
input/output; make an optional input required; change default behaviour a
caller would notice.

**Non-breaking**: add optional inputs with defaults; add a new action;
bugfixes that keep the declared contract; docs-only changes.

## Release process

Tags are created automatically by [`.github/workflows/release.yml`](../.github/workflows/release.yml):

1. Land on `main` via PR.
2. Push to `main` → **patch** bump by default (`vX.Y.Z`, plus moving `vX` / `vX.Y`).
3. For **minor** / **major**, run **Actions → Release tags** and choose the bump.
4. Workflows that call this repo can keep pinning `@v1`; retag workflows after
   actions releases when they depend on new action behaviour.

Bootstrap (no full tags yet): first run creates `v1.0.0`, `v1.0`, and `v1`.
