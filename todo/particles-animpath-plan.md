# Particles + AnimatedPath Integration Plan

Goal: Make particles work with animated paths for effects like trail particles along projectiles, emitting from moving path points, and path-driven spawn control. Must be fast — no per-particle `getClosestRate()` in hot loops where avoidable.

## Features (ordered by value/effort)

### 1. Emit along named path (HIGH VALUE, MEDIUM EFFORT)

Replace the flat `Path(points)` emit mode with the full path system.

**Syntax:**
```manim
particles {
    emit: path(myBezierPath)               # sample random positions along curve
    emit: path(myBezierPath, tangent)      # + initial velocity follows tangent
}
```

**Implementation:**
- New `PartEmitMode` variant: `CurvePath(path:Path, tangentAlign:Bool)`
- On `init()`: `rate = rand()` → `path.getPoint(rate)` for position, `path.getTangentAngle(rate)` for velocity direction
- No `getClosestRate()` — just forward sampling, O(1) per particle
- Builder resolves path name via existing `getPaths().getPath(pathName)`
- Parser: extend `parseParticlesEmitMode()` to recognize `path(name)` and `path(name, tangent)`

**Why fast:** Single `getPoint()` + `getTangentAngle()` call per spawn, no per-frame cost.

### 2. Moving emitter: attach particle group to AnimatedPath (HIGH VALUE, MEDIUM EFFORT)

Particle emitter follows a moving path position. Think: fire trail behind a projectile, sparks along a sword swing.

**Syntax:**
```manim
particles {
    emit: point(0, 0)
    attachTo: myAnimPath          # emitter position tracks animated path
}
```

**Implementation:**
- New field on `ParticleGroup`: `attachedPath:AnimatedPath` (nullable)
- In `ParticleGroup` update: if attached, read `attachedPath.getState().position` → set group's `dx, dy` offset
- Particles use `isRelative: false` (world coords) so already-emitted particles stay in world space while new ones spawn at moving position
- Builder: resolve animPath name, store reference
- Parser: add `attachTo:` property in particles block

**Why fast:** Just reads cached state from AnimatedPath (which is already being updated externally). O(1) per frame, not per particle.

**Important:** The AnimatedPath must be updated by the user before the Particles system syncs. Document this ordering requirement.

### 3. Curve-driven spawn rate (MEDIUM VALUE, LOW EFFORT)

Control particle emission rate over the animated path's lifetime using a custom curve.

**Syntax:**
```manim
#trail animatedPath {
    path: arc1
    type: time
    duration: 2.0
    0.0: custom("spawnRate"): burstCurve    # 0..1 mapped to 0..maxCount
}
```

No new particle syntax needed — user code reads `state.custom.get("spawnRate")` and calls `group.emitCount(n)` or similar. This is a usage pattern, not a new feature. Document it as a recipe.

**Alternative** — if we want it declarative:

```manim
particles {
    attachTo: myAnimPath
    spawnCurve: burstCurve           # references a named curve
}
```

Add `spawnCurve` to `ParticleGroup`. On update, evaluate curve at `attachedPath.getState().rate` to get spawn multiplier (0 = none, 1 = full rate). Modulates emission timing.

**Why fast:** Single curve eval per frame, not per particle.

### 4. Emit at path events (MEDIUM VALUE, LOW EFFORT)

Burst-emit particles when an animated path fires a named event (e.g., emit sparks at impact point).

**Syntax** — runtime API only, no .manim syntax needed:
```haxe
animPath.onEvent = function(name, state) {
    if (name == "impact") {
        particleGroup.dx = Std.int(state.position.x);
        particleGroup.dy = Std.int(state.position.y);
        particleGroup.emitBurst(20); // new method: force-emit N particles now
    }
};
```

**Implementation:**
- Add `emitBurst(count:Int)` to `ParticleGroup` — force-init N particles immediately regardless of emission timer
- This is useful beyond path integration (any event-driven burst)

**Why fast:** Only runs on event, not per frame.

### 5. Sub-emitter spawning (EXISTING TODO, MEDIUM EFFORT)

Already parsed and stubbed. Implement actual spawning in `triggerSubEmitters()`.

**Implementation:**
- `subGroup.emitBurst(1)` at particle position with optional velocity inheritance
- Reuses `emitBurst()` from feature 4
- Set `dx/dy` offset to dying particle's position before burst

**Not directly animPath-related** but unlocks particle chains (explosion → debris → smoke) which compose well with path-driven effects.

---

## What NOT to do

- **No per-particle path following** — that's what AnimatedPath is for. Particles are fire-and-forget physics.
- **No AnimatedPath curves on individual particles** — too expensive, defeats the batch model. Use force fields (PathGuide) for soft guidance instead.
- **No automatic Particles ↔ AnimatedPath sync** — keep them decoupled, user controls update order.

## Implementation Order

1. `emitBurst()` on ParticleGroup — small, useful for everything else
2. Emit along named path — highest visual impact, clean implementation
3. `attachTo` moving emitter — enables trail effects, the main use case
4. `spawnCurve` (optional) — only if declarative control needed, otherwise document as recipe
5. Sub-emitter spawning — separate concern, do when ready

## Performance Summary

| Feature | Per-frame cost | Per-particle cost |
|---------|---------------|-------------------|
| Emit along path | 0 | O(1) on spawn only |
| attachTo | O(1) read cached state | 0 |
| spawnCurve | O(1) curve eval | 0 |
| emitBurst | O(n) init particles | one-time |
| PathGuide (existing) | 0 | O(50) getClosestRate |

All new features are O(1) per frame or O(1) per spawn. The only expensive per-particle operation remains the existing PathGuide force field (which uses `getClosestRate` with 50-sample coarse search + golden-section refinement).
