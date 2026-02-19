# Property Access, Context Variables & Named Coordinate Systems Plan

## Problem

1. No way to read tile dimensions in expressions — can't position things relative to `$tile.width`/`$tile.height`
2. `function(gridWidth)` / `function(gridHeight)` syntax is verbose and inconsistent — **remove entirely** (will be superseded by things like `tile.sub(...)` in a future version)
3. `@final` only stores numeric/string expressions, not tile sources
4. Coordinate system keywords (`hexCorner`, `hexEdge`, `grid()`, `hex()`) are hardcoded in `parseXY` — not extensible
5. No access to current scope's coordinate system or screen-level properties from expressions
6. No way to name coordinate systems and access them from descendants

## Key Decisions

- **Remove old keywords entirely.** `hexCorner`, `hexEdge`, `grid()`, `hex()` as position keywords are removed. All coordinate access goes through `$name.method()` syntax. Existing `.manim` files must be updated.
- **Remove `function()` entirely.** The current `parseFunction()` is trivial — it only handles two cases: `function(gridWidth)` → `RVFGridWidth` and `function(gridHeight)` → `RVFGridHeight`, both returning `ReferenceableValueFunction` enum values. These are replaced by `$grid.width` and `$grid.height`. Delete `parseFunction()`, `ReferenceableValueFunction` enum, `RVFunction`, and all resolution code. No deprecation period.
- **Semicolons required.** Do not skip `;` — it provides strong error detection.
- **`$ctx`** is the scope context variable (screen dimensions, current coordinate systems, etc.).
- **`$ctx.width`/`$ctx.height` are runtime-reactive** — they read from `h2d.Scene` and reflect actual screen size, including after resize events.
- **Use Hex.hx coordinate systems as-is.** `Hex` = integer cube coords (q+r+s=0), `FractionalHex` = float cube coords. `HexLayout` provides `hexToPixel`, `polygonCorner`, `polygonEdge`, `pixelToHex`. Axial uses cube coordinates (axial is just cube with s omitted since s = -q-r).
- **Support fractional hex coordinates.** `$hex.cube(q, r, s)` accepts float args via `FractionalHex`, rounds to nearest `Hex` for `hexToPixel`. Useful for interpolation and sub-cell positioning.

---

## Proposed Syntax

### 1. Property access: `$ref.property`

```manim
// Tile parameter properties
#centered programmable(icon:tile) {
    bitmap($icon): -$icon.width / 2, -$icon.height / 2;
    text(f3x5, "below", #fff): 0, $icon.height + 2;
}

// Grid properties
tilegroup(grid(32, 32)) {
    bitmap(generated(color($grid.width, $grid.height, #448844))): $grid.pos(0, 0);
}

// Hex properties
point {
    hex: pointy(32, 32);
    text(f3x5, $hex.width, #fff): 0, 0;      // hex size.x from HexLayout.size
    text(f3x5, $hex.height, #fff): 0, 10;     // hex size.y from HexLayout.size
}
```

Supported properties:
- **Tile params** (`name:tile`): `.width`, `.height`
- **@final tiles**: `.width`, `.height`
- **Grid** (implicit `$grid`): `.width`, `.height` (spacingX, spacingY)
- **Hex** (implicit `$hex`): `.width`, `.height` (HexLayout.size.x, HexLayout.size.y)

### 2. Context variable: `$ctx`

`$ctx` provides access to the current scope's runtime state. **`$ctx.width`/`$ctx.height` are reactive** — they read from `h2d.Scene.width`/`h2d.Scene.height` at build/render time, not baked at compile time. If the screen resizes, these values update.

```manim
// Screen dimensions (reactive — updates on resize)
text(f3x5, "Screen: " + $ctx.width + "x" + $ctx.height, #fff): 0, 0;
bitmap(...): $ctx.width - 100, $ctx.height - 50;    // position relative to screen edge

// Current coordinate system access
point {
    hex: pointy(32, 32);
    bitmap(...): $ctx.hex.corner(0, 1.1);   // nearest hex system in scope
    text(f3x5, $ctx.hex.width, #fff): 0, 0;
}

tilegroup(grid(32, 32)) {
    bitmap(...): $ctx.grid.pos(0, 0);       // nearest grid system in scope
    text(f3x5, $ctx.grid.width, #fff): 0, 0;
}
```

#### `$ctx` properties

| Property | Type | Description |
|----------|------|-------------|
| `$ctx.width` | Float | Screen/scene width from `h2d.Scene`. **Runtime-reactive.** |
| `$ctx.height` | Float | Screen/scene height from `h2d.Scene`. **Runtime-reactive.** |
| `$ctx.hex` | HexCoordSystem | Nearest hex coordinate system in scope (same as `$hex` when unnamed) |
| `$ctx.grid` | GridCoordSystem | Nearest grid coordinate system in scope (same as `$grid` when unnamed) |
| `$ctx.random(min, max)` | Int | Random integer in [min, max) range. Inclusive min, exclusive max. |

