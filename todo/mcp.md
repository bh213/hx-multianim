# MCP Server for hx-multianim — Implementation

## Status: Implemented (v2)

## Architecture

```
Claude Code <--stdio--> MCP Server (Node.js) <--HTTP POST--> DevBridge (Haxe/HL)
                        hx-multianim-mcp/                     src/bh/multianim/dev/DevBridge.hx
```

### Two Components:

1. **MCP Server** (`hx-multianim-mcp/`) — Node.js/TypeScript process using `@modelcontextprotocol/sdk`. Communicates with Claude via stdio, with the running app via HTTP POST.

2. **Dev Bridge** (`src/bh/multianim/dev/DevBridge.hx`) — Haxe HTTP server compiled into the app when `-D MULTIANIM_DEV` is set. Listens on port 9001 using `hxd.net.Socket` (libuv async). Executes commands and returns JSON results.

## MCP Tools (24)

### v1: Core Tools (12)

| Tool | Description |
|------|-------------|
| `performance` | FPS, draw calls, triangles, object count, scene size |
| `list_screens` | All registered screens with active/failed status |
| `list_builders` | Loaded .manim builders + programmable parameter definitions |
| `scene_graph` | Scene tree dump (types, positions, names, depth-limited) |
| `inspect_element` | Detailed info about a named element on a screen |
| `screenshot` | Capture current frame as base64 PNG |
| `set_parameter` | Update parameter on a live programmable (incremental mode) |
| `set_visibility` | Toggle element visibility |
| `reload` | Hot-reload .manim file(s) |
| `eval_manim` | Parse .manim snippet, return node names |
| `list_resources` | List loaded sheets, fonts, .manim/.anim files |
| `send_event` | Inject input events (click, key press, mouse move, wheel, text) |

### v2: Game Control (3)

| Tool | Description |
|------|-------------|
| `pause` | Pause/resume game loop (replaces `hxd.System.loopFunc`; DevBridge stays alive via libuv) |
| `step` | Advance N frames while paused, then re-pause |
| `quit` | Clean shutdown (response sent before exit) |

### v2: Trace & Error Capture (2)

| Tool | Description |
|------|-------------|
| `get_traces` | Ring buffer of recent `trace()` output (last 200 lines) |
| `get_errors` | Accumulated runtime exceptions since last query |

### v2: Deep Inspection (7)

| Tool | Description |
|------|-------------|
| `get_parameters` | Read current parameter values + definitions for a live programmable |
| `list_interactives` | List interactive hit-test regions on a screen (id, position, metadata) |
| `list_slots` | Enumerate slots on a programmable (occupied/empty, indexed, parameterized) |
| `get_tween_state` | Active tweens with target, duration, elapsed, progress |
| `get_screen_state` | Screen manager mode, transition status, pause state, element counts |
| `find_element_at` | Hit-test a screen position — all objects at (x,y), sorted front-to-back |
| `inspect_programmable` | Deep one-call inspection: parameters, slots, dynamic refs, named elements, settings |

## Protocol

HTTP POST to `http://localhost:9001/` with JSON body:

```json
{"method": "performance", "params": {}}
```

Response:
```json
{"ok": true, "result": {...}}
{"ok": false, "error": "message"}
```

## Port Configuration

Priority order:
1. Explicit constructor: `new DevBridge(screenManager, 9002)`
2. Environment variable: `HX_DEV_PORT=9002`
3. Default: `9001`

MCP server reads `HX_DEV_PORT` from its env config in `.mcp.json`.

## Setup

```bash
# Build MCP server
cd hx-multianim-mcp && npm install && npm run build

# Configure in Claude Code (.mcp.json in project root)
# Already configured — uses npx @bh213/hx-multianim-mcp

# Start game with dev mode
# -D MULTIANIM_DEV in hxml, instantiate DevBridge in game code:
# var devBridge = new bh.multianim.dev.DevBridge(screenManager);
# devBridge.start();
```

## Key Decisions

- **HTTP over WebSocket**: Stateless, simpler, no connection management, `curl`-testable, easier future JS target support
- **Port 9001**: Avoids conflicts with common dev ports; configurable via `HX_DEV_PORT`
- **JSON protocol**: Simple, debuggable
- **Dev-only**: All Haxe code guarded by `#if MULTIANIM_DEV` — zero overhead in release
- **Base64 screenshots**: Self-contained in JSON response
- **ReloadableRegistry for set_parameter**: Finds live BuilderResult instances via hot-reload tracking
- **Pause via loopFunc replacement**: Freezes entire game loop; sockets stay alive via libuv (separate from main loop)
- **Trace capture via haxe.Log.trace wrapping**: Ring buffer tees to original trace; zero overhead when DevBridge not started

## Future Ideas

- JS target support (playground integration via React shell interop)
- SSE endpoint for push notifications if ever needed
- Multi-instance discovery via lock files (for multiple game instances)
