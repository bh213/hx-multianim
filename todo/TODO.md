# TODO

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 15 | Text input codegen | `@:manim` factory with `createTextInput()` | Low |
| 16 | ScreenManager: auto-reload on re-entry | `h2d.Graphics.onRemove()` calls `clear()`, wiping draw data. ScreenManager re-adds the same root without calling `clear()`+`load()`, so Graphics objects render empty. Every re-enterable screen must manually handle `UIEntering` → `clear()`+`load()`. ScreenManager should do this automatically. | Medium |

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)


v1.0

## Known Issues


- ~~Haxelib release~~ — DONE (1.0.0-rc.1, see [release.md](release.md))
- More hot reload integration tests — see [docs/hot-reload.md "Missing Tests"](../docs/hot-reload.md#missing-tests-needed)
- Add blob47 utils for easier testing/dev/selection
- ~~MCP server~~ — DONE (DevBridge 31 tools)


## After 1.0
- Text input codegen support (`@:manim` factory with `createTextInput()`)
- Negative codegen tests: `RVArray`/`RVArrayReference` throws, runtime `.x`/`.y` extraction throws
- Bit expression: support for any-bit and all-bits (e.g. grid direction)
- Radio: paired UIElement (click on label to change radio)
- Subelements: handle nested subelements, keep state, don't query each time (cache `Std.isOfType`)
- Layouts: absoluteScreens / layers support
- UIElements: move to separate list, don't check interfaces all the time
- Hex/grid XY: enable scale & translate
- Custom `h2d.Object` subclasses with repeats-to-index or grid-to-index functionality
- Optimize grid/hex coordinate system so it doesn't walk the tree each time
- Text width for align revisit
- Setting editor
- apply animPath tweening to element?
