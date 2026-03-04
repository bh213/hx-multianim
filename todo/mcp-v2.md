# MCP DevBridge v2 — New Tools Plan

## Overview

Extend the DevBridge (12 tools currently) with debugging, inspection, and control tools.
Changes touch two repos: **hx-multianim** (DevBridge.hx, ScreenManager.hx) and **hx-multianim-mcp** (tools.ts, bridge.ts).

All new Haxe code stays behind `#if MULTIANIM_DEV`.

---

## Phase 1: Game Control

### 1.1 `pause` / `resume`

Freeze the entire game loop while keeping DevBridge responsive.

**Approach:** Replace `hxd.System.setLoop(fn)` — save the real loop function, swap in a no-op that only renders the last frame once (for screenshots).

- Socket I/O runs on libuv, independent of the main loop — DevBridge stays alive
- All game logic, tweens, AnimationSM, particles stop completely
- Scene graph remains in memory — all inspection tools work on frozen state
- Mutations (`set_parameter`, `set_visibility`) apply and become visible on resume (or via `step`)

**Params:** `pause(paused:bool)` — toggle. Returns `{paused: bool}`.

### 1.2 `step`

Run exactly one frame, then re-pause. For frame-by-frame debugging.

**Approach:** Temporarily restore the real loop function, run one frame via `haxe.Timer.delay`, then re-pause.

**Params:** `step(frames:int=1)` — advance N frames. Returns `{paused: true, framesAdvanced: int}`.

### 1.3 `quit`

Clean game shutdown.

**Approach:** Send HTTP response first, then `haxe.Timer.delay(() -> hxd.System.exit(), 100)`.

**Params:** none. Returns `{success: true}` (then process exits).

---

## Phase 2: Trace & Error Capture

### 2.1 `get_traces`

Return recent `trace()` output.

**Approach:** On DevBridge.start(), wrap `haxe.Log.trace` to tee output into a ring buffer (last 200 lines, configurable). Original trace function still called (console output preserved).

**Params:** `get_traces(clear:bool=false, limit:int=50)`. Returns `{lines: string[], total: int, dropped: int}`.

### 2.2 `get_errors`

Return accumulated runtime exceptions since last query.

**Approach:** Install error handler that captures uncaught exceptions into a buffer. Also captures hot-reload errors that happen during rendering (post-reload runtime failures).

**Params:** `get_errors(clear:bool=true)`. Returns `{errors: [{message, stack, timestamp}], count: int}`.

---

## Phase 3: Deep Inspection

### 3.1 `get_parameters`

Read current parameter values of a live programmable.

**Approach:** Use `ReloadableRegistry.getAllHandles()` to find the BuilderResult, then `incrementalContext.snapshotParams()` to read state. Also return parameter definitions (type, default, enum values).

**Params:** `get_parameters(programmable:string)`. Returns `{parameters: [{name, type, currentValue, default}]}`.

### 3.2 `list_interactives`

List all registered interactives on a screen.

**Approach:** Read `screen.interactiveMap` — return id, position (from the h2d.Object), disabled/hovered state, event flags, metadata key-values, bind info.

**Params:** `list_interactives(screen:string)`. Returns `{interactives: [{id, x, y, w, h, disabled, hovered, events, metadata, bind}]}`.

### 3.3 `list_slots`

Enumerate slots on a programmable's BuilderResult.

**Approach:** Read `result.slots` array. Return key (name + index), occupied/empty, has parameterized state.

**Params:** `list_slots(programmable:string)`. Returns `{slots: [{name, index, occupied, hasParameters}]}`.

### 3.4 `get_tween_state`

Query active tweens.

**Approach:** Expose `TweenManager` internals — iterate active tween handles, return target object name, duration, elapsed, property list, completion %.

**Params:** `get_tween_state()`. Returns `{activeTweens: int, tweens: [{target, duration, elapsed, progress, properties}]}`.

### 3.5 `get_screen_state`

Detailed state of the screen manager and active screen(s).

**Approach:** Read ScreenManager mode, isTransitioning, active screen names, controller stack depth, element/interactive counts, tooltip/panel open state.

**Params:** `get_screen_state()`. Returns `{mode, isTransitioning, paused, activeScreens: [{name, elements, interactives, ...}]}`.

### 3.6 `find_element_at`

Hit-test a screen position — "what's at pixel x,y?"

**Approach:** Walk scene graph, check `getBounds()` + visibility for all objects under the point. Return matches sorted by z-order (front to back). Include object type, name, position.

**Params:** `find_element_at(x:float, y:float, screen?:string)`. Returns `{elements: [{type, name, x, y, w, h, depth}]}`.

### 3.7 `inspect_programmable`

Deep one-call inspection of a live BuilderResult — parameters, slots, dynamic refs, named elements, coordinate systems, settings.

**Approach:** Combine data from multiple sources into one response. Richer than `inspect_element` which only does basic h2d.Object properties.

**Params:** `inspect_programmable(programmable:string)`. Returns `{name, parameters, slots, dynamicRefs, namedElements, settings, ...}`.

---

## Phase 4: Advanced (Lower Priority)

### 4.1 `switch_screen`

Navigate to a registered screen.

**Params:** `switch_screen(screen:string, transition?:string)`.

### 4.2 `eval_manim_full`

Parse + build a .manim snippet (dry-run). Returns parameter definitions, element tree, settings — not just node names.

### 4.3 `get_animated_path_state`

Query AnimatedPath progress — position, rate, done, cycle count.

---

## Implementation Order

1. **Phase 1** (pause/resume/step/quit) — highest value, enables all other inspection
2. **Phase 2** (traces/errors) — essential for debugging workflow
3. **Phase 3.1-3.2** (get_parameters, list_interactives) — most-used inspection tools
4. **Phase 3.3-3.7** (remaining inspection) — fill out the toolkit
5. **Phase 4** (advanced) — as needed

## Files to Modify

| File | Changes |
|------|---------|
| `src/bh/multianim/dev/DevBridge.hx` | All new handler methods + trace/error capture |
| `src/bh/ui/screens/ScreenManager.hx` | Expose pause state, possibly add accessors for screen inspection |
| `src/bh/base/TweenManager.hx` | Add inspection method for active tweens (if not already accessible) |
| `hx-multianim-mcp/src/tools.ts` | Register all new MCP tools with Zod schemas |

## MCP Server Changes

Each new DevBridge method needs a corresponding tool registration in `hx-multianim-mcp/src/tools.ts`:
- Zod schema for parameters
- Tool description for Claude
- HTTP POST forwarding (same pattern as existing tools)

Publish new npm version of `@bh213/hx-multianim-mcp` after adding tools.
