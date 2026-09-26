# Agentic Workflow Review — MCP, `.manim`, `.anim` — 2026-09-24

Review of how well an AI agent can **understand, edit, validate, see and verify** hx-multianim
content, focusing on the MCP server (`../hx-multianim-mcp` + `src/bh/multianim/dev/DevBridge.hx`),
the `.manim` DSL and the `.anim` format. Four review passes (MCP/DevBridge, `.manim`, `.anim`,
surrounding tooling) over this repo and the siblings (proto-game, inc_game, game-template,
hx-easy-game, playground, assets, hx-multianim-utils, screenwright). Findings cite `file:line`;
the ones that drive a recommendation were re-checked against source. Items marked *(likely)* come
from reading the code and have not been reproduced at runtime.

**Item IDs:** `MCP-*` MCP server + DevBridge · `MAN-*` `.manim` · `ANM-*` `.anim` · `TOOL-*` offline
tooling · `KB-*` docs/skills/onboarding · `BUG-*` defects found along the way. The prefixes don't
collide with `todo/release-1.0-audit.md`; where an item overlaps an audit ID it says so.
Effort: **S** ≤ 1 day · **M** a few days · **L** a week or more.

---

## Summary

An agent working on a game here runs one loop: **understand → edit → validate → see → verify**.
The edit step is fine (plain text). The other four steps are weak:

| Step | What an agent has today | Main gap |
|---|---|---|
| Understand | Free-text `//` comments (on ~345 of ~840 game/playground programmables), `list_builders` (names + param types) | No structured intent anywhere. `.anim` can't say frame counts, durations, size, or what the sprite is. Resource↔code links are ~270 string literals |
| Validate (offline) | `manim-validate` (parse-only, 43 lines), LSP (first error only, 1-char ranges) | Nothing real for `.anim`: the LSP skims bodies, reports false positives on 30 of 62 files and misses real errors. No build-level checks without a running game |
| See | Full-window `screenshot` of the running game | Can't render one programmable offline or in N states. Can't watch an animation. screenwright already solved this (see `TOOL-2`) |
| Verify | 38 MCP tools, SSE events pushed as MCP log messages | Pushed events don't reach the model. No blocking wait. Same-name instances can't be told apart. No way to go from a pixel back to its `.manim` line |
| Iterate (`.anim`) | — | No `.anim` hot reload, no `.anim` DevBridge tools, no public parse result |

**Highest-leverage recommendations, in order:**

1. **Fix the cheap defects first (`BUG-4..14`).** Several silently break what an agent relies on: the reload registry drops screens, `eval_manim` leaks handles, click coordinates don't match reported bounds, `reload` reports success when nothing happened, and the docs teach invalid `.anim` syntax. (`BUG-1` and `BUG-2` are latent SSE bugs. Today's SSE output never reaches the model, so fix them together with `MCP-3`.)
2. **Offline render + check (`TOOL-2`, `MCP-6`).** Build a programmable with given params into a PNG, plus bounds and interactives, without clicking through the game. screenwright's `packages/runtime` already implements this. Upstream it.
3. **A reliable event channel (`MCP-1`, `MCP-2`).** One cursor-based `get_events` inbox, plus a small `_notices` block on every tool result, so reload failures and runtime errors can't go unseen.
4. **Self-describing `.manim` (`MAN-1..5`).** Add `///` doc comments and inline parameter docs, plus a few structured annotations (`@size`, `@usedBy`, `@example`). Surface them through one outline extractor used by the LSP, CLI and MCP.
5. **Self-describing `.anim` (`ANM-1..6`).** Add header fields (description, tags, source, facing), per-animation intent, a public introspection API, and an `anim describe` that joins the `.atlas2` to report frames, durations and event timelines.
6. **Pixel ↔ source mapping and instance addressing (`MCP-10`, `MCP-11`).** `find_element_at` should answer "`ui/combat.manim:118`, `#hpFill` in `hpBar@3`", not an enum dump.
7. **Shrink and fix the knowledge layer (`KB-1..4`).** About 29k tokens of rules load every session, and some snippets in them don't parse. Add a snippet CI gate, a condensed grammar, and turn the flat `.claude/skills/*.md` files into skills Claude Code can actually discover.

---

## Part 0 — Defects and drift found during the review (fix first)

These are cheap and each one silently breaks an agent workflow.

> **`BUG-1` and `BUG-2` are latent today.** The SSE pipe works (verified live against a running game:
> it connects after `connect`, and events arrive). But its only consumer is `sendLoggingMessage`,
> which Claude Code doesn't put into the model's context (`MCP-3`). Every polling tool
> (`get_traces`, `get_errors`, `get_debugger_hits`, `get_game_events`) reads DevBridge's HTTP
> buffers and never touches SSE. Fix both as part of `MCP-3`, when SSE becomes the path into the
> model.

- [ ] `BUG-1` **MCP drops pushed game events.** `index.ts` has no `case "game_event"`, so events from
  `DevBridge.emitEvent` (DevBridge.hx:354) fall through to `default` and are logged as
  `"Unknown SSE event: game_event"` at debug level. Polling with `get_game_events` is unaffected.
  **S** (with `MCP-3`)
- [ ] `BUG-2` **The SSE client truncates events that span read chunks.** `sse.ts:66-80` splits each
  chunk on `\n` without carrying a partial last line over to the next chunk (despite the comment
  saying it does).
  - **Reproduced** with the compiled client against a fake server: a 5 KB event split at byte 2000
    arrived as a 1,981-char `data` that failed `JSON.parse`. `index.ts`'s `catch {}` would drop it
    silently.
  - **Rarely triggers today:** DevBridge events are typically 100–500 bytes, and on localhost they
    arrive in one chunk. Only big payloads can split (large `debugger()` snapshots, long
    reload-error lists), and those are exactly what a channel should carry.
  - CRLF line endings happen to work, because a trailing `\r` is JSON whitespace.
  - **S** (with `MCP-3`)
- [ ] `BUG-3` **Stale MCP metadata.** `index.ts:24` reports server version `1.10.0` (package is
  `1.15.0`), and `dist/channel.js` is an uncommitted build artifact with no `src/` counterpart (see
  `MCP-3`). **S**
