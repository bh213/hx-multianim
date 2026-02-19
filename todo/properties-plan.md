# Property Access & @final Tile Support Plan

## Problem

1. No way to read tile dimensions in expressions — can't position things relative to `$tile.width`/`$tile.height`
2. `function(gridWidth)` / `function(gridHeight)` syntax is verbose and inconsistent
3. `@final` only stores numeric/string expressions, not tile sources
4. Coordinate system keywords (`hexCorner`, `hexEdge`) are hardcoded in `parseXY` — not extensible

## Proposed Syntax

### Property access: `$ref.property`

```manim
// Tile parameter properties
#centered programmable(icon:tile) {
    bitmap($icon): -$icon.width / 2, -$icon.height / 2
    text(f3x5, "below", #fff): 0, $icon.height + 2
}

// Grid properties (replaces function(gridWidth) / function(gridHeight))
tilegroup(grid(32, 32)) {
    bitmap(generated(color($grid.width, $grid.height, #448844))): grid(0, 0)
}
// Old syntax: function(gridWidth) → $grid.width
// Old syntax: function(gridHeight) → $grid.height

// Hex properties
point {
    hex: pointy(32, 32)
    text(f3x5, $hex.width, #fff): 0, 0     // hex size.x
    text(f3x5, $hex.height, #fff): 0, 10   // hex size.y
}
```

Supported properties:
- **Tile params** (`name:tile`): `.width`, `.height`
- **@final tiles**: `.width`, `.height`
- **Grid** (implicit `$grid`): `.width`, `.height`
- **Hex** (implicit `$hex`): `.width`, `.height` (size dimensions)

### Named coordinate systems (position context)

Instead of hardcoding `hexCorner`, `hexEdge` as keywords in `parseXY`, coordinate systems become named objects that expose methods for position calculation.

```manim
// Default names: $grid, $hex (implicit from grid:/hex: property)
point {
    hex: pointy(32, 32)
    bitmap(...): $hex.corner(0, 1.1)    // replaces hexCorner(0, 1.1)
    bitmap(...): $hex.edge(1, 1.3)      // replaces hexEdge(1, 1.3)
    bitmap(...): $hex.pos(0, 1, -1)     // replaces hex(0, 1, -1)

    pixels(
        line $hex.corner(0, 1.1), $hex.corner(1, 1.1), #f00   // works in pixels() too
    );
}

tilegroup(grid(32, 32)) {
    bitmap(...): $grid.pos(0, 0)              // replaces grid(0, 0)
    bitmap(...): $grid.pos(2, 3, 5, 10)       // replaces grid(2, 3, 5, 10)
}
```

#### Why named coordinate systems?

**Pros:**
- Consistent with property access syntax (`$grid.width` and `$grid.pos(x, y)` are the same object)
- Extensible: if we later add polar, isometric etc — no new parseXY keywords needed
- Could support multiple named grids in the same scope (future)
- Unified mental model: `$grid` is the coordinate system, `.width` reads it, `.pos()` positions with it

**Cons:**
- More complex parsing: `$ref.method(args)` in position context needs to return `Coordinates`
- Currently `hexCorner(0, 1.1)` is 19 chars vs `$hex.corner(0, 1.1)` is 21 chars (slightly longer)
- Breaking change for existing .manim files using `hexCorner`, `hexEdge`, `grid()`, `hex()`

### Approach comparison

#### Approach A: Dual context — keep old keywords, add property access (Recommended)

Keep `grid(x,y)`, `hexCorner(idx, f)`, `hexEdge(dir, f)`, `hex(q,r,s)` as-is in `parseXY`. Add `$ref.property` for scalar access only. Add `$hex.corner()` / `$hex.edge()` / `$grid.pos()` as **alternative** position syntax.

```manim
// Both work:
bitmap(...): hexCorner(0, 1.1)       // old
bitmap(...): $hex.corner(0, 1.1)     // new

// Expression context (new):
bitmap(generated(color($grid.width, $grid.height, #448844))): grid(0, 0)
```

Lowest risk. Old syntax never breaks. New syntax is additive.

#### Approach B: Replace keywords entirely

Remove `hexCorner`, `hexEdge`, `grid()`, `hex()` from parseXY. All coordinate operations go through `$name.method()`.

Cleaner but breaking. Would require updating all existing .manim files.

#### Approach C: Named coordinate systems with custom names (future)

