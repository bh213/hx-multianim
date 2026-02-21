# .manim Language Reference

Quick-lookup reference of all elements, properties, and operations in the `.manim` language.

---

## File Structure

| Construct | Description |
|-----------|-------------|
| `version: 0.5` | Required file header declaring format version |
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
| `text(font, text, color, align, maxWidth, options)` | Render text with font, color, and formatting options |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable image for resizable panels |
| `pixels(...)` | Pixel-level drawing primitives |
| `graphics(...)` | Vector graphics shapes |
| `stateanim("file", state, selector)` | State machine animation from .anim file |
| `stateanim construct(initial, states)` | Inline state machine animation definition |
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
| `staticRef($ref, params)` | Static embed of another programmable (alias: `reference`) |
| `dynamicRef($ref, params)` | Dynamic embed with runtime `setParameter()` support (alias: `component`) |
| `#name slot` | Swappable content container |
| `#name[$i] slot` | Indexed slot inside repeatable |
| `#name slot(params)` | Parameterized slot with visual states and conditionals |
| `slotContent` | Content insertion point inside parameterized slot body |
| `interactive(w, h, id, debug, metadata)` | Hit-test region with optional typed key-value metadata |
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
| `layout("blockName", "entryName")` | Position from named relative layout (blockName is label only, entryName is the `#name` used in layout) |
| `array(arrayName)` | Iterate over data array |
| `range(start, end, step)` | Numeric range with optional step |
| `stateanim(file, anim, selector)` | Iterate animation frames; exposes `$bitmap`, `$tilename` |
| `tiles(sheet, prefix)` | Iterate all tiles from sheet; exposes `$bitmap`, `$tilename` |

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

---

## Text Options

| Option | Description |
|--------|-------------|
| `letterSpacing` | Space between characters |
| `lineSpacing` | Space between lines |
| `lineBreak` | Enable word wrapping |
| `html` | Parse HTML tags in text |
| `dropShadowXY` | Shadow offset (x, y) |
| `dropShadowColor` | Shadow color |
| `dropShadowAlpha` | Shadow opacity |
| `maxWidth` | Maximum text width (triggers wrapping) |
| `maxHeight` | Maximum text height |
| `minWidth` | Minimum text width |
| `minHeight` | Minimum text height |
| `lineHeight` | Fixed line height override |
| `colWidth` | Column width for layout |

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
| `debug` | Show debug layout borders |

---

## Conditionals

| Syntax | Description |
|--------|-------------|
| `@(param=>value)` | Match when parameter equals value |
| `@if(param=>value)` | Explicit if (same as `@()`) |
| `@ifstrict(param=>value)` | Strict match — ALL parameters in condition must match |
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

Additional condition keywords: `greaterthanorequal`, `lessthanorequal`, `bit`, `between`.

---

## Parameter Types

| Type | Description |
|------|-------------|
| `int` | Signed integer |
| `uint` | Unsigned integer (0+) |
| `float` | Floating point number |
| `bool` | Boolean (`true`/`false`/`yes`/`no`/`1`/`0`) |
| `string` | Text string (quoted) |
| `color` | Color value — hex `#RRGGBB` or named color |
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
| `$grid.pos(x, y)` | Position at grid cell |
| `$grid.pos(x, y, offX, offY)` | Grid cell with pixel offset |
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
| `$hex.width`, `$hex.height` | Cell dimensions |

### Layout Positioning
`layout(layoutName)` or `layout(layoutName, $index)` — position from named layout definition.

### Offset Suffix
`.offset(x, y)` suffix on any coordinate expression adds a pixel offset to the result.
Works with all coordinate types: `layout(name).offset(5, 10)`, `$grid.pos(1, 2).offset(3, 4)`, `$hex.cube(q, r, s).offset(5, 5)`.

### Value Extraction
`.x` or `.y` suffix on any coordinate method extracts a single component for use in expressions.

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
| `hex: orientation(w, h)` | Hex coordinate system for children |
| `scale: value` | Scale factor |
| `alpha: value` | Opacity (0.0-1.0) |
| `tint: color` | Color tint overlay |
| `layer: index` | Z-order index within layers/programmable |
| `filter: filterType(...)` | Visual filter |
| `blendMode: mode` | Blend mode |

### Inline Property Prefixes (before element at `@`)
`@layer(index)`, `@alpha(value)`, `@scale(value)`, `@tint(color)`

---

## Named Elements

| Syntax | Description |
|--------|-------------|
| `#name element(...)` | Named element — accessible from builder/codegen |
| `#name[$i] element(...)` | Indexed named element inside repeatable — creates `name_0`, `name_1`, etc. |
| `#name(updatable) element(...)` | Explicitly marked updatable for runtime property changes |

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

---

## Blend Modes

`none`, `alpha`, `add`, `alphaAdd`, `softAdd`, `multiply`, `alphaMultiply`, `erase`, `screen`, `sub`, `max`, `min`

---

## Named Colors

