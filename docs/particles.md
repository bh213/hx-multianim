# Particles Guide

Particles let you create visual effects like fire, smoke, rain, explosions, and magic — all defined declaratively in `.manim`.

This guide covers the full system: **emission shapes**, **tile sources**, **motion and physics**, **color and curves**, **bounds and collision**, **animation integration**, and **sub-emitters**.

---

## Quick Start

A minimal particle effect — sparks shooting upward:

```manim
#sparks particles {
    count: 50
    emit: cone(0, 0, -90, 30)
    tiles: file("spark.png")
    maxLife: 1.5
    speed: 100
}
```

```haxe
var builder = MultiAnimBuilder.load(fileContent, loader, "effects.manim");
var particles = builder.createParticles("sparks");
scene.addChild(particles);
```

Add color, gravity, and fading to make it look better:

```manim
#sparks particles {
    count: 50
    emit: cone(0, 0, -90, 30)
    tiles: file("spark.png")
    maxLife: 1.5
    speed: 100
    gravity: 80
    gravityAngle: 90
    fadeIn: 0.1
    fadeOut: 0.7
    0.0: colorCurve: linear, #FF4400, #FFAA00
    0.5: colorCurve: linear, #FFAA00, #FFFF88
}
```

---

## All Properties Reference

### Core Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `count` | int | 100 | Maximum particles alive at once |
| `loop` | bool | true | Re-emit dead particles continuously |
| `maxLife` | float | 1.0 | Particle lifetime in seconds |
| `lifeRandom` | float | 0 | Random lifetime variation (multiplicative, 0-1) |
| `relative` | bool | false | Particles relative to emitter (true) or world space (false) |

### Movement

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `speed` | float | 50 | Initial velocity magnitude |
| `speedRandom` | float | 0 | Random speed variation (multiplicative, 0-1) |
| `speedIncrease` | float | 0 | Velocity change rate over time (exponential) |
| `gravity` | float | 0 | Gravity force magnitude |
| `gravityAngle` | float | 90 | Gravity direction in degrees (90 = down) |

### Size

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `size` | float | 1.0 | Initial particle scale |
| `sizeRandom` | float | 0 | Random size variation (multiplicative, 0-1) |

### Rotation

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `rotationInitial` | float | 0 | Initial random rotation range in degrees |
| `rotationSpeed` | float | 0 | Rotation speed in degrees/sec |
| `rotationSpeedRandom` | float | 0 | Random rotation speed variation |
| `rotateAuto` | bool | false | Auto-rotate sprite to match velocity direction |
| `forwardAngle` | float | 0 | Which direction the sprite "faces" (0 = right). Used with `rotateAuto` |

### Fading

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `fadeIn` | float | 0.2 | Fade-in duration as normalized lifetime (0-1) |
| `fadeOut` | float | 0.8 | When fade-out starts as normalized lifetime (0-1) |
| `fadePower` | float | 1.0 | Fade curve exponent (>1 = faster fade) |

### Emission Timing

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `emitSync` | float | 0 | Synchronization factor (0 = fully staggered, 1 = all at once) |
| `emitDelay` | float | 0 | Fixed delay in seconds before particles appear |

### Rendering

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blendMode` | enum | alpha | Blend mode: `alpha`, `add`, `multiply`, `screen`, etc. |
| `animationRepeat` | float | 1 | How many times tile animation loops during lifetime (0 = random static frame) |

**Note:** All property names are case-insensitive (`maxLife`, `maxlife`, and `MAXLIFE` are all equivalent).

---

## Emission Modes

The `emit` property controls the shape and direction of particle emission.

```
emit: mode(params)
```

### Point

Emit from a single point in all random directions.

```
emit: point(distance, distanceRandom)
```

| Parameter | Description |
|-----------|-------------|
| `distance` | Minimum spawn distance from the emitter |
| `distanceRandom` | Additional random spawn distance |

```manim
// Emit right at the emitter, random directions
emit: point(0, 0)

// Emit in a ring 10-30px from center
emit: point(10, 20)
```

### Cone

Emit within a directed arc.

```
emit: cone(distance, distanceRandom, angle, angleRandom)
```

| Parameter | Description |
|-----------|-------------|
| `distance` | Minimum spawn distance along the cone direction |
| `distanceRandom` | Additional random spawn distance |
| `angle` | Center direction in degrees |
| `angleRandom` | Half-width of the cone spread |

Angle reference: **0 = right**, **-90 = up**, **90 = down**, **180 = left**.

```manim
// Upward cone with 30-degree spread
emit: cone(0, 10, -90, 30)

