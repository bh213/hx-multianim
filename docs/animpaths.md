# Animated Paths Guide

Animated paths let you move objects along curves with eased timing, property animation, events, looping, and color gradients — all defined declaratively in `.manim`.

This guide covers the full system: **paths** (the shape), **curves** (the easing/timing), and **animated paths** (the orchestration).

---

## Quick Start

A minimal example — move an object along a line over 1 second:

```manim
paths {
    #flight path {
        lineTo(200, -50)
    }
}

#anim animatedPath {
    path: flight
    duration: 1.0
}
```

```haxe
var ap = builder.createAnimatedPath("anim");
ap.onUpdate = (state) -> {
    sprite.setPosition(state.position.x, state.position.y);
};

// In your update loop:
ap.update(dt);
```

Add easing to make it smooth:

```manim
#anim animatedPath {
    path: flight
    duration: 1.0
    easing: easeOutCubic
}
```

---

## Paths

Paths define the shape an object follows. All paths start at `(0, 0)` and are built from sequential commands.

### Defining Paths

```manim
paths {
    #myPath path {
        lineTo(100, 0)
        bezier(80, -60, 40, -80)
        lineTo(50, 30)
    }
}
```

Multiple named paths can be defined in a single `paths {}` block.

### Path Commands

| Command | Description |
|---------|-------------|
| `lineTo(x, y)` | Line to relative position |
| `lineAbs(x, y)` | Line to absolute position |
| `bezier(endX, endY, ctrlX, ctrlY)` | Quadratic bezier (relative) |
| `bezier(endX, endY, c1X, c1Y, c2X, c2Y)` | Cubic bezier (relative) |
| `bezierAbs(...)` | Bezier with absolute coordinates |
| `forward(distance)` | Move forward in the current direction |
| `turn(degrees)` | Change direction without moving |
| `arc(radius, angleDelta)` | Circular arc. Positive = counter-clockwise |
| `spiral(radiusStart, radiusEnd, angleDelta)` | Arc with expanding/contracting radius |
| `wave(amplitude, wavelength, count)` | Sinusoidal wave along the current direction |
| `moveTo(x, y)` | Jump to relative position (no line drawn) |
| `moveAbs(x, y)` | Jump to absolute position (no line drawn) |
| `checkpoint(name)` | Named point for timed actions (see below) |
| `close` | Close the path back to start with a line |

### Relative vs Absolute

Default commands (`lineTo`, `bezier`, `moveTo`) use **relative coordinates** — offsets from the current position. Commands ending in `Abs` use **absolute coordinates** in path space.

### Bezier Smoothing

Bezier curves support an optional `smoothing` parameter that aligns the entry tangent with the previous segment's exit direction:

```manim
bezier(80, -60, 40, -80, smoothing: auto)   // auto-smoothed (default)
bezier(80, -60, 40, -80, smoothing: none)    // sharp corner allowed
bezier(80, -60, 40, -80, smoothing: 25)      // custom smoothing distance
```

When omitted, smoothing defaults to `auto` (50% distance to the first control point).

### Checkpoints

Checkpoints mark named positions along a path. They can be used instead of numeric rates in animated path actions:

```manim
paths {
    #route path {
        lineTo(100, 0)
        checkpoint(halfway)
        bezier(100, -50, 50, -80)
        checkpoint(arrival)
        lineTo(30, 0)
    }
}

#anim animatedPath {
    path: route
    duration: 2.0
    halfway: event("reachedMiddle"), scaleCurve: shrink
    arrival: event("almostDone")
}
```

Checkpoint rates are calculated automatically based on arc length.

### Complex Path Examples

**S-curve:**
```manim
#sCurve path {
    bezier(50, -40, 25, -60)
    bezier(50, 40, 25, 60)
}
```

**Spiral approach:**
```manim
#approach path {
    forward(100)
    spiral(30, 10, 720)
}
```

**Zigzag with arcs:**
```manim
#zigzag path {
    lineTo(40, -20)
    arc(15, 180)
    lineTo(40, 20)
    arc(15, -180)
    lineTo(40, -20)
}
```

**Looping orbit:**
```manim
#orbit path {
    arc(50, 360)
}
```

---

## Curves

Curves define how values change over normalized time (0 to 1). They are used by animated paths to control properties like speed, scale, alpha, and color.

### Predefined Easing Names

These easing functions can be used **inline** in animated path curve slots without defining a `curves{}` block:

| Name | Description |
|------|-------------|
| `linear` | Constant rate, no easing |
| `easeInQuad` | Slow start, accelerating (quadratic) |
| `easeOutQuad` | Fast start, decelerating (quadratic) |
| `easeInOutQuad` | Slow start and end (quadratic) |
| `easeInCubic` | Slow start, accelerating (cubic) |
| `easeOutCubic` | Fast start, decelerating (cubic) |
| `easeInOutCubic` | Slow start and end (cubic) |
| `easeInBack` | Pulls back before moving forward |
| `easeOutBack` | Overshoots then settles |
| `easeInOutBack` | Pull-back start, overshoot end |
| `easeOutBounce` | Bounces at the end |
| `easeOutElastic` | Elastic spring at the end |

Easing names are **case-insensitive** in `.manim` files.

### Inline Easing in Animated Paths

Use any easing name directly as a curve reference — no `curves{}` block needed:

```manim
#anim animatedPath {
    path: myPath
    duration: 1.0
    0.0: alphaCurve: easeInQuad
    0.0: scaleCurve: easeOutBack
}
```

### Custom Curves in a `curves{}` Block

For curves that aren't simple easing functions, define them in a `curves{}` block:

**Easing-based:**
```manim
curves {
    #smooth curve { easing: easeOutCubic }
    #custom curve { easing: cubicBezier(0.25, 0.1, 0.25, 1.0) }
}
```

**Point-based** (linear interpolation between control points):
```manim
curves {
    #pulse curve {
        points: [(0, 0), (0.2, 1.0), (0.4, 0.3), (0.8, 0.8), (1, 0)]
    }
}
```

**Segmented** (chain multiple easings across time ranges):
```manim
curves {
    #complex curve {
        [0.0 .. 0.4] easeInQuad
        [0.4 .. 0.7] easeOutCubic
        [0.7 .. 1.0] easeInBack
    }
}
```

Segments can specify explicit value ranges:
```manim
curves {
    #ramp curve {
        [0.0 .. 0.5] easeInQuad (0.0, 0.8)
        [0.5 .. 1.0] easeOutCubic (0.8, 0.3)
    }
}
```

**Segment rules:**
- Overlapping segments are blended (weighted average in the overlap zone)
- Gaps between segments are linearly interpolated
- Values default to `(0.0, 1.0)` if omitted
- Cannot mix segments with `easing:` or `points:` in the same curve

### Accessing Curves at Runtime

```haxe
var curve = builder.getCurve("pulse");
var value = curve.getValue(0.5); // evaluate at t=0.5
```

Macro codegen generates `getCurve_<name>():Curve` factory methods.

---

## Animated Paths

Animated paths combine a **path** (shape) with **curves** (timing) to control traversal. They output position, angle, and animated properties on every frame.

### Definition

```manim
#animName animatedPath {
    path: myPath
    type: time
    duration: 1.5
    loop: false
    pingPong: false
    easing: easeOutCubic
    0.0: scaleCurve: easeInQuad, alphaCurve: easeOutQuad
    0.5: event("halfway")
    0.0: colorCurve: linear, #FF0000, #00FF00
    0.0: custom("glow"): pulse
}
```

### Properties

| Property | Values | Default | Description |
|----------|--------|---------|-------------|
| `path` | path name | **required** | Name of a path from the `paths {}` block |
| `type` | `time`, `distance` | inferred | Animation mode (see below) |
| `duration` | float (seconds) | — | Total duration (time mode) |
| `speed` | float (px/sec) | — | Base speed (distance mode) |
| `loop` | `true`, `false` | `false` | Repeat continuously |
| `pingPong` | `true`, `false` | `false` | Alternate forward/reverse each cycle |
| `easing` | easing name | — | Shorthand for `0.0: progressCurve: <easing>` |

### Animation Modes

**Time mode** (`type: time` or just `duration:`):
The object completes the path in exactly `duration` seconds regardless of path length. Use `progressCurve` or `easing:` to control the speed profile.

```manim
#fadeIn animatedPath {
    path: entryArc
    duration: 0.8
    easing: easeOutCubic
}
```

**Distance mode** (`type: distance` or just `speed:`):
The object moves at `speed` pixels per second. Total time depends on path length. Use `speedCurve` to vary speed along the path.

```manim
#patrol animatedPath {
    path: guardRoute
    speed: 120.0
    loop: true
}
```

The `type:` field is optional — it's inferred from whether you specify `duration` or `speed`.

### Curve Slots

Curve slots animate properties as the object traverses the path. Each slot assignment has three parts: **rate** (when), **slot name** (what), and **curve reference** (how).

```
<rate>: <slotName>: <curveRef>
```

**Rate** is either:
- A float from `0.0` to `1.0` (e.g. `0.0`, `0.5`, `0.75`)
- A checkpoint name from the referenced path (e.g. `halfway`)