- [ ] `BUG-4` **The screenshot background isn't grey.** `engine.clear(0x1f1f1fff, 1)`
  (DevBridge.hx:651) is ARGB, so it clears to blue at 12 % alpha. Screenshots differ from the window
  wherever the screen doesn't paint. Use `engine.backgroundColor` or `0xFF1F1F1F` (screenwright
  PLAN #6). **S**
- [ ] `BUG-5` *(likely)* **Coordinate spaces don't match.** `send_event` passes x/y straight to
  `hxd.Window.event` (DevBridge.hx:911-915). That is window pixels, because `h2d.Scene.handleEvent`
  calls `screenToViewport`. Meanwhile `find_element_at`, `list_interactives`, `check_overlaps` and
  `coordinate_transform` report s2d scene coordinates, and the MCP tool descriptions say "scene
  coordinates". The two agree only at viewport scale 1. With AutoZoom, clicking at a coordinate
  from `list_interactives` misses. See `MCP-12`. **S**
- [ ] `BUG-6` *(likely)* **`eval_manim` leaks reload handles.** Each eval build registers a
  `ReloadableHandle` (MultiAnimBuilder.hx:8374, `reloadable=true` by default). The object is never
  attached, so `result.object.remove()` (DevBridge.hx:855) never fires the sentinel's `onRemove`
  (HotReload.hx:141-144). `<eval>` entries pile up in `list_active_programmables` and can shadow
  `set_parameter`, because `findBuilderResult` (DevBridge.hx:2062) returns the first name match.
  Build eval results with `reloadable=false`, or unregister explicitly. **S**
- [ ] `BUG-7` **The reload registry forgets a screen once it leaves the scene.** The sentinel's
  `onRemove` unregisters the handle, and `ScreenManager` detaches screen roots on switch
  (ScreenManager.hx:569, 859). Nothing registers them again. After navigating away and back,
  `set_parameter`, `get_parameters`, `inspect_programmable` and in-place hot reload can't find that
  screen's programmables (screenwright PLAN #10; not in the 1.0 audit). **M**
- [ ] `BUG-8` **`reload` reports success when nothing happened.** It returns `success:true,
  rebuiltCount:0` for an unchanged file, an untracked file and an `.anim` file alike
  (DevBridge.hx:771-783). Because the hash is updated before screens rebuild (ScreenManager.hx:1391),
  a screen that failed during auto-reload is reported as success on a later explicit `reload`. Only
  the last file's report is returned (:1302). **S**
- [ ] `BUG-9` **DevBridge pollutes its own trace buffer.** Every request traces `[DevBridge] << method`
  and `>> method OK` (DevBridge.hx:455-458) into the same 200-line ring that `get_traces` returns. An
  agent that polls evicts the game's traces two lines per call. Confirmed live: one `ping` produced
  three SSE events, all DevBridge's own logging and none from the game. **S**
- [ ] `BUG-10` **Two DevBridges per game.** `inc_game/src/game/Main.hx:180` and
  `game-template/src/game/Main.hx:111` start a second instance (binds 9002) next to the one
  `ScreenManager` auto-starts (ScreenManager.hx:126-127). `DevBridge.start` should warn if one is
  already running. **S**
- [ ] `BUG-11` **Docs and LSP hover teach invalid `.anim` syntax.**
  - `event <name> trigger` appears in `AnimParser.hx:162` (the LSP hover text), `CLAUDE.md:101`,
    `anim-reference.md:152` and `anim.md:30/309/554`. `trigger` isn't a keyword, and the bare-event
    branch (AnimParser.hx:1602-1604) leaves it as an unexpected token.
  - Per-animation `center:` is documented (anim-reference.md:107/121, anim.md:115/261), but
    `parseAnimation` rejects it.
  - `CLAUDE.md:25/158` claims `.anim` hot reload, which doesn't exist (hot-reload.md:465).
  - "Per-frame filters accumulate" (anim-reference.md:240) is wrong: `SetFilter` replaces
    (AnimationSM.hx:262-279).
  - `loop: N` means N extra loops (N+1 plays; AnimationSM.hx:143, 216-219). Say so explicitly.

  DOC-14 / DOC-24 in the audit cover part of this but miss the hover copy. **S**
- [ ] `BUG-12` **`$$state$$` parses, then fails at load.** The parser substitutes only `${state}`
  (AnimParser.hx:2043-2050), and `validateSheetName` ignores `$$` (:1864-1879). 23 files still use
  `$$` (all 20 in hx-easy-game, plus escape and the playground `dist`), and the unit generator still
  emits it (`assets/scripts/spritesheet_to_anim.py:509-512`). They fail at runtime with "tiles not
  found". Reject `$$` at parse time with a migration message, and fix the generator. **S**
- [ ] `BUG-13` **`.anim` LSP gets it backwards.** `AnimParserLsp` reports false positives on the legacy
  `animation {` form (30 of 62 real files) and on the documented `animation name @(cond) {`
  (AnimParser.hx:2458-2464). Meanwhile it reports 0 diagnostics for real body errors (`bogus fire`,
  `center:` in an animation, `${nostate}`, `event x trigger`), because it `skipBlock()`s every
  animation body (:2465). Lexer errors land at 0:0 (AnimAnalyzer.hx:40-46). Fixed properly by
  `ANM-5`. **S** (stopgap) / **M** (real fix)
- [ ] `BUG-14` **Agent instructions that don't load or are stale.**
  - `../.claude/skills/manim-ui.md` and `add-unit.md` are flat files with no frontmatter, so Claude
    Code doesn't discover them as skills.
  - proto-game `.claude/commands/screenshot.md` has stale paths (`c:/Users/goraz/work/dotabota`) and
    sends `width/height` straight to DevBridge, which ignores them.
  - `screen-design.md` says "use `npx haxe`" while `screenshot.md` says "do NOT use npx", and it
    points to a `manim-ui.md` that doesn't exist in proto-game.
  - The card-hand arrow snippet in the auto-loaded `.claude/rules/runtime-systems.md` doesn't parse
    (`expected graphics element or ), got TQuestion`; DOC-4/24). **S**

---

## Part 1 — MCP server + DevBridge