// Rightward narrow beam
emit: cone(5, 5, 0, 10)

// Downward wide spray
emit: cone(0, 0, 90, 60)
```

### Box

Emit from random positions within a rectangle.

```
emit: box(width, height, angle, angleRandom)
```

| Parameter | Description |
|-----------|-------------|
| `width` | Rectangle width |
| `height` | Rectangle height |
| `angle` | Emission direction in degrees |
| `angleRandom` | Direction spread |

```manim
// Rain from a wide strip, falling down
emit: box(500, 10, 90, 5)

// Snow from a wide strip, drifting down-left
emit: box(400, 5, 100, 15)
```

### Circle

Emit from the edge of a circle or ring.

```
emit: circle(radius, radiusRandom, angle, angleRandom)
```

| Parameter | Description |
|-----------|-------------|
| `radius` | Base circle radius |
| `radiusRandom` | Additional random radius |
| `angle` | Emission direction (0, 0 = radial outward) |
| `angleRandom` | Direction spread |

When both `angle` and `angleRandom` are 0, particles emit **radially outward** from the circle center. Otherwise, the specified angle overrides.

```manim
// Expanding ring - particles fly outward
emit: circle(50, 10, 0, 0)

// Ring with upward emission
emit: circle(30, 5, -90, 20)
```

### Path

Emit along a named path defined in a `paths{}` block. Particles spawn at random positions along the path.

```
emit: path(pathName)
emit: path(pathName, tangent)
```

Without `tangent`, particles emit in random directions. With `tangent`, particle velocity follows the path tangent at the spawn point.

```manim
paths {
    #river path {
        bezier(200, 50, 100, -40)
        lineTo(100, 0)
    }
}

#waterSpray particles {
    emit: path(river)
    // ...
}

#flowingParticles particles {
    emit: path(river, tangent)
    // ...
}
```

---

## Tile Sources

The `tiles` property specifies what image each particle renders. Multiple tile sources can be listed — particles randomly select from them.

### File

```
tiles: file("particle.png")
```

### Sheet

```
tiles: sheet("atlasName", "tileName")
tiles: sheet("atlasName", "tileName", frameIndex)
```

### Generated

```
tiles: generated(color(width, height, #hexColor))
```

### Multiple Tiles

List multiple sources separated by spaces for variety:

```manim
tiles: file("spark1.png") file("spark2.png") file("spark3.png")
tiles: sheet("effects", "star") sheet("effects", "dot")
```

Tile images should be similar in size for consistent appearance.

---

## Color Curves

Particles can transition through colors over their lifetime using per-segment color curves.

### Syntax

```
rate: colorCurve: curveName, #startColor, #endColor
```

The `rate` is a normalized lifetime value (0.0 to 1.0). Multiple segments at different rates create multi-stop color gradients. The curve reference controls interpolation speed within each segment — use a named curve from a `curves{}` block or an inline easing name.

### Examples

**Simple two-color fade:**
```manim
0.0: colorCurve: linear, #FF0000, #0000FF
```

**Fire gradient (orange to yellow to white):**
```manim
0.0: colorCurve: linear, #FF4400, #FFAA00
0.4: colorCurve: linear, #FFAA00, #FFFF88
```

**Two-phase color with easing:**
```manim
0.0: colorCurve: easeInQuad, #FF0000, #00FF00
0.5: colorCurve: easeOutQuad, #00FF00, #0000FF
```

Each segment's curve runs from its rate to the next segment's rate (or 1.0 for the last segment).

---

## Curves

Curves control how size and velocity change over the particle's normalized lifetime (0 to 1).

| Property | Description |
|----------|-------------|
| `sizeCurve` | Size multiplier over lifetime |
| `velocityCurve` | Velocity multiplier over lifetime |

The value is a reference to a named curve from a `curves{}` block, or an inline easing name.

```manim
// Inline easing — no curves{} block needed
sizeCurve: easeOutQuad
velocityCurve: easeInCubic

// Named curve reference
sizeCurve: myCustomGrowShrink
```

### Custom Curves

Define custom curves in a `curves{}` block:

```manim
curves {
    #fireGrowShrink curve {
        points: [(0, 0.5), (0.2, 1.2), (0.6, 0.8), (1, 0)]
    }

    #slowDown curve {
        easing: easeOutQuad
    }
}

