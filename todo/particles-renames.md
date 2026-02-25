# Particles & Angle System Renames

## 1. Universal Angle Units

Add `deg`, `rad`, `turn` suffixes to the parser for all angle inputs, not just particles.

### Current behavior
- All angles are implicitly degrees, converted via `degToRad()` in the builder
- No way to know at the call site what unit is expected
- 0° = right (positive X), 90° = down (screen coords, Y-down), clockwise

### Proposed syntax
```manim
gravityAngle: 90deg
gravityAngle: 1.57rad
gravityAngle: 0.25turn
gravityAngle: 90            # bare number = degrees (backward compat)
```

### Parser changes
- Add `parseAngle()` / `parseAngleOrReference()` that wraps `parseFloatOrReference()` with optional unit suffix
- Return value should be tagged with unit (or pre-converted to radians at parse time)
- Replace all angle-accepting call sites:
  - **Particles**: `gravityAngle`, `rotationSpeed`, `rotationSpeedRandom`, `rotationInitial`, `forwardAngle`, emit cone/box/circle angles
  - **Graphics**: `arc(color, style, radius, startAngle, arcAngle)`
  - **Filters**: `dropShadow` angle
  - **Paths**: `turn(angle)`, `arc(...)` in path definitions

## 2. Named Direction Constants

Add named direction keywords that resolve to angles.

### Proposed constants
```
right = 0deg
down  = 90deg
left  = 180deg
up    = 270deg
```

### Expression support
```manim
gravityAngle: down                  # 90deg
emit: cone(50, 10, left, 90deg)     # emit leftward ±90°
emit: cone(50, 10, down + 10deg)    # 100deg
```

### Notes
- No `clockwise`/`counterclockwise` modifier — `left + 10deg` (= 190°) and `left - 10deg` (= 170°) are clear enough with named constants.

## 3. Emitter Renames with Named Parameters

Redesign emit modes with named parameters and centered variants.

### Current syntax
```manim
emit: point(0, 0)
emit: cone(dist, distRand, angle, angleRand)
emit: box(w, h, angle, angleRand)
emit: circle(r, rRand, angle, angleRand)
```

### Proposed syntax
```manim
emit: point(dist: 50, distRand: 10)
emit: cone(dist: 50, distRand: 10, angle: right, angleSpread: 90deg)
emit: box(w: 100, h: 100, angle: down, angleSpread: 45deg)
emit: box(w: 100, h: 100, center: true, angle: down, angleSpread: 45deg)
emit: circle(r: 50, rRand: 10, angle: 0deg, angleSpread: 180deg)
```

### Center support
- `box(w, h)` currently spawns in `(0..w, 0..h)` — top-left aligned
- `box(w, h, center: true)` should spawn in `(-w/2..w/2, -h/2..h/2)`
- `circle` is already centered by nature
- `point` is already centered

### Backward compatibility
- Positional args should still work: `emit: cone(50, 10, 0, 180)` = old behavior
- Named params are opt-in enhancement

### Rename `angleRand` → `angleSpread`
- `angleSpread` is more intuitive than `angleRand` / `emitConeAngleRandom`
- Spread of 180deg = full circle (since srand() gives ±1)

## 4. Bounds Rework

Replace separate `boundsMinX/MaxX/MinY/MaxY` + `boundsLine` with structured `bounds:` syntax.

### Current syntax (6 separate properties)
```manim
boundsMode: kill
boundsMinX: -50
boundsMaxX: 200
boundsMinY: -50
boundsMaxY: 200
boundsLine: 0, 0, 100, 0
boundsLine: 0, 0, 0, 100
```

### Proposed syntax
```manim
bounds: kill, box(minX: -50, minY: -50, maxX: 200, maxY: 200)
bounds: bounce(0.6), box(x: -50, y: -50, w: 250, h: 250), line(0, 0, 100, 0)
bounds: wrap, box(0, 0, 800, 600)
```

