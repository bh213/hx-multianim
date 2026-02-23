# Color System TODO

## Bug: 8-Digit Hex Alpha Misinterpretation

Users write `#RRGGBBAA` (CSS convention, alpha-last), but parser treats it as raw 32-bit int, which Heaps interprets as `AARRGGBB` (alpha-first). Both the color AND alpha end up wrong.

### Affected files

| Written | Heaps sees | User intended | Actual result |
|---------|-----------|---------------|---------------|
| `#444444ff` | A=0x44 RGB=4444FF | gray, opaque | semi-transparent blue |
| `#00aa00ff` | A=0xFF RGB=AA00FF | green, opaque | opaque purple |
| `#ffaa00ff` | A=0xFF RGB=AA00FF | orange, opaque | opaque purple |
| `#ff0000ff` | A=0xFF RGB=0000FF | red, opaque | opaque blue |
| `#ffffff00` | A=0xFF RGB=FFFF00 | white, transparent | opaque yellow |
| `#ffff00ff` | A=0xFF RGB=FF00FF | yellow, opaque | opaque magenta |
| `#7fdbda33` | A=0x7F RGB=DBDA33 | teal @ 20% | yellow-green @ 50% |
| `#ffffff12` | A=0xFF RGB=FFFF12 | white @ 7% | opaque near-yellow |
| `#ffffffff` | A=0xFF RGB=FFFFFF | white, opaque | correct (coincidence) |

Files: slotParams.manim, slot2dIndex.manim, characterSheetDemo.manim, updatableDemo.manim, repeatAllNodes.manim, repeatRebuild.manim, indexedNamed.manim, slotDemo.manim, tileParamDemo.manim, codegenButton.manim

### Root cause

`tryStringToColor()` in MacroManimParser.hx (line ~1006-1018) does raw `Std.parseInt("0x" + hexStr)` for 8-digit hex with no byte rotation. Heaps APIs (`Tile.fromColor`, `Vector4.setColor`, filters) all expect AARRGGBB.

### `addAlphaIfNotPresent` side effects (ColorUtils.hx)

- 6-digit `#RRGGBB` → `0x00RRGGBB` → becomes `0xFFRRGGBB` — correct
- Intentional 0% alpha `#00RRGGBB` → becomes `0xFFRRGGBB` — **can never specify 0 alpha**
- Text color masking (`& 0xFFFFFF`) strips top byte, giving wrong RGB for 8-digit colors

## Fix Plan

### 1. Parse `#RRGGBBAA` as RGBA (convert to AARRGGBB internally)

In `tryStringToColor`, when `#` hex string is exactly 8 chars, rotate bytes:

```haxe
if (colorStr.length == 8 && colorVal != null) {
    // Convert RRGGBBAA → AARRGGBB (CSS convention → Heaps convention)
    final aa = colorVal & 0xFF;
    final rrggbb = colorVal >>> 8;
    return (aa << 24) | rrggbb;
}
```

Convention after fix:
- `#RGB` — shorthand, auto-opaque (keep)
- `#RRGGBB` — RGB, auto-opaque (keep)
- `#RRGGBBAA` — RGBA, CSS convention (fix)
- `0xAARRGGBB` — native Heaps format (keep for power users)

### 2. Validate hex length

Only accept 3, 6, or 8 hex digits after `#`. Reject others with parser error:
```
Invalid color '#ABCD' — expected #RGB (3), #RRGGBB (6), or #RRGGBBAA (8) digits
```

### 3. Add `transparent` named color

Add `"transparent": 0x00000000` to the named color map. Requires `addAlphaIfNotPresent` to NOT override it — either:
- Use a sentinel value, or
- Skip `addAlphaIfNotPresent` when color is exactly `0x00000000` (fully transparent black)

### 4. Fix all existing 8-digit hex in .manim test files

After the parser fix, most 8-digit colors will just work. But `#ffffffff` (which worked by coincidence) stays correct too. Review each file and regenerate reference images.

### 5. Update documentation

- Document color formats in `docs/manim-reference.md`
- Add examples: `#f00`, `#FF0000`, `#FF000080` (red @ 50% alpha), `white`, `0xFFFF0000`

## More Named Colors

