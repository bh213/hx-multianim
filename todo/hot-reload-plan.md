# Hot Reload Plan — Incremental .manim Reload Without Breaking Game State

Goal: When a `.manim` file changes on disk, update the visual output in-place without destroying game logic state. Preserve slot contents, parameter values, UI element state, and h2d scene graph positions where possible. Only force full restart when structural changes make it unavoidable.

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
- Particles restart

## Classification: What Can Be Hot-Reloaded

### Safe to hot-reload (no structural change)
- **Position changes** — element `x,y` / grid pos / hex pos
- **Bitmap source changes** — swap tile on existing h2d.Bitmap
- **Text content/color changes** — update existing h2d.Text
- **NinePatch size changes** — update width/height on existing ScaleGrid
- **Graphics/Pixels content** — clear + redraw on existing h2d.Graphics
- **Filter changes** — swap filter on existing h2d.Object
- **Alpha/scale changes** — update property on existing h2d.Object
- **Color/tint changes** — update on existing object
- **Conditional value changes** — re-evaluate @if/@else visibility (already works in incremental mode)
- **Expression value changes** — e.g. change `$width * 2 + 10` to `$width * 3`
- **Particle property changes** — speed, gravity, colors, etc (just update ParticleGroup fields)
- **Path/curve control point changes** — update path data, existing AnimatedPath picks it up

### Requires element rebuild (but not full restart)
- **Element type change** — bitmap → text, text → ninepatch (must destroy + recreate that subtree)
- **Adding/removing children** in a container (layers, flow)
- **Repeatable iterator change** — count change means add/remove iterations
- **New staticRef/dynamicRef** — need to build new sub-programmable
- **Slot parameter signature change** — new params need new IncrementalUpdateContext

### Requires full restart
- **Programmable parameter signature change** — adding/removing/renaming params in `programmable(...)` header. Codegen factories are compile-time, can't adapt. Runtime builder could potentially handle this but game code passing params won't know about new params.
- **New imports** — `import "file" as "name"` adds new dependency
- **Sheet name changes** — cached sheet references won't match
- **Structural type changes** — programmable → data, particles → animatedPath

## Option A: AST Diff + Targeted Patch (Recommended)

Diff old and new AST node-by-node. For each changed node, apply the minimal update to the existing h2d object tree.

### Architecture

```
File changed
  → Re-parse .manim to new AST
  → Diff old AST vs new AST per named node (programmable, particles, etc.)
  → For each live BuilderResult:
      → Walk the matched old/new node children in parallel
      → Classify each difference (position, property, structural)
      → Apply safe patches directly to h2d objects
      → For structural changes: rebuild that subtree, splice into parent
      → If signature changed: flag for full restart
  → Return { patched: [...], needsRestart: [...] }
```

### Key Components

**1. ASTDiffer** — compares two Node trees

```
diff(oldNode, newNode) → Array<NodePatch>

enum NodePatch {
    PositionChanged(object, oldPos, newPos);
    PropertyChanged(object, field, oldVal, newVal);  // alpha, scale, filter
    ContentChanged(object, oldContent, newContent);   // bitmap tile, text, graphics
    ChildAdded(parent, index, newNode);
    ChildRemoved(parent, index, oldNode);
    ChildReordered(parent, oldIndex, newIndex);
    SubtreeReplaced(parent, index, oldNode, newNode); // type mismatch
    SignatureChanged(name);                            // → full restart needed
}
```

Diffing strategy: Match children by stable identity. Options:
- **Named elements** (`#name`) — match by name
- **Positional** — match by index (fragile if elements inserted)
- **Content hash** — match by node type + key properties

Recommendation: Use `#name` when available, fall back to index within same-type runs.

**2. PatchApplier** — applies NodePatch to live h2d objects

Needs a **node → h2d.Object mapping** that persists after build. Currently the builder creates objects but doesn't maintain a map back to AST nodes. The `IncrementalUpdateContext` tracks some (conditionals, expressions) but not all.

**New requirement:** During build, maintain a `Map<Node, h2d.Object>` (or use node identity/unique ID). Store this in BuilderResult.

**3. BuilderResult.hotReload(newAST)**

