# MCP in the browser: driving a JS build of an hx-multianim game

A plan for the agent who will do the work. It expands [IDEAS.md](IDEAS.md) §12.6, with the
DevBridge asks of §10.4 and §11, into phases with exit criteria.

**Goal.** A game compiled to JavaScript and running in a browser page can be inspected and driven
by the same tools that drive a HashLink build today: every DevBridge method, every game op, and
`hx-multianim-mcp` in front of them.

**Not the goal.** Making the web the default target anywhere. HashLink stays what Screenwright
builds, runs, measures and replays ([IDEAS.md](IDEAS.md) §12.1). A published build still has
`MULTIANIM_DEV` off and no DevBridge in it at all.

**Where the work is.** `hx-multianim` (phases 0–3, 5a) and `hx-multianim-mcp` (phase 4, 5b), which
are sibling repos of this one and separate git repositories. Screenwright is written from here and
only in phase 6, which is a sketch, not a commitment. Nothing in this file asks for a change to
the playground; it is used as a test client only.

---

## 1. What is true today

Checked against the sources on 2026-09-24. Line numbers are from that state.

**The one blocker.** The DevBridge is an HTTP server inside the game, and a browser page cannot
listen on a port: Heaps has `ALLOW_BIND = hl || (nodejs && hxnodejs)`
(`hxd/net/Socket.hx:46`). Everything else follows from that.

**Already portable, and the reason this is worth doing.** `dispatch(method, params)`
(`src/bh/multianim/dev/DevBridge.hx:515`) takes a method name and a `Dynamic` and returns a
`Dynamic`, throwing `DevBridgeError` with a code. It knows nothing about sockets. All ~45 ops
hang off it, as do the game's own ops registered through `registerQuery` / `registerCommand` /
`emitEvent`, which is what Screenwright's generated `Main` uses (`open_screen`, `state_get`,
`slice_start`, and the rest).

Portable too, verified in the pinned Heaps:

| Piece | Where | Note |
|---|---|---|
| pause / step | `hxd.System.loopFunc` | exists in `hxd/System.js.hx:40,59`, same as the HL one |
| screenshot | `Texture.capturePixels` → `GlDriver.hx:1738` | the GL driver is the WebGL one; `format.png` is pure Haxe |
| trace capture | `haxe.Log.trace` override, `DevBridge.hx:160` | unchanged |
| input injection, scene graph, parameters, interactives | | no platform API |

**Not portable, exhaustively.** This is the whole list to deal with:

| What | Where |
|---|---|
| `Sys.getEnv` for port, bind address, ready file | `DevBridge.hx:81, 95, 131` |
| `sys.io.File.saveContent` for the ready file | `DevBridge.hx:138` |
| `hxd.net.Socket`, the HTTP parsing, the response writing | `DevBridge.hx:33, 68, 107–128, 387–441, 477–510`, and `HttpConnection` at `2210–2342` |
| SSE as sockets held open | `DevBridge.hx:191–230` |
| `tick()` pumping pending connections | `DevBridge.hx:425` |
| `MULTIANIM_STRICT` ending in `Sys.stderr` and `Sys.exit(1)` | `ScreenManager.hx:1718–1720` |
| `hotReload()` reading a file to reload it | `ScreenManager.hx:1290+`, `#if hl` |

**The MCP server.** One HTTP POST per call, no timeout (`src/bridge.ts:57`); an SSE client that
splits on newlines and keeps nothing between chunks (`src/sse.ts`); `connect` must be called first
and marks itself connected before the ping (`src/tools.ts:56`). Its faults are listed in
[IDEAS.md](IDEAS.md) §10.2; the ones this plan touches are fixed on the way through.

---

## 2. The shape: one core, three transports

```
                        ┌──────────────────────────────┐
                        │  DevBridge (unchanged API)   │
   registerQuery ──────▶│  dispatch(method, params)    │◀────── every op, every game op
   registerCommand      │  pushEvent(name, data)       │
   emitEvent            └──────────────┬───────────────┘
                                       │ IDevBridgeTransport
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
     HttpServerTransport         PageTransport          WebSocketTransport
     #if (hl || nodejs)          #if js                 #if js
     today's server, moved       window.hxDevBridge     dials out to a relay
     HL behaviour unchanged      Playwright drives it   the MCP server holds it
```

