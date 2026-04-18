# .manim Language Reference

Quick-lookup reference of all elements, properties, and operations in the `.manim` language.

---

## File Structure

| Construct | Description |
|-----------|-------------|
| `version: 1.0` | Required file header declaring format version |
| `import "file" as "name"` | Import external .manim file for cross-file references |
| `#name programmable(params) { ... }` | Define a parameterized component (the main building block) |
| `#name data { ... }` | Define static typed data block with records and fields |
| `#name curves { ... }` | Define named interpolation curves |
| `#name paths { ... }` | Define named movement paths |
| `#name animatedPath { ... }` | Define animated path with curves, events, and timing |
| `#name layouts { ... }` | Define named coordinate layouts for positioning |
| `#name atlas2("file") { ... }` | Define inline sprite atlas from image file |
| `#name palette { ... }` | Define color palette |
| `#name autotile { ... }` | Define procedural auto-tile set |
| `@final name = expr` | Declare immutable named constant |

---

## Visual Elements

| Element | Description |
|---------|-------------|
| `bitmap(source, hAlign, vAlign)` | Display image tile with optional alignment |
| `text(font, text, color, align, maxWidth, options)` | Simple text with font, color, and formatting options |
| `richText(font, text, color, align, maxWidth, options)` | Rich text with `[markup]`, styles, images — always `h2d.HtmlText` |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable image for resizable panels |
| `pixels(...)` | Pixel-level drawing primitives |
| `graphics(...)` | Vector graphics shapes |
| `stateanim("file", state, selector)` | State machine animation from .anim file |
| `stateanim construct(initial, states)` | Inline state machine animation definition |
| `stateanim construct(initial, externallyDriven, states)` | Inline state animation driven externally (not by internal timer) |
| `particles { ... }` | Particle effect system |

---

## Structural Elements

| Element | Description |
|---------|-------------|
| `flow(params)` | Layout container (horizontal, vertical, stack) with padding, spacing, overflow |
| `layers()` | Z-ordering container for explicit depth stacking |
| `mask(w, h)` | Clipping rectangle that hides overflow |
| `tilegroup` | Optimized tile grouping (GPU batching for bitmaps, ninepatch, pixels, point) |
| `spacer(w, h)` | Empty spacing element inside flow containers |
| `point` | Positioning anchor/marker point |
| `apply(...)` | Apply properties to parent element |

---

## Dynamic Content

| Element | Description |
|---------|-------------|
| `placeholder(type, source)` | Dynamic content slot resolved at build time |
| `staticRef($ref, params)` | Static embed of another programmable |
| `staticRef(external("importName"), $ref, params)` | Static embed from imported .manim file |
| `dynamicRef($ref, params)` | Dynamic embed with runtime `setParameter()` support |
| `dynamicRef(external("importName"), $ref, params)` | Dynamic embed from imported .manim file |
| `dynamicRef($paramName, params)` | Dynamic embed where `$paramName` is a parameter naming the target programmable. Full rebuild on template change |
| `#name slot` | Swappable content container |
| `#name[$i] slot` | Indexed slot inside repeatable |
| `#name slot(params)` | Parameterized slot with visual states and conditionals |
| `slotContent` | Content insertion point inside parameterized slot body |
| `interactive(w, h, id, debug, metadata)` | Hit-test region with optional typed key-value metadata, event filtering, and bind |
| `settings { key=>val }` | Emit typed settings to builder |

---

## Repetition

| Element | Description |
|---------|-------------|
| `repeatable($var, iterator)` | Repeat child elements over an iterator |
| `repeatable2d($x, $y, iterX, iterY)` | 2D grid repetition with two iterators |

### Iterator Types

| Iterator | Description |
|----------|-------------|
| `step(count, dx: N, dy: N)` | Fixed step offset, repeated `count` times |
| `layout("entryName")` | Position from named relative layout (entryName is the `#name` used in the `layouts {}` block) |
| `array($valueVar, $arrayName)` | Iterate over data array |
| `range(start, end [, step])` | Numeric range (exclusive end), optional step |
| `range(from: X, to: Y [, step: S])` | Named range (inclusive end: `to: 5` includes 5) |
| `range(from: X, until: Y [, step: S])` | Named range (exclusive end: `until: 5` excludes 5) |
| `stateanim($bitmapVar, "file.anim", "animName", key=>value)` | Iterate animation frames; exposes `$bitmapVar` and `$index` |
| `tiles($bitmapVar, $tilenameVar, "sheetName")` | Iterate all tiles from sheet; exposes `$bitmapVar`, `$tilenameVar`, and `$index` |
| `tiles($bitmapVar, "sheetName", "exactTile")` | Iterate frames of a specific tile; exposes `$bitmapVar` and `$index` |
| `tiles($bitmapVar, "sheetName")` | Iterate all tiles (without tilename var); exposes `$bitmapVar` and `$index` |

---

## Tile Sources (for bitmap)

| Source | Description |
|--------|-------------|
| `file("image.png")` | Load from image file |
| `sheet("sheetName", "tileName")` | Tile from sprite sheet atlas |
| `sheet("sheetName", "tileName", index)` | Specific frame index from sheet |
| `generated(color(w, h, #color))` | Solid color rectangle |
| `generated(cross(w, h, color, thickness))` | Cross/X marker |
| `generated(colorwithtext(w, h, color, text, textColor, font))` | Colored rect with text label |
| `generated(autotile(name, selector))` | Tile from autotile definition |
| `generated(autotileregionsheet(name, scale, font, color))` | Autotile debug visualization |
| `$variable` | Tile from parameter or iterator variable |
| `center(source)` | Set tile pivot to center (0.5, 0.5) — shorthand for `pivot(0.5, 0.5, source)`. Nested pivot/center rejected at parse time |
| `pivot(x, y, source)` | Set tile pivot point (0–1 ratio, validated at parse time). Overrides bitmap's hAlign/vAlign. Nested pivot/center rejected at parse time |

---

## Text Options (`text()`)

| Option | Description |
|--------|-------------|
| `letterSpacing` | Space between characters |
| `lineSpacing` | Space between lines |
| `lineBreak` | Enable word wrapping |
| `dropShadowXY` | Shadow offset (x, y) |
| `dropShadowColor` | Shadow color |
| `dropShadowAlpha` | Shadow opacity |
| `autoFit: <mode> [font1, font2, ...]` | Automatic font fallback when text exceeds available space |

`text()` creates plain `h2d.Text`. Does not support markup, styles, images, or condenseWhite.

### autoFit Modes

| Mode | Description |
|------|-------------|
| `autoFit: width [f1, f2]` | Try primary font, then f1, f2 — use first that fits `maxWidth` |
| `autoFit: box(w, h) [f1, f2]` | Try fonts in order — use first that fits width AND height |
| `autoFit: fill [f1, f2, ...]` | Try ALL fonts (including primary) — pick the largest that fits `maxWidth` |
| `autoFit: fill box(w, h) [f1, f2, ...]` | Try ALL fonts — pick the largest that fits both dimensions |

**Width/fill modes require `maxWidth` to be set.** Box dimensions are absolute pixels (divided by `@scale` internally). The font list is fallback-only for `width`/`box` modes; for `fill` modes, the primary font is also a candidate.

```manim
// Width mode: try dd first, fall back to m3x6, then f3x5
text(dd, "Hello", #44FF44, left, 100, lineBreak: false,
    autoFit: width [m3x6, f3x5]): 1, 1;

// Fill mode: pick largest font that fits 150px
text(f3x5, "Fill this", #44BBFF, left, 150, lineBreak: false,
    autoFit: fill [pixellari, dd, m6x11, m3x6, f3x5]): 1, 1;

// Box mode with richText
richText(dd, "Deal [dmg]50[/] fire damage", white, left, 150, lineBreak: false,
    autoFit: width [m3x6, f3x5],
    styles: {dmg: color(#FF4444)}): 1, 1;
```

---

## Rich Text Options (`richText()`)