The tool set is broad (37 DevBridge methods + `connect`) and the error model is good: `code`
values, `isError`, cursor-based debugger hits. The gaps are in **feedback delivery**,
**addressing**, **seeing**, and **`.anim`**.

### A. Getting feedback to the model

- [ ] `MCP-1` **Unified event inbox with a cursor.**
  - **Today:** events live in separate buffers with inconsistent semantics.
    - `get_traces`: no ids, `clear` defaults to false.
    - `get_errors`: no ids, `clear` defaults to **true**.
    - `get_debugger_hits` and `get_game_events`: have ids and cursors.
    - `reload`, `screen_change`, `parameter_change` and `custom`: SSE only, nothing to poll.
  - **Proposal:** one ring buffer of typed events, each with a monotonically increasing id, and
    `get_events({since_id, types?, limit?})`. Keep the old tools as filtered views. This also gives a
    **reload history**, so an agent that saved a file can ask "what happened to my reload?"
    (auto-reload on save, ScreenManager.hx:318, is otherwise invisible). **M**
- [ ] `MCP-2` **Piggyback notices on every tool result.** Append a compact block to every response,
  e.g. `_notices: {lastEventId, newErrors: 2, reloadFailed: "ui/menu.manim:12:4 unknown variable
  $hq", paused: true, debuggerHit: 7}`. An agent busy with `screenshot` or `click_button` then
  learns about a background failure without remembering to poll. Omit it when there is nothing
  new, so it costs nothing. **S**
- [ ] `MCP-3` **Push through Claude Code channels, not log messages.**
  - Claude Code does not put MCP logging notifications (`notifications/message`, which is what
    `sendLoggingMessage` sends) into the model's context. Every SSE "real-time" promise in the tool
    descriptions and the server `instructions` (debugger hits, reload results, game events) is
    therefore invisible to the agent.
  - Channels are Claude Code's supported push path (research preview):
    - The server declares `capabilities.experimental['claude/channel']` and sends
      `notifications/claude/channel` with `{content, meta}`.
    - The user enables it with `--channels` / `--dangerously-load-development-channels`, and
      Team/Enterprise orgs must allow it in managed settings.
  - The uncommitted `dist/channel.js` prototype (routes `debugger` by default, configurable via
    `HX_CHANNEL_EVENTS`) was the right idea. Commit it as `src/channel.ts` and route
    `debugger`, `reload:failed`, `error` and `game_event` through it.
  - Keep `MCP-1` + `MCP-2` as the path that works without channels. **S–M**
- [ ] `MCP-4` **Blocking waits with a timeout.**
  - **Today:** `wait_for_idle` doesn't wait; it returns the current state, so agents write polling
    loops.
  - **Proposal:** `wait_for({until: "idle"|"event"|"element"|"reload"|"screen", name?, timeout_ms})`.
    Implement it as a *deferred* HTTP response completed from `tick()`, which already runs every
    frame (DevBridge.hx:425). That avoids blocking the game loop.
  - Also give `bridge.ts` `fetch` a timeout (`AbortSignal.timeout`). Today a hung game hangs the
    agent's tool call forever. **M**
- [ ] `MCP-5` **Stop self-pollution.** Make request tracing (`BUG-9`) opt-in (`HX_DEV_VERBOSE=1`),
  or keep it out of the ring buffer. **S**

### B. Seeing what changed

- [ ] `MCP-6` **`render` tool: build and screenshot one programmable offscreen.**
  - **Input:** `{file | source, programmable, params?, sweep?: {param: [values]}, scale?,
    background?}`.
  - **Output:**
    - a PNG, or a labelled contact-sheet grid when `sweep` is given;
    - bounds of every `#named` element and interactive;
    - build errors with positions.
  - **Why:** it removes "navigate the game to the screen that uses it" from the loop. A sweep over
    `status: [normal, hover, pressed, disabled]` renders four states in one call. It also catches
    screenwright PLAN #8 (errors in a non-default arm only surface on `setParameter`).
  - Reuse the offscreen path from `handleScreenshot` and the logic in screenwright's runtime
    (`TOOL-2`). **M**
- [ ] `MCP-7` **Better screenshots.**
  - `element` / `region` crop.
  - `annotate: "interactives" | "named"`: draw numbered boxes with IDs on the image (set-of-marks
    prompting). Agents click far more accurately from marked images than from raw coordinates.
  - Return the pixel→scene scale in the result.
  - Fix `BUG-4`. **M**
- [ ] `MCP-8` **`capture_frames({count, every_frames, element?})`.** Pause, then take N screenshots
  `every_frames` apart and return a single contact sheet. Agents can't watch animations, tweens,
  particles or transitions; a strip of frames is the closest substitute. Reuses `step` and
  `screenshot`. **S–M**
- [ ] `MCP-9` **Visual diff.** `screenshot({baseline: "name"})` stores a baseline in MCP-server
  memory, and `screenshot({compare_to: "name"})` returns the changed-region bounding box plus a diff
  image (sharp is already a dependency). This answers "did my edit change anything, and only what I
  intended?" **M**

### C. Addressing things and mapping them back to source

- [ ] `MCP-10` **Instance addressing.**
  - **Today:** every programmable tool looks up by *name* and silently takes the first match
    (`findBuilderResult`, DevBridge.hx:2062). With five `#card` instances, four are unreachable.
  - **Proposal:**
    - Give each handle a stable `instanceId` (`card@3`) in `list_active_programmables`.
    - Accept `instance` in `set_parameter`, `get_parameters`, `inspect_programmable` and
      `list_slots`.
    - Return `ambiguous` with the candidate list when a bare name matches more than one instance.
  - **S–M**
- [ ] `MCP-11` **Pixel → source.**
  - **Today:** built objects are named `node.uniqueNodeName` (MultiAnimBuilder.hx:6707), i.e.
    `'${name}_${Std.string(type)}_${counter}'` (MacroManimParser.hx:2903). For an unnamed bitmap
    that is `null_BITMAP(TSGenerated(...), ...)_654399`: a full enum dump that is unstable, costs
    many tokens, and says nothing about where it came from.
  - **Proposal:**
    - In DEV builds, keep a side table from object to `{kind, userName, file, line, col,
      programmable, instanceId}`, filled where the builder names objects.
    - `scene_graph`, `find_element_at` and `inspect_element` return
      `{kind: "bitmap", name: "#hpFill", src: "ui/combat.manim:118:5", in: "hpBar@3"}`.
    - A stable path (`hpBar@3/#bar/bitmap[2]`) is accepted anywhere an element name is.
  - This closes the most common agent task: "this looks wrong in the screenshot → which line do I
    edit?" Depends on `MAN-6` for positions outside DEV. **M**
