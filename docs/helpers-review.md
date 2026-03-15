# Helper Library Review Report

Review of UI helper classes: drag-drop, card hand, rich interactive, tooltip, panel, grid, floating text, and their interop.

## Instructions for Claude

Pick a few unfixed issues from the BUGS section (prioritize High, then Medium severity).
For each issue:
1. Read the relevant source file(s) and verify the bug is real (not a false positive)
2. Create a failing unit test that demonstrates the bug
3. Run `powershell -ExecutionPolicy Bypass -File test.ps1 run` to confirm the test fails
4. Fix the bug in the source code
5. Run tests again to confirm the fix passes (and no regressions)
6. Mark the issue as FIXED in this file (use ~~strikethrough~~ on title + severity, add brief fix description)
7. Update the summary table at the bottom

Skip issues already marked as FIXED or FALSE POSITIVE. Focus on bugs with tests that can be written as unit tests (no visual/rendering tests needed).

---

## 1. BUGS

### ~~1.1 UIRichInteractiveHelper: setDisabled(false) loses hover state~~ FIXED
**File:** `src/bh/ui/UIRichInteractiveHelper.hx:104-106`
**Severity:** ~~Medium~~ Fixed

~~When `setDisabled(id, false)` is called, the state unconditionally resets to `Normal`, even if the mouse is currently over the interactive. Since the OS-level cursor hasn't moved, no new `UIEntering` event fires, leaving the interactive visually in `Normal` while the user sees the cursor over it.~~

**Fix applied:** `setDisabled(false)` now checks `wrapper.hovered` — restores `Hover` state if mouse is still over the interactive, `Normal` otherwise. Test: `testSetDisabledFalseRestoresHoverWhenMouseOver`.

### ~~1.2 UITooltipHelper: rebuild() loses params on second call~~ FALSE POSITIVE
**File:** `src/bh/ui/UITooltipHelper.hx:194-232`
**Severity:** ~~Medium~~ None

~~`rebuild()` without params uses `activeParams` as fallback (line 199), but `showTooltip` stores the raw `params` argument (which is `null`) into `activeParams` (line 232). Second `rebuild()` call with no params finds `activeParams == null`.~~

**Analysis:** This is NOT a bug. `rebuild()` captures `buildParams = params ?? activeParams` (line 199) BEFORE calling `hide()` (line 200). The resolved `buildParams` is then passed to `showTooltip()`, which stores it in `activeParams`. The params are correctly preserved across multiple `rebuild()` calls.

### ~~1.3 UITooltipHelper: startHover ignores changed buildName for same interactive~~ FIXED
**File:** `src/bh/ui/UITooltipHelper.hx:75-87`
**Severity:** ~~Low~~ Fixed

~~If `startHover("btn1", "basicTooltip")` is called, then `startHover("btn1", "advancedTooltip")` while the tooltip is already showing, the second call returns early at line 77 (`activeTooltipId == interactiveId`). The tooltip stays as `basicTooltip`.~~

**Fix applied:** Early return now also compares `activeBuildName == buildName`. If buildName differs, the old tooltip is hidden and a new hover timer starts for the new buildName. Test: `testStartHoverWithChangedBuildNameUpdatesTooltip`.

### ~~1.4 UICardHandHelper: setCardEnabled breaks state for animating cards~~ FIXED
**File:** `src/bh/ui/UICardHandHelper.hx:366-375`
**Severity:** ~~Medium~~ Fixed

~~Comment says "enabling is deferred to onComplete" for animating cards, but code sets `InHand` immediately. If a card is disabled while animating, then re-enabled before animation completes, it becomes `InHand` prematurely — the animation's `onComplete` callback checks `if (entry.state == Animating)` and won't reset it properly.~~

**Fix applied:** Added `enableAfterAnimation` flag on `CardEntry`. When a card is disabled during animation and then re-enabled before the animation completes, the flag defers the enable. All animation `onComplete` callbacks now use `resolveAnimationComplete()` which checks the flag and restores `InHand` + re-enables the interactive if deferred. Tests: `testSetCardEnabledDuringAnimationDefersEnable`, `testResolveAnimationCompleteWithDeferredEnable`, `testResolveAnimationCompleteStaysDisabled`.

### ~~1.5 UICardHandHelper: TargetCard enum variant is dead code~~ FIXED
**File:** `src/bh/ui/UICardHandTypes.hx:58`
**Severity:** ~~Low~~ Fixed