#fire particles {
    // ...
    sizeCurve: fireGrowShrink
    velocityCurve: slowDown
}
```

See the [Animated Paths Guide](animpaths.md) for full curve documentation.

---

## Force Fields

Force fields apply physics forces to particles. Multiple fields can be combined in a single array.

```
forceFields: [force1, force2, ...]
```

### Force Types

| Force | Syntax | Description |
|-------|--------|-------------|
| Attractor | `attractor(x, y, strength, radius)` | Pulls particles toward a point |
| Repulsor | `repulsor(x, y, strength, radius)` | Pushes particles away from a point |
| Vortex | `vortex(x, y, strength, radius)` | Spins particles around a point (perpendicular force) |
| Wind | `wind(vx, vy)` | Constant directional force |
| Turbulence | `turbulence(strength, scale, speed)` | Noise-based displacement |
| PathGuide | `pathguide(pathName, attractStrength, flowStrength, radius)` | Attracts toward a named path and pushes along its tangent |

For point-based forces (attractor, repulsor, vortex), `x, y` is the force center position relative to the emitter, `strength` controls the force magnitude, and `radius` is the influence range. Force falls off linearly within the radius.

### Examples

```manim
// Swirling vortex with center pull
forceFields: [vortex(0, 0, 200, 200), attractor(0, 0, 50, 180)]

// Rising smoke with drift and turbulence
forceFields: [turbulence(20, 0.015, 1.0), wind(15, 0)]

// Repulsive explosion center
forceFields: [repulsor(0, 0, 100, 120), turbulence(15, 0.02, 2.0)]

// Magical stream along a path
forceFields: [pathguide(myBezierPath, 80, 120, 50)]
```

### Runtime API

Force fields are mutable at runtime:

```haxe
var group = particles.getGroup("fire");
group.addForceField(Wind(10, 0));
group.removeForceFieldAt(0);
group.clearForceFields();
```

---

## Bounds and Collision

Control what happens when particles reach boundaries.

### Bounds Mode

| Mode | Syntax | Description |
|------|--------|-------------|
| None | `boundsMode: none` | No boundary checking (default) |
| Kill | `boundsMode: kill` | Remove particle on exit |
| Bounce | `boundsMode: bounce(damping)` | Reflect velocity (damping 0-1) |
| Wrap | `boundsMode: wrap` | Teleport to opposite side |

### Rectangular Bounds

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `boundsMinX` | float | 0 | Left boundary |
| `boundsMaxX` | float | 800 | Right boundary |
| `boundsMinY` | float | 0 | Top boundary |
| `boundsMaxY` | float | 600 | Bottom boundary |

### Line Bounds

```
boundsLine: x1, y1, x2, y2
```

Line boundaries define one-sided walls. The "out" side is the **left side** of the direction from (x1,y1) to (x2,y2). Multiple `boundsLine` entries can be used for complex shapes. Line bounds work with `kill` and `bounce` modes (not `wrap`).

### Examples

```manim
// Kill at boundaries
boundsMode: kill
boundsMinX: -100
boundsMaxX: 300
boundsMinY: -50
boundsMaxY: 250

// Bounce with energy loss
boundsMode: bounce(0.6)
boundsMinX: 0
boundsMaxX: 200
boundsMinY: 0
boundsMaxY: 200

// Wrap-around rain
boundsMode: wrap
boundsMinX: -50
boundsMaxX: 450
boundsMinY: -20
boundsMaxY: 350

// Bounce off line walls
boundsMode: bounce(0.8)
boundsLine: 0, 200, 300, 200
boundsLine: 300, 200, 300, 0
```

---

## AnimSM Tile Source

Use frames from `.anim` state animation files as particle sprites. Particles can transition between animation states based on lifetime and events.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `animFile` | string | Path to `.anim` file |
| `animSelector` | key => value | State selector for the animation state machine |
| `rate: anim("name")` | rate action | Switch animation state at the given lifetime rate (0.0-1.0) |
| `onBounce: anim("name")` | event override | Switch animation on bounce collision |
| `onDeath: anim("name")` | event override | Switch animation on particle death |

The `tiles` property should still be set as a fallback. When `animFile` is specified, the animation tiles override the basic tiles.

### Lifetime-Driven Animation

Assign animation states at different lifetime rates. Each state plays from its start rate to the next state's start rate:

```manim
#sparks particles {
    emit: point(0, 10)
    tiles: file("fallback.png")
    animFile: "spark.anim"
    animSelector: type => fire
    0.0: anim("birth")
    0.5: anim("midlife")
    0.8: anim("dying")
}
```

At 0-50% lifetime the "birth" animation plays, at 50-80% "midlife" plays, and at 80-100% "dying" plays. Frame selection within each state is based on local time within that state's range.

### Event-Driven Animation

Override the current animation state when specific events occur:

```manim
#bouncing particles {
    emit: cone(0, 0, -45, 30)
    tiles: file("ball.png")
    animFile: "ball.anim"
    animSelector: type => default
    0.0: anim("flying")
    onBounce: anim("impact")
    onDeath: anim("explode")
}
```

---

## AnimatedPath Integration

Particles can be linked to animated paths for emitter movement and dynamic emission rates.

### Attached Path

The `attachTo` property makes the emitter position track a named animated path:

```manim
paths {
    #trail path {
        bezier(200, -100, 100, -150)
        lineTo(100, 50)
    }
}