```manim
// Random integer between 0 (inclusive) and 100 (exclusive)
text(f3x5, $ctx.random(0, 100), #fff): 0, 0;

// Random position offset
bitmap(...): $ctx.random(0, 200), $ctx.random(0, 150);
```

**Note:** `$ctx.hex` and `$hex` are equivalent when no named coordinate systems are in play. `$ctx` is primarily useful for screen dimensions and for clarity when multiple coordinate systems exist.

#### Implementation of reactive `$ctx.width`/`$ctx.height`

**Builder (runtime):** Straightforward — read `h2d.Scene.width`/`h2d.Scene.height` at resolve time. Since the builder runs at render time, the values are always current.

**Codegen (compile-time macros):** Cannot bake screen dimensions as compile-time constants. Instead, generate code that reads from the scene at runtime:
```haxe
// Generated code for $ctx.width:
this.getScene().width   // or passed-in scene reference
```

This means expressions containing `$ctx.width`/`$ctx.height` (and other reactive properties) cannot be fully resolved at compile time — the codegen must emit runtime expressions rather than constant values. This already has precedent: parameter references (`$paramName`) generate runtime field reads.

### 3. Named coordinate systems

Coordinate systems can be named at declaration, making them available through all descendants.

```manim
// Named hex coordinate system
point {
    hex: #localhex pointy(32, 32);
    bitmap(...): $localhex.corner(0, 1.1);
    bitmap(...): $localhex.edge(1, 1.3);
    bitmap(...): $localhex.cube(0, 1, -1).hexCorner(0, 1.1);
    text(f3x5, $localhex.width, #fff): 0, 0;

    // Works in all children — inherited through scope
    point {
        bitmap(...): $localhex.corner(3, 1.0);
    }
}

// Named grid coordinate system
tilegroup {
    grid: #terrain 64, 64;
    bitmap(...): $terrain.pos(0, 0);

    tilegroup {
        grid: #detail 16, 16;
        bitmap(...): $terrain.pos(0, 0);    // parent's grid
        bitmap(...): $detail.pos(5, 5);     // child's grid
    }
}

// $ctx.hex / $ctx.grid always resolves to the nearest coordinate system
// regardless of its name
point {
    hex: #myhex pointy(32, 32);
    bitmap(...): $ctx.hex.corner(0, 1.0);    // same as $myhex.corner(0, 1.0)
}
```

Unnamed coordinate systems are still supported — they're accessed via the implicit names `$grid` and `$hex`:

```manim
point {
    hex: pointy(32, 32);          // unnamed → accessible as $hex
    bitmap(...): $hex.corner(0, 1.1);
}
```

### 4. Hex coordinate methods

Hex.hx uses **cube coordinates** (q, r, s where q+r+s=0). Axial is a subset (just q, r — s is derived). We use `cube` as the method name since it maps directly to the `Hex` class, and support both integer and fractional coordinates.

#### `$hex.cube(q, r, s)` — integer cube coordinates

Maps directly to `new Hex(q, r, s)` → `HexLayout.hexToPixel(hex)`.

```manim
point {
    hex: pointy(32, 32);

    // Position at hex cell center — uses Hex(1, 0, -1)
    bitmap(...): $hex.cube(1, 0, -1);

    // Chained with corner/edge offset
    bitmap(...): $hex.cube(0, 1, -1).hexCorner(0, 1.1);
    bitmap(...): $hex.cube(0, 1, -1).hexCorner(0);         // factor defaults to 1.0
    bitmap(...): $hex.cube(0, 1, -1).hexEdge(2, 1.3);

    // Extract single coordinate for expressions
    text(f3x5, $hex.cube(0, 1, -1).hexCorner(0, 1.1).x, #fff): 0, 0;
    text(f3x5, $hex.cube(0, 1, -1).hexCorner(0, 1.1).y, #fff): 0, 10;
}
```

**Validation:** Parser enforces `q + r + s == 0` for integer args (same as `Hex` constructor). With expression/reference args, validation defers to build time.

#### `$hex.cube(q, r, s)` — fractional cube coordinates

When any of q, r, s are floats, uses `FractionalHex(q, r, s).round()` → `HexLayout.hexToPixel(hex)`.

```manim
point {
    hex: pointy(32, 32);

    // Fractional hex — rounds to nearest cell
    bitmap(...): $hex.cube(0.5, 0.5, -1.0);

    // Useful with expressions
    bitmap(...): $hex.cube($q, $r, -$q - $r);
}
```

**Implementation:** `parseFloatOrReference()` is used for all three args. At resolve time:
- If all three are integers → `new Hex(q, r, s)` directly
- If any is fractional → `new FractionalHex(q, r, s).round()` → `Hex`

Note: `FractionalHex` already validates `round(q+r+s) == 0`.

