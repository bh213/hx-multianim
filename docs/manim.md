# .manim Format Reference

MultiAnim is a library for creating partial UI and game elements from a custom language made specifically for pixel art UI. For example, a dropdown can use two different `programmable` objects, one to create an element with the current value and another one with an opened panel.

Programmables can accept parameters and these parameters can be used either in expressions passed to elements or to filter elements.

## Element Syntax

There are two ways you can declare elements: short form and long form.

**Short form:**
```
#name @optionalConditional shortcuts element(params): xy
```

**Long form:**
```
#name @optionalConditional shortcuts element(params) {
  pos: xy
  alpha: percentage
  layer: index
  filter: filter(params)
  scale: float
  hex: pointy|flat(dimensions)
  grid: sizex, sizey
  blendMode: blendMode

  #childName anotherElement(params):0,0;
  #childName anotherElement(params) {
     pos: xy
  }
}
```

Short form is for adding elements such as bitmaps and text without being too verbose. Long form supports adding children and inline properties.

### Shorthand Prefixes: alpha() and scale()

In short form, `alpha(value)` and `scale(value)` can be used as inline prefixes before an element, as an alternative to the long-form `alpha:` and `scale:` properties:

```
// Shorthand prefix form (short form only)
@alpha(0.5) bitmap(generated(color(1280, 720, blue)));
@scale(5) ninepatch("ui", "Window_3x3_idle", 60, 60): 40, 100

// Can be combined with conditionals
@(mode=>idle) alpha(0.1) ninepatch("ui", "Droppanel_3x3_idle", $width, $height): 0,0

// Supports expressions with parameter references
@alpha(1.0 - $index/5.0) scale(4) bitmap(sheet("crew2", "marine_r_shooting_d")):120,320
```

These are equivalent to setting `alpha:` and `scale:` in the long form:
```
// Long form equivalent
ninepatch("ui", "Window_3x3_idle", 60, 60) {
    pos: 40, 100
    scale: 5
}
```

The prefix form is more concise for single elements that don't need children or other long-form properties.

### Example
```
#panel programmable(width:uint=180, height:uint=30, mode:[idle,pressed]=pressed) {
     @(mode=>idle) alpha(0.1) ninepatch("ui", "Droppanel_3x3_idle", $width, $height): 0,0
     @(mode=>pressed) ninepatch("ui", "Droppanel_3x3_pressed", $width, $height): 0,0
}
```

In this example, a programmable in the long form with name `panel` is created. It accepts `width` and `height` parameters (both unsigned integers with defaults of `180` and `30`), plus a `mode` parameter which is an enum accepting either `idle` or `pressed` values.

`$width` and `$height` are expressions referencing input parameters. Expressions can include `+`, `-`, `*`, `/`, and `%`.

## Long Form Properties

