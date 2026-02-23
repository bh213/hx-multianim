# TODO

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## Fixes

### Color format & alpha inconsistencies
- PixelOutline: colors passed to `Vector4.setColor()` without `addAlphaIfNotPresent()` → alpha=0, outline invisible
- Graphics `beginFill`/`lineStyle`: get ARGB via `addAlphaIfNotPresent()`, but API expects RGB (works by accident due to `& 0xFF` masking)
- `Tile.fromColor`: gets ARGB but API expects RGB (works in practice)
- Particle colors: no masking or alpha handling — works by accident with `& 0xFF`
- AnimatedPath `lerpColor`: same RGB-only pattern as Particles
- `textColor` masking inconsistent: masked in static text but not in incremental or codegen
- `dropShadow.color` not masked

### Particles
- Sub-emitters: implement actual particle spawning in `triggerSubEmitters()` and `checkIntervalSubEmitters()` (currently stubbed)
- AnimSM support
- Events: onEnd, onGroundHit (collision triggers exist for sub-emitters, no user-defined events)

### Other fixes
- Repeatable step scale for dx/dy
- HTML text: standalone `HTMLTEXT` element type is deprecated/commented out
- Double reload issue

## Features

- Generic components support
- Bit expression: support for any-bit and all-bits (e.g. grid direction)
- StateAnim: color replace (replaceColor filter exists in MultiAnimParser, not fully exposed for stateanim)
- Radio: paired UIElement (click on label to change radio)

## Later / Optimization

- Subelements: handle nested subelements, keep state, don't query each time (cache `Std.isOfType`)
- Layouts: absoluteScreens / layers support
- UIElements: send initial change event so control value can be synced to logic
- UIElements: move to separate list, don't check interfaces all the time
- Hex/grid XY: enable scale & translate
- Custom `h2d.Object` subclasses with repeats-to-index or grid-to-index functionality
- Optimize grid/hex coordinate system so it doesn't walk the tree each time
- Text width for align revisit
- Setting editor