Current 18 (CSS basic): maroon, red, orange, yellow, olive, green, lime, purple, fuchsia, teal, cyan/aqua, blue, navy, black, gray, silver, white

### Proposed additions

**Essential (game UI):**
| Name | Hex | Rationale |
|------|-----|-----------|
| `transparent` | 0x00000000 | Very common need, avoids `#00000000` |
| `gold` | 0xFFD700 | RPG/game UI staple |
| `brown` | 0x8B4513 | Missing earth tone |
| `pink` | 0xFFC0CB | Common UI color |
| `coral` | 0xFF7F50 | Warm accent, good for warnings |
| `crimson` | 0xDC143C | Deep red, good for HP/damage |
| `indigo` | 0x4B0082 | Deep purple, good for magic/mana |

**Grays (pixel art needs fine gray control):**
| Name | Hex | Rationale |
|------|-----|-----------|
| `darkgray` | 0x404040 | Between black and gray |
| `lightgray` | 0xD0D0D0 | Between silver and white |

**Nice-to-have:**
| Name | Hex | Rationale |
|------|-----|-----------|
| `skyblue` | 0x87CEEB | UI backgrounds |
| `forestgreen` | 0x228B22 | Nature/health |
| `tomato` | 0xFF6347 | Warm notification color |
| `wheat` | 0xF5DEB3 | Parchment/paper UI |
| `slate` | 0x708090 | Subdued UI panels |

Total: 18 current + 7 essential + 2 grays + 5 nice-to-have = 32

Note: keep list focused. Pixel art projects use exact hex values for sprite work — named colors are mainly for UI backgrounds, text, and generated placeholders.

## Color Type in SettingValueType

### Problem

Two parallel type systems handle colors differently:

**`DefinitionType` (programmable parameters)** — has `PPTColor`, preserves "this is a color" semantics:
```haxe
enum DefinitionType {
    PPTInt; PPTFloat; PPTBool; PPTString; PPTColor; // ...
}
```

**`SettingValueType` (settings/interactive metadata)** — NO color type, colors stored as `SVTInt`:
```haxe
enum SettingValueType {
    SVTString; SVTInt; SVTFloat; SVTBool; // no SVTColor
}
enum SettingValue {
    RSVString(s:String); RSVInt(i:Int); RSVFloat(f:Float); RSVBool(b:Bool); // no RSVColor
}
```

When `fontColor:color => white` is parsed (MacroManimParser.hx:3259-3262), the color type is recognized but then stored as `SVTInt` — the semantic information is lost.

### Consequences

1. **Error messages are confusing** — "expected int" instead of "expected color" when a color setting has wrong format
2. **No color-specific validation** — can't validate that a setting declared as `:color` actually received a valid color
3. **Debugging is opaque** — `RSVInt(16777215)` doesn't tell you it's `white`
4. **Consumer code can't distinguish** — code reading settings can't tell if `RSVInt(255)` is the color blue or the number 255

### Proposed fix: Add `SVTColor` and `RSVColor`

```haxe
enum SettingValueType {
    SVTString; SVTInt; SVTFloat; SVTBool;
    SVTColor; // NEW
}

enum SettingValue {
    RSVString(s:String); RSVInt(i:Int); RSVFloat(f:Float); RSVBool(b:Bool);
    RSVColor(c:Int); // NEW — stores AARRGGBB, same as RSVInt but semantically distinct
}
```

**Changes needed:**
1. Add `SVTColor` to `SettingValueType` enum (MultiAnimParser.hx:225)
2. Add `RSVColor(c:Int)` to `SettingValue` enum (MultiAnimParser.hx:237)
3. Parser: `case "color":` stores `{type: SVTColor, value: ...}` instead of `SVTInt` (MacroManimParser.hx:3262)
4. Builder: add `case SVTColor: RSVColor(resolveAsColorInteger(settingValue.value))` in settings resolution (MultiAnimBuilder.hx:3605, 3803)
5. Codegen: add `case SVTColor:` alongside `SVTInt` cases (ProgrammableCodeGen.hx:2502, 4670)
6. Consumer code: pattern match on `RSVColor(c)` for color settings, `RSVInt(i)` for integers — existing `RSVInt` color usage keeps working until migrated

**Backward compatibility:** Existing code matching `RSVInt` for colors still compiles — it just won't match `RSVColor`. Add a helper:

```haxe
// On SettingValue or as extension
static function asColorInt(sv:SettingValue):Null<Int> {
    return switch sv {
        case RSVColor(c): c;
        case RSVInt(i): i; // backward compat
        default: null;
    };
}
```

**Impact:** Low risk. The `SVTColor`/`RSVColor` addition is purely additive. Existing `SVTInt` paths still work for plain int settings. Migration of consumers can be gradual.

## Verification: Color Usage by Context

Full audit of how colors flow through every subsystem, verified against Heaps 2.1.0 source.

**Key Heaps insight**: Most Heaps APIs extract RGB from lower 24 bits and handle alpha separately. Only `Vector4.setColor()` extracts alpha from the top byte. This means `addAlphaIfNotPresent()` is only truly needed for `Vector4.setColor()` call sites.

### `addAlphaIfNotPresent()` consistency

| Context | Called? | Needed? | Why (verified in Heaps source) |
|---------|---------|---------|-------------------------------|
| `Tile.fromColor` (bitmap generated) | YES | **NO** | `Texture.fromColor` does `color & 0xFFFFFF`, alpha defaults to `1.0` — top byte discarded |
| Graphics `beginFill` / `setColor` | YES | **NO** | Extracts RGB via `(color >> N) & 0xFF`, alpha is separate param |
| Graphics `lineStyle` | YES | **NO** | Same RGB extraction pattern, separate alpha param |
| Pixel shapes (line, rect, pixel) | YES | **NO** | Uses Graphics internally — same pattern |
| Tint (`@tint`) — `Vector4.setColor()` | YES | **YES** | `Vector4.setColor` extracts `(c >>> 24) / 255` as alpha |
| Autotile demo tiles | YES | **NO** | Goes through `Tile.fromColor` |
| `ReplacePaletteShader` — `Vector4.setColor()` | YES | **YES** | Same Vec4 path — alpha used in shader comparison |
| `PixelOutline` — `outlineColor` (Vec3) | NO | **NO** | `Vector.setColor` (Vec3 version) has NO alpha field — only RGB |
| `PixelOutline` — `inlineColor` (Vec4) | NO | **YES — BUG** | `Vector4.setColor` extracts alpha; shader uses `output.color = inlineColor` (Vec4 with alpha) |
| Outline filter | NO | **NO** | `h3d.pass.Outline`: `shader.color.setColor(color)` then `.a = alpha` — alpha overwritten |
| Glow filter | NO | **NO** | Same pattern: color.setColor + color.a override |
| DropShadow filter | NO | **NO** | Same pattern: color.setColor + color.a override |
| Text color (builder) | NO | **NO** | `h2d.Text.textColor` documented as "RGB color. Alpha value is ignored." |
| Text color (codegen) | NO | **NO** | Same |
| Text `dropShadow.color` | NO | **NO** | `color.setColor(ds.color)` then `color.a = ds.alpha * oldA` — alpha overwritten |
| Particle colorCurve | NO | **NO** | `lerpColor()` is RGB-only; runtime extracts via `(col >> N) & 0xFF` |
| AnimatedPath colorCurve | NO | **NO** | Same `lerpColor()` pattern |

**Bugs:**
- Fix `PixelOutline` `InlineColor` mode — add `addAlphaIfNotPresent()` before `setColor()` on `inlineColor` (Vec4).

**Cleanup opportunity:** `addAlphaIfNotPresent()` calls on `Tile.fromColor`, `Graphics`, and pixel shapes are harmless but unnecessary — Heaps ignores the top byte in all these APIs. Could simplify if desired, but low priority.

### Particle colorCurve

- **Parser** (MacroManimParser.hx:3576-3603): `parseColorOrReference()` for start/end colors
- **Builder** (MultiAnimBuilder.hx:4124): `resolveAsInteger(cc.startColor)` — uses `resolveAsInteger`, not `resolveAsColorInteger` (works but loses semantic intent)
- **Runtime** (Particles.hx:810-821): `lerpColor()` — RGB-only channel interpolation, correct
- **Application** (Particles.hx:205-211): extracts R,G,B from lower 24 bits, normalizes to 0.0-1.0
- **Alpha**: completely separate via `fadeIn`/`fadeOut` envelope — **by design, correct**
- **8-digit hex impact**: If user writes `#FF000080`, after RRGGBBAA fix it becomes `0x80FF0000`. `lerpColor` extracts `(c >> 16) & 0xFF = 0xFF` (R) — correct since AARRGGBB puts RGB in lower 24 bits

