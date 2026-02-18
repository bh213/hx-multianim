# Property Access & @final Tile Support Plan

## Problem

1. No way to read tile dimensions in expressions — can't position things relative to `$tile.width`/`$tile.height`
2. `function(gridWidth)` / `function(gridHeight)` syntax is verbose and inconsistent
3. `@final` only stores numeric/string expressions, not tile sources

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
```

Supported properties:
- **Tile params** (`name:tile`): `.width`, `.height`
- **@final tiles**: `.width`, `.height`
- **Grid** (implicit `$grid`): `.width`, `.height`

### @final with tile value

```manim
@final bg = file("background.png")
@final icon = sheet("atlas", "myIcon")
@final gen = generated(color(16, 16, red))

bitmap($bg): 0, 0
bitmap($icon): $bg.width + 5, 0
text(f3x5, "w=" + $bg.width, #fff): 0, $bg.height + 2
```

## Implementation Changes

### 1. AST — `MultiAnimParser.hx`

**ReferenceableValue enum** — add:
```haxe
RVPropertyAccess(ref:String, property:String);
```

**NodeType enum** — add:
```haxe
FINAL_TILE(name:String, tileSource:TileSource);
```

**ReferenceableValueFunction enum** — keep for backward compat initially, deprecate later. Or remove immediately and handle `$grid.width`/`$grid.height` purely via `RVPropertyAccess("grid", "width")`.

### 2. Lexer — `MacroManimParser.hx`

Add `TDot` token type. In lexer, add to single-char tokens (after `..` double-dot check, after number `.5` parsing):
```
case '.'.code: pos++; return new Token(TDot, startLine, startCol);
```

### 3. Parser — `MacroManimParser.hx`

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

**`$grid` validation** — `validateRef()` should accept `"grid"` as a valid reference (it's not a declared parameter, it's implicit from the coordinate system context).

**Deprecation of `function(gridWidth/gridHeight)`** — keep parsing it for backward compatibility, but it can be removed later. Alternatively, remove now and update all .manim files.

### 4. Builder — `MultiAnimBuilder.hx`

**`resolveAsInteger()`** — add case:
```haxe
case RVPropertyAccess(ref, property):
    if (ref == "grid") {
        // resolve from grid coordinate system
        final grid = getGridCoordinateSystem(currentNode);
        return switch property { case "width": grid.spacingX; case "height": grid.spacingY; }
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

### 5. Codegen — `ProgrammableCodeGen.hx`

**`rvToExpr()`** — add case:
```haxe
case RVPropertyAccess(ref, property):
    if (ref == "grid") {
        final grid = getGridFromCurrentNode();
        return switch property { case "width": macro $v{grid.spacingX}; case "height": macro $v{grid.spacingY}; }
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

### 6. Backward Compat — `function(gridWidth/gridHeight)`

**Option A (recommended):** Keep both syntaxes. Old `function(gridWidth)` still works. New `$grid.width` is preferred. Remove old syntax in a future release.

**Option B:** Remove `RVFunction`, `ReferenceableValueFunction` enum, `parseFunction()`, and `resolveRVFunction()`. Update all .manim files. Cleaner but breaking.

## Files to Modify

| File | Changes |
|------|---------|
| `src/bh/multianim/MultiAnimParser.hx` | Add `RVPropertyAccess`, `FINAL_TILE` |
| `src/bh/multianim/MacroManimParser.hx` | Add `TDot`, parse `.property`, parse `@final tile`, validate `$grid` |
| `src/bh/multianim/MultiAnimBuilder.hx` | Resolve `RVPropertyAccess` (tile + grid), handle `FINAL_TILE` |
| `src/bh/multianim/ProgrammableCodeGen.hx` | Codegen for `RVPropertyAccess`, `FINAL_TILE` |

## .manim Files Using `function(gridWidth/gridHeight)` (if migrating)

- `playground/public/assets/autotileDemo.manim` (1 usage)
- `playground/public/assets/examples1.manim` (18 usages)
- `test/examples/56-codegenGridFunc/codegenGridFunc.manim` (4 usages)

## Test Plan

1. Compile: `haxe hx-multianim.hxml`
2. Existing tests pass: `test.bat run`
3. Add new test (next available number) with:
   - Tile param + `$t.width` / `$t.height` in positions and @final
   - `@final bg = file(...)` + `$bg.width` in expression
   - `$grid.width` / `$grid.height` replacing `function(gridWidth/gridHeight)`
4. Generate references: `test.bat gen-refs`
