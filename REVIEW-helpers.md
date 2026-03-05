# Helper Library Review Report

Review of UI helper classes: drag-drop, card hand, rich interactive, tooltip, panel, grid, floating text, and their interop.

---

## 1. BUGS

### 1.1 UIRichInteractiveHelper: setDisabled(false) loses hover state
**File:** `src/bh/ui/UIRichInteractiveHelper.hx:104-106`
**Severity:** Medium

When `setDisabled(id, false)` is called, the state unconditionally resets to `Normal`, even if the mouse is currently over the interactive. Since the OS-level cursor hasn't moved, no new `UIEntering` event fires, leaving the interactive visually in `Normal` while the user sees the cursor over it.

```haxe
// Line 104-106: always resets to Normal
} else {
    binding.currentState = Normal;
    binding.result.setParameter(binding.stateParam, "normal");
}
```

**Fix:** Check `wrapper.hovered` before deciding the state:
```haxe
final wrapper = screen.getInteractive(interactiveId);
final isHovered = wrapper != null && wrapper.hovered;
binding.currentState = isHovered ? Hover : Normal;
binding.result.setParameter(binding.stateParam, isHovered ? "hover" : "normal");
```

### 1.2 UITooltipHelper: rebuild() loses params on second call
**File:** `src/bh/ui/UITooltipHelper.hx:194-232`
**Severity:** Medium

`rebuild()` without params uses `activeParams` as fallback (line 199), but `showTooltip` stores the raw `params` argument (which is `null`) into `activeParams` (line 232). Second `rebuild()` call with no params finds `activeParams == null`.

```haxe
// Line 199: buildParams = params ?? activeParams; // correct fallback
// ...
// Line 232: activeParams = params; // BUG: overwrites with null
```

**Fix:** Line 232 should store the resolved params: `activeParams = buildParams ?? params;` or pass `buildParams` through.

### 1.3 UITooltipHelper: startHover ignores changed buildName for same interactive
**File:** `src/bh/ui/UITooltipHelper.hx:75-87`
**Severity:** Low

If `startHover("btn1", "basicTooltip")` is called, then `startHover("btn1", "advancedTooltip")` while the tooltip is already showing, the second call returns early at line 77 (`activeTooltipId == interactiveId`). The tooltip stays as `basicTooltip`.

**Fix:** Also compare `buildName` before returning early:
```haxe
if (activeTooltipId == interactiveId && activeBuildName == buildName)
    return;
```

### 1.4 UICardHandHelper: setCardEnabled breaks state for animating cards
**File:** `src/bh/ui/UICardHandHelper.hx:366-375`
**Severity:** Medium

Comment says "enabling is deferred to onComplete" for animating cards, but code sets `InHand` immediately:
```haxe
if (entry.state == Animating) {
    if (!enabled)
        entry.state = Disabled;  // only disable overrides
} else {
    entry.state = if (enabled) InHand else Disabled;  // re-enable goes here even during animation
}
```
If a card is disabled while animating, then re-enabled before animation completes, it becomes `InHand` prematurely — the animation's `onComplete` callback checks `if (entry.state == Animating)` and won't reset it properly.

### 1.5 UICardHandHelper: TargetCard enum variant is dead code
**File:** `src/bh/ui/UICardHandTypes.hx:58`
**Severity:** Low (API consistency)

`TargetingResult` has a `TargetCard(targetCardId)` variant, but `CardCombined` is a separate event. When card-to-card combining occurs, only `CardCombined` is emitted — `CardPlayed` with `TargetCard` is never used. Dead variant.

### 1.6 UICardHandHelper: concurrent multi-draw produces stale layout positions
**File:** `src/bh/ui/UICardHandHelper.hx:282-306`
**Severity:** Medium

`drawCard()` computes layout at line 282 and captures `targetIdx` at line 283. If another `drawCard()` is called before the first animation completes, the second call's `computeLayout` produces different positions (array now has the first card). Meanwhile, `rearrangeCards` from draw #1 may still be animating cards toward positions that are no longer correct. Cards can briefly animate to wrong positions during rapid multi-draw sequences.

### 1.7 UIMultiAnimDraggable: clear() nullifies target but doesn't remove root
**File:** `src/bh/ui/UIMultiAnimDraggable.hx:353-372`
**Severity:** Low

