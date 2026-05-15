# Release Process

## Overview

Releases are **driven by merging `haxelib.json` to `main`**. The CI workflow detects the version change, builds, tags, creates a GitHub Release, and publishes to Haxelib — all automatically. The only manual step is the merge.

## Prerequisites

- GitHub repo secret `HAXELIB_PASSWORD` must be configured in repo settings
- Haxelib account registered (`haxelib register`) with publish access to `hx-multianim`

## Release Steps

### 1. Pre-release Checks (on dev)

```bash
# All tests pass
test.bat run

# Library compiles on both targets
haxe hx-multianim.hxml -hl build/hl-manim.hl -D message.reporting=pretty -D resourcesPath=test/res
haxe hx-multianim.hxml -js build/js-manim.js -D message.reporting=pretty -D resourcesPath=test/res
```

### 2. Bump Version

Edit `haxelib.json`:
- `version` — follows restricted SemVer: `major.minor.patch[-alpha|beta|rc[.N]]`
- `releasenote` — brief summary of changes

Haxelib versions **cannot be overwritten** once submitted. Always bump for any release.

### 3. Update CHANGELOG

In `CHANGELOG.md`:
- Set the date on the current section header (e.g. `## [1.0.0-rc.5] - 2026-05-15`)
- Add a new `[next-dev]` section at the top for future work

### 4. Merge to main

Open a PR from `dev` → `main` (or fast-forward) including the bumped `haxelib.json` and CHANGELOG. Merge it.

That's it. The merge to `main` (where `haxelib.json` is in the diff) fires `.github/workflows/release-and-publish.yml`, which does the rest.

### 5. CI Workflow (Automatic)

The workflow performs:
1. Checkout + Haxe 4.3.6 + Lix setup
2. Read version from `haxelib.json`
3. Check if `v<version>` tag already exists — if so, skip everything (idempotent on re-runs)
4. Build library (HashLink + JavaScript targets)
5. Verify build artifacts exist
6. **Create and push the `v<version>` git tag**
7. Create a GitHub Release pointing at the tag
8. **Publish to Haxelib** via `haxelib submit . $HAXELIB_PASSWORD --always`

Both GitHub Release and Haxelib publish run for **every** version, including RCs (`-rc.N`, `-alpha`, `-beta`). The `--always` flag suppresses haxelib's interactive confirmation prompt.

### 6. Post-release Verification

- Verify the GitHub Release appeared at `https://github.com/bh213/hx-multianim/releases`
- Verify the package at `https://lib.haxe.org/p/hx-multianim/`

## Version Strategy

| Version | Meaning |
|---------|---------|
| `0.x.y` | Unstable API, breaking changes expected |
| `1.0.0-rc.N` | Release candidate, published to both GitHub Releases and Haxelib |
| `1.0.0` | First stable release |
| `1.x.y` | Stable API, semver guarantees apply |

## Manual Release (Fallback)

If CI is unavailable, run the workflow's steps locally from a clean checkout of `main`:

```bash
# Build and verify
haxe hx-multianim.hxml -hl build/hl-manim.hl -D message.reporting=pretty -D resourcesPath=test/res
haxe hx-multianim.hxml -js build/js-manim.js -D message.reporting=pretty -D resourcesPath=test/res

# Tag + push
VERSION=$(python3 -c "import json; print(json.load(open('haxelib.json'))['version'])")
git tag "v$VERSION"
git push origin "v$VERSION"

# Submit to Haxelib (prompts for password if not piped)
haxelib submit . --always
```

GitHub Release for the tag must be created manually via `gh release create v$VERSION`.

## CI Workflow Details

The workflow (`.github/workflows/release-and-publish.yml`) triggers on:

```yaml
on:
  push:
    branches: [main]
    paths: ['haxelib.json']
```

Any push to `main` that modifies `haxelib.json` starts a release attempt. If the version in `haxelib.json` already has a corresponding `v<version>` tag on origin, every subsequent step short-circuits — so no-op bumps and re-runs are safe.

### Tag creation

The workflow creates the tag itself rather than reacting to a manually pushed one:

```yaml
- name: Create git tag
  if: steps.check.outputs.exists == 'false'
  run: |
    git tag "v${{ steps.version.outputs.version }}"
    git push origin "v${{ steps.version.outputs.version }}"
```

**Do not manually pre-push the tag** — the "tag already exists" guard would then skip the entire release.

### `softprops/action-gh-release@v2`

Creates a GitHub Release from the tag:

```yaml
- uses: softprops/action-gh-release@v2
  with:
    tag_name: v${{ steps.version.outputs.version }}
    generate_release_notes: false
    body: |
      Release ${{ steps.version.outputs.version }}
      See [CHANGELOG.md](CHANGELOG.md) for details.
```

- Tag name pinned explicitly (the workflow is not running on a tag ref, so `tag_name` is required)
- `generate_release_notes: false` — we use CHANGELOG instead of GitHub's auto-generated notes
- Uses the default `GITHUB_TOKEN`; requires `permissions: contents: write` (set at workflow scope)

### Haxelib publish

```yaml
- name: Publish to Haxelib
  if: steps.check.outputs.exists == 'false'
  env:
    HAXELIB_PASSWORD: ${{ secrets.HAXELIB_PASSWORD }}
  run: haxelib submit . $HAXELIB_PASSWORD --always
```

`.` packages the current directory using `classPath` from `haxelib.json`. `--always` suppresses the "submit version X.Y.Z? (y/n)" prompt that would otherwise hang in non-interactive CI.

## File Reference

| File | Role |
|------|------|
| `haxelib.json` | Package metadata, version, releasenote — bumping this on `main` fires the release |
| `CHANGELOG.md` | Human-readable change history |
| `.github/workflows/release-and-publish.yml` | CI release automation |
| `.haxelib` | Lix dependency lock (not related to publishing) |
