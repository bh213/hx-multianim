# Main goals

- allow code generation - programmable element should always work via builder.buildWithParameters or via macro system e.g. @:manim("test/examples/60-newPathCommands/newPathCommands.manim", "newPathCommands")
- some tools/testing might be split into separate repos. Most likely candidates are utils/  and playground.

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
    - LARGELY IMPLEMENTED
    - Full parsing: parseSubEmitter(), parseSubEmitters() in MultiAnimParser
    - Building: MultiAnimBuilder.hx:2633-2644
    - Runtime: Particles.hx with SubEmitTrigger, triggerSubEmitters(), checkIntervalSubEmitters()
    - Triggers: OnBirth, OnDeath, OnCollision, Interval
    - REMAINING: Implement actual particle spawning in triggerSubEmitters() and checkIntervalSubEmitters() (currently stubbed)


next major release
===================================
* generic components support
    - NOT IMPLEMENTED - no code references found
    - Would allow reusable component patterns

* bit expression - support for any bit and all bits (e.g. grid direction)
    - NOT IMPLEMENTED - no anyBit/allBits code found
    - Would help with grid direction bitfields

# stateanim:
* color replace?
    - PARTIAL: replaceColor filter exists in MultiAnimParser.hx:3549
    - May not be fully exposed for stateanim use



next major release
===================================
* tilegroup support:  ninepatch
    - NOT IMPLEMENTED - TileGroup exists but no ninepatch integration
    - See MultiAnimBuilder.hx:14 (import), :276 (TileGroupMode)
    - ninepatch() element exists separately, would need merging

* tilegroup REPEAT - extract into single func
    - EXISTS: REPEAT/REPEAT2D work with TileGroup mode
    - See MultiAnimParser.hx:884-885, MultiAnimBuilder.hx:1397+
    - May be about code deduplication, not missing feature

* radio:
    * paired uielement (click on label to change radio)
        - NOT IMPLEMENTED - UIMultiAnimRadioButtons.hx exists
        - Currently only checkbox is clickable, not accompanying label
        - Would improve usability

* named/optional parameters for filters
    - DONE: Named parameters supported (e.g., `outline(size: 2, color: red)`)
    - Positional parameters still work for backward compatibility


next major release
========================

# better reload behaviour
Reload white system is live, requires tracking, custom h2d.object?

 # multianim:
* subelements - handle nested subelements, keep state, don't query each time
    - PARTIAL: UIElementSubElements interface exists in UIElement.hx:236-237
    - Used by UIMultiAnimRadioButtons, UIMultiAnimDropdown
    - UIScreen.hx:126-127 queries via Std.isOfType each time - inefficient
    - Could cache subelement lists

* layouts -> relativeLayouts & absoluteScreens? layers support - support xy - layouts(layout node name, layout [,index] ): resolve layouts & palette references on load?
    - PARTIAL: MultiAnimLayouts.hx exists
    - Some layout support present in builder/parser
    - xy positioning and layer support incomplete


* uielements -> send initial change to uievents so control value can be synced to logic OR save/restore state for full page reloads & similar
    - NOT IMPLEMENTED
    - Initial state not propagated to event listeners
    - Causes desync on page reload

* move uielements to separate list, don't check interfaces all the time
    - NOT IMPLEMENTED - uses Std.isOfType checks
    - Performance optimization opportunity

* add myhtml text from escape
    - NOT IMPLEMENTED - no myhtml references found
    - May be about a specific HTML text rendering library

* hex/grid xy -> enable scale & translate - has offset for now
    - PARTIAL - offset supported (SELECTED_GRID_POSITION_WITH_OFFSET)
    - scale & translate NOT implemented for coordinate systems

* custom h2d.object subclasses with repeats to index or grid to index functionality
    - NOT IMPLEMENTED
    - Would allow custom object types with built-in repeat/grid indexing

* optimize grid/hex coordinate system so it doesn't walk the tree all the time
    - NOT IMPLEMENTED
    - Currently recalculates coordinate system by walking tree
    - Could cache coordinate systems


* draggable scrollbar
    - PARTIAL: UIMultiAnimDraggable.hx exists for general dragging
    - UIMultiAnimScrollableList has scroll but not draggable scrollbar thumb
    - Would need to add thumb element + drag handling

* text width for align revisit
    - NOT IMPLEMENTED - no textWidth alignment code found
    - Text alignment may not respect width constraints

* scrollable: whole disabled (all items to disabled)
    - NOT IMPLEMENTED
    - Would propagate disabled state to all scrollable children


next major release
========================
* setting editor
    - NOT IMPLEMENTED - no code references
    - Would be a tool for editing settings/configs



will not implement:
===================
* affine transformation on node?



