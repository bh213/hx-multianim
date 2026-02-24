# Interactives Improvements

Suggestions based on reviewing the current interactive system (UIInteractiveWrapper, UIRichInteractiveHelper, UITooltipHelper, UIPanelHelper) and existing TODOs.

---

## 1. Bugs & Code Quality

### 1.1 `outsideClick.handle()` called on every event type
**File:** `UIControllerBase.hx:118`
**Issue:** `controllable.outsideClick.handle(element)` is called for every event dispatch, not just mouse clicks. This means hover events unnecessarily trigger outside-click tracking logic.
**Fix:** Guard with a check for click-relevant events (`OnPush`, `OnRelease`, `OnReleaseOutside`) before calling `outsideClick.handle()`.

### 1.2 Dropdown panel not on modal layer
**File:** `UIMultiAnimDropdown.hx:246`
**Issue:** The dropdown's floating panel uses `PositionLinkObject` but doesn't get placed on the modal layer. This can cause z-ordering issues where other UI elements render on top of the dropdown.
**Fix:** Route through `UIElementCustomAddToLayer` or `screen.addObjectToLayer(obj, ModalLayer)`.

### 1.3 `UIClickOutside` fires on `OnReleaseOutside` — naming mismatch
**File:** `UIInteractiveWrapper.hx:72`
**Issue:** `UIClickOutside` is emitted from `OnReleaseOutside`, which fires when the user presses inside and releases outside. This is a "drag-off" gesture, not a true "click outside" (click somewhere else entirely). The naming `UIClickOutside` suggests the latter. The actual "clicked elsewhere" behavior comes from `Controllable.outsideClick` which UIPanelHelper uses correctly, so this event's semantics may confuse users.
**Suggestion:** Document the distinction clearly, or consider renaming to `UIReleaseOutside` / adding a separate true outside-click event.

---

## 2. UIRichInteractiveHelper Improvements

### 2.1 No re-entry protection on rapid state changes
**Issue:** If `handleEvent` receives `UILeaving` while in `Pressed` state (mouse dragged off while pressed), it correctly resets to `Normal`. But if the user quickly re-enters, the state machine goes `Normal → Hover` without a visual "release" frame. This is usually fine but could cause subtle visual glitches with slow animations.
**Suggestion:** Optional `transitionDelay` or just document that pressed→leave→enter skips the release visual.

### 2.2 No cursor change support
**Issue:** Interactive hover doesn't change the mouse cursor. For buttons/clickable areas, users expect a pointer cursor.
**Suggestion:** Add optional `cursor` metadata on `interactive()` elements (e.g. `cursor => "pointer"`). `UIRichInteractiveHelper` could set `hxd.System.setCursor()` on `UIEntering`/`UILeaving`.

### 2.3 `register()` doesn't store results for bulk `setDisabled`
**Issue:** If you have 10 interactives from one `register()` call, disabling them all requires 10 individual `setDisabled()` calls. No batch API.
**Suggestion:** Add `setAllDisabled(disabled:Bool)` or `setDisabledByPrefix(prefix, disabled)`.

### 2.4 No `isDisabled()` query
**Issue:** Can check `wrapper.disabled` on the UIInteractiveWrapper but no API on the helper itself.
**Suggestion:** Add `isDisabled(interactiveId):Bool`.

---

## 3. UITooltipHelper Improvements

### 3.1 No `Auto` positioning with overflow detection
**Issue:** Only supports Above/Below/Left/Right. If the tooltip would overflow the screen (e.g. tooltip Above an element near the top edge), it gets clipped.
**Suggestion:** Add `Auto` position that checks screen bounds and flips to the opposite side. Already mentioned in `tooltip-planning.md` §6 but not implemented.

### 3.2 No tooltip content update for active tooltip
**Issue:** Once a tooltip is shown, its content is static. If the underlying data changes (e.g. a price updates while hovering), the tooltip shows stale data.
**Suggestion:** Add `updateParams(params:Map<String,Dynamic>)` that calls `setParameter()` on the active `BuilderResult` for incremental update, or `rebuild()` for full rebuild.

### 3.3 No per-interactive offset override
**Issue:** `setDelay()` and `setPosition()` allow per-interactive overrides, but there's no `setOffset()`.
**Suggestion:** Add `offsetOverrides:Map<String, Int>` and `setOffset(interactiveId, offset)`.

### 3.4 Tooltip doesn't follow mouse
**Issue:** Tooltip is positioned once when shown and stays fixed relative to the anchor. For large interactives, the tooltip may feel disconnected from the cursor.
**Suggestion:** Optional `followMouse:Bool` mode that updates position in `update(dt)` based on current mouse position.

### 3.5 No show/hide transition
**Issue:** Tooltip appears/disappears instantly. `transitions-planning.md` mentions fade in/out but it's not implemented.
**Suggestion:** Defer to the transitions system when implemented. In the meantime, a simple alpha tween (0→1 over 0.1s) would improve feel.

