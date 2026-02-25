# Hot Reload — Live `.manim` File Updates

Enable with compile flag: `-D MULTIANIM_DEV`

Hot reload updates live visuals in-place when a `.manim` file changes on disk — move an HP bar, tweak colors, adjust a layout — and see the result instantly without restarting. Parameter values, slot contents, and dynamic ref state are preserved across reloads.

## Strategy Summary

| Strategy | When Used | State | Scene | Performance |
|----------|-----------|-------|-------|-------------|
| **A: Nuclear** | File was loaded by a screen (`screen.load()`) | Lost — screen rebuilt from scratch | Cleared + reloaded | Slow (full screen rebuild) |
| **B: In-Place** | Non-screen incremental handles (auto-registered `BuilderResult`) | Preserved — params, slots, dynamicRefs snapshotted + restored | Children swapped, stable root stays in scene | Fast (per-handle rebuild) |
| **C: Transient** | Builder-only usage — no screens, no registered handles | N/A — no live objects to update | N/A | Instant (just cache replacement) |

**Key invariant**: Game-held `BuilderResult` references stay valid across ALL three strategies. Strategy B achieves this via `adoptFrom()` + stable object; Strategy A rebuilds screens fresh; Strategy C has no live references.

## How Strategy Selection Works

```
File changed → hotReload() called
  │
  ├─ screenSourceMap has screens for this file?
  │   YES → Strategy A (Nuclear)
  │   NO  ↓
  ├─ hotReloadRegistry has handles for this file?
  │   YES → Strategy B (In-Place)
  │   NO  → Strategy C (Transient)
```

**What controls the mapping:**
- **Screen mapping** happens during `screen.load()` — any `buildFromResource()` call while `currentlyLoadingScreen` is set records the screen in `screenSourceMap[path]`
- **Handle registration** happens automatically when `buildWithParameters(..., incremental: true)` is called and `reloadable == true` (default)
- **Avoiding screen mapping**: Call `buildFromResourceName()` BEFORE `addScreen()` — since `currentlyLoadingScreen` is null, no screen mapping occurs, and the result uses Strategy B instead of A

## Strategy A: Nuclear Screen Reload

**When**: A `.manim` file that was loaded during `screen.load()` changes.

**What happens**: All screens that loaded this file are cleared and reloaded from scratch. This is the simplest strategy but loses all runtime state.

```
hotReload("ui.manim")
  │
  ├─ screenSourceMap["ui.manim"] → [MyScreen]
  │
  ├─ Unregister all handles for "ui.manim"
  │   (prevents stale ReloadSentinel firing during clear)
  │
  ├─ loader.clearCache()
  │
  ├─ For each affected screen:
  │   │
  │   ├─ screen.clear()
  │   │   ├─ removeElement() for all UI elements
  │   │   ├─ controller.clearState() — resets hover/capture
  │   │   └─ getSceneRoot().removeChildren()
  │   │
  │   ├─ clearScreenFromSourceMap(screen)
  │   │
  │   ├─ currentlyLoadingScreen = screen
  │   │
  │   ├─ screen.load()
  │   │   ├─ buildFromResource() calls → re-recorded in screenSourceMap
  │   │   └─ Auto-registers new incremental results
  │   │
  │   ├─ currentlyLoadingScreen = null
  │   │
  │   └─ On error: record in failedScreens, continue
  │
  ├─ updateScreenMode(this.mode) — refresh scene
  │
  └─ Notify listeners: ReloadSucceeded or ReloadFailed
```

**What is lost:**
- All parameter values (reset to defaults)
- All slot contents (drag-and-drop state, user-placed items)
- UI element state (scroll positions, selected items, toggles)
- In combat: triggers full combat restart (unit positions, HP, XP — gone)
- Animations restart from frame 0

**When to use**: Best for screens where state loss is acceptable (main menu, settings). Unavoidable when the file was loaded inside `screen.load()`.

## Strategy B: In-Place Incremental Reload

**When**: A `.manim` file has registered incremental handles but no screen mapping.