`DevBridge` keeps its public API exactly: `new(screenManager, ?port, ?bind)`, `start()`, `stop()`,
`tick()`, `registerQuery`, `registerCommand`, `emitEvent`, `debugger`, `autoStart`. The
ScreenManager keeps creating it under `#if MULTIANIM_DEV` (`ScreenManager.hx:120`) and calling
`tick()` every update (`ScreenManager.hx:289–290`).

### The transport interface

```haxe
interface IDevBridgeTransport {
	function start(handle:String -> String):Void;  // handle: request JSON → response JSON
	function stop():Void;
	function tick():Void;                          // pump; a no-op where nothing needs pumping
	function pushEvent(name:String, data:Dynamic):Void;
	var describe(get, never):String;               // for the startup trace
}
```

`handle` is the existing `handleRequest` body without the socket: parse, `dispatch`, and return
`{ok, result}` or `{ok, false, error, code}` as a string. Every transport shares it, so an error
reads the same however it arrived.

### Configuration without `Sys`

```haxe
class DevBridgeConfig {
	public static function get(name:String):Null<String>;
	// #if sys        → Sys.getEnv(name)
	// #elseif js     → window.HX_DEV?.[name] ?? new URLSearchParams(location.search).get(lower(name))
}
```

So `HX_DEV_PORT`, `HX_DEV_BIND`, `HX_DEV_READY_FILE`, `HX_DEV_TOKEN` keep their names on system
targets, and in a page the same settings arrive as `?devbridge=ws://127.0.0.1:9010&token=abc` or
as a `window.HX_DEV` object written by the host page before the game's script runs.

### The wire, for the WebSocket transport

One JSON object per message, mirroring the HTTP body shape so the MCP server parses one thing:

```jsonc
// game → relay, first frame after the socket opens
{"kind":"hello","protocol":1,"app":"playground","title":"…","url":"http://…","session":"k3f9…","token":"abc"}
// relay → game
{"kind":"call","id":7,"method":"list_screens","params":{}}
// game → relay
{"kind":"result","id":7,"ok":true,"result":{…}}
{"kind":"result","id":7,"ok":false,"error":"no screen named play","code":"not_found"}
// game → relay, unsolicited
{"kind":"event","seq":42,"event":"trace","data":{"message":"…","timestamp":1.23}}
```

`id` is the relay's; the game echoes it. `seq` is the game's, monotonic from 1, so a client that
missed frames can tell. Events are the same names the SSE stream uses today (`trace`, `error`,
`screen_change`, `reload`, `parameter`, `debugger`, `game_event`), so nothing downstream learns a
new vocabulary.

### The page API, for the PageTransport

```js
window.hxDevBridge = {
  protocol: 1,
  info: () => ({ app, title, session, ops: [...] }),
  call: (requestJson) => responseJson,   // synchronous: dispatch already is
  poll: (sinceSeq) => '{"events":[…],"dropped":0}',
};
```

Synchronous because `dispatch` is. This one is nearly free and pays for itself immediately: with
it, the Playwright MCP already in use for films can drive a web build through `browser_evaluate`
before any relay exists.

Mark it `@:keep` (or `@:expose`), or `-dce full` removes it.

---

## 3. Phases

Each phase is one commit in one repo, and each ends with the HashLink path proved unchanged.

### Phase 0 — `MULTIANIM_DEV` compiles for JS (hx-multianim)

1. `#if sys` around the `Sys.stderr` / `Sys.exit(1)` tail of `strictFail`
   (`ScreenManager.hx:1685–1720`); on other targets keep the message and `throw` it. Asked for
   already in [IDEAS.md](IDEAS.md) §11.
2. Introduce `DevBridgeConfig` (above) and replace the three `Sys.getEnv` calls.
3. Put the ready file behind `#if sys`.

**Exit.** `haxe playground.hxml -D MULTIANIM_DEV -D MULTIANIM_STRICT` compiles and the playground
still runs in Chrome. On HashLink nothing moved: `test.bat run` is green, and a Screenwright
project still builds, runs and answers on port 9001.

### Phase 1 — the split, with HashLink unchanged (hx-multianim)

Move the socket half of `DevBridge.hx` into `src/bh/multianim/dev/transport/HttpServerTransport.hx`:
`start`/`stop`/`tick`, `onClientConnected`, `handleRequest`'s socket parts, `sendResponse`,
`sendJsonResponse`, `handleSseConnect`, `broadcastSseEvent`, `closeSseClients`, `HttpConnection`.
`DevBridge` keeps the dispatch, the buffers (traces, errors, debugger hits, game events), the
registries and `pushEvent`, and calls the transport.

