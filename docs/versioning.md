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

1. Land on `main` via PR.
2. Tag: move major (`git tag -f v1 <sha>`) and cut an immutable full tag
   (`git tag v1.0.0 <sha>`).
3. Workflows that call this repo bump their `@vX` refs as needed and release
   their own tag so app consumers stay on a single workflows pin.