```manim
// Custom name for coordinate system
tilegroup($terrain: grid(64, 64)) {
    bitmap(...): $terrain.pos(0, 0)
    text(..., $terrain.width): 0, 0
}

// Multiple coordinate systems
tilegroup($big: grid(128, 128)) {
    tilegroup($small: grid(32, 32)) {
        bitmap(...): $big.pos(0, 0)     // parent grid
        bitmap(...): $small.pos(5, 5)   // child grid
    }
}
```

This is future work. Current design implicitly names them `$grid` and `$hex`. Named variants can be added later without breaking changes.

### @final with tile value

```manim
@final bg = file("background.png")
@final icon = sheet("atlas", "myIcon")
@final gen = generated(color(16, 16, red))

bitmap($bg): 0, 0
bitmap($icon): $bg.width + 5, 0
text(f3x5, "w=" + $bg.width, #fff): 0, $bg.height + 2
```

---

## Can elements skip `;` for ZERO position?

Current parser (MacroManimParser.hx:2944-2986) expects one of four tokens after an element:

```
TColon     → `: x, y`     parse position
TSemiColon → `;`           ZERO position, done
TCurlyOpen → `{ ... }`    children block
TEof       → error
default    → error
```

### Analysis

**Could we make `;` optional for elements at ZERO?** The parser would fall through to `default:` and treat it as ZERO:

```haxe
default:
    // No explicit position or children — implicit ZERO
    node.pos = ZERO;
    // Don't consume token — it's the start of the next element
```

**Risk: silent error swallowing.** If someone forgets `:` before coordinates:
```manim
bitmap(generated(color(100, 100, white))) 50, 100   // Forgot ':'
```
Without `;` requirement, this would silently give ZERO position and then fail trying to parse `50` as an element name — a confusing error far from the actual mistake.

### Verdict

**Making `;` optional is feasible but NOT recommended.** The semicolon is cheap to type and provides strong error detection. Without it, typos produce confusing errors.

**However**, there's a safe middle ground: `;` could be **optional when followed by `}` or another element keyword.** The parser already knows the set of valid element-starting tokens (`bitmap`, `text`, `point`, `flow`, `@(`, `#name`, etc.). If the next token is one of those or `}`, the previous element clearly ended.

**Suggestion:** defer this change. It adds parser complexity for minimal benefit. Revisit if it becomes a common pain point.

---

## Implementation Changes

### Phase 1: Property access + @final tile (core value)

#### 1. AST — `MultiAnimParser.hx`

**ReferenceableValue enum** — add:
```haxe
RVPropertyAccess(ref:String, property:String);
```

**NodeType enum** — add:
```haxe
FINAL_TILE(name:String, tileSource:TileSource);
```

**ReferenceableValueFunction enum** — keep for backward compat. `$grid.width` resolves via `RVPropertyAccess("grid", "width")`.

#### 2. Lexer — `MacroManimParser.hx`

Add `TDot` token type. In lexer, add to single-char tokens (after `..` double-dot check, after number `.5` parsing):
```
case '.'.code: pos++; return new Token(TDot, startLine, startCol);
```

#### 3. Parser — `MacroManimParser.hx`

**After every `TReference(s)` consumption**, check for `TDot`:

```
case TReference(s):
    advance(); validateRef(s);
    if (match(TBracketOpen)) { ... array access ... }
    if (match(TDot)) {
        prop = expectIdentifier();
        validate prop is "width" or "height"
        return RVPropertyAccess(s, prop);
    }
    return RVReference(s);
```

Locations to update (each has normal + unary-minus variant):
- `parseIntegerOrReference()` — lines ~543-574
- `parseFloatOrReference()` — lines ~627-655
- `parseAnything()` — lines ~792-823

**@final tile parsing** — in `@final` handler (~line 2311):
```
case "final":
    name = expectIdentifier()
    expect(TEquals)
    if peek is "file" or "generated" or "sheet":
        tileSource = parseTileSource()
        return FINAL_TILE(name, tileSource)
    else:
        expr = parseAnything()
        return FINAL_VAR(name, expr)
```

**`$grid` / `$hex` validation** — `validateRef()` should accept `"grid"` and `"hex"` as valid implicit references (not declared parameters, but context-dependent).

**Deprecation of `function(gridWidth/gridHeight)`** — keep parsing for backward compat.

#### 4. Builder — `MultiAnimBuilder.hx`