Nothing about the protocol changes. `broadcastSseEvent(name, data)` becomes
`transport.pushEvent(name, data)`; the loop control (`savedLoopFunc`, in `handlePause`,
`handleStep` and `send_events`' step handling at `DevBridge.hx:1805–1818`) stays in the core,
because it is not about transport.

**Exit.** A `curl` POST and an SSE subscription behave exactly as before, the port-busy retry and
the ready file still work, and Screenwright's own suite (`packages/server/test/game.test.ts`,
`gameState.test.ts`, `review.test.ts`) passes against the rebuilt engine. Diff review should show
moved code, not rewritten code.

### Phase 2 — PageTransport (hx-multianim)

`src/bh/multianim/dev/transport/PageTransport.hx`, `#if js`: install `window.hxDevBridge`, keep a
ring buffer of events (200, with a `dropped` count, as the trace buffer does), answer `poll`.
Chosen when the config names no relay.

**Exit.** The playground, built with `-D MULTIANIM_DEV`, driven from the Playwright MCP through
`browser_evaluate`: `ping`, `list_screens`, `scene_graph`, `list_interactives`, `set_parameter`,
`send_events`, and a `screenshot` whose base64 decodes to a PNG of the right size. A `pause` then
three `step`s advances exactly three frames. Write what was run into the repo as
`test/devbridge-page.md` or a small script, so the next person repeats it in a minute.

### Phase 3 — WebSocketTransport (hx-multianim)

`src/bh/multianim/dev/transport/WebSocketTransport.hx`, `#if js`, on `js.html.WebSocket`: dial the
URL from the config, send `hello`, answer `call` frames through the shared handler, push events,
reconnect with backoff (1 s, doubling to 30 s) and re-send `hello` — a page that outlives the
relay must come back by itself. Both JS transports may be on at once.

Ship a 40-line Node script in `test/` that accepts the socket and runs the phase 2 op list, so the
engine repo can prove this without the MCP server existing yet.

**Exit.** The playground page, opened with `?devbridge=ws://127.0.0.1:9010`, connects; the script
drives it; killing and restarting the script reconnects within a few seconds; closing the page
leaves nothing behind.

### Phase 4 — the MCP server reaches a browser game (hx-multianim-mcp)

1. **A transport behind `DevBridge`** in `src/bridge.ts`: `HttpTransport` (today's, the default,
   unchanged) and `WsRelayTransport`, which **listens** — the MCP process is the server and the
   game dials in. Port from `HX_DEV_WS_PORT` (default 9010), incremented when busy as the engine
   does; `--listen` on the command line for the same thing.
2. **Instances.** A `hello` makes an instance: session, title, URL, when it connected.
   `list_instances` lists them (including the HTTP one, by ping), `connect` takes `{port}` or
   `{instance}`, and every tool takes an optional `target`. With exactly one instance, tools work
   without `connect` at all — [IDEAS.md](IDEAS.md) §10.3 item 1.
3. **One event buffer with a cursor**, fed by SSE (HTTP) or `event` frames (WS), and an
   `events(since_id, kinds)` tool. MCP log notifications do not reliably reach the model, so the
   pollable tool is the one that counts — §10.3 item 3.
4. **Fixes on the way through**, all in the code being touched (§10.2): keep the remainder between
   SSE chunks and join repeated `data:` lines; a 10 s default timeout per call, as Screenwright's
   own client has; `connect` marks itself connected only after the ping answers; the version
   string in `index.ts:25` matches `package.json`.
5. **Tests.** The repo has none. Add `node:test` against a fake DevBridge (an HTTP server and a WS
   client, both a few lines) covering: a call each way, a timeout, a split SSE event, two instances
   and `target`, and `connect` failing cleanly.

**Exit.** With `.mcp.json` pointing at the built server in relay mode, Claude drives the playground
in a browser tab: lists its screens, clicks an interactive, sets a parameter, takes a screenshot,
reads the traces. The HashLink path is proved unchanged in the same session against a running
Screenwright game on 9001.

### Phase 5 — a token, and an origin (both repos)