Since `Hex.hexToPixel` only accepts `Hex` (not `FractionalHex`), fractional values are rounded. If sub-cell precision is needed in the future, we could add `fractionalHexToPixel` to `HexLayout` — but for now, rounding is sufficient and consistent with `FractionalHex.round()` which is already used for line drawing etc.

#### `$hex.corner(index [, factor])` / `$hex.edge(index [, factor])`

Corner/edge of hex cell at origin (0, 0, 0). Already supported by `HexLayout.polygonCorner(Hex.zero(), ...)` and `HexLayout.polygonEdge(Hex.zero(), ...)`.

```manim
point {
    hex: pointy(32, 32);
    bitmap(...): $hex.corner(0, 1.1);       // replaces old hexCorner(0, 1.1)
    bitmap(...): $hex.edge(1, 1.3);         // replaces old hexEdge(1, 1.3)
    bitmap(...): $hex.corner(0);            // factor defaults to 1.0
}
```

#### `$hex.offset(col, row [, parity])` — offset coordinates

Converts offset coordinates to cube, then to pixel. Uses `OffsetCoord.qoffsetToCube()` or `roffsetToCube()` from Hex.hx.

```manim
point {
    hex: pointy(32, 32);

    // q-offset (default for pointy), even parity (default)
    bitmap(...): $hex.offset(3, 2);                  // OffsetCoord.qoffsetToCube(EVEN, col=3, row=2)
    bitmap(...): $hex.offset(3, 2, odd);             // OffsetCoord.qoffsetToCube(ODD, col=3, row=2)

    // Chaining works the same as cube
    bitmap(...): $hex.offset(3, 2).hexCorner(0, 1.1);
}

point {
    hex: flat(32, 32);

    // r-offset (default for flat)
    bitmap(...): $hex.offset(3, 2);                  // OffsetCoord.roffsetToCube(EVEN, col=3, row=2)
}
```

**Parity:** `even` (default) or `odd`. Maps to `OffsetCoord.EVEN` (1) / `OffsetCoord.ODD` (-1).

**Orientation determines offset type:** Pointy → q-offset (`qoffsetToCube`), Flat → r-offset (`roffsetToCube`). This follows the standard hex convention.

#### `$hex.doubled(col, row)` — doubled coordinates

Converts doubled coordinates to cube, then to pixel. Uses `DoubledCoord.qdoubledToCube()` or `rdoubledToCube()` from Hex.hx.

```manim
point {
    hex: pointy(32, 32);

    // q-doubled (default for pointy)
    bitmap(...): $hex.doubled(3, 5);                 // DoubledCoord.qdoubledToCube(col=3, row=5)

    // Chaining works
    bitmap(...): $hex.doubled(3, 5).hexCorner(0, 1.1);
}

point {
    hex: flat(32, 32);

    // r-doubled (default for flat)
    bitmap(...): $hex.doubled(5, 3);                 // DoubledCoord.rdoubledToCube(col=5, row=3)
}
```

**Orientation determines doubled type:** Pointy → q-doubled (`qdoubledToCube`), Flat → r-doubled (`rdoubledToCube`).

#### `$hex.pixel(x, y)` — pixel to hex (reverse mapping)

Converts pixel coordinates to the nearest hex cell, then back to pixel (snaps to cell center). Uses `HexLayout.pixelToHex()` → `FractionalHex.round()` → `hexToPixel()`.

```manim
point {
    hex: pointy(32, 32);

    // Snap pixel position to nearest hex center
    bitmap(...): $hex.pixel(100, 75);

    // Useful with expressions — which hex cell is this pixel in?
    text(f3x5, $hex.pixel(100, 75).x, #fff): 0, 0;
}
```

#### Chaining summary

| Expression | Result type | Maps to |
|-----------|-------------|---------|
| `$hex.cube(q, r, s)` | Position | `hexToPixel(Hex(q,r,s))` or `hexToPixel(FractionalHex(q,r,s).round())` |
| `$hex.offset(col, row [, parity])` | Position | `hexToPixel(qoffsetToCube/roffsetToCube(parity, col, row))` |
| `$hex.doubled(col, row)` | Position | `hexToPixel(qdoubledToCube/rdoubledToCube(col, row))` |
| `$hex.pixel(x, y)` | Position | `hexToPixel(pixelToHex(x, y).round())` |
| `$hex.corner(i [, f])` | Position | `polygonCorner(Hex.zero(), i, f)` |
| `$hex.edge(i [, f])` | Position | `polygonEdge(Hex.zero(), i, f)` |
| `...<any above>.hexCorner(i [, f])` | Position | `polygonCorner(hex, i, f)` |
| `...<any above>.hexEdge(i [, f])` | Position | `polygonEdge(hex, i, f)` |
| `...<any above>.x` | Float (expr) | Extract x coordinate |
| `...<any above>.y` | Float (expr) | Extract y coordinate |
| `$hex.width` | Float (expr) | `hexLayout.size.x` |
| `$hex.height` | Float (expr) | `hexLayout.size.y` |

### 5. Grid methods (new syntax, replaces keywords)

