# Particles — Current Feature Checklist

Mark `[x]` to change or implement
Mark `[-]` to remove


## Emission Shapes

- [ ] `point(dist, distRandom)` — emit from a point, random direction, distance offset
- [ ] `cone(dist, distRandom, angle, angleRandom)` — emit within a cone arc
- [ ] `box(w, h, angle, angleRandom)` — emit from random position in rectangle
- [ ] `circle(r, rRandom, angle, angleRandom)` — emit from circle edge (radial outward when angle=0)
- [-] `Path(points, angle, angleRandom)` — emit along polyline path (runtime only, no parser support)
- [x] - manim paths - reference

## Tile Sources

- [ ] `file("particle.png")` — single image file
- [ ] `sheet("atlas", "tile")` — tile from sprite sheet
- [ ] `sheet("atlas", "tile", index)` — indexed tile from sprite sheet
- [ ] `generated(color(w, h, #color))` — generated solid color tile
- [+] Multiple tiles — array of tile sources, used for sprite animation or random frame
- [+] AnimSM with selectors, multiple animSM states at specific times

## Particle Count & Lifetime

- [ ] `count: N` — max particles alive at once (default 100)
- [ ] `maxLife: N` — particle lifetime in seconds
- [ ] `lifeRandom: N` — random lifetime variance (multiplicative, e.g. 0.3 = +/-30%)
- [ ] `loop: true/false` — re-emit dead particles indefinitely (default true)

## Emission Timing

- [ ] `emitDelay: N` — fixed delay before particle appears after emit
- [ ] `emitSync: N` — synchronization factor (0=fully random stagger, 1=all at once)

## Motion

- [ ] `speed: N` — initial velocity magnitude
- [ ] `speedRandom: N` — random speed variance (multiplicative)
- [ ] `speedIncrease: N` — velocity acceleration/deceleration over time (exponential)
- [ ] `gravity: N` — gravity force magnitude
- [ ] `gravityAngle: N` — gravity direction in degrees (0=down in parser, converted to radians)

## Size

- [ ] `size: N` — initial particle scale
- [ ] `sizeRandom: N` — random size variance (multiplicative)

## Rotation

- [ ] `rotationInitial: N` — initial rotation range in degrees (random within +/-range)
- [ ] `rotationSpeed: N` — rotation speed in degrees/sec
- [ ] `rotationSpeedRandom: N` — random rotation speed variance
- [ ] `rotateAuto: true/false` — auto-rotate to face movement direction
- [ ] specify what is "Forward" for sprintes/animSM? Ask me if unsure

## Alpha / Fading

- [ ] `fadeIn: N` — normalized time (0-1) for fade-in period (default 0.2)
- [ ] `fadeOut: N` — normalized time (0-1) when fade-out starts (default 0.8)
- [ ] `fadePower: N` — exponent for fade curve (1=linear, >1=slower start)

## Color

- [-] `colorStart: #RRGGBB` — color at birth
- [-] `colorEnd: #RRGGBB` — color at death
- [-] `colorMid: #RRGGBB` — optional mid-point color for 3-point gradient
- [-] `colorMidPos: N` — position of mid color (0.0-1.0, default 0.5)
- [+] Color interpolation — linear lerp between color stops, per-channel RGB, maybe use curve?

## Curves (value over normalized lifetime)

- [-] `sizeCurve: [(t, val), ...]` — size multiplier curve
- [-] `velocityCurve: [(t, val), ...]` — velocity multiplier curve
- [-] Linear interpolation between curve points
- sizeCurve: use manim curve, ref or inline (if supported)
- velocityCurve: use manim curve, ref or inline (if supported)

## Sprite Animation

- [ ] `animationRepeat: N` — how many times animation loops during lifetime (0=random static frame)

## Blend Mode

- [ ] `blendMode: add | alpha` — particle rendering blend mode

## Relative / World Space

- [ ] `relative: true/false` — particles relative to emitter (true) or world space (false)
- [ ] Non-relative mode transforms position/velocity/scale to world coords at spawn

## Force Fields

