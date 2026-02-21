# Main goals

- allow code generation - programmable element should always work via builder.buildWithParameters or via macro system e.g. @:manim("test/examples/60-newPathCommands/newPathCommands.manim", "newPathCommands")
- some tools/testing might be split into separate repos. Most likely candidate is utils/. Playground already moved to ../hx-multianim-playground.

FIX:
===================================

Color format & alpha inconsistencies:
    - PixelOutline: colors passed to Vector4.setColor() without addAlphaIfNotPresent() → alpha=0, outline invisible (Builder:3816-3817, Codegen:5064-5071)
    - Graphics beginFill/lineStyle: get ARGB via addAlphaIfNotPresent(), but API expects RGB (works by accident due to & 0xFF masking) (Builder:2338+, Codegen:2584+)
    - Tile.fromColor: gets ARGB via addAlphaIfNotPresent(), but API expects RGB (works in practice) (Builder:1424, Codegen:4439)
    - Particle colors: no masking or alpha handling — extraction works by accident with & 0xFF (Particles:676-678, lerpColor:732-742)
    - AnimatedPath lerpColor: same RGB-only pattern as Particles (AnimatedPath:376)
    - textColor masking inconsistent: masked in static text (Builder:1642) but not in incremental (Builder:2029) or codegen (Codegen:1760, 3865) — works because Heaps handles it
    - dropShadow.color not masked (Builder:2948) — works because Heaps handles it

~~hex coordinate system offset support~~ DONE
    - Implemented via $hex.offset(), $hex.doubled(), $hex.pixel() coordinate methods
    - Grid offset via $grid.pos(x, y, offsetX, offsetY)
    - Coordinate .x/.y extraction for expression use

fix conditional not working with repeatable vars - e.g @(index >= 3)
    - Parser recognizes greaterThanOrEqual (MultiAnimParser.hx:2272)
    - Repeatable variables added to indexedParams during iteration
    - Bug may be timing - conditionals parsed/evaluated before repeatable sets the var

particles:
    sub-emitters: implement actual particle spawning in triggerSubEmitters() and checkIntervalSubEmitters() (currently stubbed)
    animSM support?
    events - onEnd, onGroundHit? (collision triggers exist for sub-emitters, no user-defined events)

Next:
===================================
* generic components support
* 
* bit expression - support for any bit and all bits (e.g. grid direction)
* stateanim: color replace (replaceColor filter exists in MultiAnimParser, not fully exposed for stateanim)
~~tilegroup support: ninepatch~~ DONE
    - Decomposes 9-patch into 9 sub-tiles (corners/edges/center) added directly to TileGroup
    - Edges/center scaled to fill target dimensions
~~tilegroup REPEAT - extract into single func (dedup REPEAT/REPEAT2D)~~ DONE
    - Extracted resolveTileGroupRepeatAxis(), setTileGroupRepeatIterationParams(), cleanupTileGroupRepeatExtraVars()
    - REPEAT and REPEAT2D now share resolution logic
* radio: paired uielement (click on label to change radio)

Later:
===================================
* better reload behaviour - tracking, custom h2d.object?
* subelements - handle nested subelements, keep state, don't query each time (cache Std.isOfType)
* layouts -> absoluteScreens? layers support
* uielements -> send initial change to uievents so control value can be synced to logic
* move uielements to separate list, don't check interfaces all the time
* hex/grid xy -> enable scale & translate
* custom h2d.object subclasses with repeats to index or grid to index functionality
* optimize grid/hex coordinate system so it doesn't walk the tree all the time
* text width for align revisit
* scrollable: whole disabled (all items to disabled)
* setting editor

will not implement:
===================
* affine transformation on node?