- [ ] `MCP-12` **One coordinate space.** Pick "scene" for every tool:
  - `send_event` / `send_events` convert scene → window.
  - `screenshot` reports the scale.
  - `list_interactives` returns **global** bounds plus a centre point. Today it returns local
    `interactive.x/y` with no width/height for interactives (DevBridge.hx:1278-1283), so an agent
    can't compute a click target from it.

  Fixes `BUG-5`. **S**
- [ ] `MCP-13` **Friendlier input.**
  - `send_event` accepts key names (`"ESCAPE"`, `"A"`, `"F1"`) through `hxd.Key` reflection, not
    just numeric codes.
  - `click_button` dispatches a synthetic `UIClick` (DevBridge.hx:1754), which skips hover, push
    and z-order hit testing. Add `mode: "pointer"`, which does a real move/push/release at the
    interactive's global centre, so the agent tests what a user would hit. **S**

### D. Navigation, state and discovery

- [ ] `MCP-14` **Standard navigation ops built in.**
  - `switch_screen(name, data?)`, `open_dialog`, `close_dialog`, `set_time_scale`, and
    `list_screens` with class names and which programmables each screen built.
  - Today an agent has to click through menus to reach the screen it's editing, and neither game
    registers any game ops (proto-game and inc_game register zero).
  - screenwright's template already implements `open_screen`, `screen_bounds` and `input_key`
    (`../screenwright/templates/blank/src/game/Main.hx:58-149`). Ship them as built-ins or as a
    `DevOps.registerStandard(bridge, screenManager)` helper. **M**
- [ ] `MCP-15` **Richer parameter and builder info.**
  - `list_builders` and `get_parameters` should add, per parameter: default value, declaration
    order, and doc (`MAN-1`/`MAN-2`). Today they return name + type only; the
    `list_active_programmables` comment even says "types and defaults" (DevBridge.hx:1955) but no
    defaults are emitted.
  - `list_builders` should also return the node kind (programmable / paths / curves / particles /
    data / autotile / atlas2), the source line, and drop pseudo-nodes like `#defaultPaths`.
  - Add `set_parameters` (batch, using `beginUpdate` / `endUpdate`) so a state change is one
    rebuild. **S**
- [ ] `MCP-16` **`.anim` tools.** There are none today. An `AnimationSM` shows up in `scene_graph` as
  type/x/y only.
  - **Static:** `describe_anim(file)` returns animations × states with frame counts, ms/frame, total
    duration, loop count, event timeline, extrapoints and metadata (shares code with `ANM-6`).
  - **Live:** `list_anim_instances` returns file, state selector, current animation, frame i/n,
    loops remaining, paused, and extrapoints in global coordinates.
  - **Commands:** `anim_play(instance, animation)` and `anim_set_state`.
  - **Events:** an `anim_event` event type for `onAnimationEvent` and `onFinished`.
  - **Needs:** `AnimationSM` to remember its source file and state selector (AnimationSM.hx:82),
    plus a DEV registry of live instances. **M**
- [ ] `MCP-17` **Instance identity and discovery.**
  - `ping` returns only uptime and port. Also return: main class/game name, pid, cwd, the
    **absolute resource directory** (so the agent can map `ui/menu.manim` to a file to edit), build
    flags (`MULTIANIM_DEV`, `MULTIANIM_STRICT`), library version and bridge protocol version.
  - `connect()` with no port should read `HX_DEV_READY_FILE` or scan 9001–9010 (DevBridge already
    tries port+0..9, DevBridge.hx:111), and a `list_instances` tool should show what's running.
  - With several worktrees and games, "which game am I talking to?" is a real risk. **S**
- [ ] `MCP-18` **Game ops as first-class tools (optional).** On `connect`, call `list_game_ops`,
  turn each op's schema-lite params (`{lane: "int", count: "int?"}`) into zod/JSON Schema, and
  register `game__<op>` tools, then emit `tools/list_changed` (Claude Code supports it).
  First-class tools are much easier for a model to discover and call correctly than a generic
  `game_op(op, params)`. Put it behind a flag, because it grows the tool list. **M**
- [ ] `MCP-19` **Merge `custom` into `game_event`.** `broadcastCustomEvent` (SSE only, no buffer,
  DevBridge.hx:309) and `emitEvent` (buffered, cursor, registry) overlap. Keep `emitEvent` and make
  `broadcastCustomEvent` a deprecated alias. **S**

### E. Protocol hygiene

