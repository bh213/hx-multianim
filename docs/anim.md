# .anim Format Reference

State animation is an animation that can be in different states and have different animations running based on those states.

For example, an animation can have an animation named `running` with state `direction(l,r)`. When `l` is set, animation displays running to the left; when `r` is set, animation is running to the right.

The `.anim` format uses **free-form layout** — newlines are whitespace, so declarations can span multiple lines or be on a single line.

## Basic Structure

```anim
sheet: sheetName
states: stateName(value1, value2)
center: x,y
allowedExtraPoints: [point1, point2]
fps: 20

@final OFFSET_X = 5

metadata {
    key: value
    @(state=>value) conditionalKey: value
}

animation animationName {
    fps: 20
    loop: yes | <number>
    playlist {
        sheet: "sprite_${state}_name"
        event <name> trigger | random x,y,radius | x,y
    }
    extrapoints {
        @(state=>value) pointName: x,y
        @else pointName: x,y
    }
}
```

## Example

```anim
sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48
fps: 20

@final FIRE_Y = -12

metadata {
    spriteWidth: 64
    spriteHeight: 48
    speed: 1.5
    tint: #FF0000
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
}

animation idle {
    fps: 4
    loop: yes
    playlist {
        sheet: "marine_${direction}_idle"
    }
    extrapoints {
        @(direction=>l) targeting: -1, $FIRE_Y
        @else targeting: 5, $FIRE_Y
    }
}
```

---

## Top-Level Declarations

### sheet
Specifies the sprite sheet name. Must be defined before animations. The sheet is loaded via `ResourceLoader.loadSheet2()` which looks for an `.atlas2` file.

```anim
sheet: crew2
```

The `ResourceLoader` will load `crew2.atlas2` which references the actual PNG file(s) containing the sprites. The atlas2 format (compatible with TexturePacker) defines sprite regions within the image:

```
crew2-0.png
size: 256, 1847
format: RGBA8888

marine_l_idle
  xy: 1, 100
  size: 64, 48
  orig: 64, 48
  offset: 0, 0
  index: 0
marine_l_idle
  xy: 65, 100
  size: 64, 48
  orig: 64, 48
  offset: 0, 0
  index: 1
```

When you reference `sheet: "marine_l_idle"` in a playlist, the library looks up all sprites with that name in the atlas and creates animation frames from them, ordered by their `index` value.

### states
Defines state variables and their allowed values. Must be defined before animations.

```anim
states: direction(l, r)
states: direction(l, r), color(red, blue, green)
```

### center
Optional center point for the animation. Can be set at file level (applies to all animations) or per-animation.

```anim
center: 32,48
```

### fps (file-level default)
Optional default frames per second. Individual animations can override this. Must be defined before animations.

```anim
fps: 20
```

### loop (file-level default)
Optional default loop behavior. Individual animations can override this. Must be defined before animations.

```anim
loop: yes
loop: 3
loop: no
```

### allowedExtraPoints
Declares valid extra point names that can be used in animations.

```anim
allowedExtraPoints: [fire, targeting, impact]
```

### @final (named constants)
Declares immutable named constants that can be referenced as `$NAME` in coordinate values. Must be defined before animations.

```anim
@final OFFSET_X = 5
@final OFFSET_Y = -10
@final HALF = 32
@final NEG = -$HALF
```

Constants support:
* Integer and float values: `@final X = 42`, `@final SPEED = 1.5`
* Negative values: `@final NEG = -5`
* References to other constants: `@final DOUBLE = $HALF` (order-dependent — referenced constant must be defined first)
* Negative references: `@final NEG_X = -$X`
* Used in coordinates: `fire: $OFFSET_X, $OFFSET_Y`

### metadata
Key-value pairs for storing animation metadata such as sprite dimensions, speeds, colors, etc. Supports conditional values based on state.

```anim
metadata {
    spriteWidth: 64
    spriteHeight: 48
    speed: 1.5
    tint: #FF0000
    fireFrame: 3
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
    @(level >= 3) damage: 50
    @else damage: 30
    description: "Marine unit"
}
```

**Value types:**
* Integers: `spriteWidth: 64`
* Floats: `speed: 1.5`
* Strings: `description: "Marine unit"` (quoted)
* Colors: `tint: #FF0000` (`#RGB`, `#RRGGBB`, or `#RRGGBBAA`)

