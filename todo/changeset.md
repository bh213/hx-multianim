# Changeset — Property Access & Coordinate System Overhaul

## Summary

Replaced old function-call coordinate syntax (`hex()`, `hexCorner()`, `grid()`) with property/method access syntax (`$hex.cube()`, `$hex.corner()`, `$grid.pos()`). Added `.x`/`.y` extraction for using coordinate values in expressions. Removed silent `macro 0` fallbacks in codegen — all unsupported cases now produce compile-time errors.

## New Syntax

### Coordinate Methods
| Old Syntax | New Syntax |
|------------|-----------|
| `grid(x, y)` | `$grid.pos(x, y)` |
| `grid(x, y, ox, oy)` | `$grid.pos(x, y, ox, oy)` |
| `hex(q, r, s)` | `$hex.cube(q, r, s)` |
| `hexCorner(index, scale)` | `$hex.corner(index, scale)` |
| `hexEdge(direction, scale)` | `$hex.edge(direction, scale)` |
| *(new)* | `$hex.offset(col, row, even\|odd)` |
| *(new)* | `$hex.doubled(col, row)` |
| *(new)* | `$hex.pixel(x, y)` |

### Property Access
| Syntax | Description |
|--------|-------------|
| `$grid.width`, `$grid.height` | Grid cell spacing |
| `$hex.width`, `$hex.height` | Hex cell dimensions |
| `$ctx.width`, `$ctx.height` | Element size at runtime |
| `$ctx.random(min, max)` | Random value |

### Named Coordinate Systems
```manim
#test programmable() {
    grid: #small 10, 10
    grid: #big 40, 40
    bitmap(tile): $small.pos(1, 0)
    bitmap(tile): $big.pos(1, 0)
}
```
Access via `$small.pos(x, y)`, `$big.pos(x, y)`, `$small.width`, etc.

### Value Extraction (.x / .y)
Any coordinate method call can have `.x` or `.y` appended to extract a single component as a numeric value. Works in **expression context** (bitmap dimensions, color params, text interpolation), not in position context:
```manim
bitmap(generated(color($grid.pos($n, 0).x + 5, $grid.pos($n, 0).y, #f00))): 0, 0
text(dd, '${$hex.corner(0, 1.0).x}', #fff): 0, 0
```

## Files Changed

### Parser (`MacroManimParser.hx`)
- Added `TDot` token to lexer
- `parseXY()` rewritten to handle `$ref.method(args)` coordinate syntax
- Named coordinate system parsing in programmable body (`grid: #name spacingX, spacingY`)
- `$ctx`, `$grid`, `$hex` reserved — cannot be used as parameter names
- New AST variants: `RVPropertyAccess`, `RVMethodCall`, `RVChainedMethodCall`
- New Coordinates enum variants: `SELECTED_HEX_CUBE`, `SELECTED_HEX_OFFSET`, `SELECTED_HEX_DOUBLED`, `SELECTED_HEX_PIXEL`, `SELECTED_HEX_CELL_CORNER`, `SELECTED_HEX_CELL_EDGE`, `NAMED_COORD`
- `MultiAnimParser.parseFile()` now delegates to `MacroManimParser.parseFile()` (hxparse removed)

### Builder (`MultiAnimBuilder.hx`)
- `resolveRVMethodCallToPoint()` — resolves grid/hex method calls to FPoint
- `resolveRVChainedMethodCall()` — extracts .x/.y from coordinate FPoint
- Supports all hex methods: corner, edge, cube, offset, doubled, pixel
- `NAMED_COORD` in `calculatePosition()` — looks up named system and recurses with correct grid/hex
- Named system routing: checks `isNamedGrid` before entering grid branch, preventing hex methods on named systems from erroring

### Codegen (`ProgrammableCodeGen.hx`)
- `resolveMethodCallToStaticPoint()` — compile-time static resolution
- `resolveHexMethodToStaticPoint()` — hex-specific static resolution
- `resolveMethodCallToRuntimeComponentExpr()` — runtime Haxe expression generation
- `ensureHexLayoutForExprRV()` — generates `_hexLayout` field when needed
- **Removed all silent `macro 0` fallbacks** — replaced with `Context.error()` for:
  - Unknown `$ctx` properties/methods
  - Wrong argument counts
  - Unknown refs for property/method access
  - Unsupported chained properties (not .x/.y)

### .manim Files Migrated
All existing `.manim` files updated from old syntax to new syntax.

## Tests
- All 79/79 visual tests pass
- Parser tests added for new syntax validation and error cases
- Builder unit tests added for coordinate value correctness
