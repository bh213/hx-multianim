# .anim Format Reference

Quick-lookup reference of all declarations, elements, and features in the `.anim` state animation format.

Free-form layout — newlines are whitespace. Comments: `//` line, `/* */` block.

---

## File Structure

| Declaration | Syntax | Description |
|-------------|--------|-------------|
| `sheet` | `sheet: sheetName` | Sprite sheet name (loads `sheetName.atlas2`). Required. Before animations |
| `states` | `states: name(v1, v2), name2(a, b)` | State variables and allowed values. Before animations |
| `center` | `center: x, y` | Default center point for all animations |
| `fps` | `fps: N` | Default frames per second. Before animations |
| `loop` | `loop: yes \| no \| N` | Default loop behavior. Before animations |
| `flipX` | `flipX: yes \| no` | Default horizontal flip. Before animations |
| `flipY` | `flipY: yes \| no` | Default vertical flip. Before animations |
| `allowedExtraPoints` | `allowedExtraPoints: [name1, name2]` | Declare valid extra point names. Before animations |
| `@final` | `@final NAME = expr` | Immutable named constant. Before animations |
| `metadata` | `metadata { ... }` | Key-value metadata block. Before animations |
| `animation` | `animation name { ... }` | Full animation block |
| `anim` | `anim name(modifiers): "sheet"` | Compact single-sheet shorthand |

**Ordering rule:** `sheet`, `states`, `fps`, `loop`, `allowedExtraPoints`, `@final`, and `metadata` must all appear before any `animation` or `anim` declaration.

---

## @final Constants

```anim
@final OFFSET_X = 5
@final SPEED = 1.5
@final NEG = -5
@final DOUBLE = $HALF
@final NEG_X = -$HALF
```

| Feature | Description |
|---------|-------------|
| Integer values | `@final X = 42` |
| Float values | `@final SPEED = 1.5` |
| Negative values | `@final NEG = -5` |
| Reference other constants | `@final Y = $X` (must be defined before) |
| Negative reference | `@final NEG_X = -$X` |
| Usage in coordinates | `fire: $OFFSET_X, $OFFSET_Y` |

---

## Metadata Block

```anim
metadata {
    spriteWidth: 64
    speed: 1.5
    description: "Marine unit"
    tint: #FF0000
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
    @default damage: 10
}
```

### Value Types

| Type | Syntax | Example |
|------|--------|---------|
| Integer | bare number | `spriteWidth: 64` |
| Float | number with `.` | `speed: 1.5` |
| String | quoted | `description: "Marine unit"` |
| Color | `#RGB`, `#RRGGBB`, `#RRGGBBAA` | `tint: #FF0000` |

### Metadata API (`AnimMetadata`)

| Method | Return | Description |
|--------|--------|-------------|
| `getIntOrDefault(key, default, ?stateSelector)` | `Int` | Integer value, falls back to default |
| `getIntOrException(key, ?stateSelector)` | `Int` | Integer value, throws if missing |
| `getFloatOrDefault(key, default, ?stateSelector)` | `Float` | Float value (also accepts int) |
| `getFloatOrException(key, ?stateSelector)` | `Float` | Float value, throws if missing |
| `getStringOrDefault(key, default, ?stateSelector)` | `String` | String value (coerces int/float/color) |
| `getStringOrException(key, ?stateSelector)` | `String` | String value, throws if missing |
| `getColorOrDefault(key, default, ?stateSelector)` | `Int` | Heaps `0xAARRGGBB` (alpha first); runtime preserves alpha verbatim |
| `getColorOrException(key, ?stateSelector)` | `Int` | Color value, throws if missing |

Access via `parsed.metadata` where `parsed` is an `AnimParserResult`.

---

## Animation Block

### Full Form

```anim
animation name @(direction=>l) {
    fps: 10
    loop: yes
    center: 32, 48
    playlist { ... }
    extrapoints { ... }
    filters { ... }
}
```

### Fields

| Field | Description |
|-------|-------------|
| `name` | Name in header (`animation idle {`) or body (`name: idle`). If both, must match |
| `fps` | Frames per second (inherits file-level default if omitted) |
| `loop` | `yes`/`true` = forever, `no`/`false` = none, `N` = loop N times (inherits default) |
| `center` | Per-animation center point override |
| `playlist` | Frame sequence (required, at least one) |
| `extrapoints` | Named coordinate points |
| `filters` | Typed filter declarations |
| `flipX` | `yes`/`no` — horizontally flip all frames in place. Sprite keeps the same untrimmed screen footprint; trim offsets and extrapoints auto-mirror. Inherits file-level default. All frames must share the same untrimmed size (parse-time error otherwise) |
| `flipY` | `yes`/`no` — vertically flip all frames in place. Sprite keeps the same untrimmed screen footprint; trim offsets and extrapoints auto-mirror. Inherits file-level default. All frames must share the same untrimmed size (parse-time error otherwise) |