```manim
tilegroup(grid(32, 32)) {
    bitmap(...): $grid.pos(0, 0);                // replaces grid(0, 0)
    bitmap(...): $grid.pos(2, 3, 5, 10);         // replaces grid(2, 3, 5, 10) — with offset
}
```

### 6. @final with tile value

```manim
@final bg = file("background.png");
@final icon = sheet("atlas", "myIcon");
@final gen = generated(color(16, 16, red));

bitmap($bg): 0, 0;
bitmap($icon): $bg.width + 5, 0;
text(f3x5, "w=" + $bg.width, #fff): 0, $bg.height + 2;
```

---

## Migration: Old Syntax → New Syntax

Old keywords are **removed** (not deprecated). All existing `.manim` files must be updated.

| Old Syntax | New Syntax |
|-----------|------------|
| `hexCorner(0, 1.1)` | `$hex.corner(0, 1.1)` |
| `hexEdge(1, 1.3)` | `$hex.edge(1, 1.3)` |
| `hex(0, 1, -1)` | `$hex.cube(0, 1, -1)` |
| `grid(0, 0)` | `$grid.pos(0, 0)` |
| `grid(2, 3, 5, 10)` | `$grid.pos(2, 3, 5, 10)` |
| `function(gridWidth)` | `$grid.width` |
| `function(gridHeight)` | `$grid.height` |

### Files to migrate

**`function(gridWidth/gridHeight)` — remove entirely:**
- `playground/public/assets/autotileDemo.manim` (1 usage)
- `playground/public/assets/examples1.manim` (18 usages)
- `test/examples/56-codegenGridFunc/codegenGridFunc.manim` (4 usages)

**`hexCorner`/`hexEdge`/`hex()` → `$hex.corner()`/`$hex.edge()`/`$hex.cube()`:**
- `test/examples/1-hexGridPixels/hexGridPixels.manim` (~30 usages)
- `test/examples/47-codegenHexPos/codegenHexPos.manim` (~20 usages)

**`grid()` → `$grid.pos()`:**
- Any `.manim` files using `grid(x, y)` as position specifier

---

## Implementation

### AST Changes — `MultiAnimParser.hx`

**ReferenceableValue enum** — add:
```haxe
RVPropertyAccess(ref:String, property:String);
RVMethodCall(ref:String, method:String, args:Array<ReferenceableValue>);
RVChainedMethodCall(base:ReferenceableValue, method:String, args:Array<ReferenceableValue>);
```

**NodeType enum** — add:
```haxe
FINAL_TILE(name:String, tileSource:TileSource);
```

**Remove entirely:**
- `ReferenceableValueFunction` enum (`RVFGridWidth`, `RVFGridHeight`)
- `RVFunction(functionType:ReferenceableValueFunction)` from `ReferenceableValue`

### Coordinates enum — `CoordinateSystems.hx`

Extend with new hex addressing modes and cell+sub-cell offset variants:
```haxe
// Existing (reused — corner/edge at origin hex (0,0,0)):
SELECTED_HEX_CORNER(count:RV, factor:RV);
SELECTED_HEX_EDGE(direction:RV, factor:RV);

// Hex cell addressing (all resolve to a Hex, then hexToPixel):
SELECTED_HEX_CUBE(q:RV, r:RV, s:RV);
SELECTED_HEX_OFFSET(col:RV, row:RV, parity:OffsetParity);    // qoffset/roffset based on orientation
SELECTED_HEX_DOUBLED(col:RV, row:RV);                         // qdoubled/rdoubled based on orientation
SELECTED_HEX_PIXEL(x:RV, y:RV);                               // pixelToHex().round() → hexToPixel()

// Cell + sub-cell chained positions:
SELECTED_HEX_CELL_CORNER(cell:Coordinates, cornerIndex:RV, factor:RV);
SELECTED_HEX_CELL_EDGE(cell:Coordinates, direction:RV, factor:RV);
```

Using `ReferenceableValue` args (abbreviated `RV`) instead of `Hex` allows parameter references in coordinates (`$hex.cube($q, $r, -$q - $r)`).

`SELECTED_HEX_CELL_CORNER`/`SELECTED_HEX_CELL_EDGE` take a `Coordinates` as the base cell — this allows chaining from any hex addressing mode (cube, offset, doubled, pixel), not just cube.

The old `SELECTED_HEX_POSITION(hex:Hex)` can be removed in favor of `SELECTED_HEX_CUBE`.

New supporting type:
```haxe
enum OffsetParity {
    EVEN;   // OffsetCoord.EVEN (1)
    ODD;    // OffsetCoord.ODD (-1)
}
```

### Named coordinate system storage

Add to `Node` typedef:
```haxe
namedCoordinateSystems:Null<Map<String, CoordinateSystemDef>>;
```

```haxe
enum CoordinateSystemDef {
    NamedGrid(system:GridCoordinateSystem);
    NamedHex(system:HexCoordinateSystem);
}
```

