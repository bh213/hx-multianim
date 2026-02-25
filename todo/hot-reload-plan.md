# Hot Reload Plan — Live .manim & .anim Reload for Rapid Iteration

Goal: When a `.manim` or `.anim` file changes on disk, update live visuals in-place — move an HP bar, tweak particle colors, adjust a layout, change an extrapoint position — and see the result instantly without restarting. Preserve game state, slot contents, and parameter values across all screens. Only require full restart when the change is structurally incompatible.

**Scope:** All screens (hero select, shop, combat, etc.) — not just combat. Both `.manim` and `.anim` files are supported.

## Current Reload: What Happens Today

```
File changed on disk (or R key pressed)
  → Heaps LIVE_UPDATE detects change
  → resource.watch() callback fires → onReload(resource)
  → ScreenManager.reload()
    → Save old builders map, clear it
    → Re-parse each .manim resource via buildFromResource()
      → loader.loadMultiAnim() → MacroManimParser.parseFile()
    → If parse fails: rollback to old builders, clear cache, return error
    → If parse succeeds: loader.clearCache()
    → For every registered screen: screen.clear() then screen.load()
    → Re-activate current screen mode via updateScreenMode(this.mode)
```

**What breaks:**
- All BuilderResult instances orphaned (old h2d objects removed by `removeChildren()`)
- All IncrementalUpdateContext instances invalidated
- All slot contents lost (drag-and-drop state, user-placed items)
- All runtime parameter values reset to defaults
- UI element state lost (scroll positions, selected items, toggled checkboxes)
- Game logic holding references to h2d objects now points to dead objects
- In combat: `screen.clear()` removes `combatRoot` → `UIOnControllerEvent(Entering)` triggers `initCombat()` → full combat restart. All unit positions, HP, hero XP, ability cooldowns, buffs — gone
- Animations restart from frame 0
- Particles restart from scratch

### Two Build Patterns in the Game

Understanding these is critical for the hot-reload design:

**Pattern A: Registered incremental results** — built once, updated via `setParameter()`:
- Sidebar hero cards (`CombatScreen.initSidebar()`, `incremental: true`)
- Screen HUD elements (built in `screen.load()`, held as screen fields)
- UI widgets (buttons, sliders, checkboxes, dropdowns — managed by UIScreen)

These have a stable lifecycle: created in `load()`, live until `clear()`. They hold parameter state that needs preserving across reload.

**Pattern B: Transient non-incremental builds** — rebuilt frequently, not held long-term:
- Per-unit HP/mana bars via `DrawingResources.getCreepBody()` / `getHeroBody()` etc.
- Each call to `buildWithParameters(name, params)` creates a fresh `BuilderResult` (no incremental context)
- `UnitVisual` uses a hash-based cache: only rebuilds when params change (HP, shields, status)
- Old `bodyObj` removed, new one added to `bodyContainer` each time the hash changes

For Pattern B, there's nothing to snapshot/restore — we just need the `MultiAnimBuilder` to be replaced so the *next* build call uses the new definition. The unit bodies will pick up changes on their next hash-triggered rebuild (usually next frame when any value changes, or we can invalidate hashes).

## Design Decisions

### Dev Mode — `#if MULTIANIM_DEV`

**Compile flag: `-D MULTIANIM_DEV`** enables:
- `resource.watch()` file watching on all loaded `.manim` and `.anim` files
- Reloadable object registry (see below)
- File content hashing for change detection
- Reload event logging with timing info
- Builder replacement for transient builds
- Notification callbacks for reload events and failures

All hot-reload infrastructure is wrapped in `#if MULTIANIM_DEV` conditional compilation. In release builds, no registry, no file watching, no hashing, no runtime overhead. The goal is zero cost when the flag is not set.

**Where `#if` is practical vs. not:** Registry fields and file-watcher registration are clean `#if` blocks. Avoid `#if` inside tight loops or deeply nested logic where it would hurt readability — in those cases, prefer a no-op function that compiles away.

**Note:** `@:manim` codegen factories are compile-time generated and cannot hot-reload — they require recompile. During development, use the runtime builder path (`MultiAnimBuilder.buildWithParameters()`). After iteration is done, switch to codegen for production. Hot-reload for codegen may be added later.

### Change Detection — File Content Hashing

Instead of reloading all files on every file-watch event, only reload files whose content has actually changed.

```haxe
#if MULTIANIM_DEV
class FileChangeDetector {
    // Map: file path → hash of last-loaded content
    var contentHashes:Map<String, Int>;  // use haxe.crypto.Crc32 or similar fast hash

    // Returns true if file content differs from last known version
    function hasChanged(path:String, currentContent:String):Bool;

    // Update stored hash after successful reload
    function updateHash(path:String, content:String):Void;

    // Clear hash for a file (force reload on next check)
    function invalidate(path:String):Void;
}
#end
```