#trailAnim animatedPath {
    path: trail
    duration: 3.0
    loop: true
}

#trailParticles particles {
    emit: point(0, 5)
    tiles: file("smoke.png")
    maxLife: 1.0
    speed: 20
    attachTo: trailAnim
}
```

### Spawn Curve

When an emitter is attached to a path, `spawnCurve` modulates the emission rate over the path's lifetime. A curve value of 1.0 means normal emission rate, 0.0 means no emission:

```manim
curves {
    #burstAtEnd curve {
        points: [(0, 0.2), (0.8, 0.2), (0.9, 1.0), (1, 1.0)]
    }
}

#effect particles {
    emit: point(0, 0)
    tiles: file("spark.png")
    attachTo: myAnimPath
    spawnCurve: burstAtEnd
}
```

### Runtime Burst

Force-emit particles programmatically:

```haxe
var group = particles.getGroup("sparks");
group.emitBurst(20);  // emit 20 particles immediately
```

---

## Sub-Emitters

Particles can spawn other particle groups on lifecycle events.

### Syntax

```manim
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

### Sub-Emitter Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `groupId` | string | required | Name of the particle group to spawn |
| `trigger` | enum | required | When to spawn (see triggers below) |
| `probability` | float | 1.0 | Spawn chance (0.0 to 1.0) |
| `inheritVelocity` | float | 0 | Fraction of parent particle's velocity to inherit |
| `offsetX` | float | 0 | Horizontal offset from parent particle |
| `offsetY` | float | 0 | Vertical offset from parent particle |

### Triggers

| Trigger | Description |
|---------|-------------|
| `onbirth` | When a particle is first emitted |
| `ondeath` | When a particle's lifetime expires |
| `oncollision` | When a particle hits a boundary (kill or bounce mode) |
| `oninterval(seconds)` | Periodically during the particle's life |

### Example: Firework with Sparks

```manim
#mainBurst particles {
    count: 20
    emit: point(0, 20)
    tiles: file("orb.png")
    maxLife: 1.0
    speed: 150
    gravity: 100
    gravityAngle: 90
    loop: false
    fadeOut: 0.7
    0.0: colorCurve: linear, #FFAA00, #FF4400
    subEmitters: [
        {
            groupId: "sparks",
            trigger: ondeath,
            probability: 0.8,
            inheritVelocity: 0.3
        }
    ]
}

#sparks particles {
    count: 5
    emit: point(0, 5)
    tiles: file("spark.png")
    maxLife: 0.5
    speed: 40
    size: 0.5
    loop: false
    fadeOut: 0.5
    blendMode: add
}
```

### Example: Trail Emitter

```manim
#bullet particles {
    count: 1
    emit: point(0, 0)
    tiles: file("bullet.png")
    maxLife: 2.0
    speed: 200
    loop: false
    subEmitters: [
        {
            groupId: "trail",
            trigger: oninterval(0.05),
            probability: 1.0
        }
    ]
}

#trail particles {
    count: 3
    emit: point(0, 3)
    tiles: file("smoke_small.png")
    maxLife: 0.4
    speed: 5
    size: 0.3
    loop: false
    fadeOut: 0.3
    0.0: colorCurve: linear, #FFFFFF, #888888
}
```

---

## Complete Examples

### Fire Effect

```manim
curves {
    #fireGrowShrink curve {
        points: [(0, 0.5), (0.2, 1.2), (0.6, 0.8), (1, 0)]
    }
}

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
    0.0: colorCurve: linear, #FF4400, #FFAA00
    0.4: colorCurve: linear, #FFAA00, #FFFF88
    sizeCurve: fireGrowShrink
    forceFields: [turbulence(30, 0.02, 2.0)]
}
```

### Rain