---

## 4. UIPanelHelper Improvements

### 4.1 No position override per-interactive
**Issue:** All panels use `defaultPosition`. Unlike UITooltipHelper which has `positionOverrides`, UIPanelHelper has none.
**Suggestion:** Add `positionOverrides:Map<String, TooltipPosition>` and `setPosition(interactiveId, position)`.

### 4.2 No toggle behavior
**Issue:** Clicking an interactive that already has its panel open calls `open()` which does `close()` then re-opens. There's no built-in "click to toggle" pattern.
**Suggestion:** Add `toggle(interactiveId, buildName, ?params)` that closes if already open for that id, opens otherwise.

### 4.3 Panel doesn't update when anchor moves
**Issue:** If the anchor interactive moves (e.g. inside a scrollable list), the panel stays at its original position.
**Suggestion:** Optional `trackAnchor:Bool` that re-runs `positionPanel()` in an `update(dt)` method.

### 4.4 No `onClose` callback or event
**Issue:** When a panel is closed (by outside click or programmatically), the screen only knows via `checkPendingClose()` return value or by checking `isOpen()`. There's no event pushed to `onScreenEvent`.
**Suggestion:** Push a `UIPanelClose` event (as designed in `tooltip-planning.md` §2) when the panel closes.

### 4.5 Only one panel at a time
**Issue:** Opening a new panel always closes the previous one. Can't have two panels open simultaneously (e.g. a context menu + a detail panel).
**Suggestion:** Support named panel slots or a `multi:Bool` flag. Low priority — single panel covers most cases.

---

## 5. Interactive Metadata & Parser

### 5.1 No boolean metadata type
**Issue:** Metadata supports `int`, `float`, `string`, `color` but not `bool`. Writing `enabled:int => 1` is the workaround.
**Suggestion:** Add `key:bool => true/false` parsing in `parseInteractiveMetadata()`.

### 5.2 No metadata access helpers on BuilderResolvedSettings for common patterns
**Issue:** Getting typed metadata requires `brs.getStringOrDefault("tooltip", "")` + empty-string check every time.
**Suggestion:** Add `has(key):Bool` convenience method on `BuilderResolvedSettings`.

---

## 6. Missing from tooltip-planning.md (Implementation Gaps)

These are features designed in `tooltip-planning.md` but not yet in the current helpers:

| Feature | Planning Doc | Current State |
|---------|-------------|---------------|
| `tooltip` metadata auto-wiring | §1 | Not implemented — manual `startHover`/`cancelHover` calls needed |
| `panel` metadata auto-wiring | §1 | Not implemented — manual `open`/`close` calls needed |
| Event-driven lifecycle (`UITooltipRequest`/`UIPanelRequest`) | §2 | Not implemented |
| Parameter forwarding from parent | §1 | Not implemented |
| `tooltipText` shorthand | §7 | Not implemented |
| `Auto` positioning with overflow | §6 | Not implemented |
| Screen-level `enableTooltips()`/`enablePanels()` | §3 | Not implemented |
| Nested panel interactives with compound prefix | §4 | Partially — `UIPanelHelper.open()` does register with prefix |

The current helpers are manual/imperative. The planning doc envisions a declarative, event-driven system. The gap is significant — bridging it is the largest single improvement opportunity.

---

## 7. Test Coverage Gaps

Tracked in `visualtests-todo.md` but repeated here for completeness:

- **UIRichInteractiveHelper** — no tests for `register()`, `handleEvent()`, `setDisabled()`
- **UITooltipHelper** — no tests for delay, show/hide, positioning
- **UIPanelHelper** — no tests for open/close, outside-click, deferred close
- **Event filtering** (`events: [hover, click, push]`) — no unit test
- **`bind` metadata** — no unit test
- **`UIClickOutside`** — no unit or visual test
- **Disabled interactive** gating events — no test

---

## Priority Ranking

| # | Item | Impact | Effort |
|---|------|--------|--------|
| 1 | Auto positioning with overflow (§3.1) | High — prevents clipped tooltips | Medium |
| 2 | outsideClick.handle guard (§1.1) | Medium — correctness | Low |
| 3 | Panel toggle (§4.2) | Medium — common UX pattern | Low |
| 4 | Tooltip content update (§3.2) | Medium — live data scenarios | Low |
| 5 | Cursor change (§2.2) | Medium — UX polish | Medium |
| 6 | Batch setDisabled (§2.3) | Low — convenience | Low |
| 7 | Per-interactive panel position (§4.1) | Low — parity with tooltip | Low |
| 8 | Tooltip follow mouse (§3.4) | Low — niche use case | Low |
| 9 | Boolean metadata (§5.1) | Low — workaround exists | Low |
| 10 | UIClickOutside naming (§1.3) | Low — docs fix | Low |