### Compact Shorthand

```anim
anim name: "sheetName"
anim name(fps: 10): "sheetName"
anim name(fps: 10, loop: yes): "sheetName"
anim name(loop: 3): "sheetName"
anim name(fps: 10, flipX: yes): "sheetName"
```

Creates a full animation with a single sheet playlist entry. `fps`, `loop`, `flipX`, and `flipY` can be in parentheses or inherited from file-level defaults.

---

## Playlist Elements

| Element | Syntax | Description |
|---------|--------|-------------|
| Sheet (all frames) | `sheet: "spriteName"` | All frames with that name from atlas |
| Sheet (frame range) | `sheet: "name" frames: 1..5` | Frames 1 through 5 |
| Sheet (with duration) | `sheet: "name" duration: 100ms` | Custom frame duration in ms |
| Sheet (range + duration) | `sheet: "name" frames: 1..3 duration: 50ms` | Combined |
| File frame | `file: "filename.png"` | Single PNG image |
| File (with duration) | `file: "filename.png" duration: 100ms` | With custom duration |
| Event (trigger) | `event name` or `event name trigger` | Fire named trigger event |
| Event (point) | `event name x, y` | Fire event at coordinates |
| Event (random) | `event name random x, y, radius` | Fire at random point within radius |
| Event (metadata) | `event name { key:type => val, ... }` | Fire event with typed payload |
| Filter (per-frame) | `filter tint: #FF0000` | Set per-frame filter |
| Filter (clear) | `filter none` | Revert to animation-level filter |

### State Interpolation in Sheet Names

```anim
states: direction(l, r)
playlist { sheet: "marine_${direction}_walk" }
```

`${stateName}` is validated against defined states. Resolves at runtime.

### Event Metadata Types

| Type | Syntax |
|------|--------|
| Integer | `damage:int => 50` |
| Float | `speed:float => 1.5` |
| String | `type => "physical"` |
| Bool | `critical => true` or `critical => false` |
| Color | `color => #FF0000` |

---

## Extra Points

Named coordinates for effects, bullets, particles, etc. Must be declared in `allowedExtraPoints`.

```anim
extrapoints {
    fire: 5, -19
    @(direction=>l) targeting: -1, -12
    @else targeting: 5, -12
}
```

Coordinates support `$constant` references: `fire: $OFFSET_X, $FIRE_Y`.

---

## Filters

### Animation-Level Filters

Declared in `filters { }` block inside an animation. Applied when the animation plays. Support state conditionals.

```anim
filters {
    tint: #FF4444
    @(level >= 3) outline: 2.0, #FFFF00
    @else pixelOutline: #00FF00
}
```

### Filter Types

| Filter | Syntax | Description |
|--------|--------|-------------|
| `tint` | `tint: #RRGGBB` | Color multiply (sets `Drawable.color`) |
| `brightness` | `brightness: <float>` | 0 = black, 1 = normal |
| `saturate` | `saturate: <float>` | 0 = grayscale, 1 = normal |
| `grayscale` | `grayscale: <float>` | 0 = none, 1 = full grayscale |
| `hue` | `hue: <float>` | Hue rotation angle |
| `outline` | `outline: <size>, #color` | Stroke outline |
| `pixelOutline` | `pixelOutline: #color` | Pixel-level outline |
| `replaceColor` | `replaceColor: [#src1, #src2] => [#dst1, #dst2]` | Color replacement (lists must match length) |
| `none` | `none` | Clear all filters |

### Playlist-Level Filters (Per-Frame)

`filter` entries inside a playlist set or clear the active filter for subsequent frames.

```anim
playlist {
    filter tint: #FF0000
    sheet: "hit_01"          // tint active
    filter none
    sheet: "hit_02"          // no tint
}
```

Multiple per-frame filters accumulate. `filter none` reverts to animation-level filter (or clears if none).

---

## Conditionals