**Curve reference** is either:
- An inline easing name (e.g. `easeInQuad`) — no `curves{}` block needed
- A named curve from the `curves{}` block (e.g. `myCustomCurve`)

| Slot | Type | Default | Description |
|------|------|---------|-------------|
| `progressCurve` | rate → rate | linear | Maps elapsed time to path progress (time mode only). Controls the overall feel — easing, overshoot, bounce |
| `speedCurve` | rate → multiplier | 1.0 | Speed multiplier (distance mode only) |
| `scaleCurve` | rate → float | 1.0 | Scale value |
| `alphaCurve` | rate → float | 1.0 | Alpha/opacity |
| `rotationCurve` | rate → float | 0.0 | Additional rotation in radians (on top of path tangent) |
| `colorCurve` | rate → color | 0xFFFFFF | Color interpolation (see multi-color below) |
| `custom("<name>")` | rate → float | 0.0 | User-defined named value |

Multiple curve assignments at different rates create **piecewise curves**. The curve for a given slot is evaluated within the segment that starts at its rate. For example, with two `scaleCurve` assignments at `0.0` and `0.5`, the first curve runs from rate 0.0 to 0.5, the second from 0.5 to 1.0.

#### Combining Assignments

Multiple assignments at the same rate are comma-separated on one line:

```manim
0.0: scaleCurve: grow, alphaCurve: fadeIn, event("start")
```

#### The `easing:` Shorthand

Instead of writing `0.0: progressCurve: easeOutCubic`, use the top-level shorthand:

```manim
easing: easeOutCubic
```

This only applies to `progressCurve` (time mode). It's the most common use case — applying a single easing to the entire traversal.

### Multi-Color Curve Stops

Each `colorCurve` assignment specifies its own start and end colors, enabling multi-stop gradients along the path:

```manim
0.0: colorCurve: linear, #FF0000, #FFAA00
0.3: colorCurve: linear, #FFAA00, #00FF00
0.7: colorCurve: easeInQuad, #00FF00, #0000FF
```

This creates a red → orange → green → blue gradient. The curve controls the interpolation speed within each segment.

**Single color range** (simpler case):
```manim
0.0: colorCurve: linear, #FF0000, #00FF00
```

### Events

Events fire at specific rates during traversal:

```manim
0.0: event("launch")
0.5: event("halfway")
1.0: event("arrived")
```

Events can also be placed at checkpoints:
```manim
halfway: event("passedMiddle")
```

**Built-in events** (fired automatically, no declaration needed):

| Event | When |
|-------|------|
| `pathStart` | First `update()` call |
| `pathEnd` | Animation complete (non-looping only) |
| `cycleStart` | Beginning of each loop/pingPong cycle |
| `cycleEnd` | End of each loop/pingPong cycle |

### Looping and Ping-Pong

**`loop: true`** — the path repeats indefinitely. The `cycle` counter increments each time.

**`pingPong: true`** (requires `loop: true`) — alternates forward and reverse on each cycle. Useful for patrol routes, bobbing, oscillation.

```manim
#bob animatedPath {
    path: upDown
    duration: 0.6
    loop: true
    pingPong: true
    easing: easeInOutQuad
}
```

---

## State

Every `update(dt)` and `seek(rate)` call returns an `AnimatedPathState` with the current values:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | `FPoint` | — | Position on the path in world coordinates |
| `angle` | `Float` | — | Tangent angle at current position (radians) |
| `rate` | `Float` | — | Current progress along the path (0.0 to 1.0) |
| `speed` | `Float` | — | Current effective speed |
| `scale` | `Float` | 1.0 | Value from `scaleCurve` |
| `alpha` | `Float` | 1.0 | Value from `alphaCurve` |
| `rotation` | `Float` | 0.0 | Value from `rotationCurve` |
| `color` | `Int` | 0xFFFFFF | Value from `colorCurve` (RGB) |
| `cycle` | `Int` | 0 | Current loop cycle (0-indexed) |
| `done` | `Bool` | false | `true` when a non-looping animation finishes |
| `custom` | `Map<String, Float>` | — | Values from `custom("name")` slots |

---

## Runtime API

### Creating Animated Paths

**Builder:**
```haxe
// Basic creation
var ap = builder.createAnimatedPath("animName");

// With path normalization (stretch to fit between two points)
var ap = builder.createAnimatedPath("animName",
    Stretch(new FPoint(100, 200), new FPoint(500, 100)));

// Projectile helper — shorthand for Stretch normalization
var ap = builder.createProjectilePath("animName",
    new FPoint(towerX, towerY),   // start
    new FPoint(targetX, targetY)  // end
);
```