### AnimatedPath colorCurve

- **Parser** (MacroManimParser.hx:4860-4868): same `parseColorOrReference()` path
- **Builder** (MultiAnimBuilder.hx:4440): `Std.int(resolveAsNumber(startColor))` — goes through Float, slightly inconsistent with particle path (resolveAsInteger). No practical precision issue for 32-bit ints.
- **Runtime** (AnimatedPath.hx:376-387): identical `lerpColor()` — RGB-only, correct
- **State** (AnimatedPath.hx:21): `color:Int` field in `AnimatedPathState`
- **Consumer responsibility**: caller applies color to drawable; lerpColor returns 0xRRGGBB

### Filter colors

- **Outline/Glow/DropShadow**: Heaps constructors accept Int, extract RGB internally. Alpha is a separate constructor parameter. No `addAlphaIfNotPresent` needed — **correct**.
- **PixelOutline**: Custom shader. `outlineColor:Vec3` (RGB only, OK). `inlineColor:Vec4` (RGBA, needs alpha — **bug**).
- **replaceColor**: `ReplacePaletteShader` calls `addAlphaIfNotPresent()` on both source and dest colors. Comparison is epsilon-based (~0.002/channel), RGB-only by default (`TEST_ALPHA: false`). **Correct.**
- **replacePalette**: No direct colors — uses palette row indices.

### Codegen color paths

- **Tint**: Codegen inlines `if (c >>> 24 == 0) c |= 0xFF000000` — matches builder behavior. **Correct.**
- **Tile.fromColor**: Codegen generates the call; runtime builder applies `addAlphaIfNotPresent()`. Need to verify codegen path also applies it.
- **Filter expressions**: `rvToExpr(color)` generates raw int literal — no alpha handling. OK for Outline/Glow/DropShadow (Heaps handles it). PixelOutline inlineColor would need the same fix in codegen.
- **Text color**: Codegen assigns `textColor = $colorExpr` directly. OK — h2d.Text uses RGB only.

### Text `dropShadow.color` note

`dropShadowColor` is a **static Int**, not a `ReferenceableValue`. Parsed via `tryParseColor()` (MacroManimParser.hx:2751), not `parseColorOrReference()` — so `$param` references and `palette()` are not supported. Default is `0` (line 2716). The color is assigned directly to `h2d.Text.dropShadow.color` (builder line 3024, codegen lines 1939/4132) without masking or `addAlphaIfNotPresent()`. Works because Heaps treats it as RGB. However:
- 8-digit hex colors will have wrong RGB (same main bug)
- Cannot use dynamic color parameters — only literal colors

### Text color masking inconsistency

| Path | Masking | Location |
|------|---------|----------|
| `generateTileWithText()` (builder) | `textColor & 0xFFFFFF` | MultiAnimBuilder.hx:1653 |
| Text element (builder) | `resolveAsColorInteger(textDef.color)` — no mask | MultiAnimBuilder.hx:3029 |
| Text incremental (builder) | `resolveAsColorInteger(textDefCapture.color)` — no mask | MultiAnimBuilder.hx:2095 |
| Text (codegen) | `$colorExpr` — no mask | ProgrammableCodeGen.hx |

The masking in `generateTileWithText` is correct but redundant if colors are always 0xRRGGBB. The inconsistency doesn't cause bugs today but would if 8-digit colors were used in text. After the RRGGBBAA parser fix, text colors with alpha would be 0xAARRGGBB — the lower 24 bits are RGB, so `h2d.Text.textColor` assignment works correctly without masking.

### Minor: resolveAsInteger vs resolveAsColorInteger

- Particle colorCurve: `resolveAsInteger(cc.startColor)` (line 4124)
- AnimatedPath colorCurve: `Std.int(resolveAsNumber(startColor))` (line 4440)
- All other color contexts: `resolveAsColorInteger(color)`

`resolveAsColorInteger` adds palette lookup support (`RVColor`, `RVColorXY`). The particle/animatedPath paths would fail if someone used `palette(...)` in a colorCurve — they should use `resolveAsColorInteger` instead. Low priority since palette colors in curves are unlikely.