The DevBridge answers any page in the browser with `Access-Control-Allow-Origin: *` and no
authentication, and binds every interface unless told otherwise. That is already on hx-multianim's
1.1 list ([IDEAS.md](IDEAS.md) §10.4) and it matters more once games run in browsers, because any
page the developer has open can reach `localhost:9001` and send `quit` or `eval_manim`.

- **Engine:** `HX_DEV_TOKEN` checked on every HTTP request and on the WS `hello`; the CORS header
  becomes the configured origin, `*` only when no token is set.
- **MCP:** pass the token through; refuse a socket without it.

### Phase 6 — Screenwright (sketch, not part of this task)

Serving the built page, relaying calls over the WebSocket the studio already has, and giving the
MCP server to jobs with a `look` set are Screenwright's work and belong in its own plan
([IDEAS.md](IDEAS.md) §10.3, §12.6, and step A of §13). Do not change this repo from the engine
repos.

---

## 4. Op by op: what differs on JS

| Op | On JS |
|---|---|
| `ping`, `performance`, `list_*`, `scene_graph`, `inspect_*`, `find_element_at`, `coordinate_transform`, `check_overlaps`, `get_*` | unchanged |
| `set_parameter`, `get_parameters`, `set_visibility`, `eval_manim`, game ops | unchanged |
| `screenshot` | works through `capturePixels`; the size is the render target's, not CSS pixels, so device pixel ratio does not change the picture. The ARGB clear-colour bug ([PLAN.md](PLAN.md) §13, finding 6) behaves the same way — do not fix it here |
| `send_event`, `send_events`, `click_button` | unchanged, but a key held for less than a frame is not seen. Document the `{step:1}` between down and up; it is how the first browser try at brick-break failed |
| `pause`, `step` | `loopFunc` exists on JS. A hidden or background tab throttles or stops `requestAnimationFrame`, so the page must be visible (or headless and foregrounded) |
| `reload` | `#if hl` today. On JS take `{path, content}` from the host and reload from the text; without content, answer `not_supported` |
| `quit` | the host owns the page: answer `not_supported` on JS, or stop the loop and close the socket. Never `hxd.System.exit()` |
| errors | also catch `window.onerror` and `unhandledrejection` into the error buffer, tagged as coming from the browser. These are the failures the Haxe side never sees: a lost WebGL context, a resource 404 |

---

## 5. Risks

- **Background tabs stand still.** Measures and long replays stay on HashLink. A tab being driven
  must be the visible one.
- **One WebGL context per page.** Two games side by side are two tabs, not two canvases. Heaps'
  statics push the same way (`FontManager.registerFont` throws on a second registration).
- **The targets are not each other.** An `Int` does not wrap on `+` and `*` in JS, and `Map` order
  differs, so a replay or a measure made on one target promises nothing on the other
  ([IDEAS.md](IDEAS.md) §12.1). Say so wherever a result crosses.
- **Dead code elimination** removes the page API unless it is kept.
- **Resources.** A real game in a browser needs the pack loader of [IDEAS.md](IDEAS.md) §12.4;
  the playground's synchronous-XHR `FileLoader` (`ScreenManager.hx:32`) is not a pattern to spread.
  Out of scope here, but it is why the playground is the test client and a game is not.

## 6. What not to do

- **Do not change any op's name, parameters, or the shape of what it returns.** Screenwright's
  client (`packages/server/src/game/devbridge.ts`) and the MCP server both depend on them, and the
  HashLink path must stay byte-for-byte compatible through every phase.
- **Do not make JS a default** in the engine, the MCP server or any hxml.
- **Do not add a runtime dependency to the engine.** The transports are plain Haxe and browser
  externs.
- **Do not write to Screenwright from the engine repos**, and do not change the playground beyond
  what a test needs.

## 7. Acceptance, all phases together

1. HashLink: a Screenwright game builds, runs, captures and replays exactly as before, and
   `hx-multianim`'s own tests pass.
2. Browser: the playground built with `-D MULTIANIM_DEV` is driven both ways — through
   `window.hxDevBridge` from Playwright, and through the MCP server over a relay socket.
3. Claude, given the MCP server, works on a game in a browser tab without knowing it is not
   HashLink: same tools, same names, same answers.
4. A token is required when one is set, and the CORS header is no longer `*` in that case.
5. The MCP server has tests, a fixed SSE reader, timeouts on calls, and a version that matches.