`clear()` removes and nullifies `target` (lines 368-371), but `root` remains in the scene graph as an empty wrapper. The draggable is left in a half-cleaned state — `root` is alive but `target` is null, which could cause NPE if `update()` or `onEvent()` is called after `clear()`.

### 1.8 UICardHandHelper: dispose() doesn't cancel active animations
**File:** `src/bh/ui/UICardHandHelper.hx:534-540`
**Severity:** Low

`dispose()` calls `clearHand()` which sets `activeAnimations = []`, dropping animation references without calling any cleanup. If animated path objects hold Heaps resources, they leak. The `onComplete` callbacks captured in `ActiveAnimation` may also reference disposed card entries.

### 1.9 UIMultiAnimGrid: CellCardPlayed event defined but never emitted
**File:** `src/bh/ui/UIMultiAnimGridTypes.hx:46`, `src/bh/ui/UIMultiAnimGrid.hx:803-844`
**Severity:** High

`GridEvent.CellCardPlayed(cell, cardId)` is defined in the enum but the grid never emits it. `createCardTargetsForBinding()` (line 803) wires highlight callbacks but has no mechanism to detect when a card is actually played on a target. The card hand emits `CardPlayed` events via its own callback, but the grid never listens for or converts them. Game code relying on `CellCardPlayed` in `onGridEvent` will never receive it.

### 1.10 UIMultiAnimGrid: multiple card hand registrations corrupt shared target state
**File:** `src/bh/ui/UIMultiAnimGrid.hx:104-105, 847-854`
**Severity:** High

`cardTargetInteractives` and `cardTargetWrappers` are single shared maps (lines 104-105) across all registered card hands. `clearCardTargetsForBinding()` (line 847) iterates the **entire** shared map and unregisters all targets from the specific binding's card hand — then **clears the entire map** (lines 852-853). If two card hands are registered, clearing one wipes targets belonging to the other.

### 1.11 UIMultiAnimGrid: rebuildCell doesn't refresh drag zones or card targets
**File:** `src/bh/ui/UIMultiAnimGrid.hx:302-317`
**Severity:** Medium

`rebuildCell()` replaces the cell's scene object but does NOT call `refreshAllDraggableZones()` or `refreshAllCardTargets()`. Compare with `addCell()` (line 171-172) and `removeCell()` (line 189-190) which both refresh. Drop zones and card targets still reference the old cell object after rebuild.

### 1.12 UIMultiAnimGrid: hitTestRect uses wrong stride for Y gap check
**File:** `src/bh/ui/UIMultiAnimGrid.hx:648`
**Severity:** High

```haxe
final stride = rectCellW + rectGap;    // line 637
final strideY = rectCellH + rectGap;   // line 638
// ...
final cellLocalY = localY - row * stride;  // line 648 — BUG: uses stride, not strideY
```
Line 648 calculates the Y offset within a cell using `stride` (which is `rectCellW + rectGap`) instead of `strideY` (`rectCellH + rectGap`). For non-square cells (width != height), this produces wrong gap detection on the Y axis — clicks in valid cell area can be rejected, or clicks in gap area can be accepted.

**Fix:** Change line 648 to `final cellLocalY = localY - row * strideY;`

### 1.13 UIMultiAnimGrid: hitTestRect rejects negative coordinates
**File:** `src/bh/ui/UIMultiAnimGrid.hx:640-641`
**Severity:** Medium

```haxe
if (localX < 0 || localY < 0)
    return null;
```
Cells can be added at negative coordinates (e.g., `addCell(-1, -2)`), but `hitTestRect` early-returns `null` for any negative local coords. Those cells are invisible to `cellAtPoint()`, `onMouseMove()`, and `onMouseClick()`.

### 1.14 UIMultiAnimGrid: acceptDrops allows duplicate registration
**File:** `src/bh/ui/UIMultiAnimGrid.hx:424-432`
**Severity:** Low

Calling `acceptDrops(draggable)` twice pushes the same draggable twice into `registeredDraggables`. Creates duplicate drop zones and overwrites the draggable's highlight callbacks via chaining (line 712-756).

### 1.15 UIMultiAnimDraggable: swap mode doesn't validate sourceSlot state
**File:** `src/bh/ui/UIMultiAnimDraggable.hx:480-494`
**Severity:** Medium

In swap mode, after the snap animation completes, the callback (lines 482-494) reads `sourceSlot.data` and `zone.slot.getContent()`. But `sourceSlot` is only cleared at line 494. If the slot is manipulated externally before the animation completes (e.g., another drag starts from the same slot), the swap operates on stale data.