## Bug: Named Colors in staticRef/dynamicRef Parameters

### Problem

`staticRef($colorParam, c=>red)` and `dynamicRef($ref, c=>red)` — named colors fail in the **builder** path.

**Root cause chain:**

1. `parseReferenceParams()` calls `parseAnything()` to parse parameter values
2. `parseAnything()` at line ~816 treats all identifiers as strings:
   ```haxe
   case TIdentifier(s):
       advance();
       return parseNextExpression(RVString(s), EAny);
   ```
   Named color `red` becomes `RVString("red")`, NOT `RVInteger(0xFF0000)`.
3. In builder `STATIC_REF`/`DYNAMIC_REF` case, `buildWithParameters()` receives the `Map<String, ReferenceableValue>` as `Map<String, Dynamic>`.
4. `updateIndexedParamsFromDynamicMap()` detects the value is a `ReferenceableValue`, calls `resolveReferenceableValue()`.
5. For `PPTColor`, that calls `resolveAsColorInteger(RVString("red"))`.
6. `resolveAsColorInteger()` has no `RVString` case — falls to `default: throw`.

**What works vs what doesn't:**

| Format | `parseAnything` produces | Builder path | Codegen path |
|--------|------------------------|-------------|-------------|
| `c=>#FF0000` | `RVInteger(0xFF0000)` via TName color check | OK | OK |
| `c=>#f00` | `RVInteger(0xFF0000)` via TName color check | OK | OK |
| `c=>0xFF0000` | `RVInteger(0xFF0000)` via THexInteger | OK | OK |
| `c=>16711680` | `RVInteger(16711680)` via TInteger | OK | OK |
| `c=>red` | `RVString("red")` — no color check | **THROWS** | OK (string→dynamicValueToIndex→tryStringToColor) |
| `c=>white` | `RVString("white")` | **THROWS** | OK |

**Why codegen works:** `rvToExpr(RVString("red"))` → `macro $v{"red"}` → string `"red"` passed to `ProgrammableBuilder.buildStaticRef()` → `buildWithParameters()` receives plain string (not ReferenceableValue) → takes the `else` branch in `updateIndexedParamsFromDynamicMap` → `dynamicValueToIndex("c", PPTColor, "red")` → `tryStringToColor("red")` → `0xFF0000`.

### Fix Options

**Option A — Fix `resolveAsColorInteger()` (recommended)**

Add `RVString` handling in `resolveAsColorInteger()` (MultiAnimBuilder.hx:~950):

```haxe
case RVString(s):
    final c = MacroManimParser.tryStringToColor(s);
    if (c != null) return c;
    final parsed = Std.parseInt(s);
    if (parsed != null) return parsed;
    throw 'cannot resolve color from string "$s"' + currentNodePos();
```

Pros: Minimal change, only affects color resolution, no risk to other parsing.
Cons: None — codegen path already works, this just fixes builder.

**Option B — Fix `parseAnything()` to try colors first**

```haxe
case TIdentifier(s):
    final c = tryStringToColor(s);
    if (c != null) { advance(); return parseNextExpression(RVInteger(c), EAny); }
    advance();
    return parseNextExpression(RVString(s), EAny);
```

Pros: Named colors resolve at parse time, consistent with `TName` handling (line 819-824).
Cons: **Dangerous** — `parseAnything` is used in many contexts. A string parameter or enum value named `red`, `blue`, `green` etc. would be silently converted to an integer. Breaks enum values like `[red, blue, green]` if those happen to be used. Also affects conditional values like `@($state=>red)`.

**Option C — Type-aware `parseAnything` (hybrid)**

