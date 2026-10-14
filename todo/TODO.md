# TODO

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## UI art requests

- A window dialog with a title bar and a close button: `OkCancelDialog` filling a `close` placeholder as Cancel, a `title` on `#dialogTitle(updatable)`, both optional; `std.manim`'s `#okCancelDialog` text colour `#ffffff00` is transparent. The rest of the UI-art batch (nine-patch modes, params and frames, cursor blocks, the dragged scrollbar, the vertical slider, the progress bar's contract) landed 2026-10-10.

## Known Issues

- More hot reload integration tests — see [docs/hot-reload.md "Missing Tests"](../docs/hot-reload.md#missing-tests-needed)
- Add blob47 utils for easier testing/dev/selection


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
