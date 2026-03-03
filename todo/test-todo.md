# Test TODO

23 test files, ~1506 test methods, 95 visual test examples.

## Priority Table

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 1 | Card hand orchestration | Full state machine, drag, targeting, card-to-card, animations (layout math covered) | High |
| 2 | .anim typed filter runtime | Runtime filter application via AnimationSM, state conditionals, playlist filters | High |
| 3 | Screen transition integration | ScreenManager integration (enum + pattern matching covered, runtime behavior not) | Medium |
| 4 | Animated path integration | Builder/codegen + createProjectilePath, getClosestRate (runtime API covered) | Medium |
| 5 | Interactive cursor metadata | cursor => "pointer", cursor.hover => "move", invalid suffix throws | Medium |
| 6 | Rich text codegen | @:manim codegen for richText styles/images, runtime parameter updates on HtmlText | Medium |
| 7 | Dynamic ref codegen | Macro-generated dynamicRef, nested refs via codegen path | Low |

## Gap Details

### 1. Card Hand Orchestration (HIGH)
Layout math fully tested (41 methods). Full state machine and orchestration untested.

- `setHand`, `drawCard`, `discardCard`, `updateCardParams`, `setCardEnabled`
- Card state machine (InHand -> Hovering -> Dragging -> Animating)
- Drag threshold, targeting mode, card-to-card detection
- `CardPlayed(TargetZone|NoTarget)`, `CardCombined` events
- `canPlayCard` / `canDragCard` veto callbacks, `onCardBuilt`
- Target registration, highlight callback, accepts filter
- Concurrent animations, z-order management, return animation

### 2. .anim Typed Filter Runtime (HIGH)
Parser + basic playback tested (36 methods). No state-conditional filter runtime tests.

- State-conditional filters (`@(state=>value)`, `@else`, `@default`) at runtime
- Playlist per-frame filters (`filter tint:`, `filter none`)
- Multiple filter combination, filter type coverage
- Filter changes when state selector changes

### 3. Screen Transition Integration (MEDIUM)
Enum + pattern matching tested. No ScreenManager integration.

- `isTransitioning` flag, input routing, transition interruption
- `finalizeTransition()`, modal dialog transitions, layer ordering

### 4. Animated Path Integration (MEDIUM)
Runtime API tested (50 methods). Builder/codegen path untested.

- `builder.createAnimatedPath()`, `createProjectilePath()` with Stretch
- Codegen `factory.createAnimatedPath_name()`
- `getClosestRate()` reverse lookup, easing shorthand resolution

### 5. Interactive Cursor Metadata (MEDIUM)
- `cursor => "pointer"`, `cursor.hover => "move"`, `cursor.disabled => "default"`
- Unknown `cursor.*` suffix throws
- CursorManager registry integration

### 6. Rich Text Codegen (MEDIUM)
TextMarkupConverter tested (56 methods). No codegen tests.

- `@:manim` codegen for `richText()` with styles/images
- Generated setters (`setStyleColor_`, `setStyleFont_`, `setImageTile_`)
- Runtime parameter updates propagating to HtmlText

### 7. Dynamic Ref Codegen (LOW)
Builder path tested (17 methods). No codegen path tests.

- Macro-generated dynamicRef access
- Nested refs via codegen path