**Conditional metadata:**
Use `@(state=>value)` to define state-specific values:
```anim
@(direction=>l) fireOffsetX: -5
@(direction=>r) fireOffsetX: 5
@(level >= 3) damage: 50
@default damage: 30
```

**Accessing metadata in code:**
```haxe
var loadedAnim:LoadedAnimation = AnimParser.parseFile(...);
var stateSelector:AnimationStateSelector = ["direction" => "l"];

// Integer
var fireX = loadedAnim.metadata.getIntOrDefault("fireOffsetX", 0, stateSelector);
var width = loadedAnim.metadata.getIntOrDefault("spriteWidth", 32);

// Float
var speed = loadedAnim.metadata.getFloatOrDefault("speed", 1.0, stateSelector);

// String
var desc = loadedAnim.metadata.getStringOrDefault("description", "Unknown");

// Color (returns 0xRRGGBB or 0xAARRGGBB int)
var tint = loadedAnim.metadata.getColorOrDefault("tint", 0xFFFFFF, stateSelector);

// OrException variants throw if key is missing
var dmg = loadedAnim.metadata.getIntOrException("damage", stateSelector);
var spd = loadedAnim.metadata.getFloatOrException("speed");
var col = loadedAnim.metadata.getColorOrException("tint");
```

---

## Animation Block

Each animation block defines a named animation with its properties.

### Naming

The animation name can be specified in the header or in the body:

```anim
// Name in header (compact form, preferred)
animation idle {
    fps: 4
    loop: yes
    playlist { ... }
}

// Name in body (legacy form, still supported)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { ... }
}
```

Both forms are equivalent. If both are provided, they must match.

### Fields

* `name` - Unique animation name (in body, or as header keyword)
* `fps` - Frames per second for playlist (inherits file-level default if omitted)
* `loop` - Looping behavior: `yes`/`true` (forever), `no`/`false` (no loop), `<number>` (loop N times), or inherits file-level default
* `playlist` - List of frames and events
* `center` - Center point for this specific animation
* `extrapoints` - Points of interest (e.g., particle effects, bullets)
* `filters` - Filter declarations for the animation

### Compact Shorthand (`anim`)

For simple single-sheet animations, use the `anim` shorthand:

```anim
anim name: "sheetName"
anim name(fps: 10): "sheetName"
anim name(fps: 10, loop: yes): "sheetName"
anim name(loop: 3): "sheetName"
```

This creates a full animation with a single sheet playlist entry. `fps` and `loop` can be specified as modifiers in parentheses, or inherited from file-level defaults.

---

## Playlist Elements

### Sheet Frame

```anim
sheet: "myanimation"
sheet: "myanimation" frames: 1..2
sheet: "myanimation" frames: 1..2 duration: 25ms
sheet: "marine_${direction}_idle"
```

* Uses default `fps` setting when duration not specified
* Takes all frames with the name from the atlas sheet
* `${stateName}` — State variable interpolation in sheet names (validated against defined states)

### File Frame

```anim
file: "filename.png"
file: "filename.png" duration: 100ms
```

Loads and plays a single frame PNG image.

### Events

```anim
event <name> trigger
event <name>
event <name> x,y
event <name> random x,y,radius
```

* `trigger` - fires event with specific name. The `trigger` keyword is optional — bare `event <name>` produces the same result
* `x,y` - fires point event at coordinates
* `random x,y,radius` - fires event at random point within radius of (x,y)

**Event metadata** — events can carry typed metadata in a block:

```anim
event impact { damage:int => 50, type => "physical", color => #FF0000 }
event spawn { count:int => 3, speed:float => 1.5 }
```

Metadata supports typed values: `key => val` (string), `key:int => N`, `key:float => N`, `key => true`/`false` (bool), `key => #RRGGBB` (color).

---

## Extra Points

Extra points are named coordinates where other animations or code interacts with sprites. They can represent impact points, bullet sources, particle effect origins, etc.

```anim
extrapoints {
    fire: 5, -19
    @(direction=>l) targeting: -1, -12
    @(direction=>r) targeting: 5, -12
}
```

Coordinates support `$constant` references:

```anim
@final FIRE_Y = -19

extrapoints {
    fire: 5, $FIRE_Y
}
```

---

## Filters

Animation blocks can declare typed filters that are applied at runtime. Filters support state conditionals.

### Supported filter types