---

## 2. CODE DUPLICATION

### 2.1 positionTooltip / positionPanel — identical positioning logic
**Files:**
- `src/bh/ui/UITooltipHelper.hx:246-264` (`positionTooltip`)
- `src/bh/ui/UIPanelHelper.hx:376-394` (`positionPanel`)

These are line-for-line identical except variable names. Should be extracted to a shared utility function.

### 2.2 Fade-in/fade-out pattern repeated 4 times
**Files:**
- `UITooltipHelper.hx:120-131` (hide fade-out), `221-227` (show fade-in)
- `UIPanelHelper.hx:145-155` (close fade-out), `115-121` (open fade-in), `222-224` (named fade-in), `246-251` (named fade-out)

Each helper independently manages fade tween creation, cancellation, and cleanup. A small `FadeHelper` could encapsulate this pattern.

### 2.3 OBB hit-testing duplicated in CardHandHelper
**File:** `src/bh/ui/UICardHandHelper.hx:1013-1025` and `1050-1062`

`getCardAtBasePosition` and `getCardAtPosition` both compute OBB intersection with nearly identical rotation math. Only the selection strategy differs (nearest-center vs first-hit).

### 2.4 Config null-check boilerplate in CardHandHelper constructor
**File:** `src/bh/ui/UICardHandHelper.hx:203-238`

36 lines of repetitive `config != null && config.X != null ? config.X : default`. A helper function `configOr(config?.field, default)` or using Haxe's `??` operator would reduce this significantly.

### 2.5 Target highlight state update duplicated in UICardHandTargeting
**File:** `src/bh/ui/UICardHandTargeting.hx:146-157` and `196-206`

`updateHighlight` and `updateTargetingLine` both contain identical highlight state transition logic (unhighlight old, highlight new). Should be extracted to a private method.

---

## 3. INTEROP ISSUES

### 3.1 UIRichInteractiveHelper + UICardHandHelper: state ownership conflict
**Files:** `UIRichInteractiveHelper.hx`, `UICardHandHelper.hx:729`

CardHandHelper calls `interactiveHelper.resetState()` (line 729) and `setHoverState()` (line 702) to bypass the normal event-driven state machine. This works but creates a fragile coupling — the rich interactive helper doesn't know its state is being externally manipulated. If a game also registers the same interactives with its own `UIRichInteractiveHelper` instance, both would fight over state.

**Mitigation:** CardHandHelper creates its own private `interactiveHelper` instance (line 200), so no external conflict. The design is intentional but undocumented.

### 3.2 Grid + CardHand: card target wrappers use synthetic interactives
**File:** `src/bh/ui/UIMultiAnimGrid.hx:487-504`

Grid creates synthetic `UIInteractiveWrapper` instances for card targeting. These wrappers reference `MAObject` nodes that live inside the grid's scene graph. If the grid is repositioned or cells are rebuilt, the wrappers may reference stale objects. The `refreshAllCardTargets()` method handles this, but there's a window between cell rebuild and refresh where stale wrappers exist.

### 3.3 UIPanelHelper close event fires during fade-out
**File:** `src/bh/ui/UIPanelHelper.hx:160-161`

`EVENT_PANEL_CLOSE` fires immediately on `close()`, before fade-out completes. This is documented behavior, but interactives are also unregistered immediately (line 142). If the game's `onScreenEvent` handler for `EVENT_PANEL_CLOSE` tries to access the panel's interactives, they're already gone.

### 3.4 UIMultiAnimDraggable: no dispose/cleanup method
**File:** `src/bh/ui/UIMultiAnimDraggable.hx`

`UIMultiAnimDraggable` has `clear()` which cleans state but doesn't unregister from the screen's element list or remove drop zones from other draggables. Compare with `UICardHandHelper.dispose()` which properly cleans up. Games must manually remove drop zones and screen elements.

---

## 4. INCONSISTENCIES

### 4.1 Dispose/cleanup pattern inconsistency
| Helper | Has dispose? | Cleanup method |
|--------|-------------|---------------|
| UICardHandHelper | `dispose()` | Full cleanup |
| UIMultiAnimGrid | `dispose()` | Full cleanup |
| UIMultiAnimDraggable | `clear()` | Partial cleanup (no screen/zone removal) |
| UIRichInteractiveHelper | `unbindAll()` | Bindings only |
| UITooltipHelper | None | No cleanup method |
| UIPanelHelper | None | No cleanup method |
| FloatingTextHelper | `clear()` | Instances only |

