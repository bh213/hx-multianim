# hx-multianim

A Haxe library for creating animations and pixel art UI elements using the [Heaps](https://heaps.io/) framework. This library provides a custom language for defining state animations and programmable UI components.

## Interactive Playground

Playground is available at [gh-pages](https://bh213.github.io/hx-multianim/).

This repository includes a comprehensive interactive playground that demonstrates the library's capabilities. The playground is located in the `playground/` directory and provides:

- **Live Examples**: Interactive demonstrations of UI components, animations, and effects
- **Code Editor**: Real-time editing of `.manim` files with instant preview
- **Multiple Screens**: Various examples showcasing different features
- **Resource Management**: Live reloading of assets and animations

### Running the Playground

```bash
cd playground
lix download
npm install
npm run dev
```

This will start the playground at `http://localhost:3000` with live reloading enabled.

For more details, see the [playground README](playground/README.md).

## Getting Started - Work in progress

### Prerequisites

Before using hx-multianim, you need to install the following tools:

#### Install Haxe
Download and install Haxe from [haxe.org](https://haxe.org/download/):

#### Install Lix (Recommended)
[Lix](https://www.npmjs.com/package/lix) is the modern package manager for Haxe projects. Install it:
```bash
npm install -g lix
```
### Quick Start

1. **Add to your project**:
   ```hxml
   -lib hx-multianim
   -lib heaps
   -lib hxparse
   ```

2. **Create a simple animation**:
   ```haxe
   // Your animation definition file (.manim)
   #player programmable(direction:[left,right]=right) {
     @(direction=>left) bitmap("player_left.png"): 0,0
     @(direction=>right) bitmap("player_right.png"): 0,0
   }
   ```

3. **Use in your Haxe code**:
   ```haxe
   import wt.MultiAnim;
   
   class Main {
     static function main() {
       var multianim = new MultiAnim();
       // Load and use your animations
     }
   }
   ```

---

## Trace Support

The library includes comprehensive debug tracing that can be controlled using conditional compilation. To enable debug traces, add the `MULTIANIM_TRACE` flag to your HXML file:

```hxml
-D MULTIANIM_TRACE
```

---

## Macro-Based UI Construction

The library uses macros to map `.manim` file elements to Haxe code. Builder parameters in `.manim` files (using `builderParameter("name")`) are mapped to named arguments in the macro build:

`.manim file`
```
// In your .manim file
#ui programmable() {
  placeholder(generated(cross(200, 20)), builderParameter("button")) {
      settings(buildName=>button_custom)
  }
}
```

`Haxe code`
```haxe
var ui = MacroUtils.macroBuildWithParameters(buttonBuilder, "ui", [], [
    button=>addButton(buttonBuilder, "Click Me!"),
]);
```

The `builderParameter("button")` in the `.manim` file corresponds to the `button=>addButton(...)` mapping in the Haxe code.

---

State animations
=================================

State animation is animation that can be in different states and have different animation running.

For example, animation can have animation named `running` with state `direction(l,r)`. When `l` is set, animation displays running to the left, when `r` state is set, animation is running to the right.

Animation can have extraPoints - these are points where other animations or code interacts with sprites. They can represent impact points, source of bullets, particle effect source etc.

### Example:
```
sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48

animation {
    name: idle
    fps: 4
    playlist {
        loop untilCommand {
            sheet "marine_$$direction$$_idle"
        }
    }
}
```

### Animation
Animation has the following fields:

* `name` - must be unique and is required
* `fps` - default frames per second for playlist. Each frame can have delay override using `duration`
* `playlist` list of frames and other commands
* `center` - center point for this animation. This applies to all the frames in playlist for specific animation name
* `extraPoints` - points of interest for this animation (e.g. particle effects, explosions, wounds,...)
* `loop` - looping for the whole playlist, supports all `loop` options.

### Playlist

* `loop: yes` | `loop` - loops forever
* `loop: untilCommand` - loops until there is a command in command queue
* `loop: <number>` - loops a <number> of times, can be used to create multiple events (e.g. random)
* `file: "<filename>"` - loads and plays file (should be single frame png image)
* `event <name> random x,y,radius` - fires random event with point that is at most <radius> away from (x,y)
* `event <name> trigger` - fires event with specific <name>
* `event <name> x,y` - fires point event with (x,y)
* `command` - executes next command if queue is not empty
* `goto <name>` - switches to another animation `<name>`. Can be used for transitions.
* `sheet: "myanimation" frames: 1..2 duration: 25ms` - creates playlist animation from atlas sheet (starting at frame 1 and ending at frame 2, each frame taking 25ms)
* `sheet: "myanimation"` - uses default `fps` setting and takes all frames with the name `myanimation` from the atlas sheet.
* `sheet: "myanimation_$$state$$_name"` - uses state variable interpolation in sheet names

### Conditionals based on state

```
animation @(direction=>l) @(color=>red) {
    name: bla
}
```
Only applied when `direction=>l` and `color=>red`

```
@(direction=>l) extrapoints { 
    fire : -2, -2
}
```    
Only provides extrapoints when `direction=>l`.

### Commands - programming interface

Commands can have the following triggers:

* NEXT_COMMAND_ON_ANIM_END on end of animation, end of loop or `command` playlist command
* NEXT_COMMAND_WAIT_TIMER - execute next command after specified time (does not take end of animation into account)
* NEXT_COMMAND_NOW - execute immediately

Commands
* Delay(seconds) - wait for specific time before executing next command
* SwitchState(seconds) - switch to another animation name
* CommandEvent - trigger event
* Callback - execute callback
* Visible - set sprite visibility

Multi anim
=================================

MultiAnim is a library for creating partial UI and game elements from custom language made specifically for pixel art UI.
For example, dropdown can use two different `programmable` objects, one to create element with current value and another one with opened panel.

Programmables can accept parameters and these parameters can be used either in expressions passed to elements or to filter elements.

There are two ways you can declare elements, short form and long form.

Short form looks like this:
```
#name @optionalConditional shortcuts element(params): xy
```
Long form looks like this:
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

Short form is for adding elements such as bitmaps and text without being too verbose. Long form supports adding children and inline properties, such as `pos`.

### Example:
```
#panel programmable(width:uint=180, height:uint=30, mode:[idle,pressed]=pressed) {
     @(mode=>idle) alpha(0.1) ninepatch("ui", "Droppanel_3x3_idle", $width, $height): 0,0
     @(mode=>pressed) ninepatch("ui", "Droppanel_3x3_pressed", $width, $height): 0,0
}
```

In this example programmable in the long form with name `panel` is created. Programmable is element that has parameters that affect rendering. `#panel` programmable accepts `width` and `height` parameters, both unsigned integers with default values of `180` and `30`. In addition it has `mode` parameter which is enum and can accept either `idle` or `pressed` values. Default value is `pressed`. If value of parameter is not provided, default is used. Defaults can also be used by designer to show element when it is not yet hooked up to the code.

`panel` programmable has two short-form children (both `ninepatch`). First one has conditional `@(mode=>idle)` which means that this child will only be built when `mode` equals `idle`. The other one only gets built when `mode` is `pressed`.
`ninepatch` element uses atlas sheet named `ui`, sprite name in sheet named `Droppanel_3x3_idle` for first child and `Droppanel_3x3_pressed` for the second one. `$width` and `$height` are expressions referencing input parameters. Expressions can also include `+`, `-`, `*` and `/`, so height could be set to `$height + 13` for example.
`xy` coordinates follow after `:`.

Long form of child definition which can include subchildren also exists
```
@(status=>pressed, disabled=>false) ninepatch("ui", "droppanel-mid-pressed", $itemWidth+4, 20) {
    pos:-2,0;
    alpha:0.1;
    blendMode: alphaAdd;
    point: 33,22
}
```
Long form supports subchildren and the following fields:
* `pos` - same as `xy` in the short form. See `xy`.
* `grid: sizex, sizey` - specifies grid coordinates for itself and its children
* `hex: pointy|flat(sizex, sizey)` - specifies grid coordinates for itself and its children
* `scale: value` - scale for this element and children
* `alpha: value` - alpha (opacity) of this element and children
* `blendMode: none|alpha|add|alphaAdd|softAdd|multiply|alphaMultiply|erase|screen|sub|max|min` - see [Heaps docs](https://heaps.io/api/h2d/BlendMode.html) for more details
* `layer:index` - for immediate children of `layers` and `programmable`, z-order index `layer` can be set.
* `filter: <filter>` - applies filter to itself and children

# List of supported nodes

## bitmap
* `bitmap(tileSource, [center])` - displays image file from filename or atlas sheet, optionally centering it

## stateanim
* `stateanim("filename", "state", direction"=>"l")` - create state animation from filename, with specific file and state

## flow (wip)
* `flow([optional params])` - creates a h2d.Flow (https://github.com/HeapsIO/heaps/wiki/Flow)

Optional params:
* `maxWidth:<int>`
* `maxHeight:<int>`
* `minWidth:<int>`
* `minHeight:<int>`
* `lineHeight`
* `colWidth`
* `layout`: `vertical` | `horizontal` | `stack`
* `paddingTop`
* `paddingBottom`
* `paddingLeft`
* `paddingRight`
* `padding`
* `debug`: `true` | `false`
* `horizontalSpacing:<int>`
* `verticalSpacing:<int>`

## point
* `point` - creates a point, not displayed, for positioning items

Example: _creates point with offset 200,450_

```#test point: 200,450```

## apply
By using `apply` node you can conditionally apply basic settings to node:

The following code applies glow filter to `ninepatch` object when `state` is `selected`:

```
ninepatch("cards", "card-base-patch9", 150,200) {
  @(state=>selected) apply { 
    filter:glow(color:white, alpha:0.9, radius:15, smoothColor:true)
  }
}
```  

`filter`, `scale`, `alpha` and `blendMode` are supported in `apply`

## text
* `text(fontname, text, textcolor[, align, maxWidth], options)` - creates text with font, text content and text color. Align can be `center`, `left` and `right`.

Options can be:
* `letterSpacing` - float
* `lineSpacing` - float
* `lineBreak` - bool - enables line breaks
* `dropShadowXY` - float, float
* `dropShadowColor` - color
* `dropShadowAlpha` - float
* `html` - bool - use h2d.HtmlText (use <br/> instead of \n for line breaks)

Example:
```
@(status=>hover, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
```

## tilegroup 
* `tilegroup` - tilegroup is optimized element that allows (at the moment) the following children: `bitmap`, `point`, `repeat` and `pixels`. It is intended to construct objects such as hp bars that can have 10s or even 100s of elements and would be very slow if added as separate elements. `tilegroup` is converted into single drawable object and drawn at once. See Examples #14. `programmable` can be marked as tilegroup by using the following construct `#name programmable tileGroup(...)`.

## programmable
* `programmable` - used to create instance of all children belonging to this programmable. Must have a unique name. This is core of the multianim library.

Example:
```
#list-panel programmable(width:uint=200, height:uint=200) {
  scale:1
  ninepatch("ui", "Window_3x3_idle", $width+4, $height+8): -2,-4
}
```

## repeatable
* `repeatable($varname, grid(repeatCount, dx, dy))` - creates `repeatCount` number of its children, offsetting each by `dx` and `dy` (either one or both). `$varname` is required and children can reference the current count (starts at 0) by referencing `$varname`. Example: `repeatable($i, grid(5, dx:10, dy:0))` will repeat 5 times, increasing x by 10 each time.
* `repeatable($varname, layout(layoutName))` - iterates through all points in the named layout. Example: `repeatable($i, layout("mainScreen")) { ... }`.
* `repeatable($varname, array(arrayName))` - iterates through all elements of the named array, setting `$varname` to the current value.
* `repeatable($varname, range(start, end[, step]))` - iterates from `start` (inclusive) to `end` (exclusive) by `step` (default 1). Example: `repeatable($i, range(0, 5))` will repeat for $i = 0, 1, 2, 3, 4.
* `repeatable2d($x, $y, <iteratorX>, <iteratorY>)` - nested repeatable that walks all x options for each y value (x is inner loop). Any repeatable iterator can be used for x and y: `grid`, `layout`, `array`, or `range`.

Example (range):
```
repeatable($i, range(0, 3)) {
  text(pikzel, 'Index: $i', #fff, left, 100): $i*20, 0
}
```

Example (grid):
```
repeatable($i, grid(10, dx:10)) {
  pixels (
    rect 0,0, 5, 5, #fff
  );
}
```

Example (repeatable2d):
```
repeatable2d($x, $y, grid(3, dx:10), grid(2, dy:20)) {
  bitmap("cell.png"): 0,0
}
```

NOTE: `dx` and `dy` are optional for grid, but at least one has to be specified.

`repeatable` also supports layouts iterator (see demo examples #13) which will iterate through all layouts. Use `layout(layoutName)`.

example:
```
repeatable($items, grid(0, $cellHeight,$cells)) {
  interactive(114 , $cellHeight, $items);
  text(pikzel, callback("itemName", $items), 0xffffff12, center, 120): -4,4
  @(images=>placeholder) placeholder(tile(15, 15), callback("test")):5,3
  @(images=>tile) bitmap(callback("itemImage", $items), center):5,3
}
```

## ninepatch
* `ninepatch(sheet, tilename, width, height)` - draws 9patch from atlas2 (it has to have `split` with 4 values provided in sprite sheet (atlas))

example:
```
ninepatch("ui", "Droppanel_3x3_idle", 114, $cells * $cellHeight + 6 ): 0,0
```

## layers
* `layers()` - enables children of this node to use `layer` property to change z-direction. Special `layer(index)` can be used to specify layer index in short form. `layer:index` is available in the long form.

example:
```
layers() {
  @(cornerDirections=>2) layer(2) bitmap("png/Corner_090.png", center): 0,0
}
```

## placeholder
* `placeholder(name, [onNoData], [source])` - uses callback to get object to insert. If callback doesn't exist yet, tile of size sizex * sizey is returned.

* onNoData can be `error`, `nothing` or tileSource. In case `error` is set, exception will be thrown if there is no data provided for the source. Nothing just inserts empty h2d.Object.

example:
```
placeholder(tile(15, 15), callback("test")):8,5
```

Possible sources:
* `callback("test")` - callback receives name
* `callback("test", $i)` - callback receives name and index (e.g. for dropdowns)
* `builderParameter("animCommands")` - built from programmable parameters, usually when embedding custom objects into multianim.

## reference
* `reference($reference [, <params>])` - references another programmable node by `reference` and outputs by name. 
* `reference(external(externalName), $reference, [,<params>])` - loads reference from external multianim that was imported by `import file as externalName`.

example:
```
reference($dialogBase) {
  #dialogText(updatable) text(dd, "This is a text message", ffffff00, center, 400): 50,50;
}
```

* It can also reference non-programmable nodes, in that case parameters cannot be specified.

## settings
* `settings(key1=>value1,key2=>value2,... )` - emits setting value to the build, value can only be used by code (e.g. dropdown)

Example:
```
settings(transitionTimer=>0.2)
```

Settings can also be used inside placeholders to override builder names or provide configuration:

```
placeholder(generated(cross(200, 20)), builderParameter("button")) {
    settings(buildName=>button_custom) // override builder name
}
```

### Fonts
List of supported fonts:
* "f3x5"
* "m3x6"
* "pixeled6"
* "pikzel"
* "cnc_inet_12"
* "m5x7"
* "f7x5"
* "f5x5"
* "default_heaps"
* "m6x11"
* "dd_thin"
* "dd"
* "pixellari"
* "dhkp"
* "hh"

## tile source
`tileSource` can be `sheet(sheet, name)`, `file(filename)` or `generated(cross(width, height))`. 

* `sheet(sheet, name)` loads tile from atlas sheet named `sheet`, using tile named `name`
* `file(filename)` loads tile from file.
* `generated(cross(width, height[, color]))` generates image of rectangle with cross with specified dimensions.
* `generated(solid(color, height[, color]))` generates image with solid color

File and sheet loading directories are application specific.

## filters

Filters can be applied to any visual element. Most numeric parameters support referenceable values and expressions, allowing dynamic filter configurations based on programmable parameters.

**Available Filters:**

* `replacePalette(paletteName, sourceRow, replacementRow)` - Applies color replacement using 2D palette named `paletteName`. Colors from row `sourceRow` will be replaced with colors in row `replacementRow`. Colors not matching will be passed through. `sourceRow` and `replacementRow` support references.

* `replaceColor([sourceColors...], [replacementColors...])` - Replaces specific colors with other colors. Both arrays support color references and expressions.

* `outline(size, color)` - Creates an outline around the element. Both `size` and `color` support references and expressions.

* `saturate(value)` - Adjusts color saturation (0.0 = grayscale, 1.0 = normal, >1.0 = oversaturated). Supports references.

* `brightness(value)` - Adjusts brightness (0.0 = black, 1.0 = normal, >1.0 = brighter). Supports references.

* `blur(radius, gain, [quality], [linear])` - Applies blur effect. `radius`, `gain`, `quality`, and `linear` all support references.

* `pixelOutline(knockout, color, knockoutStrength)` - Creates a pixel-perfect outline in knockout mode. `color` and `knockoutStrength` support references.
  
* `pixelOutline(inlineColor, outlineColor, inlineColor)` - Creates a pixel-perfect outline with inline coloring. Both colors support references.

* `dropShadow(distance, angle, color, alpha, radius, gain, quality)` - Creates a drop shadow. All numeric parameters and `color` support references. `angle` is in degrees.

* `glow(color, alpha, [radius], [gain], [quality], [smoothColor], [knockout])` - Creates a glow effect. `color`, `alpha`, `radius`, `gain`, and `quality` support references. `smoothColor` and `knockout` are boolean flags.

* `group(filter1, filter2, ...)` - Groups multiple filters together.

**Referenceable Parameters:**

Most numeric filter parameters and colors support:
- References to programmable parameters: `$owner`, `$index`, etc.
- Arithmetic expressions: `$value * 2 + 10`
- Ternary operators: `?($condition) trueValue : falseValue`
- Palette color references: `palette(paletteFile, $index)`
- Callbacks: `callback("colorName")`

**Examples:**

```
// Simple static filter
filter: outline(2, red)

// Using programmable parameters with ternary operator
#castle programmable(owner:[Player, Enemy]) {
  filter: pixelOutline(knockout, ?($owner == "Player") #0f0 : #f00, 0.9)
  bitmap(file("castle.png")): 0,0
}

// Using expressions with references
#healthBar programmable(health:int=100) {
  filter: saturate(?($health < 30) 0.3 : 1.0)
  bitmap(file("health.png")): 0,0
}

// Multiple filters with group
filter: group(
  outline(?($selected) 2 : 0, yellow),
  brightness(?($active) 1.2 : 0.8)
)

// Dynamic glow color from palette
filter: glow(palette(colors, $index), 1.0, radius: 4)
```

## xy 
xy position can be defined in multiple ways, usually by setting `pos` property in the long form or directly in the short form `#mypoint point:20,30`

* offset coordinates `x,y` - for example: `30, 20`
* `hex(q, r, s)` - requires `hex` coordinate system to be defined. Center of the hex with these coordinates
* `hexCorner(index, scale)` - requires `hex` coordinate system to be defined. Creates position in specific corner of hex scaled from center. Scale 0.0 is center of hex, 1.0 is on the corner, 0.5 is halfway between center and corner. Example: `pos: hexCorner(2, 0.7)`
* `hexEdge(index, scale)` - requires `hex` coordinate system to be defined. Scale 0.0 is center of hex, 1.0 is on the edge of the hex, 0.5 is halfway between center and edge. Example: `hexEdge(5, 1.2)`
* `grid(x,y[, offsetX, offsetY])` - requires `grid` coordinate system to be defined, calculates x * gridwidth, y * gridheight. Example: `grid($x, 2)`. `offsetX` and `offsetY` are optional and can be used to offset the position by a certain amount.

* `;` - 0,0 offset
* `layout(layoutName [, index])` - takes coordinates from `#layout` named `layoutName`.

# References
Referencing programmable parameters is possible in some nodes. Reference uses `$`. For example, programmable `int` parameters can be referenced as `$i` and can be used to construct expressions such as `$i * 10 + 7`
Useful for `repeatable(dx, dy, $count)` for various HP/mana/energy bars. Properties that support references support expressions as well.

# Paths
Paths are root-level elements that define animated paths for objects to follow. Paths support various commands including lines, curves, and smooth transitions.

## Path Syntax
Paths are defined using the `paths` block:

```
paths {
  #pathName path {
    // path commands here
  }
}
```

## Path Commands

### Line Commands
* `line(coordinateMode, x, y)` - Draw a line to the specified coordinates
* `line(x, y)` - Draw a line to coordinates (default relative mode)

**Coordinate Modes:**
* `absolute` - Use absolute coordinates
* `relative` - Use relative coordinates (offset from current position)
* Default is `relative` when no mode is specified

**Examples:**
```
line(absolute, 100, 50)    // Absolute coordinates
line(relative, 50, 25)     // Relative coordinates
line(100, 50)              // Default relative coordinates
```

### Bezier Curve Commands
* `bezier(coordinateMode, x1, y1, x2, y2)` - Quadratic Bezier curve (2 control points)
* `bezier(coordinateMode, x1, y1, x2, y2, x3, y3)` - Cubic Bezier curve (3 control points)
* `bezier(x1, y1, x2, y2)` - Default relative quadratic Bezier
* `bezier(x1, y1, x2, y2, x3, y3)` - Default relative cubic Bezier

**Smoothing Options:**
* `smoothing: auto` - Automatic smoothing (50% of control point distance)
* `smoothing: none` - No smoothing
* `smoothing: 20` - Custom smoothing distance

**Examples:**
```
// Quadratic Bezier curves
bezier(absolute, 200, 100, 150, 50)                    // No smoothing
bezier(relative, 100, 50, 75, 25, smoothing: auto)     // Auto smoothing
bezier(100, 50, 75, 25, smoothing: 20)                 // Custom smoothing

// Cubic Bezier curves
bezier(absolute, 400, 200, 350, 100, 300, 150)         // No smoothing
bezier(relative, 100, 50, 75, 25, 50, 75, smoothing: none)  // No smoothing
bezier(100, 50, 75, 25, 50, 75, smoothing: 30)         // Custom smoothing
```

### Other Path Commands
* `forward(distance)` - Move forward in current direction
* `turn(degrees)` - Turn by specified degrees
* `arc(radius, angleDelta)` - Draw an arc
* `checkpoint(name)` - Define a checkpoint for path navigation

## Complete Path Example
```
paths {
  #testPath path {
    line(absolute, 30, 30)
    line(absolute, 200, 150)
    arc(100, 70)
    forward(100)
    checkpoint(test)
    bezier(absolute, 150, 400, 100, 300, smoothing: auto)
    bezier(absolute, 500, 200, 600, 600, smoothing: 30)
    line(absolute, 10, 600)
  }
  
  #complexPath path {
    line(relative, 100, 50)
    bezier(absolute, 200, 100, 150, 50)
    bezier(100, 50, 75, 25, smoothing: 20)
    bezier(absolute, 400, 200, 350, 100, 300, 150)
    bezier(relative, 100, 50, 75, 25, 50, 75, smoothing: none)
  }
}
```

## Smoothing Behavior
When smoothing is enabled, the system automatically adds control points to ensure smooth angle transitions between path segments:

* **Auto smoothing** (`smoothing: auto`) - Uses 50% of the distance to the control point
* **Custom distance** (`smoothing: 20`) - Uses the specified distance in pixels
* **No smoothing** (`smoothing: none`) - No additional control points added

Smoothing is particularly useful for creating fluid animations where objects follow complex paths without sharp direction changes.

# programmable parameter types
 
* enum: `name:[value1, value2]`, example: `status: [hover, pressed, disabled, normal]` or with default `status: [hover, pressed, disabled, normal] = normal`
* range: `name:num..num`, example: `count:1..5` or with default `count:1..5 = 5`
* int: `count:int` - any integer, example `count:7` or `count:-1` or with default `delta:int = 0`
* uint: `count:uint` - any positive integer, example `count:7` or with default `count:uint = 5`
* flags: `mask:flags(bits)` - number of bits, example: `mask:flags(6)`
* string: `name="myname"`, string always have default value
* hex direction: `dir:hexdirection` - 0..5
* grid direction: `dir:griddirection`: 0..7
* bool: true/false or 0/1, example `disabled: true`
* color: `color:<color>` - 32bit color, example `color: 0xff0000ff` or `color: #f0f` or `red`
 
# Imports
Multianims can be imported by the following construct:
```
import "screens/helpers.manim" as "helpers"
```
external name (`helpers` in example above) can be used to reference programmables from external multianim. 
Works with palettes. Layouts will work as well.

# Conditionals
Conditions are defined by `@(...)` structure and can be specified once per element. Specify parameters that must be used for node to be built. Multiple nodes might be built. Use `parameter=>*` to match all.

* `@()` or `@if(...)` - match all provided
* `@(!param=>'value')` - match when `param` is not `value`
* `@ifstrict(...)` - must match all provided parameters from programmable. Missing parameters will NOT match.

examples:

```
#panel programmable(width:uint=180, height:uint=30, mode:[idle,pressed]=pressed) {
     @(mode=>idle) ninepatch("ui", "Droppanel_3x3_idle", $width, $height): 0,0
     @(mode=>pressed) ninepatch("ui", "Droppanel_3x3_pressed", $width, $height): 0,0
}
```
`@(mode=>idle)` matches whenever `mode` = `idle`. Other parameters do not matter.

`@ifstrict(mode=>idle)` will match nothing as `width` & `height` are not provided. For `@ifstrict` to work in this case use: `@ifstrict(mode=>idle, width=>*, height=>*)`

Range matches (for numbers):
* `@(key => greaterThan 30)` matches when `key` is 30 or more
* `@(key => lessThan 30)` matches when `key` is 30 or less
* `@(key => between 10..30)` matches when `key` is between inclusive 10 and 30

multi enum match:
* `@(key => [value1, value2])` matches when `key` is either `value1` or `value2`. Works with numbers as well.

# expressions
* `+` - addition
* `-` - subtraction
* `*` - multiplication
* `/` - division
* `%` - modulo (integer only)
* `div` - integer division, behaves the same as `/` with integers

## Ternary Operator

The ternary operator `?(condition) valueIfTrue : valueIfFalse` allows conditional expressions. The condition is wrapped in parentheses.

**Syntax:**
```
?(condition) trueValue : falseValue
```

**Comparison Operators:**
* `==` - equality
* `!=` - inequality
* `<` - less than
* `>` - greater than

**Examples:**
```
// Simple numeric ternary
alpha: ?($enabled) 1.0 : 0.5

// String comparison
color: ?($owner == "Player") #00ff00 : #ff0000

// Numeric comparison
scale: ?($health < 30) 0.8 : 1.0

// In filters
filter: pixelOutline(knockout, ?($team == "ally") blue : red, 0.9)

// Nested ternaries
value: ?($score > 100) 3 : ?($score > 50) 2 : 1

// With expressions
width: ?($count > 5) $count * 20 : $count * 30
```

References and parentheses are supported in all expressions.

Haxe style interpolated strings are supported  
```haxe
'Nice to meet you ${$name}, have a nice day'
```

`callback(name)` and `callback(name, index)` are available as expression - this requires code support. Callback enables code to insert text and tiles and prebuilt `h2d.Object`s into the elements.
`builderParam(name)` is also available and also requires code support. Builder params will enable `placeholder` to insert h2d.Object into the elements (e.g. checkboxes into panel with text, giving designer an ability to move checkbox around).

expression examples: 
* `$items + 5`
* `$width * 2 + 5`
* `($index % 5) * 25`
* `($index div 5) * 25`
* `callback("test") * 3` - callback must return int
* `placeholder(generated(cross(20, 20)), builderParameter("button2")):130,0`

## Updatable text
To enable updating text from code, text/htmltext nodes have to be marked as `(updatable)`, for example: 

```
#selectedName(updatable) text(pikzel, callback("selectedName"), 0xffffff12, center, 120): -4,6
```

Updatable text nodes are referenced by name in code and updated in response to UI events:

`.manim file`
```
#ui programmable() {
     
      #ButtonVal(updatable) text(dd, "This will get updated", #ffffff00): 5, 10
```      

`Haxe code`
```haxe
// ... build the "ui" MultiAnimBuilder using e.g. MacroUtils.macroBuildWithParameters
this.updatableText = ui.builderResults.getUpdatable("buttonVal");
this.updatableText.updateText("Button Clicked!");
```

## Updatable tile
To enable updating tile(=bitmap) from code, nodes have to be marked as `(updatable)`, for example: 

```
#bitmapToUpdate(updatable) bitmap(generated(color(20, 20, red)), left, top):10,80
```

# Layouts
Layouts are root only elements (same as `programmable`, `palette` and `paths`). Layouts are used by the code to position elements on screen. Layouts don't specify in which coordinate system they are defined, usually they are to be treated as offsets. Layout sequence can, for example, be used to position buttons in multiple rows.

Usage:
```
relativeLayouts {
  
}
```

### nodes:
* `grid: x,y {...}` - sets grid mode for layouts
* `offset: x,y {...}` sets offset for layouts (value added to all x and y coordinates)
* `hex:pointy(30,20) {...}` - sets hex coordinate system for all layouts members

### layout child nodes

* `#endpoint point: 600,10` - single point node, for example for setting "End turn" button

List of points, for positioning multiple elements (e.g. buttons, checkboxes)

```
#endpoints list {
        point: 250,20
        point: 450,20
        point: 10,20
        point: 10,20
}
```

Generated points, format `#name sequence($varName: from..to) point: xy`	

This example produces points (10,10), (20,10), (30,10) and (40,10)
```
#seq sequence($i: 1..4) point: grid(10*$i,10)	
```

See demo examples #13 for usage of layouts as repeatable iterator

# Palettes

Palettes are collection of colors that can be accessed by index. 2d palettes have colors organized in a grid, with rows representing either different coloring scheme or brightness/darkness.

example, normal palette:
```
#main palette {
  white 0xf12  0x332 0xfff
}
```
It has 4 colors which can be accessed by index values of 0..3.

example, 2d palette:
```
#main palette(2d, 4) {
  white 0xf12  0x332 0xfff
  red 0xf13  0x333 0xffa
}
```
It has 8 total colors, 2 rows with 4 colors each. `colorReplace` filter can use 2d palettes.

Palette can also be loaded from image file. These are always 2d palettes.

```
#file palette(file:"main-palette.png")
```

See demo examples #7 for palette usage example.

# Components
## ScrollList

Settings:
* `panelBuilder` - builder for the panel
* `itemBuilder` - builder for the items
* `scrollbarBuilder` - builder for the scrollbar

* `width` - width of the scroll list
* `height` - height of the scroll list
* `topClearance` - clearance from the top of the screen
* `scrollSpeed` - up/down scroll speed in pixels per second

## Dropdown
Settings:
* `transitionTimer` - time to transition between open & closed

## pixels
* `pixels (...)` - draws pixel-perfect primitives. Supported commands inside the block:
  * `line x1, y1, x2, y2, color` - draws a line
  * `rect x, y, width, height, color` - draws a rectangle
  * `filledRect x, y, width, height, color` - draws a filled rectangle
  * `pixel x, y, color` - draws a single pixel at (x, y) with the specified color

**Example:**
```
pixels (
    pixel 5,5, #f00
    pixel 7,7, #0f0
    pixel 9,9, #00f
    line 0,0, 10,10, #fff
    rect 2,2, 8,8, #0ff
    filledRect 3,3, 6,6, #ff0
) {
    scale: 8
    pos: 200, 80
}
```

## graphics
* `graphics (...)` - creates vector graphics using Heaps h2d.Graphics. Each element can have an optional position specified after the element using `:x,y` or `;` for default (0,0).

### Graphics Elements

All graphics elements follow the pattern: `elementType(color, style, ...params)` where:
- `color` - The color of the shape (required, first parameter)
- `style` - Either `filled` for filled shapes or a number for line width (required, second parameter)
- Additional parameters vary by element type

#### rect
* `rect(color, style, width, height)` - Draw a rectangle

**Styles:**
* `filled` - Filled rectangle
* `<number>` - Stroked rectangle with specified line width

**Examples:**
```
graphics (
    rect(#ff0000, filled, 100, 50);              // Filled red rectangle at (0,0)
    rect(#00ff00, 2, 80, 40):20,20               // Green outlined rectangle with 2px line at (20,20)
)
```

#### circle
* `circle(color, style, radius)` - Draw a circle

**Examples:**
```
graphics (
    circle(#0000ff, filled, 30);                 // Filled blue circle at (0,0)
    circle(#ff00ff, 1.5, 25):100,100            // Magenta outlined circle at (100,100)
)
```

#### ellipse
* `ellipse(color, style, width, height)` - Draw an ellipse

**Examples:**
```
graphics (
    ellipse(#ffff00, filled, 80, 40);           // Filled yellow ellipse at (0,0)
    ellipse(#00ffff, 2, 60, 30):50,50          // Cyan outlined ellipse at (50,50)
)
```

#### arc
* `arc(color, style, radius, startAngle, arcAngle)` - Draw an arc
  * `startAngle` - Starting angle in degrees
  * `arcAngle` - Arc angle in degrees (positive = clockwise)

**Examples:**
```
graphics (
    arc(#ff0000, 2, 50, 0, 90);                 // Red quarter-circle arc with 2px line
    arc(#0000ff, filled, 40, 45, 180):100,50   // Blue filled arc starting at 45°
)
```

#### roundrect
* `roundrect(color, style, width, height, radius)` - Draw a rectangle with rounded corners
  * `radius` - Corner radius in pixels

**Examples:**
```
graphics (
    roundrect(#ffaa00, filled, 100, 60, 10);    // Filled orange rounded rectangle
    roundrect(#aa00ff, 2, 80, 40, 15):120,80   // Purple outlined rounded rectangle
)
```

#### polygon
* `polygon(color, style, x1, y1, x2, y2, ...)` - Draw a polygon with any number of points
  * Minimum 3 points required
  * Points are specified as x,y coordinate pairs

**Examples:**
```
graphics (
    polygon(#ff0000, filled, 0,0, 50,0, 25,50);              // Red filled triangle
    polygon(#0000ff, 2, 10,10, 60,10, 80,40, 40,60, 10,40):100,50  // Blue outlined pentagon
)
```

### Complete Graphics Example
```
graphics (
    rect(#ff0000, filled, 100, 50);              // Filled red rectangle at origin
    circle(#00ff00, 2, 30):120,25                // Green circle outline at (120,25)
    ellipse(#0000ff, filled, 80, 40):200,25      // Blue filled ellipse
    arc(#ffff00, 1.5, 40, 0, 180):300,50        // Yellow arc
    pie(#ff00ff, 45, 90, 120):400,50            // Magenta pie slice
    pie(#00ffff, 45, 0, 90, 20):500,50          // Cyan donut segment
    roundrect(#ff8800, filled, 80, 50, 10):50,120  // Orange rounded rectangle
    polygon(#8800ff, filled, 0,0, 40,0, 40,40, 0,40):150,120  // Purple square
)
```

### Position Syntax
Each graphics element must be followed by either:
* `;` - Element positioned at (0,0) relative to the graphics object
* `:x,y` - Element positioned at (x,y) relative to the graphics object

