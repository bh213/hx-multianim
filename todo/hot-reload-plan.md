# Hot Reload Plan — Live .manim Reload for Rapid Iteration

Goal: When a `.manim` file changes on disk, update live visuals in-place — move an HP bar, tweak particle colors, adjust a layout — and see the result instantly without restarting. Preserve game state, slot contents, and parameter values. Only require full restart when the change is structurally incompatible.

## Current Reload: What Happens Today

```
File changed on disk
  → ScreenManager.reload()
    → Clear all builders (cached MultiAnimBuilder instances)
    → Re-parse all .manim files from scratch
    → Clear all resource caches (sheets, tiles, fonts, atlases)
    → screen.clear()  ← destroys ALL h2d objects
    → screen.load()   ← rebuilds everything from scratch
```

**What breaks:**
- All BuilderResult instances orphaned (old h2d objects gone)
- All IncrementalUpdateContext instances invalidated
- All slot contents lost (drag-and-drop state, user-placed items)
- All runtime parameter values reset to defaults
- UI element state lost (scroll positions, selected items, toggled checkboxes)
- Game logic holding references to h2d objects now points to dead objects
- Animations restart from frame 0
- Particles restart from scratch

## Design Decisions

### Dev Mode

**Compile flag: `-D MULTIANIM_DEV`** enables:
- `resource.watch()` file watching on all loaded `.manim` files
- Reloadable object registry (see below)
- Reload event logging with timing info

**Note:** `@:manim` codegen factories are compile-time generated and cannot hot-reload — they require recompile. Hot-reload only works for the runtime builder path (`MultiAnimBuilder.buildWithParameters()`). Games using codegen should use the runtime builder for components they want to iterate on live.

### Reloadable Object Registry

To know which live objects need updating when a file changes, objects must be **registered as reloadable**.

**`ReloadableRegistry`** — a global (or per-ScreenManager) registry that tracks all live BuilderResults by their source `.manim` file path.

```haxe
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
```

**Registration happens automatically** when building in dev mode:
- `builder.buildWithParameters(...)` registers the result in dev mode
- When the BuilderResult's root object is removed from scene, it auto-unregisters (via `onRemove` callback)
- Game code can also manually register/unregister for custom lifecycle management

**Why registration matters:** A single `.manim` file may produce hundreds of live objects (e.g., one HP bar per unit). The registry knows exactly which BuilderResults to update when a file changes. Without it, reload has to blindly rebuild everything.

### Marking Objects as Reloadable

By default in dev mode, all BuilderResults from `.manim` files are registered. But game code can control this:

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

### Error Handling — Keep Running on Bad Edits

Parse and build errors during reload are **expected** — this is the core workflow. A dev types half a line, saves, and the file is temporarily broken. The system must handle this gracefully:

**Rule: On any error, keep everything as-is and report the error. Never tear down live objects on a failed reload.**

| Stage | Error | Behavior |
|-------|-------|----------|
| **Parse** | Syntax error, unexpected token | Keep old builder + old AST. Log error with file:line:col. Retry on next file change. |
| **Parse** | Missing import, bad version header | Same — keep old state, log error. |
| **Build** | Missing sheet, bad tile reference | Keep old objects. Log error. Retry on next change. |
| **Build** | Expression evaluation error | Keep old objects. Log error. |
| **Signature check** | Incompatible param change | Keep old objects. Report `NeedsFullRestart` with reason. |

**Error state lifecycle:**
```
File saved (broken)
  → Parse fails → log error, keep old state, stay watching
File saved (still broken)
  → Parse fails → log error again, keep old state
File saved (fixed)
  → Parse succeeds → proceed with reload → success
```

The file watcher stays active through errors. Every save triggers a new parse attempt. Once the file is valid again, reload proceeds normally.

**Error reporting:**
```haxe
typedef ReloadReport = {
    // ... (existing fields)
    error:Null<{message:String, file:String, line:Int, col:Int}>,
}
```

