

FIX: 
===================================
error on root objects setting position - especially #name pixels(...): 100, 100 <- 100,100 is ignored
repeatable grid: scale ignored for dy/dy?
fix html/implement text
dynamicToParamValue - fix passing 0x, # and similar
write examples of all pos transforms, especially root nodes and builderResult.offset
fix double reload issue
hex coordinate system offset support 


NEXT
===================================
conditionals ELSE??


particles:
    loop/non-loop support
    animSM support?
    events - onEnd, onGroundHit?



Animations - easing & events
paths: 
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
* bit expression - support for any bit and all bits (e.g. grid direction)
# stateanim:
* color replace? 
* align elements (or at least center placeholders)
* animSM can mark loop as forever to skip inf loop check


next major release
===================================
* tilegroup support:  ninepatch 
* tilegroup REPEAT - extract into single func
* radio: 
    * paired uielement (click on label to change radio)
* named/optional parameters for filters


next major release
========================
 # multianim:
* subelements - handle nested subelements, keep state, don't query each time
* layouts -> relativeLayouts & absoluteScreens? layers support - support xy - layouts(layout node name, layout [,index] ): resolve layouts & palette references on load?
* mask element?
* uielements -> send initial change to uievents so control value can be synced to logic OR save/restore state for full page reloads & similar
* move uielements to separate list, don't check interfaces all the time
* add myhtml text from escape
* hex/grid xy -> enable scale & translate - has offset for now
* custom h2d.object subclasses with repeats to index or grid to index functionality

* optimize grid/hex coordinate system so it doesn't walk the tree all the time
* store pos for expressions/references so error can include pos
* fix scale / offset  - scaling affects offset, is that ok?
* draggable scrollbar 

* text width for align revisit
* scrollable: whole disabled (all items to disabled)
* switch to macro builder everywhere?




next major release
========================
* setting editor


will not implement:
===================
* affine transformation on node?
* object to store builder with name/params for rebuilds? (done?)









https://github.com/darmie/wrenparse/blob/master/src/wrenparse/WrenLexer.hx#L105
http://simn.github.io/hxparse/hxparse/index.html
https://github.com/Simn/hxparse/blob/master/README.md
https://github.com/benmerckx/haxeparser/blob/813b026d12123d8a3a0ed9bb0150acd546ba2a07/src/haxeparser/HaxeLexer.hx#L198