### Lexer — `MacroManimParser.hx`

Add `TDot` token type. In lexer, after `..` double-dot check and number `.5` parsing:
```
case '.'.code: pos++; return new Token(TDot, startLine, startCol);
```

### Parser — `MacroManimParser.hx`

#### Reference + dot handling in expression context

After every `TReference(s)` consumption, check for `TDot`:

```
case TReference(s):
    advance(); validateRef(s);
    if (match(TBracketOpen)) { ... array access ... }
    if (match(TDot)) {
        return parsePropertyOrMethodChain(s);
    }
    return RVReference(s);
```

`parsePropertyOrMethodChain(ref)`:
```
ident = expectIdentifier()
if (match(TOpen)):
    args = parseMethodArgs()
    expect(TClosed)
    base = RVMethodCall(ref, ident, args)
    while (match(TDot)):
        nextIdent = expectIdentifier()
        if (match(TOpen)):
            args = parseMethodArgs()
            expect(TClosed)
            base = RVChainedMethodCall(base, nextIdent, args)
        else:
            base = RVChainedMethodCall(base, nextIdent, [])  // .x, .y, .width, .height
    return base
else:
    // $ctx.hex or $ctx.grid → sub-object, check for further chaining
    if (ref == "ctx" && (ident == "hex" || ident == "grid")):
        // Treat as $ctx.hex.method() or $ctx.hex.width
        if (match(TDot)):
            return parsePropertyOrMethodChain("ctx." + ident)  // resolve as virtual ref
        return RVPropertyAccess(ref, ident)  // error or returns the system object
    return RVPropertyAccess(ref, ident)
```

Locations to update (each has normal + unary-minus variant):
- `parseIntegerOrReference()`
- `parseFloatOrReference()`
- `parseAnything()`

#### Reference validation

`validateRef()` accepts:
- Declared parameter names (existing)
- `"ctx"` — context variable
- `"grid"` — implicit grid coordinate system
- `"hex"` — implicit hex coordinate system
- Any name registered via `#name` on a coordinate system declaration

#### @final tile parsing

In `@final` handler:
```
case "final":
    name = expectIdentifier()
    expect(TEquals)
    if peek is "file" or "generated" or "sheet":
        tileSource = parseTileSource()
        expect(TSemicolon)
        return FINAL_TILE(name, tileSource)
    else:
        expr = parseAnything()
        expect(TSemicolon)
        return FINAL_VAR(name, expr)
```

#### Remove from `parseXY()`

Remove these cases entirely:
- `isKeyword(s, "grid")` — was `grid(x, y)`
- `isKeyword(s, "hex")` — was `hex(q, r, s)`
- `isKeyword(s, "hexedge")` — was `hexEdge(dir, factor)`
- `isKeyword(s, "hexcorner")` — was `hexCorner(idx, factor)`

#### New `parseXY()` — `$ref.method()` as position

```haxe
function parseXY():Coordinates {
    switch (peek()) {
        case TReference(s):
            advance(); validateRef(s);
            expect(TDot);
            return parseCoordinateMethodChain(s);

        case TIdentifier(s) if (isKeyword(s, "layout")):
            // ... existing layout parsing (kept)

        default:
            final x = parseIntegerOrReference();
            expect(TComma);
            final y = parseIntegerOrReference();
            return OFFSET(x, y);
    }
}
```

`parseCoordinateMethodChain(ref)`:

```haxe
function parseCoordinateMethodChain(ref:String):Coordinates {
    // ref is "hex", "grid", "localhex", "ctx", etc.
    // For $ctx.hex / $ctx.grid, resolve the sub-object first
    var effectiveRef = ref;
    if (ref == "ctx") {
        final sub = expectIdentifier();   // "hex" or "grid"
        expect(TDot);
        effectiveRef = sub;  // now parse as if $hex.method() or $grid.method()
        // Track that this came from $ctx for resolution
    }

    final method = expectIdentifier();
    expect(TOpen);

    if (isGridRef(effectiveRef)) {
        switch (method) {
            case "pos":
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

    if (isHexRef(effectiveRef)) {
        // Parse the hex cell addressing method
        var cellCoord:Coordinates = null;
        switch (method) {
            case "cube":
                final q = parseFloatOrReference();
                expect(TComma);
                final r = parseFloatOrReference();
                expect(TComma);
                final s = parseFloatOrReference();
                expect(TClosed);
                cellCoord = SELECTED_HEX_CUBE(q, r, s);

            case "offset":
                final col = parseIntegerOrReference();
                expect(TComma);
                final row = parseIntegerOrReference();
                var parity = EVEN;
                if (match(TComma)) {
                    final parityIdent = expectIdentifier();
                    parity = switch (parityIdent) {
                        case "even": EVEN;
                        case "odd": ODD;
                        default: error('Expected "even" or "odd", got: $parityIdent');
                    };
                }
                expect(TClosed);
                cellCoord = SELECTED_HEX_OFFSET(col, row, parity);

            case "doubled":
                final col = parseIntegerOrReference();
                expect(TComma);
                final row = parseIntegerOrReference();
                expect(TClosed);
                cellCoord = SELECTED_HEX_DOUBLED(col, row);

            case "pixel":
                final x = parseFloatOrReference();
                expect(TComma);
                final y = parseFloatOrReference();
                expect(TClosed);
                cellCoord = SELECTED_HEX_PIXEL(x, y);

            case "corner":
                final idx = parseIntegerOrReference();
                final factor = if (match(TComma)) parseFloatOrReference() else RVFloat(1.0);
                expect(TClosed);
                return SELECTED_HEX_CORNER(idx, factor);

            case "edge":
                final dir = parseIntegerOrReference();
                final factor = if (match(TComma)) parseFloatOrReference() else RVFloat(1.0);
                expect(TClosed);
                return SELECTED_HEX_EDGE(dir, factor);

            default:
                error('Unknown hex method: $method');
        }

        // Check for chained .hexCorner() / .hexEdge() after any cell addressing method
        if (match(TDot)) {
            return parseHexCellChain(cellCoord);
        }
        return cellCoord;
    }

    error('Unknown coordinate method: $effectiveRef.$method');
}

function parseHexCellChain(cell:Coordinates):Coordinates {
    final chainMethod = expectIdentifier();
    expect(TOpen);
    switch (chainMethod) {
        case "hexCorner":
            final idx = parseIntegerOrReference();
            final factor = if (match(TComma)) parseFloatOrReference() else RVFloat(1.0);
            expect(TClosed);
            return SELECTED_HEX_CELL_CORNER(cell, idx, factor);
        case "hexEdge":
            final dir = parseIntegerOrReference();
            final factor = if (match(TComma)) parseFloatOrReference() else RVFloat(1.0);
            expect(TClosed);
            return SELECTED_HEX_CELL_EDGE(cell, dir, factor);
    }
    error('Unknown hex chain method: $chainMethod');
}
```

#### Named coordinate system declarations

When parsing `hex:` or `grid:` property on a point node, check for `#name`:

```
// In point property parsing:
case "hex":
    expect(TColon);
    var name:String = null;
    if (match(THash)) {
        name = expectIdentifier();
    }
    final orientation = parseHexOrientation();
    expect(TOpen);
    final w = parseFloat_();
    expect(TComma);
    final h = parseFloat_();
    expect(TClosed);
    eatSemicolon();
    final system = {hexLayout: HexLayout.createFromFloats(orientation, w, h)};
    node.hexCoordinateSystem = system;
    if (name != null) {
        if (node.namedCoordinateSystems == null) node.namedCoordinateSystems = new Map();
        node.namedCoordinateSystems.set(name, NamedHex(system));
    }

case "grid":
    expect(TColon);
    var name:String = null;
    if (match(THash)) {
        name = expectIdentifier();
    }
    final w = parseInteger();
    expect(TComma);
    final h = parseInteger();
    eatSemicolon();
    final system = {spacingX: w, spacingY: h};
    node.gridCoordinateSystem = system;
    if (name != null) {
        if (node.namedCoordinateSystems == null) node.namedCoordinateSystems = new Map();
        node.namedCoordinateSystems.set(name, NamedGrid(system));
    }
```

#### Remove `parseFunction()` entirely

Delete the `parseFunction()` method and all references to `RVFunction`, `ReferenceableValueFunction`.

### Builder — `MultiAnimBuilder.hx`

#### Resolve new RV types

```haxe
case RVPropertyAccess(ref, property):
    if (ref == "ctx") return resolveCtxProperty(property);
    if (ref == "grid" || isNamedGrid(ref)) return resolveGridProperty(ref, property);
    if (ref == "hex" || isNamedHex(ref)) return resolveHexProperty(ref, property);
    // Otherwise: tile parameter or @final tile
    return resolveTileProperty(ref, property);

case RVMethodCall(ref, method, args):
    error("method calls not supported in expression context — use .x/.y to extract coordinates");

case RVChainedMethodCall(base, method, args):
    if (method == "x" || method == "y"):
        final coords = resolveChainAsCoordinates(base);
        return method == "x" ? coords.x : coords.y;
    error('Unsupported chain terminal: .$method');
```

#### `$ctx` — runtime resolution

```haxe
function resolveCtxProperty(property:String):Dynamic {
    switch (property) {
        case "width": return scene.width;    // h2d.Scene from build context
        case "height": return scene.height;
    }
}

function resolveCtxMethod(method:String, args:Array<ReferenceableValue>):Dynamic {
    switch (method) {
        case "random":
            final min = resolveAsInteger(args[0]);
            final max = resolveAsInteger(args[1]);
            return min + Std.random(max - min);  // [min, max)
    }
}
```

The builder already has access to the scene (or can receive it as a build parameter). Each rebuild picks up the current values.

#### Resolve new Coordinate variants