| Filter | Syntax | Description |
|--------|--------|-------------|
| `tint` | `tint: #RRGGBB` | Color multiply (sets Drawable.color) |
| `brightness` | `brightness: <float>` | Lightness adjustment (0=black, 1=normal) |
| `saturate` | `saturate: <float>` | Saturation (0=grayscale, 1=normal) |
| `grayscale` | `grayscale: <float>` | Desaturation (0=none, 1=full grayscale) |
| `hue` | `hue: <float>` | Hue rotation angle |
| `outline` | `outline: <size>, #color` | Stroke outline |
| `pixelOutline` | `pixelOutline: #color` | Pixel-level outline |
| `replaceColor` | `replaceColor: [#src1, #src2] => [#dst1, #dst2]` | Color replacement |
| `none` | `none` | Clear all filters |

### Animation-level filters

Applied to the whole animation when it plays. Supports state conditionals.

```anim
animation idle {
    fps: 4
    loop: yes
    playlist { sheet: "marine_idle" }
    filters {
        tint: #FF4444
        brightness: 0.8
        @(level >= 3) outline: 2.0, #FFFF00
        @else pixelOutline: #00FF00
        replaceColor: [#FF0000, #00FF00] => [#0000FF, #FFFF00]
    }
}
```

### Playlist-level filters (per-frame)

`filter` entries inside a playlist act as state changes — they set or clear the active filter for subsequent frames.

```anim
animation hit {
    fps: 10
    playlist {
        sheet: "marine_hit_01"
        filter tint: #FF0000
        sheet: "marine_hit_02"
        filter none
        sheet: "marine_hit_03"
    }
}
```

`filter none` reverts to the animation-level filter (or clears if none defined).

Multiple per-frame filters accumulate:

```anim
playlist {
    filter tint: #FF0000
    filter outline: 1.0, #FFFFFF
    sheet: "frame_01"
    filter none
    sheet: "frame_02"
}
```

---

## Conditionals Based on State

Conditionals filter which animation, playlist, extrapoint, or metadata entry applies based on state values.

### Basic syntax

```anim
@(state=>value)             // Match when state equals value
@(state != value)           // Negation: match when state does NOT equal value
@(state=>[v1,v2,v3])       // Multi-value: match when state is any of v1, v2, v3
@(state != [v1,v2])         // Negated multi-value: match when state is NOT v1 or v2
@(state >= 3)               // Greater than or equal (numeric comparison)
@(state <= 3)               // Less than or equal
@(state > 3)                // Strictly greater than
@(state < 3)                // Strictly less than
@(state => 1..5)            // Range match (1 <= state <= 5, inclusive)
@else                       // Matches when preceding @() didn't match
@else(state=>value)         // Else-if with condition
@default                    // Final fallback (matches everything)
```

### Animation-level conditionals

```anim
animation attack @(direction=>l) @(color=>red) {
    ...
}

animation special @(direction != l) {
    ...
}
```

Only applied when the state conditions match. Multiple `@()` blocks on the same element are combined with AND logic.

### Extrapoint conditionals

```anim
extrapoints {
    @(direction=>l) fire: -2, -2
    @(direction=>r) fire: 2, -2
    @(direction=>[l,r]) targeting: 0, -12
    @(level >= 3) bonus: 5, 5
    @else bonus: 0, 0
    @default fallback: 10, 10
}
```

### Metadata conditionals

```anim
metadata {
    @(direction=>l) fireOffsetX: -5
    @(direction != l) fireOffsetX: 5
    @(level => 1..5) damage: 30
    @(level >= 6) damage: 50
    @default damage: 10
}
```

### Playlist conditionals

```anim
playlist @(direction=>l) {
    sheet: "marine_l_walk"
}
playlist @(direction=>r) {
    sheet: "marine_r_walk"
}
```

---

## State Variable Interpolation

Use `${stateName}` in sheet names to dynamically insert state values:

```anim
states: direction(l, r)

animation walk {
    playlist {
        sheet: "marine_${direction}_walk"
    }
}
```

When `direction` is `l`, this becomes `marine_l_walk`.
When `direction` is `r`, this becomes `marine_r_walk`.

State references are validated against defined states — using an undefined state name produces an error. The old `$$state$$` syntax is no longer supported and will produce an error with a migration hint.

---

## Complete Example

