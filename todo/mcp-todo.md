# MCP DevBridge — Remaining TODO

Merged from: `mcp.md`, `mcp-review.md`, old `mcp-todo.md`, `mcp-v2.md`.
All v1/v2 tools (29 total) are implemented. This file tracks what's left.

## Implemented Tools (29)

Core (12): performance, list_screens, list_builders, scene_graph, inspect_element, screenshot, set_parameter, set_visibility, reload, eval_manim, list_resources, send_event
Control (3): pause, step, quit
Trace (2): get_traces, get_errors
Inspection (7): get_parameters, list_interactives, list_slots, get_tween_state, get_screen_state, find_element_at, inspect_programmable
Added post-v2 (5): ping, list_fonts, list_atlases, coordinate_transform, wait_for_idle

---

## P0 — Critical for Agent Productivity

### `describe_wiring` tool
Given a `.manim` programmable name, return expected Haxe wiring code:
- Which `builderParameter()` placeholders exist and their names
- Which callbacks are needed
- What settings are available
- Generate example Haxe code for `MacroUtils.macroBuildWithParameters`

Biggest knowledge gap for AI agents — mapping between `.manim` `builderParameter("name")` and Haxe lambda parameters is opaque.

---

## P1 — High Value

### `suggest_completion` tool
Given a partial `.manim` snippet and cursor position, return valid completions (element types, parameter names, font names, tile names). LSP-like but via MCP.

### Screen scaffolding (`create_screen` tool)
Generate:
- `res/manim/screenname.manim` skeleton with `#ui programmable() {}`
- `src/screens/ScreenName.hx` extending `UIScreenBase` with `load()` and `onScreenEvent()`
- Registration code for `Main.hx`

Reduces the 3-file ceremony to a single tool call.

### Live element manipulation
- **`modify_element`** — Change position, visibility, text, color of a live element without editing files
- **`add_element`** — Dynamically add a new programmable instance to the scene without file edits

### Scene graph semantic metadata
`walkSceneGraph()` lacks semantic info (programmable identity, component type). Partially addressed: `find_element_at` now annotates MAObject interactives (`isInteractive`, `interactiveId`, `disabled`). Remaining:
- **DevAnnotation objects** (attach invisible metadata children behind `#if MULTIANIM_DEV`)
- **Better `object.name` format** (e.g. `#myButton` or `programmable:myButton` instead of `myButton_PROGRAMMABLE_3`)

### `list_ui_elements` tool
List high-level UI components (buttons, checkboxes, sliders) on a screen, not just raw interactives.

---

## P2 — Nice to Have

### `run_action` tool
Game-defined action registry that agents can trigger (e.g., "start wave", "place brick at 3,2"). Screens register named actions with DevBridge.

### `get_screen_layout` tool
Structured JSON of all elements with positions, sizes, types, hierarchy — machine-readable layout description.

### `diff_preview` tool
Given a `.manim` change, preview what would change visually without committing the edit.

### `switch_screen` tool
Navigate to a registered screen with optional transition.

### `eval_manim_full` tool
~~Parse + build a `.manim` snippet (dry-run).~~ `eval_manim` now does parse + build validation. Remaining: return parameter definitions, element tree, settings — richer than just node names + errors.

### `get_animated_path_state` tool
Query AnimatedPath progress — position, rate, done, cycle count.

### MCP server: process management
MCP server owns app process lifecycle (`start_app` / `stop_app` tools). Eliminates the "agent starts app, then needs to find it" problem.

### Multi-instance support
- ~~Auto-port selection (try next port if configured is busy)~~ — DONE (tries 10 ports)
- ~~Ready signal file on DevBridge.start()~~ — DONE (`HX_DEV_READY_FILE` env var, writes JSON with port/timestamp)
- Instance discovery via ready files (`.dev-bridge-9001.json`, etc.)
- MCP server instance routing (`list_instances` / `select_instance` tools)

### SSE/WebSocket push events
Stream events (screen changes, animation completion, errors) to eliminate polling.

### Contextual documentation tools
- `help("topic")` — return relevant subset of docs
- `examples("element")` — return working `.manim` snippets

### Higher-level drag-drop DSL
`.manim` syntax for drag-drop or helper class that takes grid dimensions and a builder name.

---

## Architecture Notes

- MCP server (`hx-multianim-mcp/`) is separate npm package `@bh213/hx-multianim-mcp`
- Every DevBridge method needs a corresponding TypeScript registration in MCP server
- All Haxe dev code behind `#if MULTIANIM_DEV`
- HTTP POST protocol to `localhost:9001` (configurable via `HX_DEV_PORT`)