~~`TargetingResult` has a `TargetCard(targetCardId)` variant, but `CardCombined` is a separate event. When card-to-card combining occurs, only `CardCombined` is emitted — `CardPlayed` with `TargetCard` is never used. Dead variant.~~

**Fix applied:** Removed `TargetCard(targetCardId:CardId)` variant from `TargetingResult` enum. Card-to-card combining correctly uses `CardCombined` event. Updated existing test. Test: `testTargetingResultOnlyHasTargetZoneAndNoTarget`.

### ~~1.6 UICardHandHelper: concurrent multi-draw produces stale layout positions~~ MITIGATED
**File:** `src/bh/ui/UICardHandHelper.hx:282-306`
**Severity:** ~~Medium~~ Already handled

~~`drawCard()` computes layout at line 282 and captures `targetIdx` at line 283. If another `drawCard()` is called before the first animation completes, the second call's `computeLayout` produces different positions (array now has the first card). Meanwhile, `rearrangeCards` from draw #1 may still be animating cards toward positions that are no longer correct. Cards can briefly animate to wrong positions during rapid multi-draw sequences.~~

**Analysis:** Already mitigated. Each draw animation's `onComplete` callback calls `applyLayout(true)` (line 303), which recomputes all positions and smoothly animates cards to their correct final positions. The comment at line 301-302 documents this intentional design. Cards may briefly animate to intermediate positions during concurrent draws, but they always converge to correct positions.

### ~~1.7 UIMultiAnimDraggable: clear() nullifies target but doesn't remove root~~ FIXED
**File:** `src/bh/ui/UIMultiAnimDraggable.hx:353-372`
**Severity:** ~~Low~~ Fixed

~~`clear()` removes and nullifies `target` (lines 368-371), but `root` remains in the scene graph as an empty wrapper. The draggable is left in a half-cleaned state — `root` is alive but `target` is null, which could cause NPE if `update()` or `onEvent()` is called after `clear()`.~~

**Fix applied:** `clear()` now also removes `root` from the scene graph and sets `enabled = false` to prevent stale event processing. Also clears `sourceSlot`/`sourceData`. Tests: `testClearRemovesRootFromScene`, `testClearDisablesElement`.

### ~~1.8 UICardHandHelper: dispose() doesn't cancel active animations~~ FALSE POSITIVE
**File:** `src/bh/ui/UICardHandHelper.hx:534-540`
**Severity:** ~~Low~~ None

~~`dispose()` calls `clearHand()` which sets `activeAnimations = []`, dropping animation references without calling any cleanup. If animated path objects hold Heaps resources, they leak. The `onComplete` callbacks captured in `ActiveAnimation` may also reference disposed card entries.~~

**Analysis:** Not a real bug. `clearHand()` sets `activeAnimations = []` which creates a new empty array. The `update()` method reads from the field, so it iterates the new empty array — orphaned callbacks are never called. `AnimatedPath` objects are pure math state (no textures, no scene graph nodes), so there's no resource leak. Entries become garbage-collectable once no references remain.

### ~~1.9 UIMultiAnimGrid: CellCardPlayed event defined but never emitted~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGridTypes.hx:46`, `src/bh/ui/UIMultiAnimGrid.hx:803-844`
**Severity:** ~~High~~ Fixed

~~`GridEvent.CellCardPlayed(cell, cardId)` is defined in the enum but the grid never emits it. `createCardTargetsForBinding()` wires highlight callbacks but has no mechanism to detect when a card is actually played on a target.~~

