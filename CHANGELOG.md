# Changelog

## [0.4]

### Added
- **Autotile region sheet visualization** - New `autotileRegionSheet` generated tile type for debugging autotile tilesets
  - Displays the complete region of an autotile with a numbered grid overlay
  - Helps visually identify which tile index corresponds to which visual tile in the source image
  - Syntax: `generated(autotileRegionSheet("autotileName", scale, "font", fontColor))`
  - Scales tiles but keeps font at original size for readability on small tiles (e.g., 8x8)
- **Negative range parameters** - Range definitions now support negative numbers (e.g., `param:-50..150`)
- **Conditionals demo** - Comprehensive demo showing all conditional features:
  - `@(param=>value)` exact match, `@(param=>!value)` negation
  - `@(param=>[v1,v2])` multiple values, `@(p1=>v1, p2=>v2)` combined conditions
  - Range conditions: `greaterThanOrEqual`, `lessThanOrEqual`, `between`
  - `@ifstrict` - requires ALL parameters to match (partial params = no match)
- **Autotile system** - New root-level element for procedural terrain generation
  - Formats: `cross` (13 tiles), `blob47` (47-tile full coverage)
  - Neighbor-based tile selection with inner/outer corner handling
  - Demo mode with `demo: edgeColor, fillColor` for placeholder tile visualization
- **Autotile reference syntax** - Reference autotile demo tiles in generated() expressions
  - By index: `generated(autotile("autotileName", 0))` - select tile by index
  - By edges: `generated(autotile("autotileName", N+E+S+W))` - select tile by neighbor flags
  - Edge flags: `N`, `E`, `S`, `W` (cardinals), `NE`, `SE`, `SW`, `NW` (corners)
- **Font management** - `FontManager.registerFont()` with optional X/Y offset for positioning normalization
- **Graphics coordinates** - `line()` and `polygon()` now support all coordinate types (hexCorner, hexEdge, grid, layout)
- **New fonts** - f3x5, m3x6, pixeled6, pixellari, peaberry-white, peaberry-white-outline
- **Test infrastructure** - HTML report generator with visual diffs, improved test runner

### Fixed
- **GridDirection conditional validation** - Fixed `gridDirection` parameter validation in conditionals accepting only 0-3 instead of full 0-7 range (8 directions)
- **Anim parser negative frame indices** - Added validation to reject negative frame indices in `.anim` playlist `frames:` ranges
- **Text alignment with scale** - Center/right alignment now works correctly at any scale factor
- **Graphics line parsing** - `GELine` and `GEPolygon` use `Coordinates` type instead of individual floats

### Changed
- **Quiet test output** - Tests now only show errors by default; use `test.bat run -v` for verbose output
- **HTML report overlay** - Image lightbox now uses 100% opaque background
- Updated all test examples with consistent styling and smaller label fonts (m3x6)
- Improved hex coordinate demo showing both pointy and flat orientations with corner/edge labels