| Option | Description |
|--------|-------------|
| `letterSpacing` | Space between characters |
| `lineSpacing` | Space between lines |
| `lineBreak` | Enable word wrapping |
| `styles: {name: color(#hex) font("name"), ...}` | Named text styles with `color()` and/or `font()` wrappers |
| `images: {name: tileSource, ...}` | Named inline images for `[img:name]` markup (curly brace map) |
| `condenseWhite: true` | Collapse whitespace |
| `dropShadowXY` | Shadow offset (x, y) |
| `dropShadowColor` | Shadow color |
| `dropShadowAlpha` | Shadow opacity |
| `autoFit: <mode> [font1, font2, ...]` | Automatic font fallback (see [autoFit Modes](#autofit-modes) above) |

`richText()` always creates `h2d.HtmlText`. Markup is always processed via `TextMarkupConverter`. XML special characters (`<`, `>`, `&`) in text content are automatically escaped before conversion, so literal text like `"Hull<25%"` or `"fire & ice"` works safely.

### Rich Text Markup

Text strings support `[tag]...[/]` BBCode-style markup. Unlike `${expr}` interpolation, `[tag]` markup works in both single and double-quoted strings.

| Markup | Description |
|--------|-------------|
| `[styleName]...[/]` | Apply named style (defined in `styles:`) |
| `[br]` | Line break (self-closing) |
| `[img:name]` | Inline image (self-closing, defined in `images:`) |
| `[align:center]...[/]` | Paragraph alignment (`left`, `center`, `right`) |
| `[link:id]...[/]` | Hyperlink (fires `callback("link:id")`) |
| `[/]` | Close most recently opened tag |
| `[[` | Literal `[` (escape sequence) |

**Style definitions:** Each style needs at least `color()` or `font()`. Both accept `$param` references for incremental updates.
```manim
styles: {damage: color(#FF0000), gold: color(#FFD700) font("boldFont"), emphasis: font("italicFont"), highlight: color($hlColor)}
```

**Image definitions:** Curly brace map with colon separators. Reuses standard tile source syntax.
```manim
images: {coin: generated(color(14, 14, #FFD700)), sword: sheet("items", "sword_16")}
```

**Codegen setters:** For each style, `setStyleColor_<name>(color:Null<Int>)` and `setStyleFont_<name>(fontName:Null<String>)` are generated. For each image, `setImageTile_<name>(tile:h2d.Tile)` is generated.

---

## Alignment

### Horizontal
`left`, `center`, `right`

### Vertical
`top`, `center`, `bottom`

---

## Graphics Shapes (inside `graphics()` or standalone)

| Shape | Description |
|-------|-------------|
| `rect(color, style, w, h)` | Rectangle |
| `circle(color, style, radius)` | Circle |
| `ellipse(color, style, w, h)` | Ellipse |
| `roundrect(color, style, w, h, radius)` | Rounded rectangle |
| `arc(color, style, radius, startAngle, arcAngle)` | Arc segment |
| `line(color, lineWidth, x1, y1, x2, y2)` | Line segment |
| `polygon(color, style, points...)` | Polygon from point list |

**Style**: `filled` or numeric line width.

Graphics shapes can also be used as standalone elements (shorthand for `graphics(shape)`).

---

## Pixel Primitives (inside `pixels()`)

| Primitive | Description |
|-----------|-------------|
| `pixel(x, y, color)` | Single pixel |
| `line(x1, y1, x2, y2, color)` | Pixel line |
| `rect(x, y, w, h, color)` | Pixel rectangle outline |
| `filledrect(x, y, w, h, color)` | Filled pixel rectangle |

---

## Flow Layout Properties

| Property | Description |
|----------|-------------|
| `layout` | Direction: `horizontal`, `vertical`, `stack` |
| `maxWidth`, `maxHeight` | Maximum size constraints |
| `minWidth`, `minHeight` | Minimum size constraints |
| `lineHeight` | Fixed row height |
| `colWidth` | Fixed column width |
| `horizontalSpacing` | Horizontal gap between items |
| `verticalSpacing` | Vertical gap between items |
| `padding` | All-sides padding |
| `paddingTop/Bottom/Left/Right` | Individual side padding |
| `background` | 9-patch background element |
| `multiline` | Allow line wrapping |
| `overflow` | Overflow behavior: `expand`, `limit`, `scroll`, `hidden` |
| `fillWidth`, `fillHeight` | Expand to fill container dimension |
| `reverse` | Reverse child order |
| `horizontalAlign` | Default horizontal alignment: `left`, `right`, `middle` |
| `verticalAlign` | Default vertical alignment: `top`, `bottom`, `middle` |
| `debug` | Show debug layout borders |

### Per-Element Flow Properties (`@flow.*`)

Annotations on direct children of `flow()` to override per-element layout:

| Syntax | Description |
|--------|-------------|
| `@flow.halign(left\|right\|middle)` | Override horizontal alignment for this child |
| `@flow.valign(top\|bottom\|middle)` | Override vertical alignment for this child |
| `@flow.offset(x, y)` | Pixel offset within the flow layout |
| `@flow.absolute` | Remove from flow layout, position freely (overlays) |

Chainable: `@flow.halign(middle) @flow.offset(2, 4) bitmap(...)`
Parse-time error when used outside a flow ancestor.

---

## Conditionals

| Syntax | Description |
|--------|-------------|
| `@(param=>value)` | Match when parameter equals value |
| `@if(param=>value)` | Explicit if (same as `@()`) |
| `@any(p1=>v1, p2=>v2)` | Match when ANY listed condition matches (OR) |
| `@all(p1=>v1, p2=>v2)` | Match when ALL listed conditions match (AND, same as `@()`) |
| `@(param != value)` | Match when parameter does NOT equal value |
| `@(param=>[v1,v2])` | Match any of multiple values |
| `@(param != [v1,v2])` | Exclude multiple values |
| `@(param >= value)` | Greater than or equal |
| `@(param <= value)` | Less than or equal |
| `@(param > value)` | Strictly greater than |
| `@(param < value)` | Strictly less than |
| `@(param => start..end)` | Range match (inclusive) |
| `@(param => *)` | Wildcard — match any value |
| `@else` | Matches when preceding sibling `@()` did not match |
| `@else(conditions)` | Else-if with additional conditions |
| `@default` | Final fallback when nothing above matched |

Conditionals also work with **repeatable loop variables** (e.g., `@($i => 0)`, `@($i >= 3)`, `@($i != 1)`) inside `repeatable` bodies.

**Comparison and range values support `$param` references** — e.g., `@($i < $level)`, `@(hp >= $threshold)`, `@(param => $from..$to)`, `between $min..$max`. The reference is resolved at build time from current parameter values.

Additional condition keywords: `greaterthanorequal`, `lessthanorequal`, `bit`, `between`.

### Conditional Blocks

Any conditional prefix supports a block body `{ ... }` to group multiple elements under one condition:

```manim
@(status=>active) {
    bitmap(generated(color(60, 40, #060)));
    text(m3x6, "ACTIVE", #8f8, center, 60):0,12;
}
@else(status=>hover) {
    bitmap(generated(color(60, 40, #063)));
    text(m3x6, "HOVER", #8ff, center, 60):0,12;
}
@default {
    bitmap(generated(color(60, 40, #333)));
    text(m3x6, "OTHER", #888, center, 60):0,12;
}
```

Works with `@()`, `@if()`, `@any()`, `@all()`, `@else`, `@else(cond)`, `@default`. Blocks can be nested (block-in-block) and can contain inner conditionals.

### @switch Block

`@switch(param) { }` groups multiple conditions on a single parameter into a block, avoiding repetition:

```manim
@switch(status) {
    normal: bitmap(generated(color(60, 30, #666)));
    hover: bitmap(generated(color(60, 30, #060)));
    pressed | disabled: bitmap(generated(color(60, 30, #600)));
    default: bitmap(generated(color(60, 30, #333)));
}
```

**Arm patterns:**

| Pattern | Description |
|---------|-------------|
| `value` | Match single value (enum name, integer, `"quoted string"`, `#RRGGBB` color, `true`/`false`) |
| `value1 \| value2` | Match any of multiple values. Enum/string use `CoEnums`; color/int/uint/bool use `CoAnyOf` of typed inner conditionals |
| `<= N` | Less than or equal (numeric params only) |
| `>= N` | Greater than or equal (numeric params only) |
| `< N` | Strictly less than (numeric params only) |
| `> N` | Strictly greater than (numeric params only) |
| `N..M` | Range match, inclusive (numeric params only) |
| `default` | Fallback when no arm matches |

**Parameter type support:** `@switch` works on discrete types — `enum`, `int`, `uint`, `range`, `string`, `color`, `bool`. Single-value arms route through the same type-aware converter as `@(param => value)`, so a color arm like `#FF0000` produces an integer match and `true`/`false` arms on a `bool` param work as expected. `@switch` rejects `float`, `tile`, and `flags` parameters at parse time (use `@(param => bit[N])` for flag tests). Range/comparison arms (`<= N`, `N..M`, etc.) are rejected on non-numeric parameters.

**Block arms** for multiple elements per case:

```manim
@switch(mode) {
    a {
        bitmap(generated(color(60, 40, #600)));
        text(m3x6, "AAA", #f88, center, 60):0,12;
    }
    b {
        bitmap(generated(color(60, 40, #060)));
        text(m3x6, "BBB", #8f8, center, 60):0,12;
    }
    default {
        bitmap(generated(color(60, 40, #006)));
        text(m3x6, "DEF", #88f, center, 60):0,12;
    }
}
```

**Nested conditionals** — regular `@()` conditions work inside switch arms:

```manim
@switch(status) {
    normal {
        @(enabled=>on) bitmap(generated(color(70, 30, #060)));
        @(enabled=>off) bitmap(generated(color(70, 30, #333)));
    }
    hover {
        @(enabled=>on) bitmap(generated(color(70, 30, #090)));
        @(enabled=>off) bitmap(generated(color(70, 30, #444)));
    }
    default: bitmap(generated(color(70, 30, #600)));
}
```

**Notes:**
- `@switch` cannot be combined with other `@` modifiers (`@alpha`, `@scale`, etc.)
- Cannot be used at root level (must be inside a programmable body)
- Only one `default` arm per `@switch` block (duplicate rejected at parse time)
- **Incremental mode:** `setParameter()` triggers full arm rebuild (teardown + rebuild of active arm). All param refs inside all arms are collected — changing any referenced param (not just the switch param) triggers rebuild. Supports nested `@switch`, `@()` conditionals, repeatables, and `$param` expressions inside arms
- **Codegen:** lazy rebuild via ordinal-based arm lookup. Generated `_applyVisibility` always rebuilds on any parameter change, forwarding current param values to the builder

---

## Parameter Types

| Type | Description |
|------|-------------|
| `int` | Signed integer |
| `uint` | Unsigned integer (0+) |
| `float` | Floating point number |
| `bool` | Boolean (`true`/`false`/`yes`/`no`/`1`/`0`) |
| `string` | Text string (quoted) |
| `color` | Color value — `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `0xAARRGGBB`, or named color |
| `tile` | Tile reference (no default allowed) |
| `[val1,val2,val3]` | Enum — one of listed values |
| `start..end` | Integer range |
| `flags` | Bit flags |
| `hexdirection` | Hex direction flags (0-5) |
| `griddirection` | Grid direction flags (0-7) |
| `array` | Array type |

---

## Expressions

### Operators
| Operator | Description |
|----------|-------------|
| `+` | Addition / string concatenation |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Modulo |
| `div` | Integer division |
| `==`, `!=` | Equality comparison |
| `<`, `>`, `<=`, `>=` | Ordering comparison |

### Ternary
`?(condition) trueValue : falseValue`

### References
| Reference | Description |
|-----------|-------------|
| `$paramName` | Parameter reference |
| `$index` | Loop iteration index (repeatable) |
| `$indexX`, `$indexY` | Grid iteration indices (repeatable2d) |
| `$bitmap`, `$tilename` | Iterator-provided tile variables |
| `callback("name")` | Runtime callback reference |
| `callback("name", $index)` | Callback with index argument |
| `[val1, val2, ...]` | Array literal |
| `$ref[index]` | Array element access |

---

## Coordinate Systems

### Direct Offset
Position with `x, y` pixel coordinates. Semicolon `;` means `0, 0`.

### Grid
Define with `grid: spacingX, spacingY` (or named: `grid: #name spacingX, spacingY`).

| Method | Description |
|--------|-------------|
| `$grid.pos(x, y)` | Position at grid cell (use `.offset(x, y)` for pixel offsets) |
| `$grid.width` | Cell width |
| `$grid.height` | Cell height |

### Hex
Define with `hex: flat(w, h)` or `hex: pointy(w, h)` (or named: `hex: #name ...`).

| Method | Description |
|--------|-------------|
| `$hex.cube(q, r, s)` | Cube coordinates (q+r+s=0) |
| `$hex.offset(col, row, even/odd)` | Offset coordinates |
| `$hex.doubled(col, row)` | Doubled coordinates |
| `$hex.corner(index, scale)` | Hex polygon corner (0-5) |
| `$hex.edge(direction, scale)` | Hex polygon edge midpoint |
| `$hex.pixel(x, y)` | Snap pixel to nearest hex center |
| `$hex.cube(q,r,s).hexCorner(i, f)` | Corner relative to specific hex cell |
| `$hex.cube(q,r,s).hexEdge(d, f)` | Edge midpoint relative to specific hex cell |
| `$hex.width`, `$hex.height` | Cell dimensions |

All hex coordinate types support param-dependent values in both builder and codegen (e.g., `$hex.offset($col, $row, even)`).

### Layout Positioning
`layout(layoutName)` or `layout(layoutName, $index)` — position from named layout definition.

### Offset Suffix
`.offset(x, y)` suffix on any coordinate expression adds a pixel offset to the result.
Works with all coordinate types: `layout(name).offset(5, 10)`, `$grid.pos(1, 2).offset(3, 4)`, `$hex.cube(q, r, s).offset(5, 5)`.

### Value Extraction
`.x` or `.y` suffix on any coordinate method extracts a single component for use in expressions.

### Extra Point Coordinates
Query extra points from `.anim` state animations as positioning coordinates (resolved at build time).

**From a named stateanim element:**
```manim
#player stateanim("player.anim", "idle", direction=>"l"): 100, 100
bitmap(...): $player.extraPoint("bulletSpawn")
bitmap(...): $player.extraPoint("bulletSpawn", fallback: 50, 50)
bitmap(...): $player.extraPoint("bulletSpawn").offset(10, 0)
```

**Directly from a .anim file:**
```manim
bitmap(...): extraPoint("player.anim", "fire-up", "fire", direction=>"r")
bitmap(...): extraPoint("player.anim", "idle", "fire", direction=>"l", fallback: 0, 0)
```

When a point is not found: throws if no `fallback:` specified, uses fallback coordinates otherwise. Fallback accepts any coordinate type (literal, layout, grid, etc.).

**`.x`/`.y` extraction in expressions:**
```manim
text(font, '${$player.extraPoint("fire").x + $OFFSET_X}', #FF0000): 0, 0
text(font, '${$ref.extraPoint("name", 99, 88).y}', #00FF00): 0, 0
```
Use `$ref.extraPoint("name").x` / `.y` to extract a single coordinate component for use in text interpolation and arithmetic expressions. Fallback via positional args: `$ref.extraPoint("name", fallbackX, fallbackY).x`.

Note: coordinates are static — resolved from the initial animation state at build time.

### Context Properties
| Property | Description |
|----------|-------------|
| `$ctx.width` | Container width |
| `$ctx.height` | Container height |
| `$ctx.random(min, max)` | Random value |
| `$ctx.font("name").lineHeight` | Font line height |
| `$ctx.font("name").baseLine` | Font baseline |

---

## Element Properties

Applied to any element via long-form body or inline syntax.

| Property | Description |
|----------|-------------|
| `pos: x, y` | Position offset |
| `grid: spacingX, spacingY` | Grid coordinate system for children |
| `hex: flat(w, h)` / `hex: pointy(w, h)` | Hex coordinate system for children |
| `scale: value` | Scale factor |
| `rotate: angle` | Rotation angle (supports `deg`, `rad`, `turn`, direction constants) |
| `alpha: value` | Opacity (0.0-1.0) |
| `tint: color` | Color tint overlay |
| `layer: index` | Z-order index within layers/programmable |
| `filter: filterType(...)` | Visual filter |
| `blendMode: mode` | Blend mode |

### Inline Property Prefixes (before element at `@`)
`@layer(index)`, `@alpha(value)`, `@scale(value)`, `@rotate(angle)`, `@tint(color)`, `@flow.halign(align)`, `@flow.valign(align)`, `@flow.offset(x, y)`, `@flow.absolute`

---

## Named Elements

| Syntax | Description |
|--------|-------------|
| `#name element(...)` | Named element — accessible from builder/codegen |
| `#name[$i] element(...)` | Indexed named element inside repeatable |
| `#name(updatable) element(...)` | Explicitly marked updatable for runtime property changes |
| `@(cond) #name element(...)` | Named element after conditional — `#name` can appear after `@` modifiers |

**Builder API:**
- `result.getUpdatable("name")` / `result.getUpdatableByIndex("name", index)`
- `result.hasName("name")` / `result.hasNameByIndex("name", index)` — check existence without throwing

---

## Parameterized Slots

Slots with parameters support visual states via conditionals. `slotContent` marks the content insertion point (parser-validated: must be inside a slot body).

```manim
#statusSlot slot(status:[empty,active,warning]=empty, label:string="Slot") {
    @(status=>empty) ninepatch(ui, slotBgEmpty, 64, 64): 0, 0
    @(status=>active) ninepatch(ui, slotBgActive, 64, 64): 0, 0
    @(status=>warning) ninepatch(ui, slotBgWarning, 64, 64): 0, 0
    text(f3x5, $label, #ffffffff): 5, 50
    slotContent: 8, 8
}
```

**Parameter types:** Same as `programmable()` — `uint`, `int`, `float`, `bool`, `string`, `color`, enum (`[val1,val2]`), range, flags.

**Body features:** Conditionals (`@()`, `@else`, `@default`), expressions (`$param`), all standard elements.

**Runtime API:**
- `slot.setParameter("status", "active")` — update visual state (incremental)
- `slot.setContent(obj)` / `slot.clear()` — content independent of decorations
- Codegen: `instance.getSlot_name().setParameter("status", "warning")`

**Indexed:** `#name[$i] slot(params)` inside repeatable — combines indexed access with parameters.

---

## Filters

| Filter | Description |
|--------|-------------|
| `outline(size, color)` | Stroke outline around edges |
| `glow(color, alpha, radius, gain, quality, smoothColor, knockout)` | Glow effect |
| `blur(radius, gain, quality, linear)` | Gaussian blur |
| `saturate(value)` | Color saturation (0=gray, 1=normal) |
| `brightness(value)` | Brightness multiplier (0=black, 1=normal) |
| `grayscale(value)` | Grayscale conversion (0=none, 1=full) |
| `hue(value)` | Hue rotation in degrees |
| `dropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor)` | Drop shadow |
| `pixelOutline(mode)` | Pixel-level outline — modes: `knockout(color, knockoutColor)` or `inlineColor(outlineColor, inlineColor)` |
| `replacePalette(palette, sourceRow, replacementRow)` | Swap palette rows |
| `replaceColor(sourceColors[], replacementColors[])` | Replace specific colors |
| `group(filter1, filter2, ...)` | Combine multiple filters |
| `none` | No filter / remove inherited filter |
| `customName(args...)` | Custom filter registered via `FilterManager` |

### Custom Filters

Game code can register custom filters via `FilterManager.registerFilter()`. Custom filters are parsed as opaque (unknown filter names are accepted) and validated at build time against registered filters.

**Registration (Haxe):**
```haxe
FilterManager.registerFilter("perlinNoise", [
    {name: "seed", type: CFFloat, defaultValue: 0.0},
    {name: "scale", type: CFFloat, defaultValue: 10.0},
    {name: "intensity", type: CFFloat, defaultValue: 0.5},
], (params) -> {
    return new PerlinNoiseFilter(params["seed"], params["scale"], params["intensity"]);
});
```

**Usage in `.manim`:**
```manim
filter: perlinNoise(42.0, 8.0, 0.6)
filter: group(perlinNoise(42.0, 12.0, 0.8), outline(1, #000000))
```

**Parameter types:** `CFFloat`, `CFColor` (hex colors), `CFBool` (true/false). Parameters support `$param` references. Extra args beyond the schema are ignored; missing args use defaults (or throw if no default). Filter names are case-insensitive and cannot shadow built-in filter names.

**Validation:** `FilterManager.validateCustomFilters(parseResult.customFilterRefs)` checks all custom filter references against the registry. Called automatically by `MultiAnimBuilder` and `DevBridge.eval_manim`.

---

## Blend Modes

`none`, `alpha`, `add`, `alphaAdd`, `softAdd`, `multiply`, `alphaMultiply`, `erase`, `screen`, `sub`, `max`, `min`

---

## Color Formats

Two conventions coexist. **CSS `#` forms** assume opacity (3/6 hex digits bake `0xFF` alpha). **Heaps `0x` forms** are the internal AARRGGBB representation and are preserved **verbatim** — the top byte IS alpha. If you write `0xFF0000`, that's transparent red (alpha = 0), not opaque red.

| Format | Example | Stored as | Notes |
|--------|---------|-----------|-------|
| `#RGB` | `#f00` | `0xFFFF0000` | CSS shorthand, expanded to `#RRGGBB` then baked opaque |
| `#RRGGBB` | `#FF0000` | `0xFFFF0000` | CSS RGB, baked opaque |
| `#RRGGBBAA` | `#FF000080` | `0x80FF0000` | CSS RGBA, alpha last — converted to Heaps AARRGGBB |
| `0xAARRGGBB` | `0xFFFF0000` | `0xFFFF0000` | Heaps literal, preserved exactly — alpha first |
| `0xRRGGBB` | `0xFF0000` | `0x00FF0000` | Heaps literal with top byte 0 — **transparent** red |
| Named | `red` | `0xFFFF0000` | Baked opaque at parser (except `transparent`) |

**Rule of thumb:** use `#RRGGBB` for opaque colors, `#RRGGBBAA` for CSS-style with alpha, and reserve `0x...` for cases where you're thinking in Heaps AARRGGBB and want byte-exact control (including fully transparent values).

### Runtime Color Semantics (Strict-D)

Color values are plain `Int`s in Heaps `0xAARRGGBB` form at every API boundary. **Nothing in the runtime rewrites alpha** — not `setColor(v)`, not `setParameter("c", v)`, not `createFrom({c: v})`, not hot-reload. If you want opaque red at runtime, pass `0xFFFF0000`. If you pass `0xFF0000`, you get transparent red; if you pass `0`, you get fully transparent.

**One documented exception:** `bh.base.HeapsUtils.solidTile(color, w, h)` / `solidBitmap(color, w, h)` treat `top-byte == 0` as opaque (alpha 1.0). This is a deliberate compat shim for legacy Haxe callers that pass bare `0xRRGGBB` (notably `TileHelper.generatedRectColor(w, h, 0xRRGGBB)` and the builder/codegen `generated(color(...))` path). For fully transparent, call `h2d.Tile.fromColor` directly with an explicit alpha argument. This exception does **not** apply to parameter/setter/color-literal paths — those are strict.

This means `@switch` arms match against already-baked values:
```manim
#widget programmable(tint:color=#FFFFFF) {
  @switch(tint) {
    #FF0000: bitmap(...);  // matches 0xFFFF0000
    #00000000: bitmap(...); // matches 0 / 0x00000000 (fully transparent)
    #000000: bitmap(...);  // matches 0xFF000000 (opaque black)
  }
}
```
`widget.setTint(0)` lands on the `#00000000` arm. `widget.setTint(0xFF000000)` lands on `#000000`. The two are now distinguishable — previously, 0-alpha inputs were silently clobbered to opaque black on the way into the field.

### Named Colors

**Basic (CSS):** `transparent`, `white`, `silver`, `lightgray`, `gray`, `darkgray`, `black`, `maroon`, `red`, `crimson`, `orange`, `coral`, `tomato`, `gold`, `yellow`, `wheat`, `olive`, `green`, `lime`, `forestgreen`, `teal`, `cyan`, `aqua`, `skyblue`, `blue`, `navy`, `indigo`, `purple`, `fuchsia`, `pink`, `brown`, `slate`

`transparent` = fully transparent (alpha 0). All other named colors are fully opaque.

### Settings Color Type

Use `:color` type annotation for explicit color semantics in settings:
```
fontColor:color => red
fontColor:color => #FF0000
fontColor:color => #FF000080
```

Untyped settings also accept `#hex` and `0xhex` values:
```
fontColor => #FF0000       // → 0xFFFF0000 (opaque red)
fontColor => 0xFFFF0000    // → 0xFFFF0000 (opaque red, explicit)
fontColor => 0xFF0000      // → 0x00FF0000 (transparent red — usually a bug)
```

---

## Palette Types

| Type | Description |
|------|-------------|
| `palette { colors... }` | Indexed color list |
| `palette(2d, width) { colors... }` | 2D color grid |
| `palette(file: "image.png")` | Colors from image file |
| `palette(external)` | External palette reference |

Access: `palette(name, index)` or `palette(name, x, y)` for 2D.

---

## Autotile

| Property | Description |
|----------|-------------|
| `format` | Tile format: `cross` (13 tiles) or `blob47` (47 tiles) |
| `tileSize` | Size of each tile in pixels |
| `source` | Tile source: `sheet(...)`, `file(...)`, `tiles: [...]`, or `demo(edgeColor, fillColor)` |
| `depth` | Isometric elevation depth (cross format) |
| `mapping` | Custom index-to-tile mapping (blob47) |
| `allowPartialMapping` | Allow incomplete tile mappings with fallback |

---

## Atlas2 (Inline Sprite Atlas)

Define inline within .manim file. Source can be image file or existing sheet reference.

Tile entry properties: `x, y, w, h`, plus optional `offset: ox, oy`, `orig: ow, oh`, `split: l, r, t, b`, `index: n`.

---

## Data Blocks

| Construct | Description |
|-----------|-------------|
| `#name enum(val1, val2, ...)` | Define enum type with named values |
| `#name record(field: type, ...)` | Define record schema |
| `fieldName: enumName value` | Enum value |
| `fieldName: recordName { ... }` | Record instance |
| `fieldName: type[] [values]` | Typed array |
| Optional fields with `?` prefix | Field not required |

Types: `int`, `float`, `string`, `bool`, enum names, record names, `type[]` arrays.

Enums generate Haxe `enum` types at compile time (via `@:data`). Runtime builder returns enum values as strings.

---

## Paths

### Path Commands

| Command | Description |
|---------|-------------|
| `forward(distance)` | Move forward in current direction |
| `turn(angle)` | Change direction by angle (degrees) |
| `arc(radius, angle)` | Circular arc |
| `spiral(radiusStart, radiusEnd, angle)` | Expanding/contracting arc |
| `wave(amplitude, wavelength, count)` | Sinusoidal wave |
| `lineTo(x, y)` | Relative line to point |
| `lineAbs(x, y)` | Absolute line to point |
| `moveTo(x, y)` | Jump to relative point (no line) |
| `moveAbs(x, y)` | Jump to absolute point |
| `bezier(endX, endY, ctrl1X, ctrl1Y, ctrl2X, ctrl2Y, smoothing)` | Relative bezier curve |
| `bezierAbs(endX, endY, ctrl1X, ctrl1Y, ctrl2X, ctrl2Y, smoothing)` | Absolute bezier curve |
| `checkpoint(name)` | Named position marker |
| `close` | Close path back to start |

Bezier smoothing options: `auto`, `distance(value)`, or none.

---

## Animated Paths

### Properties

| Property | Description |
|----------|-------------|
| `path` | Path reference (required) |
| `type` | `time` (duration-based) or `distance` (speed-based) |
| `duration` | Duration in seconds (time mode) |
| `speed` | Speed in px/sec (distance mode) |
| `loop` | Repeat continuously |
| `pingPong` | Alternate forward/reverse |
| `easing` | Shorthand for `progressCurve` |

### Curve Slots (at rate 0.0-1.0 or checkpoint name)

| Curve | Description |
|-------|-------------|
| `progressCurve` | Maps elapsed time to path progress (time mode) |
| `speedCurve` | Speed multiplier over lifetime (distance mode) |
| `scaleCurve` | Scale value over lifetime |
| `alphaCurve` | Opacity over lifetime |
| `rotationCurve` | Additional rotation over lifetime |
| `colorCurve: curve, #start, #end` | Color interpolation (multi-segment) |
| `custom("name"): curve` | User-defined numeric value |

### Events
`event("name")` at any rate. Built-in events: `pathStart`, `pathEnd`, `cycleStart`, `cycleEnd`.

---

## Curves

### Curve Definitions

| Style | Description |
|-------|-------------|
| `easing: easingName` | Single easing function |
| `points: [(t,v), ...]` | Linear interpolation between control points |
| `[start..end] easing` | Segmented easing (optionally with explicit value range) |
| `cubicBezier(x1, y1, x2, y2)` | Custom cubic bezier curve |

### Curve Operations

| Operation | Syntax | Result |
|-----------|--------|--------|
| `multiply: [a, b, ...]` | N-ary product | `a(t) * b(t) * ...` |
| `apply: inner, outer` | Composition | `outer(inner(t))` |
| `invert: a` | Inversion | `1.0 - a(t)` |
| `scale: a, factor` | Scaling | `a(t) * factor` |

Operations reference other named curves **or built-in easing names**. Forward references and chaining allowed. Circular references error.

Example using easing names directly in operations:
```manim
curves {
    #env curve { points: [(0, 0), (0.1, 1.0), (0.9, 1.0), (1.0, 0)] }
    #shaped curve { multiply: [easeInBack, env] }
    #gentle curve { scale: easeOutBounce, 0.7 }
    #composed curve { apply: easeOutBounce, easeInQuad }
}
```

### Easing Names
`linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeOutBounce`, `easeOutElastic`

---

## Particles

### Angle Units

All angle properties accept unit suffixes and direction constants:

| Unit/Constant | Description |
|---------------|-------------|
| `90deg` | Degrees (default for bare numbers) |
| `1.57rad` | Radians |
| `0.25turn` | Turns (1 turn = 360°) |
| `right` | 0° (positive X) |
| `down` | 90° (positive Y) |
| `left` | 180° |
| `up` | 270° |
| `down + 10deg` | Direction with offset expression |

Angle units also work in graphics `arc()`, `dropShadow` filter angle, and path `turn()`/`arc()`/`spiral()`.

### Emission Modes

| Mode | Description |
|------|-------------|
| `point(dist: N, distRand: N)` | Emit from a point with optional spread |
| `cone(dist: N, distRand: N, angle: A, angleSpread: A)` | Directional cone emission |
| `box(w: N, h: N, angle: A, angleSpread: A [, center: true])` | Rectangular area emission |
| `circle(r: N, rRand: N, angle: A, angleSpread: A)` | Circular area emission |
| `path(pathName [, tangent])` | Emit along a path, optionally tangent-aligned |

```
emit: cone(dist: 50, distRand: 10, angle: right, angleSpread: 90deg)
emit: box(w: 100, h: 100, center: true, angle: down, angleSpread: 45deg)
emit: circle(r: 50, rRand: 10, angle: 0deg, angleSpread: 180deg)
```

### Core Properties

| Property | Aliases | Description |
|----------|---------|-------------|
| `count` | | Maximum alive particles |
| `loop` | | Continuous emission |
| `maxLife` | | Particle lifetime in seconds |
| `lifeRandom` | `lifeRand` | Lifetime variance (0-1) |
| `relative` | | Particles move with emitter |
| `externallyDriven` | | Disable auto-update; use `advanceTime(dt)` |

### Movement

| Property | Aliases | Description |
|----------|---------|-------------|
| `speed` | | Initial velocity |
| `speedRandom` | `speedRand` | Speed variance |
| `speedIncrease` | `speedIncr`, `acceleration` | Acceleration |
| `gravity` | | Gravity strength |
| `gravityAngle` | | Gravity direction (angle) |

### Size & Rotation

| Property | Aliases | Description |
|----------|---------|-------------|
| `size` | | Particle size |
| `sizeRandom` | `sizeRand` | Size variance |
| `rotationInitial` | `rotInitial` | Starting rotation (angle) |
| `rotationSpeed` | `rotSpeed` | Spin rate (angle/sec) |
| `rotationSpeedRandom` | `rotSpeedRand` | Spin variance |
| `rotateAuto` | `autoRotate` | Auto-rotate to face velocity |
| `forwardAngle` | | Sprite forward direction (angle) |

### Fading

| Property | Description |
|----------|-------------|
| `fadeIn` | Fade-in point (0-1 of lifetime) |
| `fadeOut` | Fade-out start (0-1 of lifetime) |
| `fadePower` | Fade curve exponent |

### Rendering

| Property | Aliases | Description |
|----------|---------|-------------|
| `blendMode` | | Blend mode for particles |
| `tiles` | | Tile sources (file, sheet, generated) |
| `emitDelay` | `delay` | Fixed delay before emission |
| `emitSync` | | Synchronization (0=spread, 1=burst) |
| `animFile` | | State animation file |
| `animSelector` | | State selection |
| `animationRepeat` | `animRepeat` | Animation loops |

### Color

```
colorStops: 0.0 #FF4400, 0.5 #FFAA00 easeInQuad, 1.0 #FFFF88
```
Each stop: `rate color [curve]`. Curve specifies interpolation to next stop (default: linear).

### Lifetime Curves

| Property | Description |
|----------|-------------|
| `sizeCurve` | Size over lifetime (named curve or inline easing) |
| `velocityCurve` | Speed over lifetime |
| `spawnCurve` | Emission rate modulation |

### Lifetime Animation Events
`rate: anim("name")` — trigger animation at lifetime rate.
`onBounce: anim("name")` — trigger on boundary collision.

### Bounds

```
bounds: kill, box(x: 0, y: 0, w: 800, h: 600)
bounds: bounce(0.6), box(x: -50, y: -50, w: 250, h: 250), line(0, 0, 100, 0)
```

### Force Fields

| Force | Description |
|-------|-------------|
| `turbulence(strength, scale, speed)` | Noise-based turbulence |
| `wind(vx, vy)` | Constant directional force |
| `vortex(x, y, strength, radius)` | Circular spinning force |
| `attractor(x, y, strength, radius)` | Pull toward point |
| `repulsor(x, y, strength, radius)` | Push away from point |
| `pathguide(path, attractStrength, flowStrength, radius)` | Guide along path |

### Sub-Emitters

| Property | Description |
|----------|-------------|
| `groupId` | Particle group reference |
| `trigger` | `onbirth`, `ondeath`, `oncollision`, `oninterval(seconds)` |
| `probability` | Spawn chance (0-1) |
| `burstCount` | Number of particles to emit per trigger |
| `inheritVelocity` | Velocity inheritance factor |
| `offsetX`, `offsetY` | Spawn offset |

### Path Integration
`attachTo: pathName` — emitter follows animated path.

### Shutdown

Graceful particle stop — configures how a looping emitter winds down when `shutdown()` is called at runtime.

```manim
shutdown: {
    duration: 1.0                    // wind-down time in seconds
    curve: easeOutQuad               // count curve (how fast particles stop recycling)
    alphaCurve: easeInQuad           // global alpha multiplier during shutdown
    sizeCurve: myCustomCurve         // global size multiplier during shutdown
    speedCurve: linear               // global speed multiplier during shutdown
}
```

| Property | Description |
|----------|-------------|
| `duration` | Default shutdown duration (seconds). Used when `shutdown()` called without args |
| `curve` | Count curve — shapes how particle density decreases. `easeOutQuad` = fast initial die-off |
| `alphaCurve` | Alpha multiplier over shutdown. Applied on top of per-particle fadeIn/fadeOut |
| `sizeCurve` | Size multiplier over shutdown. Applied on top of per-particle sizeCurve |
| `speedCurve` | Speed multiplier over shutdown. Applied on top of per-particle velocityCurve |

**Curve convention:** All curves use "progress" semantics: `multiplier = 1.0 - curve(t)` where `t` is shutdown progress (0..1). Standard easings work intuitively — `easeOutQuad` means fast start (rapid initial die-off / fade), `easeInQuad` means slow start (lingers then rapid end).

**Runtime API:**
```haxe
// Graceful shutdown (uses .manim configured duration/curves)
particles.shutdown();

// Override duration
particles.shutdown(0.5);

// Override duration and count curve
particles.shutdown(1.0, myCustomCurve);

// Per-group control
group.shutdown(1.0);

// Query state
group.isShuttingDown();  // Bool
group.getShutdownRate(); // 0..1 progress

// Set curves via API before calling shutdown()
group.shutdownCountCurve = myCurve;
group.shutdownAlphaCurve = myCurve;
group.shutdownSizeCurve = myCurve;
group.shutdownSpeedCurve = myCurve;
```

**Behavior:**
- No-op on non-looping groups
- After shutdown, `emitBurstAt()` still works (manual one-shot effects)
- `group.emitFilter = (x:Float, y:Float) -> Bool` — filter particles by world-space spawn position (return `false` to discard). Works for both relative and non-relative groups
- Existing `onEnd()` callback fires when last particle dies (default: `this.remove()`)
- Total visual clear time: `duration` (curve phase) + up to `maxLife` (natural die-off of remaining particles)

### Externally Driven

When `externallyDriven: true`, particles do not auto-update from the render loop. Game code drives the simulation:

```haxe
// Drive all externally-driven groups:
particles.advanceTime(dt);

// Or per-group:
group.advanceTime(dt);
```

---

## Layouts

Defined inside `layouts { ... }` block at the root of a programmable.

### Layout Entry Types

| Syntax | Description |
|--------|-------------|
| `#name point: x, y` | Single named position |
| `#name point: $grid.pos(x, y)` | Single position using grid coordinates |
| `#name list { point: x, y; ... }` | Explicit list of positions |
| `#name sequence($i: from..to) point: expr, expr` | Generated positions from range variable |
| `#name cells(cols: N, rows: N, cellWidth: N, cellHeight: N)` | Cell grid layout — `cols * rows` points in row-major order |

### Container Blocks

Containers scope coordinate systems and offsets for nested entries:

| Block | Description |
|-------|-------------|
| `grid: spacingX, spacingY { ... }` | Set grid coordinate system for children |
| `hexgrid: flat\|pointy(w, h) { ... }` | Set hex coordinate system for children |
| `offset: x, y { ... }` | Add offset to all children (cumulative, nestable) |

### Accessing Layout Points

| Syntax | Description |
|--------|-------------|
| `layout(layoutName)` | Position element at layout's single/first point |
| `layout(layoutName, $index)` | Position at indexed point (for list/sequence/cells) |

### Alignment (Edge-Relative Positioning)

Per-layout trailing modifier that changes the coordinate origin edge. Coordinates become insets from the specified edge of the screen/container.

```
#name <layout-type> align: <values>
```

| Value | Axis | Meaning |
|-------|------|---------|
| `left` | X | Default — x measured from left edge |
| `right` | X | x measured from right edge (`screenWidth - x`) |
| `centerX` | X | x measured from horizontal center (`screenWidth/2 + x`) |
| `top` | Y | Default — y measured from top edge |
| `bottom` | Y | y measured from bottom edge (`screenHeight - y`) |
| `centerY` | Y | y measured from vertical center (`screenHeight/2 + y`) |
| `center` | X+Y | Shorthand for `centerX, centerY` |

Only one value per axis is allowed. Mixing two X values (e.g. `right, centerX`) or two Y values is an error. `center` cannot be combined with any other value (ambiguity error).

```manim
#hud point: 10, 10 align: right, top           # 10px from right edge, 10px from top
#status point: 0, 20 align: center             # centered on screen, 20px below center
#invGrid cells(...) align: right, bottom        # grid anchored from bottom-right
```

### Example

```manim
layouts {
    offset: 10, 20 {
        #pos1 point: 50, 100
        grid: 32, 32 {
            #slots sequence($i: 0..5) point: $grid.pos($i, 0)
        }
        hexgrid: pointy(25.0, 25.0) {
            #hexPattern list {
                point: $hex.cube(0, 0, 0)
                point: $hex.cube(1, -1, 0)
                point: $hex.cube(0, 1, -1)
            } align: right
        }
        #invGrid cells(cols: 4, rows: 3, cellWidth: 58, cellHeight: 58)
        #minimap point: 10, 10 align: right, bottom
    }
}

// Using layouts in programmable:
#myComponent programmable() {
    bitmap(...): layout(pos1)                              // single point
    bitmap(...): layout(minimap).offset(-80, 0)            // with offset suffix
    repeatable($i, layout("slots")) {                      // layout iterator
        bitmap(...): 0, 0                                  // children at 0,0 (iterator positions the wrapper)
    }
}
```

---

## Placeholder Types

| Type | Description |
|------|-------------|
| `callback("name")` | Content resolved by runtime callback |
| `callback("name", $index)` | Callback with index parameter |
| `builderparameter("name")` | Content from builder parameter |
| `error` | Show error marker |
| `nothing` | Empty/invisible placeholder |

---

## UI Components (Built-in Programmables)

These are pre-built UI components used through the builder/screen system.

| Component | Description |
|-----------|-------------|
| **Button** | Clickable button with text, hover/pressed states, disabled state |
| **Checkbox** | Toggle with checked/unchecked states |
| **Checkbox with text** | Checkbox combined with label text |
| **Slider** | Draggable value selector with custom range (int or float) |
| **Radio buttons** | Mutually exclusive selection group |
| **Dropdown** | Collapsible selection list with scrollable panel |
| **Scrollable list** | Scrollable list of selectable items with scrollbar. `setItems(?preserveScroll)`, `scrollToIndex()`, `clickMode`, disabled state |
| **Progress bar** | Display-only value indicator (0-100) |
| **Interactive** | Hit-test region with ID and optional typed metadata |
| **Draggable** | Drag-and-drop with drop zones, slot integration, swap mode |
| **Grid** | 2D grid (rect or hex) with cell state, drag-drop zones, card targeting |
| **Tabs** | Tab bar with per-tab content management, relative coordinates mode |

### Tabs Settings

| Setting | Category | Description |
|---------|----------|-------------|
| `buildName` | control | Tab bar programmable name (default: `"tabBar"`) |
| `tabButtonBuildName` | control | Tab button programmable name (default: `"tab"`) |
| `tabButton.*` | prefixed | Forwarded to tab buttons (e.g. `tabButton.width`, `tabButton.height`) |
| `tabPanel.width` | prefixed | Panel ninepatch width (→ `panelWidth` param) |
| `tabPanel.height` | prefixed | Panel ninepatch height (→ `panelHeight` param) |
| `tabPanel.contentRoot` | behavioral | Named element for relative coordinates (e.g. `contentArea`) |

When `tabPanel.contentRoot` is set, tab content coordinates are relative to the named element's position. Each tab gets its own `h2d.Layers` for proper layer support within the panel.

### Grid Component (`UIMultiAnimGrid`)

2D grid (rectangular or hexagonal) managing cell state, rendering, drag-drop, and card targeting.

| Config field | Description |
|-------------|-------------|
| `gridType` | `Rect(cellW, cellH, ?gap)` or `Hex(orientation, sizeX, sizeY)` |
| `cellVisualFactory` | `CellVisualFactory<T>` — factory for building cell visuals (required) |
| `originX`, `originY` | Grid root position |
| `snapPathName` | AnimatedPath for drop snap (null = instant) |
| `returnPathName` | AnimatedPath for drag cancel return (null = instant) |
| `swapPathName` | AnimatedPath for displaced item during swap (null = falls back to `returnPathName`, then instant) |
| `swapEnabled` | Enable swap semantics on occupied cell drops (default: false) |
| `swapAccepts` | `(cell, draggable) -> Bool` delegate for swap decision. When null, defaults to `isOccupied()` |
| `swapAnimContainer` | Parent container for in-flight swap visuals (null = grid root at high z-order) |
| `swapVisualProvider` | `(cell, data) -> Null<h2d.Object>` delegate for custom displaced-item visuals |
| `tweenManager` | Optional `TweenManager` for cell lifecycle animations (null = instant) |
| `rectOrigin` | Cell origin for Rect grids: `TopLeft` (default) or `Centered` (hit area centered on cell position) |
| `cellDragEnabled` | Cells with data become draggable on press (default: false) |
| `cellDragFilter` | `(col, row, data) -> Bool` filter for which cells can be dragged (null = all with data) |
| `cellDragContainer` | Parent container for drag visual (null = grid root at high z-order) |

**`DefaultCellVisualFactory` config** (`CellVisualFactoryConfig`): `cellBuildName` (programmable name), `?cellBuildDelegate`, `?highlightParam` (default `"highlight"`), `?statusParam` (default `"status"`), `?highlightDelegate`.

**`CellVisual<T>` interface** — wraps the visual representation of a grid cell:

| Method | Description |
|--------|-------------|
| `object:h2d.Object` | Scene graph object |
| `setHighlight(value)` | Set highlight state (e.g. `"none"`, `"accept"`, `"reject"`) |
| `setStatus(value)` | Set status state (e.g. `"normal"`, `"hover"`) |
| `beginUpdate(?data:T)` | Begin batch update — defers re-evaluation. Optional `data` for typed payload |
| `endUpdate()` | End batch update — applies all deferred changes |
| `getResult():Null<BuilderResult>` | Escape hatch for game-specific parameter access |

**Cell programmable contract:** Must have `col:int`, `row:int`, plus matching `highlightParam` (enum with "none"/"accept"/"reject") and `statusParam` (enum with `normal`/`hover`). Custom highlight values supported via `highlightDelegate` on factory config.

**Events** (`GridEvent` enum via `onGridEvent`): `CellClick`, `CellHoverEnter`, `CellHoverLeave`, `CellDrop(cell, draggable, sourceGrid, sourceCell, ctx)`, `CellSwap(source, target, draggable, ctx)`, `CellDragStart(cell, draggable)`, `CellDragEnd(cell)`, `CellCardPlayed`, `CellDataChanged`. `CellDrop` includes `DropContext`: `ctx.accept()` / `ctx.reject()` controls snap vs return animation; `ctx.onComplete(cb)` fires after animation; `ctx.acceptWithPath(name)` / `ctx.rejectWithPath(name)` for custom paths. `CellSwap` includes `SwapContext`: `ctx.accept()` / `ctx.reject()`, `ctx.acceptWithSwapPath(name)` / `ctx.acceptWithPaths(snap, swap)` for custom paths, `ctx.onComplete(cb)` / `ctx.onSnapComplete(cb)`, `ctx.programmatic` flag (true for `swapCells()`, false for drag-drop). `CellDragStart`/`CellDragEnd` emitted by built-in cell drag (`cellDragEnabled`).

**Key API:** `addRectRegion(cols, rows)`, `addHexRegion(center, radius)`, `set(col, row, data, ?params)`, `get()`, `clear()`, `isOccupied()`, `forEach()`, `cellAtPoint(sceneX, sceneY)`, `sceneToHex(sceneX, sceneY)`, `cellPosition(col, row)`, `neighbors()`, `distance()`, `acceptDrops(draggable, ?filter)`, `registerAsCardTarget(cardHand, ?filter)`, `makeDraggableFromCell(col, row, ?visual)`, `linkDropTarget(target, ?accepts)`, `unlinkDropTarget(target)`, `UIMultiAnimGrid.linkGrids(a, b, ?accepts)`, `dispose()`.

**Grid layers:** `addLayer(name, {buildName, zOrder})`, `setLayer(col, row, name, ?params)`, `clearLayer(col, row, name)`, `clearLayerAll(name)`, `clearAllLayers()`, `getLayerVisual(col, row, name)`, `hasLayer()`. Base cells at z-order 0; layers at configurable z-orders. `removeCell()` auto-clears layers. **External objects:** `addExternalObject(obj, zOrder)` / `removeExternalObject(obj)`.

**Cell swap:** `swapCells(col1, row1, col2, row2, ?animated)` — swap data and visuals between two cells. Animated mode uses `swapPathName` (fallback: `returnPathName`) for both items. Emits `CellSwap` with `ctx.programmatic=true`. Drag-drop swap: when `swapEnabled=true` and a draggable drops on a cell with a source cell, the `swapAccepts` delegate (or `isOccupied()` by default) decides whether to emit `CellSwap` or fall through to `CellDrop`.

**Cell animations** (require `tweenManager`): `tweenCell(col, row, duration, props, ?easing)`, `addCellAnimated(col, row, ?data, ?params, duration, initProps, ?easing)`, `removeCellAnimated(col, row, duration, props, ?easing, ?onComplete)`. **Detach/reattach**: `detachCellVisual(col, row)` → `{object, data, sceneX, sceneY}`, `reattachCellVisual(col, row, ?obj)`.

### Common UI Settings

| Setting | Description |
|---------|-------------|
| `buildName` | Override programmable name for single-builder component |
| `text` | Button text content |
| `initialValue` | Starting value (checkbox, slider) |
| `min`, `max`, `step` | Numeric range (slider) |
| `width`, `height` | Dimensions |
| `font`, `fontColor` | Typography |
| `panelMode` | `scrollable` or `scalable` (dropdown, scrollable list) |
| `scrollSpeed` | Scroll velocity |
| `clickMode` | `"single"` or `"double"` — action event mode (scrollable list) |
| `prefix.setting` | Route setting to sub-builder (`item.font`, `scrollbar.thickness`) |
| `overlay.color` | Modal overlay color (`:color`, e.g. `#000000`) |
| `overlay.alpha` | Modal overlay opacity (`:float`, 0.0–1.0) |
| `overlay.fadeIn` | Overlay fade-in duration in seconds (`:float`) |
| `overlay.fadeOut` | Overlay fade-out duration in seconds (`:float`) |
| `overlay.blur` | Blur radius on underlying screens (`:float`, 0 = none) |

---

## Incremental Update Mode

When enabled, elements support efficient runtime updates without full rebuild:
- All conditional branches built simultaneously (non-matching set invisible)
- Expression-dependent properties tracked for targeted updates
- `setParameter()` re-evaluates only affected properties
- `beginUpdate()` / `endUpdate()` for batched parameter changes

Used by: dynamic refs, slider, scrollbar, parameterized slots, button, checkbox, tab button.

---

## Transition Declarations

Declare animated transitions for parameter changes inside programmable elements. When a parameter with a transition is changed via `setParameter()`, visibility changes are animated instead of instant.

```manim
#button programmable(status:[normal,hover,pressed]=normal) {
    transition {
        status: crossfade(0.1, easeOutQuad)
    }
    @(status => normal)  bitmap(...): 0, 0
    @(status => hover)   bitmap(...): 0, 0
    @(status => pressed) bitmap(...): 0, 0
}
```

### Transition Types

| Type | Description |
|------|-------------|
| `none` | Instant visibility (default behavior) |
| `fade(duration, ?easing)` | One-sided alpha fade (showing element fades in, hiding fades out independently) |
| `crossfade(duration, ?easing)` | Sequential blend-through-zero: old fades out over `duration`, then new fades in over `duration` (total = 2 × `duration`) |
| `flipX(duration, ?easing)` | Scale X to 0 then back to 1 (half-duration each) |
| `flipY(duration, ?easing)` | Scale Y to 0 then back to 1 (half-duration each) |
| `slide(direction, duration, ?distance, ?easing)` | Position + alpha offset animation (distance defaults to 50px) |

### Slide Directions

`left`, `right`, `up`, `down`

### Requirements

- Must be inside a `programmable` body
- Parameter names must match declared parameters
- Requires `TweenManager` — auto-injected when using `ScreenManager.buildFromResource()` or when `MultiAnimBuilder.tweenManager` is set
- Falls back to instant visibility when no TweenManager is available
- Codegen path (`@:manim`): generates `CodegenTransitionHelper` with `setTweenManager(tm)` and `cancelAllTransitions()` methods; factory auto-injects `tweenManager` from `ProgrammableBuilder`

### Behavior

- In-progress transitions are finished immediately when a new parameter change occurs
- Alpha, scaleX, scaleY, position values are saved before transition and restored on completion
- Works with incremental update mode (used by all UI controls)

---

## Interactive Event Filtering & Bind

### Event Filtering

Control which events an interactive emits via `events:` metadata:

```manim
interactive(200, 30, "myBtn", events: [hover, click])
interactive(200, 30, "tooltip-trigger", events: [hover])
```

| Flag | Events controlled |
|------|-------------------|
| `hover` | `UIEntering(?data)` + `UILeaving` |
| `click` | `UIClick` |
| `push` | `UIPush` + `UIClickOutside` + outside-click tracking |

Default: all events enabled. Omitting `events:` emits all event types.

### autoStatus Metadata (Screen Auto-Wiring)

Auto-wire Normal→Hover→Pressed state management at screen level — no manual `UIRichInteractiveHelper` needed:

```manim
interactive(200, 30, "shopBtn", autoStatus => "status", events: [hover, click, push])
```

When `screen.addInteractives(result)` detects `autoStatus` metadata, it automatically creates an internal `UIRichInteractiveHelper` and wires hover/press/leave state transitions. Events still reach `onScreenEvent()` for game logic.

Advanced: `screen.getAutoInteractiveHelper()` returns the internal helper for `setDisabled()`, `setParameter()`, etc.

### Bind Metadata (Manual Wiring)

For custom state management (e.g., `UICardHandHelper`), use `bind` with a manually-created `UIRichInteractiveHelper`:

```manim
interactive(200, 30, "shopBtn", bind => "status", events: [hover, click, push])
```

`UIRichInteractiveHelper.register(result, ?prefix, metadataKey)` scans interactives for the given metadata key (default: `"bind"`) and auto-wires state transitions. The key `"autoStatus"` is reserved and throws if used manually.

**Important:** An interactive cannot have both `autoStatus` and `bind` — `register()` throws if the screen already manages the interactive via `autoStatus`.

### Cursor Metadata

Set cursor for interactive elements via `cursor` metadata:

```manim
interactive(200, 30, "buyBtn", cursor => "pointer")
interactive(200, 30, "dragArea", cursor => "move", cursor.hover => "move", cursor.disabled => "default")
```

| Key | Description |
|-----|-------------|
| `cursor` | Base cursor (fallback for all states). Default: `CursorManager.getDefaultInteractiveCursor()` |
| `cursor.hover` | Cursor when hovered. Default: same as `cursor` |
| `cursor.disabled` | Cursor when disabled. Default: `CursorManager.getDefaultCursor()` |

Pre-registered cursor names: `default`, `pointer`/`button`, `move`, `text`, `hide`/`none`. Register custom cursors via `CursorManager.registerCursor("name", cursor)`.

### Event Priority

Control event dispatch order when interactives overlap via `eventPriority` metadata:

```manim
interactive(200, 30, "overlay", eventPriority:int => 10)
interactive(200, 30, "background", eventPriority:int => 0)
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `eventPriority` | `int` | `0` | Higher values receive events first when overlapping |

When multiple interactives overlap at the cursor position, `UIDefaultController` sorts by `eventPriority` (descending), with registration order as tiebreaker for equal priorities. By default, the first element consumes the event (no bubbling).

**Priority tier constants** (`UIEventPriority` class):

| Constant | Value | Usage |
|----------|-------|-------|
| `Content` | 0 | Normal screen content — buttons, lists, interactives |
| `Overlay` | 100 | Floating overlays — dropdown panels, tooltips, popovers |
| `Modal` | 200 | Modal dialogs — above all other UI |

Use arithmetic for fine-tuning: `UIEventPriority.Overlay + 2`. Built-in components automatically use appropriate tiers:
- **Dropdown** sets `Overlay` when panel opens, `Content` when closed
- **PanelHelper** sets `Overlay` on all panel interactives at registration time

`UIInteractiveWrapper.eventPriority` is publicly writable for programmatic override after construction.

### Event Bubbling

Event handlers can pass events through to the next overlapping element by setting `wrapper.consumed = false` in `onEvent()`:

```haxe
public function onEvent(wrapper:UIElementEventWrapper):Void {
    // Handle event...
    wrapper.consumed = false; // pass through to element below
}
```

- `consumed` defaults to `true` — existing elements consume events without code changes
- Hover (enter/leave) is always single-element (topmost only, no bubbling)
- Click, release, key, and wheel events support bubbling
- `UIElementPriority` is an opt-in interface — elements without it default to priority 0

---

## Macro Code Generation

| Macro | Description |
|-------|-------------|
| `@:manim("file", "name")` | Generate typed factory and instance classes from programmable |
| `@:data("file", "name", "pkg")` | Generate typed record classes from data block |
| `@:build(ProgrammableCodeGen.buildAll())` | Trigger code generation on class |

Generated factories provide type-safe `create()`, `createFrom()`, parameter setters, and element accessors.

---

## Card Hand Config (`CardHandConfig`)

All fields are optional. Used with `UICardHandHelper` / `addCardHand()`.

### Layout

| Field | Type | Description |
|-------|------|-------------|
| `layoutMode` | `HandLayoutMode` | `Fan`, `Linear`, or `PathLayout` |
| `anchorX` | Float | Hand anchor X position |
| `anchorY` | Float | Hand anchor Y position |
| `cardWidth` | Float | Card width for layout calculations |
| `cardHeight` | Float | Card height for layout calculations |

### Fan Layout

| Field | Type | Description |
|-------|------|-------------|
| `fanRadius` | Float | Arc radius for fan spread |
| `fanMaxAngle` | Float | Maximum total angle of fan arc |

### Linear Layout

| Field | Type | Description |
|-------|------|-------------|
| `linearSpacing` | Float | Horizontal spacing between cards |
| `linearMaxWidth` | Float | Maximum total width — cards compress spacing to fit |

### Path Layout

| Field | Type | Description |
|-------|------|-------------|
| `layoutPathName` | String | Name of path in `paths{}` block |
| `pathDistribution` | `PathDistribution` | `EvenArcLength` (uniform visual spacing) or `EvenRate` (equal rate increments) |
| `pathOrientation` | `PathOrientation` | `Tangent`, `Straight`, or `TangentClamped(maxDeg)` |

### Hover

| Field | Type | Description |
|-------|------|-------------|
| `hoverPopDistance` | Float | Vertical pop distance on hover |
| `hoverScale` | Float | Scale multiplier on hover |
| `hoverNeighborSpread` | Float | Extra spacing pushed to neighbor cards during hover |

### Targeting

| Field | Type | Description |
|-------|------|-------------|
| `targetingThresholdY` | Float | Legacy: auto-creates full-width zone above `anchorY - threshold` (default: 100) |
| `targetingZones` | `Array<TargetingZone>` | Explicit zones — `{id, x, y, w, h}` rects in handContainer local space. Replaces threshold when set |

### Card-to-Card

| Field | Type | Description |
|-------|------|-------------|
| `allowCardToCard` | Bool | Enable card-to-card combining interactions |
| `cardToCardHighlightScale` | Float | Scale applied to target card during card-to-card hover |
| `cardToCardHoverPop` | Bool | Pop the target card upward during card-to-card hover |
| `cardToCardHoverScale` | Bool | Scale the target card during card-to-card hover |
| `cardToCardSpread` | Bool | Spread neighbor cards when hovering over a card-to-card target |

### Pile Positions

| Field | Type | Description |
|-------|------|-------------|
| `drawPilePosition` | `FPoint` | Off-screen origin for draw animations |
| `discardPilePosition` | `FPoint` | Off-screen destination for discard animations |

### Layers

| Field | Type | Description |
|-------|------|-------------|
| `handLayer` | `LayersEnum` | Scene layer for the hand container |
| `dragLayer` | `LayersEnum` | Scene layer for dragged cards and targeting arrow |

### Animation Paths

| Field | Type | Description |
|-------|------|-------------|
| `drawPathName` | String | `animatedPath` name for draw animation (null = instant). Uses tracking: endpoint dynamically follows the card's layout position each frame, handling concurrent draws gracefully |
| `discardPathName` | String | `animatedPath` name for discard animation (null = instant) |
| `returnPathName` | String | `animatedPath` name for return-to-hand animation (null = instant) |
| `rearrangePathName` | String | `animatedPath` name for rearrange animation (null = instant) |

### Targeting Arrow (Segmented Chain)

The targeting arrow renders as a **chain of `.manim` programmable instances** placed evenly along a Stretch-normalized path from the card's origin to the cursor (or snapped target).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `arrowSegmentName` | String | null | Programmable name for arrow body segments (receives `valid:bool`) |
| `arrowHeadName` | String | null | Programmable name for arrow tip (receives `valid:bool`) |
| `arrowPathName` | String | null | Path name for arrow curve shape |
| `arrowSegmentSpacing` | Float | 25.0 | Pixel spacing between segments |

Segments are placed at evenly-spaced rates along the path, rotated to follow the tangent. The head is placed at the endpoint. Max 30 segments. When `arrowSegmentName` is null, no arrow visual is drawn (target detection still works). Both segment and head programmables must accept a `valid:bool` parameter for valid/invalid target state.

### Other

| Field | Type | Description |
|-------|------|-------------|
| `interactivePrefix` | String | Prefix for card interactive IDs (default: `"card"`) |
| `onCardBuilt` | `(CardId, BuilderResult, h2d.Object) -> Void` | Callback after each card is built — customize via `result.getSlot()`, `result.setParameter()` |

---

## Screen Manager

### `SceneLayerConfig`

Configures scene layer ordering for `ScreenManager`. All fields optional. Passed to `new ScreenManager(s2d, ?sceneLayerConfig)`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `content` | Int | 2 | Main game screen layer |
| `master` | Int | 4 | Persistent overlay screen layer (e.g. top bar) |
| `overlay` | Int | 5 | Modal darkening overlay layer |
| `dialog` | Int | 6 | Modal dialog screen layer |

**Validation:** Must satisfy strict ordering `content < master < overlay < dialog`. Throws at construction if violated.

### Screen Data Passing

`switchTo()` and `modalDialogWithTransition()` accept an optional `data:Dynamic` parameter that is delivered to the target screen via the `UIEntering(?data)` event:

```haxe
// Sending data:
screenManager.switchTo(shopScreen, {itemId: 42, category: "weapons"}, Fade(0.3));
screenManager.modalDialogWithTransition(confirmDialog, this, "confirm", {action: "delete"}, SlideUp(0.3));

// Receiving data in target screen's onScreenEvent:
case UIEntering(data):
    if (data != null) {
        var itemId:Int = data.itemId;
        // use data...
    }
```

## ScreenShakeHelper

Additive screen shake for impact feedback. File: `src/bh/ui/ScreenShakeHelper.hx`. Construct with `new ScreenShakeHelper(target:h2d.Object)`.

| Method | Description |
|--------|-------------|
| `shake(intensity, duration)` | Linear-decay shake |
| `shakeDirectional(intensity, duration, dirX, dirY)` | Axis-masked shake (1.0 full / 0.0 none) |
| `shakeWithCurve(intensity, duration, curve)` | Custom decay curve — curve receives `remaining` ratio 0..1, returns factor |
| `update(dt)` | Drive decay; call from game loop |
| `stop()` | Cancel and remove residual offset |
| `isShaking` | Query active state |

Concurrent shakes stack additively (explosion + hit). Applies per-frame offsets as *deltas* so gameplay movement (camera, layout, animation) is not fought back to a captured baseline. Uniform jitter via `hxd.Rand`. No per-frame allocations. Works with curves loaded from `.manim` `curves {}` via `builder.getCurve("name")`.

## FloatingTextHelper

AnimatedPath-driven floating text manager for damage numbers, heal text, status effects. File: `src/bh/ui/FloatingTextHelper.hx`. Construct with `new FloatingTextHelper(?parent:h2d.Object)`.

| Method | Description |
|--------|-------------|
| `spawn(text, font, x, y, animPath, ?color, absolutePosition)` | Spawn text instance driven by an `AnimatedPath` |
| `spawnObject(obj, x, y, animPath, absolutePosition)` | Spawn arbitrary `h2d.Object` |
| `update(dt)` | Advance all active instances; auto-removes on completion |
| `clear()` | Remove all instances immediately |
| `count` | Active instance count |

**Position modes:**
- `absolutePosition = false` (default): AnimatedPath position is an offset from `(x, y)`. Use with `Anchor` normalization.
- `absolutePosition = true`: AnimatedPath position IS world coordinates. Use with `Stretch(startPoint, endPoint)` normalization.

**Applied state:** position, alpha, scale, rotation. Color applied to `h2d.Text` when a `colorCurve` is active on the path. `onComplete` callback on the path fires when done; completed instances auto-removed from manager and scene.

## Interaction Controllers

Modal interaction controllers for common targeting/selection flows. Extend `UIDefaultController` to inherit hover/cursor/outside-click while overriding specific interactions. Files in `src/bh/ui/controllers/`.

**Base — `UIInteractionController`:**
- `complete(result)` / `cancel()` — deferred to next `update()` frame
- `onActivate()` / `onDeactivate()` — lifecycle hooks
- Escape and right-click cancel built-in
- Static `start()` methods on each subclass push the controller and wire result → `popController()`

**`UISelectFromHandController`** — click cards to select/deselect.

| Config field | Description |
|--------------|-------------|
| `minCount` / `maxCount` | Selection bounds |
| `filter` | Per-card predicate (dims non-selectable) |
| `selectedParam` | Card param name to toggle (e.g. `"selected"`) |
| `selectedValue` / `deselectedValue` | Values to set on that param |
| `autoConfirm` | Auto-confirm when `maxCount` reached |

Suppresses drag during selection (`canDragCard = _ -> false`). Restores visual state + drag on deactivation. API: `confirm()`, `getSelectedCards()`, `getRemainingCount()`.

```haxe
UISelectFromHandController.start(this, cardHand, {maxCount: 2}, (result) -> {
    if (result != null) discardCards(result.cards);
});
```

**`UIPickTargetController`** — pick a target from interactives, grid cells, or cards.

| Config field | Description |
|--------------|-------------|
| `validTargetIds` / `targetPrefix` / `filter` | Interactive targets |
| `grid` / `cellFilter` | Grid cell targets (highlights valid cells) |
| `cardHand` / `cardFilter` | Card targets |

Intercepts `UIInteractiveEvent(UIClick, ...)` for interactives/cards and overrides `handleClick()` with `grid.cellAtPoint()` for grid cells. Routes mouse move to grid for hover feedback. Result: `PickTargetResult` enum — `TargetInteractive(id)`, `TargetCell(col, row)`, `TargetCard(cardId)`.

```haxe
UIPickTargetController.start(this, {grid: hexGrid, cellFilter: (c, r) -> hexGrid.isOccupied(c, r)}, (result) -> {
    if (result != null) switch result {
        case TargetCell(c, r): attack(c, r);
        default:
    }
});
```

**Composable:** controllers can chain — `start()` one controller in the callback of another.

**CardHandHelper additions for controllers:** `findCardIdByInteractiveId(id)`, `isCardInHand(cardId)`.