**`resolveAsInteger()`** — add case:
```haxe
case RVPropertyAccess(ref, property):
    if (ref == "grid") {
        final grid = getGridCoordinateSystem(currentNode);
        return switch property { case "width": grid.spacingX; case "height": grid.spacingY; }
    }
    if (ref == "hex") {
        final hex = getHexCoordinateSystem(currentNode);
        return switch property {
            case "width": Std.int(hex.hexLayout.size.x);   // or however size is stored
            case "height": Std.int(hex.hexLayout.size.y);
        }
    }
    // Otherwise resolve tile
    final param = indexedParams.get(ref);
    final tile = switch param { case TileSourceValue(ts): loadTileSource(ts); }
    return switch property { case "width": Std.int(tile.width); case "height": Std.int(tile.height); }
```

Same for `resolveAsNumber()` (returns Float) and `resolveAsString()` (returns toString).

**`FINAL_TILE` handling** — store as `TileSourceValue(tileSource)` in `indexedParams`:
```haxe
case FINAL_TILE(name, tileSource):
    indexedParams.set(name, TileSourceValue(tileSource));
```

Update `cleanupFinalVars()` to also clean `FINAL_TILE`.

#### 5. Codegen — `ProgrammableCodeGen.hx`

**`rvToExpr()`** — add case:
```haxe
case RVPropertyAccess(ref, property):
    if (ref == "grid") {
        final grid = getGridFromCurrentNode();
        return switch property { case "width": macro $v{grid.spacingX}; case "height": macro $v{grid.spacingY}; }
    }
    if (ref == "hex") {
        final hex = getHexFromCurrentNode();
        return switch property {
            case "width": macro $v{hex.hexLayout.size.x};
            case "height": macro $v{hex.hexLayout.size.y};
        }
    }
    if (finalTileSources.exists(ref)) {
        // Generate tile loading + property access inline
    }
    // Parameter tile
    final fieldExpr = macro $p{["this", "_" + ref]};
    return switch property {
        case "width": macro Std.int(cast($fieldExpr, h2d.Tile).width);
        case "height": macro Std.int(cast($fieldExpr, h2d.Tile).height);
    }
```

**`collectParamRefsImpl()`** — add:
```haxe
case RVPropertyAccess(ref, _):
    // same logic as RVReference — track param dependency
```

**`FINAL_TILE`** — store in `finalTileSources:Map<String, TileSource>`.

**TSReference in tile source codegen** — when generating bitmap code, check if ref name is in `finalTileSources` to inline the tile loading.

### Phase 2: Named coordinate methods in position context (optional, additive)

This extends `parseXY()` to support `$ref.method(args)` returning `Coordinates`:

#### Changes to `parseXY()` in `MacroManimParser.hx`

Add a new case at the **top** of the `parseXY()` switch for `TReference`:

```haxe
function parseXY():Coordinates {
    switch (peek()) {
        case TReference(s):
            // Could be $grid.pos(x, y), $hex.corner(idx, f), $hex.edge(dir, f), $hex.pos(q, r, s)
            advance(); validateRef(s);
            expect(TDot);
            final method = expectIdentifier();
            return parseCoordinateMethod(s, method);

        case TIdentifier(s) if (isKeyword(s, "grid")):
            // ... existing grid parsing (kept for backward compat)
        // ... rest unchanged
    }
}

function parseCoordinateMethod(ref:String, method:String):Coordinates {
    if (ref == "grid" || /* check if ref is a known grid name */) {
        switch (method) {
            case "pos":
                expect(TOpen);
                final x = parseIntegerOrReference();
                expect(TComma);
                final y = parseIntegerOrReference();
                if (match(TComma)) {
                    final ox = parseIntegerOrReference();
                    expect(TComma);
                    final oy = parseIntegerOrReference();
                    expect(TClosed);
                    return SELECTED_GRID_POSITION_WITH_OFFSET(x, y, ox, oy);
                }
                expect(TClosed);
                return SELECTED_GRID_POSITION(x, y);
        }
    }
    if (ref == "hex" || /* check if ref is a known hex name */) {
        switch (method) {
            case "corner":
                expect(TOpen);
                final dir = parseIntegerOrReference();
                expect(TComma);
                final factor = parseFloatOrReference();
                expect(TClosed);
                return SELECTED_HEX_CORNER(dir, factor);
            case "edge":
                expect(TOpen);
                final dir = parseIntegerOrReference();
                expect(TComma);
                final factor = parseFloatOrReference();
                expect(TClosed);
                return SELECTED_HEX_EDGE(dir, factor);
            case "pos":
                expect(TOpen);
                final q = parseInteger();
                expect(TComma);
                final r = parseInteger();
                expect(TComma);
                final sv = parseInteger();
                eatComma();
                expect(TClosed);
                if (q + r + sv != 0) error("q + r + s must be 0");
                return SELECTED_HEX_POSITION(new Hex(q, r, sv));
        }
    }
    error('unknown coordinate method: $ref.$method');
}
```

