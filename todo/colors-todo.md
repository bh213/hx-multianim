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

Full audit of how colors flow through every subsystem. The convention throughout is **0xRRGGBB** (24-bit, no alpha) as the internal color format, with `addAlphaIfNotPresent()` applied only where Heaps APIs need 32-bit AARRGGBB.

### `addAlphaIfNotPresent()` consistency

| Context | Called? | Correct? | Notes |
|---------|---------|----------|-------|
| `Tile.fromColor` (bitmap generated) | YES | OK | Builder line 1435, 2130 |
| Graphics shapes (rect, circle, line, polygon, etc.) | YES | OK | Builder lines 2414-2501 |
| Pixel shapes (line, rect, pixel) | YES | OK | Builder lines 2365-2382 |
| Tint (`@tint`) | YES | OK | Builder line 3836, codegen inlines check |
| Autotile demo tiles | YES | OK | Builder lines 4736-4737 |
| `ReplacePaletteShader` (replaceColor filter) | YES | OK | Shader constructor lines 55, 57 |
| `PixelOutline` — `outlineColor` | NO | OK | Shader param is `Vec3` — alpha byte ignored |
| `PixelOutline` — `inlineColor` | NO | **BUG** | Shader param is `Vec4`, alpha=0 makes color invisible |
| Outline filter | NO | OK | Heaps `h2d.filter.Outline` uses RGB only internally |
| Glow filter | NO | OK | Heaps Glow: separate `alpha` parameter |
| DropShadow filter | NO | OK | Heaps DropShadow: separate `alpha` parameter |
| Text color (builder) | NO | OK | `h2d.Text.textColor` is RGB-only property |
| Text color (codegen) | NO | OK | Same — assigned directly, alpha irrelevant |
| Particle colorCurve | NO | OK | `lerpColor()` is RGB-only; alpha via separate fadeIn/fadeOut |
| AnimatedPath colorCurve | NO | OK | Same `lerpColor()` pattern; alpha via separate alphaCurve |

**Action needed:** Fix `PixelOutline` `InlineColor` mode — add `addAlphaIfNotPresent()` before `setColor()` on `inlineColor`.

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

## Summary of All Bugs Found

1. **8-digit hex RRGGBBAA vs AARRGGBB** — main bug, affects 10+ test files (see top of doc)
2. **PixelOutline `inlineColor` missing alpha** — `Vec4` shader param gets alpha=0, making inline color invisible for 6-digit hex colors
3. **Particle/AnimatedPath colorCurve uses `resolveAsInteger`** instead of `resolveAsColorInteger` — palette colors in curves would fail
4. **`addAlphaIfNotPresent` blocks 0% alpha** — cannot specify fully transparent colors