**Macro codegen:**
```haxe
var ap = factory.createAnimatedPath_animName();
var ap = factory.createAnimatedPath_animName(startPoint, endPoint);
```

### Driving the Animation

```haxe
// Assign callbacks
ap.onUpdate = (state) -> {
    sprite.setPosition(state.position.x, state.position.y);
    sprite.alpha = state.alpha;
    sprite.scaleX = state.scale;
    sprite.scaleY = state.scale;
    sprite.rotation = state.angle + state.rotation;
};

ap.onEvent = (name, state) -> {
    switch (name) {
        case "launch": playSound("whoosh");
        case "arrived": onProjectileHit();
    }
};

// In your update loop — returns the current state
var state = ap.update(dt);
```

### Querying Without Side Effects

```haxe
// Seek to a specific rate — no events fire, no time advances
var state = ap.seek(0.5);

// Read current state without updating
var state = ap.getState();
```

### Resetting

```haxe
// Reuse the animated path from the beginning (avoids re-creation)
ap.reset();
```

### Path Utilities

```haxe
var paths = builder.getPaths();
var path = paths.getPath("myPath");

// Get a point on the path at a given rate
var point = path.getPoint(0.5);

// Get the tangent angle at a given rate (radians)
var angle = path.getTangentAngle(0.5);

// Reverse lookup: find the closest rate to a world point
var rate = path.getClosestRate(new FPoint(mouseX, mouseY));

// Get the endpoint of the path
var end = path.getEndpoint();

// Get a checkpoint's rate
var rate = path.getCheckpoint("halfway");

// Apply normalization to get a transformed path
var stretched = path.applyTransform(Stretch(startPt, endPt));
```

---

## Path Normalization

Path normalization transforms a path to fit between two arbitrary points. The path shape is preserved — it's scaled, rotated, and translated so that:
- The path origin `(0, 0)` maps to the start point
- The path endpoint maps to the end point

This is how projectiles, card animations, and other point-to-point effects work — define the flight shape once, then stretch it between source and target at runtime.

```manim
paths {
    #arc path {
        bezier(100, 0, 50, -80)
    }
}

#projectile animatedPath {
    path: arc
    duration: 0.5
    easing: easeInQuad
}
```

```haxe
// The arc shape is stretched between tower and target
var ap = builder.createProjectilePath("projectile", towerPos, targetPos);
```

---

## Examples

### Projectile with Trail Color

```manim
paths {
    #arc path {
        bezier(100, 0, 50, -60)
    }
}

curves {
    #growShrink curve {
        points: [(0, 0.5), (0.3, 1.2), (1, 0.2)]
    }
}

#projectile animatedPath {
    path: arc
    duration: 0.6
    easing: easeInCubic
    0.0: scaleCurve: growShrink
    0.0: colorCurve: linear, #FF4400, #FFFF00
    0.8: colorCurve: linear, #FFFF00, #FFFFFF
    0.0: event("launch")
    1.0: event("impact")
}
```

### Patrol Route

```manim
paths {
    #guardPath path {
        lineTo(200, 0)
        checkpoint(corner)
        lineTo(0, 100)
        checkpoint(end)
    }
}

#patrol animatedPath {
    path: guardPath
    speed: 80.0
    loop: true
    pingPong: true
    corner: event("turnCorner")
}
```

### UI Element Entry Animation

```manim
paths {
    #slideIn path {
        lineTo(0, -30)
    }
}

#entry animatedPath {
    path: slideIn
    duration: 0.4
    easing: easeOutBack
    0.0: alphaCurve: easeOutQuad
}
```

```haxe
var ap = builder.createAnimatedPath("entry",
    Stretch(new FPoint(panel.x, panel.y + 30), new FPoint(panel.x, panel.y)));
ap.onUpdate = (state) -> {
    panel.setPosition(state.position.x, state.position.y);
    panel.alpha = state.alpha;
};
```

### Orbiting with Custom Property

```manim
paths {
    #orbit path {
        arc(40, 360)
    }
}

curves {
    #glow curve {
        points: [(0, 0.3), (0.25, 1.0), (0.5, 0.3), (0.75, 1.0), (1, 0.3)]
    }
}

#orbiter animatedPath {
    path: orbit
    duration: 3.0
    loop: true
    0.0: custom("glow"): glow
    0.0: scaleCurve: easeInOutQuad
}
```

```haxe
ap.onUpdate = (state) -> {
    sprite.setPosition(state.position.x, state.position.y);
    sprite.scaleX = state.scale;
    glowFilter.intensity = state.custom.get("glow");
};
```
