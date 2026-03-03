# Test Review v1 — Reference Notes

Review completed. All recommendations implemented.

## Known Limitations (not actionable, for reference)

- **test30 (Blob47Fallback)**: pre-existing reference image mismatch (not a regression, documented in testing-and-debugging.md)
- **TextInput codegen**: builder-only (test89), codegen planned post-1.0 (TODO.md #15)
- **PVFactory settings**: builder-only by design (test77)

## Untested Codegen Limitations

No negative tests exist for these codegen-specific errors:
1. `RVArray`/`RVArrayReference` in codegen throws
2. Runtime `.x`/`.y` extraction from grid/hex throws in codegen

## Key Behavioral Diffs (Builder vs Incremental vs Codegen)

| Scenario | Builder | Incremental | Codegen |
|----------|---------|------------|---------|
| `BITMAP` param change | Full rebuild | No re-tile (static) | Typed field, no setParameter for tile source |
| `STATEANIM`/`PARTICLES`/`TILEGROUP` | Full support | Static (built once) | Delegates to builder at runtime |
| Param-dependent repeat count | Full rebuild | Tracked — removes + rebuilds | Rebuild — removes + recreates |
| `RVArray`/`RVArrayReference` | Full support | Full support | Throws |
| Runtime `.x`/`.y` extraction | Full support | Full support | Throws |
| Hot reload | Yes (MULTIANIM_DEV) | Yes (MULTIANIM_DEV) | No |
| Transitions | N/A (full rebuild) | Full (IncrementalUpdateContext) | Full (CodegenTransitionHelper) |