| Syntax | Description |
|--------|-------------|
| `@(state => value)` | Match when state equals value |
| `@(state != value)` | Negation |
| `@(state => [v1, v2])` | Match any of multiple values |
| `@(state != [v1, v2])` | Exclude multiple values |
| `@(state >= N)` | Greater than or equal (numeric) |
| `@(state <= N)` | Less than or equal |
| `@(state > N)` | Strictly greater than |
| `@(state < N)` | Strictly less than |
| `@(state => min..max)` | Range match (inclusive both ends) |
| `@else` | Fallback when preceding `@()` didn't match |
| `@else(state => value)` | Else-if with condition |
| `@default` | Final fallback (matches everything) |

### Where Conditionals Apply

| Context | Example |
|---------|---------|
| Animation block | `animation attack @(direction=>l) { ... }` |
| Playlist | `playlist @(direction=>r) { ... }` |
| Extra points | `@(direction=>l) fire: -2, -2` |
| Metadata | `@(level >= 3) damage: 50` |
| Filters | `@(level >= 3) outline: 2.0, #FFFF00` |

Multiple `@()` on the same animation are combined with AND logic.

---

## Haxe API

### Loading and Creating AnimationSM

```haxe
// Via ResourceLoader (recommended — caches result)
var parsed:AnimParserResult = resourceLoader.loadAnimParser("marine.anim");

// Direct parsing
var parsed:AnimParserResult = AnimParser.parseString(content, "marine.anim", resourceLoader);

// Create initial state selector
var stateSelector:AnimationStateSelector = [];
for (key => values in parsed.definedStates)
    stateSelector.set(key, values[0]);

// Create animation state machine
var animSM:AnimationSM = parsed.createAnimSM(stateSelector);
scene.addChild(animSM);
```

### AnimParserResult Interface

| Member | Type | Description |
|--------|------|-------------|
| `definedStates` | `Map<String, Array<String>>` | State names → allowed values |
| `metadata` | `Null<AnimMetadata>` | Parsed metadata (null if no metadata block) |
| `createAnimSM(selector)` | `AnimationSM` | Create animation state machine |

### AnimationSM API

| Member | Type | Description |
|--------|------|-------------|
| `play(name)` | `Void` | Play named animation |
| `isFinished()` | `Bool` | Check if current animation completed |
| `getCurrentAnimName()` | `Null<String>` | Current animation name |
| `getCurrentFrame()` | `Null<AnimationFrame>` | Current displayed frame |
| `getExtraPoint(name)` | `Null<h2d.col.IPoint>` | Get named extra point for current state |
| `getExtraPointForAnim(pointName, animState)` | `Null<h2d.col.IPoint>` | Get extra point for specific animation |
| `getExtraPointNames()` | `Array<String>` | All extra point names |
| `update(dt)` | `Void` | Manual update (when `externallyDriven = true`) |
| `paused` | `Bool` | Pause/resume playback |
| `externallyDriven` | `Bool` | If true, must call `update(dt)` manually. Also settable from `.manim` via the `stateanim construct("state", externallyDriven, ...)` flag — see `docs/manim.md` "stateanim construct" |
| `playWhenHidden` | `Bool` | Continue animating when not visible |
| `onFinished` | `() -> Void` | Callback when animation finishes |
| `onAnimationEvent` | `(AnimationEvent) -> Void` | Callback for playlist events |

### AnimationEvent Enum

| Variant | Description |
|---------|-------------|
| `Trigger(data:Dynamic)` | Named trigger event (data is the event name string) |
| `TriggerData(name:String, meta:Map<String, String>)` | Trigger with typed metadata |
| `PointEvent(name:String, point:h2d.col.IPoint)` | Point event at coordinates |

`random` events are resolved to `PointEvent` with randomized coordinates at runtime.

```haxe
animSM.onAnimationEvent = (event) -> {
    switch event {
        case Trigger(name):
            trace('Event: $name');
        case TriggerData(name, meta):
            var damage = meta.get("damage");
        case PointEvent(name, point):
            var global = animSM.localToGlobal(point.toPoint());
    }
};
```

### Changing States

```haxe
stateSelector.set("direction", "r");
animSM = parsed.createAnimSM(stateSelector);
```

---

## stateAnim construct (inline in .manim)

For simple animations without a separate `.anim` file:

```manim
stateAnim construct("initialState",
    "state1" => sheet "sheetName", tileName, fps, loop
    "state2" => sheet "sheetName", tileName, fps
)
```

**When to use:** Simple ad-hoc animations with a few states needing only sheet, FPS, and loop. Use `.anim` files for complex animations with events, extra points, metadata, state interpolation, and filters.