**Fix applied:** Grid now adds a chained event listener to the card hand via `chainedListeners` array (avoids overwriting the game's `onCardEvent` callback). When `CardPlayed(cardId, TargetZone(targetId))` fires and the targetId matches this grid's prefix, the grid emits `CellCardPlayed(cell, cardId)`. Listener is cleaned up on `unregisterAsCardTarget()`. Tests: `testCellCardPlayedEventEmitted`, `testCellCardPlayedNotEmittedForForeignTarget`, `testCellCardPlayedListenerRemovedOnUnregister`.

### ~~1.10 UIMultiAnimGrid: multiple card hand registrations corrupt shared target state~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGrid.hx:104-105, 847-854`
**Severity:** ~~High~~ Fixed

~~`cardTargetInteractives` and `cardTargetWrappers` are single shared maps (lines 104-105) across all registered card hands. `clearCardTargetsForBinding()` (line 847) iterates the **entire** shared map and unregisters all targets from the specific binding's card hand — then **clears the entire map** (lines 852-853). If two card hands are registered, clearing one wipes targets belonging to the other.~~

**Fix applied:** Each card hand binding now gets a unique `targetPrefix` (e.g., `grid0ch0`, `grid0ch1`). Target IDs include the prefix, and `clearCardTargetsForBinding` only removes entries matching the binding's prefix instead of calling `.clear()`. Test: `testMultipleCardHandRegistrationsDontCorrupt`.

### ~~1.11 UIMultiAnimGrid: rebuildCell doesn't refresh drag zones or card targets~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGrid.hx:302-317`
**Severity:** ~~Medium~~ Fixed

`rebuildCell()` now calls `refreshAllDraggableZones()` and `refreshAllCardTargets()` after rebuilding, consistent with `addCell()` and `removeCell()`.

### ~~1.12 UIMultiAnimGrid: hitTestRect uses wrong stride for Y gap check~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGrid.hx:646`
**Severity:** ~~High~~ Fixed

Changed `localY - row * stride` to `localY - row * strideY`. Test: non-square cells (60x30, gap=4) — gap points between rows are now correctly rejected. Test: `testHitTestNonSquareCellYGap`.

### ~~1.13 UIMultiAnimGrid: hitTestRect rejects negative coordinates~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGrid.hx:638-639`
**Severity:** ~~Medium~~ Fixed

Removed the `if (localX < 0 || localY < 0) return null` guard. `Math.floor` correctly handles negative values, and the cell-local offset calculation works for negative coordinates. Test: `testCellAtPointNegativeCoordinates`.

### ~~1.14 UIMultiAnimGrid: acceptDrops allows duplicate registration~~ FIXED
**File:** `src/bh/ui/UIMultiAnimGrid.hx:424-432`
**Severity:** ~~Low~~ Fixed

~~Calling `acceptDrops(draggable)` twice pushes the same draggable twice into `registeredDraggables`. Creates duplicate drop zones and overwrites the draggable's highlight callbacks via chaining.~~

**Fix applied:** `acceptDrops()` now checks if the draggable is already registered and returns early if so. Test: `testAcceptDropsDuplicateIgnored`.

### ~~1.15 UIMultiAnimDraggable: swap mode doesn't validate sourceSlot state~~ FIXED
**File:** `src/bh/ui/UIMultiAnimDraggable.hx:480-494`
**Severity:** ~~Medium~~ Fixed

~~In swap mode, after the snap animation completes, the callback (lines 482-494) reads `sourceSlot.data` and `zone.slot.getContent()`. But `sourceSlot` is only cleared at line 494. If the slot is manipulated externally before the animation completes (e.g., another drag starts from the same slot), the swap operates on stale data.~~

**Fix applied:** Added `sourceData` field that snapshots `sourceSlot.data` at `createFromSlot()` time (before slot is cleared). Swap mode now uses `sourceData` instead of reading `sourceSlot.data` at callback time. Cancel path also restores `sourceSlot.data` from snapshot. Tests: `testSwapModeSnapshotsCapturedBeforeAnimation`, `testSwapModePreservesSnapshotAfterExternalModification`.

---

## 2. CODE DUPLICATION

### 2.1 positionTooltip / positionPanel — identical positioning logic — VERIFIED
**Files:**
- `src/bh/ui/UITooltipHelper.hx:246-264` (`positionTooltip`)
- `src/bh/ui/UIPanelHelper.hx:390-408` (`positionPanel`)

Confirmed: structurally identical `switch` on `TooltipPosition` with same Above/Below/Left/Right math. Only variable names differ (`tooltip`→`panel`, `tooltipBounds`→`panelBounds`). Could extract to a shared static utility.

### 2.2 Fade-in/fade-out pattern repeated 4 times — VERIFIED (overstated)
**Files:**
- `UITooltipHelper.hx:120-131` (hide fade-out), `221-227` (show fade-in)
- `UIPanelHelper.hx:145-155` (close fade-out), `115-121` (open fade-in), `222-233` (named fade-in), `259-265` (named fade-out)

Confirmed: the core pattern (create tween, cancel previous, remove on complete) repeats across 6 sites. However, each site has unique state management — different tracking variables, different cleanup actions (tooltip clears `fadingOutObj`, panel also calls `removeInteractives`, named panel stores ref in `PanelState`). A `FadeHelper` would need generics or callbacks to accommodate all variants. Pattern similarity is real but "line-for-line identical" overstates it.

### 2.3 OBB hit-testing duplicated in CardHandHelper — VERIFIED
**File:** `src/bh/ui/UICardHandHelper.hx:1022-1034` and `1059-1072`

Confirmed: both methods compute `dx,dy → cos/sin(-rotation) → localX/localY → halfW/halfH bounds check` with identical rotation math. Differences: (1) position source (computed `basePositions` vs `entry.layoutPos`), (2) iteration direction, (3) selection strategy (nearest-center vs first-hit reverse-z), (4) skip filters. A shared `obbContains(x, y, posX, posY, rotation, halfW, halfH):Bool` helper would eliminate the core duplication.

### 2.4 Config null-check boilerplate in CardHandHelper constructor — VERIFIED
**File:** `src/bh/ui/UICardHandHelper.hx:206-241`

Confirmed: 36 lines of `config != null && config.X != null ? config.X : default`. Every line follows the exact same pattern. Haxe's safe navigation + null coalescing (`config?.field ?? default`) would reduce each to a single expression. The typedef already uses `var ?field` optionals so `??` is the natural fit.

### 2.5 Target highlight state update duplicated in UICardHandTargeting — VERIFIED
**File:** `src/bh/ui/UICardHandTargeting.hx:146-155` and `196-206`

Confirmed: both methods compute `newTargetId`, compare with `activeTargetId`, unhighlight old via `onTargetHighlight(id, false, metadata)`, update `activeTargetId`, highlight new. The code is nearly character-for-character identical. A private `updateHighlightState(newTargetId, hoveredWrapper)` method would eliminate the duplication cleanly.

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

### ~~4.4 Named panel fade-in tween not tracked~~ FIXED
**File:** `src/bh/ui/UIPanelHelper.hx:224`
**Severity:** ~~Low~~ Fixed

~~Single-panel API tracks `activeFadeInTween` (line 117) for cancellation, but named panel fade-in tween is fire-and-forget (line 224). If `closeNamed()` is called during fade-in, the tween continues running on a panel that's being removed, potentially causing visual artifacts.~~

**Fix applied:** Added `fadeInTween` field to `PanelState`. `openNamed()` now stores the tween reference; `closeNamed()` cancels it before starting fade-out. The onComplete callback clears the reference when the fade-in finishes normally. Tests: `testNamedPanelFadeInCancelledOnClose`, `testNamedPanelReplaceInSameSlotCancelsFadeIn`.

### 4.5 FloatingTextHelper: color application only for h2d.Text
**File:** `src/bh/ui/FloatingTextHelper.hx:120-124`

`spawnObject()` allows spawning arbitrary `h2d.Object`, but color from `AnimatedPathState.color` is only applied to `h2d.Text` instances. No way to apply color curves to custom objects.

### ~~4.6 beginUpdate/endUpdate wrapping inconsistent across UI components~~ PARTIALLY FIXED
**Files:** Multiple UI components
**Severity:** ~~Low~~ Partially fixed

~~Some components batch multi-parameter changes with `beginUpdate()`/`endUpdate()`, others don't:~~

| Component | Method | Uses batching? | Status |
|-----------|--------|---------------|--------|
| UIMultiAnimButton | `set_disabled` | Yes | OK |
| UIMultiAnimCheckbox | `set_disabled` | ~~No~~ Yes | **FIXED** |
| UIMultiAnimCheckbox | `set_selected` | No (1 param) | OK — single `setParameter` doesn't need batching |
| UIMultiAnimTextInput | `set_disabled` | Yes | OK |
| UIMultiAnimTabs (TabButton) | `set_selected` | Only when `value==true` | OK — deselection sets 1 param |
| UIMultiAnimTabs (TabButton) | `set_disabled` | ~~No~~ Yes | **FIXED** |

**Fix applied:** `UIMultiAnimCheckbox.set_disabled` and `UIMultiAnimTabButton.set_disabled` now use `beginUpdate/endUpdate` and set both `status` (to `"disabled"`/`"normal"`) and `disabled` parameters, matching the `UIMultiAnimButton` pattern. Previously, disabling a checkbox or tab button would leave `status` at whatever it was (e.g. "hover"), causing inconsistent visuals.

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
| 1.1 | ~~Bug~~ | ~~Medium~~ | RichInteractive | ~~setDisabled(false) loses hover~~ FIXED |
| 1.2 | ~~Bug~~ | ~~Medium~~ | Tooltip | ~~rebuild() loses params~~ FALSE POSITIVE |
| 1.3 | ~~Bug~~ | ~~Low~~ | Tooltip | ~~startHover ignores changed buildName~~ FIXED |
| 1.4 | ~~Bug~~ | ~~Medium~~ | CardHand | ~~setCardEnabled breaks animating cards~~ FIXED |
| 1.5 | ~~Bug~~ | ~~Low~~ | CardHand | ~~TargetCard enum variant dead code~~ FIXED |
| 1.6 | ~~Bug~~ | ~~Medium~~ | CardHand | ~~Concurrent multi-draw stale positions~~ MITIGATED |
| 1.7 | ~~Bug~~ | ~~Low~~ | Draggable | ~~clear() partial cleanup~~ FIXED |
| 1.8 | ~~Bug~~ | ~~Low~~ | CardHand | ~~dispose() doesn't cancel animations~~ FALSE POSITIVE |
| 1.9 | ~~Bug~~ | ~~**High**~~ | Grid | ~~CellCardPlayed event never emitted~~ FIXED |
| 1.10 | ~~Bug~~ | ~~**High**~~ | Grid | ~~Multiple card hand registrations corrupt targets~~ FIXED |
| 1.11 | ~~Bug~~ | ~~Medium~~ | Grid | ~~rebuildCell doesn't refresh zones/targets~~ FIXED |
| 1.12 | ~~Bug~~ | ~~**High**~~ | Grid | ~~hitTestRect Y gap uses wrong stride variable~~ FIXED |
| 1.13 | ~~Bug~~ | ~~Medium~~ | Grid | ~~hitTestRect rejects negative coordinates~~ FIXED |
| 1.14 | ~~Bug~~ | ~~Low~~ | Grid | ~~acceptDrops allows duplicate registration~~ FIXED |
| 1.15 | ~~Bug~~ | ~~Medium~~ | Draggable | ~~swap mode doesn't validate sourceSlot state~~ FIXED |
| 2.1 | Duplication | Medium | Tooltip+Panel | Identical positioning logic — VERIFIED |
| 2.2 | Duplication | Low | Tooltip+Panel | Fade pattern repeated — VERIFIED (overstated) |
| 2.3 | Duplication | Low | CardHand | OBB hit-test duplicated — VERIFIED |
| 2.4 | Duplication | Low | CardHand | Config null-check boilerplate — VERIFIED |
| 2.5 | Duplication | Low | Targeting | Highlight state update duplicated — VERIFIED |
| 3.1 | Interop | Low | RichInteractive+CardHand | State ownership undocumented |
| 3.2 | Interop | Low | Grid+CardHand | Stale wrapper window |
| 3.3 | Interop | Low | Panel | Close event before fade completes |
| 3.4 | Interop | Low | Draggable | No screen cleanup on dispose |
| 4.1 | Inconsistency | Medium | All | Dispose/cleanup patterns differ |
| 4.2 | Inconsistency | Low | All | Event emission patterns differ |
| 4.3 | Inconsistency | Low | Tooltip+Panel | Param passing to builder |
| 4.4 | ~~Inconsistency~~ | ~~Low~~ | Panel | ~~Named panel fade not tracked~~ FIXED |
| 4.5 | Inconsistency | Low | FloatingText | Color only for h2d.Text |
| 4.6 | ~~Inconsistency~~ | ~~Low~~ | UI Components | ~~beginUpdate/endUpdate wrapping inconsistent~~ PARTIALLY FIXED |
| 4.7 | Inconsistency | Low | Slider+ProgressBar | clear() nullifies builder, prevents reuse |
| 4.8 | Duplication | Low | UI Components | Cursor implementation duplicated in all components |
| 5.1 | Missing | Low | RichInteractive | No state change callbacks |
| 5.2 | Missing | Low | Tooltip+Panel | No reposition API |
| 5.3 | Missing | Low | CardHand | No card reorder API |