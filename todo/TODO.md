# TODO

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## V1
- hot reload
- tooltips
- visual tests
- haxelib release


### Particles
- Events: onEnd, onGroundHit (collision triggers exist for sub-emitters, no user-defined events)

### Other fixes
- Repeatable step scale for dx/dy
- HTML text: standalone `HTMLTEXT` element type is deprecated/commented out

## After 1.0

- Generic components support
- Bit expression: support for any-bit and all-bits (e.g. grid direction)
- StateAnim: color replace (replaceColor filter exists in MultiAnimParser, not fully exposed for stateanim)
- Radio: paired UIElement (click on label to change radio)
- Subelements: handle nested subelements, keep state, don't query each time (cache `Std.isOfType`)
- Layouts: absoluteScreens / layers support
- UIElements: send initial change event so control value can be synced to logic
- UIElements: move to separate list, don't check interfaces all the time
- Hex/grid XY: enable scale & translate
- Custom `h2d.Object` subclasses with repeats-to-index or grid-to-index functionality
- Optimize grid/hex coordinate system so it doesn't walk the tree each time
- Text width for align revisit
- Setting editor
