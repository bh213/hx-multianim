# .manim Language Quick Reference

## Programmable Elements

```manim
#name programmable(param:type=default) {
  transition {
      param: crossfade(0.1, easeOutQuad)
  }
  @(condition) element(params): x,y
}
```

**Parameter types**: `uint`, `int`, `float`, `bool`, `string`, `color`, `tile`, enum (`[val1,val2]`), range (`1..5`), flags

**Color format (strict-D)**: Internal storage is Heaps `0xAARRGGBB`. CSS `#` forms bake `0xFF` alpha on 3/6-digit shorthand (`#FF0000` → `0xFFFF0000`), alpha preserved on 8-digit `#RRGGBBAA`. Heaps `0x` forms preserve every byte verbatim — `0xFF0000` is transparent red (top byte = 0), not opaque. `transparent` / `0x00000000` is reachable from runtime code (`setColor(0)` no longer gets clobbered to opaque black). Migration from pre-strict-D: any `0xRRGGBB` literal meant for opaque → use `#RRGGBB` or `0xFFRRGGBB`.

**Transition types**: `none`, `fade(duration, ?easing)`, `crossfade(duration, ?easing)`, `flipX(duration, ?easing)`, `flipY(duration, ?easing)`, `slide(direction, duration, ?distance, ?easing)` (directions: `left`, `right`, `up`, `down`; distance defaults to 50px). Requires TweenManager (auto-injected via ScreenManager). Falls back to instant without TweenManager.

## Common Elements

| Element | Description |
|---------|-------------|
| `bitmap(source, [center])` | Display image. Source can be wrapped: `center(source)` or `pivot(x, y, source)` |
| `text(font, text, color, [align, maxWidth, options])` | Simple text element (plain `h2d.Text`). Options: `letterSpacing`, `lineSpacing`, `lineBreak`, `dropShadow*`, `autoFit` |
| `richText(font, text, color, [align, maxWidth, options])` | Rich text with `[markup]`, `styles:`, `images:` (always `h2d.HtmlText`). Options: same as text + `styles:`, `images:`, `condenseWhite` |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable |
| `placeholder(size, source)` | Dynamic placeholder |
| `staticRef($ref)` | Static embed of another programmable |
| `dynamicRef($ref, params)` | Dynamic embed with runtime `setParameter()` support |
| `dynamicRef($paramName, params)` | Dynamic embed where `$paramName` is a parameter naming the target programmable. Full rebuild on template change |
| `#name slot` / `#name[$i] slot` | Swappable container (indexed variant for repeatables) |
| `#name slot(param:type=default, ...)` | Parameterized slot with visual states |
| `spacer(w, h)` | Empty space inside `flow` containers |
| `interactive(w, h, id [, debug] [, key=>val ...])` | Hit-test region with optional metadata |
| `layers()` | Z-ordering container |
| `mask(w, h)` | Clipping mask rectangle |
| `flow(...)` | Layout flow container |
| `repeatable($var, iterator)` | Loop elements |
| `tilegroup` | Optimized tile grouping (supports `bitmap`, `ninepatch`, `repeatable`, `repeatable2d`, `pixels`, `point`) |
| `stateanim construct(...)` | Inline state animation |
| `point` | Positioning point |
| `apply(...)` | Apply properties to parent |
| `graphics(...)` | Vector graphics |
| `pixels(...)` | Pixel primitives |
| `particles {...}` | Particle effects |
| `@final name = expr` | Immutable named constant |
| `#name data {...}` | Static typed data block |
| `#name atlas2("file") {...}` | Inline sprite atlas |
| `curves {...}` | 1D curve definitions |
| `paths {...}` | Path definitions |
| `#name animatedPath {...}` | Animated path with curves/events |
| `import "file" as "name"` | Import external .manim |

## Conditionals

```manim
@(param=>value)           # Match when param equals value
@if(param=>value)         # Explicit @if (same as @())
@any(p1=>v1, p2=>v2)      # Match when ANY listed condition matches (OR)
@all(p1=>v1, p2=>v2)      # Match when ALL listed conditions match (AND, same as @())
@(param != value)         # Match when param NOT equals value
@(param=>[v1,v2])         # Match multiple values
@(param >= 30)            # Greater than or equal
@(param <= 30)            # Less than or equal
@(param > 30)             # Strictly greater than
@(param < 30)             # Strictly less than
@(param => 10..30)        # Range match (10 <= param <= 30)
@(param => bit[N])        # Bit flag test (checks if bit N is set)
@($loopVar => value)      # Match repeatable loop variable (inside repeatable body)
@($loopVar >= N)          # Range/comparison on loop variable
@($loopVar < $param)      # Comparison with $param reference (resolved at build time)
@else                     # Matches when preceding @() didn't match
@else(param=>value)       # Else-if with conditions
@default                  # Final fallback
```

All conditionals support **block form**: `@(cond) { ... }`, `@else { ... }`, `@default { ... }`. Blocks can be nested.

### @switch Block

Groups conditions on a single parameter — avoids repeating parameter name:

```manim
@switch(param) {
    value1: element(...);                    # Single enum value
    value2 | value3: element(...);            # Multiple values (OR)
    <= 10: element(...);                     # Comparison
    0..100: element(...);                    # Range
    default: element(...);                   # Fallback
    valueName {                              # Block arm (multiple elements)
        element1(...);
        element2(...);
    }
}
```

Supports nested `@()` conditionals inside block arms. Cannot combine with other `@` modifiers.

Works on discrete param types — `enum`, `int`, `uint`, `range`, `string` (quoted), `color` (`#RRGGBB`), `bool` (`true`/`false`). Rejects `float`, `tile`, `flags` at parse time. Range/comparison arms (`<= N`, `N..M`, ...) are numeric-only. Single-value arms use the same type-aware conversion as `@(p => value)`; pipe-separated arms use string-based `CoEnums` (same limitation as `@(p => [v1, v2])`).

## Expressions

- Operators: `+`, `-`, `*`, `/`, `%`, `div`
- References: `$paramName`
- Ternary: `?(condition) trueValue : falseValue`
- Callbacks: `callback("name")`, `callback("name", $index)`

## Coordinate Systems

- Offset: `x,y`
- Grid: `$grid.pos(x, y)` (requires `grid: spacingX, spacingY` in body)
- Grid properties: `$grid.width`, `$grid.height`
- Hex: `$hex.cube(q, r, s)`, `$hex.corner(index, scale)`, `$hex.edge(direction, scale)` (requires `hex: flat(w, h)` or `hex: pointy(w, h)` in body)
- Hex offset/doubled: `$hex.offset(col, row, even|odd)`, `$hex.doubled(col, row)`
- Hex properties: `$hex.width`, `$hex.height`
- Named systems: `grid: #name spacingX, spacingY`, `hex: #name flat(w, h)` / `hex: #name pointy(w, h)`
- Value extraction: `$grid.pos(x, y).x`, `$hex.corner(0, 1.0).y`
- Offset suffix: `.offset(x, y)` on any coordinate expression adds a pixel offset (e.g., `layout(name).offset(5, 10)`, `$grid.pos(1, 2).offset(3, 4)`)
- Context: `$ctx.width`, `$ctx.height`, `$ctx.random(min, max)`, `$ctx.font("name").lineHeight`, `$ctx.font("name").baseLine`
- Layout: `layout(layoutName [, index])`
- Extra point (from named stateanim): `$ref.extraPoint("pointName")`, `$ref.extraPoint("pointName", fallback: x, y)`
- Extra point (from .anim file): `extraPoint("file.anim", "animName", "pointName", "key"=>"value"...)`, with optional `fallback: x, y`

## Filters

`outline`, `glow`, `blur`, `saturate`, `brightness`, `grayscale`, `hue`, `dropShadow`, `replacePalette`, `replaceColor`, `pixelOutline`, `group`, custom filters via `FilterManager`

### Custom Filters

Register custom filters from game code, use them in `.manim` by name:

```haxe
FilterManager.registerFilter("perlinNoise", [
    {name: "seed", type: CFFloat, defaultValue: 0.0},
    {name: "scale", type: CFFloat, defaultValue: 10.0},
], (params) -> new PerlinNoiseFilter(params["seed"], params["scale"]));
```

```manim
filter: perlinNoise(42.0, 8.0)
filter: group(perlinNoise(42.0, 12.0), outline(1, #000000))
```

Param types: `CFFloat`, `CFColor`, `CFBool`. `$param` refs supported. Parsed opaque, validated at build time.

## Curves Quick Reference

```manim
curves {
    #name curve { easing: easingName }
    #name curve { points: [(0, 0), (0.5, 1.0), (1.0, 0)] }
    #name curve { [0.0 .. 0.5] easeInQuad, [0.5 .. 1.0] easeOutQuad }
    #name curve { multiply: [a, b] }        // a(t) * b(t), N-ary
    #name curve { apply: inner, outer }      // outer(inner(t))
    #name curve { invert: a }               // 1.0 - a(t)
    #name curve { scale: a, 1.5 }           // a(t) * factor
}
```

Operations reference other named curves **or built-in easing names** (e.g. `multiply: [easeInBack, envelope]`). Forward references and chaining allowed. Circular references error.

## Particles Quick Reference