`white`, `silver`, `gray`, `black`, `maroon`, `red`, `orange`, `yellow`, `olive`, `green`, `lime`, `purple`, `fuchsia`, `teal`, `cyan`, `aqua`, `blue`, `navy`

Also hex: `#RRGGBB` or `#RRGGBBAA`.

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
| `record RecordName { field: type, ... }` | Define record schema |
| `fieldName: RecordName { ... }` | Record instance |
| `fieldName: type[] [values]` | Typed array |
| Optional fields with `?` prefix | Field not required |

Types: `int`, `float`, `string`, `bool`, record names, `Type[]` arrays.

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
| Point-based | Key-value pairs: `0.0: 100`, `0.5: 50`, `1.0: 100` |
| Segment-based | `0.0->0.5: easing from startVal to endVal` |
| `cubicBezier(x1, y1, x2, y2)` | Custom cubic bezier curve |

### Easing Names
`linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeOutBounce`, `easeOutElastic`

---

## Particles

### Emission Modes

| Mode | Description |
|------|-------------|
| `point(distance, distRand)` | Emit from a point with optional spread |
| `cone(dist, distRand, angle, angleRand)` | Directional cone emission |
| `box(w, h, angle, angleRand)` | Rectangular area emission |
| `circle(radius, radiusRand, angle, angleRand)` | Circular area emission |
| `path(pathName, tangent)` | Emit along a path, optionally tangent-aligned |

### Core Properties

| Property | Description |
|----------|-------------|
| `count` | Maximum alive particles |
| `loop` | Continuous emission |
| `maxLife` | Particle lifetime in seconds |
| `lifeRandom` | Lifetime variance (0-1) |
| `relative` | Particles move with emitter |

### Movement

| Property | Description |
|----------|-------------|
| `speed` | Initial velocity |
| `speedRandom` | Speed variance |
| `speedIncrease` | Acceleration |
| `gravity` | Gravity strength |
| `gravityAngle` | Gravity direction (degrees) |

### Size & Rotation

| Property | Description |
|----------|-------------|
| `size`, `sizeRandom` | Particle size and variance |
| `rotationInitial` | Starting rotation |
| `rotationSpeed`, `rotationSpeedRandom` | Spin rate and variance |
| `rotateAuto` | Auto-rotate to face velocity direction |
| `forwardAngle` | Sprite forward direction offset |

### Fading

| Property | Description |
|----------|-------------|
| `fadeIn` | Fade-in point (0-1 of lifetime) |
| `fadeOut` | Fade-out start (0-1 of lifetime) |
| `fadePower` | Fade curve exponent |

### Rendering

| Property | Description |
|----------|-------------|
| `blendMode` | Blend mode for particles |
| `tiles` | Tile sources (file, sheet, generated) |
| `animFile` | State animation file for animated particles |
| `animSelector` | State selection for animated particles |

### Lifetime Curves

| Property | Description |
|----------|-------------|
| `sizeCurve` | Size over lifetime (named curve or inline easing) |
| `velocityCurve` | Speed over lifetime |
| `colorCurve` | Color gradient segments: `rate: colorCurve: easing, #start, #end` |
| `spawnCurve` | Emission rate modulation |

### Lifetime Animation Events
`rate: anim("name")` — trigger animation at lifetime rate.
`onBounce: anim("name")` — trigger on boundary collision.

### Bounds

| Property | Description |
|----------|-------------|
| `boundsMode` | `none`, `kill`, `bounce(damping)`, `wrap` |
| `boundsMinX/MaxX/MinY/MaxY` | Rectangular boundary |
| `boundsLine` | Line boundary: `x1, y1, x2, y2` |

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
| `inheritVelocity` | Velocity inheritance factor |
| `offsetX`, `offsetY` | Spawn offset |

### Path Integration
`attachTo: pathName` — emitter follows animated path.

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
    repeatable($i, layout("layouts", "slots")) {            // layout iterator
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
| **Scrollable list** | Scrollable list of selectable items with scrollbar |
| **Progress bar** | Display-only value indicator (0-100) |
| **Interactive** | Hit-test region with ID and optional typed metadata |
| **Draggable** | Drag-and-drop with drop zones, slot integration, swap mode |

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
| `prefix.setting` | Route setting to sub-builder (`item.font`, `scrollbar.thickness`) |

---

## Incremental Update Mode

When enabled, elements support efficient runtime updates without full rebuild:
- All conditional branches built simultaneously (non-matching set invisible)
- Expression-dependent properties tracked for targeted updates
- `setParameter()` re-evaluates only affected properties
- `beginUpdate()` / `endUpdate()` for batched parameter changes

Used by: dynamic refs, slider, scrollbar, parameterized slots.

---

## Macro Code Generation

| Macro | Description |
|-------|-------------|
| `@:manim("file", "name")` | Generate typed factory and instance classes from programmable |
| `@:data("file", "name", "pkg")` | Generate typed record classes from data block |
| `@:build(ProgrammableCodeGen.buildAll())` | Trigger code generation on class |

Generated factories provide type-safe `create()`, `createFrom()`, parameter setters, and element accessors.
