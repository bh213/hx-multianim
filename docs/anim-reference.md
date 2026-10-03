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
| `layers` | `layers: shadow, body, hat` | The file's layers, drawn bottom first; its animations are then written in `layer` blocks (see Layers). Before animations |
| `@final` | `@final NAME = expr` | Immutable named constant. Before animations |
| annotation | `@name` or `@name(value, key: value)` | Kept for tools, never acted on. Before an animation it is the animation's; anywhere else at the top level, the file's |
| `metadata` | `metadata { ... }` | Key-value metadata block. Before animations |
| `animation` | `animation name { ... }` | Full animation block |
| `anim` | `anim name(modifiers): "sheet"` | Compact single-sheet shorthand |

**Ordering rule:** `sheet`, `states`, `fps`, `loop`, `allowedExtraPoints`, `@final`, and `metadata` must all appear before any `animation` or `anim` declaration.

**Strings:** quoted strings must be closed before end of file — an unclosed
string is a positioned `Unterminated string` error at the opening quote.
Embedded newlines are legal string content and count toward line numbers.

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

## Annotations

```anim
@pack("Creatures")
sheet: "lib/Creatures/wolf"

@from("Beasts/Wolf/WolfWalk.png", grid: 32, rows: direction)
@from(layer: shadow, "Beasts/Wolf/_Shadows/ShadowWolfWalk.png")
animation walk { fps: 5 loop: yes playlist { sheet: "wolf_walk_${direction}" } }
```

An annotation is for tools: the engine keeps it and never acts on it, so a tool can write down
in the file what it needs to know about it (where the frames were cut from, who made them).