- [ ] `attractor(x, y, strength, radius)` — pulls particles toward a point
- [ ] `repulsor(x, y, strength, radius)` — pushes particles away from a point
- [ ] `vortex(x, y, strength, radius)` — spins particles (perpendicular force)
- [ ] `wind(vx, vy)` — constant directional force
- [ ] `turbulence(strength, scale, speed)` — noise-based displacement (sine wave approximation)
- [ ] `pathguide(pathName, attractStrength, flowStrength, radius)` — attract toward + flow along a named path (uses `getClosestRate`, expensive)

## Bounds / Collision

- [ ] `boundsMode: none` — no boundary checking (default)
- [ ] `boundsMode: kill` — remove particle when leaving bounds
- [ ] `boundsMode: bounce(damping)` — reflect velocity at bounds
- [ ] `boundsMode: wrap` — teleport to opposite side
- [ ] `boundsMinX/boundsMaxX/boundsMinY/boundsMaxY` — boundary rectangle

## Trails (parsed + data tracked, NOT rendered)

- [ ] `trailEnabled: true/false` — enable trail history tracking per particle
- [ ] `trailLength: N` — number of position history entries (as int)
- [ ] `trailFadeOut: true/false` — whether trail alpha fades along length
- [ ] **Note: trail history array is maintained but never drawn as geometry**

## Sub-Emitters (parsed + built, spawning NOT implemented)

- [ ] `subEmitters: [{ groupId, trigger, probability, ... }]` — array of sub-emitter configs
- [ ] `trigger: onBirth` — spawn when parent particle is born
- [ ] `trigger: onDeath` — spawn when parent particle dies
- [ ] `trigger: onCollision` — spawn on bounds collision
- [ ] `trigger: onInterval(seconds)` — spawn periodically during particle life
- [ ] `probability: N` — chance of triggering (0.0-1.0)
- [ ] `inheritVelocity: N` — velocity inheritance factor (parsed, not used at runtime)
- [ ] `offsetX/offsetY: N` — position offset from parent (parsed, not used at runtime)
- [ ] **Note: trigger detection works, but actual particle spawning is stubbed out (empty code blocks)**

## Runtime API (Particles class)

- [ ] `new Particles(?parent)` — create particle system
- [ ] `addGroup(group)` — add a named particle group
- [ ] `removeGroup(id)` — remove group by name
- [ ] `getGroup(id)` — get group by name
- [ ] `getGroups()` — iterate all groups
- [ ] `onEnd()` — dynamic callback when all groups finish (default: `this.remove()`)

## Runtime API (ParticleGroup)

- [ ] `enabled` — enable/disable group (disabling removes+resets)
- [ ] `blendMode` — set blend mode
- [ ] `id` — group name (read-only)
- [ ] All properties above are settable but use `(default, null)` access

## Builder API

- [ ] `createParticles("name")` — build particles from named .manim node
- [ ] `createParticleFromDef(def, name)` — build from ParticlesDef directly
- [ ] All values support `$references` to programmable parameters
- [ ] Angles converted from degrees (parser) to radians (runtime) by builder

## Codegen (ProgrammableBuilder)

- [ ] Particles nodes in programmable blocks generate runtime builder calls
- [ ] `$param` references resolved against programmable parameters

## Planned: AnimatedPath Integration

- [ ] FEATURE: `emit: path(pathName)` — emit along named curve path (random position sampling, O(1) per spawn)
- [ ] FEATURE: `emit: path(pathName, tangent)` — same + initial velocity follows path tangent direction
- [ ] FEATURE: `attachTo: animPathName` — emitter position tracks an animated path (trail effects, sparks along moving object)
- [ ] FEATURE: `spawnCurve: curveName` — modulate emission rate over attached path's lifetime using a named curve
- [ ] FEATURE: `emitBurst(count)` — runtime API to force-emit N particles immediately (event-driven bursts)

## Planned: Sub-Emitter Spawning

- [ ] FEATURE: Implement actual particle spawning in `triggerSubEmitters()` (currently stubbed)
- [ ] FEATURE: Velocity inheritance from parent particle to sub-emitted particles
- [ ] FEATURE: Position offset (offsetX/offsetY) applied to sub-emitted particles

## Planned: Trail Rendering

- [ ] FEATURE: Render trail history as ribbon/line geometry (data tracking already works)
