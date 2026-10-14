# Checking the DevBridge in a browser build

How to prove, in a few minutes, that a JS build with `-D MULTIANIM_DEV` answers the DevBridge ops:
through `window.hxDevBridge` (Playwright) and through the WebSocket relay. Both run the same op
list, [`devbridge-checks.js`](devbridge-checks.js): ping, list_screens, scene_graph,
list_interactives, set_parameter (read back with get_parameters), send_events with frame steps,
screenshot (the base64 must decode to a PNG of the reported size), pause + three steps (exactly
three frames), and the JS-only answers (`quit` and `reload` without content: `not_supported`).

The playground is the test client. Build it with the DEV flags into its gitignored
`public/playground.js`, serve it, and rebuild it normally when done.

```bash
cd ../hx-multianim-playground
haxe playground.hxml -D MULTIANIM_DEV -D MULTIANIM_STRICT   # or a copy of the hxml with the two -D lines added
BROWSER=none npx vite --port 3000 --strictPort --open false
# ... checks below ...
haxe playground.hxml                                          # back to the normal build
```

## Through `window.hxDevBridge` (Playwright MCP)

1. `browser_navigate` to `http://localhost:3000/#screen=buttons`. The console shows
   `[DevBridge] Ready: page window.hxDevBridge`.
2. `browser_evaluate` with this function, pasting the whole of `devbridge-checks.js` where it says:

   ```js
   async () => {
     const checks = /* paste test/devbridge-checks.js here */;
     const b = window.hxDevBridge;
     return checks(async (method, params) => JSON.parse(b.call(JSON.stringify({ method, params }))), () => b.info().frame);
   }
   ```

3. Expect `failed: []` and `details.pauseStep.framesCounted === 3`. The screenshot is the render
   target's size (the canvas's device pixels), for example 1503x1766 at a device pixel ratio of 1.5.

Events: `window.hxDevBridge.poll(0)` returns what `/sse` would have streamed (`trace`,
`screen_change`, `parameter_change`, ...), with `lastSeq` as the cursor for the next poll.

Reload from text (JS needs the text; the page can fetch what Vite serves):

```js
async () => {
  const path = 'demos/ui/buttons-demo.manim';
  const text = await (await fetch('/assets/' + path)).text();
  return JSON.parse(window.hxDevBridge.call(JSON.stringify({ method: 'reload', params: { file: path, content: text.replace('Normal Buttons', 'Reloaded') } })));
}
```

## Through the relay

```bash
node test/devbridge-relay.mjs --port 9010          # add --once to exit (status 0/1) after the first game
```

Open `http://localhost:3000/?devbridge=ws://127.0.0.1:9010#screen=buttons`. The relay prints the
game's hello and `checks: 10 passed, 0 failed` (`framesCounted` is `n/a` here: the frame counter
cannot be read synchronously over a socket).

- **Reconnect:** stop the relay (Ctrl+C) and start it again; the page dials back by itself
  (1 s, doubling to 30 s) with the same session, and the checks run again.
- **Page closed:** navigate the tab away; the relay prints `closed: <session>`.
- **Token:** `node test/devbridge-relay.mjs --token abc` refuses a page without `&token=abc`
  (close code 4401; the page's console says so) and accepts one with it.

The MCP server in `--listen` mode is the same relay with the tools in front; its
`scripts/smoke.mjs` drives a browser game and a HashLink game through the MCP tools.