| Rule | |
|------|--|
| Where | At the top level. Before `animation` or `anim` it belongs to that animation; before anything else, or after the last animation, to the file |
| Name | Any word but `final`, `else` and `default` |
| Values | Comma-separated: numbers, quoted strings, bare words (read as strings), colours, `[lists]`; a value may have a key, `grid: 32`, given once |
| Reading | `parsed.loaded().annotations` (the file's) and `loaded().animations[i].annotations`, each `{name, args, named, line, col}` with `MetadataValue`s |

`@(`, `@else` and `@default` stay conditions: they are not annotations, and at the top level they
are errors.

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
| List of words | `[word, "quoted", 3]` | `tags: [beast, wolf]` |

Color literals follow the same strict-D semantics as `.manim`: `#RGB` and
`#RRGGBB` bake opaque alpha (`#FF0000` is stored as `0xFFFF0000`); `#RRGGBBAA`
keeps its explicit alpha (`#FF000080` → `0x80FF0000`).

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
| `getListOrDefault(key, default, ?stateSelector)` | `Array<String>` | List of words; a single string is a list of one |
| `getListOrException(key, ?stateSelector)` | `Array<String>` | List of words, throws if missing |

`getString*` of a list gives its words joined by `, `; the number and colour getters throw on a list.

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

## Layers

```anim
sheet: "lib/NPCs/guard"
states: direction(se, sw, ne, nw), hat(none, hood, cap)
layers: shadow, body, hat, glow        // drawn in this order, bottom first
center: 16, 28
fps: 5

animation walk {
    loop: yes
    layer body { sheet: "body_walk_${direction}" }                  // the timeline
    layer shadow { sheet: "shadow_walk_${direction}" }
    layer hat @(hat != none) { sheet: "hat_${hat}_walk_${direction}" }
    layer glow { sheet: "glow_walk_${direction}" blend: add }
}
```

A character that changes its equipment is several pictures drawn on one another, frame for
frame. With `layers:` a file draws one clip per layer, and every layer shows the same frame of the
animation's **timeline**: one clock, so they cannot drift apart.

| Rule | |
|------|--|
| `layers: a, b, c` | The file's layers, bottom first. Before animations. With it, every animation is written in layer blocks (no `playlist`, no `anim` shorthand) |
| `layer name @(cond) { … }` | A layer's frames, in any order in the animation, conditional as playlists are (`@else`, `@default`, most specific wins). A name `layers:` does not declare is an error |
| The timeline | `timeline: name` in the animation, or else the first of `layers:` that has a block in it. Its frames, durations, events and `filter` lines are the animation's; its blocks must cover every combination of states |
| Other layers | `sheet:` and `file:` lines only, with `frames:` and `offset:`; `duration:`, `event` and `filter` are errors. Each must have as many frames as the timeline for every combination of states (checked when the state machine is made, naming the layer and the states). A layer no block matches draws nothing |
| `blend: add` | In a layer block: the names `.manim`'s `blendMode:` takes, without regard to case: `none`, `alpha` (the default), `add`, `alphaAdd`, `softAdd`, `multiply`, `alphaMultiply`, `erase`, `screen`, `sub`, `max`, `min` |
| The whole | `center`, `flipX`/`flipY`, the animation's `filters { }` (on all layers together) and `extrapoints` belong to the animation |

In code, `sm.layer("hat")` is a layer's clip (to hide, tint, read); `sm.clip` is the timeline's.
`sm.setState("hat", "cap")` changes the hat while walking, and `sm.detachLayer("shadow", mapShadows)`
draws the shadow in another object so every shadow is under every character (see the API below).

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
| Nudge | `sheet: "name" offset: 1, -2` | The line's frames drawn that many pixels over (x right, y down). Also on `file:` lines |
| Event (trigger) | `event name` or `event name trigger` | Fire named trigger event |
| Event (point) | `event name x, y` | Fire event at coordinates |
| Event (random) | `event name random x, y, radius` | Fire at random point within radius |
| Event (metadata) | `event name { key:type => val, ... }` | Fire event with typed payload |
| Filter (per-frame) | `filter tint: #FF0000` | Set per-frame filter |
| Filter (clear) | `filter none` | Revert to animation-level filter |

An event carries EITHER a point/random spec OR a metadata block, not both —
`event name x,y { meta }` is a parse error (the payload cannot hold both).

After `sheet:` the line may have `frames:`, `duration:` and `offset:`, and after `file:` the
last two: each at most once, in any order, commas between them optional. An `offset:` is added
before `flipX`/`flipY`, so a flipped animation mirrors the nudge with the art.

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

Multiple `@()` on the same animation are combined with AND logic. `@else` /
`@default` cannot follow a `@()` in the same header (parse error — the
combination has no defined meaning).

Comparison (`>=`, `<=`, `>`, `<`) and range (`min..max`) conditionals are
validated at parse time: the operands must be numeric, and the compared state
must declare at least one numeric value — otherwise the arm could never match
and the file is rejected.

Reachability is also validated at parse time: every animation, playlist, and
extra point must be selectable for at least one combination of declared state
values. An entry fully shadowed by a more specific sibling (e.g. an
unconditional `playlist { }` after a `playlist @(direction=>[l, r])` that wins
for every state) is rejected with a `... not reachable` error.

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
| `loaded()` | `LoadedAnimation` | What the file says, as written: for tools (below) |

### What the file says, for tools (`loaded()`)

`LoadedAnimation` is the file as written, not as played: `sheet`, `states`, `allowedExtraPoints`,
`center`, `metadata` (the API above) and `metadataEntries` (every entry by key, with its states),
`animations` (each `AnimationState` as parsed, with its `annotations`), `defaults` (the file-level
`fps`, `loop`, `flipX`, `flipY`), the file's `annotations`, and `spans`. The arrays and maps are
the parser's own: read them, never change them.

`spans` are kept only when the parse asks for them, `AnimParser.parseString(text, name, loader, true)`
(or `parseFile`'s same last argument): a game's parse has none, and a tool that changes a value in
place asks. The rest of `loaded()` is there either way.

A span is `{path, start, end, line, col}`: where a value is written, `start` the offset of its
first character and `end` just past its last, so a tool can change one value and leave the rest of
the file as it was. Its `path`:

| Path | What it covers |
|------|----------------|
| `sheet`, `states`, `center`, `fps`, `loop`, `flipX`, `flipY`, `allowedExtraPoints` | The value |
| `metadata` | The block, from `metadata` to `}` |
| `metadata.<key>#<n>` | The value of the key's n-th entry |
| `@<name>#<n>` | The file's n-th annotation of that name, whole |
| `animations.<i>` | The i-th animation, from `animation` (or `anim`) to its end |
| `animations.<i>.name`, `.fps`, `.loop`, `.flipX`, `.flipY` | The value |
| `animations.<i>.@<name>#<n>` | The animation's annotation, whole |
| `animations.<i>.extrapoints`, `.filters` | The block |
| `animations.<i>.extrapoints.<point>#<n>` | The point's n-th coordinates |
| `animations.<i>.playlist#<p>` | The p-th playlist block |
| `animations.<i>.playlist#<p>.<j>` | Its j-th line (the j-th of the playlist's `anims`) |
| `….<j>.sheet`, `.file`, `.frames`, `.duration`, `.offset`, `.at` | A part of the line; `.at` is an event's point |

`#<n>` counts from 0 in the file's order; `<i>` indexes `loaded().animations`. An `anim` shorthand
is `animations.<i>` with `.name`, its modifiers, and `.playlist#0.0.sheet`.

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
| `onFinished` | `() -> Void` | Callback when animation finishes (fires once per completed playback) |
| `onAnimationEvent` | `(AnimationEvent) -> Void` | Callback for playlist events. A handler may call `play()`; the new animation then starts at its own first frame |
| `setState(name, value)` | `Void` | Changes one state while playing. The animations are reloaded for the new states; if the one playing has as many frames and events as before it goes on from the same frame and time, otherwise it starts again. A load that fails (frames the sheet has not for the new states) throws and leaves the machine as it was, playing what it played. Needs a machine made by `createAnimSM` |
| `setStates(map)` | `Void` | Several states at once |
| `seek(stateIndex)` | `Void` | Shows the playing animation at a state and stays there, paused (scrubbing): the frame at or before it on every layer, the per-frame filters up to it, no event |
| `currentSelector` | `AnimationStateSelector` | The states it plays |
| `clip` | `AnimationClip` | The clip drawing the frames; in a layered file, the playing animation's timeline |
| `layerNames` | `Array<String>` | A layered file's `layers:`, bottom first |
| `layer(name)` | `Null<AnimationClip>` | A layer's clip: hide it, tint it, read its frame |
| `detachLayer(name, parent)` | `Void` | Draws the layer inside `parent` (a map's shadow layer), placed where it would have been (position and scale) on every sync, still on the same frame; the animation's filter goes with it, on the layer alone. Hidden while the machine or anything above it is hidden, as it would be among the layers; `layer(name).visible = false` from the game holds |
| `attachLayer(name)` | `Void` | Puts a detached layer back in its place |

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
