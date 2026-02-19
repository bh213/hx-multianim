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

**Note:** Property and keyword names are case-insensitive (`maxLife`, `maxlife`, and `MAXLIFE` are all equivalent). Some element names accept multiple spellings (e.g., `animatedPath`, `animated_path`, `animatedpath`).

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
* `multiline`: `true` | `false` — enables multi-line content wrapping
* `horizontalSpacing:<int>`, `verticalSpacing:<int>`
* `background: ninepatch(sheet, tile)` — adds a 9-patch background to the flow
* `overflow`: `expand` | `limit` | `scroll` | `hidden` — controls child overflow behavior (default: `limit`)
* `fillWidth`: `true` | `false` — children fill available width
* `fillHeight`: `true` | `false` — children fill available height
* `reverse`: `true` | `false` — reverses child rendering order

### spacer
Inserts empty space inside a `flow` container. Only valid as a child of `flow`.

```
spacer(width, height)
```

* `width`, `height` — fixed dimensions of the spacer (integer or `$reference`)

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

**Step iterator:**
```
repeatable($varname, step(repeatCount, dx, dy))
```
Note: `grid` is accepted as a deprecated alias for `step`.

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

repeatable($i, step(10, dx:10)) {
  pixels (rect 0,0, 5, 5, #fff);
}

repeatable2d($x, $y, step(3, dx:10), step(2, dy:20)) {
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

### Indexed Named Elements

Inside `repeatable`, element names can include the loop variable to create per-iteration named references:

```
repeatable($i, step(4, dx: 40)) {
    #label[$i] text(f3x5, $i, #ffffffff): 14, 0
    #icon[$i] bitmap(generated(color(32, 32, #885522))): 0, 10
}
```

This creates `label_0`, `label_1`, `label_2`, `label_3` and matching `icon_0`..`icon_3`.

**Builder access:**
```haxe
result.getUpdatableByIndex("label", 0).updateText("Fireball");
result.getUpdatableByIndex("icon", 2).updateTile(someTile);
```

**Codegen access:**
```haxe
instance.get_label(0);  // h2d.Object (cast to h2d.Text)
instance.get_icon(2);   // h2d.Object (cast to h2d.Bitmap)
```

### slot
Defines a swappable container whose content can be replaced at runtime. Children are default content shown when no replacement is set. Requires a `#name` prefix.

```
#footer slot {
    // default content
    text(f3x5, "default", #ffffffff): 0, 50
}
```

**Indexed slots** inside `repeatable` use the `#name[$i]` syntax:

```
repeatable($i, step(3, dx: 70)) {
    #icon[$i] slot {
        bitmap(generated(color(20, 20, #555555))): 20, 10
    }
}
```

This creates slots `icon_0`, `icon_1`, `icon_2`.

**Builder access:**
```haxe
// Non-indexed slot
result.getSlot("footer").setContent(myWidget);
result.getSlot("footer").clear();  // restores default content

// Indexed slot — index is required
result.getSlot("icon", 0).setContent(itemIcon);
result.getSlot("icon", 2).clear();

// Mismatches throw errors:
result.getSlot("icon");        // Error: indexed slot requires index
result.getSlot("footer", 0);  // Error: non-indexed slot rejects index
```

**Codegen access:**
```haxe
// Named accessors
instance.getSlot_icon(0).setContent(itemIcon);
instance.getSlot_footer().clear();

// Generic accessor (same validation as builder)
instance.getSlot("icon", 0);
instance.getSlot("footer");
```

**SlotHandle API:**
* `setContent(obj:h2d.Object)` — hides defaults, adds replacement
* `clear()` — removes replacement, restores defaults
* `getContent():Null<h2d.Object>` — returns current replacement or null
* `container:h2d.Object` — the underlying container object

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

### mask
Clips all child content to a rectangular region. Wraps `h2d.Mask`.

```
mask(width, height) {
  bitmap(...): x, y
}
```

* `width`, `height` — size of the clipping rectangle (integer or `$reference`)
* Children positioned outside the mask bounds are clipped
* Supports `pos`, `scale`, `alpha` properties

### placeholder
Uses callback to get object to insert.

```
placeholder(name, [onNoData], [source])
```

* `onNoData`: `error`, `nothing`, or tileSource
* Sources: `callback("name")`, `callback("name", $i)`, `builderParameter("name")`

### staticRef
Embeds another programmable with parameters. The result is built **once** and is static — parameters cannot be changed after building.

```
staticRef($reference [, <params>])
staticRef(external(externalName), $reference [, <params>])
```

Use for reusable visual templates that don't need runtime updates.

### dynamicRef
Embeds another programmable with **incremental mode** enabled, allowing parameters to be updated at runtime via `setParameter()`. Conditionals and expressions are re-evaluated when parameters change.

```
dynamicRef($reference [, <params>])
dynamicRef(external(externalName), $reference [, <params>])
```

The dynamic ref's `BuilderResult` is stored and accessible via `result.getDynamicRef("name")`:

```haxe
var result = builder.buildWithParameters("myScreen", []);
var hpBar = result.getDynamicRef("statusBar");
hpBar.setParameter("value", 25);   // updates visuals
```

Use for elements that need dynamic parameter changes after building (health bars, status displays, etc.).

**staticRef vs dynamicRef:**

| | `staticRef` | `dynamicRef` |
|---|---|---|
| Mutable at runtime | No | Yes (`setParameter()`) |
| Stored in BuilderResult | No | Yes (`getDynamicRef()`) |
| Overhead | Minimal | Higher (tracks changes) |

### Builder Incremental Update

Dynamic refs use **incremental mode** internally. You can also enable it directly via `buildWithParameters()`:

```haxe
var result = builder.buildWithParameters("statusBar", params, builderParams, indexedParams, true);
```

The last `true` parameter enables incremental mode. When enabled:
- All conditional branches are built (not just matching ones), with non-matching elements set to `invisible`
- Expression-dependent properties (text, color, size, position, alpha, tint, filters) are tracked
- Calling `setParameter()` re-evaluates conditionals and expressions without rebuilding the tree

**API:**
```haxe
// Single parameter update (applies immediately)
result.setParameter("value", 75);
result.setParameter("label", "ATK");

// Batch update (defers re-evaluation until endUpdate)
result.beginUpdate();
result.setParameter("value", 30);
result.setParameter("label", "MP");
result.endUpdate();  // applies all changes at once

// Access sub-dynamic refs
result.getDynamicRef("statusBar").setParameter("value", 25);
```

Calling `setParameter()` without incremental mode throws an error.

### interactive
Creates a hit-test region for UI interaction. Optionally carries an identifier and typed metadata.

```
interactive(width, height, id)
interactive(width, height, id, debug)
interactive(width, height, id, key => value, key2 => value2)
interactive(width, height, id, debug, key => value)
```

**Parameters:**
* `width`, `height` — size of the hit-test region (integer or `$reference`)
* `id` — string identifier (string or `$reference`)
* `debug` — optional flag to render a visible orange overlay with label (requires registered font)
* `key => value` — optional metadata pairs (string values by default)

**Typed metadata:**
Metadata values can be typed to match the settings system:
```
interactive(200, 30, "buyBtn", action => "buy", price:int => 100, weight:float => 1.5)
interactive(120, 40, $idx, type:string => "slot", slot:int => $i)
```

Supported types: `int`, `float`, `string` (default when no type specified). Keys and values can be `$references`.

**UI integration:**
* `UIInteractiveWrapper` wraps the interactive as a `UIElement` with `UIElementIdentifiable`
* Screen methods: `addInteractive(obj, prefix)`, `addInteractives(result, prefix)`, `removeInteractives(prefix)`
* Emits standard `UIClick`, `UIEntering`, `UILeaving` — check `source` for `UIElementIdentifiable` to access `id`/`metadata`

### settings
Emits setting values to the build.

```
settings{key1=>value1, key2=>value2, ...}
```

Values can be typed, similar to interactive metadata:
```
settings{action => "buy", price:int => 100, weight:float => 1.5}
```

Supported types: `int`, `float`, `string` (default when no type specified).

---

## Coordinate Systems (xy)

### Basic Coordinates

* `x,y` - offset coordinates
* `;` - 0,0 offset
* `layout(layoutName [, index])` - coordinates from layout

### Grid Coordinates

Requires a `grid:` declaration inside the element body:

```manim
#test programmable(n:uint=0) {
    grid: 20, 20
    bitmap(tile): $grid.pos($n, 0)
}
```

* `$grid.pos(x, y)` - grid position
* `$grid.pos(x, y, offsetX, offsetY)` - grid position with pixel offset
* `$grid.width` - grid cell width (spacingX)
* `$grid.height` - grid cell height (spacingY)

Named grid systems use `#name`:

```manim
#test programmable(n:uint=0) {
    grid: #smallGrid 10, 10
    grid: #bigGrid 40, 40
    bitmap(tile): $smallGrid.pos($n, 0)
    bitmap(tile): $bigGrid.pos($n, 0)
}
```

### Hex Coordinates

Requires a `hex:` declaration inside the element body:

```manim
#test programmable(n:uint=0) {
    hex: pointy(16, 16)
    bitmap(tile): $hex.cube(0, 0, 0)
}
```

* `$hex.cube(q, r, s)` - hex cube coordinates
* `$hex.corner(index, scale)` - position at hex polygon corner
* `$hex.edge(direction, scale)` - position at hex polygon edge
* `$hex.offset(col, row, even|odd)` - hex offset coordinates
* `$hex.doubled(col, row)` - hex doubled coordinates
* `$hex.pixel(x, y)` - snap pixel position to nearest hex center
* `$hex.width` - hex cell width
* `$hex.height` - hex cell height

Cell-relative hex methods (position relative to a specific hex cell):

* `$hex.cube(q, r, s).corner(index, scale)` - corner of a specific hex cell
* `$hex.cube(q, r, s).edge(direction, scale)` - edge of a specific hex cell

### Coordinate Value Extraction (.x / .y)

Any coordinate method call can have `.x` or `.y` appended to extract a single component as a numeric value. This is useful in expressions:

```manim
#test programmable(n:uint=0) {
    grid: 20, 15
    hex: pointy(16, 16)
    bitmap(generated(color($grid.pos($n, 0).x + 5, $grid.pos($n, 0).y, #f00))): 0, 0
    text(dd, '${$hex.corner(0, 1.0).x}', #fff): 0, 0
}
```

### Context Properties

* `$ctx.width` - width of the programmable element
* `$ctx.height` - height of the programmable element
* `$ctx.random(min, max)` - random value between min and max

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
* `float`: `size:float`, e.g., `opacity:float = 0.8`
* `flags`: `mask:flags(bits)`, e.g., `mask:flags(6)`
* `string`: `name="myname"` (always has default)
* `hexdirection`: `dir:hexdirection` (0..5)
* `griddirection`: `dir:griddirection` (0..7)
* `bool`: `true`/`false`, `yes`/`no`, or `0`/`1`
* `color`: `color:<color>`, e.g., `color:#f0f` or `red`
* `tile`: `name:tile` — a tile source passed at runtime (no default allowed). Used with `bitmap($name)` to display caller-provided tiles. In generated code, maps to `Dynamic` (accepts `h2d.Tile`). For the builder, pass via `TileHelper.sheet("atlas", "tile")` or `TileHelper.file("img.png")`.

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

### Inline Properties

In addition to `alpha()` and `scale()` prefixes (documented above), these inline properties can be used on elements:

* `@layer(index)` — set z-layer index (integer), for children of `layers` or `programmable`
* `@alpha(value)` — set opacity (float or `$reference`)
* `@scale(value)` — set scale multiplier (float or `$reference`)
* `@tint(color)` — set color tint (hex color or `$reference`)

Multiple inline properties can be combined:
```
@layer(2) @alpha(0.8) @tint(#FF0000) bitmap("sprite.png"): 10, 20
```

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

Single-quoted strings support `${...}` interpolation to embed expressions inline:

```
'Hello ${$name}'                          // simple variable
'prefix ${$name} suffix'                  // text before and after
'${$x * 2} pixels'                        // expression with arithmetic
'${$first} and ${$second}'                // multiple interpolations
'Score: ${$points}/${$max}'               // adjacent to text
```

Interpolation expressions are wrapped in parentheses for correct precedence, so `'val: ${$x * 2}'` becomes `"val: " + ($x * 2)`.

Single-quoted strings without `${` are treated as plain strings. A literal `$` without `{` is kept as-is.

Interpolation can be mixed with the `+` concatenation operator:
```
'Hello ${$name}' + " (id: " + $id + ")"
```

**Error detection:**
- Unclosed `${` (missing `}`) produces: `Unclosed string interpolation, expected }`
- Empty `${}` or `${ }` produces: `Empty expression in string interpolation`
- Missing closing quote produces: `Unterminated string, missing closing single quote`

---

## Variable Validation

Inside `programmable` blocks, all `$variable` references are validated at parse time. Referencing an undefined variable produces an error listing available variables:

```
unknown variable $foo. Available: width, height, index
```

**Variables in scope:**
- **Parameters** defined in `programmable(...)` declaration
- **Loop variables** (`$i`, `$x`, `$y`) inside `repeatable` / `repeatable2d` bodies
- **Iterator output variables** (`$bitmap`, `$tilename`, `$value`) inside iterator bodies
- **`@final` constants** after their declaration point

Loop and iterator variables are only valid inside their enclosing `{ }` block. `@final` variables are valid from their declaration to the end of their scope.

Outside `programmable` blocks (e.g., root-level elements), no validation is performed.

---

## Constants (`@final`)

Declare immutable named constants to avoid repeating complex expressions:

```
@final cx = $x + $w / 2
@final cy = $y + $h / 2
bitmap(...): $cx, $cy
text(...): $cx, $cy + 12
```

All parameter types are supported: numeric, string, color, bool, arrays.

```
@final label = "Player " + $name
@final bg = #FF0000
@final coords = [$x, $y, 15]
@final displaySize = ?($big) 100 : 50
```

Constants can reference other constants:
```
@final baseX = 400
@final offsetX = $baseX + 100
```

**Scoping:** Every `{ }` block creates a scope. Constants declared inside are cleaned up when leaving:
```
#test programmable(x:uint=5) {
    @final doubled = $x * 2

    flow() {
        @final inner = $doubled + 1   // $doubled visible from outer scope
        bitmap(...): $inner, 0
    }
    // $inner NOT available here

    bitmap(...): $doubled, 0           // $doubled still in scope
}
```

Inside repeatable, constants are re-evaluated per iteration:
```
repeatable($i, step(5, dx: 20)) {
    @final angle = $i * 72
    @final radius = $i * 10 + 20
    bitmap(...): $radius, $angle
}
```

**Errors:**
- Duplicate name in same scope: `@final x = 1` then `@final x = 2`
- Shadowing a programmable parameter: `@final width = ...` when `width` is a parameter

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

Paths define animated paths for objects to follow. Each path maintains a current position and direction angle.

```
paths {
  #pathName path {
    lineTo(50, -20)
    lineAbs(100, 50)
    bezier(100, 50, 75, 25, smoothing: auto)
    bezierAbs(100, 50, 75, 25)
    arc(100, 70)
    forward(100)
    checkpoint(test)
    spiral(20, 60, 360)
    wave(30, 80, 3)
    moveTo(40, 0)
    moveAbs(100, 50)
    close
  }
}
```

**Path Commands:**
* `lineTo(x, y)` - Draw a line to relative coordinates (offset from current position)
* `lineAbs(x, y)` - Draw a line to absolute coordinates in path space
* `bezier(endX, endY, ctrlX, ctrlY[, ctrl2X, ctrl2Y][, smoothing: ...])` - Relative bezier curve (quadratic or cubic)
* `bezierAbs(endX, endY, ctrlX, ctrlY[, ctrl2X, ctrl2Y][, smoothing: ...])` - Absolute bezier curve
* `forward(distance)` - Move forward in the current direction
* `turn(degrees)` - Turn by degrees (changes direction without moving)
* `arc(radius, angleDelta)` - Draw a circular arc. Positive angleDelta = CCW, negative = CW
* `checkpoint(name)` - Define a named checkpoint for timed actions
* `close` - Close the path back to start with a line
* `moveTo(x, y)` - Jump to a relative position without drawing
* `moveAbs(x, y)` - Jump to an absolute position without drawing
* `spiral(radiusStart, radiusEnd, angleDelta)` - Spiral arc with expanding/contracting radius. Positive angleDelta = CCW, negative = CW
* `wave(amplitude, wavelength, count)` - Sinusoidal wave along the current direction

**Relative vs Absolute commands:**
Commands ending in `Abs` use absolute coordinates in path space. The default commands (`lineTo`, `bezier`, `moveTo`) use relative coordinates (offsets from the current position).

**Smoothing (bezier only):**
Bezier curves support an optional smoothing parameter that adds a control point aligned with the current direction for smooth tangent transitions between path segments:
* `smoothing: auto` (default when omitted) - Smoothing control point at 50% distance to the first control point
* `smoothing: none` - No smoothing; may produce sharp angle transitions between segments
* `smoothing: <number>` - Custom distance for the smoothing control point

**Path Normalization (runtime):**
Paths can be scaled/rotated to fit between arbitrary start and end points:
```haxe
var path = paths.getPath("cardFlight", startPos, endPos);
```
The original path shape is preserved but transformed via scale + rotation + translation so that the path origin maps to `startPoint` and the path endpoint maps to `endPoint`.

---

## Animated Paths

Animated paths control how objects traverse a named path over time, with curve-based property animation, timed events, and optional looping. **See [Animated Paths Guide](animpaths.md) for a detailed tutorial with examples.**

```
#animName animatedPath {
    path: myPath
    duration: 0.8
    easing: easeOutCubic
    0.0: scaleCurve: easeInQuad, alphaCurve: fadeIn
    0.5: event("halfway")
    0.0: colorCurve: linear, #FF0000, #00FF00
    0.5: colorCurve: linear, #00FF00, #0000FF
    0.0: custom("myValue"): customCurve
}
```

**Properties:** `path` (required), `type: time|distance`, `duration`, `speed`, `loop`, `pingPong`, `easing` (shorthand for `0.0: progressCurve:`)

**Curve slots** (at rate 0.0–1.0 or checkpoint name): `speedCurve`, `scaleCurve`, `alphaCurve`, `rotationCurve`, `progressCurve`, `colorCurve: curve, #start, #end`, `custom("name"): curve`

Curve references can be named curves from `curves{}` or **inline easing names** (e.g. `easeInQuad`, `easeOutCubic`) — no `curves{}` block needed. Multiple `colorCurve` assignments at different rates create per-segment color interpolation, each with its own start/end colors.

**Events:** `<rate>: event("name")`. Built-in: `pathStart`, `pathEnd`, `cycleStart`, `cycleEnd`

**AnimatedPathState** (returned by `update(dt)` and `seek(rate)`): `position`, `angle`, `rate`, `speed`, `scale`, `alpha`, `rotation`, `color`, `cycle`, `done`, `custom`

**Runtime API:**
```haxe
var ap = builder.createAnimatedPath("name");                         // basic
var ap = builder.createAnimatedPath("name", Stretch(start, end));    // normalized
var ap = builder.createProjectilePath("name", start, end);           // projectile shorthand
var ap = factory.createAnimatedPath_name(start, end);                // macro codegen

ap.onUpdate = (state) -> { sprite.setPosition(state.position.x, state.position.y); };
ap.onEvent = (name, state) -> { if (name == "halfway") doSomething(); };

var state = ap.update(dt);   // advance and get state
var state = ap.seek(0.5);    // query without side effects
ap.reset();                  // reuse from beginning

var rate = path.getClosestRate(worldPoint);  // reverse lookup
```

---

## Curves

1D curves map a normalized input (0→1) to a float output value. Useful for speed profiles, opacity fades, size animations, etc.

```
curves {
    #fadeIn curve {
        easing: easeoutquad
    }
    #speedProfile curve {
        points: [(0, 0.2), (0.3, 0.8), (0.7, 1.0), (1.0, 0.6)]
    }
    #custom curve {
        easing: cubicbezier(0.25, 0.1, 0.25, 1.0)
    }
}
```

**Curve Types:**
* **Easing-based:** `easing: <easingType>` - Uses an easing function to map input to output
* **Point-based:** `points: [(t1, v1), (t2, v2), ...]` - Linear interpolation between control points
* **Segmented:** Multiple time-ranged easing segments, optionally overlapping

### Segmented Curves

Segmented curves chain multiple easing functions across time ranges. Each segment applies its easing within its time interval.

```
curves {
    // Non-overlapping segments (values default to 0→1)
    #chained curve {
        [0.0 .. 0.4] easeinquad
        [0.4 .. 0.7] easeoutcubic
        [0.7 .. 1.0] easeinback
    }

    // Segments with explicit value ranges
    #detailed curve {
        [0.0 .. 0.4] easeinquad (0.0, 0.6)
        [0.3 .. 0.8] easeoutcubic (0.4, 1.0)
        [0.7 .. 1.0] easeinback (0.9, 0.5)
    }
}
```

**Segment syntax:** `[timeStart .. timeEnd] easingType` or `[timeStart .. timeEnd] easingType (valueStart, valueEnd)`

* **Easing is required** per segment
* **Values default** to `(0.0, 1.0)` if omitted
* **Overlapping segments** are blended (equal-weight average in the overlap zone)
* **Gaps** between segments are linearly interpolated between the nearest left segment's end value and right segment's start value
* Cannot mix segments with `easing:` or `points:` in the same curve

**Runtime API:**
```haxe
var curve = builder.getCurve("fadeIn");
var value = curve.getValue(0.5); // returns eased value at t=0.5
```

**Macro codegen** generates `getCurve_<name>():Curve` factory methods. Easing-only curves are baked inline at compile time.

---

## Data

Data blocks define static typed data within `.manim` files — game configuration, upgrade costs, tier definitions, etc. Data is accessible at runtime via the builder (`Dynamic`) or at compile time via macro-generated typed classes.

### Basic Syntax

```
#name data {
    fieldName: value
    anotherField: value
}
```

Field types are inferred from values:
- `5` → int
- `3.5` → float
- `"text"` → string
- `true` / `false` → bool
- `[1, 2, 3]` → array (element type inferred from first element)

### Record Types

Named record types define schemas for structured data. Declare them with `#name record(field: type, ...)` inside a data block:

```
#upgrades data {
    #tier record(name: string, cost: int, ?dmg: float)

    maxLevel: 5
    name: "Warrior"
    enabled: true
    speed: 3.5
    costs: [10, 20, 40, 80]
    tiers: tier[] [
        { name: "Bronze", cost: 10, dmg: 1.0 }
        { name: "Silver", cost: 20, dmg: 1.5 }
    ]
    defaultTier: tier { name: "None", cost: 0, dmg: 0.0 }
    basicTier: tier { name: "Basic", cost: 5 }
}
```

**Supported field types in records:** `int`, `float`, `string`, `bool`

**Optional fields:** Prefix a field name with `?` to make it optional. Optional fields can be omitted from record values and default to `null`:
```
#item record(name: string, ?description: string, ?weight: float)
light: item { name: "Feather" }                          // description=null, weight=null
heavy: item { name: "Anvil", weight: 100.0 }             // description=null
```

**Record-typed fields** require an explicit type prefix:
- Single record: `fieldName: recordName { field: value, ... }`
- Array of records: `fieldName: recordName[] [{ ... } { ... }]`

Record values are validated against the schema — unknown fields, missing required fields, and duplicate fields produce parser errors. Optional fields can be omitted without error.

### Using Data at Runtime (Builder)

```haxe
var builder = MultiAnimBuilder.load(fileContent, loader, "config.manim");
var data:Dynamic = builder.getData("upgrades");
trace(data.maxLevel);         // 5
trace(data.costs[0]);         // 10
trace(data.tiers[0].name);    // "Bronze"
```

### Using Data with Macros

Use `@:data` metadata for compile-time typed access:

```haxe
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class MyScreen extends bh.multianim.ProgrammableBuilder {
    @:data("res/config.manim", "upgrades")
    public var upgrades;
}
```

The macro generates typed classes. Record types are exposed as top-level classes named `PascalCase(dataName) + PascalCase(recordName)`:

```haxe
// Generated record class: "upgrades" data + "tier" record → UpgradesTier
class UpgradesTier {
    public final name:String;
    public final cost:Int;
    public final dmg:Null<Float>;     // optional field → Null<T>
    public function new(name:String, cost:Int, ?dmg:Null<Float>) { ... }
}

// Generated data class with public final fields
class MyScreen_Upgrades {
    public final maxLevel:Int;        // = 5
    public final name:String;         // = "Warrior"
    public final costs:Array<Int>;    // = [10, 20, 40, 80]
    public final tiers:Array<UpgradesTier>;
    public final defaultTier:UpgradesTier;
    public final basicTier:UpgradesTier;  // dmg is null (omitted)
}
```

Usage:

```haxe
var screen = new MyScreen(resourceLoader);
trace(screen.upgrades.maxLevel);         // 5
trace(screen.upgrades.tiers[0].name);    // "Bronze"
trace(screen.upgrades.defaultTier.dmg);  // 0.0
trace(screen.upgrades.basicTier.dmg);    // null (optional, omitted)
```

#### Custom Type Package

By default, generated record types use the parent class's package. Override with a 3rd parameter:

```haxe
@:data("res/config.manim", "upgrades", "game.data")
public var upgrades;
// → generates game.data.UpgradesTier instead of default package
```

#### mergeTypes

When multiple `@:data` fields reference files with identically-shaped records, use `mergeTypes` to share a single generated type:

```haxe
@:data("res/warriors.manim", "warriors", "game.units", mergeTypes)
public var warriors;

@:data("res/mages.manim", "mages", "game.units", mergeTypes)
public var mages;
// If both have #tier record(name: string, cost: int) → single game.units.WarriorsTier is reused
```

Records are considered identical when they have the same fields (name, type, optional flag) in the same order. A fatal error occurs if the generated type name collides with an existing type.

### Rules

- Data blocks must be root-level (not nested inside programmables)
- Data blocks require a `#name`
- Record names must be unique within a data block
- Commas between array elements and record fields are optional
- Optional fields (`?name: type`) default to `null` when omitted from record values

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
| `relative` | bool | false | Particles move relative to emitter (vs world space) |

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
| PathGuide | `pathguide(pathName, attractStrength, flowStrength, radius)` | Attracts particles toward a named path and nudges them along its direction |

**Examples:**
```
// Swirling vortex with center attractor
forceFields: [vortex(0, 0, 200, 200), attractor(0, 0, 50, 180)]

// Rising smoke with wind and turbulence
forceFields: [turbulence(20, 0.015, 1.0), wind(15, 0)]

// Plasma with repulsor
forceFields: [repulsor(0, 0, 100, 120), turbulence(15, 0.02, 2.0)]

// Magical stream along a path — particles attracted to path and pushed along it
forceFields: [pathguide(myBezierPath, 80, 120, 50)]
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
| `boundsMode` | enum | `none`, `kill`, `bounce(damping)`, `wrap` |
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

### Trail Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `trailEnabled` | bool | false | Enable particle trails |
| `trailLength` | float | — | Trail length multiplier |
| `trailFadeOut` | bool | false | Fade trail opacity over length |

### Sub-Emitters

Particles can spawn other particle groups on lifecycle events.

```
subEmitters: [
    {
        groupId: "sparkGroup",
        trigger: ondeath,
        probability: 0.8,
        inheritVelocity: 0.5,
        offsetX: 10,
        offsetY: 0
    }
]
```

**Sub-emitter properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `groupId` | string | — | Name of the particle group to spawn |
| `trigger` | enum | — | `onbirth`, `ondeath`, `oncollision`, `oninterval(seconds)` |
| `probability` | float | 1.0 | Chance of spawning (0-1) |
| `inheritVelocity` | float | — | Fraction of parent velocity inherited |
| `offsetX` | float | — | Horizontal offset from parent |
| `offsetY` | float | — | Vertical offset from parent |

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
* `generated(cross(width, height, color[, thickness]))` - generated cross (thickness default: 1)
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

## UI Components

UI components are Haxe classes that wrap `.manim` programmables into interactive widgets. Each component requires its `.manim` programmable to follow a specific parameter/element naming contract.

Components are typically created either:
- Directly via static `create()` methods on the component class
- Via `UIScreenBase` helper methods (`addButton`, `addCheckbox`, etc.) which support `.manim` settings overrides

### Settings Convention

`UIScreenBase` helper methods accept a `ResolvedSettings` map (from `.manim` `settings{...}` blocks). Setting names follow this convention:
- **Single builder**: `buildName` — overrides the programmable name to build
- **Multiple builders**: `<element>BuildName` — e.g. `radioBuildName`, `radioButtonBuildName`

### Button

**Haxe class:** `UIStandardMultiAnimButton`

**Required `.manim` parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `buttonText` | string | Display text |
| `status` | combo: `normal`, `hover`, `pressed` | Interaction state |
| `disabled` | combo: `true`, `false` | Disabled state |

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"button"` | Programmable name |
| `text` | string | method param | Button text override |

**Events:** `UIClick`

```haxe
// Direct
var btn = UIStandardMultiAnimButton.create(builder, "button", "Click Me");

// Via UIScreenBase (with macro settings injection)
var btn = addButtonWithSingleBuilder(builder, "button", "Click Me");
var btn = addButton(builder.createElementBuilder("button"), "Click Me", settings);
```

### Checkbox

**Haxe class:** `UIStandardMultiCheckbox`

**Required `.manim` parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | combo: `normal`, `hover`, `pressed` | Interaction state |
| `disabled` | combo: `true`, `false` | Disabled state |
| `checked` | combo: `true`, `false` | Checked state |

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"checkbox"` | Programmable name |
| `initialValue` | bool | `false` | Initial checked state |

**Events:** `UIToggle(checked:Bool)`

```haxe
var cb = UIStandardMultiCheckbox.create(builder, "checkbox", true);
var cb = addCheckbox(builder, false);
```

### Checkbox with Text

**Haxe class:** `UIElementContainer` (wraps checkbox + text)

**Required `.manim` parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `textColor` | int | Text color |
| `title` | string | Label text |
| `font` | string | Font name |

**Required `.manim` placeholder:** `checkbox` — resolved via factory to a checkbox widget

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"checkboxWithText"` | Programmable name |
| `textColor` | int | `0xFFFFFFFF` | Text color override |
| `font` | string | method param | Font name override |

```haxe
var cbText = addCheckboxWithText(builder, "my label", "m6x11", true);
```

### Slider

**Haxe class:** `UIStandardMultiAnimSlider`

**Interfaces:** `UIElement`, `UIElementDisablable`, `StandardUIElementEvents`, `UIElementNumberValue`, `UIElementFloatValue`, `UIElementSyncRedraw`

**Required `.manim` parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string: `normal`, `hover`, `pressed` | Interaction state |
| `size` | int | Slider track width in pixels |
| `value` | int | Current value (0-100 internally) |
| `disabled` | string: `true`, `false` | Disabled state |

**Required `.manim` named points:**
- `start` — left edge of the slider track
- `end` — right edge of the slider track

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"slider"` | Programmable name |
| `size` | int | `200` | Track width |
| `min` | float | `0` | Minimum value of the slider range |
| `max` | float | `100` | Maximum value of the slider range |
| `step` | float | `0` | Step size for snapping (0 = continuous) |

**Events:**
- `UIChangeValue(value:Int)` — integer value (rounded)
- `UIChangeFloatValue(value:Float)` — precise float value

**Custom range:** The slider maps any external `min`..`max` float range to the internal 0-100 `.manim` grid. For example, setting `min=0, max=1, step=0.1` gives a 0.0–1.0 slider with 0.1 increments, while the `.manim` grid still uses 0-100.

**Incremental updates:** The slider uses incremental build mode — the first `doRedraw()` builds the full visual tree, subsequent redraws only update changed parameters (`status`, `value`, `disabled`) via `setParameter()`.

```haxe
var slider = UIStandardMultiAnimSlider.create(builder, "slider", 200, 50);
var slider = addSlider(builder, 50);

// Custom range and steps
slider.min = 0;
slider.max = 1;
slider.step = 0.1;

// Float value access
slider.setFloatValue(0.5);
var v:Float = slider.getFloatValue();

// Float callback
slider.onFloatChange = (value:Float, wrapper) -> trace('Value: $value');
```

### Radio Buttons

**Haxe class:** `UIMultiAnimRadioButtons`

**Required `.manim` parameters (container):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `count` | int | Number of radio buttons |

**Required `.manim` placeholder (container):** `checkbox` — indexed placeholder, resolved to individual radio button widgets via callback

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `radioBuildName` | string | `"radioButtonsVertical"` / `"radioButtonsHorizontal"` | Container programmable name |
| `radioButtonBuildName` | string | `"radio"` | Single radio button programmable name |

**Events:** `UIChangeItem(index:Int, items:Array<UIElementListItem>)`

```haxe
var radio = UIMultiAnimRadioButtons.create(builder, "radioButtons", "radio", items, 0);
var radio = addRadio(builder, items, true, 0); // vertical, selected index 0
```

### Progress Bar

**Haxe class:** `UIMultiAnimProgressBar`

**Interfaces:** `UIElement`, `UIElementNumberValue`, `UIElementSyncRedraw`

A display-only component for health bars, XP bars, loading indicators, etc. The `.manim` definition receives a `value` (0-100) parameter and can use conditionals to change colors at different thresholds.

**Required `.manim` parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | 0..100 | Current progress value |

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"progressBar"` | Programmable name |

**Events:** `UIChangeValue(value:Int)` — emitted via `syncInitialState` when added to screen

**Example `.manim`:**

```manim
#progressBar programmable(value:0..100=50) {
    bitmap(generated(color(202, 20, #333333))): 0, 0
    @(value => 0..25) bitmap(generated(color($value * 2, 16, #ff4444))): 1, 2
    @(value => 26..60) bitmap(generated(color($value * 2, 16, #ffaa00))): 1, 2
    @(value => 61..100) bitmap(generated(color($value * 2, 16, #44cc44))): 1, 2
    text(dd, $value, white, left): 210, 3
}
```

```haxe
var bar = UIMultiAnimProgressBar.create(builder, "progressBar", 75);
var bar = addProgressBar(builder, settings, 75);

bar.setIntValue(50); // triggers redraw
var v:Int = bar.getIntValue();
```

> **Note:** The progress bar uses full rebuild (not incremental mode) because `bitmap(generated(color(...)))` elements are not tracked by the incremental expression system.

### Scrollable List

**Haxe class:** `UIMultiAnimScrollableList`

**Required `.manim` parameters (panel):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `width` | int | Panel width |
| `height` | int | Panel height |
| `topClearance` | int | Top margin |

**Required `.manim` placeholder (panel):** `mask` — clipping mask for scroll content

**Required `.manim` parameters (item via `UIElementBuilder`):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `itemWidth` | int | Item width |
| `index` | int | Item index |
| `title` | string | Item display text |
| `tile` | tile | Item icon (if available) |
| `status` | combo: `normal`, `hover`, `pressed` | Interaction state |
| `selected` | combo: `true`, `false` | Selection state |
| `disabled` | combo: `true`, `false` | Disabled state |

**Required `.manim` root setting (item):** `height` — item height in pixels

**List item tile sources:** Each `UIElementListItem` can specify a tile via the `tileRef` field using the `TileRef` enum:

```haxe
var items:Array<UIElementListItem> = [
    {name: "Sword", tileRef: TRFile("sword.png")},
    {name: "Shield", tileRef: TRSheet("items", "shield")},
    {name: "Potion", tileRef: TRSheetIndex("items", "potion", 2)},
    {name: "Spacer", tileRef: TRGeneratedRect(16, 16)},
    {name: "Red box", tileRef: TRGeneratedRectColor(16, 16, 0xFF4444)},
    {name: "No icon"},  // tile parameter omitted
];
```

`TileRef` variants: `TRFile`, `TRSheet`, `TRSheetIndex`, `TRGeneratedRect`, `TRGeneratedRectColor`, `TRTile` (pass pre-loaded `h2d.Tile`).

The legacy `tileName` field (plain string file path) is still supported but deprecated in favor of `tileRef`.

**Required `.manim` parameters (scrollbar):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `panelHeight` | string | Visible panel height |
| `scrollableHeight` | string | Total scrollable content height |
| `scrollPosition` | string | Current scroll position |

**Optional `.manim` root setting (scrollbar):** `scrollSpeed` — pixels per second (default: 100)

**UIScreenBase settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `panelBuildName` | string | method param | Panel programmable name |
| `itemBuildName` | string | method param | Item programmable name |
| `scrollbarBuildName` | string | method param | Scrollbar programmable name |
| `scrollbarInPanelName` | string | `"scrollbar"` | Named element in panel for scrollbar placement |
| `width` | int | `100` | Panel width |
| `height` | int | `100` | Panel height (acts as max height when `panelMode` is `scalable`) |
| `topClearance` | int | `0` | Top margin |
| `panelMode` | string | `"scrollable"` | `"scrollable"` for fixed height with scrollbar, `"scalable"` for auto-sizing to content |
| `scrollSpeed` | float | from `.manim` or `100` | Scroll speed override (pixels/sec) |
| `doubleClickThreshold` | float | `0.3` | Double-click detection window (seconds) |
| `wheelScrollMultiplier` | float | `10` | Mouse wheel scroll sensitivity |

**Events:** `UIChangeItem(index, items)`, `onItemDoubleClicked` callback

```haxe
var list = UIMultiAnimScrollableList.create(panelBuilder, itemBuilder,
    scrollbarBuilder, "scrollbar", 200, 300, items, 0, 0);

// With settings overrides
var list = addScrollableList(panelBuilder, itemBuilder, scrollbarBuilder,
    "scrollbar", items, settings, 0, 200, 300);

// Configurable after creation
list.scrollSpeedOverride = 150.0;
list.doubleClickThreshold = 0.5;
list.wheelScrollMultiplier = 20;
```

**Performance:** The scrollbar is built with incremental mode. On scroll events (wheel, keyboard), only the `scrollPosition` parameter is updated via `setParameter()` instead of rebuilding the entire scrollbar visual. Full scrollbar rebuilds only happen when the item list changes (via `buildItems()`).

### Dropdown

**Haxe class:** `UIStandardMultiAnimDropdown`

Combines a closed/open button with a `UIMultiAnimScrollableList` panel. Supports both scrollable (fixed height with scrollbar) and scalable (auto-sizing to content) panel modes via the `panelMode` setting.

**Required `.manim` parameters (dropdown):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | combo: `normal`, `hover`, `pressed` | Interaction state |
| `panel` | combo: `open`, `closed` | Panel visibility state |

**Required `.manim` named elements (dropdown):**
- `panelPoint` — updatable point where the panel is positioned
- `selectedName` — text element showing the currently selected item name

**Optional `.manim` root setting (dropdown):** `transitionTimer` — open/close animation duration (default: 1.0 seconds)

**UIScreenBase settings** (includes all Scrollable List settings, plus):

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `dropdownBuildName` | string | method param | Dropdown programmable name |
| `autoOpen` | bool | `true` | Open on mouse enter |
| `autoCloseOnLeave` | bool | `true` | Close on mouse leave |
| `closeOnOutsideClick` | bool | `true` | Close when clicking outside |
| `transitionTimer` | float | from `.manim` or `1.0` | Open/close animation duration override |

**Events:** `UIChangeItem(index, items)`

```haxe
// Direct with separate builders
var dd = UIStandardMultiAnimDropdown.create(
    builder.createElementBuilder("dropdown"),
    builder.createElementBuilder("list-panel"),
    builder.createElementBuilder("list-item"),
    builder.createElementBuilder("scrollbar"),
    "scrollbar", items);

// Convenience with single builder (uses standard component names as defaults)
var dd = UIStandardMultiAnimDropdown.createWithSingleBuilder(builder, items);

// Configurable after creation
dd.autoOpen = false;
dd.transitionTimerOverride = 0.5;
```

### Interactive

**Haxe class:** `UIInteractiveWrapper`

Hit-test regions with optional typed metadata. No `.manim` parameter contract — wraps `MAInteractive` objects directly.

See the [interactive element](#interactive) section for `.manim` syntax.

**Screen integration:**
```haxe
// Add single interactive
var wrapper = addInteractive(maObject, "prefix");

// Add all interactives from a build result
var wrappers = addInteractives(buildResult, "prefix");

// Remove by prefix
removeInteractives("prefix");
```

**Events:** `UIClick`, `UIEntering`, `UILeaving` — check `source` for `UIElementIdentifiable` to get `id` and `metadata`

### Draggable

**Haxe class:** `UIMultiAnimDraggable`

Wraps any `h2d.Object` to make it draggable. No `.manim` parameter contract.

```haxe
var draggable = UIMultiAnimDraggable.create(someObject);
draggable.enabled = false; // disable dragging
```

---

## Programmable Macros (Compile-Time Code Generation)

The library can generate **typed Haxe classes** from `.manim` programmable definitions at compile time. Instead of building UI at runtime with `MultiAnimBuilder.buildWithParameters()`, the macro system generates factory and instance classes with typed `create()` methods and parameter setters — giving you full type safety, IDE autocomplete, and zero parsing overhead.

### Overview: Builder vs Macro

| Approach | When to Use |
|----------|-------------|
| **Builder** (runtime) | Dynamic UIs, hot-reload during development, editor/playground |
| **Macro** (compile-time) | Production code, type-safe APIs, performance-critical UI |

Both approaches render identically — the macro system generates the same h2d tree that the runtime builder would produce.

### Quick Start

**1. Define a programmable in a `.manim` file:**

```
version: 0.5

#myButton programmable(status:[hover, pressed, normal]=normal, buttonText="Click") {
    @(status=>normal)  ninepatch("ui", "button-idle", 200, 30):    0, 0
    @(status=>hover)   ninepatch("ui", "button-hover", 200, 30):   0, 0
    @(status=>pressed) ninepatch("ui", "button-pressed", 200, 30): 0, 0
    text(dd, $buttonText, white, center, 200): 0, 8
}
```

**2. Create a factory class with `@:manim` annotations:**

```haxe
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class MyUI extends bh.multianim.ProgrammableBuilder {
    @:manim("res/ui/buttons.manim", "myButton")
    public var button;
}
```

**3. Use the generated typed API:**

```haxe
var ui = new MyUI(resourceLoader);

// create() with positional parameters
var btn = ui.button.create();                  // all defaults
var btn2 = ui.button.create("Submit");         // another independent instance

// createFrom() with named parameters via anonymous struct
var btn3 = ui.button.createFrom({buttonText: "OK"});              // only set what you need
var btn4 = ui.button.createFrom({status: MyUI_Button.Hover, buttonText: "Cancel"});

// Type-safe setters for each parameter
btn.setStatus(MyUI_Button.Hover);              // enum constants are generated
btn.setButtonText("Cancel");

// The instance IS an h2d.Object — add directly to the scene
scene.addChild(btn);
scene.addChild(btn2);
```

### How It Works

The `@:build(ProgrammableCodeGen.buildAll())` macro scans the class for `@:manim` fields and generates two classes for each one:

1. **Factory class** (`MyUI_Button`) — extends `ProgrammableBuilder`, lives on the parent field (`ui.button`). Stateless — only holds the resource loader and cached builder. Has `create()` and `createFrom()` methods and static enum constants.

2. **Instance class** (`MyUI_ButtonInstance`) — extends `h2d.Object`, returned by `create()`/`createFrom()`. Holds all element fields, parameter fields, setters, and visibility/expression update logic. Since it extends `h2d.Object`, it can be added directly to the scene graph.

For the example above, the generated API provides:

- **`create([params...])`** — on the factory; positional parameters, builds a new h2d tree and returns a new instance
- **`createFrom({...})`** — on the factory; named parameters via anonymous struct, optional params can be omitted
- **`setStatus(v)`**, **`setButtonText(v)`** — on the instance; typed setters that update visibility and expressions
- **Static enum constants** — `MyUI_Button.Hover`, `MyUI_Button.Pressed`, `MyUI_Button.Normal` (on the factory class)

### Parameter Type Mapping

Each `.manim` parameter type maps to a Haxe type in the generated `create()` signature:

| .manim Type | Haxe Type | Generated Constants | Example |
|-------------|-----------|-------------------|---------|
| `[hover, pressed, normal]` | `Int` | `static inline var Hover = 0;` etc. | `setStatus(MyUI_Button.Hover)` |
| `bool` | `Bool` | — | `setVisible(true)` |
| `uint`, `int` | `Int` | — | `setWidth(200)` |
| `float` | `Float` | — | `setOpacity(0.8)` |
| `0..100` (range) | `Int` | — | `setLevel(75)` |
| `flags(8)` | `Int` | — | `setBits(5)` |
| `"text"` (string) | `String` | — | `setLabel("Hello")` |
| `color` | `Int` | — | `setTint(0xFF0000)` |
| `tile` | `Dynamic` | — | `create(myTile)` (pass `h2d.Tile`) |

Parameters with defaults are optional in `create()`. Required parameters (no default) must be provided. `tile` parameters never have defaults and are always required.

### `createFrom()` — Named Parameters

Every factory also generates a `createFrom()` method that takes an anonymous struct with named fields instead of positional arguments. This is useful when a programmable has many parameters and you only want to set a few:

```haxe
// Positional — must count argument positions
var dlg = ui.dialog.create(400, 200, "Title", "Body", MyUI_Dialog.Hover);

// Named — specify only what you need, rest use defaults
var dlg = ui.dialog.createFrom({w: 400, title: "Title"});

// All defaults
var dlg = ui.dialog.createFrom({});
```

**Rules:**
- Field names match the `.manim` parameter names exactly
- Parameters with defaults in `.manim` are optional in the struct (can be omitted)
- Parameters without defaults are required (compiler enforces this)
- Both `create()` and `createFrom()` return the same instance type and produce identical results

### Examples

#### Button with enum and string parameters

```
// button.manim
#myBtn programmable(status:[hover, pressed, normal]=normal, disabled:[true,false]=false, buttonText="Button") {
    @(status=>normal, disabled=>false)  ninepatch("ui", "button-idle", 200, 30):     10, 21
    @(status=>hover, disabled=>false)   ninepatch("ui", "button-hover", 200, 30):    10, 20
    @(status=>pressed, disabled=>false) ninepatch("ui", "button-pressed", 200, 30):  10, 20
    @(status=>*, disabled=>true)        ninepatch("ui", "button-disabled", 200, 30): 10, 20

    text(dd, $buttonText, 0xffffff12, center, 200): 10, 30
}
```

```haxe
// Haxe usage — positional
var btn = ui.button.create();
btn.setStatus(MyUI_Button.Pressed);
btn.setDisabled(true);   // shows disabled style regardless of status
btn.setButtonText("Save");

// Or with named parameters
var btn2 = ui.button.createFrom({status: MyUI_Button.Pressed, disabled: true, buttonText: "Save"});
```

#### Health bar with expressions and range conditionals

```
// healthbar.manim
#healthbar programmable(w:uint=200, h:uint=20, health:uint=75, maxHealth:uint=100) {
    // Background
    ninepatch("ui", "Sliderbar_H_3x1", $w, $h): 0, 0

    // Health fill — width is an expression of parameters
    @(health => 30..100) ninepatch("ui", "button-idle", $w * $health / $maxHealth, $h - 4): 2, 2
    @(health => 0..30)   ninepatch("ui", "button-pressed", $w * $health / $maxHealth, $h - 4): 2, 2

    // Text overlay
    text(dd, $health, white, center, $w): 0, 3
}
```

```haxe
var hb = ui.healthbar.create();                          // defaults: 200x20, 75/100 health
var hb2 = ui.healthbar.createFrom({w: 300, health: 50}); // named: custom width + health
hb.setHealth(50);                       // bar resizes, text updates to "50"
hb.setHealth(15);                       // switches to red (pressed) style
```

When you call `setHealth()`, the generated code:
1. Updates visibility — shows the green bar for 30-100, red bar for 0-30
2. Recalculates expressions — resizes the bar width (`$w * $health / $maxHealth`)
3. Updates text — displays the new health value

#### Bool and float parameters

```
// panel.manim
#panel programmable(showBorder:bool=true, showLabel:bool=false, opacity:float=0.8, barWidth:float=1.5) {
    @(showBorder=>true)  ninepatch("ui", "button-hover", 150, 30): 0, 0
    @(showBorder=>false) ninepatch("ui", "button-disabled", 150, 30): 0, 0
    @(showLabel=>true)   text(dd, "Label", white, left, 100): 5, 8
    @alpha($opacity)     ninepatch("ui", "button-idle", 120, 20): 0, 35
    ninepatch("ui", "Sliderbar_H_3x1", 80 * $barWidth, 10): 0, 60
}
```

```haxe
var p = ui.panel.create(true, false, 0.8, 1.5);  // all params explicit
p.setShowBorder(false);   // Bool setter
p.setOpacity(0.5);        // Float — updates alpha expression
p.setBarWidth(2.0);       // Float — recalculates width expression
```

#### Filters with parameter-driven values

```
// effects.manim
#effects programmable(outlineColor:color=#FF0000, blurRadius:int=2, tintColor:color=#00FF00) {
    bitmap(generated(color(60, 60, #4488FF))) {
        filter: outline(size: 2, color: $outlineColor)
        pos: 20, 20
    }
    bitmap(generated(color(60, 60, #44FF88))) {
        filter: blur(radius: $blurRadius, gain: 1.0)
        pos: 120, 20
    }
    @tint($tintColor) bitmap(generated(color(60, 60, #FFFFFF))): 220, 20
}
```

```haxe
var fx = ui.effects.create();
fx.setOutlineColor(0x00FF00);  // filter updates in-place
fx.setBlurRadius(5);
fx.setTintColor(0xFF0000);
```

#### Static refs to other programmables

```
// components.manim
#colorBox programmable(width:int, height:int, c1:color=white) {
    bitmap(generated(color($width, $height, $c1)));
}

#threeBoxes programmable() {
    staticRef($colorBox, width=>100, height=>80, c1=>#FF0000): 20, 20;
    staticRef($colorBox, width=>100, height=>80, c1=>#00FF00): 140, 20;
    staticRef($colorBox, width=>100, height=>80, c1=>#0000FF): 260, 20;
}
```

Static refs are resolved at runtime — the macro generates a `buildStaticRef()` call that uses the runtime builder to construct the referenced programmable's tree dynamically.

#### Range and flags parameters

```
// stats.manim
#statsBar programmable(level:0..100=60, power:0..50=30, bits:flags(8)=5) {
    @(level => 50..100) ninepatch("ui", "button-idle", $level * 2, 15): 0, 0
    @(level => 0..50)   ninepatch("ui", "button-pressed", $level * 2, 15): 0, 0
    ninepatch("ui", "button-hover", $power * 3, 12): 0, 20
    text(dd, $level, white, left, 80): 0, 50
}
```

```haxe
var stats = ui.statsBar.create(80, 25, 5);
stats.setLevel(30);    // switches to "pressed" style, bar shrinks
stats.setPower(50);    // bar grows to 150px wide
stats.setBits(7);      // flags parameter — individual bits can be tested in conditionals
```

### Multiple Instances

Each call to `create()` returns a new independent `h2d.Object` instance. The factory (`ui.button`) is stateless, so you can create as many instances as you need:

```haxe
var ui = new MyUI(resourceLoader);
for (i in 0...4) {
    var btn = ui.button.create();
    btn.setButtonText('Button $i');
    btn.setPosition(0, i * 40);
    scene.addChild(btn);
}
```

### MacroUtils.macroBuildWithParameters

For **placeholder-based** composition (embedding interactive widgets like buttons, sliders, and dropdowns into a `.manim` layout), use `MacroUtils.macroBuildWithParameters`:

**.manim file:**
```
#settingsPanel programmable() {
    ninepatch("ui", "Window_3x3_idle", 300, 400): 0, 0
    placeholder(generated(cross(200, 20, #FF0000)), builderParameter("volumeSlider")): 20, 50
    placeholder(generated(cross(200, 20, #FF0000)), builderParameter("muteCheckbox")): 20, 100
}
```

**Haxe code:**
```haxe
var res = MacroUtils.macroBuildWithParameters(builder, "settingsPanel", [], [
    volumeSlider => addSlider(builder, 50),
    muteCheckbox => addCheckbox(builder, true)
]);

// Access the created widgets through the typed result
res.volumeSlider;          // the slider UIElement
res.muteCheckbox;          // the checkbox UIElement
res.builderResults;        // the BuilderResult with .object, .getUpdatable(), etc.
```

The macro automatically:
- Detects whether each value is a factory function or a pre-created object
- Injects `ResolvedSettings` into factory function calls
- Adds UIElements to the UIScreen element list
- Returns a typed anonymous struct with all named placeholders plus `builderResults`
