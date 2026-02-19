# Paths, Curves & AnimatedPath Improvements

## High Priority (quick wins)

- [ ] Inline easing names in animatedPath curve slots — allow `alphaCurve: easeInQuad` directly without requiring a separate `curves{}` block definition
- [ ] AnimatedPath easing shorthand — `easing: easeOutCubic` as shortcut for `0.0: progressCurve: <inline>`
- [ ] Non-visual unit tests for AnimatedPath in BuilderUnitTest — curve evaluation values, event firing order, loop/pingPong cycles, checkpoint resolution, normalization correctness, edge cases (dt=0, rate>1.0)

## Medium Priority (features)

- [ ] Projectile path integration (game) — AnimatedPath-based projectile option using `Stretch(towerPos, targetPos)` normalization, define flight characteristics in .manim instead of hardcoded physics
- [ ] Particles emit along named .manim paths — replace flat `Path(points)` emit mode with full path system: `emit: path(myBezierPath)`, particles born at positions sampled along curve with velocity tangent to it
- [ ] Path operations: reverse, subpath, append — `reverse(outward)`, `subpath(outward, 0.0, 0.5)`, `ref(outward)` for composing paths from existing ones (boomerang projectiles, patrol routes, reusable fragments)
- [ ] Multi-color curve stops — per-segment color pairs instead of single global `setColorRange(start, end)`, enabling proper gradients (e.g. red -> orange -> yellow)

## Lower Priority

- [ ] `attachToPath` .manim element — declarative path-following without custom Haxe code, builder handles `update(dt)` internally applying position/scale/alpha from AnimatedPathState
- [ ] Path `getClosestRate(point)` reverse lookup — given world position, find nearest rate on path (enables snapping to paths, path-based collision, slider-on-curve interactions)
- [ ] `pathGuide` force field for particles — attract particles toward a path and nudge along its direction (magical streams, fire trails along curves)
- [ ] Curve-driven parameter animation — `slot.animateParameter("brightness", from, to, curve, duration)` for smooth transitions between parameter states