Tooltip and Panel helpers have no way to clean up override maps (`delayOverrides`, `positionOverrides`, `offsetOverrides`). These grow unbounded in long-lived screens.

### 4.2 Event emission pattern inconsistency
| Helper | Event pattern |
|--------|--------------|
| UICardHandHelper | Callback: `onCardEvent:(CardHandEvent)->Void` |
| UIMultiAnimGrid | Callback: `onGridEvent:(GridEvent)->Void` |
| UIPanelHelper | Screen event: `UICustomEvent(EVENT_PANEL_CLOSE, id)` |
| UIMultiAnimDraggable | Screen event: `UICustomEvent("dragStart"/"dragDrop"/"dragCancel", data)` + callback delegates |
| UITooltipHelper | None — no events emitted |

Three different patterns: typed enum callbacks, UICustomEvent strings, and delegate functions. A unified approach would reduce learning curve.

### 4.3 Builder parameter passing inconsistency
| Helper | How params are passed to buildWithParameters |
|--------|---------------------------------------------|
| UITooltipHelper | `params ?? []` (empty array fallback) |
| UIPanelHelper | `params ?? []` (empty array fallback) |
| UICardHandHelper | `params` (Map, copied from descriptor) |
| UIMultiAnimGrid | `params` (Map, built internally) |

The `?? []` pattern in tooltip/panel is suspicious — `buildWithParameters` takes a `Map<String, Dynamic>`, and `[]` creates an empty array, not a map. In Haxe, `[]` for maps creates an empty `Map` via array literal syntax, so this works, but it's confusing.

### 4.4 Named panel fade-in tween not tracked
**File:** `src/bh/ui/UIPanelHelper.hx:224`

Single-panel API tracks `activeFadeInTween` (line 117) for cancellation, but named panel fade-in tween is fire-and-forget (line 224). If `closeNamed()` is called during fade-in, the tween continues running on a panel that's being removed, potentially causing visual artifacts.

### 4.5 FloatingTextHelper: color application only for h2d.Text
**File:** `src/bh/ui/FloatingTextHelper.hx:120-124`

`spawnObject()` allows spawning arbitrary `h2d.Object`, but color from `AnimatedPathState.color` is only applied to `h2d.Text` instances. No way to apply color curves to custom objects.

### 4.6 beginUpdate/endUpdate wrapping inconsistent across UI components
**Files:** Multiple UI components

Some components batch multi-parameter changes with `beginUpdate()`/`endUpdate()`, others don't:

| Component | Method | Uses batching? |
|-----------|--------|---------------|
| UIMultiAnimButton | `set_disabled` | Yes |
| UIMultiAnimCheckbox | `set_disabled` | No |
| UIMultiAnimCheckbox | `set_selected` | No |
| UIMultiAnimTextInput | `set_disabled` | Yes |
| UIMultiAnimTabs | `set_selected` | Only when `value==true` |
| UIMultiAnimTabs | `set_disabled` | No |

The tabs `set_selected` is particularly odd — it wraps in `beginUpdate/endUpdate` only when selecting (setting `checked` + `status`), but not when deselecting (only `checked`). This is technically correct since deselection sets one param, but the asymmetric pattern is confusing.

### 4.7 Slider/ProgressBar clear() nullifies builder, preventing reuse
**Files:**
- `src/bh/ui/UIMultiAnimSlider.hx` (`clear()`)
- `src/bh/ui/UIMultiAnimProgressBar.hx` (`clear()`)

These components nullify their `builder` reference in `clear()`, making them permanently unusable after cleanup. Other components' `clear()` methods either do nothing or just reset state without destroying the ability to rebuild.

### 4.8 Cursor implementation duplicated across all interactive components
**Files:** Button, Checkbox, TextInput, Slider, Dropdown, ScrollableList, Tabs

All implement `UIElementCursor` with identical logic: return `Default` if disabled, else `defaultInteractiveCursor()`. This is consistent (good) but could be extracted to a shared base or mixin to avoid the duplication.

---

## 5. MISSING FEATURES / IMPROVEMENTS