- [ ] `MCP-20` **Tool annotations.**
  - Mark the ~25 read-only tools `readOnlyHint: true`, mark `quit` / `reload` / `set_*` / `send_*` /
    `game_op` with `destructiveHint`, and add `title`s. It's cheap and MCP-spec correct.
  - Claude Code doesn't document using annotations for permissions, so keep the `settings.json`
    allowlists regardless. Other clients do use them.
  - **Don't** add `outputSchema` / `structuredContent` for now. A reported Claude Code bug
    (anthropics/claude-code#25081) drops a server's tools when `outputSchema` is present. Re-check
    before adopting. **S**
- [ ] `MCP-21` **MCP resources and prompts.**
  - **Resources:** the condensed grammar (`KB-1`), `anim-reference.md`, the cookbook and
    `devbridge.md`. Also live views: `manim://builders`, `manim://screens`,
    `manim://outline/<file>` (from `MAN-5`).
  - **Prompts:** workflow recipes such as "verify a UI change" (render → annotate → overlaps) and
    "debug a layout" (find_element_at → source → edit → reload → diff).
  - The MCP server then carries its own manual instead of depending on the game repo's
    CLAUDE.md. Client support for resources and prompts varies, so check how the target client
    surfaces them before investing heavily. A skill (`KB-3`) delivers the same recipes
    reliably. **S–M**
- [ ] `MCP-22` **Output size control.**
  - `callBridge` pretty-prints every result (`JSON.stringify(result, null, 2)`, `tools.ts:37`).
    Emit compact JSON.
  - `scene_graph` defaults to depth 10 over the whole `s2d`. Add `root` / `screen` /
    `name_filter` / `type_filter` / `max_nodes`, and omit default-valued fields.
  - With `MCP-11`'s short names, this cuts typical dumps by a large factor.
  - This matters beyond cost: Claude Code warns above 10k tokens of MCP tool output and truncates
    at `MAX_MCP_OUTPUT_TOKENS` (default 25k), images included. A depth-10 `scene_graph` of a busy
    screen, or a full-resolution hi-DPI screenshot, can hit that. Consider defaulting `screenshot`
    to a capped width. **S**
- [ ] `MCP-23` **Tests for the MCP server.** There are none (no `test` script in `package.json`). A
  fake DevBridge HTTP+SSE server test would have caught `BUG-1` and `BUG-2`. **S**

---

## Part 2 — `.manim`: files that describe themselves

**Principle:** the prose already exists. About 345 of ~840 programmables in the games and
playground have a `//` comment directly above them, and the good ones carry exactly what an agent
needs: render size and origin ("a 28x28 weapon icon (origin top-left)", `inc_game/res/manim/art.manim:900`),
the Haxe consumer ("CombatScreen.showBars", `art.manim:815`), invariants ("Nothing inside an arm
may reference hp / shield / status", `art.manim:8`). Turn that habit into structured data rather
than inventing a new one.

**Constraints:**
- `#` can't start a comment: it's names and colours (MacroManimParser.hx:393-404).
- `//` and `/* */` are dropped in the lexer (:128-157) with no trivia channel.
- `Token` has line/col only (:62-71).
- `Node` positions exist only under `MULTIANIM_DEV` (MultiAnimParser.hx:1035).
- Neither `///` nor `/** */` appears in any of the 333 real `.manim` files, so claiming them breaks
  nothing.

- [ ] `MAN-1` **Doc comments.**
  - `///` (and `/** … */`) attach to the next node, programmable or parameter.
  - The lexer accumulates doc text onto the next token. `createNode` (MacroManimParser.hx:2871)
    fills a new `Node.doc`, and `parseDefine` fills `Definition.doc` (MultiAnimParser.hx:266, today
    just `{name, type, defaultValue}`).
  - Opt-in fallback: treat a contiguous `//` block directly above a root `#name` (no blank line,
    banner lines of `=`/`-` skipped) as its doc. That documents ~345 programmables with zero edits.
  - Store docs on `Node`/`Definition`, **never** in `NodeType` payloads. `uniqueNodeName` embeds
    `Std.string(type)`, so payload changes rename nodes.
  - Doc edits stay hot-reload-safe: `SignatureChecker` compares only parameter names and types.
  - **M**
- [ ] `MAN-2` **Inline parameter docs.** `hp:0..999=100 "current hull points"`. A trailing string
  after the default is unambiguous, because `,` or `)` must follow (MacroManimParser.hx:1857).
  Parameter meaning is what agents most often guess wrong: `lease`, `sel`, `sub` on
  `combat.manim:112`'s `#nodeCell`. **S**
- [ ] `MAN-3` **A few structured annotations.** Proposed syntax is illustrative; add them to the `@`
  loop (MacroManimParser.hx:2943-3087) without counting toward `atCount`, and store them in
  `Node.annotations`.

  | Annotation | Carries | Consumed by |
  |---|---|---|
  | `@size(w, h)` + `@origin(topLeft\|center)` | declared footprint | `render`, bounds checks in tests/STRICT, `check_overlaps` |
  | `@usedBy("CombatScreen.showBars")` | Haxe consumer | outline, resource index (`TOOL-4`) |
  | `@example(status=>hover, hp=>30)` (repeatable) | states worth previewing | `render` sweeps, auto visual tests, docs |
  | `@tag(hud, card)` | grouping | outline filtering |

  **M**
- [ ] `MAN-4` **Host contracts made explicit.** The hardest thing for an agent is the unwritten
  contract between a `.manim` file and Haxe code. `ftl4.manim:1188-1219` wires `callback("hpBar")`,
  `builderParameter("endTurnBtn")` and `#energyDisplay(updatable)`, and nothing lists what the
  host must provide.
  - `std.manim`'s `#button` / `#checkbox` / `#slider` must declare `status`, `buttonText` and
    `checked`; renaming one breaks `UIMultiAnimButton` silently.
  - The outline should derive a **contract section** automatically (callbacks, builderParameters,
    placeholders, updatables, slots, interactive IDs + metadata keys, settings keys).
  - Add `@implements(button)` on widget programmables, validated against the widget's required
    parameters at build time. **M**
- [ ] `MAN-5` **One outline extractor, three front-ends.**
  - A noheaps-safe `ManimOutline` in the library produces, in **declaration order**:
    - kind;
    - parameters (type / default / doc);
    - annotations;
    - the contract (`MAN-4`);
    - ref targets (`staticRef`, `dynamicRef`, `buildName`);
    - imports;
    - paths, curves, particles, animatedPaths, data blocks and `@final`s, with source lines.
  - **Two fixes it needs:**
    - `MultiAnimResult.nodes` is a `Map` and loses order (MultiAnimParser.hx:1042).
    - `import` is dropped entirely when there is no loader (MacroManimParser.hx:5342), so no tool
      can list imports today.
  - **Front-ends:** `manim outline --json` (CLI), `describe_manim(file)` (MCP, no live instance
    needed), and LSP outline/hover. **M**
- [ ] `MAN-6` **Real positions in the AST, always.**
  - Add start/end line/col on every `Node` (tokens need offsets or lengths), not gated by
    `MULTIANIM_DEV`.
  - `MULTIANIM_DEV` doesn't compile for JS, so browser builds lose all build-error positions
    (screenwright PLAN #2). At minimum, split positions into their own flag (e.g.
    `MULTIANIM_POSITIONS`) that doesn't pull in DevBridge.
  - **Unlocks:**
    - correct LSP ranges (today 1-char ranges via `findNameInText`);
    - codegen errors inside the `.manim` file instead of at the `@:manim` field
      (ProgrammableCodeGen.hx:487-497);
    - `MCP-11`;
    - positioned errors for `staticRef(external(...))` (screenwright PLAN #7).
  - **M**
- [ ] `MAN-7` **LSP uses the docs.**
  - Hover on `#name`, on `staticRef` / `dynamicRef` targets and on `buildName => "x"` shows the
    signature plus doc (today it shows nothing).
  - `$param` hover is scoped to the enclosing programmable (today a whole-file regex,
    HoverProvider.hx:40).
  - Completion offers programmable names and params with docs. Add workspace symbols.
  - Overlaps the audit's LSP backlog (release-1.0-audit.md:414-417). **M**
- [ ] `MAN-8` **Codegen emits `doc`** on generated Instance/Factory types, `create` (with `@param`
  lines) and the `setX` setters, so Haxe IDE hover works (ProgrammableCodeGen.hx:309-333, 971,
  9129+). Low priority: the games use no `@:manim` fields (0 in proto-game/inc_game) and ~270
  string-keyed builds. **S**
- [ ] `MAN-9` **Errors an agent can act on.**
  - Add codes to `InvalidSyntax`.
  - Show readable tokens instead of `TIdentifier(bitmapp)` / `TCurlyOpen`.
  - Add edit-distance "did you mean" for element names, param types, filters, particle keys and
    `$refs`. `unknown variable $hq. Available: hp` is close; extend the pattern everywhere.
  - Report an unclosed `{` at the opener, not at EOF.
  - Recover at root `#name` boundaries so one pass reports every error.
  - Overlaps ERR-1/2/5 (make ERR-5, silently ignored particle keys like `speeed: 50`, a
    priority). **M**
- [ ] `MAN-10` **Document the comment/doc syntax** in `docs/manim-reference.md` (`.manim` comment
  syntax is currently undocumented anywhere). Add `///` to the VS Code grammar. **S**
- [ ] `MAN-11` *(lower priority)* **Named shape reuse.** A point-list `@final` or named polygon, so
  the 12-number hex vertex list repeated ~10× in `combat.manim:113-127` is one edit. **M**

---

## Part 3 — `.anim`: sprites that describe themselves

**What an agent can't learn from a `.anim` today:**
- what the sprite depicts, its facing, its size, or which entity uses it;
- frame counts or durations (those live in the `.atlas2`);
- event timing, and which state × animation combinations are valid;
- whether an animation is meant as a one-shot.

The runtime surface is `AnimParserResult` = `definedStates` + `metadata` + `createAnimSM()`
(AnimParser.hx:736-741). Animation names, sheet, center and events aren't exposed, so screenwright
reaches in with `@:access` (PLAN #11).

**Comments drift:** `proto-game/res/beam_crew.anim:45-47` says "anims always loop in this engine"
and sets death animations to `loop: yes`. `loop: no` + `onFinished` exist (AnimationSM.hx:161-167).
Structured, validated fields don't drift the way prose does.

The best current practice is `inc_game/res/ships/enemy1.anim` (generated by
`assets/scripts/ships_to_anim.py:667-677`): a prose header plus `facing/length/width` metadata, and
a hull polygon squeezed into a string because metadata has no arrays.

- [ ] `ANM-1` **Header fields.** `description:`, `tags: [...]`, `usedBy:`, `facing:`, `source:` /
  `credit:` / `license:`, and a `version:` header like `.manim` has. Touches `parse()`
  (AnimParser.hx:866-981), `AnimKeywordInfo`, the LSP and the docs. **S**
- [ ] `ANM-2` **Per-animation intent.**
  - `///` doc comments attach to animations, states, extrapoints and metadata keys.
  - Per animation: `description:`, `intent: loop | oneShot | hold`, and `emits: [hit, release]`,
    validated against the playlist's events. `intent: oneShot` with `loop: yes` becomes a lint
    instead of a misleading comment.
  - **S–M**
- [ ] `ANM-3` **Declare valid state combinations.** Example: the archer's `impact` colour exists only
  for `attack` (`_variants` in `assets/input/archer.input-anim`), but the `.anim` declares it for
  every animation. An invalid combination only fails when first instantiated (AnimParser.hx:2103).
  A `valid:` / `@(…)` scope on states would make combinations enumerable, for tools, sweeps and
  validation. **M**
- [ ] `ANM-4` **Public introspection API.**
  - On `AnimParserResult`, expose: animation names; states in **declaration order** (today a Map,
    so order is lost; screenwright PLAN #13); sheet; center; `allowedExtraPoints`; and per
    animation fps / loop / playlist / events / filters.
  - Add `AnimMetadata.keys()` / `has()`: it has typed getters but can't be enumerated
    (AnimParser.hx:503-624).
  - **S**
- [ ] `ANM-5` **Split `AnimParser` into a Heaps-free parse phase and a load phase.**
  - The whole parser is `#if (!macro && !noheaps)` (AnimParser.hx:746) because `PlaylistEvent` /
    `ExtraPoints` use `h2d.col.IPoint` (:641-643, 697).
  - Swap in a plain point type, and the LSP, CLI and codegen can all use the real grammar. Retire
    `AnimParserLsp` (`BUG-13`), and completion can offer state values, animation and extrapoint
    names.
  - **M–L**
- [ ] `ANM-6` **`anim describe` (CLI + MCP `describe_anim`).**
  - Parse the `.anim`, join its `.atlas2` (Atlas2.hx:161-212), and output JSON per animation × state:
    - frame count, ms/frame, total ms, loop count;
    - event timeline with ms offsets;
    - untrimmed size and bounding-box union;
    - extrapoints.
  - `--png` adds a contact sheet per animation with the centre and extrapoints drawn (the
    `ships_to_anim.py --preview` pattern), so vision-capable agents can see the art.
  - **M**
- [ ] `ANM-7` **Validate against the atlas.** An opt-in pass over *all* state combinations:
  - tile existence;
  - frame ranges (out-of-range `frames:` is silently clipped today, AnimParser.hx:2118-2121);
  - flip same-size checks (load-time string throws today, :2153-2171).

  Positioned errors, run automatically under `MULTIANIM_STRICT`. Also check `.manim` references
  (`stateanim("f.anim", …)`, `extraPoint("f.anim", …)`), which nothing validates today. **M**
- [ ] `ANM-8` **Structured errors.**
  - Error codes (`anim_unreachable`, `anim_missing_tile`, …).
  - Multiple errors per pass.
  - Lexer errors as `InvalidSyntax` (today plain strings, AnimParser.hx:287/349/419).
  - Load-time errors carry the sheet position (today unpositioned, :2036/2104/2163).
  - **S–M**
- [ ] `ANM-9` **Richer metadata.**
  - Add bool, arrays / point lists (for the hull polygon), bare identifiers, and per-animation
    `metadata {}`.
  - Keep event payload types at runtime; today they flatten to `Map<String,String>`
    (AnimParser.hx:2129-2139) and `bool` becomes int.
  - **M**
- [ ] `ANM-10` **`.anim` hot reload.** Already Phase 2 in hot-reload.md:465; needs the `AnimationSM`
  indirection handle. Without it an agent editing a sprite must restart the game every time.
  `ReloadFileType.Anim` exists but nothing emits it (HotReload.hx:21). **L**
- [ ] `ANM-11` **Keep generator knowledge.** `spritesheet_to_anim.py:430-519` throws away:
  - source pack (artist/licence), frame size, per-animation frame counts;
  - `_variants`, the default state value;
  - every `_comment` ("Collision bounds for game logic", stripped at :477).

  Emit them as `ANM-1` / `ANM-2` fields, and emit `${state}` instead of `$$state$$` (`BUG-12`). **S**
- [ ] `ANM-12` **Lints and cross-references.**
  - Unused `allowedExtraPoints` and states.
  - Duplicate `loop:` / `fps:`.
  - LSP find-references / go-to-definition from `.manim` `stateanim("x.anim", "anim")` to the
    animation in the `.anim`.
  - **M**

---

## Part 4 — Offline tooling (no running game)

**Today:**
- `manim-validate` is parse-only and `.manim`-only. It catches `e:String` first, so an
  `InvalidSyntax` falls through to "Unexpected error". It rebuilds with Heaps on every run.
- The LSP only speaks stdio LSP (ManimLanguageServer.hx:227).
- `MULTIANIM_STRICT` needs a real game run, and doesn't fire on the hot-reload path
  (ScreenManager.hx:1419-1422).
- An offline PNG requires registering a visual test and recompiling.

- [ ] `TOOL-1` **LSP one-shot mode.**
  - `node lsp/bin/server.js --check <files…> --json` reuses `ManimAnalyzer` / `AnimAnalyzer`
    diagnostics. Node-only, fast, and already built.
  - Pair it with an optional PostToolUse hook on Edit/Write of `*.manim` / `*.anim`, so every
    agent edit is validated immediately. That is a `.claude/settings.json` change; your call.
  - **S**
- [ ] `TOOL-2` **Upstream screenwright's engine runtime.** `../screenwright/packages/runtime` already
  implements, over an in-memory file set:
  - `validate` (imports included) and `render(file, programmable, params)`;
  - `setParameter`, `bounds()` (`#name → rect`), `interactives()`, `getData(file, block)`;
  - `playAnim`, and a PNG `snapshot`;
  - structured errors (`kind/file/line/col/name/code`), plus a HashLink checker (`check.hxml`)
    that emits per-state bounds, interactives and texts.

  That is exactly the missing offline layer. Move the engine-facing part into hx-multianim (a
  `bh.multianim.tools` module plus a `manim check|render|describe|outline` CLI in
  hx-multianim-utils replacing `manim-validate`). DevBridge's `render` / `eval_manim` (`MCP-6`,
  `TOOL-5`) and screenwright then share one implementation. **M**
- [ ] `TOOL-3` **Resource ↔ code index.** `manim index --json` scans `res/` (programmables + params,
  `.anim` animations + states, atlas tiles, fonts) and `src/` (`buildFromResourceName("…")`,
  `buildWithParameters("x"`, `buildName =>`, `setParameter("p"`, `@:manim`, `@:data`).
  - proto-game alone has ~55 `buildFromResourceName` calls, and the games have ~270 string-keyed
    programmable references.
  - The index answers "who uses this programmable?" before an agent renames a parameter, and flags
    dead or misspelled keys.
  - DevBridge `list_resources` should also list the filesystem, not only the loader cache
    (ResourceLoader.hx:40).
  - **M**
- [ ] `TOOL-4` **Clear `MULTIANIM_STRICT` coverage.** Fire `strictFail` on the hot-reload path too,
  and build every conditional arm (not just defaults) under a `STRICT_ALL_ARMS` option. This
  turns "only a capture of every state proves a wireframe whole" (screenwright PLAN #8) into one
  flag. **S–M**
- [ ] `TOOL-5` **`eval_manim` v2.**
  - Positions on parse errors: today `parseError: '$e'` with no line/col (DevBridge.hx:826-828),
    while reload errors are fully structured.
  - Pass the resource loader so imports resolve.
  - `programmable` / `params` selection.
  - A `render` option (shares `MCP-6`).
  - `sweep` over enum / bool params, so every arm gets built.
  - Fix `BUG-6`.
  - **M**

---

## Part 5 — Agent knowledge: docs, skills, onboarding

**Context cost today:** auto-loaded context is ~116 KB (~29k tokens: root + library CLAUDE.md +
four rules files) every session. `docs/` is 9,882 lines / 386 KB. There is no machine-readable
grammar (no EBNF, schema or `llms.txt`); the only structured grammar metadata is
`ManimKeywordInfo.hx` and `AnimKeywordInfo`.

- [ ] `KB-1` **Condensed agent grammar.**
  - `docs/manim-grammar.md` (~300 lines), generated from `ManimKeywordInfo` / `AnimKeywordInfo`
    plus a curated EBNF. It is authoritative because it is generated from the same tables as LSP
    hover.
  - An `llms.txt` index.
  - Slim `.claude/rules/*.md` to pitfalls plus pointers (big API dumps like the card-hand section
    move to docs). That frees roughly 20k tokens per session.
  - **M**
- [ ] `KB-2` **Doc-snippet CI gate.** Parse every ` ```manim ` / ` ```anim ` block in `docs/`,
  `CLAUDE.md`, `.claude/rules`, skills, and the keyword hover strings, with `TOOL-1`'s `--check`.
  It would have caught `BUG-11`, the card-hand snippet (`BUG-14`), and future drift. Mark
  intentionally-invalid examples with ` ```manim-invalid `. **S–M**
- [ ] `KB-3` **Skills that close the loop.**
  - Move `manim-ui` to `hx-multianim/.claude/skills/manim-ui/SKILL.md` with frontmatter (see
    `BUG-14`).
  - Add an `anim-author` skill (create or edit a `.anim` from an atlas; check with
    `anim describe`).
  - Give `particle-creator` a validate + preview step: today it has none, and ERR-5 lets key typos
    through.
  - Every authoring skill should end with the same loop: **edit → check (`TOOL-1`) → reload / render
    (`MCP-6`) → annotated screenshot + `check_overlaps` → diff (`MCP-9`)**.
  - Fix proto-game's `screenshot.md` / `screen-design.md`.
  - **S–M**
- [ ] `KB-4` **"Agent tooling" section in root `CLAUDE.md`.** Cover: the MCP server and its package,
  DevBridge ports and `HX_DEV_READY_FILE`, `MULTIANIM_STRICT` semantics, LSP `--check`,
  `manim-validate`, and screenwright. The root CLAUDE.md mentions none of them today. Link to it
  from the game repos' CLAUDE.md files (inc_game's is 1,019 lines on its own). **S**

---

## Suggested sequencing

1. **Quick wins (days):**
   - `BUG-3..14` (`BUG-1`/`BUG-2` go with `MCP-3`);
   - `MCP-5`, `MCP-12`, `MCP-13`, `MCP-15`, `MCP-17`, `MCP-19`, `MCP-20`, `MCP-22`, `MCP-23`;
   - `MAN-2`, `MAN-10`, `ANM-1`, `ANM-4`, `ANM-11`;
   - `TOOL-1`, `KB-2`, `KB-4`.
2. **Feedback loop:** `MCP-1`, `MCP-2`, `MCP-3` (+ `BUG-1`, `BUG-2`), `MCP-4`; `TOOL-2` + `MCP-6` (render); `MCP-7`,
   `MCP-8`, `MCP-10`; `TOOL-5`, `TOOL-4`.
3. **Self-describing assets:** `MAN-1`, `MAN-3`, `MAN-4`, `MAN-5`, `MAN-6`, `MAN-7`; `ANM-2`,
   `ANM-3`, `ANM-6`, `ANM-7`, `ANM-8`; `MCP-11`, `MCP-14`, `MCP-16`; `TOOL-3`.
4. **Deeper work:** `ANM-5`, `ANM-9`, `ANM-10`, `ANM-12`; `MAN-8`, `MAN-9`, `MAN-11`; `MCP-9`,
   `MCP-18`, `MCP-21`; `KB-1`, `KB-3`.

---

## Appendix A — What "good" looks like

**A documented `.manim` programmable** (annotation syntax illustrative):

```manim
/// HP bar drawn above each unit; one instance per unit.
/// Origin top-left. The fill width is hp / maxHp of the track.
@size(48, 6) @usedBy("CombatScreen.showBars") @example(hp => 30) @example(team => enemy)
#hpBar programmable(
    hp:0..999=100 "current hit points",
    maxHp:1..999=100 "maximum hit points",
    team:[player,enemy]=player "fill colour: green for player, red for enemy"
) {
    /// Track behind the fill
    bitmap(generated(color(48, 6, #202020))): 0, 0
    ...
}
```

The same facts then show up in: LSP hover on `#hpBar` / `buildName => "hpBar"`; `describe_manim`
and `list_builders` (with defaults and docs); `render` (sweeps the two `@example`s); the bounds
check (`@size`); and the resource index (`@usedBy`).

**A documented `.anim` header:**

```anim
/// Archer unit. Faces right; flip for left. Death is one-shot and holds the last frame.
description: "Archer unit sprite"
tags: [unit, ranged]
facing: right
source: "<pack name / licence>"
sheet: archer
states: direction(l, r), color(normal, impact)
center: 16, 24

/// Plays once per shot; `release` is when the arrow spawns.
animation shoot { intent: oneShot  emits: [release]  ... }
```

`anim describe archer.anim` then reports per animation × state: frames, ms, event offsets
(`release @ 240 ms`), size and extrapoints, plus a contact sheet.

**`find_element_at` before and after `MCP-11`:**

```jsonc
// today
{"type": "h2d.Bitmap", "name": "null_BITMAP(TSGenerated(...), ...)_654399", "depth": 7, "x": 2, "y": 1}
// proposed
{"kind": "bitmap", "name": "#hpFill", "src": "ui/combat.manim:118:5", "in": "hpBar@3", "bounds": {...}}
```

---

## Appendix B — Cross-references

- **`todo/release-1.0-audit.md`:**
  - ERR-1/2/5 → `MAN-9`, `ANM-8`
  - DOC-4 / DOC-14 / DOC-21 / DOC-24 / DOC-25 → `BUG-11`, `BUG-14`, `KB-2`
  - LSP backlog (:414-417) → `MAN-6`, `MAN-7`
  - `.anim` hot reload (:398) → `ANM-10`
  - DevBridge auth (:418) → relevant once `MCP-17` exposes more instance detail
- **`../screenwright/PLAN.md` "Found in hx-multianim":**
  - #2 → `MAN-6`
  - #6 → `BUG-4`
  - #7 → `MAN-6`
  - #8 → `MCP-6`, `TOOL-4`
  - #9 → `BUG-10`
  - #10 → `BUG-7`
  - #11 → `BUG-11`, `ANM-4`
  - #12 → `BUG-12`
  - #13 → `ANM-4`
  - #1 (flow + conditional repeatable) and #3–5, #14 are engine issues outside this review's scope,
    but worth filing in the audit.
- **`docs/hot-reload.md` Phase 2** → `ANM-10`.
