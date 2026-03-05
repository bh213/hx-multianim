# MCP Improvements for AI Agent Usability

Improvements identified from analyzing proto-brick (a real game using hx-multianim) and the current MCP tooling.

## P0 - Critical for Agent Productivity

### Semantic validation in `eval_manim`
Currently `eval_manim` only parses and returns node names. Extend it to validate:
- Font names against registered fonts
- Atlas/tile references against loaded sheets
- Parameter type compatibility
- `builderParameter` name collisions
- Expression correctness (undefined `$refs`, type mismatches)

### `reload` should return errors directly
Currently requires a separate `get_errors` call after reload. The reload response should include any parse/build errors with structured data: `{ file, line, col, message, suggestion, context_snippet }`.

### `describe_wiring` tool
Given a `.manim` programmable name, return the expected Haxe wiring code:
- Which `builderParameter()` placeholders exist and their names
- Which callbacks are needed
- What settings are available
- Generate example Haxe code for `MacroUtils.macroBuildWithParameters`

This is the biggest knowledge gap for AI agents — the mapping between `.manim` `builderParameter("name")` and Haxe lambda parameters is opaque without deep framework knowledge.

## P1 - High Value

### Resource discovery tools

**`list_fonts`** - Return all registered font names with type (bitmap/SDF) and properties (size, lineHeight).

**`list_atlases`** - Return loaded atlas names and their tile/sprite names. Essential for agents to pick sprites when building `.manim` UI.

**`suggest_completion`** - Given a partial `.manim` snippet and cursor position, return valid completions (element types, parameter names, font names, tile names). LSP-like but via MCP.

### Screen scaffolding
**`create_screen`** tool or template that generates:
- `res/manim/screenname.manim` skeleton with `#ui programmable() {}`
- `src/screens/ScreenName.hx` extending `UIScreenBase` with `load()` and `onScreenEvent()`
- Registration code for `Main.hx`

Reduces the 3-file ceremony to a single tool call.

### Live element manipulation

**`modify_element`** - Change position, visibility, text, color of a live element without editing files. For rapid prototyping.

**`add_element`** - Dynamically add a new programmable instance to the scene without file edits.

## P2 - Nice to Have

### Higher-level drag-drop DSL
The drag-drop wiring in GameScreen.hx is ~80 lines of Haxe for what is conceptually "drag sidebar bricks to grid cells." Consider:
- `.manim` syntax: `draggable(source: "sidebarBrick", dropZones: grid(10, 8))`
- Or a helper class that takes grid dimensions and a builder name

### Named anchor points / coordinate sharing
Allow `.manim` to define named positions (`#gridOrigin point: 160, 360`) queryable from Haxe, so coordinates are defined in one place instead of duplicated between `.manim` and `.hx`.

### `run_action` tool
Game-defined action registry that agents can trigger (e.g., "start wave", "place brick at 3,2", "reset game"). Screens would register named actions with the DevBridge.

### `get_screen_layout` tool
Return a structured JSON of all elements with positions, sizes, types, and hierarchy — a machine-readable layout description rather than the raw scene graph.

### `diff_preview` tool
Given a `.manim` change, preview what would change visually without committing the edit.

### Contextual documentation tools

**`help("topic")`** - Return relevant subset of docs (e.g., `help("particles")` returns particle properties).

**`examples("element")`** - Return working `.manim` snippets (e.g., `examples("button")` returns button patterns).

### Error fix suggestions
When a font name is wrong, suggest the closest match. When a parameter type is wrong, show valid types. Structured: `{ message, suggestion, valid_alternatives[] }`.

## Notes

- Current MCP tools (24 total) are strong for inspection but weak for creation/modification
- The biggest friction for AI agents is the multi-file coordination: `.manim` + `.hx` + `Main.hx` registration
- `MacroUtils.macroBuildWithParameters` is the most AI-unfriendly API — agents need `describe_wiring` to bridge the gap
- Semantic validation would prevent most iteration cycles (edit -> reload -> error -> fix -> repeat)