Public API for consumers:

```haxe
class BuilderResult {
    // existing
    public function setParameter(name, value):Void;

    // new
    public function hotReload(newParsed:MultiAnimResult):HotReloadResult;
}

enum HotReloadResult {
    Success;                        // all changes applied in-place
    PartialSuccess(rebuilt:Array<String>);  // some subtrees rebuilt
    NeedsFullRestart(reason:String);       // signature/structural change
}
```

### Pros
- Maximum preservation of state
- Surgical updates — only changed objects touched
- Reuses existing incremental infrastructure (conditionals, expressions already tracked)
- Consumers get feedback about what changed

### Cons
- Complex AST diffing logic
- Needs persistent node→object mapping (new bookkeeping during build)
- Edge cases: what about repeatable iterations that changed count? Flows that need re-layout?
- Significant implementation effort

### Estimated effort: Large (3-4 weeks of focused work)

---

## Option B: Rebuild-in-Place with State Snapshot/Restore (Simpler)

Don't diff ASTs. Instead: snapshot the runtime state before reload, do a full rebuild, then restore state to the new objects.

### Architecture

```
File changed
  → Snapshot all live BuilderResults:
      → Parameter values (from IncrementalUpdateContext.indexedParams)
      → Slot contents (SlotHandle → content object + data)
      → Named element positions (for game-moved objects)
      → UI element state (scroll pos, selected index, toggle state)
      → Animation frame positions
  → Re-parse + full rebuild (like today)
  → Restore snapshot to new BuilderResults:
      → Re-apply parameters via setParameter()
      → Re-attach slot contents to new SlotHandles
      → Restore UI state
      → Seek animations to saved frame
  → If signature changed: skip restore, return NeedsFullRestart
```

### Key Components

**1. BuilderStateSnapshot**

```haxe
typedef BuilderStateSnapshot = {
    parameters: Map<String, Dynamic>,          // current param values
    slotContents: Map<String, {content:h2d.Object, data:Dynamic}>,
    uiState: Map<String, Dynamic>,             // scroll pos, selection, etc.
    dynamicRefParams: Map<String, Map<String, Dynamic>>,
}
```

**2. ScreenManager.hotReload()** — replaces current reload()

```
hotReload(resource) {
    // 1. Snapshot
    var snapshots = new Map<String, BuilderStateSnapshot>();
    for (screen in screens) {
        snapshots.set(screen.name, screen.captureState());
    }

    // 2. Check signature compatibility
    var newParsed = MultiAnimParser.parseFile(resource);
    if (!isSignatureCompatible(oldParsed, newParsed))
        return NeedsFullRestart;

    // 3. Rebuild
    clearBuilders();
    rebuildAll();

    // 4. Restore
    for (screen in screens) {
        screen.restoreState(snapshots.get(screen.name));
    }
}
```

**3. Screen interface additions**

```haxe
interface IReloadableScreen {
    function captureState():BuilderStateSnapshot;
    function restoreState(snapshot:BuilderStateSnapshot):Void;
}
```

### Pros
- Much simpler than AST diffing
- Full rebuild means no stale state bugs
- Slot contents are h2d.Objects that can be reparented (just `addChild` to new slot container)
- Parameter restore via existing `setParameter()` API
- Game screens opt in by implementing `IReloadableScreen`

### Cons
- Still does full rebuild (slower than Option A for large scenes)
- Brief visual flash as objects are destroyed + recreated
- Some state hard to capture (custom h2d object modifications, runtime-added children)
- Game logic references to old h2d objects still break (unless using named lookups)
- Animation state harder to restore perfectly (frame-perfect seek)

### Estimated effort: Medium (1-2 weeks)

---

## Option C: Proxy Objects + Indirection Layer (Most Transparent)

Wrap all h2d objects in proxy containers. Game code references the proxy, not the inner object. On reload, swap the inner object; proxy reference stays valid.

### Architecture

```haxe
class MAnimProxy extends h2d.Object {
    var inner:h2d.Object;
    public function swapInner(newInner:h2d.Object) {
        removeChild(inner);
        inner = newInner;
        addChild(inner);
    }
}
```