```manim
#effectName particles {
    count: 100
    emit: point(dist: 0, distRand: 0) | cone(dist: N, distRand: N, angle: A, angleSpread: A) | box(w: N, h: N, angle: A, angleSpread: A) | circle(r: N, rRand: N, angle: A, angleSpread: A) | path(pathName [, tangent])
    tiles: file("particle.png")                          # also: center(file(...)), pivot(0.5, 1.0, file(...))
    loop: true
    maxLife: 2.0
    speed: 50
    speedRandom: 0.3
    gravity: 100
    gravityAngle: 90deg
    size: 0.5
    sizeRandom: 0.2
    blendMode: add | alpha
    fadeIn: 0.1
    fadeOut: 0.8
    forwardAngle: down
    colorStops: 0.0 #FF4400, 0.5 #FFAA00 easeInQuad, 1.0 #FFFF88
    sizeCurve: myCurveName | easeOutQuad
    velocityCurve: myCurveName | easeOutQuad
    forceFields: [turbulence(30, 0.02, 2.0), wind(10, 0), vortex(0, 0, 100, 150), attractor(0, 0, 50, 100), repulsor(0, 0, 80, 120), pathguide(myPath, 80, 120, 50)]
    bounds: kill, box(x: 0, y: 0, w: 800, h: 600)
    rotationSpeed: 90deg
    rotateAuto: true
    relative: true
    externallyDriven: true
    attachTo: animPathName
    spawnCurve: curveName
    animFile: "spark.anim"
    animSelector: type => fire
    0.0: anim("birth")
    0.8: anim("dying")
    onBounce: anim("impact")
    subEmitters: [{ groupId: "sparks", trigger: ondeath, probability: 0.8 }]
    shutdown: {
        duration: 1.0
        curve: easeOutQuad
        alphaCurve: easeInQuad
        sizeCurve: myCustomCurve
        speedCurve: linear
    }
}
```

**Angle units:** All angle properties accept `deg`, `rad`, `turn` suffixes. Bare numbers are degrees (backward compat). Direction constants: `right` (0°), `down` (90°), `left` (180°), `up` (270°). Expressions: `down + 10deg`.

**Emit named params:** `emit: cone(dist: 50, distRand: 10, angle: right, angleSpread: 90deg)`. Box supports `center: true` for centered spawning.

**Color stops:** `colorStops: 0.0 #FF0000, 0.5 #00FF00 easeInQuad, 1.0 #0000FF`. Each stop is `rate color [curve]`. Curve specifies interpolation to next stop.

**Bounds combined:** `bounds: kill, box(x: -50, y: -50, w: 250, h: 250), line(0, 0, 100, 0)`. Positional: `box(x, y, w, h)`.

**Property aliases:** `lifeRand`, `sizeRand`, `speedRand`, `speedIncr`/`acceleration`, `rotSpeed`, `rotSpeedRand`, `rotInitial`, `autoRotate`, `delay`, `animRepeat`.

**Shutdown block:** Configures graceful particle stop. All curves use "progress" convention: `multiplier = 1.0 - curve(t)`. `curve` controls particle count (how many recycle vs die). `alphaCurve`/`sizeCurve`/`speedCurve` apply global multipliers during shutdown. `duration` is the default when `shutdown()` is called without arguments.

**Runtime API:** `group.emitBurst(count)`, `group.addForceField(ff)`, `group.removeForceFieldAt(i)`, `group.clearForceFields()`, `group.shutdown(?duration, ?curve)`, `particles.shutdown(?duration, ?curve)`, `group.isShuttingDown()`, `group.getShutdownRate()`, `group.emitFilter = (x, y) -> Bool`, `group.advanceTime(dt)`, `particles.advanceTime(dt)`

See `docs/manim.md` for full particles documentation.

## Animated Paths Quick Reference

```manim
#animName animatedPath {
    path: myPath
    type: time
    duration: 1.0
    loop: false
    pingPong: false
    easing: easeOutCubic
    0.0: scaleCurve: grow, alphaCurve: easeInQuad
    0.5: event("halfway")
    0.0: colorCurve: linear, #FF0000, #00FF00
    0.5: colorCurve: easeInQuad, #00FF00, #0000FF
    0.0: custom("myValue"): customCurve
}
```

**Properties:** `path` (required), `type: time|distance`, `duration`, `speed`, `loop: bool`, `pingPong: bool`, `easing: <easingName>` (shorthand for `0.0: progressCurve: <easingName>`)

**Curve slots** (at rate 0.0–1.0 or checkpoint name): `speedCurve`, `scaleCurve`, `alphaCurve`, `rotationCurve`, `progressCurve`, `colorCurve: curve, startColor, endColor`, `custom("name"): curve`. Curve references can be named curves from `curves{}` or **inline easing names** (e.g. `easeInQuad`). Multiple `colorCurve` assignments at different rates create per-segment color interpolation.

**Events:** `event("name")`. Built-in: `pathStart`, `pathEnd`, `cycleStart`, `cycleEnd`

**State fields:** `position`, `angle`, `rate`, `speed`, `scale`, `alpha`, `rotation`, `color`, `cycle`, `done`, `custom`

**Runtime API:**
- Builder: `builder.createAnimatedPath("name", ?startPoint, ?endPoint)`
- Projectile helper: `builder.createProjectilePath("name", startPoint, endPoint)` (Stretch normalization)
- Codegen: `factory.createAnimatedPath_name(?startPoint, ?endPoint)`
- `ap.update(dt)` → `AnimatedPathState`, `ap.seek(rate)` → state without side effects, `ap.reset()` for reuse
- Reverse lookup: `path.getClosestRate(worldPoint)` → closest rate (0..1)

See `docs/manim.md` for full animated paths documentation.