* `pos` - same as `xy` in the short form
* `grid: sizex, sizey` - specifies grid coordinates for itself and its children
* `hex: pointy|flat(sizex, sizey)` - specifies hex coordinates for itself and its children
* `scale: value` - scale for this element and children
* `alpha: value` - alpha (opacity) of this element and children
* `blendMode: none|alpha|add|alphaAdd|softAdd|multiply|alphaMultiply|erase|screen|sub|max|min` - see [Heaps docs](https://heaps.io/api/h2d/BlendMode.html)
* `layer: index` - for immediate children of `layers` and `programmable`, z-order index
* `filter: <filter>` - applies filter to itself and children

---

## Nodes Reference

### bitmap
Displays an image file from filename or atlas sheet.

```
bitmap(tileSource, [center])
```

### stateanim
Creates a state animation from a `.anim` file.

```
stateanim("filename", "initialState", "direction"=>"l")
```

### stateanim construct
Creates a state animation inline without requiring a separate `.anim` file. Each state maps to a sheet animation with FPS and optional flags.

```
stateAnim construct("initialState",
  "state1" => sheet "sheetName", tileName, fps, loop
  "state2" => sheet "sheetName", tileName, fps
)
```

**Parameters per state:**
* `sheet "sheetName"` - atlas sheet to load tiles from (required)
* `tileName` - animation tile name in the atlas (required)
* `fps` - frames per second (required)
* `loop` - if present, animation loops forever; if omitted, plays once
* `center` - if present, tiles are centered

The first argument is the initial state to play on creation.

**Example:**
```
@scale(4) stateAnim construct("state2",
  "state1" => sheet "demo", indexed-tile, 10, loop
  "state2" => sheet "demo", tile-center, 10
): 200, 300
```

This creates a two-state animation: `state1` plays the `indexed-tile` animation from the `demo` atlas at 10 FPS looping, and `state2` plays `tile-center` at 10 FPS once. The animation starts in `state2`.

### flow
Creates an h2d.Flow layout container.

```
flow([optional params])
```

**Optional params:**
* `maxWidth:<int>`, `maxHeight:<int>`, `minWidth:<int>`, `minHeight:<int>`
* `lineHeight`, `colWidth`
* `layout`: `vertical` | `horizontal` | `stack`
* `paddingTop`, `paddingBottom`, `paddingLeft`, `paddingRight`, `padding`
* `debug`: `true` | `false`
* `horizontalSpacing:<int>`, `verticalSpacing:<int>`

### point
Creates a point (not displayed) for positioning items.

```
#test point: 200,450
```

### apply
Conditionally apply settings to a node:

```
ninepatch("cards", "card-base-patch9", 150,200) {
  @(state=>selected) apply {
    filter:glow(color:white, alpha:0.9, radius:15, smoothColor:true)
  }
}
```

Supports `filter`, `scale`, `alpha`, and `blendMode`.

### text
Creates text with font, content, and color.

```
text(fontname, text, textcolor[, align, maxWidth], options)
```

**Options:**
* `letterSpacing` - float
* `lineSpacing` - float
* `lineBreak` - bool
* `dropShadowXY` - float, float
* `dropShadowColor` - color
* `dropShadowAlpha` - float
* `html` - bool (use h2d.HtmlText)

**Example:**
```
@(status=>hover) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
```

### tilegroup
Optimized element for constructing objects with many elements (e.g., HP bars). Allows `bitmap`, `point`, `repeat`, and `pixels` children. Converted into a single drawable object.

```
#name programmable tileGroup(...)
```

### programmable
Core element of the library. Creates an instance of all children belonging to this programmable.

```
#list-panel programmable(width:uint=200, height:uint=200) {
  scale:1
  ninepatch("ui", "Window_3x3_idle", $width+4, $height+8): -2,-4
}
```

### repeatable
Repeats children with various iterators.

**Grid iterator:**
```
repeatable($varname, grid(repeatCount, dx, dy))
```

**Layout iterator:**
```
repeatable($varname, layout(layoutName))
```

**Array iterator:**
```
repeatable($varname, array(arrayName))
```

**Range iterator:**
```
repeatable($varname, range(start, end[, step]))
```

**Stateanim iterator:**
Iterates over all frames of an animation from a `.anim` file. Exposes `$bitmap` (the tile source) and `$index`.
```
repeatable($index, stateanim($bitmap, "filename.anim", "animationName", stateKey=>stateValue))
```

**Tiles iterator:**
Iterates over tiles from an atlas sheet. Has two variants:

1. **Full iteration** - all tiles in sheet, exposes `$bitmap`, `$tilename`, and `$index`:
```
repeatable($index, tiles($bitmap, $tilename, "sheetName"))
```

2. **Filtered by tile name** - only frames of a specific tile, exposes `$bitmap` and `$index`:
```
repeatable($index, tiles($bitmap, "sheetName", "exactTileName"))
```

**2D repeatable:**
```
repeatable2d($x, $y, <iteratorX>, <iteratorY>)
```

Note: `stateanim` and `tiles` iterators are not supported in `repeatable2d`.

**Examples:**
```
repeatable($i, range(0, 3)) {
  text(pikzel, 'Index: $i', #fff, left, 100): $i*20, 0
}

repeatable($i, grid(10, dx:10)) {
  pixels (rect 0,0, 5, 5, #fff);
}

repeatable2d($x, $y, grid(3, dx:10), grid(2, dy:20)) {
  bitmap("cell.png"): 0,0
}

// Iterate over animation frames from .anim file
repeatable($index, stateanim($bitmap, "marine.anim", "idle", direction=>r)) {
  bitmap($bitmap): $index * 70, 0
  text(dd, ""+$index, yellow, left, 50): $index * 70, 60
}

// Iterate over all tiles in an atlas sheet
repeatable($index, tiles($bitmap, $tilename, "crew2")) {
  bitmap($bitmap): ($index % 8) * 35, ($index div 8) * 20
}

// Iterate over frames of a specific tile in an atlas
repeatable($index, tiles($bitmap, "crew2", "Arrow_dir0")) {
  bitmap($bitmap): $index * 35, 0
}
```

### ninepatch
Draws 9-patch from atlas (requires `split` with 4 values in atlas).

```
ninepatch(sheet, tilename, width, height)
```

### layers
Enables children to use `layer` property for z-ordering.

```
layers() {
  @(cornerDirections=>2) layer(2) bitmap("png/Corner_090.png", center): 0,0
}
```

### placeholder
Uses callback to get object to insert.

```
placeholder(name, [onNoData], [source])
```

* `onNoData`: `error`, `nothing`, or tileSource
* Sources: `callback("name")`, `callback("name", $i)`, `builderParameter("name")`

### reference
References another programmable node.

```
reference($reference [, <params>])
reference(external(externalName), $reference, [,<params>])
```

### settings
Emits setting values to the build.

```
settings{key1=>value1, key2=>value2, ...}
```

---

## Coordinate Systems (xy)

* `x,y` - offset coordinates
* `hex(q, r, s)` - hex coordinates (requires hex system)
* `hexCorner(index, scale)` - position at hex corner
* `hexEdge(index, scale)` - position at hex edge
* `grid(x, y[, offsetX, offsetY])` - grid coordinates
* `;` - 0,0 offset
* `layout(layoutName [, index])` - coordinates from layout

---

## Filters

Filters can be applied to any visual element. Most parameters support expressions.

* `replacePalette(paletteName, sourceRow, replacementRow)`
* `replaceColor([sourceColors...], [replacementColors...])`
* `outline(size, color)`
* `saturate(value)` - 0.0=grayscale, 1.0=normal
* `brightness(value)` - 0.0=black, 1.0=normal
* `blur(radius, gain, [quality], [linear])`
* `pixelOutline(knockout, color, knockoutStrength)`
* `pixelOutline(inlineColor, outlineColor, inlineColor)`
* `dropShadow(distance, angle, color, alpha, radius, gain, quality)`
* `glow(color, alpha, [radius], [gain], [quality], [smoothColor], [knockout])`
* `group(filter1, filter2, ...)`

**Examples:**
```
filter: outline(2, red)
filter: pixelOutline(knockout, ?($owner == "Player") #0f0 : #f00, 0.9)
filter: group(outline(?($selected) 2 : 0, yellow), brightness(?($active) 1.2 : 0.8))
```

---

## Parameter Types

* `enum`: `name:[value1, value2]` or with default `status:[hover, pressed]=normal`
* `range`: `name:num..num`, e.g., `count:1..5 = 5`
* `int`: `count:int`, e.g., `delta:int = 0`
* `uint`: `count:uint`, e.g., `count:uint = 5`
* `flags`: `mask:flags(bits)`, e.g., `mask:flags(6)`
* `string`: `name="myname"` (always has default)
* `hexdirection`: `dir:hexdirection` (0..5)
* `griddirection`: `dir:griddirection` (0..7)
* `bool`: `true`/`false`, `yes`/`no`, or `0`/`1`
* `color`: `color:<color>`, e.g., `color:#f0f` or `red`

---

## Conditionals

Conditions are defined by `@(...)` and can be specified once per element.

* `@()` or `@if(...)` - match all provided
* `@(param != value)` - match when param is NOT value
* `@ifstrict(...)` - must match all provided parameters

**Comparison operators:**
* `@(key >= 30)` - greater than or equal
* `@(key <= 30)` - less than or equal
* `@(key > 30)` - strictly greater than
* `@(key < 30)` - strictly less than
* `@(key => 10..30)` - range match (10 <= key <= 30)

**Multi enum match:**
* `@(key => [value1, value2])`

**Wildcard match:**
* `@(key => *)` - matches any value of the parameter

The wildcard `*` is useful when a condition must constrain some parameters but accept any value for others. This commonly appears in disabled/fallback states:

```
#button programmable(status:[hover, pressed, normal], disabled:[true, false]) {
    @(status=>hover) ninepatch("ui", "button-hover", 200, 30)
    @(status=>*, disabled=>true) ninepatch("ui", "button-disabled", 200, 30)
}
```

In the example above, the disabled style applies regardless of the `status` value, as long as `disabled` is `true`.

### Conditional Chains: @else and @default

Elements can use `@else` and `@default` to form conditional chains, similar to if/else-if/else:

* `@else` - matches when the preceding sibling's `@()` condition did not match
* `@else(conditions)` - matches when the preceding sibling didn't match AND the given conditions match
* `@default` - matches when no preceding sibling in the chain matched (catch-all)

```
@(status=>hover) text(dd, "Hovered", white)
@else(status=>pressed) text(dd, "Pressed", yellow)
@default text(dd, "Normal", gray)
```

`@else` and `@default` must follow a sibling that has a `@()` conditional. They cannot be used on root elements.

---

## Expressions

**Operators:**
* `+` - addition
* `-` - subtraction
* `*` - multiplication
* `/` - division
* `%` - modulo (integer only)
* `div` - integer division

**Ternary Operator:**
```
?(condition) trueValue : falseValue
```

**Comparison Operators:** `==`, `!=`, `<`, `>`

**Examples:**
```
alpha: ?($enabled) 1.0 : 0.5
color: ?($owner == "Player") #00ff00 : #ff0000
width: ?($count > 5) $count * 20 : $count * 30
```

**Interpolated strings:**
```
'Nice to meet you ${$name}, have a nice day'
```

---

## Imports

```
import "screens/helpers.manim" as "helpers"
```

External name can be used to reference programmables from external multianim.

---

## Layouts

Layouts are root-level elements for positioning elements on screen.

```
relativeLayouts {
  #endpoint point: 600,10

  #endpoints list {
    point: 250,20
    point: 450,20
  }

  #seq sequence($i: 1..4) point: grid(10*$i,10)
}
```

**Layout nodes:**
* `grid: x,y {...}` - sets grid mode
* `offset: x,y {...}` - sets offset for all layouts
* `hex:pointy(30,20) {...}` - sets hex coordinate system

---

## Palettes

Collections of colors accessed by index.

**Normal palette:**
```
#main palette {
  white 0xf12 0x332 0xfff
}
```

**2D palette:**
```
#main palette(2d, 4) {
  white 0xf12 0x332 0xfff
  red 0xf13 0x333 0xffa
}
```

**File palette:**
```
#file palette(file:"main-palette.png")
```

---

## Autotile

Root-level element for procedural terrain/tileset generation. Autotiles automatically select the correct tile variant based on neighboring tiles.

### Basic Syntax

```
#name autotile {
    format: cross | blob47
    tileSize: <int>
    <source>
    [optional properties]
}
```

### Formats

| Format | Tiles | Description |
|--------|-------|-------------|
| `cross` | 13 | Cardinal directions + corners (N, E, S, W, C, outer corners, inner corners) |
| `blob47` | 47 | Full 8-directional coverage with all edge/corner combinations |

### Source Types

One source type is required:

**Atlas with prefix:**
```
sheet: "sheetName", prefix: "tile_"
```
Loads tiles named `tile_0`, `tile_1`, etc. from atlas.

**Atlas with region:**
```
sheet: "sheetName", region: [x, y, width, height]
```
Extracts tiles from a rectangular region of the atlas. **Requires `mapping:`** since region tiles are rarely in autotile index order.

**Image file:**
```
file: "filename.png"
```
Loads tiles from an image file. Use with `region:` to specify tile area. **Requires `mapping:`** when using a region.

**Explicit tiles:**
```
tiles: sheet("atlas", "tile1") sheet("atlas", "tile2") generated(color(16,16,red)) ...
```
List of explicit tile sources for full control.

**Demo (auto-generated):**
```
demo: edgeColor, fillColor
```
Generates placeholder tiles for prototyping. Shows edge/fill colors to visualize tile variants.

### Optional Properties

| Property | Description |
|----------|-------------|
| `region: [x, y, w, h]` | For file source: extract tiles from this region only |
| `depth: <int>` | Isometric elevation depth |
| `mapping: [...]` | Remap tile indices (see below) |
| `allowPartialMapping: true` | For blob47: missing tiles use fallback instead of error |

### Mapping

Maps autotile indices to tileset indices. **Required for region-based sources** because tileset artists rarely arrange tiles in autotile index order.

Autotile indices encode which neighbors are present:
- **cross format**: 0-12, encoding cardinal directions and corners
- **blob47 format**: 0-46, encoding all 8-directional neighbor combinations

Two mapping formats:

**Sequential:** Position in array = autotile index, value = tileset index
```
mapping: [4, 7, 3, 6]  // autotile 0->4, 1->7, 2->3, 3->6
```

**Explicit:** `autotileIndex:tilesetIndex` pairs (recommended for partial mapping)
```
mapping: [0:4, 1:7, 5:1, 13:5]
```

### Partial Mapping (blob47)

Full blob47 coverage requires 47 distinct tiles, but many tilesets only provide a subset (typically 13-20 tiles for basic terrain). Use `allowPartialMapping: true` to enable automatic fallback:

```
allowPartialMapping: true
mapping: [
    0:4,    // isolated tile
    1:7,    // N neighbor only
    // ... only map tiles that exist in your tileset
]
```

**Fallback behavior:** When a blob47 index isn't mapped, the system finds a simpler tile that still looks correct:
- Unmapped corner combinations fall back to edge-only tiles
- Complex patterns fall back to simpler patterns with the same cardinal edges
- This allows a 15-tile tileset to work with the full 47-tile system

See [test/examples/32-blob47Fallback/](../test/examples/32-blob47Fallback/) for a working example with the Forgotten Plains tileset.

### Examples

**Demo autotile for prototyping:**
```
#terrainDemo autotile {
    format: blob47
    tileSize: 16
    demo: 0x66AA44, 0x886644    // green edges, brown fill
}
```
See [test/examples/31-autotile/](../test/examples/31-autotile/) for cross and blob47 demo examples.

**Tileset with region and partial mapping:**
```
#grassTerrain autotile {
    format: blob47
    tileSize: 8
    file: "tileset.png"
    region: [56, 24, 24, 40]
    allowPartialMapping: true
    mapping: [
        0:4,    // isolated tile
        1:7,    // N neighbor
        5:1,    // S neighbor
        13:5,   // W neighbor
        21:4    // all neighbors (center)
        // unmapped tiles use fallback
    ]
}
```
See [test/examples/32-blob47Fallback/](../test/examples/32-blob47Fallback/) for a complete partial mapping example.

### Using Autotile Tiles

Reference autotile tiles in `generated()` expressions:

```
// By index (0-12 for cross, 0-46 for blob47)
bitmap(generated(autotile("terrainDemo", 0)))

// By edge flags (N, E, S, W, NE, SE, SW, NW)
bitmap(generated(autotile("terrainDemo", N|E|S|W)))
```

### Debugging with Region Sheet

Visualize the tileset region with numbered grid:

```
bitmap(generated(autotileRegionSheet("grassTerrain", 4, "f3x5", white)))
```

---

## Paths

Paths define animated paths for objects to follow.

```
paths {
  #pathName path {
    line(absolute, 100, 50)
    bezier(relative, 100, 50, 75, 25, smoothing: auto)
    arc(100, 70)
    forward(100)
    checkpoint(test)
  }
}
```

**Path Commands:**
* `line(coordinateMode, x, y)` - Draw a line
* `bezier(coordinateMode, x1, y1, x2, y2[, x3, y3])` - Bezier curve
* `forward(distance)` - Move forward
* `turn(degrees)` - Turn by degrees
* `arc(radius, angleDelta)` - Draw an arc
* `checkpoint(name)` - Define checkpoint

**Smoothing Options:** `auto`, `none`, or custom distance

---

## Pixels

Draws pixel-perfect primitives.

```
pixels (
    pixel 5,5, #f00
    line 0,0, 10,10, #fff
    rect 2,2, 8,8, #0ff
    filledRect 3,3, 6,6, #ff0
) {
    scale: 8
    pos: 200, 80
}
```

---

## Graphics

Creates vector graphics using Heaps h2d.Graphics.

```
graphics (
    rect(#ff0000, filled, 100, 50);
    circle(#00ff00, 2, 30):120,25
    ellipse(#0000ff, filled, 80, 40):200,25
    arc(#ffff00, 1.5, 40, 0, 180):300,50
    line(#ff00ff, 2, 0, 0, 100, 50):400,50
    roundrect(#ff8800, filled, 80, 50, 10):50,120
    polygon(#8800ff, filled, 0,0, 40,0, 40,40, 0,40):150,120
)
```

**Elements:**
* `rect(color, style, width, height)`
* `circle(color, style, radius)`
* `ellipse(color, style, width, height)`
* `arc(color, style, radius, startAngle, arcAngle)`
* `line(color, lineWidth, x1, y1, x2, y2)`
* `roundrect(color, style, width, height, radius)`
* `polygon(color, style, x1, y1, x2, y2, ...)`

**Style:** `filled` or line width number

---

## Particles

Particle systems for visual effects like fire, smoke, explosions, and magic effects.

### Basic Syntax

```
#effectName particles {
    count: 100
    emit: point(0, 0)
    tiles: file("particle.png")
    loop: true
    maxLife: 2.0
    speed: 50
}
```

### Required Properties

| Property | Description |
|----------|-------------|
| `emit` | Emission mode (see Emission Modes below) |
| `tiles` | Particle tile source(s) |

### Core Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `count` | int | 100 | Maximum particles alive at once |
| `loop` | bool | true | Continuously emit particles |
| `maxLife` | float | 1.0 | Particle lifetime in seconds |
| `lifeRandom` | float | 0 | Random lifetime variation (0-1) |

### Movement Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `speed` | float | 50 | Initial particle velocity |
| `speedRandom` | float | 0 | Random speed variation (0-1) |
| `speedIncrease` | float | 0 | Speed change over time (-1 to 1) |
| `gravity` | float | 0 | Gravity strength |
| `gravityAngle` | float | 90 | Gravity direction in degrees (90 = down) |

### Size Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `size` | float | 1.0 | Initial particle scale |
| `sizeRandom` | float | 0 | Random size variation (0-1) |

### Rotation Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `rotationInitial` | float | 0 | Initial rotation range in degrees |
| `rotationSpeed` | float | 0 | Rotation speed in degrees/sec |
| `rotationSpeedRandom` | float | 0 | Random rotation speed variation |
| `rotateAuto` | bool | false | Auto-rotate to match velocity direction |

### Fade Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `fadeIn` | float | 0.2 | Fade-in time (0-1 normalized) |
| `fadeOut` | float | 0.8 | Fade-out start time (0-1 normalized) |
| `fadePower` | float | 1.0 | Fade curve exponent |

### Emission Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `emitSync` | float | 0 | Synchronization (0=spread, 1=burst) |
| `emitDelay` | float | 0 | Fixed delay before emission |

### Rendering Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blendMode` | enum | alpha | `alpha`, `add`, `multiply`, etc. |
| `animationRepeat` | float | 1 | Animation loops (0=random frame) |

### Emission Modes

```
emit: point(distance, distanceRandom)
emit: cone(distance, distanceRandom, angle, angleRandom)
emit: box(width, height, angle, angleRandom)
emit: circle(radius, radiusRandom, angle, angleRandom)
```

**Angles are in degrees.** -90 = up, 0 = right, 90 = down, 180 = left.

**Examples:**
```
// Point emission in all directions
emit: point(0, 20)

// Cone upward with 30° spread
emit: cone(0, 10, -90, 30)

// Box area with downward emission
emit: box(200, 10, 90, 10)

// Circle edge with outward emission (angle 0,0 = radial)
emit: circle(50, 10, 0, 0)
```

### Color Interpolation

Particles can transition through colors over their lifetime.

| Property | Type | Description |
|----------|------|-------------|
| `colorStart` | color | Color at birth |
| `colorEnd` | color | Color at death |
| `colorMid` | color | Optional middle color |
| `colorMidPos` | float | Position of middle color (0-1) |

**Example:**
```
// Fire gradient: orange -> yellow -> white
colorStart: #FF4400
colorMid: #FFAA00
colorMidPos: 0.4
colorEnd: #FFFF88
```

### Force Fields

Apply physics forces to particles. Multiple force fields can be combined.

```
forceFields: [force1, force2, ...]
```

**Force Types:**

| Force | Syntax | Description |
|-------|--------|-------------|
| Attractor | `attractor(x, y, strength, radius)` | Pulls particles toward point |
| Repulsor | `repulsor(x, y, strength, radius)` | Pushes particles from point |
| Vortex | `vortex(x, y, strength, radius)` | Spins particles around point |
| Wind | `wind(vx, vy)` | Constant directional force |
| Turbulence | `turbulence(strength, scale, speed)` | Noise-based displacement |

**Examples:**
```
// Swirling vortex with center attractor
forceFields: [vortex(0, 0, 200, 200), attractor(0, 0, 50, 180)]

// Rising smoke with wind and turbulence
forceFields: [turbulence(20, 0.015, 1.0), wind(15, 0)]

// Plasma with repulsor
forceFields: [repulsor(0, 0, 100, 120), turbulence(15, 0.02, 2.0)]
```

### Curves

Define how values change over particle lifetime using curve points `(time, value)`.

| Property | Description |
|----------|-------------|
| `sizeCurve` | Size multiplier over lifetime |
| `velocityCurve` | Velocity multiplier over lifetime |

**Syntax:**
```
sizeCurve: [(time1, value1), (time2, value2), ...]
velocityCurve: [(time1, value1), (time2, value2), ...]
```

Time is normalized (0.0 = birth, 1.0 = death). Values are multipliers.

**Examples:**
```
// Grow then shrink
sizeCurve: [(0, 0.5), (0.3, 1.2), (1.0, 0.2)]

// Slow down over time
velocityCurve: [(0, 1.0), (0.2, 0.5), (1.0, 0.1)]

// Pulsing size
sizeCurve: [(0, 0.5), (0.25, 1.2), (0.5, 0.8), (0.75, 1.1), (1.0, 0.3)]
```

### Bounds Modes

Control particle behavior at boundaries.

| Property | Type | Description |
|----------|------|-------------|
| `boundsMode` | enum | `kill`, `bounce(damping)`, `wrap` |
| `boundsMinX` | float | Left boundary |
| `boundsMaxX` | float | Right boundary |
| `boundsMinY` | float | Top boundary |
| `boundsMaxY` | float | Bottom boundary |

**Examples:**
```
// Kill particles at bounds
boundsMode: kill
boundsMinX: -100
boundsMaxX: 300
boundsMinY: -50
boundsMaxY: 250

// Bounce with energy loss
boundsMode: bounce(0.6)

// Wrap around (for rain, etc.)
boundsMode: wrap
```

### Multiple Tiles

Use multiple tile sources for variety. Particles randomly select from available tiles.

```
tiles: file("spark.png") file("flare.png")
tiles: file("star.png") file("dot.png") file("ring.png")
```

**Note:** Tile images should be similar in size for consistent appearance.

### Complete Examples

**Fire Effect:**
```
#fire particles {
    count: 100
    emit: cone(0, 10, -90, 30)
    maxLife: 2.0
    lifeRandom: 0.3
    speed: 80
    speedRandom: 0.3
    tiles: file("circle_soft.png")
    loop: true
    size: 0.8
    sizeRandom: 0.4
    emitSync: 0.2
    blendMode: add
    fadeIn: 0.1
    fadeOut: 0.6
    fadePower: 1.5
    colorStart: #FF4400
    colorMid: #FFAA00
    colorMidPos: 0.4
    colorEnd: #FFFF88
    sizeCurve: [(0, 0.5), (0.3, 1.2), (1.0, 0.2)]
    forceFields: [turbulence(30, 0.02, 2.0)]
}
```

**Rain Effect:**
```
#rain particles {
    count: 200
    emit: box(500, 10, 100, 5)
    maxLife: 1.5
    lifeRandom: 0.2
    speed: 400
    speedRandom: 0.15
    tiles: file("spark.png")
    loop: true
    size: 0.2
    blendMode: alpha
    fadeIn: 0.1
    fadeOut: 0.9
    colorStart: #AACCFF
    colorEnd: #6688CC
    gravity: 100
    gravityAngle: 90
    boundsMode: wrap
    boundsMinX: -50
    boundsMaxX: 450
    boundsMinY: -20
    boundsMaxY: 350
    rotateAuto: true
}
```

### Using Particles in Haxe

```haxe
// Load and create particles
var builder = MultiAnimBuilder.load(fileContent, loader, "effects.manim");
var particles = builder.createParticles("fire");
scene.addChild(particles);

// Use with updatable placeholder
var ui = MacroUtils.macroBuildWithParameters(builder, "ui", [], []);
var updatable = ui.builderResults.getUpdatable("particlesSlot");
updatable.setObject(particles);
```

---

## Tile Sources

* `sheet(sheet, name)` - from atlas sheet
* `sheet(sheet, name, index)` - from atlas sheet with specific frame index (for multi-frame tiles)
* `file(filename)` - from file
* `$varname` - reference to a tile source variable (e.g., `$bitmap` from stateanim/tiles iterators)
* `generated(cross(width, height[, color]))` - generated cross
* `generated(color(width, height, color))` - solid color
* `generated(colorWithText(width, height, color, text, textColor, font))` - solid color with text
* `generated(autotile("name", selector))` - demo tile from autotile definition
  - By index: `autotile("grassTerrain", 0)` - select tile by index (0-12 for cross, 0-46 for blob47)
  - By edges: `autotile("grassTerrain", N+E+S+W)` - select tile by neighbor flags
  - Edge flags: `N`, `E`, `S`, `W` (cardinals), `NE`, `SE`, `SW`, `NW` (corners)
  - Requires autotile with `demo: edgeColor, fillColor` defined
* `generated(autotileRegionSheet("name", scale, "font", fontColor))` - visualization of autotile region with numbered grid
  - Displays the complete region of an autotile with tile indices overlaid
  - Useful for debugging and identifying which tile index corresponds to which visual
  - `scale` - scale factor for tiles (font remains at original size for readability)
  - Requires autotile with `region` defined (file source or atlas region)

---

## Updatable Elements

Mark elements as `(updatable)` to enable updating from code:

```
#selectedName(updatable) text(pikzel, callback("selectedName"), 0xffffff12, center, 120): -4,6
#bitmapToUpdate(updatable) bitmap(generated(color(20, 20, red)), left, top):10,80
```

---

## Fonts

Supported fonts: `f3x5`, `m3x6`, `pixeled6`, `pikzel`, `cnc_inet_12`, `m5x7`, `f7x5`, `f5x5`, `default_heaps`, `m6x11`, `dd_thin`, `dd`, `pixellari`, `dhkp`, `hh`

---

## Debug Tracing

Enable debug traces by adding to your HXML file:

```hxml
-D MULTIANIM_TRACE
```

---

## Components

### ScrollList

Settings:
* `panelBuilder` - builder for the panel
* `itemBuilder` - builder for the items
* `scrollbarBuilder` - builder for the scrollbar
* `width` - width of the scroll list
* `height` - height of the scroll list
* `topClearance` - clearance from the top of the screen
* `scrollSpeed` - up/down scroll speed in pixels per second

### Dropdown

Settings:
* `transitionTimer` - time to transition between open & closed

---

## Macro-Based UI Construction

The library uses macros to map `.manim` file elements to Haxe code. Builder parameters in `.manim` files (using `builderParameter("name")`) are mapped to named arguments in the macro build:

**.manim file:**
```
#ui programmable() {
  placeholder(generated(cross(200, 20)), builderParameter("button")) {
      settings{buildName=>button_custom}
  }
}
```

**Haxe code:**
```haxe
var ui = MacroUtils.macroBuildWithParameters(buttonBuilder, "ui", [], [
    button=>addButton(buttonBuilder, "Click Me!"),
]);
```