```haxe
case SELECTED_HEX_CUBE(q, r, s):
    final hex = resolveHexCube(q, r, s);
    final pos = hexSystem.hexLayout.hexToPixel(hex);
    return {x: pos.x, y: pos.y};

case SELECTED_HEX_OFFSET(col, row, parity):
    final c = resolveAsInteger(col);
    final r = resolveAsInteger(row);
    final parityVal = switch (parity) { case EVEN: OffsetCoord.EVEN; case ODD: OffsetCoord.ODD; };
    final hex = switch (hexSystem.hexLayout.orientation) {
        case POINTY: OffsetCoord.qoffsetToCube(parityVal, new OffsetCoord(c, r));
        case FLAT: OffsetCoord.roffsetToCube(parityVal, new OffsetCoord(c, r));
    };
    final pos = hexSystem.hexLayout.hexToPixel(hex);
    return {x: pos.x, y: pos.y};

case SELECTED_HEX_DOUBLED(col, row):
    final c = resolveAsInteger(col);
    final r = resolveAsInteger(row);
    final hex = switch (hexSystem.hexLayout.orientation) {
        case POINTY: DoubledCoord.qdoubledToCube(new DoubledCoord(c, r));
        case FLAT: DoubledCoord.rdoubledToCube(new DoubledCoord(c, r));
    };
    final pos = hexSystem.hexLayout.hexToPixel(hex);
    return {x: pos.x, y: pos.y};

case SELECTED_HEX_PIXEL(x, y):
    final px = resolveAsNumber(x);
    final py = resolveAsNumber(y);
    final hex = hexSystem.hexLayout.pixelToHex(new Point(px, py)).round();
    final pos = hexSystem.hexLayout.hexToPixel(hex);
    return {x: pos.x, y: pos.y};

case SELECTED_HEX_CELL_CORNER(cell, cornerIdx, factor):
    final cellPos = resolveCoordinates(cell);  // resolve cell to Hex first
    final hex = hexSystem.hexLayout.pixelToHex(new Point(cellPos.x, cellPos.y)).round();
    final pos = hexSystem.hexLayout.polygonCorner(hex, resolveAsInteger(cornerIdx), resolveAsNumber(factor));
    return {x: pos.x, y: pos.y};

case SELECTED_HEX_CELL_EDGE(cell, dir, factor):
    final cellPos = resolveCoordinates(cell);
    final hex = hexSystem.hexLayout.pixelToHex(new Point(cellPos.x, cellPos.y)).round();
    final pos = hexSystem.hexLayout.polygonEdge(hex, resolveAsInteger(dir), resolveAsNumber(factor));
    return {x: pos.x, y: pos.y};
```

Helper for fractional cube hex resolution:
```haxe
function resolveHexCube(q:RV, r:RV, s:RV):Hex {
    final qf = resolveAsNumber(q);
    final rf = resolveAsNumber(r);
    final sf = resolveAsNumber(s);
    if (qf == Math.floor(qf) && rf == Math.floor(rf) && sf == Math.floor(sf)) {
        return new Hex(Std.int(qf), Std.int(rf), Std.int(sf));
    }
    return new FractionalHex(qf, rf, sf).round();
}
```

#### Named coordinate system resolution

```haxe
function getNamedCoordinateSystem(name:String, node:Node):CoordinateSystemDef {
    var n = node;
    while (n != null) {
        if (n.namedCoordinateSystems != null) {
            final cs = n.namedCoordinateSystems.get(name);
            if (cs != null) return cs;
        }
        n = n.parent;
    }
    error('Unknown coordinate system: $name');
}
```

#### Remove `resolveRVFunction()` and `RVFunction` handling entirely.

### Codegen — `ProgrammableCodeGen.hx`

#### `rvToExpr()` — add cases

```haxe
case RVPropertyAccess(ref, property):
    if (ref == "ctx") return ctxPropertyToExpr(property);
    if (ref == "grid") return gridPropertyToExpr(property);
    if (ref == "hex") return hexPropertyToExpr(property);
    // tile param / @final tile
    return tilePropertyToExpr(ref, property);

case RVChainedMethodCall(base, method, []):
    if (method == "x" || method == "y"):
        // Generate coordinate resolution + extract
        return coordinateChainToExpr(base, method);
```

#### `$ctx` in codegen — runtime expressions

```haxe
function ctxPropertyToExpr(property:String):Expr {
    switch (property) {
        case "width": return macro this.getScene().width;
        case "height": return macro this.getScene().height;
    }
}

function ctxMethodToExpr(method:String, args:Array<Expr>):Expr {
    switch (method) {
        case "random":
            final minExpr = args[0];
            final maxExpr = args[1];
            return macro $minExpr + Std.random($maxExpr - $minExpr);
    }
}
```

These generate **runtime code**, not compile-time constants. The generated factory class inherits from something that has scene access (or receives it as a parameter).

#### Remove `RVFunction` / `ReferenceableValueFunction` codegen support entirely.

---

### Phase summary