### Design
- `bounds:` combines mode + shapes in one line
- Mode: `kill` | `bounce(damping)` | `wrap` | `none`
- `box(minX, minY, maxX, maxY)` or `box(x, y, w, h)` — need to decide which
- `line(x1, y1, x2, y2)` — multiple allowed, comma-separated
- All coordinates are in particle local space (relative to group origin)

### Design decision: box format
Use `box(x, y, w, h)` — consistent with graphics `rect(color, style, w, h)` which uses width/height from position, not min/max corners. Named params for clarity: `box(x: -50, y: -50, w: 250, h: 250)`.

### Open questions
- Should `box(center: true, w: 250, h: 250)` be supported for centered bounds?
- Keep old `boundsMinX` etc. as deprecated fallback?

## 5. Color Curve Rework

Replace segmented color curves with color-stop syntax.

### Current syntax (redundant, error-prone)
```manim
0.0: colorCurve: linear, #FF4400, #FFAA00
0.5: colorCurve: easeInQuad, #FFAA00, #FFFF88
```
- Each segment repeats the boundary color
- Curve name comes before colors (reads backward)
- Rate prefix is shared with unrelated actions (`anim()`, `sizeCurve`)

### Proposed syntax (color stops)
```manim
colorStops: 0.0 #FF4400, 0.5 #FFAA00 easeInQuad, 1.0 #FFFF88
```
- Each stop is `rate color [curve]`
- Curve specifies interpolation **from this stop to the next** (default: linear)
- Curve can be a built-in easing name (`easeInQuad`, `linear`, etc.) or a named curve defined in `curves {}`
- No redundant color duplication
- Single property instead of multiple rate-prefixed lines

### Examples
```manim
# Simple two-color
colorStops: 0.0 #FF0000, 1.0 #0000FF

# Three-color with custom easing
colorStops: 0.0 #FF4400, 0.5 #FFAA00 easeInQuad, 1.0 #FFFF88

# Using a named curve from curves {} block
colorStops: 0.0 #FF0000 myCurve, 0.5 #00FF00, 1.0 #0000FF

# Named colors
colorStops: 0.0 red, 0.3 yellow easeOutCubic, 1.0 transparent
```

### Migration
- Old `0.0: colorCurve:` syntax → deprecated fallback
- New `colorStops:` is a single particle property, not a rate action

## 6. Property Name Aliases — DONE

Alternative names added to `parseParticles()` switch in `MacroManimParser.hx`:

| Canonical | Aliases |
|-----------|---------|
| `maxLife` |  |
| `lifeRandom` | `lifeRand` |
| `sizeRandom` | `sizeRand` |
| `speedRandom` | `speedRand` |
| `speedIncrease` | `speedIncr`, `acceleration` |
| `gravityAngle` |  |
| `rotationSpeed` | `rotSpeed` |
| `rotationSpeedRandom` | `rotSpeedRand`, `rotationSpeedRand` |
| `rotationInitial` | `rotInitial` |
| `rotateAuto` | `autoRotate` |
| `forwardAngle` |
| `emitDelay` | `delay` |
| `emitSync` |  |
| `animationRepeat` | `animRepeat` |
| `spawnCurve` |  |

All matching is case-insensitive (existing behavior).

## 7. Implementation Order

1. **Angle units** — DONE: `parseAngleOrReference()` with deg/rad/turn suffixes, backward compat with bare numbers
2. **Named directions** — DONE: `right/down/left/up` constants with expression support (e.g. `down + 10deg`)
3. **Emitter named params** — DONE: `parseEmitModeNamed()` with named parameters, `center` support on Box
4. **Bounds rework** — DONE: `bounds:` combined syntax with `box()` and `line()` shapes
5. **Color stops** — DONE: `colorStops:` property with `parseColorStops()`
6. **Deprecation** — old syntax still works (no warnings, backward compatible)