```anim
sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48
fps: 20

@final FIRE_Y = -19

metadata {
    spriteWidth: 64
    spriteHeight: 48
    speed: 1.5
    tint: #FF0000
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
}

animation idle {
    fps: 4
    loop: yes
    playlist {
        sheet: "marine_${direction}_idle"
    }
    extrapoints {
        @(direction=>l) targeting: -1, -12
        @else targeting: 5, -12
    }
}

animation fire-up {
    loop: 2
    playlist {
        sheet: "marine_${direction}_shooting_u"
        event fire trigger
    }
    extrapoints {
        fire: 5, $FIRE_Y
    }
}

animation walk {
    fps: 8
    loop: yes
    playlist {
        sheet: "marine_${direction}_walk"
    }
}

animation special-attack @(direction=>l) {
    fps: 12
    playlist {
        sheet: "marine_l_special"
    }
}

animation special-attack @(direction=>r) {
    fps: 12
    playlist {
        sheet: "marine_r_special"
    }
}

// Compact shorthand for simple animations
anim stand(fps: 1, loop: yes): "marine_l_standing"
```

---

## Haxe Usage Examples

### Loading and Creating AnimationSM

```haxe
import bh.stateanim.AnimParser;
import bh.stateanim.AnimParser.AnimationStateSelector;
import bh.stateanim.AnimationSM;

// Load and parse the .anim file
var parsed = resourceLoader.loadAnimParser("marine.anim");

// Create initial state selector
var stateSelector:AnimationStateSelector = [];
for (key => values in parsed.definedStates) {
    stateSelector.set(key, values[0]); // Set first value as default
}

// Create the animation state machine
var animSM:AnimationSM = parsed.createAnimSM(stateSelector);

// Add to scene
scene.addChild(animSM);
animSM.setScale(3.0);
```

### Playing Animations

```haxe
// Play a specific animation
animSM.play("idle");

// Play an animation and do something when it finishes
animSM.play("fire-up");
animSM.onFinished = () -> {
    animSM.play("idle");
};

// Check if animation has finished
if (animSM.isFinished()) {
    animSM.play("walk");
}

// Get current animation name
var currentAnim = animSM.getCurrentAnimName();
```

### Handling Animation Events

```haxe
animSM.onAnimationEvent = (event) -> {
    switch event {
        case Trigger(name):
            trace('Event triggered: $name');
        case TriggerData(name, meta):
            trace('Event $name with metadata');
            var damage = meta.get("damage"); // String value
        case PointEvent(name, point):
            var globalPoint = animSM.localToGlobal(point.toPoint());
            // Spawn effect at globalPoint
    }
};
```

### Accessing Metadata

```haxe
// Access metadata with state selector
var fireOffsetX = parsed.metadata.getIntOrDefault("fireOffsetX", 0, stateSelector);

// Access metadata without state (for non-conditional values)
var spriteWidth = parsed.metadata.getIntOrDefault("spriteWidth", 32);
var description = parsed.metadata.getStringOrDefault("description", "Unknown");

// Float metadata
var speed = parsed.metadata.getFloatOrDefault("speed", 1.0, stateSelector);

// Color metadata
var tint = parsed.metadata.getColorOrDefault("tint", 0xFFFFFF, stateSelector);
```

### Changing States at Runtime

```haxe
// Update state selector
stateSelector.set("direction", "r");

// Recreate animation with new state
animSM = parsed.createAnimSM(stateSelector);
```

### Manual Animation Update

```haxe
// Create externally driven animation
var animSM = parsed.createAnimSM(stateSelector);
animSM.externallyDriven = true;

// In your game loop, manually update the animation
function update(dt:Float) {
    animSM.update(dt);
}
```

---

## Inline Construction via .manim (stateAnim construct)

For simple state animations that don't need the full `.anim` file format, you can define animations inline in `.manim` files using `stateAnim construct`. This creates an `AnimationSM` directly from sheet references without a separate `.anim` file.

```manim
stateAnim construct("initialState",
  "state1" => sheet "sheetName", tileName, fps, loop
  "state2" => sheet "sheetName", tileName, fps
)
```

See [docs/manim.md](manim.md#stateanim-construct) for full syntax details.

**When to use `.anim` vs `construct`:**
* Use `.anim` files for complex animations with events, extra points, metadata, state interpolation (`${state}`), and playlist features
* Use `construct` for simple ad-hoc animations with a few states that only need sheet, FPS, and loop settings