Game code can display the error in a debug overlay (e.g., semi-transparent error text at screen top). The `onHotReload` callback fires even on errors, so the game can show/hide the error display.

### Parameter Change Rules

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

### StateAnim (.anim files)

State animations have their own state machines with current state, current frame, and transition history.

| Change | Result |
|--------|--------|
| Frame data / sheet references | Reload. Preserve current state + frame index if still valid. |
| Extrapoints positions | Reload. Immediate feedback (e.g., moving a weapon attachment point). |
| State list changed | Restart animation. State machine structure is different. |
| Animation timing (fps) | Reload. Current frame preserved, playback speed changes. |

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
    programmablesRebuilt:Array<String>,
    paramsAdded:Array<String>,           // new params with defaults
    pathsChanged:Bool,
    curvesChanged:Bool,
    layoutsChanged:Bool,
    dataChanged:Bool,
    atlasChanged:Bool,
    particlesRestarted:Array<String>,
    needsFullRestart:Null<String>,       // non-null = reason
    error:Null<{message:String, file:String, line:Int, col:Int}>,  // parse or build error
}
```

## Reload Flow

```
File changed on disk (resource.watch callback in dev mode)
  │
  ├─ Try re-parse .manim file → new MultiAnimResult
  │    └─ PARSE ERROR? → keep old builder, log error, return ReloadReport(error=...), STOP
  │                       file watcher stays active, retry on next save
  │
  ├─ Compare signatures:
  │    ├─ Top-level params: removed or renamed? → NeedsFullRestart (keep old state)
  │    ├─ Top-level params: type changed? → NeedsFullRestart (keep old state)
  │    ├─ Structural type changes? (programmable→data) → NeedsFullRestart (keep old state)
  │    └─ Otherwise: proceed with hot reload
  │
  ├─ Create new MultiAnimBuilder from new AST
  │
  ├─ For each registered ReloadableHandle for this file:
  │    │
  │    ├─ Snapshot current state:
  │    │    ├─ Parameter values (from IncrementalUpdateContext)
  │    │    ├─ Slot contents + data (reparent h2d.Objects)
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
  └─ Return ReloadReport (success or partial success with per-handle errors)
```

### Scene Graph Swap

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
1. **File watching** — `resource.watch()` registered for all loaded `.manim` files
2. **Object registry** — `ReloadableRegistry` tracks all live BuilderResults
3. **Auto-registration** — `buildWithParameters` auto-registers results; `onRemove` auto-unregisters
4. **Debug overlay** (optional) — flash/highlight reloaded objects briefly for visual confirmation

The overhead is acceptable for development. Ship without `-D MULTIANIM_DEV`.

## API Surface

### Game Code (Minimal)

```haxe
// In dev mode, BuilderResult gains:
class BuilderResult {
    public var reloadable:Bool;                    // default true in dev mode
    public var onReload:Null<(BuilderResult, ReloadReport) -> Void>;
}

