---
name: particle-creator
description: >
  Create and edit particle effects in .manim files for hx-multianim. Use this skill whenever the user wants to add, modify, or
  tweak particle systems — fire, smoke, sparks, rain, explosions, magic effects, trails, vortexes, fountains, fireworks, or any
  other particle-based visual effect. Also trigger when users describe visual effects in natural language ("I want glowing
  embers floating up", "add a sparkle effect", "make the explosion bigger"). Handles both creating new particle blocks and
  surgically editing existing ones. Proactively discovers available tile images in the project.
---

# Particle Creator for hx-multianim

You create and edit particle effects in `.manim` files. Users describe effects in natural language or technical terms, and you produce working `.manim` particle blocks.

## Workflow

### 1. Understand the Request

Determine whether the user wants to:
- **Create** a new particle effect (from scratch or described in words)
- **Edit** an existing particle effect (tweak properties, change behavior)
- **Add** particles to an existing `.manim` file

If the request is ambiguous or seems like a drastic change to an existing effect (e.g., "turn this explosion into a button glow"), confirm with the user before proceeding. Offer options when multiple interpretations are reasonable.

### 2. Discover Available Tiles

Before writing any particle block, find what particle tile images are available in the project. This matters because particles need a `tiles:` source.

**Search strategy:**
1. Check the Heaps resource directory of the target project (look for `-D resourcesPath=` in `.hxml` files, or check `res/` directories)
2. Look for `.png` files that are typical particle tiles: `circle_soft`, `circle_hard`, `dot`, `spark`, `star`, `flare`, `glow`, `ring`, `smoke`, `trail`, `comet`, etc.
3. Check existing particle blocks in the same file or nearby `.manim` files to see what tiles are already in use
4. Check atlas files (`.atlas2`) for particle-suitable sprite tiles

**Tile selection by effect type** (use as defaults when no specific tile is requested):

| Effect | Good tile choices |
|--------|-------------------|
| Fire, flame | `circle_soft.png` (soft edges blend well with additive) |
| Smoke, fog, clouds | `smoke.png`, `circle_soft.png` |
| Sparks, embers | `dot.png`, `circle_hard.png` |
| Stars, sparkles, magic | `star.png`, `flare.png` |
| Explosion debris | `circle_hard.png` + `flare.png` (multiple) |
| Rain, snow | `spark.png`, `dot.png` |
| Glow, aura | `glow.png`, `circle_soft.png` |
| Trail | `dot.png`, `circle_soft.png` |
| Electric | `electric-small.png`, `spark.png` |

If no suitable tiles are found, ask the user to provide a tile.

### 3. Write the Particle Block

Use this reference to construct the particle definition.

## .manim Particle Syntax Reference

```manim
#effectName particles {
    // --- Core ---
    count: 80                    // max alive particles (int, default: 100)
    loop: true                   // continuously emit (bool, default: true)
    relative: false              // particles move with emitter (bool, default: true in parser, false common)

    // --- Tiles (REQUIRED) ---
    tiles: file("circle_soft.png")
    // OR: tiles: sheet("atlasName", "tileName")
    // OR: tiles: generated(color(4, 4, #FFFFFF))
    // Multiple for variety: tiles: file("a.png") file("b.png")

    // --- Emission Shape ---
    emit: cone(dist: 10, distRand: 5, angle: up, angleSpread: 25deg)
    // point(dist: N, distRand: N)           — omnidirectional from center
    // cone(dist:, distRand:, angle:, angleSpread:)  — directed arc
    // box(w:, h:, angle:, angleSpread:, center: true) — rectangular area
    // circle(r:, rRand:, angle:, angleSpread:)      — ring/circle edge
    // path(pathName) or path(pathName, tangent)      — along a path

    // Angle values: degrees (25deg), radians (1.5rad), turns (0.5turn)
    // Direction constants: up, down, left, right
    // Expressions: down + 10deg, up - 5deg

    // --- Lifetime ---
    maxLife: 1.8                 // seconds (float, default: 1.0)
    lifeRand: 0.3                // random variation factor (float, default: 0)

    // --- Movement ---
    speed: 60                    // initial velocity px/s (float, default: 50)
    speedRand: 0.3               // random speed factor (float, default: 0)
    acceleration: 0              // exponential velocity change (float, default: 0)
    gravity: 40                  // gravity force (float, default: 0)
    gravityAngle: up             // gravity direction (default: 0 = right)

    // --- Size ---
    size: 0.6                    // scale (float, default: 1.0)
    sizeRand: 0.3                // random size factor (float, default: 0)

    // --- Fading ---
    fadeIn: 0.1                  // normalized lifetime 0-1 (default: 0.2)
    fadeOut: 0.7                 // when fadeout starts 0-1 (default: 0.8)
    fadePower: 1.0               // fade curve exponent (default: 1.0)

    // --- Rotation ---
    rotInitial: 0                // initial random rotation range in degrees
    rotSpeed: 45deg              // rotation speed (degrees/sec)
    rotSpeedRand: 0.5            // random rotation speed factor
    autoRotate: true             // sprite faces velocity direction
    forwardAngle: down           // which direction sprite "faces" (for autoRotate)

    // --- Rendering ---
    blendMode: add               // add (glowy), alpha (normal), multiply, screen
    emitSync: 0.9                // 0=staggered, 1=all at once (for bursts)

    // --- Color Gradient ---
    // Each stop: rate color [easing]
    // Rate is normalized lifetime (0.0 = birth, 1.0 = death)
    colorStops: 0.0 #FF4400, 0.4 #FFAA00, 1.0 #FFFF88

    // --- Curves (reference named curves or inline easing) ---
    sizeCurve: easeOutQuad       // size multiplier over lifetime
    velocityCurve: easeInCubic   // velocity multiplier over lifetime

    // --- Force Fields ---
    forceFields: [
        turbulence(strength, scale, speed),
        wind(vx, vy),
        vortex(x, y, strength, radius),
        attractor(x, y, strength, radius),
        repulsor(x, y, strength, radius),
        pathguide(pathName, attractStrength, flowStrength, radius)
    ]

    // --- Bounds & Collision ---
    // Mode: none, kill, bounce(damping), wrap
    // Shapes: box(x:, y:, w:, h:), line(x1, y1, x2, y2)
    bounds: bounce(0.7), box(x: -100, y: -100, w: 200, h: 200)

    // --- Sub-Emitters ---
    subEmitters: [{
        groupId: "sparkGroup",   // name of another particles block
        trigger: ondeath,        // onbirth, ondeath, oncollision, oninterval(0.1)
        probability: 0.8,        // spawn chance 0-1
        burstCount: 10,          // particles per trigger
        inheritVelocity: 0.5,    // fraction of parent velocity
        offsetX: 0, offsetY: 0   // spawn offset
    }]

    // --- Animation Integration ---
    animFile: "spark.anim"
    animSelector: type => fire
    0.0: anim("birth")           // lifetime-driven state at 0%
    0.8: anim("dying")           // lifetime-driven state at 80%
    onBounce: anim("impact")     // event-driven override
    onDeath: anim("explode")

    // --- Path Attachment ---
    attachTo: trailAnimPath      // emitter follows an animated path
    spawnCurve: burstAtEnd       // modulates emission rate over path lifetime

    // --- Emission Timing ---
    delay: 0                     // delay before first emission (seconds)
}
```

## Effect Recipes

These are starting points. Adjust values based on the user's description.

### Fire / Flame
```manim
#fire particles {
    count: 80
    emit: cone(dist: 10, distRand: 5, angle: up, angleSpread: 25deg)
    tiles: file("circle_soft.png")
    maxLife: 1.8
    speed: 60
    speedRand: 0.3
    gravity: 40
    gravityAngle: up
    size: 0.6
    sizeRand: 0.3
    fadeIn: 0.1
    fadeOut: 0.7
    colorStops: 0.0 #FF4400, 0.4 #FFAA00, 1.0 #FFFF88
    blendMode: add
}
```

### Smoke
```manim
#smoke particles {
    count: 60
    emit: cone(dist: 5, distRand: 3, angle: up, angleSpread: 30deg)
    tiles: file("smoke.png")
    maxLife: 3.0
    speed: 20
    speedRand: 0.4
    gravity: 15
    gravityAngle: up
    size: 0.4
    sizeRand: 0.3
    fadeIn: 0.2
    fadeOut: 0.5
    colorStops: 0.0 #888888, 0.5 #666666, 1.0 #444444
    blendMode: alpha
}
```

### Sparkles / Magic
```manim
#sparkles particles {
    count: 50
    emit: circle(r: 60, rRand: 30, angle: 0deg, angleSpread: 0deg)
    tiles: file("star.png")
    maxLife: 2.0
    speed: 15
    speedRand: 0.5
    size: 0.4
    sizeRand: 0.3
    fadeIn: 0.2
    fadeOut: 0.6
    colorStops: 0.0 #FFFFFF, 0.5 #88DDFF, 1.0 #4488FF
    blendMode: add
    rotSpeed: 45deg
    rotSpeedRand: 0.5
}
```

### Explosion (one-shot burst)
```manim
#explosion particles {
    count: 60
    emit: point(dist: 0, distRand: 15)
    tiles: file("circle_hard.png") file("flare.png")
    loop: false
    maxLife: 0.8
    lifeRand: 0.3
    speed: 200
    speedRand: 0.5
    gravity: 150
    gravityAngle: down
    size: 0.5
    sizeRand: 0.4
    fadeIn: 0.0
    fadeOut: 0.4
    colorStops: 0.0 #FFFF88, 0.5 #FF4400, 1.0 #882200
    blendMode: add
    emitSync: 0.9
}
```

### Rain
```manim
#rain particles {
    count: 150
    emit: box(w: 300, h: 5, angle: down + 5deg, angleSpread: 5deg)
    tiles: file("spark.png")
    maxLife: 1.2
    lifeRand: 0.3
    speed: 300
    speedRand: 0.15
    size: 0.3
    sizeRand: 0.1
    fadeIn: 0.05
    fadeOut: 0.9
    colorStops: 0.0 #AACCFF, 1.0 #6688CC
    autoRotate: true
}
```

### Snow
```manim
#snow particles {
    count: 80
    emit: box(w: 300, h: 5, angle: down, angleSpread: 15deg)
    tiles: file("dot.png")
    maxLife: 4.0
    lifeRand: 0.4
    speed: 30
    speedRand: 0.5
    size: 0.3
    sizeRand: 0.4
    fadeIn: 0.1
    fadeOut: 0.8
    colorStops: 0.0 #FFFFFF, 1.0 #CCDDFF
    rotSpeed: 20deg
    rotSpeedRand: 0.8
    forceFields: [turbulence(15, 0.01, 1.0)]
}
```

### Vortex / Swirl
```manim
#vortex particles {
    count: 100
    emit: circle(r: 80, rRand: 20, angle: 0deg, angleSpread: 0deg)
    tiles: file("dot.png")
    maxLife: 3.0
    speed: 5
    speedRand: 0.5
    size: 0.6
    sizeRand: 0.3
    fadeIn: 0.15
    fadeOut: 0.7
    colorStops: 0.0 #4488FF, 0.5 #FF44FF, 1.0 #44FFFF
    blendMode: add
    forceFields: [vortex(0, 0, 150, 200), attractor(0, 0, 30, 180)]
}
```

### Fountain
```manim
#fountain particles {
    count: 60
    emit: cone(dist: 0, distRand: 5, angle: up, angleSpread: 15deg)
    tiles: file("circle_hard.png")
    maxLife: 2.0
    lifeRand: 0.2
    speed: 150
    speedRand: 0.2
    gravity: 200
    gravityAngle: down
    size: 0.4
    sizeRand: 0.2
    fadeIn: 0.05
    fadeOut: 0.8
    colorStops: 0.0 #4488FF, 0.5 #88CCFF, 1.0 #224488
    blendMode: add
}
```

### Firework (with sub-emitter)
```manim
#fireworkLaunch particles {
    count: 8
    emit: cone(dist: 0, distRand: 5, angle: up, angleSpread: 10deg)
    tiles: file("circle_hard.png")
    maxLife: 1.0
    lifeRand: 0.2
    speed: 120
    speedRand: 0.2
    gravity: 100
    gravityAngle: down
    size: 0.4
    fadeIn: 0.0
    fadeOut: 0.8
    colorStops: 0.0 #FFFFFF, 1.0 #FFFF88
    blendMode: add
    emitSync: 0.1
    subEmitters: [{
        groupId: "fireworkBurst"
        trigger: ondeath
        probability: 1.0
        burstCount: 20
    }]
}

#fireworkBurst particles {
    count: 0
    emit: point(dist: 0, distRand: 25)
    tiles: file("star.png") file("dot.png")
    loop: false
    maxLife: 1.2
    lifeRand: 0.3
    speed: 80
    speedRand: 0.5
    gravity: 60
    gravityAngle: down
    size: 0.3
    sizeRand: 0.3
    fadeIn: 0.0
    fadeOut: 0.5
    colorStops: 0.0 #FFFF44, 0.5 #FF4400, 1.0 #880000
    blendMode: add
}
```

### Embers / Floating sparks
```manim
#embers particles {
    count: 30
    emit: box(w: 100, h: 10, angle: up, angleSpread: 30deg)
    tiles: file("dot.png")
    maxLife: 3.0
    lifeRand: 0.5
    speed: 15
    speedRand: 0.6
    gravity: 10
    gravityAngle: up
    size: 0.3
    sizeRand: 0.4
    fadeIn: 0.1
    fadeOut: 0.6
    colorStops: 0.0 #FF8844, 0.5 #FF4400, 1.0 #882200
    blendMode: add
    forceFields: [turbulence(20, 0.015, 1.5)]
}
```

### Heal / Buff aura
```manim
#healAura particles {
    count: 40
    emit: circle(r: 30, rRand: 15, angle: up, angleSpread: 30deg)
    tiles: file("star.png")
    maxLife: 1.5
    speed: 25
    speedRand: 0.4
    gravity: 20
    gravityAngle: up
    size: 0.3
    sizeRand: 0.3
    fadeIn: 0.15
    fadeOut: 0.6
    colorStops: 0.0 #44FF44, 0.5 #88FFAA, 1.0 #FFFFFF
    blendMode: add
    rotSpeed: 30deg
}
```

## Editing Existing Particles

When the user wants to modify an existing particle effect:

1. **Read** the current particle block from the file
2. **Identify** which properties need to change based on the request
3. **Edit surgically** — only change the specific properties requested, preserving everything else
4. If the user's request is vague ("make it look better"), suggest specific improvements and confirm

**Common modification patterns:**
- "Make it bigger" → increase `count`, `size`, emission area (`w`/`h`/`r`), or `angleSpread`
- "Make it faster" → increase `speed`, decrease `maxLife`
- "Make it glow more" → switch to `blendMode: add`, brighter `colorStops`, add `glow.png` tile
- "More spread out" → increase `angleSpread`, `distRand`, emission area
- "Add gravity" → add `gravity` + `gravityAngle`
- "Make it loop/one-shot" → toggle `loop`, adjust `emitSync` for bursts
- "Change color" → update `colorStops`
- "Add turbulence" → add `forceFields: [turbulence(strength, scale, speed)]`

## Guidelines

- **No `version: 1.0` header** unless creating a brand new `.manim` file from scratch (existing files already have it)
- **No programmable wrapper** unless the user asks for one or the context requires it
- **Particle blocks are top-level** — they sit at file root alongside other elements, not nested inside programmable
- **Name the effect** with a descriptive `#name` — use camelCase matching the effect (e.g., `#fireTrail`, `#healBurst`)
- **Use direction constants** (`up`, `down`, `left`, `right`) instead of raw degree numbers when they fit
- **Use `deg` suffix** for angles (e.g., `25deg`, `45deg`) — it's more readable than bare numbers
- **Additive blending** (`blendMode: add`) for glowing/light effects (fire, sparks, magic, explosions)
- **Alpha blending** (`blendMode: alpha`) for opaque/physical effects (smoke, rain, snow, dust)
- **Sub-emitter children** use `count: 0` and `loop: false` — they're driven entirely by the parent
- When adding curves, define them in a `curves { }` block in the same file (before or after the particles block)
- When using paths for emission or pathguide, define them in a `paths { }` block
- If the user describes a complex multi-stage effect (e.g., firework = launch + burst), create multiple particle groups with sub-emitters
- Always check what tiles exist before using `file("...")` — don't assume a tile exists

## Asking for Confirmation

Ask the user before proceeding when:
- The request would fundamentally change the nature of an effect (explosion to gentle glow)
- Multiple reasonable interpretations exist ("add some particles" — what kind?)
- No suitable tile images were found in the project
- The user asks for something the particle system can't do (particles are 2D sprites, not 3D meshes)

When asking, offer concrete options: "Did you mean (A) a soft ambient glow using circle_soft with additive blend, or (B) a pulsing ring effect using the ring tile?"

## Reference Files

If the syntax reference above isn't enough (e.g., for advanced features, edge cases, or understanding runtime behavior), consult these files in the hx-multianim repo:

| File | What it covers |
|------|----------------|
| `docs/particles.md` | Full particles guide with detailed explanations and examples |
| `docs/manim.md` | Complete .manim language reference (search for "particles" section) |
| `docs/manim-reference.md` | Quick-lookup reference for all .manim elements |
| `src/bh/multianim/MacroManimParser.hx` | Parser source — search for `parseParticles()`, `parseEmitMode()`, `parseForceFields()`, `parseBoundsCombined()`, `parseSubEmitters()` |
| `src/bh/multianim/MultiAnimBuilder.hx` | Builder source — search for `createParticleImpl()`, `resolveParticleCurveRef()` |
| `src/bh/base/Particles.hx` | Runtime — `ParticleGroup` class with all runtime defaults and force field types |

**Existing particle examples** (good for seeing real-world patterns):
- `../hx-multianim-playground/public/assets/demos/animation/particles-basics.manim` — fire, rain, sparkles, explosion
- `../hx-multianim-playground/public/assets/demos/animation/particles-motion.manim` — vortex, turbulence, attractor/repulsor, fountain
- `../hx-multianim-playground/public/assets/demos/animation/particles-colors.manim` — color stops, size/velocity curves
- `../hx-multianim-playground/public/assets/demos/animation/particles-bounds.manim` — kill, bounce, wrap, line walls
- `../hx-multianim-playground/public/assets/demos/animation/particles-paths.manim` — path emission, pathguide force field
- `../hx-multianim-playground/public/assets/demos/animation/particles-subemitters.manim` — fireworks, bounce sparks
