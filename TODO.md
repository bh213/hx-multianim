# Main goals

- allow code generation - programmable should be able to be generated in haxe macro with haxe code. Make sure all functionality is aligned with this goal. There should be update programmable functionality down the line as well
- some tools/testing might be split into separate repos. Most likely candidates are utils/  and playground.

FIX:
===================================


Components: allow setting various components via settings 

repeatable grid: scale ignored for dy/dy?
    - VALID BUG: GridIterator uses resolveAsInteger(dirX/dirY) directly
    - Grid's spacingX/spacingY is NOT applied to dx/dy values
    - If you have grid(32,32) and repeatable grid(1,0,5), dx=1 is treated as 1 pixel, not 32 pixels
    - See MultiAnimBuilder.hx:1409-1412
    - grid is not supposed to mean grid coordinate system but that it moves in x,y direction by grid cells

repeatable: inline array with $index, $value?
    - UNCLEAR: ArrayIterator exists with $index support
    - Need clarification on what specific syntax is missing

fix html/implement text
    - PARTIAL: createHtmlText() exists in MultiAnimBuilder.hx:1071-1074
    - Used when isHtml=true in TEXT node
    - HTMLTEXT case is commented out (lines 1816-1818) - incomplete feature
    - HtmlText works but may not be fully exposed in .manim DSL

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

 
 add data support in manim files, stuff like key/value, string, int, float, array, ability to get by name, maybe index, probably expression support. Maybe sort of programmable that just return data


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
    - Verify all triggers work correctly

Animations - easing & events
paths:
    - BASIC IMPLEMENTATION in AnimatedPath.hx
    - Supports: ChangeSpeed, Accelerate, Event, AttachParticles, RemoveParticles, ChangeAnimSMState
    - MISSING: Easing functions (only linear), grid/hex coordinate systems, start/end references
    grid & hex coordinate systems
    start, end references
    particles diff with direction & speed as variables
    make object follow animation, maybe based on center or extra point??



#animate

animate <path> by time {
    0.2s: event("event")
    2000ms: particleSystem("ps", lifetime: 1s), speed: 2.0)
    10%:
}

animate <path> by distance {
    10%:
    200px: event
}




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

* align elements (or at least center placeholders)
    - NOT IMPLEMENTED - no alignment code for placeholders
    - Would help center dynamic content in placeholders

* animSM can mark loop as forever to skip inf loop check
    - RELATED CODE: AnimationSM.hx:177-233 has maxIterations=1000 safety check
    - Some legitimate animations may hit this limit
    - Would need new flag to skip check for known-infinite loops


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
    - NOT IMPLEMENTED - filters use positional parameters only
    - See MultiAnimParser.hx filter parsing


next major release
========================
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

* mask element?
    - PARTIAL: h2d.Mask used internally in UIMultiAnimScrollableList.hx:21,65
    - NOT exposed as .manim element type
    - Would allow masking regions in DSL

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

* fix scale / offset  - scaling affects offset, is that ok?
    - DESIGN QUESTION - scaling does affect offset in current impl
    - May be intentional or may need separation

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

* switch to macro builder everywhere?
    - PARTIAL: MacroUtils.macroBuildWithParameters exists
    - Used in some places but not consistently
    - Would reduce boilerplate for placeholder bindings



next major release
========================
* setting editor
    - NOT IMPLEMENTED - no code references
    - Would be a tool for editing settings/configs


DONE
===================================
* store pos for expressions/references so error can include pos
    - IMPLEMENTED: MacroUtils.nodePos() macro and currentNodePos() helper
    - Enabled with -D MULTIANIM_TRACE
    - All builder errors now include position when flag is set

will not implement:
===================
* affine transformation on node?
* object to store builder with name/params for rebuilds? (done?)




https://github.com/darmie/wrenparse/blob/master/src/wrenparse/WrenLexer.hx#L105
http://simn.github.io/hxparse/hxparse/index.html
https://github.com/Simn/hxparse/blob/master/README.md
https://github.com/benmerckx/haxeparser/blob/813b026d12123d8a3a0ed9bb0150acd546ba2a07/src/haxeparser/HaxeLexer.hx#L198