Not feasible — `parseAnything` has no type context (doesn't know if the caller expects a color, string, or int).

**Recommendation: Option A.** Safe, targeted fix to `resolveAsColorInteger`. The same pattern of "try named color, fall back to parseInt" is already used in `dynamicValueToIndex` for `PPTColor`.

### Also applies to `resolveReferenceableValue()` in dynamicRef bindings

The incremental binding code at MultiAnimBuilder.hx:~3163 also calls `resolveAsColorInteger` for `PPTColor` params — same fix covers this path too since it goes through the same function.

## Settings Color Handling — Design Options

### Current flow

```
.manim settings{} block
    → parseStringOrReference / parseColorOrReference
    → ParsedSettingValue {type: SVTString|SVTInt, value: ReferenceableValue}
    → resolveSettings() → ResolvedSettings (Map<String, SettingValue = RSVString|RSVInt|...>)
    → settingValueToDynamic() → Map<String, Dynamic>    ← type info lost here
    → buildWithParameters() → updateIndexedParamsFromDynamicMap()
    → dynamicValueToIndex(key, targetType, value)        ← target type available here
```

Settings are parsed **without knowing the target** programmable's parameter types. Type info is lost at the `settingValueToDynamic` step. But `dynamicValueToIndex` at the end DOES know the target type and handles string→color conversion (`tryStringToColor`).

### What works today

| Setting syntax | Stored as | Forwarded as Dynamic | Target `PPTColor` param | Result |
|---|---|---|---|---|
| `fontColor:color => red` | `SVTInt, RVInteger(0xFF0000)` | `16711680` (int) | `dynamicValueToIndex → Value(0xFF0000)` | **OK** |
| `fontColor:color => #FF0000` | `SVTInt, RVInteger(0xFF0000)` | `16711680` (int) | same | **OK** |
| `fontColor => red` (untyped) | `SVTString, RVString("red")` | `"red"` (string) | `tryStringToColor("red") → Value(0xFF0000)` | **OK** (accidental) |
| `fontColor => #FF0000` (untyped) | `SVTString, RVString("FF0000")` | `"FF0000"` (string) | `tryStringToColor("FF0000") → null, Std.parseInt → null` | **FAILS** |
| `fontColor => 0xFF0000` (untyped) | `SVTString, RVString("0xFF0000")` | `"0xFF0000"` (string) | `tryStringToColor("0xFF0000") → 0xFF0000` | **OK** |

Note: untyped `fontColor => #FF0000` — the `#` prefix makes the lexer produce `TName("FF0000")`, and `parseStringOrReference` stores it as `RVString("FF0000")` (no `#` prefix). Then `tryStringToColor("FF0000")` fails because it needs a `#` or `0x` prefix. **This is a bug** — `#hex` colors silently become wrong strings in untyped settings.

### Design Options

**Option 1: Require explicit `:color` type (status quo + docs)**

Users must write `fontColor:color => red`. Untyped `fontColor => red` works by accident; `fontColor => #FF0000` is silently broken. Document that color settings require `:color` annotation.

Pros: No code changes.
Cons: Footgun — untyped `#hex` silently fails.

**Option 2: Add `SVTColor`/`RSVColor` + keep requiring `:color`**

Already planned in the SVTColor section above. Settings with `:color` type annotation get proper `SVTColor`/`RSVColor` type. Untyped settings stay strings.

Pros: Better type safety for explicit colors. Consumer code can distinguish `RSVColor(0xFF0000)` from `RSVInt(255)`.
Cons: Still doesn't fix untyped `fontColor => #FF0000`.

**Option 3: Type-infer settings from target programmable (at resolution time)**

When `resolveSettings()` runs, it doesn't know the target. But we could defer color resolution: keep the raw `ReferenceableValue` through to `updateIndexedParamsFromDynamicMap` and let the target type drive resolution.

Implementation: Change `settingValueToDynamic` to preserve `ReferenceableValue` for string settings:
```haxe
case RSVString(s):
    // Check if the string looks like a color reference — forward as RV
    // so target type resolution can handle it
    RVString(s);  // or just s — both paths work via dynamicValueToIndex
```

But this doesn't actually help — the issue is that `parseStringOrReference` for `#hex` drops the `#` prefix. The fix needs to happen at parse time.

**Option 4: Use `parseAnything` for untyped settings values (recommended)**

Change the untyped settings path from `parseStringOrReference()` to `parseAnything()`:

```haxe
// Current (MacroManimParser.hx:~3280):
case TArrow:
    advance();
    final value = parseStringOrReference();  // untyped defaults to string
    parent.settings.set(key, {type: SVTString, value: value});

// Proposed:
case TArrow:
    advance();
    final value = parseAnything();
    // Infer type from what parseAnything produced
    final svType = switch (value) {
        case RVInteger(_): SVTInt;
        case RVFloat(_): SVTFloat;
        case RVString(s) if (s == "true" || s == "false"): SVTBool;
        default: SVTString;
    };
    parent.settings.set(key, {type: svType, value: value});
```

This fixes:
- `fontColor => #FF0000` — `parseAnything` handles `TName` → tries `tryStringToColor("#FF0000")` → `RVInteger(0xFF0000)` → stored as `SVTInt`
- `fontColor => 0xFF0000` — `parseAnything` handles `THexInteger` → `RVInteger(0xFF0000)` → `SVTInt`
- `fontColor => 255` — `parseAnything` → `RVInteger(255)` → `SVTInt`
- `fontColor => red` — `parseAnything` → `RVString("red")` → `SVTString` (named colors still need `:color` or target-type resolution)
- `text => "hello"` — `parseAnything` → `RVString("hello")` → `SVTString`

Pros: `#hex` and `0xhex` values work in untyped settings. Better type inference overall.
Cons: Slightly different parsing behavior — `fontColor => 42` currently stored as `SVTString/RVString("42")`, would become `SVTInt/RVInteger(42)`. Shouldn't matter since `dynamicValueToIndex` handles both, but needs testing.

**Option 5: Option 4 + SVTColor inference**

Same as Option 4 but also infer `SVTColor` when `parseAnything` produces an integer from a color-looking token:

```haxe
case TArrow:
    advance();
    // Peek to detect color-like tokens before parsing
    final isColorLike = switch (peek()) {
        case TName(_): true;  // #hex
        default: false;
    };
    final value = parseAnything();
    final svType = switch (value) {
        case RVInteger(_) if (isColorLike): SVTColor;  // was #hex
        case RVInteger(_): SVTInt;
        case RVFloat(_): SVTFloat;
        default: SVTString;
    };
    parent.settings.set(key, {type: svType, value: value});
```

This is over-engineering — we can't reliably distinguish "is this int a color?" without knowing the target. **Not recommended.**

### Recommendation

**Option 4** — switch untyped settings from `parseStringOrReference` to `parseAnything`. Fixes the `#hex` bug and gives better type inference. Combined with **Option 2** (SVTColor/RSVColor for `:color` typed settings) for full type safety when explicit.

Named colors (`red`, `white`) in untyped settings stay as `RVString` and work via `dynamicValueToIndex` at the target. For explicit color semantics, use `:color` type annotation.

## Summary of All Bugs Found

1. **8-digit hex RRGGBBAA vs AARRGGBB** — main bug, affects 10+ test files (see top of doc)
2. **PixelOutline `inlineColor` missing alpha** — `Vec4` shader param gets alpha=0, making inline color invisible for 6-digit hex colors
3. **Particle/AnimatedPath colorCurve uses `resolveAsInteger`** instead of `resolveAsColorInteger` — palette colors in curves would fail
4. **`addAlphaIfNotPresent` blocks 0% alpha** — cannot specify fully transparent colors
5. **Named colors in staticRef/dynamicRef params** — builder path throws on `c=>red` because `resolveAsColorInteger` doesn't handle `RVString`
6. **Untyped settings `#hex` colors lose `#` prefix** — `fontColor => #FF0000` stores `RVString("FF0000")` without `#`, `tryStringToColor` fails

## Implementation TODO

Ordered by dependency — earlier items unblock later ones.

### Phase 1: Core parser fixes (no API changes)

- [ ] **1a. Fix `#RRGGBBAA` → AARRGGBB rotation** in `tryStringToColor()` (MacroManimParser.hx:~1006)
  - 8-char hex: rotate `RRGGBBAA → AARRGGBB`
  - Validate hex length: accept only 3, 6, or 8 digits after `#`; reject others with clear error
  - Files: MacroManimParser.hx

- [ ] **1b. Add `transparent` named color** to `tryStringToColor()` map
  - Value: `0x00000000`
  - Requires `addAlphaIfNotPresent` to not override `0x00000000` (use sentinel or skip when exactly 0)
  - Files: MacroManimParser.hx, ColorUtils.hx

- [ ] **1c. Add more named colors** to `tryStringToColor()` map
  - Essential: `gold`, `brown`, `pink`, `coral`, `crimson`, `indigo`
  - Grays: `darkgray`, `lightgray`
  - Nice-to-have: `skyblue`, `forestgreen`, `tomato`, `wheat`, `slate`
  - Files: MacroManimParser.hx

- [ ] **1d. Fix `resolveAsColorInteger` for `RVString`** (MultiAnimBuilder.hx:~950)
  - Add: `case RVString(s): tryStringToColor(s) ?? Std.parseInt(s) ?? throw`
  - Fixes named colors in staticRef/dynamicRef params (bug #5)
  - Files: MultiAnimBuilder.hx

- [ ] **1e. Fix particle/animatedPath colorCurve resolution** (bug #3)
  - Change `resolveAsInteger(cc.startColor)` → `resolveAsColorInteger(cc.startColor)` (MultiAnimBuilder.hx:~4124)
  - Change `Std.int(resolveAsNumber(startColor))` → `resolveAsColorInteger(startColor)` (MultiAnimBuilder.hx:~4440)
  - Enables palette() colors in colorCurves
  - Files: MultiAnimBuilder.hx

- [ ] **1f. Fix PixelOutline `inlineColor` alpha** (bug #2)
  - Add `addAlphaIfNotPresent()` before `setColor()` on `inlineColor` Vec4
  - Files: PixelOutline shader code

### Phase 2: Settings type system improvements

- [ ] **2a. Add `SVTColor` / `RSVColor`** to type enums
  - Add `SVTColor` to `SettingValueType` (MultiAnimParser.hx:225)
  - Add `RSVColor(c:Int)` to `SettingValue` (MultiAnimParser.hx:237)
  - Parser: `case "color":` stores `{type: SVTColor, ...}` instead of `SVTInt` (MacroManimParser.hx:~3262)
  - Builder: `case SVTColor: RSVColor(resolveAsColorInteger(settingValue.value))` in `resolveSettings()` (MultiAnimBuilder.hx:~3803)
  - Interactive metadata: add `case SVTColor:` alongside `SVTInt` (MultiAnimBuilder.hx:~3605)
  - Codegen: add `case SVTColor:` alongside `SVTInt` cases
  - Add helper: `SettingValue.asColorInt()` → matches both `RSVColor` and `RSVInt` for backward compat
  - Files: MultiAnimParser.hx, MacroManimParser.hx, MultiAnimBuilder.hx, ProgrammableCodeGen.hx, UIScreen.hx

- [ ] **2b. Switch untyped settings to `parseAnything()`**
  - Change `parseStringOrReference()` → `parseAnything()` for `key => value` settings (MacroManimParser.hx:~3280)
  - Infer `SVTInt`/`SVTFloat`/`SVTString` from what `parseAnything` produces
  - Fixes bug #6: `fontColor => #FF0000` now parsed correctly via `parseAnything`'s `TName` color handling
  - Test: `fontColor => #FF0000`, `fontColor => 0xFF0000`, `fontColor => 42`, `text => "hello"`, `fontColor => red`
  - Files: MacroManimParser.hx

### Phase 3: Cleanup and consistency

- [ ] **3a. Fix all existing 8-digit hex in .manim test files**
  - After 1a, review: slotParams, slot2dIndex, characterSheetDemo, updatableDemo, repeatAllNodes, repeatRebuild, indexedNamed, slotDemo, tileParamDemo, codegenButton
  - Regenerate reference images

- [ ] **3b. Audit `addAlphaIfNotPresent` calls**
  - Remove unnecessary calls on `Tile.fromColor`, Graphics, pixel shapes (Heaps ignores top byte)
  - Keep on `Vector4.setColor()` paths (tint, replacePalette, pixelOutline inlineColor)
  - Low priority — harmless but noisy

- [ ] **3c. Update documentation**
  - `docs/manim-reference.md`: document all color formats, named colors, `#RRGGBBAA` convention
  - Add examples: `#f00`, `#FF0000`, `#FF000080` (red @ 50%), `white`, `transparent`, `0xFFFF0000`
  - Document that settings colors should use `:color` type for best results

- [ ] **3d. Add color verification visual test** (test 88)
  - Already started: `test/examples/88-colorVerification/colorVerification.manim`
  - Extend with: named colors in ref params, settings forwarding, 8-digit alpha colors
  - Generate reference image
