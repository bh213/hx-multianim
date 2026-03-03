# Release Process

## Overview

Releases are tag-driven. Pushing a `v*` tag triggers the CI workflow which builds, validates, creates a GitHub Release, and publishes to Haxelib.

## Prerequisites

- GitHub repo secret `HAXELIB_PASSWORD` must be configured in repo settings
- Haxelib account registered (`haxelib register`) with publish access to `hx-multianim`

## Release Steps

### 1. Pre-release Checks

```bash
# All tests pass
test.bat run

# Library compiles on both targets
haxe hx-multianim.hxml -hl build/hl-manim.hl -D message.reporting=pretty -D resourcesPath=test/res
haxe hx-multianim.hxml -js build/js-manim.js -D message.reporting=pretty -D resourcesPath=test/res

# Local haxelib validation
haxelib dev hx-multianim .
```

### 2. Version Bump

Edit `haxelib.json`:
- `version` — follows restricted SemVer: `major.minor.patch[-alpha|beta|rc[.N]]`
- `releasenote` — brief summary of changes

Haxelib versions **cannot be overwritten** once submitted. Always bump for any change.

### 3. Update CHANGELOG

In `CHANGELOG.md`:
- Rename `[X.Y.Z-dev]` header to the release version (e.g., `[1.0.0-rc.1]`)
- Set the date
- Add a new `[next-dev]` section at the top for future work

### 4. Commit and Tag

```bash
git add haxelib.json CHANGELOG.md
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push && git push --tags
```

The tag push triggers `.github/workflows/release-and-publish.yml`.

### 5. CI Workflow (Automatic)

The workflow performs:
1. Checkout + Haxe 4.3.6 + Lix setup
2. Build library (HashLink + JavaScript targets)
3. Verify build output exists
4. Validate tag version matches `haxelib.json` version
5. Create GitHub Release with link to CHANGELOG
6. Publish to Haxelib via `haxelib submit`

**RC versions** (`-rc`, `-alpha`, `-beta`) skip the Haxelib publish step — GitHub Release only.

### 6. Post-release

- Verify the GitHub Release appeared at `https://github.com/bh213/hx-multianim/releases`
- For non-RC releases: verify package at `https://lib.haxe.org/p/hx-multianim/`
- Start new `[next-dev]` section in CHANGELOG

## Version Strategy

| Version | Meaning |
|---------|---------|
| `0.x.y` | Unstable API, breaking changes expected |
| `1.0.0-rc.N` | Release candidate, GitHub Release only (no Haxelib) |
| `1.0.0` | First stable release, published to Haxelib |
| `1.x.y` | Stable API, semver guarantees apply |

## Manual Release (Fallback)

If CI is unavailable:

```bash
# Build and verify locally
haxe hx-multianim.hxml -hl build/hl-manim.hl -D message.reporting=pretty -D resourcesPath=test/res
haxe hx-multianim.hxml -js build/js-manim.js -D message.reporting=pretty -D resourcesPath=test/res

# Submit directly (prompts for password if not piped)
haxelib submit .
```

## CI Workflow Details

The workflow (`.github/workflows/release-and-publish.yml`) uses standard build actions plus one release-specific action:

### `softprops/action-gh-release@v2`

Creates a GitHub Release from the pushed tag. Config:

```yaml
- uses: softprops/action-gh-release@v2
  with:
    generate_release_notes: false
    body: |
      Release ${{ steps.version.outputs.version }}
      See [CHANGELOG.md](CHANGELOG.md) for details.
```

- Automatically uses the tag name as the release title
- `generate_release_notes: false` — we use CHANGELOG instead of GitHub's auto-generated notes
- Requires no extra token config (uses default `GITHUB_TOKEN`)
- Docs: https://github.com/softprops/action-gh-release

### Haxelib publish gating

```yaml
- name: Publish to Haxelib
  if: ${{ !contains(steps.version.outputs.version, 'rc') }}
```

The `if` condition skips `haxelib submit` for RC versions. This means tagging `v1.0.0-rc.1` creates a GitHub Release but does not publish to Haxelib. Tagging `v1.0.0` does both.

### Version validation

The workflow extracts the version from `haxelib.json` via Python and compares it to the tag:

```yaml
TAG_VERSION=${GITHUB_REF#refs/tags/v}
if [ "$VERSION" != "$TAG_VERSION" ]; then exit 1; fi
```

This prevents accidental mismatches between tag and package metadata.

## File Reference

| File | Role |
|------|------|
| `haxelib.json` | Package metadata, version, releasenote |
| `CHANGELOG.md` | Human-readable change history |
| `.github/workflows/release-and-publish.yml` | CI release automation |
| `.haxelib` | Lix dependency lock (not related to publishing) |
