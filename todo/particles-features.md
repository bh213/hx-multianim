# Particles — Feature Checklist (Updated)

All items below have been implemented unless noted.

## Emission Shapes

- [x] `point(dist, distRandom)` — emit from a point, random direction, distance offset
- [x] `cone(dist, distRandom, angle, angleRandom)` — emit within a cone arc
- [x] `box(w, h, angle, angleRandom)` — emit from random position in rectangle
- [x] `circle(r, rRandom, angle, angleRandom)` — emit from circle edge (radial outward when angle=0)
- [x] `path(pathName)` — emit along named manim path
- [x] `path(pathName, tangent)` — emit along path with tangent-following velocity

## Tile Sources

- [x] `file("particle.png")` — single image file
- [x] `sheet("atlas", "tile")` — tile from sprite sheet
- [x] `sheet("atlas", "tile", index)` — indexed tile from sprite sheet
- [x] `generated(color(w, h, #color))` — generated solid color tile
- [x] Multiple tiles — array of tile sources for animation or random frame
- [x] AnimSM tile source — `animFile`, `animSelector`, rate-based `anim("name")`, event overrides

## Particle Count & Lifetime

- [x] `count: N` — max particles alive at once (default 100)
- [x] `maxLife: N` — particle lifetime in seconds
- [x] `lifeRandom: N` — random lifetime variance (multiplicative)
- [x] `loop: true/false` — re-emit dead particles indefinitely (default true)

## Emission Timing

- [x] `emitDelay: N` — fixed delay before particle appears after emit
- [x] `emitSync: N` — synchronization factor (0=fully random stagger, 1=all at once)

## Motion

- [x] `speed: N` — initial velocity magnitude
- [x] `speedRandom: N` — random speed variance (multiplicative)
- [x] `speedIncrease: N` — velocity acceleration/deceleration over time (exponential)
- [x] `gravity: N` — gravity force magnitude
- [x] `gravityAngle: N` — gravity direction in degrees (0=down in parser, converted to radians)

## Size

- [x] `size: N` — initial particle scale
- [x] `sizeRandom: N` — random size variance (multiplicative)

## Rotation

- [x] `rotationInitial: N` — initial rotation range in degrees
- [x] `rotationSpeed: N` — rotation speed in degrees/sec
- [x] `rotationSpeedRandom: N` — random rotation speed variance
- [x] `rotateAuto: true/false` — auto-rotate to face movement direction
- [x] `forwardAngle: N` — configurable forward direction in degrees (default 0 = right)

## Alpha / Fading

- [x] `fadeIn: N` — normalized time (0-1) for fade-in period
- [x] `fadeOut: N` — normalized time (0-1) when fade-out starts
- [x] `fadePower: N` — exponent for fade curve

## Color

- [x] Per-segment color curves: `0.0: colorCurve: curveName, #startColor, #endColor`
- [x] Supports named curves and inline easings
- ~~colorStart/colorEnd/colorMid/colorMidPos~~ — removed, replaced by colorCurve

## Curves (value over normalized lifetime)

- [x] `sizeCurve: curveName` — ICurve reference (named curve or inline easing)
- [x] `velocityCurve: curveName` — ICurve reference (named curve or inline easing)
- ~~sizeCurve: [(t,v)...]~~ — removed, replaced by ICurve references

## Sprite Animation

- [x] `animationRepeat: N` — how many times animation loops during lifetime (0=random static frame)

## Blend Mode

- [x] `blendMode: add | alpha` — particle rendering blend mode

## Relative / World Space

- [x] `relative: true/false` — particles relative to emitter (true) or world space (false)
- [x] Non-relative mode transforms position/velocity/scale to world coords at spawn

## Force Fields

- [x] `attractor(x, y, strength, radius)` — pulls particles toward a point
- [x] `repulsor(x, y, strength, radius)` — pushes particles away from a point
- [x] `vortex(x, y, strength, radius)` — spins particles (perpendicular force)
- [x] `wind(vx, vy)` — constant directional force
- [x] `turbulence(strength, scale, speed)` — noise-based displacement (sine wave approximation)
- [x] `pathguide(pathName, attractStrength, flowStrength, radius)` — attract + flow along path
- [x] Runtime mutable: `group.addForceField()`, `removeForceFieldAt()`, `clearForceFields()`

## Bounds / Collision

- [x] `boundsMode: none` — no boundary checking (default)
- [x] `boundsMode: kill` — remove particle when leaving bounds
- [x] `boundsMode: bounce(damping)` — reflect velocity at bounds
- [x] `boundsMode: wrap` — teleport to opposite side
- [x] `boundsMinX/boundsMaxX/boundsMinY/boundsMaxY` — boundary rectangle
- [x] `boundsLine: x1, y1, x2, y2` — one-sided line boundary (multiple allowed)

## Trails

- ~~Removed entirely~~ — trail tracking, rendering, and all related fields deleted

## Sub-Emitters

- [x] `subEmitters: [{ groupId, trigger, probability, ... }]` — array of sub-emitter configs
- [x] `trigger: onBirth | onDeath | onCollision | onInterval(seconds)` — trigger conditions
- [x] `probability: N` — chance of triggering (0.0-1.0)
- [x] `inheritVelocity: N` — velocity inheritance factor (now implemented)
- [x] `offsetX/offsetY: N` — position offset from parent (now implemented)
- [x] Actual particle spawning via `emitBurstAt()` — fully functional

## AnimatedPath Integration

- [x] `emit: path(pathName)` — emit along named curve path
- [x] `emit: path(pathName, tangent)` — velocity follows path tangent
- [x] `attachTo: animPathName` — emitter position tracks animated path
- [x] `spawnCurve: curveName` — modulate emission rate over attached path's lifetime
- [x] `emitBurst(count)` — runtime API to force-emit N particles immediately

## AnimSM Tile Source

- [x] `animFile: "path.anim"` — load .anim file for tile extraction
- [x] `animSelector: key => value` — state selector for AnimSM
- [x] `0.0: anim("stateName")` — lifetime-driven animation states
- [x] `onBounce: anim("name")` — event-driven animation override on bounce
- [x] `onDeath: anim("name")` — event-driven animation override on death
