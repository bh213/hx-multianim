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
stateanim("filename", "state", "direction"=>"l")
```

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

**2D repeatable:**
```
repeatable2d($x, $y, <iteratorX>, <iteratorY>)
```

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
* `bool`: `true`/`false` or `0`/`1`
* `color`: `color:<color>`, e.g., `color:#f0f` or `red`

---

## Conditionals

Conditions are defined by `@(...)` and can be specified once per element.

* `@()` or `@if(...)` - match all provided
* `@(!param=>'value')` - match when param is NOT value
* `@ifstrict(...)` - must match all provided parameters

**Range matches:**
* `@(key => greaterThanOrEqual 30)`
* `@(key => lessThanOrEqual 30)`
* `@(key => between 10..30)`

**Multi enum match:**
* `@(key => [value1, value2])`

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

## Tile Sources

* `sheet(sheet, name)` - from atlas sheet
* `file(filename)` - from file
* `generated(cross(width, height[, color]))` - generated cross
* `generated(solid(color, width, height))` - solid color

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