Single phase — all changes ship together since old keywords are removed.

| Step | Description |
|------|-------------|
| 1 | Add AST types (`RVPropertyAccess`, `RVMethodCall`, `RVChainedMethodCall`, `FINAL_TILE`) |
| 2 | Remove `ReferenceableValueFunction` enum, `RVFunction`, `parseFunction()`, `resolveRVFunction()` |
| 3 | Add `TDot` token to lexer |
| 4 | Update parser: property/method chain after `$ref`, `$ctx` support, named coord sys declarations |
| 5 | Remove old `parseXY` keywords (`grid`, `hex`, `hexCorner`, `hexEdge`) |
| 6 | Add new `parseXY` handling for `$ref.method()` and `$hex.cube().hexCorner()` chains |
| 7 | Add `Coordinates` enum variants (`SELECTED_HEX_CUBE`, `SELECTED_HEX_OFFSET`, `SELECTED_HEX_DOUBLED`, `SELECTED_HEX_PIXEL`, `SELECTED_HEX_CELL_CORNER`, `SELECTED_HEX_CELL_EDGE`, `OffsetParity`) |
| 8 | Update builder: resolve properties, methods, named systems, `$ctx` (runtime scene access) |
| 9 | Update codegen: same, with runtime expressions for `$ctx` |
| 10 | Migrate all existing `.manim` files |
| 11 | Add tests |

---

## Files to Modify

| File | Changes |
|------|---------|
| `src/bh/multianim/MultiAnimParser.hx` | Add `RVPropertyAccess`, `RVMethodCall`, `RVChainedMethodCall`, `FINAL_TILE`, `namedCoordinateSystems` on Node. Remove `ReferenceableValueFunction`, `RVFunction`. |
| `src/bh/multianim/CoordinateSystems.hx` | Add `SELECTED_HEX_CUBE`, `SELECTED_HEX_OFFSET`, `SELECTED_HEX_DOUBLED`, `SELECTED_HEX_PIXEL`, `SELECTED_HEX_CELL_CORNER`, `SELECTED_HEX_CELL_EDGE`, `OffsetParity`, `CoordinateSystemDef` |
| `src/bh/multianim/MacroManimParser.hx` | Add `TDot`. Parse property/method chains. Parse named coord sys (`#name`). Remove old keywords from `parseXY`. Remove `parseFunction`. Add `$ctx`. |
| `src/bh/multianim/MultiAnimBuilder.hx` | Resolve `RVPropertyAccess`, `RVMethodCall`, `RVChainedMethodCall`. Named coord sys resolution. `$ctx` runtime resolution via scene. Handle `FINAL_TILE`. Remove `resolveRVFunction`. |
| `src/bh/multianim/ProgrammableCodeGen.hx` | Codegen for new RV types. Runtime expressions for `$ctx`. Remove `RVFunction` codegen. Handle `FINAL_TILE`. |
| `.manim` files (see migration list) | Update all coordinate syntax |

---

## Test Plan

1. Compile: `haxe hx-multianim.hxml`
2. Migrate existing `.manim` files to new syntax
3. Existing tests pass: `test.bat run`
4. **New test — property access:**
   - Tile param + `$t.width` / `$t.height` in positions and @final
   - `@final bg = file(...)` + `$bg.width` in expression
   - `$grid.width` / `$grid.height`
   - `$hex.width` / `$hex.height`
5. **New test — coordinate methods:**
   - `$hex.corner(0, 1.1)` and `$hex.edge(1, 1.3)` as position specifiers
   - `$hex.cube(0, 1, -1)` as position (integer cube coords)
   - `$hex.cube(0.5, 0.5, -1.0)` as position (fractional cube coords, rounds)
   - `$hex.offset(3, 2)` and `$hex.offset(3, 2, odd)` as position (offset coords)
   - `$hex.doubled(3, 5)` as position (doubled coords)
   - `$hex.pixel(100, 75)` as position (pixel snap to nearest hex)
   - `$hex.cube(0, 1, -1).hexCorner(0, 1.1)` chained position
   - `$hex.offset(3, 2).hexCorner(0)` chaining from offset coords
   - `$hex.cube(0, 1, -1).hexCorner(0)` with default factor
   - `$hex.cube(0, 1, -1).hexCorner(0, 1.1).x` as expression value
   - `$grid.pos(x, y)` and `$grid.pos(x, y, ox, oy)` as position specifiers
6. **New test — named coordinate systems:**
   - `hex: #myhex pointy(32, 32)` + `$myhex.corner(0, 1.0)`
   - Named system accessible from child nodes
   - Multiple named systems in same tree
7. **New test — $ctx:**
   - `$ctx.width` / `$ctx.height` reactive (verify updates on resize)
   - `$ctx.random(0, 100)` returns int in [0, 100)
   - `$ctx.hex.corner()` resolving to nearest hex system
   - `$ctx.grid.pos()` resolving to nearest grid system
8. Generate references: `test.bat gen-refs`