**What happens**: Each live `BuilderResult` is snapshotted, rebuilt with the new definition, state restored, and children swapped into the stable scene node. Game references remain valid.

```
hotReload("sidebar.manim")
  │
  ├─ screenSourceMap["sidebar.manim"] → null (no screens)
  ├─ hotReloadRegistry["sidebar.manim"] → [handle1, handle2, ...]
  │
  ├─ For each handle:
  │   │
  │   ├─ 1. SNAPSHOT current state
  │   │   ├─ params: incrementalContext.snapshotParams()
  │   │   │   → Map<String, ResolvedIndexParameters>
  │   │   ├─ slots: each slot's content object + data
  │   │   └─ dynamicRefs: recursively capture sub-result params
  │   │
  │   ├─ 2. DETACH slot contents
  │   │   └─ slot.clear() on each slot (releases h2d.Objects for reparenting)
  │   │
  │   ├─ 3. REMOVE sentinel + unregister
  │   │   ├─ ReloadableRegistry.removeSentinel(oldResult.object)
  │   │   └─ hotReloadRegistry.unregister(handle)
  │   │   (prevents stale auto-unregister during scene swap)
  │   │
  │   ├─ 4. REBUILD with new builder
  │   │   └─ newBuilder.buildWithParameters(
  │   │         programmableName,
  │   │         snapshotToInputMap(snapshot.params),  ← restored values
  │   │         oldBuilderParams,                     ← original build config
  │   │         null,
  │   │         incremental: true
  │   │       )
  │   │
  │   ├─ 5. RESTORE state into new result
  │   │   ├─ restoreParams: beginUpdate() → setParameter() each → endUpdate()
  │   │   ├─ restoreSlots: reparent content objects into matching new slots
  │   │   └─ restoreDynamicRefs: restore sub-result params
  │   │
  │   ├─ 6. UNREGISTER auto-registration
  │   │   └─ newResult auto-registered itself during build
  │   │       → removeSentinel(newResult.object)
  │   │       → unregister(newResult.reloadHandle)
  │   │   (we'll re-register the stable oldResult instead)
  │   │
  │   ├─ 7. SWAP children in scene
  │   │   └─ SceneSwapper.replaceChildren(oldResult.object, newResult.object)
  │   │       ├─ Remove all old children from oldResult.object
  │   │       ├─ Move all new children from newResult.object → oldResult.object
  │   │       └─ Copy filter property (from apply() nodes)
  │   │       NOTE: oldResult.object stays in scene at same position
  │   │       NOTE: Game transforms (x, y, scale, alpha) preserved
  │   │
  │   ├─ 8. ADOPT internals
  │   │   ├─ stableObject = oldResult.object  ← save stable reference
  │   │   ├─ oldResult.adoptFrom(newResult)   ← copies all internals:
  │   │   │     name, names, interactives, layouts, palettes,
  │   │   │     rootSettings, gridCoordinateSystem, hexCoordinateSystem,
  │   │   │     slots, dynamicRefs, incrementalContext
  │   │   └─ oldResult.object = stableObject  ← restore stable reference
  │   │
  │   ├─ 9. RE-REGISTER stable result
  │   │   └─ oldResult.reloadHandle = hotReloadRegistry.register(...)
  │   │       (plants new ReloadSentinel on oldResult.object)
  │   │
  │   └─ 10. DEFER onReload callback
  │       └─ If oldResult.onReload is set, queue for after report
  │
  ├─ Fire deferred onReload callbacks with final report
  │
  └─ Notify listeners: ReloadSucceeded or ReloadFailed
```