**How it works:**
1. When a `.manim` or `.anim` file is first loaded, compute and store a hash of its content
2. When `resource.watch()` fires, read the file and compare hash to stored value
3. If hash matches → skip reload (file modification timestamp changed but content didn't, e.g. editor auto-save without changes)
4. If hash differs → proceed with reload, update stored hash on success
5. On failed reload (parse error), do NOT update the hash — the old hash stays so next save triggers another comparison

**Hash choice:** CRC32 or a simple string hash — doesn't need to be cryptographic, just fast. Content is typically <50KB.

### .anim File Hot-Reload

`.anim` files define state animations with playlists, extrapoints, events, and metadata. They are now in scope for hot-reload with specific rules about what can change safely.

**What updates and when:**

| Change | Behavior |
|--------|----------|
| **Extrapoint positions** | Applied on next state change (when `AnimationSM` transitions to a new animation/state, it re-reads extrapoints from the parsed data) |
| **Event timing/names** | Applied on next state change (event triggers are re-resolved from playlist data on animation start) |
| **Animation FPS** | Applied on next state change |
| **Add new animation** | Available immediately for new `playAnimation()` calls. Existing instances don't see it until they try to play it |
| **Modify existing animation** (playlist, frames, loop) | Applied on next state change or `playAnimation()` call |
| **Delete an animation** | **Requires full restart.** Game code referencing the deleted animation by name will fail at runtime |
| **Rename an animation** | **Requires full restart.** Same reason — game code uses the old name |
| **Delete/rename a state** | **Requires full restart.** State selectors in game code would break |
| **Add new state values** | Safe — existing selectors continue to work |
| **Change center point** | Applied on next state change |
| **Modify metadata** | Applied on next metadata access (metadata is re-read from parsed result) |

**Why "on next state change" is sufficient:** In a running game, units constantly cycle through animations (idle → walk → attack → idle). A state change happens within seconds at most. For immediate feedback during development, the developer can trigger a state change manually (e.g., attack a unit, move it). This avoids the complexity of patching live `AnimationSM` instances mid-animation.

**Implementation:**
- `.anim` files are currently loaded via `sys.io.File.getBytes()` (bypassing `hxd.Res`), so they don't have `resource.watch()` support
- In dev mode, register `.anim` file paths with the `FileChangeDetector` and poll for changes (or add `resource.watch()` support by loading through `hxd.Res`)
- On change detected: re-parse via `AnimParser.parseFile()`, replace cached `AnimParserResult` in `CachingResourceLoader.animSMCache`
- Existing `AnimationSM` instances hold a reference to their `AnimParserResult` — on next state change, they read from the (now-replaced) parsed data
- Signature check: compare old vs. new animation names and state definitions. If any animation or state was deleted/renamed, report `NeedsFullRestart`

**Cache invalidation:** `CachingResourceLoader.animSMCache` caches `AnimParserResult` by filename. On `.anim` reload:
1. Remove old entry from `animSMCache`
2. Re-parse and store new result
3. Live `AnimationSM` instances that were created from the old result need their internal `parsedResult` reference updated. Two approaches:
   - **(a) Indirection:** `AnimationSM` holds a reference to a wrapper/handle that points to the latest parsed result. The wrapper is updated in-place. Minimal code change.
   - **(b) Registry:** Similar to `.manim` ReloadableRegistry, track live `AnimationSM` instances and update them on reload. More explicit but more bookkeeping.

Approach (a) — indirection via a thin handle — is preferred for simplicity.

### Hot-Reload Strategy: Two Paths (for .manim)

**Path A — Incremental results:** Full snapshot → rebuild → restore cycle. These are screen-level UI elements with state to preserve.

**Path B — Transient builds:** Just replace the cached `MultiAnimBuilder` in `ScreenManager.builders` / `DrawingResources`. The next `buildWithParameters()` call automatically uses the new definition. No snapshot needed — these objects are rebuilt on demand anyway.

For unit bodies specifically: on `.manim` file change, invalidate the `bodyHash` on all `UnitVisual` instances so they rebuild on the next `draw()` call (next frame). This is the "force rehash" approach — no immediate rebuild of 50+ unit bodies, just a hash invalidation that triggers natural rebuild.

### Reloadable Object Registry

To know which live objects need updating when a file changes, **incremental** BuilderResults must be **registered as reloadable**.

```haxe
#if MULTIANIM_DEV
class ReloadableRegistry {
    // Map: source file path → list of live ReloadableHandle
    var liveObjects:Map<String, Array<ReloadableHandle>>;

    function register(sourcePath:String, result:BuilderResult, ?onReload:ReloadCallback):ReloadableHandle;
    function unregister(handle:ReloadableHandle):Void;
    function reloadFile(sourcePath:String):ReloadReport;
}

typedef ReloadableHandle = {
    sourcePath:String,
    result:BuilderResult,
    programmableName:String,
    currentParams:Map<String, Dynamic>,
    onReload:Null<ReloadCallback>,
}

typedef ReloadCallback = (result:BuilderResult, report:ReloadReport) -> Void;
#end
```

**Registration happens automatically** when building in dev mode:
- `builder.buildWithParameters(...)` registers the result in dev mode
- When the BuilderResult's root object is removed from scene, it auto-unregisters (via `onRemove` callback)
- Game code can also manually register/unregister for custom lifecycle management

**Transient builds (Pattern B) are NOT registered** — they have no state to preserve. The builder replacement handles them.

**Why registration matters:** A single `.manim` file may produce hundreds of live objects (e.g., one HP bar per unit). For incremental results with state, the registry knows exactly which BuilderResults to update. For transient builds, no tracking is needed — just replace the builder.

### Marking Objects as Reloadable

By default in dev mode, all **incremental** BuilderResults are registered. Non-incremental builds are not (they're transient). But game code can control this:

```haxe
// Opt out — this object won't be hot-reloaded (e.g., one-shot temporary effects)
result.reloadable = false;

// Provide custom reload callback (e.g., game needs to re-wire event handlers)
result.onReload = (newResult, report) -> {
    // newResult has same slot contents, same params, fresh visuals
    myUnit.hpBar = newResult;
    wireEvents(newResult);
};
```

### Reload Notification System

Game code needs to know about reload events — both successes and failures — with rich diagnostic information.

```haxe
#if MULTIANIM_DEV
// Listener callback type
typedef ReloadListener = (event:ReloadEvent) -> Void;

enum ReloadEvent {
    // Fired when a file change is detected and reload begins
    ReloadStarted(file:String, fileType:ReloadFileType);

    // Fired on successful reload
    ReloadSucceeded(report:ReloadReport);

    // Fired on parse or build error (old state preserved)
    ReloadFailed(report:ReloadReport);

    // Fired when change requires full restart
    ReloadNeedsRestart(report:ReloadReport);
}

enum ReloadFileType {
    Manim;
    Anim;
}
#end
```

**Registration API on ScreenManager:**

```haxe
#if MULTIANIM_DEV
class ScreenManager {
    // Register/unregister reload listeners
    public function addReloadListener(listener:ReloadListener):Void;
    public function removeReloadListener(listener:ReloadListener):Void;
}
#end
```

**Use cases for listeners:**
- **Debug overlay:** Show reload status, error messages with file:line:col, timing info
- **Error display:** Semi-transparent error text at screen top showing parse errors (auto-clears on next successful reload)
- **Sound feedback:** Play a click on success, a buzz on failure
- **Logging:** Write reload events to a log file for later analysis
- **Metrics:** Track reload counts, average times, failure rates

**Failure information — maximum detail:**

```haxe
typedef ReloadError = {
    message:String,           // human-readable error description
    file:String,              // full path to the file
    line:Int,                 // 1-based line number
    col:Int,                  // 1-based column number
    errorType:ReloadErrorType,
    context:Null<String>,     // surrounding source lines for context
}

enum ReloadErrorType {
    ParseError;               // syntax error, unexpected token
    BuildError;               // missing sheet, bad tile reference, expression error
    SignatureIncompatible;    // param removed/renamed/type changed
    AnimDeletedOrRenamed;     // .anim animation or state deleted/renamed
}
```

### Error Handling — Keep Running on Bad Edits

Parse and build errors during reload are **expected** — this is the core workflow. A dev types half a line, saves, and the file is temporarily broken. The system must handle this gracefully:

**Rule: On any error, keep everything as-is and report the error. Never tear down live objects on a failed reload.**

| Stage | Error | Behavior |
|-------|-------|----------|
| **Parse** | Syntax error, unexpected token | Keep old builder + old AST. Log error with file:line:col. Retry on next file change. |
| **Parse** | Missing import, bad version header | Same — keep old state, log error. |
| **Build** | Missing sheet, bad tile reference | Keep old objects. Log error. Retry on next change. |
| **Build** | Expression evaluation error | Keep old objects. Log error. |
| **Signature check** | Incompatible param change (.manim) | Keep old objects. Report `NeedsFullRestart` with reason. |
| **Signature check** | Deleted/renamed animation or state (.anim) | Keep old state. Report `NeedsFullRestart` with reason. |

**Error state lifecycle:**
```
File saved (broken)
  → Parse fails → notify listeners (ReloadFailed), keep old state, stay watching
File saved (still broken)
  → Parse fails → notify listeners (ReloadFailed) again, keep old state
File saved (fixed)
  → Parse succeeds → proceed with reload → notify listeners (ReloadSucceeded)
```

The file watcher stays active through errors. Every save triggers a new parse attempt. Once the file is valid again, reload proceeds normally.

### Parameter Change Rules (.manim)

**Top-level programmable parameters** (`programmable(param:type=default, ...)`):

| Change | Result |
|--------|--------|
| **Add** new param with default value | Reload works. Existing instances get the default. |
| **Change** default value | Reload works. Instances using the default get the new value. Instances with explicitly-set values keep their value. |
| **Remove** a param | **Requires full restart.** Existing game code may reference it. |
| **Rename** a param | **Requires full restart.** Same reason — game code uses the old name. |
| **Change param type** | **Requires full restart.** Type mismatch would cause runtime errors. |

**Non-top-level parameters** (inner elements, conditionals, expressions):

All changes to inner elements should auto-apply. These are entirely within the `.manim` file's control:

| Change | Result |
|--------|--------|
| Move element position (x,y / grid / hex) | Auto-applies to all live instances |
| Change bitmap source | Auto-applies (swap tile) |
| Change text content/color/font | Auto-applies |
| Change filter parameters | Auto-applies |
| Change alpha/scale/color | Auto-applies |
| Change conditional expressions | Auto-applies (re-evaluate visibility) |
| Change arithmetic expressions | Auto-applies |
| Add/remove child elements | Rebuild that subtree, splice into parent |
| Change element type (bitmap→text) | Rebuild that subtree |

### Static Items Always Auto-Apply

Elements without parameter dependencies are "static" — their output is fully determined by the `.manim` file alone. Changes to static items are the simplest case and should **always auto-apply** with zero game code involvement.

Examples:
- A background `bitmap` at a fixed position
- A `text` label with hardcoded content
- A `ninepatch` border with fixed dimensions
- A `tilegroup` with static tile placements
- `graphics` / `pixels` primitives
- `layers` / `flow` containers with static children

Since these elements have no parameter-driven state to preserve, the reload can simply rebuild them and swap them into the scene graph at the same position.

### Particles

Particle systems have their own runtime state (live particles, emission timers, force fields). Hot-reload rules:

| Particle type | On reload |
|---------------|-----------|
| **Looped** (`loop: true`, default) | Restart with new properties. Looped particles are continuous effects — restarting is acceptable and gives immediate visual feedback of the change. |
| **Temporary/one-shot** (`loop: false`) | Keep alive until natural death. These are fire-and-forget effects (explosions, impacts). Don't kill mid-animation. New instances will use new properties. |

Implementation:
- When reloading, check each live `Particles` object's `emitLoop` flag
- Looped: destroy existing `ParticleGroup`, create new one from updated AST, restart emission
- Temporary: leave untouched. They'll die naturally via `isDone` → `onEnd` → `remove()`
- If particle properties changed but no structural change: update `ParticleGroup` fields in-place (speed, gravity, colors, etc.) — even for looped particles this is preferable to restart when possible

### Other Top-Level Components

Top-level non-programmable definitions (paths, curves, layouts, data, atlas2) live in the same `.manim` file and should reload too. The challenge: game code may hold references to resolved instances.

#### Paths

```manim
paths {
    myPath: M 0,0 L 100,50 C 80,20 120,80 200,50
}
```

**On reload:** Re-parse path definitions. But game code may hold a `MultiAnimPaths` or `AnimatedPath` object obtained from `builder.getPaths()` or `builder.createAnimatedPath()`.

**Strategy:** Paths are re-created on each `getPaths()` / `createAnimatedPath()` call (not cached), so after the builder is replaced, the next call gets fresh data. But live `AnimatedPath` instances hold a snapshot of the path.

**Solution — invalidation callback:**
```haxe
var ap = builder.createAnimatedPath("myPath");
// In dev mode, ap registers itself. On reload:
// ap.onPathInvalidated is called, ap re-reads path data from new builder
// ap.position/rate preserved, path geometry updated
```

Game code that caches `getPaths()` results needs to re-fetch after reload. The `onReload` callback on `ReloadableHandle` is the right place:
```haxe
result.onReload = (newResult, report) -> {
    if (report.pathsChanged) {
        myPaths = newBuilder.getPaths();
        // rebuild any path-dependent state
    }
};
```

#### Curves

```manim
curves {
    easeAttack: bezier(0, 0, 0.2, 1.0)
    fadeOut: steps(5)
}
```

Similar to paths — `getCurves()` creates fresh instances each call. Live references (e.g., `AnimatedPath` curve slots, particle `sizeCurve`) hold snapshots.

**Solution:** Same invalidation pattern. `AnimatedPath` re-reads its curve slots on invalidation. Particles that reference named curves re-resolve them.

#### Layouts

```manim
layouts {
    gridSlot: 50, 30
    headerBar: 0, 0, 400, 40
}
```

Layouts are used by `layout(name)` coordinate references. On reload, positions using `layout()` coordinates should auto-update since they're recalculated during rebuild.

**For game code using `builder.getLayouts()`:** Same re-fetch pattern via `onReload` callback.

#### Data Blocks

```manim
#stats data {
    hp: 100
    speed: 5.5
    name: "warrior"
}
```

Data blocks are pure values. On reload, game code that called `builder.getData("stats")` holds a stale snapshot.

**Solution:** `onReload` callback + `report.dataChanged` flag. Game code re-fetches and applies.

#### Inline Atlas2

```manim
#sprites atlas2("spritesheet.png") {
    idle: 0, 0, 32, 32
    walk: 32, 0, 32, 32
}
```

Atlas definitions affect tile lookups. On reload, the builder's `inlineAtlases` map is rebuilt. Any `bitmap(sheet(...))` references using the atlas will get new tiles during rebuild.

**No special game code action needed** — tiles are resolved during build, and the rebuild produces correct tiles from the new atlas definition.

### ReloadReport

Every reload produces a report so game code knows what changed:

```haxe
typedef ReloadReport = {
    success:Bool,
    file:String,                                  // path of the changed file
    fileType:ReloadFileType,                      // Manim or Anim
    programmablesRebuilt:Array<String>,            // .manim only
    paramsAdded:Array<String>,                     // new params with defaults (.manim)
    animationsModified:Array<String>,              // .anim only — which animations changed
    pathsChanged:Bool,
    curvesChanged:Bool,
    layoutsChanged:Bool,
    dataChanged:Bool,
    atlasChanged:Bool,
    particlesRestarted:Array<String>,
    needsFullRestart:Null<String>,                 // non-null = reason
    errors:Array<ReloadError>,                     // all errors (parse, build, per-handle)
    rebuiltCount:Int,                              // number of live objects rebuilt
    elapsedMs:Float,                               // total reload time
}
```

## Reload Flow — .manim Files

```
File changed on disk (resource.watch callback in dev mode)
  │
  ├─ Read file content, compute hash
  │    └─ Hash matches stored hash? → skip reload, STOP (content unchanged)
  │
  ├─ Try re-parse .manim file → new MultiAnimResult
  │    └─ PARSE ERROR? → keep old builder, notify listeners (ReloadFailed), STOP
  │                       file watcher stays active, retry on next save
  │
  ├─ Compare signatures (for each programmable in file):
  │    ├─ Top-level params: removed or renamed? → NeedsFullRestart (keep old state)
  │    ├─ Top-level params: type changed? → NeedsFullRestart (keep old state)
  │    ├─ Structural type changes? (programmable→data) → NeedsFullRestart (keep old state)
  │    └─ Otherwise: proceed with hot reload
  │
  ├─ Create new MultiAnimBuilder from new AST
  │
  ├─ Replace cached builder in ScreenManager.builders map
  │    (transient builds will pick up the new builder automatically on next build call)
  │
  ├─ Update content hash for this file
  │
  ├─ Notify transient-build consumers (e.g., DrawingResources):
  │    └─ Invalidate bodyHash on all live UnitVisuals → rebuild on next draw frame
  │
  ├─ For each registered ReloadableHandle for this file (incremental results):
  │    │
  │    ├─ Snapshot current state:
  │    │    ├─ Parameter values (from IncrementalUpdateContext)
  │    │    ├─ Slot contents + data (reparent h2d.Objects to temp holder)
  │    │    ├─ UI element state (scroll pos, selection, toggles)
  │    │    └─ DynamicRef parameter values
  │    │
  │    ├─ Try rebuild with new builder:
  │    │    ├─ builder.buildWithParameters(name, savedParams, incremental: true)
  │    │    └─ BUILD ERROR? → keep old objects for this handle, log error, continue to next handle
  │    │
  │    ├─ Restore state to new BuilderResult:
  │    │    ├─ Re-apply parameter values via setParameter()
  │    │    ├─ Reparent slot contents into new SlotHandles
  │    │    ├─ Restore UI element state
  │    │    └─ Restore dynamicRef parameters
  │    │
  │    ├─ Handle particles:
  │    │    ├─ Looped: restart with new properties
  │    │    └─ Temporary: keep alive, don't touch
  │    │
  │    ├─ Swap in scene graph:
  │    │    └─ Replace old root object with new root at same position in parent
  │    │
  │    └─ Call onReload callback if registered
  │
  ├─ Notify listeners (ReloadSucceeded with report)
  │
  └─ Return ReloadReport (success or partial success with per-handle errors)
```

## Reload Flow — .anim Files

```
File change detected (polling or resource.watch in dev mode)
  │
  ├─ Read file content, compute hash
  │    └─ Hash matches stored hash? → skip reload, STOP (content unchanged)
  │
  ├─ Try re-parse .anim file → new AnimParserResult
  │    └─ PARSE ERROR? → keep old parsed result, notify listeners (ReloadFailed), STOP
  │
  ├─ Signature check:
  │    ├─ Compare animation names: any deleted or renamed? → NeedsFullRestart
  │    ├─ Compare state definitions: any state deleted or renamed? → NeedsFullRestart
  │    └─ Otherwise: proceed
  │
  ├─ Replace cached AnimParserResult in CachingResourceLoader.animSMCache
  │    (live AnimationSM instances hold a handle/wrapper that now points to new data)
  │
  ├─ Update content hash for this file
  │
  ├─ Notify listeners (ReloadSucceeded with report)
  │    Report includes: animationsModified list
  │
  └─ Live AnimationSM instances pick up changes on next state change:
       ├─ New extrapoint positions read from updated parsed data
       ├─ New event timings read from updated playlists
       ├─ New FPS applied to animation playback
       └─ New/modified animations available for playAnimation() calls
```

**Key difference from .manim reload:** No snapshot/rebuild/restore cycle. `.anim` reload just swaps the parsed data behind an indirection handle. The `AnimationSM` state machine continues running — it picks up new data naturally when it transitions to a new animation.

### Scene Graph Swap (for .manim)

The key operation: replacing the old `BuilderResult.object` with the new one **at the same position in the parent's child list**, preserving the parent-set `x`, `y`, `scaleX`, `scaleY`, `alpha`, and any filters applied by game code.

```haxe
function swapInScene(oldRoot:h2d.Object, newRoot:h2d.Object) {
    var parent = oldRoot.parent;
    if (parent == null) return; // not in scene

    // Preserve game-applied transforms
    newRoot.x = oldRoot.x;
    newRoot.y = oldRoot.y;
    newRoot.scaleX = oldRoot.scaleX;
    newRoot.scaleY = oldRoot.scaleY;
    newRoot.alpha = oldRoot.alpha;
    newRoot.rotation = oldRoot.rotation;
    newRoot.filter = oldRoot.filter; // transfer filter ownership

    // Find position in parent's child list
    var index = getChildIndex(parent, oldRoot);
    parent.removeChild(oldRoot);
    parent.addChildAt(newRoot, index);
}
```

## Dev Mode Implementation

`-D MULTIANIM_DEV` enables:
1. **File watching** — `resource.watch()` registered for all loaded `.manim` files; polling or `resource.watch()` for `.anim` files
2. **Content hashing** — `FileChangeDetector` stores hashes per file, skips reload when content unchanged
3. **Object registry** — `ReloadableRegistry` tracks live incremental BuilderResults
4. **Auto-registration** — `buildWithParameters(..., incremental: true)` auto-registers results; `onRemove` auto-unregisters
5. **Builder replacement** — transient builds pick up new definitions automatically
6. **AnimationSM indirection** — live state machines pick up new `.anim` data via handle
7. **Notification system** — `ReloadListener` callbacks for all reload events (start, success, failure, needs-restart)
8. **Debug overlay** (optional) — flash/highlight reloaded objects briefly for visual confirmation

All wrapped in `#if MULTIANIM_DEV`. The overhead is acceptable for development. Ship without `-D MULTIANIM_DEV`.

## ScreenManager Integration

The critical change: `ScreenManager.reload()` must NOT do `screen.clear()` + `screen.load()` in dev mode. Instead:

```
Current reload (non-dev):
  screen.clear() → screen.load()    // full teardown and rebuild

Hot-reload (dev mode):
  1. Detect which file changed (via content hash comparison)
  2. Replace cached MultiAnimBuilder / AnimParserResult for the changed file only
  3. Clear resource caches that reference the changed file
  4. Rebuild registered incremental results (snapshot → rebuild → restore → swap) — .manim only
  5. Notify transient-build consumers to invalidate — .manim only
  6. For .anim: just swap parsed data behind indirection handle
  7. Notify all registered ReloadListeners
  8. Do NOT call screen.clear() or screen.load()
```

This means the screen's `load()` method only runs once at startup. Hot-reload preserves all screen state — combat continues running, hero selection state preserved, shop inventory intact.

### DrawingResources Integration

`DrawingResources` holds `unitBodiesBuilder`, `terrainBuilder`, etc. On hot-reload:

```haxe
// In dev mode, DrawingResources listens for builder replacement:
// When unitBodiesBuilder's source file changes:
//   1. Replace unitBodiesBuilder with new builder
//   2. Invalidate all UnitVisual.bodyHash values → forces rebuild on next draw()
//   3. Unit bodies pick up new .manim definition naturally on next frame
```

This is lightweight — no 50-unit rebuild burst, just hash invalidation + natural per-frame rebuild.

## API Surface

### Game Code (Minimal)

```haxe
// In dev mode, BuilderResult gains:
#if MULTIANIM_DEV
class BuilderResult {
    public var reloadable:Bool;                    // default true for incremental results
    public var onReload:Null<(BuilderResult, ReloadReport) -> Void>;
}
#end

// ScreenManager gains:
class ScreenManager {
    #if MULTIANIM_DEV
    public function hotReload(?resource):ReloadReport;
    public function addReloadListener(listener:ReloadListener):Void;
    public function removeReloadListener(listener:ReloadListener):Void;
    #end
}
```

### Screen Code

Screens that need custom state preservation implement:
```haxe
#if MULTIANIM_DEV
interface IHotReloadable {
    function captureState():Dynamic;
    function restoreState(state:Dynamic):Void;
}
#end
```

Most screens won't need this — the automatic parameter/slot/UI state snapshot handles common cases. Only implement `IHotReloadable` for custom game state that the library can't know about (e.g., a unit reference, a game-logic timer tied to a visual).

### Transient Build Consumer

Game code that creates transient builds needs to know when its builder changed:

```haxe
#if MULTIANIM_DEV
// DrawingResources or similar:
interface IBuilderConsumer {
    function onBuilderReplaced(sourcePath:String, newBuilder:MultiAnimBuilder):Void;
}
#end

// Implementation in DrawingResources:
function onBuilderReplaced(sourcePath:String, newBuilder:MultiAnimBuilder) {
    if (sourcePath == "manim/unitbodies.manim") {
        unitBodiesBuilder = newBuilder;
        invalidateAllBodyHashes();  // force rebuild on next draw
    }
}
```

## What NOT to Do

- **Don't hot-reload in release mode** — hot-reload is dev-only. No registry, no file watching, no hashing, no runtime overhead in shipped builds.
- **Don't preserve broken references** — if a named element was removed in the new `.manim`, log a warning. Don't silently return null from `getUpdatable()`.
- **Don't auto-cascade imported files** — if `import "other.manim"` changed, that's a separate file watch event. Reload only the directly-changed file. Imports are resolved during parse, so the re-parsed file picks up the new import content.
- **Don't cache old AST** — always re-parse from disk. Parser is fast enough.
- **Don't try to diff ASTs** (Phase 1) — snapshot/rebuild/restore is simpler and sufficient. AST diffing can be added later as an optimization if rebuild is too slow for large scenes.
- **Don't call screen.clear()/screen.load()** — the whole point is avoiding the teardown cycle.
- **Don't rebuild transient builds eagerly** — just replace the builder and let the normal rebuild cycle handle it (next hash change or next frame).
- **Don't forcefully update live AnimationSM mid-animation** — let them pick up changes on next state change. Simpler, safer.

## Phased Implementation

### Phase 1: Core Infrastructure

1. **`FileChangeDetector`** — content hashing for `.manim` and `.anim` files, skip reload on unchanged content
2. **`ReloadableRegistry`** — registry of live incremental BuilderResults by source path
3. **Auto-register/unregister** — `buildWithParameters(..., incremental: true)` in dev mode auto-registers; `onRemove` auto-unregisters
4. **Builder replacement** — `ScreenManager.hotReload(resource)` replaces cached builder for a single file, clears relevant caches
5. **Error-safe reload** — parse/build errors keep old state, log error with file:line:col, stay watching for next save
6. **Notification system** — `ReloadListener` callbacks for reload events (started, succeeded, failed, needs-restart) with full error detail
7. **Signature check** — detect param removes/renames/type changes → NeedsFullRestart
8. **State snapshot** — capture params, slots, UI state from `IncrementalUpdateContext`
9. **Rebuild + restore** — full rebuild with new builder, restore snapshot to new result
10. **Scene graph swap** — replace old root with new root preserving transforms
11. **Param addition** — new params with defaults merge into existing param set
12. **`ReloadReport`** — structured feedback to game code (including errors)
13. **`IBuilderConsumer` notification** — tell DrawingResources etc. that a builder changed
14. All infrastructure behind `#if MULTIANIM_DEV`

### Phase 2: .anim Hot-Reload + Full State Preservation

1. **`.anim` file watching** — register `.anim` paths with change detector, wire up reload trigger
2. **`.anim` parsed data replacement** — re-parse and swap `AnimParserResult` in cache
3. **AnimationSM indirection handle** — live instances follow pointer to latest parsed data
4. **`.anim` signature check** — detect deleted/renamed animations or states → NeedsFullRestart
5. **Particle handling** — restart looped, preserve temporary
6. **Path invalidation** — `AnimatedPath.onPathInvalidated` callback, re-read geometry
7. **Curve invalidation** — re-resolve curve references in AnimatedPath and particles
8. **Layout invalidation** — auto-handled during rebuild (layout coords recalculated)
9. **Data block change detection** — `report.dataChanged` flag
10. **`ReloadReport` enrichment** — per-component change flags, `.anim`-specific fields
11. **UI element state restoration** — scroll positions, selected items, toggles
12. **DynamicRef state** — capture and restore nested dynamic ref parameters
13. **Slot content reparenting** — preserve slot contents across rebuild

### Phase 3: Polish & Optimization (if needed)

1. **Nested import tracking** — when `shared.manim` changes, reload everything that imports it
2. **Fast-path patching** — for position-only and property-only changes, skip full rebuild
3. **Node→object mapping** — store during build for targeted patching
4. **Debug overlay** — brief highlight flash on reloaded objects
5. **Hot-reload indicator** — on-screen status showing reload count/timing/errors

## Use Case: HP Bar on Live Units

This is the motivating scenario. A game has 50 creeps on screen, each with an HP bar built from `unitbodies.manim`. The designer wants to nudge the HP bar 3 pixels to the right.

**Without hot-reload:** Change file → press R → combat restarts from scratch → wait for units to spawn → check position. Minutes per iteration.

**With hot-reload (dev mode):**

1. Game builds unit bodies via `DrawingResources.getCreepBody(...)` → `unitBodiesBuilder.buildWithParameters("creepBody", params)` (non-incremental, hash-cached)
2. `unitbodies.manim` file changes on disk → `resource.watch` fires
3. `ScreenManager.hotReload("unitbodies.manim")`:
   - Content hash check: hash differs → proceed
   - Re-parses the file → creates new `MultiAnimBuilder`
   - Replaces `unitBodiesBuilder` in DrawingResources
   - Invalidates all `UnitVisual.bodyHash` values
4. On next `Combat.run()` → `unit.draw()` → `visual.updateBody()`:
   - Hash check finds mismatch (was invalidated)
   - `getCreepBody(...)` calls `buildWithParameters` on new builder → new visuals
   - Old body replaced, new body shown
5. All 50 unit bodies update within 1-2 frames. Combat continues uninterrupted — same HP, same positions, same buffs.

## Use Case: Sidebar Hero Card

Sidebar hero cards use incremental mode with `setParameter()`:

1. `CombatScreen.initSidebar()` builds `heroCard` with `incremental: true` → auto-registered in `ReloadableRegistry`
2. Every frame, `updateSidebar()` calls `cardResult.setParameter("hp", ...)` etc.
3. `sidebar.manim` changes on disk → `ScreenManager.hotReload("sidebar.manim")`
4. Registry finds the live `heroCard` result:
   - Snapshots current params: `hp`, `mana`, `name`, `heroClass`, `level`, etc.
   - Rebuilds with new builder and same params
   - Restores slot contents (ability icons, item icons)
   - Swaps in scene graph
5. Sidebar updates instantly. Next `updateSidebar()` call continues using the new result as if nothing happened.

## Use Case: Adjusting Unit Extrapoints

A developer wants to move the "fire" extrapoint on an archer unit 2 pixels to the left so projectiles spawn from the correct position.

**Without hot-reload:** Change `.anim` file → restart game → wait for combat to start → wait for archer to attack → check projectile origin. Minutes per iteration.

**With hot-reload (dev mode):**

1. `archer.anim` is loaded at game start, parsed into `AnimParserResult`, cached in `CachingResourceLoader`
2. `AnimationSM` instances for all archers hold a handle pointing to this parsed result
3. Developer edits `archer.anim`, changes `@(direction=>r) fire : 7, -11` to `fire : 5, -11`
4. File change detected → content hash differs → re-parse
5. Signature check: no animations deleted/renamed, no states changed → proceed
6. New `AnimParserResult` replaces old in cache; handle updated to point to new data
7. Next time any archer transitions to attack animation:
   - Extrapoints are read from the (now-updated) parsed data
   - Projectile spawns at the new position
8. Combat continues uninterrupted. Developer sees the change within seconds.

## Resolved Questions

1. **Performance at scale:** Transient builds (unit bodies) don't have a rebuild burst — they update naturally via hash invalidation (1-2 frames). Only incremental results (screen UI, typically <20 per screen) need snapshot/rebuild/restore. Not a concern.

2. **Nested imports:** Deferred to Phase 3. For Phase 1, editing an imported file requires also re-saving the importing file (or pressing R for full reload). Import dependency tracking can be added later.

3. **.anim hot-reload approach:** `.anim` files use a simpler indirection-based approach — no snapshot/rebuild/restore. Live `AnimationSM` instances pick up changes on next state change. Adding new animations is safe; deleting or renaming requires full restart (detected by signature check).

4. **Change detection cost:** Content hashing (CRC32) on file-watch callback is negligible — files are small (<50KB) and callbacks are infrequent (human edit speed). Skipping unchanged files avoids unnecessary parse/rebuild work.

5. **Playground integration:** No — the playground re-parses and rebuilds from scratch each time, which is fine for single-component editing. Different architecture, different needs.

6. **Codegen hot-reload:** Out of scope for now. During development, use runtime builder path. After iteration is done, switch to codegen for production. Codegen hot-reload may be added later as an enhancement.