Builder creates proxies around every element. Game code gets proxy references. On reload, build new objects, swap them into existing proxies.

### Pros
- Game code references never go stale
- No state capture/restore needed for position (proxy stays where game put it)
- Clean separation: library handles swap, game doesn't need to know

### Cons
- Extra h2d.Object layer everywhere (performance cost — Heaps walks object tree each frame)
- Named lookups return proxy not real object — type casting gets awkward
- Doesn't help with slot contents or UI state (still need snapshot for those)
- Filters, alpha, scale applied to proxy vs inner gets confusing
- Deep nesting (proxy → inner → children) complicates scene graph debugging

### Estimated effort: Medium, but ongoing maintenance cost

---

## Recommendation

**Start with Option B (Snapshot/Restore)** as the pragmatic first step. It's simpler, delivers most of the value, and the snapshot infrastructure is useful even if you later add AST diffing.

Then **incrementally add Option A's diffing** for the hot path: position changes, text changes, and bitmap swaps — the three most common tweaks during development. This gives instant visual feedback for the 80% case without the full rebuild flash.

Skip Option C — the proxy layer adds permanent runtime cost for a dev-time-only feature.

### Phased Implementation

**Phase 1: Smart state preservation (Option B)**
1. Add `captureState()` / `restoreState()` to BuilderResult
2. Snapshot: parameter values, slot contents (reparent h2d.Objects), UI element state
3. ScreenManager.hotReload() — snapshot → rebuild → restore
4. Signature compatibility check (compare programmable param lists)
5. Return `NeedsFullRestart` if params changed, otherwise restore silently

**Phase 2: Fast-path patching for common changes**
1. Store node→object mapping during build (in BuilderResult)
2. On reload: quick-compare positions, bitmap sources, text content
3. If only these changed: patch in-place, skip full rebuild
4. Falls back to Phase 1 (snapshot/restore) for structural changes

**Phase 3: Granular diffing (if needed)**
1. Full AST diff for precise subtree updates
2. Handle child add/remove without full rebuild
3. Incremental flow re-layout

## API Surface for Game Code

### Minimal (Phase 1)
```haxe
// ScreenManager
function hotReload(?resource):{ success:Bool, ?needsRestart:Bool, ?error:String };

// Screen interface (opt-in)
interface IHotReloadable {
    function captureState():Dynamic;
    function restoreState(state:Dynamic):Void;
}
```

### Extended (Phase 2+)
```haxe
// BuilderResult
function hotPatch(newAST:MultiAnimResult):HotReloadResult;

// Callback for game code to react
var onHotReload:Null<(result:HotReloadResult)->Void>;
```

## What NOT to Do

- **Don't try to hot-reload codegen factories** — `@:manim` generates Haxe code at compile time. Changing `.manim` can't update compiled Haxe classes. Runtime builder path must be used for hot-reload. Document this clearly.
- **Don't preserve broken references** — if a named element was removed in the new .manim, don't silently return null from `getUpdatable()`. Throw or log clearly.
- **Don't auto-reload imported files** — if `import "other.manim"` changed, that's a separate file watch. Handle it, but don't cascade automatically (risk of infinite loops with circular imports).
- **Don't cache old AST across reloads** — always re-parse from disk. Parser is fast enough, and caching adds invalidation complexity.

## Open Questions

1. **StateAnim (.anim files):** These have their own state machines. Should hot-reload preserve animation state (current frame, current state)? Likely yes for position tweaking, but state machine transitions might need reset.

2. **Particles:** Currently stateless from the .manim perspective (runtime state is in Particles.hx). Hot-reload should re-read particle properties but keep existing particles alive. New particles use new properties.

3. **Codegen path:** Games using `@:manim` macro get compile-time factories. These can't hot-reload by definition (need recompile). Should the library provide a `devMode` flag that switches codegen factories to use runtime builder instead? This would enable hot-reload in dev but keep codegen performance in release.

4. **Multiple BuilderResults from same .manim:** If the same programmable is built multiple times (e.g., list items), each gets its own BuilderResult. All need updating. The ScreenManager.builders map only tracks one builder per resource, not per build-instance. Need a registry of live BuilderResults per source file.