**What is preserved:**
- Parameter values (uint, int, float, bool, string, enum, flags)
- Slot contents (h2d.Objects reparented to new slots)
- Slot data (arbitrary payload)
- Dynamic ref parameter values (recursively)
- Scene graph position (stable root stays in parent's child list)
- Game-applied transforms (x, y, scale, alpha, rotation, visible)
- Game-held `BuilderResult` reference (same object, updated internals)

**What is NOT preserved:**
- `ExpressionAlias` parameters (unsnappable — returns null)
- `TileSourceValue` parameters (unsnappable — returns null)
- Active animations (restart from current state)
- Particle system state (particles restart)
- Scroll positions, focus state (UI element state)

## Strategy C: Transient Builder Replacement

**When**: A `.manim` file has no screens and no registered handles.

**What happens**: The cached builder is replaced. Nothing else. The next `buildWithParameters()` call on this builder uses the new definition automatically.

```
hotReload("unitbodies.manim")
  │
  ├─ screenSourceMap → null
  ├─ hotReloadRegistry → [] (no handles)
  │
  ├─ Builder already replaced in step 6 of main flow
  ├─ IBuilderConsumer.onBuilderReplaced() already notified
  │
  └─ Notify listeners: ReloadSucceeded
```

**Use case**: Unit bodies, temporary effects, anything built fresh each frame. Game code (e.g., `DrawingResources`) implements `IBuilderConsumer` to invalidate caches when the builder changes, causing natural rebuilds on the next frame.

## Main Flow — All Strategies

```
hotReload(?resource) called
  │
  ├─ 1. FILE SELECTION
  │   ├─ If resource given: process only that file
  │   └─ Otherwise: iterate all cached builders
  │
  ├─ 2. CONTENT HASH CHECK
  │   ├─ Read file bytes via resource.entry.getBytes()  (HL only)
  │   ├─ fileChangeDetector.hasChanged(path, content)
  │   └─ Skip if unchanged (FNV-1a hash comparison)
  │
  ├─ 3. NOTIFY ReloadStarted(path, Manim)
  │
  ├─ 4. PARSE
  │   ├─ MultiAnimBuilder.load(content, loader, path)
  │   └─ On error → ReloadFailed, keep old builder, continue
  │
  ├─ 5. SIGNATURE CHECK
  │   ├─ For each live handle:
  │   │   ├─ Compare old vs new parameter definitions
  │   │   ├─ Removed param? → NeedsFullRestart
  │   │   ├─ Type changed? → NeedsFullRestart
  │   │   └─ Added param? → OK (recorded in report.paramsAdded)
  │   └─ Enum value changes within same type → OK
  │
  ├─ 6. REPLACE CACHED BUILDER
  │   ├─ builders.set(resource, newBuilder)
  │   └─ loader.replaceMultiAnim(path, newBuilder)
  │
  ├─ 7. UPDATE CONTENT HASH
  │
  ├─ 8. NOTIFY TRANSIENT CONSUMERS
  │   └─ IBuilderConsumer.onBuilderReplaced(path, newBuilder)
  │
  └─ 9. SELECT STRATEGY (A, B, or C as described above)
```

## Enabling Hot Reload

### Build Configuration

Add to your HXML:
```hxml
-D MULTIANIM_DEV
```

All hot-reload infrastructure is wrapped in `#if MULTIANIM_DEV`. In release builds: no registry, no file watching, no hashing — zero runtime overhead.

### ScreenManager Setup

`ScreenManager` handles everything automatically:
- Registers file watchers via `resource.watch()`
- Creates `ReloadableRegistry` and `FileChangeDetector`
- Passes registry to `CachingResourceLoader` for auto-registration
- Wires `onReload` callback to `hotReload()`

```haxe
// No special setup needed — just use -D MULTIANIM_DEV
final screenManager = new ScreenManager(app);
```

### Listening to Reload Events

```haxe
#if MULTIANIM_DEV
screenManager.addReloadListener((event) -> {
    switch (event) {
        case ReloadStarted(file, _):
            trace('Reloading: $file');
        case ReloadSucceeded(report):
            trace('Reload OK: ${report.file} (${report.elapsedMs}ms, ${report.rebuiltCount} rebuilt)');
        case ReloadFailed(report):
            for (err in report.errors)
                trace('ERROR ${err.file}:${err.line}:${err.col} ${err.message}');
        case ReloadNeedsRestart(report):
            trace('RESTART NEEDED: ${report.needsFullRestart}');
    }
});
#end
```

### Controlling Reloadability

```haxe
// Opt out of hot-reload for a specific result
result.reloadable = false;

// Custom callback after reload (for rewiring event handlers, etc.)
result.onReload = (result, report) -> {
    wireEvents(result);
};
```

### Transient Build Consumers

For game code that creates non-incremental builds (unit bodies, etc.):

```haxe
#if MULTIANIM_DEV
class DrawingResources implements IBuilderConsumer {
    public function onBuilderReplaced(sourcePath:String, newBuilder:MultiAnimBuilder):Void {
        if (sourcePath == "manim/unitbodies.manim") {
            unitBodiesBuilder = newBuilder;
            invalidateAllBodyHashes(); // force rebuild on next draw
        }
    }
}
// Register:
screenManager.addBuilderConsumer(drawingResources);
#end
```

### Forcing Strategy B (In-Place) for Screen Content

By default, files loaded during `screen.load()` use Strategy A (nuclear). To use Strategy B instead, load the builder BEFORE adding the screen:

```haxe
// Load builder first — currentlyLoadingScreen is null, so no screen mapping
final builder = screenManager.buildFromResourceName("ui/sidebar.manim", true);

// Then add screen — screen.load() won't call buildFromResource for this file
// (it's already cached)
screenManager.addScreen("combat", combatScreen);
```

## Key Components

### FileChangeDetector
FNV-1a hash-based content comparison. Prevents unnecessary reloads when file timestamp changes but content doesn't (e.g., editor auto-save).

### ReloadableRegistry
Tracks live incremental `BuilderResult` instances by source file path. Uses `ReloadSentinel` (invisible child on `result.object`) for automatic unregistration when the object is removed from scene.

### ReloadSentinel
An invisible `h2d.Object` child planted on each registered `BuilderResult.object`. Its `onRemove()` callback triggers `registry.unregister()`. During hot-reload, sentinels are manually removed before `SceneSwapper.replaceChildren()` to prevent stale auto-unregistration.

### SignatureChecker
Validates parameter compatibility between old and new definitions:

| Change | Result |
|--------|--------|
| Add new param with default | Compatible |
| Change default value | Compatible |
| Add enum values to existing param | Compatible |
| Remove a param | **NeedsFullRestart** |
| Rename a param | **NeedsFullRestart** (= remove + add) |
| Change param type | **NeedsFullRestart** |

### StateSnapshotter / StateRestorer
Captures and restores `BuilderResult` state across rebuilds:

| Captured | Restored Via | Notes |
|----------|-------------|-------|
| Parameter values | `beginUpdate()` + `setParameter()` + `endUpdate()` | Batch mode for efficiency |
| Slot contents | `reparent to matching new slot` | Matched by `SlotKey` |
| Slot data | `newHandle.data = saved.data` | Arbitrary payload |
| DynamicRef params | Recursive `restoreParams()` | Matched by name |

**Unsnappable types** (return null, skipped during restore):
- `ExpressionAlias` — expressions not pre-evaluated
- `TileSourceValue` — tile sources are references, not values

### SceneSwapper
Replaces children of a stable root with children from a new root:
1. Remove all old children from `oldRoot`
2. Move all new children from `newRoot` → `oldRoot`
3. Copy `filter` property if set (from `apply()` nodes)
4. Does NOT touch game-applied transforms (x, y, scale, alpha, rotation, visible)

### BuilderResult.adoptFrom()
Transfers all internal state from one result to another:
- `name`, `names`, `interactives`, `layouts`, `palettes`
- `rootSettings`, `gridCoordinateSystem`, `hexCoordinateSystem`
- `slots`, `dynamicRefs`, `incrementalContext`

The `object` field is deliberately overwritten back to the stable reference by the caller.

## Parameter Snapshot Conversion

`resolvedToDynamic()` converts internal parameter representations to values suitable for `buildWithParameters()` input:

| ResolvedIndexParameters | Output | Notes |
|------------------------|--------|-------|
| `Value(42)` | `42` | int |
| `ValueF(3.14)` | `3.14` | float |
| `StringValue("hello")` | `"hello"` | string |
| `Flag(1)` | `1` | bool (1=true, 0=false) |
| `Index(2, "active")` | `"active"` | Enum: returns **name string**, not index |
| `ArrayString([...])` | `[...]` | string array |
| `ExpressionAlias(_)` | `null` | Skipped |
| `TileSourceValue(_)` | `null` | Skipped |

## Error Handling

**Rule: On any error, keep everything as-is and report the error. Never tear down live objects on a failed reload.**

| Stage | Error | Behavior |
|-------|-------|----------|
| File read | IO error | Skip file, continue |
| Parse | Syntax error | Keep old builder, `ReloadFailed` event, retry on next save |
| Signature | Incompatible change | Keep old state, `ReloadNeedsRestart` event |
| Build | Missing sheet, bad reference | Keep old objects for this handle, log error, continue to next |
| Screen reload | Exception in `screen.load()` | Record in `failedScreens`, continue |
| onReload callback | Exception | Caught and logged, doesn't break reload |

The file watcher stays active through errors. Every save triggers a new parse attempt.

## Current Implementation Status

### Implemented (Phase 1)

- [x] `FileChangeDetector` — FNV-1a content hashing
- [x] `ReloadableRegistry` — live handle tracking with sentinel auto-unregister
- [x] Auto-register/unregister — incremental builds in dev mode
- [x] Builder replacement — cache update for transient builds
- [x] Error-safe reload — parse/build errors keep old state
- [x] `ReloadListener` notification system
- [x] `SignatureChecker` — param remove/type-change detection
- [x] `StateSnapshotter` / `StateRestorer` — params, slots, dynamicRefs
- [x] `SceneSwapper.replaceChildren()` — stable scene graph swap
- [x] `adoptFrom()` — stable `BuilderResult` references
- [x] `IBuilderConsumer` — transient build notification
- [x] Three-strategy selection (A/B/C)
- [x] `ReloadReport` with errors, timing, rebuilt list
- [x] Screen source tracking via `screenSourceMap`
- [x] `UIController.clearState()` — prevents stale hover/capture state
- [x] HotReloadTest — 25 unit tests
- [x] Dev build config — `test-hx-multianim-dev.hxml`

### Not Implemented (Phase 2 — Planned)

- [ ] `.anim` file hot-reload — re-parse `.anim` files, swap `AnimParserResult` in cache, `AnimationSM` picks up changes on next state change
- [ ] `AnimationSM` indirection handle — live instances follow pointer to latest parsed data
- [ ] `.anim` signature check — deleted/renamed animations or states → NeedsFullRestart
- [ ] Particle handling — restart looped, preserve temporary
- [ ] Path/Curve invalidation — `AnimatedPath.onPathInvalidated()` callback
- [ ] Data block change detection — `report.dataChanged` flag
- [ ] UI element state restoration — scroll positions, selected items, toggles
- [ ] `ReloadReport` enrichment — per-component change flags (pathsChanged, curvesChanged, etc.)

### Not Implemented (Phase 3 — Future)

- [ ] Nested import tracking — when `shared.manim` changes, reload everything that imports it
- [ ] Fast-path patching — position-only or property-only changes skip full rebuild
- [ ] Debug overlay — flash/highlight reloaded objects
- [ ] `@:manim` codegen hot-reload — currently requires recompile

## Testing

### Build & Run

```bash
# Compile dev mode tests
haxe test-hx-multianim-dev.hxml

# Run (test.ps1 runs both standard + dev suites)
.\test.ps1 run
```

### Existing Tests (HotReloadTest.hx)

| Category | Tests | What's Verified |
|----------|-------|----------------|
| `resolvedToDynamic` | 5 | Int, float, string, bool, enum→name conversion |
| `SignatureChecker` | 5 | Compatible, removed param, type change, added param, enum values |
| `FileChangeDetector` | 3 | Basic hash, storeInitialHash, invalidate |
| Snapshot/Restore | 5 | uint, enum, bool, float, string param preservation |
| `SceneSwapper` | 2 | Children replaced, stable root position |
| Visual content | 1 | New elements rendered, params restored |
| Slot preservation | 1 | Slot content reparented across reload |
| Unsnappable types | 3 | ExpressionAlias→null, TileSource→null, skipped in inputMap |
| Error resilience | 1 | Parse error keeps old state functional |
| Dynamic refs | 1 | Dynamic ref params captured and present in snapshot |

### Missing Tests (Needed)

**Multi-reload cycles:**
- [ ] Reload same file 3+ times — verify state preserved across each cycle
- [ ] Reload with param change → reload again reverting → verify original values

**Strategy A (Nuclear):**
- [ ] Integration test: screen loaded via `screen.load()`, file change triggers nuclear reload
- [ ] Multiple screens sharing same `.manim` file — both reloaded
- [ ] Screen with failed reload → fix file → successful reload

**Strategy B (In-Place) edge cases:**
- [ ] Multiple handles from same file — all rebuilt independently
- [ ] Handle with `reloadable = false` — skipped during reload
- [ ] Result removed from scene between reloads — sentinel auto-unregisters
- [ ] `onReload` callback — verify it fires with correct report
- [ ] `onReload` callback throws — doesn't break other handles

**Strategy C (Transient):**
- [ ] `IBuilderConsumer.onBuilderReplaced()` called with correct path and builder
- [ ] Multiple consumers — all notified

**Parameterized slots:**
- [ ] Slot with parameters (`slot(status:...)`) — params preserved across reload
- [ ] Indexed slots (`#name[$i] slot`) — all indices preserved

**Complex state:**
- [ ] Nested dynamicRefs — multi-level param preservation
- [ ] DynamicRef with slot — slot content in dynamic ref preserved
- [ ] Result with both slots and dynamicRefs — both preserved in single reload

**Signature changes:**
- [ ] Param renamed (= remove + add) — correctly detected as NeedsFullRestart
- [ ] Multiple params: one added, one removed — detected as incompatible
- [ ] Param type: enum→uint, uint→string, etc. — all detected

**Content detection:**
- [ ] Same content, different timestamp — reload skipped
- [ ] Whitespace-only change — detected as changed (content differs)
- [ ] Parse error → same broken content saved again → no re-attempt (hash unchanged)

**Error recovery:**
- [ ] Build error on one handle, success on another — partial success report
- [ ] Parse error → fix → successful reload → verify state

**Filter/Apply preservation:**
- [ ] `apply(alpha: 0.5)` on root — filter copied via SceneSwapper
- [ ] Game-applied filter on root — NOT overwritten by reload

**Integration with UI components:**
- [ ] Button with incremental mode — state preserved across reload
- [ ] Scrollable list — item content preserved (or correctly rebuilt)
- [ ] Dropdown — panel state handling during reload

## Files

| File | Role |
|------|------|
| [HotReload.hx](../src/bh/multianim/dev/HotReload.hx) | Core types, enums, all reload infrastructure classes |
| [ScreenManager.hx](../src/bh/ui/screens/ScreenManager.hx) | `hotReload()` orchestration, screen source tracking |
| [MultiAnimBuilder.hx](../src/bh/multianim/MultiAnimBuilder.hx) | `adoptFrom()`, `reloadHandle`, auto-registration |
| [ResourceLoader.hx](../src/bh/base/ResourceLoader.hx) | `replaceMultiAnim()`, registry/detector fields |
| [UIScreen.hx](../src/bh/ui/screens/UIScreen.hx) | `clear()` with `clearState()` |
| [HotReloadTest.hx](../test/src/bh/test/examples/HotReloadTest.hx) | 25 unit tests |
| [test-hx-multianim-dev.hxml](../test-hx-multianim-dev.hxml) | Dev mode build config |