### 5.1 UIRichInteractiveHelper: no state change callbacks
No way to observe state transitions (Normal→Hover→Pressed). Games must manually wire tooltip/panel show/hide in `onScreenEvent`. A callback like `onStateChange:(id, oldState, newState)->Void` would reduce boilerplate.

### 5.2 UITooltipHelper/UIPanelHelper: no reposition on layout change
Tooltips and panels are positioned once at show time. If the anchor interactive moves (scroll, resize, animation), the tooltip/panel stays at the old position. A `reposition()` method or automatic tracking would improve UX.

### 5.3 UICardHandHelper: no way to reorder cards
`setHand()` rebuilds everything. A `reorderCards(newOrder:Array<CardId>)` method that animates cards to new positions without rebuilding visuals would be useful for sorting.

### 5.4 UIMultiAnimDraggable: no multi-touch support
`draggingButton` is a single int. On touch devices, simultaneous drags would conflict. The helper assumes single-pointer input.

### 5.5 UICardHandTargeting: pre-builds 60 segment objects
**File:** `src/bh/ui/UICardHandTargeting.hx:67-76`

`MAX_SEGMENTS = 30`, and each segment has valid+invalid variants = 60 pre-built objects. For short arrows most are wasted. A lazy-growth pool (build on demand, keep for reuse) would reduce initial cost.

---

## 6. SUMMARY TABLE

| # | Category | Severity | Component | Description |
|---|----------|----------|-----------|-------------|
| 1.1 | Bug | Medium | RichInteractive | setDisabled(false) loses hover |
| 1.2 | Bug | Medium | Tooltip | rebuild() loses params |
| 1.3 | Bug | Low | Tooltip | startHover ignores changed buildName |
| 1.4 | Bug | Medium | CardHand | setCardEnabled breaks animating cards |
| 1.5 | Bug | Low | CardHand | TargetCard enum variant dead code |
| 1.6 | Bug | Medium | CardHand | Concurrent multi-draw stale positions |
| 1.7 | Bug | Low | Draggable | clear() partial cleanup |
| 1.8 | Bug | Low | CardHand | dispose() doesn't cancel animations |
| 1.9 | Bug | **High** | Grid | CellCardPlayed event never emitted |
| 1.10 | Bug | **High** | Grid | Multiple card hand registrations corrupt targets |
| 1.11 | Bug | Medium | Grid | rebuildCell doesn't refresh zones/targets |
| 1.12 | Bug | **High** | Grid | hitTestRect Y gap uses wrong stride variable |
| 1.13 | Bug | Medium | Grid | hitTestRect rejects negative coordinates |
| 1.14 | Bug | Low | Grid | acceptDrops allows duplicate registration |
| 1.15 | Bug | Medium | Draggable | swap mode doesn't validate sourceSlot state |
| 2.1 | Duplication | Medium | Tooltip+Panel | Identical positioning logic |
| 2.2 | Duplication | Low | Tooltip+Panel | Fade pattern repeated |
| 2.3 | Duplication | Low | CardHand | OBB hit-test duplicated |
| 2.4 | Duplication | Low | CardHand | Config null-check boilerplate |
| 2.5 | Duplication | Low | Targeting | Highlight state update duplicated |
| 3.1 | Interop | Low | RichInteractive+CardHand | State ownership undocumented |
| 3.2 | Interop | Low | Grid+CardHand | Stale wrapper window |
| 3.3 | Interop | Low | Panel | Close event before fade completes |
| 3.4 | Interop | Low | Draggable | No screen cleanup on dispose |
| 4.1 | Inconsistency | Medium | All | Dispose/cleanup patterns differ |
| 4.2 | Inconsistency | Low | All | Event emission patterns differ |
| 4.3 | Inconsistency | Low | Tooltip+Panel | Param passing to builder |
| 4.4 | Inconsistency | Low | Panel | Named panel fade not tracked |
| 4.5 | Inconsistency | Low | FloatingText | Color only for h2d.Text |
| 4.6 | Inconsistency | Low | UI Components | beginUpdate/endUpdate wrapping inconsistent |
| 4.7 | Inconsistency | Low | Slider+ProgressBar | clear() nullifies builder, prevents reuse |
| 4.8 | Duplication | Low | UI Components | Cursor implementation duplicated in all components |
| 5.1 | Missing | Low | RichInteractive | No state change callbacks |
| 5.2 | Missing | Low | Tooltip+Panel | No reposition API |
| 5.3 | Missing | Low | CardHand | No card reorder API |