```manim
#rain particles {
    count: 200
    emit: box(500, 10, 100, 5)
    maxLife: 1.5
    lifeRandom: 0.2
    speed: 400
    speedRandom: 0.15
    tiles: file("raindrop.png")
    loop: true
    size: 0.2
    blendMode: alpha
    fadeIn: 0.1
    fadeOut: 0.9
    0.0: colorCurve: linear, #AACCFF, #6688CC
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

### Magic Vortex

```manim
#vortex particles {
    count: 80
    emit: circle(60, 20, 0, 0)
    maxLife: 3.0
    speed: 30
    tiles: file("star.png")
    loop: true
    size: 0.6
    sizeRandom: 0.3
    blendMode: add
    fadeIn: 0.2
    fadeOut: 0.7
    0.0: colorCurve: linear, #4400FF, #FF00FF
    0.5: colorCurve: easeInQuad, #FF00FF, #00FFFF
    sizeCurve: easeOutQuad
    forceFields: [vortex(0, 0, 150, 200), attractor(0, 0, 40, 180)]
}
```

### Explosion Burst

```manim
#explosion particles {
    count: 60
    emit: point(0, 30)
    maxLife: 0.8
    speed: 200
    speedRandom: 0.4
    tiles: file("spark.png") file("ember.png")
    loop: false
    size: 1.0
    sizeRandom: 0.5
    blendMode: add
    fadeIn: 0.05
    fadeOut: 0.5
    gravity: 150
    gravityAngle: 90
    0.0: colorCurve: linear, #FFFFFF, #FFAA00
    0.3: colorCurve: easeInQuad, #FFAA00, #FF2200
    velocityCurve: easeOutCubic
}
```

### Path-Following Stream

```manim
paths {
    #river path {
        bezier(150, -40, 75, -80)
        lineTo(100, 30)
        bezier(100, 0, 50, 40)
    }
}

#stream particles {
    count: 60
    emit: path(river, tangent)
    maxLife: 2.0
    speed: 40
    speedRandom: 0.2
    tiles: file("droplet.png")
    loop: true
    size: 0.4
    sizeRandom: 0.2
    fadeOut: 0.8
    0.0: colorCurve: linear, #88CCFF, #4488CC
    forceFields: [pathguide(river, 60, 80, 40)]
}
```

### Bouncing Balls

```manim
#balls particles {
    count: 15
    emit: box(200, 5, -90, 20)
    maxLife: 5.0
    speed: 100
    tiles: file("ball.png")
    loop: true
    size: 0.8
    sizeRandom: 0.3
    gravity: 200
    gravityAngle: 90
    boundsMode: bounce(0.7)
    boundsMinX: 0
    boundsMaxX: 300
    boundsMinY: 0
    boundsMaxY: 250
    boundsLine: 0, 250, 300, 250
    rotateAuto: true
    forwardAngle: 90
}
```

---

## Using Particles in Haxe

### Builder API

```haxe
// Load and create
var builder = MultiAnimBuilder.load(fileContent, loader, "effects.manim");
var particles = builder.createParticles("fire");
scene.addChild(particles);

// Access a specific group
var group = particles.getGroup("fire");

// Force-emit a burst
group.emitBurst(20);

// Modify force fields at runtime
group.addForceField(Wind(10, 0));
group.removeForceFieldAt(0);
group.clearForceFields();
```

### Within a Programmable

Particles can be placed inside a programmable block:

```manim
#myUI programmable() {
    bitmap("background.png"): 0, 0

    point {
        pos: 200, 150
        #fireEffect particles {
            count: 50
            emit: cone(0, 0, -90, 20)
            tiles: file("spark.png")
            maxLife: 1.5
            speed: 60
        }
    }
}
```

### Using with Updatable Placeholders

```haxe
// Create particles and attach to a placeholder slot
var particles = builder.createParticles("fire");
var updatable = ui.builderResults.getUpdatable("particlesSlot");
updatable.setObject(particles);
```

### Codegen (Macro)

With `@:manim` macro codegen, particles are built automatically:

```haxe
@:build(ProgrammableCodeGen.buildAll())
class MyEffects {
    @:manim("effects.manim", "myUI")
    public static var myUI;
}

// Usage:
var factory = new MyEffects_myUI(resourceLoader);
var instance = factory.create();
```

---

## Lifecycle and Callback

The `Particles` class extends `h2d.Drawable`. When all particle groups finish (no particles alive and `loop: false`), the `onEnd` callback fires:

```haxe
var particles = builder.createParticles("explosion");
scene.addChild(particles);

particles.onEnd = () -> {
    particles.remove();  // default behavior
    // Add custom cleanup here
};
```
