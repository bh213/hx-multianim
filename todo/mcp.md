# MCP Server for hx-multianim — Implementation

## Status: Implemented (v1)

## Architecture

```
Claude Code <--stdio--> MCP Server (Node.js) <--HTTP POST--> DevBridge (Haxe/HL)
                        mcp-server/                           src/bh/multianim/dev/DevBridge.hx
```

### Two Components:

1. **MCP Server** (`mcp-server/`) — Node.js/TypeScript process using `@modelcontextprotocol/sdk`. Communicates with Claude via stdio, with the running app via HTTP POST.

2. **Dev Bridge** (`src/bh/multianim/dev/DevBridge.hx`) — Haxe HTTP server compiled into the app when `-D MULTIANIM_DEV` is set. Listens on port 9001 using `hxd.net.Socket` (libuv async). Executes commands and returns JSON results.

## MCP Tools (12)

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

## Setup

```bash
# Build MCP server
cd mcp-server && npm install && npm run build

# Configure in Claude Code settings
# mcpServers.hx-multianim.command = "node"
# mcpServers.hx-multianim.args = ["<path>/mcp-server/dist/index.js"]

# Start game with dev mode
# -D MULTIANIM_DEV in hxml, instantiate DevBridge in game code:
# var devBridge = new bh.multianim.dev.DevBridge(screenManager);
# devBridge.start();
```

## Key Decisions

- **HTTP over WebSocket**: Stateless, simpler, no connection management, `curl`-testable, easier future JS target support
- **Port 9001**: Avoids conflicts with common dev ports
- **JSON protocol**: Simple, debuggable
- **Dev-only**: All Haxe code guarded by `#if MULTIANIM_DEV` — zero overhead in release
- **Base64 screenshots**: Self-contained in JSON response
- **ReloadableRegistry for set_parameter**: Finds live BuilderResult instances via hot-reload tracking

## Future Ideas

- `reload_status` — Get last reload report
- JS target support (playground integration via React shell interop)
- SSE endpoint for push notifications if ever needed
