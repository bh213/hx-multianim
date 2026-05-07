# Per-frame allocation hotspots in hx-multianim

A frame-level allocation profile from a downstream project (proto-game's `ShmupCombatScreen`) showed two hot library paths that allocate every frame even when nothing changes. Together they account for ~10 allocations and ~1500 bytes per frame on an idle scene.

This is a self-contained brief for a future agent to fix. Read it, verify the current state of the code (line numbers may have drifted), implement, and run the test suite.

---

## Issue 1 — `Particles.sync` / `Particles.draw` iterate a `Map` every frame

**File:** `src/bh/base/Particles.hx`

**Symptom:** every frame `Particles.sync()` runs once and `Particles.draw()` runs twice (the body has two separate `for (g in groups)` loops). Each iteration of a `Map<String, ParticleGroup>` allocates:

- a backing array (`hl.NativeArray<Dynamic>`, ~32–336 B depending on bucket count)
- an iterator virtual struct (~40 B)
- an `hl.NativeArrayIterator_Dynamic` (~24 B)

= ~3 allocations × 3 loops = ~9 allocations / ~1.3 KB per frame on every `Particles` node in the scene, even when the particles do nothing.

**Current code shape (around line 1379, 1457, 1479, 1501 — verify with grep):**

```haxe
final groups : Map<String, ParticleGroup>;

override function sync(ctx) {
    ...
    for (g in groups) { ... }       // line ~1457 — iter alloc
}
override function draw(ctx) {
    ...
    for (g in groups) { ... }       // line ~1479 — iter alloc
    ...
    for (g in groups) { ... }       // line ~1501 — iter alloc
}
```

**Fix:** keep a parallel `Array<ParticleGroup>` for ordered iteration in the hot path; keep the `Map` for `getGroup(id)` lookup.

```haxe
final groups : Map<String, ParticleGroup>;
final groupList : Array<ParticleGroup> = [];   // NEW — iteration order
```

Update the few mutators (`addGroup`, `removeGroup`, anywhere groups is mutated — grep for `groups.set` and `groups.remove`) to keep `groupList` in sync. Then change every hot-path `for (g in groups)` to `for (g in groupList)`. The `getGroups()` public iterator at ~line 1508 should keep returning what callers expect; if callers are tolerant to either, return `groupList.iterator()` (which on HL arrays does NOT allocate per call — it's a stack-allocated iterator).

Iterating an `Array<T>` on HL is alloc-free in the steady state — the compiler emits a direct length-indexed loop.

**Acceptance:**
- `for ... in groups` no longer appears in `Particles.hx` (the Map is only touched on add/remove/lookup).
- All Particles tests still pass: `cd hx-multianim && haxe test.hxml && hl build/test.hl` (or whatever the standard test invocation is — check `CLAUDE.md` / `test.hxml`).
- Re-run a downstream alloc capture on an idle Particles-heavy scene; the StringMap iterator allocations from `bh.base.Particles.sync/draw` should be gone.

---

## Issue 2 — `UIScreenBase.getElements` allocates a defensive copy every frame

**File:** `src/bh/ui/screens/UIScreen.hx` (function `getElements`, around line 298)

**Symptom:** `UIDefaultController.update` (in `src/bh/ui/controllers/UIDefaultController.hx`, around line 236) calls `integration.getElements(SETReceiveUpdates)` once per frame, which does:

```haxe
public function getElements(type:SubElementsType):Array<UIElement> {
    var retVal = elements.copy();                               // 208 B alloc/frame
    for (provider in subElementProviders) {
        retVal = retVal.concat(provider.getSubElements(type));  // more allocs if any provider exists
    }
    return retVal;
}
```

This is a defensive snapshot. Most callers just iterate it and discard.

**Fix options (in order of preference):**

1. **Add a callback variant** that doesn't allocate, and switch `UIDefaultController.update` to use it:

   ```haxe
   public function forEachElement(type:SubElementsType, fn:UIElement->Void):Void {
       for (e in elements) fn(e);
       for (provider in subElementProviders) {
           // Provider may still allocate internally; if so, fix that too,
           // or add a forEachSubElement to ISubElementProvider.
           for (e in provider.getSubElements(type)) fn(e);
       }
   }
   ```

   Then `UIDefaultController.update`:

   ```haxe
   integration.forEachElement(SETReceiveUpdates, e -> redrawAndUpdate(e, dt));
   ```

   Caveat: a closure literal can itself allocate per call on HL. Verify with a profile capture; if it does, hoist the closure to a stored field on the controller (or use a non-capturing static + `this` parameter).

2. **Reuse a scratch buffer** if mutating the API is too disruptive: keep an `Array<UIElement>` field on the screen, clear it, push current elements + sub-elements into it, return it. Document that the returned array is invalidated on next call. Lower-impact change but leaks the rule to all callers.

3. Leave option (1) but additionally fix `ISubElementProvider` to expose a `forEachSubElement` so providers don't internally allocate either.

Prefer option (1) plus (3) for a clean solution.

**Acceptance:**
- `ArrayObj.copy` no longer appears in the steady-state `UIDefaultController.update` allocation path (re-run the downstream alloc capture).
- All UI tests still pass.
- The old `getElements` may stay for external callers; just don't use it from the hot path.

---

## How to verify end-to-end

The downstream project that surfaced this is `proto-game`. After your fix:

1. Build hx-multianim's tests and run them.
2. In `proto-game` (sibling repo), run `haxe hl.hxml`, launch the game, navigate to `ShmupCombatScreen` (the menu has a button), open the F11 console, run `/alloc frame`, then press F2 to capture one frame. The output goes to `proto-game/build/alloc-frame.txt`.
3. Confirm:
   - No `bh.base.Particles.sync/draw` entries remain in the trace.
   - No `bh.ui.screens.UIScreenBase.getElements` / `ArrayObj.copy` entry from `UIDefaultController.update` remains.
4. Total allocs for an idle frame should drop from ~92 to ~70 or below.

---

## Out of scope (for reference)

The proto-game side has already been fixed: change-detection in `ShmupCombatScreen.refreshCounts` and `drawHpShieldBars` (don't update text/tiles when values haven't changed), and gating `hl.Gc.stats()` on the perf overlay being visible in `Main.update`.