**Note:** This reuses existing `Coordinates` enum values — no changes needed in builder or codegen for position resolution. The only change is in parsing.

**Validation concern:** At parse time, we don't know whether `$ref` is a grid or hex system (it could be a parameter name). Options:
1. **Parse-time:** Only accept `$grid` and `$hex` as coordinate system refs (hardcoded names) — simple, matches phase 1
2. **Defer validation:** Parse `$ref.method(args)` generically, validate at build time — more flexible for future named systems
3. **Track declarations:** When `grid:` or `hex:` properties are parsed, register the scope name — most correct but complex

**Recommendation:** Start with option 1 (hardcoded `$grid`/`$hex`). The parser only enters `parseCoordinateMethod` when it sees `$grid.` or `$hex.` at the start of a position.

### Phase 3: Custom named coordinate systems (future)

```manim
// Custom name via property syntax
tilegroup {
    $terrain: grid(64, 64);        // or: grid($terrain, 64, 64);
    bitmap(...): $terrain.pos(0, 0)
}

// Multiple grids
tilegroup {
    $big: grid(128, 128);
    $small: grid(32, 32);
    bitmap(...): $big.pos(0, 0)
    bitmap(...): $small.pos(5, 5)
}
```

This would require:
- New node property: `namedCoordinateSystems: Map<String, CoordinateSystemDef>`
- Builder: resolve named systems from scope chain
- Codegen: generate system lookups

**Defer to future.** Current design with implicit `$grid`/`$hex` names is sufficient.

---

## Backward Compatibility — `function(gridWidth/gridHeight)`

**Option A (recommended):** Keep both syntaxes. Old `function(gridWidth)` still works. New `$grid.width` is preferred. Remove old syntax in a future release.

**Option B:** Remove `RVFunction`, `ReferenceableValueFunction` enum, `parseFunction()`, and `resolveRVFunction()`. Update all .manim files. Cleaner but breaking.

## Files to Modify

| File | Phase | Changes |
|------|-------|---------|
| `src/bh/multianim/MultiAnimParser.hx` | 1 | Add `RVPropertyAccess`, `FINAL_TILE` |
| `src/bh/multianim/MacroManimParser.hx` | 1 | Add `TDot`, parse `.property`, parse `@final tile`, validate `$grid`/`$hex` |
| `src/bh/multianim/MacroManimParser.hx` | 2 | Add `$ref.method()` handling in `parseXY()` |
| `src/bh/multianim/MultiAnimBuilder.hx` | 1 | Resolve `RVPropertyAccess` (tile + grid + hex), handle `FINAL_TILE` |
| `src/bh/multianim/ProgrammableCodeGen.hx` | 1 | Codegen for `RVPropertyAccess`, `FINAL_TILE` |
| `src/bh/multianim/CoordinateSystems.hx` | — | No changes needed (reuses existing enum values) |

## .manim Files Using `function(gridWidth/gridHeight)` (if migrating)

- `playground/public/assets/autotileDemo.manim` (1 usage)
- `playground/public/assets/examples1.manim` (18 usages)
- `test/examples/56-codegenGridFunc/codegenGridFunc.manim` (4 usages)

## .manim Files Using `hexCorner`/`hexEdge` (if migrating to `$hex.corner`/`$hex.edge`)

- `test/examples/1-hexGridPixels/hexGridPixels.manim` (~30 usages in pixels + positions)
- `test/examples/47-codegenHexPos/codegenHexPos.manim` (~20 usages)

## Test Plan

1. Compile: `haxe hx-multianim.hxml`
2. Existing tests pass: `test.bat run`
3. **Phase 1 test** (next available number):
   - Tile param + `$t.width` / `$t.height` in positions and @final
   - `@final bg = file(...)` + `$bg.width` in expression
   - `$grid.width` / `$grid.height` replacing `function(gridWidth/gridHeight)`
   - `$hex.width` / `$hex.height` in expression context
4. **Phase 2 test** (if implementing):
   - `$hex.corner(0, 1.1)` and `$hex.edge(1, 1.3)` as position specifiers
   - `$grid.pos(x, y)` as position specifier
   - Mix of old (`hexCorner`) and new (`$hex.corner`) in same file
5. Generate references: `test.bat gen-refs`