// ScreenManager gains:
class ScreenManager {
    public function hotReload(?resource):ReloadReport;
    public var onHotReload:Null<(ReloadReport) -> Void>;  // global callback
}
```

### Screen Code

Screens that need custom state preservation implement:
```haxe
interface IHotReloadable {
    function captureState():Dynamic;
    function restoreState(state:Dynamic):Void;
}
```

Most screens won't need this — the automatic parameter/slot/UI state snapshot handles common cases. Only implement `IHotReloadable` for custom game state that the library can't know about (e.g., a unit reference, a game-logic timer tied to a visual).

## What NOT to Do

- **Don't hot-reload in release mode** — hot-reload is dev-only. No registry, no file watching, no runtime overhead in shipped builds.
- **Don't preserve broken references** — if a named element was removed in the new `.manim`, log a warning. Don't silently return null from `getUpdatable()`.
- **Don't auto-cascade imported files** — if `import "other.manim"` changed, that's a separate file watch event. Reload only the directly-changed file. Imports are resolved during parse, so the re-parsed file picks up the new import content.
- **Don't cache old AST** — always re-parse from disk. Parser is fast enough.
- **Don't try to diff ASTs** (Phase 1) — snapshot/rebuild/restore is simpler and sufficient. AST diffing can be added later as an optimization if rebuild is too slow for large scenes.
- **Don't hot-reload codegen** — `@:manim` factories are compile-time. Use the runtime builder path for components you want to iterate on live.

## Phased Implementation

### Phase 1: Core Hot-Reload Infrastructure

1. **Error-safe reload** — parse/build errors keep old state, log error, stay watching for next save
2. **`ReloadableRegistry`** — registry of live BuilderResults by source path
3. **Auto-register/unregister** in `buildWithParameters` (dev mode only)
4. **State snapshot** — capture params, slots, UI state from `IncrementalUpdateContext`
5. **Rebuild + restore** — full rebuild with new builder, restore snapshot to new result
6. **Scene graph swap** — replace old root with new root preserving transforms
7. **Signature check** — detect param removes/renames/type changes → NeedsFullRestart
8. **Param addition** — new params with defaults merge into existing param set
9. **Particle handling** — restart looped, preserve temporary
10. **`ReloadReport`** — structured feedback to game code (including errors)

### Phase 2: Top-Level Component Invalidation

1. **Path invalidation** — `AnimatedPath.onPathInvalidated` callback, re-read geometry
2. **Curve invalidation** — re-resolve curve references in AnimatedPath and particles
3. **Layout invalidation** — auto-handled during rebuild (layout coords recalculated)
4. **Data block change detection** — `report.dataChanged` flag
5. **`ReloadReport` enrichment** — per-component change flags

### Phase 3: Polish & Optimization (if needed)

1. **Fast-path patching** — for position-only and property-only changes, skip full rebuild
2. **Node→object mapping** — store during build for targeted patching
3. **Debug overlay** — brief highlight flash on reloaded objects
4. **Hot-reload indicator** — on-screen status showing reload count/timing

## Use Case: HP Bar on Live Units

This is the motivating scenario. A game has 50 units on screen, each with an HP bar built from `hpBar.manim`. The designer wants to nudge the HP bar 3 pixels to the right.

**Without hot-reload:** Change file → recompile → restart game → replay to get 50 units on screen → check position. Minutes per iteration.

**With hot-reload (dev mode):**

1. Game builds HP bars via `builder.buildWithParameters("hpBar", params, incremental: true)`
2. Each HP bar's `BuilderResult` is auto-registered in `ReloadableRegistry` under `"hpBar.manim"`
3. Designer changes position in `hpBar.manim` and saves
4. `resource.watch` fires → `ScreenManager.hotReload("hpBar.manim")`
5. Registry finds 50 live `ReloadableHandle`s for this file
6. For each: snapshot params (current HP value, color, etc.) → rebuild with new builder → restore params → swap in scene graph
7. All 50 HP bars update to new position instantly. HP values, colors preserved.

Total time: ~100ms for 50 rebuilds. Instant visual feedback.

## Open Questions

1. **Performance at scale:** 50 rebuilds should be fine. 500? Need to measure. If too slow, Phase 4's fast-path patching (position-only changes skip rebuild) becomes important.

2. **Nested imports:** If `main.manim` imports `shared.manim`, and `shared.manim` changes, should we reload everything that imports it? Probably yes in dev mode — track import dependencies in the registry.

3. **StateAnim (.anim) hot-reload:** `.anim` files are a separate parser. Should they also hot-reload? Useful for tweaking animation timing. Lower priority than `.manim` but same infrastructure applies. Can share the same file-watch + invalidation pattern.

4. **Playground integration:** The web playground (`hx-multianim-playground`) already has live preview. Should it share the same reload logic? Probably not — the playground re-parses and rebuilds from scratch each time, which is fine for single-component editing.
