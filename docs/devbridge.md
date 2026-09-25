# DevBridge MCP Server

Runtime inspection and manipulation server for hx-multianim applications. Designed for AI/Claude Code integration and interactive debugging.

**Compilation:** Only available with `-D MULTIANIM_DEV`. Zero overhead in release builds.

**Files:** `src/bh/multianim/dev/DevBridge.hx` does the work (every op, the game's own ops, the event buffers). `src/bh/multianim/dev/transport/` holds how it is reached: `HttpServerTransport` on HashLink (the HTTP server and `/sse` below), and in a browser page `PageTransport` (`window.hxDevBridge`) and `WebSocketTransport` (dials out to a relay). Every transport answers the same methods with the same bodies. See [Configuration](#configuration), [Token and origin](#token-and-origin) and [Browser builds (JS)](#browser-builds-js).

---

## Connection

**Protocol:** JSON-RPC over HTTP POST.

**Default port:** 9001

**Autostart:** DevBridge starts automatically when `ScreenManager` is constructed with `-D MULTIANIM_DEV`. Accessible via `screenManager.devBridge`. No manual setup needed. Set `DevBridge.autoStart = false` before constructing `ScreenManager` to suppress auto-start (e.g., in test harnesses).

**Port configuration:**
1. **Environment variable** `HX_DEV_PORT` — parsed as integer (1–65535), falls back to 9001
2. **Constructor parameter** `new DevBridge(screenManager, port)` — if `port != 0`, uses that value; if `0`, checks env var
3. **Auto-fallback** — if the configured port is busy, tries up to 10 consecutive ports (e.g. 9001→9010)

**Bind address configuration:**
1. **Environment variable** `HX_DEV_BIND` — the address the HTTP server binds to. Defaults to `0.0.0.0` (all interfaces) so MCP clients on other LAN machines can connect.
2. **Constructor parameter** `new DevBridge(screenManager, port, bindAddress)` — overrides the env var.

> **Security note:** without `HX_DEV_TOKEN`, DevBridge has no authentication and answers with `Access-Control-Allow-Origin: *`. Anything that can reach the port — including any web page open in the developer's browser, which can POST to `localhost:9001` without a preflight — can screenshot the app, inject input, evaluate `.manim`, or quit the process. Set a token (see [Token and origin](#token-and-origin)), and on untrusted networks set `HX_DEV_BIND=127.0.0.1`. (DevBridge only compiles with `-D MULTIANIM_DEV`, so release builds are unaffected.)

**Ready signal:** When `HX_DEV_READY_FILE` env var is set, DevBridge writes JSON to that path after binding:
```json
{"port": 9001, "timestamp": 1711234567.89}
```

**MCP config** (`.mcp.json`):
```json
{
  "mcpServers": {
    "hx-multianim": {
      "command": "npx",
      "args": ["-y", "@bh213/hx-multianim-mcp"],
      "env": { "HX_DEV_PORT": "9001" }
    }
  }
}
```

### Request Format

```json
{"method": "tool_name", "params": {"key": "value"}}
```

### Response Format

```json
{"ok": true, "result": { ... }}
{"ok": false, "error": "message", "code": "error_code"}
```

**Error codes:**

| Code | HTTP | Description |
|------|------|-------------|
| `not_found` | 404 | Screen, element, programmable, resource, or interactive not found |
| `invalid_params` | 400 | Missing or invalid parameters |
| `invalid_state` | 409 | Precondition not met (e.g. game not paused for `step`) |
| `unknown_method` | 404 | Unknown DevBridge method name |
| `not_supported` | 501 | The op does not exist on this target (JS: `quit`, `reload` without `content`) |
| `unauthorized` | 401 | HTTP only: `HX_DEV_TOKEN` is set and the request did not carry it |
| `forbidden` | 403 | HTTP only: `HX_DEV_ORIGIN` is set and the request's `Origin` differs |
| `internal` | 500 | Unexpected server error (includes stack trace in trace output) |

A body that is not JSON answers 400 `{"ok": false, "error": "Invalid JSON"}` (no `code`). The MCP server adds `not_connected`, `ambiguous_target`, `unknown_target`, `connection_failed`, `timeout` and `bad_reply` of its own.

---

## Configuration

Settings keep their environment-variable names on every target. On HashLink they are environment variables (`Sys.getEnv`). A browser page has none, so there they come from a `window.HX_DEV` object the host page writes before the game's script runs, or from the page's query string under the short key (the name lower-cased without `HX_DEV_`) — see [Browser builds (JS)](#browser-builds-js). Read through `bh.multianim.dev.DevBridgeConfig.get(name)`.

| Setting | Query key | Default | Meaning |
|---------|-----------|---------|---------|
| `HX_DEV_PORT` | `port` | 9001 | HTTP port (HashLink); the next nine are tried when busy |
| `HX_DEV_BIND` | `bind` | `0.0.0.0` | HTTP bind address (HashLink) |
| `HX_DEV_READY_FILE` | — | unset | HashLink: write `{port, timestamp}` here once listening |
| `HX_DEV_TOKEN` | `token` | unset | Required on every HTTP request; sent in a relay `hello` |
| `HX_DEV_ORIGIN` | `origin` | unset | HTTP: the one CORS origin allowed |
| `HX_DEV_RELAY` | `devbridge` | unset | Browser: a relay to dial, e.g. `ws://127.0.0.1:9010` |
| `HX_DEV_PAGE` | `page` | on unless a relay is named | Browser: install `window.hxDevBridge` (`1`/`0`) |
| `HX_DEV_APP` | `app` | the `hxd.App` class name | The name a relay and `info()` show |

## Token and origin

With `HX_DEV_TOKEN` set, every HTTP request must carry it, as `X-HX-Dev-Token: <token>`, `Authorization: Bearer <token>`, or `?token=<token>` (the only way for `GET /sse` from an `EventSource`, which cannot set headers). A request without it answers 401 `unauthorized`. CORS preflights (`OPTIONS`) are answered without it, since browsers send no credentials on a preflight.

The `Access-Control-Allow-Origin` header is `HX_DEV_ORIGIN` when set, `*` when no token is set, and left out otherwise (a page on another origin then cannot read answers). With `HX_DEV_ORIGIN` set, a request whose `Origin` header differs answers 403 `forbidden`; requests without an `Origin` (curl, the MCP server) are not affected.

With neither setting, requests and responses are byte-for-byte what they were before the transports were split out.

In a browser page the token travels in the relay `hello` (`?token=` or `window.HX_DEV.HX_DEV_TOKEN`); the MCP server refuses a `hello` without the token it was given (close code 4401). Set the same `HX_DEV_TOKEN` for the game and the MCP server.

## Browser builds (JS)

A browser page cannot listen on a port, so a JS build with `-D MULTIANIM_DEV` has no HTTP server. It is reached in two other ways, and every op answers the same as on HashLink.

**`window.hxDevBridge`** (`PageTransport`), installed when no relay is named, or with `?page=1`:

```js
window.hxDevBridge = {
  protocol: 1,
  info: () => ({app, session, frame, paused, transports, ops, gameOps, title, url}),
  call: (request) => responseJson,  // request: '{"method":"list_screens","params":{}}' or {method, params}; synchronous
  poll: (sinceSeq) => '{"events":[{"seq","event","data"}],"lastSeq":N,"dropped":N,"missed":N}',
};
```

`call` returns the same body as an HTTP reply, as a JSON string. `poll` returns the pushed events (the `/sse` names) newer than `sinceSeq` from a ring of 200: `dropped` counts every event pushed out since start, `missed` those newer than `sinceSeq`. This is what the Playwright MCP drives with `browser_evaluate`; `test/devbridge-page.md` has the check to paste.

**A relay** (`WebSocketTransport`): open the page with `?devbridge=ws://127.0.0.1:9010` (and `&token=...`). The game dials the URL and keeps dialling (1 s, doubling to 30 s) while the relay is down, sending its `hello` again each time. The MCP server in `--listen` mode is the relay (see its README); `test/devbridge-relay.mjs` is a dependency-free one for testing. One JSON object per message:

```jsonc
{"kind":"hello","protocol":1,"app":"Main","title":"…","url":"…","session":"k3f9…","token":"…"}  // game → relay, on open
{"kind":"welcome","protocol":1,"instance":"web-1"}                                            // relay → game
{"kind":"call","id":7,"method":"list_screens","params":{}}                                    // relay → game
{"kind":"result","id":7,"ok":true,"result":{…}}                                               // game → relay
{"kind":"result","id":7,"ok":false,"error":"…","code":"not_found"}
{"kind":"event","seq":42,"event":"trace","data":{…}}                                           // game → relay
```

`id` is the relay's and is echoed. `seq` counts from 1 and keeps counting while the socket is down, so a gap says events were lost. `session` stays the same for the life of the page, so a relay can tell a reconnect from a new game.

**What differs on JS:**

| Op | On JS |
|----|-------|
| `screenshot` | PNG-encoded by the browser (`canvas.toDataURL`); the size is the render target's, so the device pixel ratio does not change the picture |
| `reload` | needs `{file, content}`: a page cannot read the file. Without `content` it answers `not_supported` |
| `quit` | `not_supported`: the page owns the game |
| `pause`, `step` | work, but a hidden or background tab throttles or stops `requestAnimationFrame`: the tab being driven must be visible |
| `send_event`, `send_events` | a key down and up inside one frame is not seen by code that polls keys: put `{step: 1}` between them |
| `get_errors` | also has what the page reports and the Haxe side never sees: uncaught errors, unhandled promise rejections, a resource that failed to load, a lost WebGL context — prefixed `[browser]` |
| `ping` | `port` is 0 |

A result from one target promises nothing about the other: an `Int` does not wrap on `+`/`*` in JS and `Map` order differs.

**Strict mode:** with `-D MULTIANIM_STRICT` on JS, `strictFail` throws the report instead of writing stderr and exiting.

---

## SSE Streaming

**Endpoint:** `GET /sse`

Real-time Server-Sent Events stream for game lifecycle events. Connect with any SSE client (e.g., `EventSource` in browsers, `curl`).

**Event types:**

| Event | Data Fields | Description |
|-------|-------------|-------------|
| `trace` | `message`, `timestamp` | Trace output (same as captured by `get_traces`) |
| `error` | `message`, `stack`, `timestamp` | Runtime errors reported via `reportError()` |
| `screen_change` | `action`, `mode`, `previousMode`, `entering[]`, `leaving[]`, `dialogName`, `timestamp` | Screen switch, dialog open/close |
| `reload` | `status`, `file`, `fileType`, `programmablesRebuilt[]`, `rebuiltCount`, `elapsedMs`, `errors[]`, `timestamp` | Hot reload lifecycle (`started`, `succeeded`, `failed`, `needs_restart`) |
| `parameter_change` | `programmable`, `param`, `value`, `timestamp` | Parameter changed via DevBridge `set_parameter` tool |
| `custom` | `name`, `data`, `timestamp` | Custom game event via `broadcastCustomEvent()` |
| `debugger` | `id`, `data`, `paused`, `file`, `line`, `method`, `timestamp` | `debugger()` breakpoint hit (see `get_debugger_hits`) |
| `game_event` | `id`, `name`, `data`, `timestamp` | Game event emitted via `emitEvent()` (see `get_game_events`) |

**MCP logging levels:** `trace`→info, `error`→error, `screen_change`→info, `reload`→info/error/warning, `parameter_change`→debug, `custom`→info.

**Usage:**
```javascript
const es = new EventSource("http://localhost:9001/sse");
es.addEventListener("trace", (e) => console.log(JSON.parse(e.data).message));
es.addEventListener("error", (e) => console.error(JSON.parse(e.data).message));
es.addEventListener("screen_change", (e) => console.log("Screen:", JSON.parse(e.data)));
es.addEventListener("reload", (e) => console.log("Reload:", JSON.parse(e.data)));
es.addEventListener("custom", (e) => console.log("Custom:", JSON.parse(e.data)));
```

**Custom events from game code:**
```haxe
#if MULTIANIM_DEV
screenManager.devBridge.broadcastCustomEvent("playerDied", {reason: "lava", hp: 0});
#end
```

Multiple concurrent clients supported. Dead clients are automatically cleaned up on write failure. All SSE clients are closed when DevBridge stops.

---

## Tools Reference

### Inspection

#### `performance`
FPS, draw calls, triangle count, object count, scene dimensions.

No parameters.

Returns: `fps`, `drawCalls`, `drawTriangles`, `objectCount`, `sceneWidth`, `sceneHeight`.

#### `list_screens`
All registered screens with active/failed status.

No parameters.

Returns: `screens[]` — each with `name`, `active`, `failed`, optional `error`.

#### `list_builders`
Loaded `.manim` builders with programmable names and parameter definitions.

No parameters.

Returns: `builders[]` — each with `resource`, `programmables[]` (each with `name`, `parameters[]` of `{name, type}`).

#### `scene_graph`
Scene graph tree with object types, positions, visibility, names.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `depth` | int | 10 | Maximum tree depth |

Returns: recursive node tree — `type`, `name`, `x`, `y`, `visible`, optional `alpha`/`scaleX`/`scaleY`/`text`/`tileW`/`tileH`, `children[]`.

#### `screenshot`
Capture current frame as PNG.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `width` | number | engine width | Output width in pixels |
| `height` | number | engine height | Output height in pixels |

Returns: `base64` (PNG data), `width`, `height`.

#### `inspect_element`
Detailed info about a named element (position, size, visibility, text).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `screen` | string | yes | Screen name |
| `element` | string | yes | Element name (`h2d.Object.name`) |

Returns: `name`, `type`, `x`, `y`, `visible`, `alpha`, `scaleX`, `scaleY`, optional `text`/`textColor`.

#### `inspect_programmable`
Deep inspection of a live programmable: parameters, slots, dynamic refs, named elements, interactives, settings.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `programmable` | string | yes | Programmable name |

Returns: `name`, `objectType`, `x`, `y`, `visible`, `currentParameters`, `slots[]`, `dynamicRefs[]`, `namedElements[]`, `interactiveCount`, `settings`.

#### `get_parameters`
Current parameter values and definitions for a live programmable.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `programmable` | string | yes | Programmable name |

Returns: `programmable`, `parameters[]` — each with `name`, `type`, optional `currentValue`.

#### `list_interactives`
All registered interactive hit-test regions with IDs, positions, and metadata.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `screen` | string | no | Screen name (omit to aggregate all active screens) |

Returns: `interactives[]` — each with `id`, `x`, `y`, `disabled`, optional `screen`/`metadata`.

#### `list_slots`
All slots on a programmable with occupied/empty status.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `programmable` | string | yes | Programmable name |

Returns: `slots[]` — each with `name`, optional `index`/`indexX`/`indexY`, `occupied`, optional `hasParameters`.

#### `list_active_programmables`
All live incremental-mode programmables with current values, definitions, named elements, slots, interactive count.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `programmable` | string | | Filter by name (omit for all) |
| `sceneGraph` | bool | false | Include scene graph subtree |
| `depth` | int | 6 | Scene graph depth (when `sceneGraph` is true) |

Returns: `count`, `programmables[]` — each with `name`, `source`, `x`, `y`, `visible`, `currentParameters`, `parameterDefinitions[]`, `namedElements[]`, `slots[]`, `interactiveCount`, optional `sceneGraph`.

#### `find_element_at`
Hit-test a position to find all scene objects at those coordinates (front-to-back).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `x` | float | yes | X in scene space |
| `y` | float | yes | Y in scene space |
| `relative_to` | string | no | Element name for relative coordinates |

Returns: `elements[]` — each with `type`, `depth`, `x`, `y`, optional `name`/`text`/`isInteractive`/`interactiveId`/`disabled`.

#### `check_overlaps`
Detect overlapping elements for layout debugging.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `screen` | string | | Screen name (omit for all active screens) |
| `mode` | string | `"all"` | `"interactives"`, `"visual"`, or `"all"` |
| `min_overlap_area` | int | 1 | Minimum overlap area in px² |
| `include_hidden` | bool | false | Include non-visible/disabled elements |

Returns: `overlaps[]` (each with `type`, `severity`, `elementA`, `elementB`, `overlapArea`, `overlapRect`), `summary` (`total`, `interactive_overlaps`, `visual_overlaps`).

### Resources

#### `list_resources`
All loaded resources: sprite sheets, fonts, `.manim` files, `.anim` files.

No parameters.

#### `list_fonts`
Registered font names.

No parameters.

Returns: `fonts[]`.

#### `list_atlases`
Loaded sprite atlases with tile/sprite names.

No parameters.

Returns: `atlases[]` — each with `name`, `tiles[]`.

### Manipulation

#### `set_parameter`
Set a parameter on a live programmable (incremental mode).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `programmable` | string | yes | Programmable name |
| `param` | string | yes | Parameter name |
| `value` | dynamic | yes | New value |

Returns: `success`.

#### `set_visibility`
Toggle visibility of a named element.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `screen` | string | yes | Screen name |
| `element` | string | yes | Element name |
| `visible` | bool | no | Target visibility (default: true) |

Returns: `success`, `visible`.

#### `reload`
Hot-reload a `.manim` file (or all files).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | no | Resource path (e.g. `"ui/menu.manim"`). Omit to reload all (HashLink only) |
| `content` | string | no | Reload from this text instead of reading the file. Required on JS (with `file`); `not_found` lists the loaded paths when `file` matches none |

Returns: `success`, `file`, `programmablesRebuilt[]`, `rebuiltCount`, `elapsedMs`, `needsFullRestart`, `paramsAdded[]`, `errors[]` (each with `message`, `file`, `line`, `col`, `errorType`, `context`).

#### `eval_manim`
Parse and validate a `.manim` source snippet.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | string | yes | `.manim` source code |

Returns: `success`, `nodes[]`, optional `parseError`, `buildErrors[]`. Each `buildErrors[]` entry has `node` (programmable name or `<filters>`) and `error` (message). When the underlying error is a `BuilderError` (runtime builder failure with source-position context), the entry additionally carries `file`, `line`, `col`, and optional `code` (e.g. `"missing_ref"`, `"not_a_number"`) — use these for clickable diagnostics.

### Input Events

#### `send_event`
Inject a single input event.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `click`, `mouse_down`, `mouse_up`, `move`, `key_down`, `key_up`, `key_press`, `text`, `wheel` |
| `x` | float | no | X coordinate (mouse events) |
| `y` | float | no | Y coordinate (mouse events) |
| `button` | int | no | Mouse button: 0=left, 1=middle, 2=right |
| `delta` | float | no | Wheel delta (default: 1.0) |
| `keyCode` | int | no | Keyboard key code (`hxd.Key` constants) |
| `charCode` | int | no | Character code (text input) |

Returns: `success`, `type`, echoed parameters.

A `key_down` and `key_up` sent in the same frame are not seen by code that polls `hxd.Key` each frame (`key_press` is exactly that). Use `send_events` with a `{step: 1}` between them.

#### `send_events`
Batch: sequence of events with frame steps between them. Enables multi-step interactions (drag-and-drop, slider scrub) in a single call.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `events` | array | yes | Array of event objects or `{step: N}` frame-step objects. Max 200 entries, max 100 frames per step |
| `auto_pause` | bool | no | Auto-pause before executing, resume after (default: false) |

Returns: `success`, `eventsProcessed`, `totalFramesStepped`, `results[]`, `paused`.

#### `click_interactive`
Click an interactive by ID (bypasses coordinate hit-testing). Also aliased as `click_button`.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Interactive identifier |
| `screen` | string | no | Screen name (omit to search all active screens) |

Returns: `success`, `id`, `screen`, optional `error`/`type`.

### Game Control

#### `pause`
Pause or resume the game loop. DevBridge stays responsive while paused.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `paused` | bool | true | True to pause, false to resume |

Returns: `paused`.

#### `step`
Advance by N frames while paused, then re-pause. Game must be paused first.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `frames` | int | 1 | Frames to advance (max 100) |

Returns: `paused`, `framesAdvanced`.

#### `quit`
Cleanly shut down the application (exits with 100ms delay). In a browser page it answers `not_supported`: the page owns the game.

No parameters.

Returns: `success`.

### Diagnostics

#### `ping`
Health check.

No parameters.

Returns: `ok`, `uptime`, `port`.

#### `get_traces`
Recent `trace()` output (ring buffer, last 200 lines).

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clear` | bool | false | Clear buffer after reading |
| `limit` | int | 50 | Max lines to return (max 200) |

Returns: `lines[]`, `total`, `dropped`.

#### `get_errors`
Accumulated runtime errors/exceptions.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clear` | bool | true | Clear buffer after reading |

Returns: `errors[]` (each with `message`, `stack`, `timestamp`), `count`.

#### `get_debugger_hits`
Recent `devBridge.debugger()` hits (ring buffer, last 100 entries).

Pairs with the `debugger` SSE event for push-based notification. Game code calls `devBridge.debugger(data, pause=true)` at a point of interest — file/line/method are auto-captured from `haxe.PosInfos`, `data` is snapshotted, the hit is appended to the ring buffer, an SSE `debugger` event is broadcast, and (if `pause=true`) the game loop is paused. Resume with the `pause` RPC (`{paused:false}`).

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clear` | bool | false | Clear buffer after reading |
| `limit` | int | 50 | Max hits to return (clamped to 1..100) |
| `since_id` | int | -1 | Return only hits with `id > since_id` (cursor for polling) |

Returns: `hits[]` (each with `id`, `data`, `paused`, `file`, `line`, `method`, `timestamp`), `total`, `dropped`, `lastId`.

**Game-side usage:**
```haxe
#if MULTIANIM_DEV
screenManager.devBridge.debugger({hp: player.hp, state: currentState});
// or without pause
screenManager.devBridge.debugger({hp: player.hp}, false);
#end
```

#### `get_tween_state`
All active tweens with targets, duration, progress.

No parameters.

Returns: `activeTweens`, `tweens[]` (each with `duration`, `elapsed`, `progress`, optional `target`).

#### `get_screen_state`
Screen manager state: mode, active screens, transition status, pause state.

No parameters.

Returns: `mode`, `isTransitioning`, `paused`, `activeTweens`, `activeScreens[]` (each with `name`, `elementCount`, `interactiveCount`).

#### `wait_for_idle`
Check if system is idle (no active tweens, no transitions). Non-blocking.

No parameters.

Returns: `idle`, `activeTweens`, `isTransitioning`, `isPaused`.

#### `coordinate_transform`
Transform coordinates between local and global space.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `element` | string | yes | Element name |
| `x` | float | yes | X coordinate |
| `y` | float | yes | Y coordinate |
| `direction` | string | yes | `"to_local"` (scene→element) or `"to_global"` (element→scene) |
| `screen` | string | no | Scope element search to specific screen |

Returns: `element`, `direction`, `inputX`, `inputY`, `resultX`, `resultY`.

### Custom Game Ops

Game-specific queries, commands, and events registered from game code. MCP clients discover registered ops via `list_game_ops`, invoke them via `game_op`, and poll emitted events via `get_game_events` (or subscribe to the `game_event` SSE stream).

**Game-side registration:**
```haxe
#if MULTIANIM_DEV
var bridge = screenManager.devBridge;

// Read-only: returns unit positions
bridge.registerQuery("global_map", "All unit positions", {team: "string?"},
    params -> [for (u in world.units) if (params.team == null || u.team == params.team) {id: u.id, x: u.x, y: u.y}]);

// Mutating: spawn a wave
bridge.registerCommand("spawn_wave", "Spawn N enemies in a lane", {lane: "int", count: "int"},
    params -> {world.spawnWave(params.lane, params.count); return {ok: true};});

// Declare event type (metadata-only; emitEvent does not require registration)
bridge.registerEvent("unit_died", "Fired when a unit dies", {id: "string", killer: "string?"});

// Emit event at runtime
bridge.emitEvent("unit_died", {id: "hero-1", killer: "orc-7"});
#end
```

`params` is a schema-lite metadata hint (JSON-serializable) surfaced to MCP clients via `list_game_ops`. Suffix `?` denotes optional. Handler receives the raw params object and must return a JSON-serializable value; throwing `haxe.Exception` surfaces as MCP `internal` error with the thrown message preserved.

**Registration rules:**
- Query and command names share a namespace — re-registering an existing op name throws.
- Event names have a separate namespace — duplicate event registration throws.
- `emitEvent()` warns (DEV trace) when called with an unregistered name but still buffers + broadcasts.

#### `list_game_ops`
Discover all registered queries, commands, and event types.

No parameters.

Returns: `queries[]` (each `{op, description, params}`), `commands[]` (same shape), `events[]` (each `{name, description, payload}`).

#### `game_op`
Invoke a registered query or command by name. Looks up queries first, then commands.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `op` | string | yes | Registered op name |
| `params` | object | no | Passed through to the handler (default `{}`) |

Returns: `kind` (`"query"` or `"command"`), `op`, `result` (handler's return value).

Errors: `not_found` for unknown op, `invalid_params` when `op` missing, `internal` when handler throws.

#### `get_game_events`
Poll the game-event ring buffer (capacity 200).

Pairs with the `game_event` SSE stream for push-based delivery — use `get_game_events` when SSE is unavailable or for catch-up after a gap.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clear` | bool | false | Clear buffer after reading |
| `limit` | int | 50 | Max events to return (clamped to 1..200) |
| `since_id` | int | -1 | Return only events with `id > since_id` (cursor for polling) |
| `types` | string[] | — | Filter by event name (omit for all) |

Returns: `events[]` (each `{id, name, data, timestamp}`), `total`, `dropped`, `lastId`.

---

## Parameter Types

Type fields in tool responses use these formats:

| Type | Format |
|------|--------|
| Simple | `"int"`, `"uint"`, `"float"`, `"bool"`, `"string"`, `"color"`, `"tile"` |
| Enum | `{type: "enum", values: ["a", "b"]}` |
| Range | `{type: "range", from: 1, to: 5}` |
| Flags | `{type: "flags", bits: ["bit0", "bit1"]}` |

---

## Implementation Notes

- **Trace capture:** Ring buffer (200 lines) auto-installed on `start()`
- **Error capture:** `reportError(message, ?stack)` public method for external error injection
- **Hot-reload registry:** Only `incremental:true` programmables are tracked and appear in `list_active_programmables`
- **CORS:** `*` without a token; the configured origin, or none, with one (see [Token and origin](#token-and-origin))
- **Listens on:** `0.0.0.0:port` (all interfaces) unless `HX_DEV_BIND` says otherwise
- **HTTP server:** `HttpServerTransport`, on Heaps' `hxd.net.Socket` (libuv async); HashLink (and hxnodejs) only
- **HTTP requests:** one request per connection — bytes after a complete request (a pipelined request, a trailing CRLF) are drained, never dispatched. A body needs `Content-Length`: `Transfer-Encoding` answers 411, a non-decimal `Content-Length` 400, a body over the limit 413, oversized headers 431
- **Node (`hxnodejs`):** settings come from `process.env`; a busy port is reported asynchronously, so the next ports are tried from the socket's error callback and `actualPort` settles after `start()`
- **Transports:** `IDevBridgeTransport` (`start`/`stop`/`tick`/`pushEvent`); `DevBridge` implements `IDevBridgeHost` (`handleRequestJson`, `handleCall`, `getToken`, `describeInstance`). `DevBridge.METHODS` lists every method `dispatch` answers
