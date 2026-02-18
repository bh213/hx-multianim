# Main goals

- allow code generation - programmable element should always work via builder.buildWithParameters or via macro system e.g. @:manim("test/examples/60-newPathCommands/newPathCommands.manim", "newPathCommands")
- some tools/testing might be split into separate repos. Most likely candidate is utils/. Playground already moved to ../hx-multianim-playground.

FIX:
===================================

Components: allow setting various components via settings

fix html/implement text
    - PARTIAL: `text(..., html: true)` parameter approach works via createHtmlText() in MultiAnimBuilder.hx
    - Standalone HTMLTEXT element type is intentionally deprecated/commented out
    - The `html: true` parameter on text elements is the supported approach

fix double reload issue
    - NO CODE REFERENCES - likely runtime behavior in playground/game
    - Need more context on when this occurs

hex coordinate system offset support
    - VALID - NOT IMPLEMENTED
    - Grid has SELECTED_GRID_POSITION_WITH_OFFSET supporting grid(x,y,offsetX,offsetY)
    - Hex only has SELECTED_HEX_POSITION - no offset variant
    - HexCoordinateSystem missing offset parameters

fix conditional not working with repeatable vars - e.g @(index greaterOrEqual 3)
    - LIKELY VALID BUG
    - Parser recognizes greaterThanOrEqual (MultiAnimParser.hx:2272)
    - Repeatable variables added to indexedParams during iteration
    - Bug may be timing - conditionals parsed/evaluated before repeatable sets the var


particles:
    loop/non-loop support
        - EXISTS: emitLoop property in Particles
    animSM support?
        - NOT IMPLEMENTED for particles
    events - onEnd, onGroundHit?
        - Collision triggers exist for sub-emitters
        - No user-defined events system

sub-emitters
    - LARGELY IMPLEMENTED (parsing + building + runtime scaffolding)
    - Full parsing: parseSubEmitter(), parseSubEmitters() in MultiAnimParser
    - Runtime: Particles.hx with SubEmitTrigger, triggerSubEmitters(), checkIntervalSubEmitters()
    - Triggers: OnBirth, OnDeath, OnCollision, Interval
    - REMAINING: Implement actual particle spawning in triggerSubEmitters() and checkIntervalSubEmitters() (currently stubbed)


next major release
===================================
* generic components support
    - NOT IMPLEMENTED
    - Would allow reusable component patterns

* bit expression - support for any bit and all bits (e.g. grid direction)
    - NOT IMPLEMENTED
    - Would help with grid direction bitfields

# stateanim:
* color replace?
    - PARTIAL: replaceColor filter exists in MultiAnimParser
    - May not be fully exposed for stateanim use


next major release
===================================
* tilegroup support: ninepatch
    - NOT IMPLEMENTED - TileGroup exists but no ninepatch integration

* tilegroup REPEAT - extract into single func
    - Code deduplication opportunity — REPEAT/REPEAT2D already work with TileGroup mode

* radio:
    * paired uielement (click on label to change radio)
        - NOT IMPLEMENTED
        - Currently only checkbox is clickable, not accompanying label

next major release
========================

# better reload behaviour
Reload white system is live, requires tracking, custom h2d.object?

 # multianim:
* subelements - handle nested subelements, keep state, don't query each time
    - PARTIAL: UIElementSubElements interface exists
    - UIScreen queries via Std.isOfType each time - could cache

* layouts -> relativeLayouts & absoluteScreens? layers support
    - PARTIAL: MultiAnimLayouts.hx exists
    - xy positioning and layer support incomplete

* uielements -> send initial change to uievents so control value can be synced to logic OR save/restore state for full page reloads
    - NOT IMPLEMENTED
    - Initial state not propagated to event listeners

* move uielements to separate list, don't check interfaces all the time
    - NOT IMPLEMENTED - performance optimization opportunity

* hex/grid xy -> enable scale & translate
    - PARTIAL - offset supported, scale & translate NOT implemented

* custom h2d.object subclasses with repeats to index or grid to index functionality
    - NOT IMPLEMENTED

* optimize grid/hex coordinate system so it doesn't walk the tree all the time
    - NOT IMPLEMENTED - could cache coordinate systems

* draggable scrollbar
    - PARTIAL: UIMultiAnimDraggable.hx exists for general dragging
    - ScrollableList needs draggable scrollbar thumb

* text width for align revisit
    - NOT IMPLEMENTED

* scrollable: whole disabled (all items to disabled)
    - NOT IMPLEMENTED

next major release
========================
* setting editor
    - NOT IMPLEMENTED


will not implement:
===================
* affine transformation on node?
