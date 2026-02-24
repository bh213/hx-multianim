# Interactives Improvements

Suggestions based on reviewing the current interactive system (UIInteractiveWrapper, UIRichInteractiveHelper, UITooltipHelper, UIPanelHelper) and existing TODOs.

---

## 1. Bugs & Code Quality

### 1.2 Dropdown panel not on modal layer
**File:** `UIMultiAnimDropdown.hx:246`
**Issue:** The dropdown's floating panel uses `PositionLinkObject` but doesn't get placed on the modal layer. This can cause z-ordering issues where other UI elements render on top of the dropdown.
**Fix:** Route through `UIElementCustomAddToLayer` or `screen.addObjectToLayer(obj, ModalLayer)`.


---

## 2. UIRichInteractiveHelper Improvements



### 2.3 `register()` doesn't store results for bulk `setDisabled`
**Issue:** If you have 10 interactives from one `register()` call, disabling them all requires 10 individual `setDisabled()` calls. No batch API.
**Suggestion:** Add `setAllDisabled(disabled:Bool)` or `setDisabledByPrefix(prefix, disabled)`.

### 2.4 No `isDisabled()` query
**Issue:** Can check `wrapper.disabled` on the UIInteractiveWrapper but no API on the helper itself.
**Suggestion:** Add `isDisabled(interactiveId):Bool`.

---

## 3. UITooltipHelper Improvements



---

## 4. UIPanelHelper Improvements

### 4.2 No toggle behavior
**Issue:** Clicking an interactive that already has its panel open calls `open()` which does `close()` then re-opens. There's no built-in "click to toggle" pattern.
**Suggestion:** Add `toggle(interactiveId, buildName, ?params)` that closes if already open for that id, opens otherwise.

### 4.3 Panel doesn't update when anchor moves
**Issue:** If the anchor interactive moves (e.g. inside a scrollable list), the panel stays at its original position.
**Suggestion:** Optional `trackAnchor:Bool` that re-runs `positionPanel()` in an `update(dt)` method.

### 4.6 Dedup open/openNamed internals
**Issue:** `open()` and `openNamed()` duplicate the positioning + registration logic.
**Suggestion:** Extract a private `openPanel()` that returns `PanelState`, with `open`/`openNamed` as thin wrappers.

### 4.7 `closeAllNamed()` iterator safety
**Issue:** `closeAllNamed()` iterates `namedPanels` while `closeNamed()` removes from it. Currently works because Haxe `StringMap` iteration copies keys, but fragile.
**Suggestion:** Collect keys first (like `checkPendingClose` already does).

### 4.8 Named panel outside-click scope is too broad
**Issue:** In `handleOutsideClick`, clicking inside *any* panel cancels the pending close for a *specific* named panel (line 254 uses `isOwnInteractive` which checks all panels). Should only cancel if the click is on this panel's own interactives or the trigger interactive.
**Suggestion:** Check `panel.prefix` and `panel.interactiveId` directly instead of `isOwnInteractive(id)`.

### 4.9 `closeAll()` convenience
**Issue:** No single call to close both the single panel and all named panels. Useful for screen transitions/cleanup.
**Suggestion:** Add `closeAll()` that calls `close()` + `closeAllNamed()`.

### 4.10 `EVENT_PANEL_OPEN` for symmetry
**Issue:** `EVENT_PANEL_CLOSE` exists but no open event. Screens that want to react to panel lifecycle must wrap `open()`/`openNamed()`.
**Suggestion:** Emit `UICustomEvent(EVENT_PANEL_OPEN, interactiveId)` from `open()`/`openNamed()`.

---


---

## 6. Declarative Event-Driven Tooltip/Panel System (Not Yet Implemented)

The current helpers (`UITooltipHelper`, `UIPanelHelper`) are manual/imperative. The planned design is a declarative, event-driven system that would be the largest single improvement. Key pieces:

### 6.1 Metadata auto-wiring
`tooltip => "progName"` and `panel => "progName"` metadata on interactives would auto-wire hover/click behavior without manual `startHover`/`cancelHover`/`open`/`close` calls. Parent parameters forwarded by name-match.

### 6.2 Event-driven lifecycle
New `UIScreenEvent` variants: `UITooltipRequest(config)`, `UITooltipHide`, `UIPanelRequest(config)`, `UIPanelClose`. Config objects are mutable — screens can modify params, swap buildName, change position, or set `cancelled = true` before the tooltip/panel appears. All control flows through existing `onScreenEvent`.

### 6.3 Screen-level setup
`enableTooltips(builder, {delay, position, offset, layer})` and `enablePanels(builder, {closeOn, position, layer})` — one-time setup per screen. Manual registration (`setTooltip`/`setPanel`) available for interactives without metadata.

### 6.4 `tooltipText` shorthand
`tooltipText => "Click to purchase"` for simple text tooltips using a built-in default programmable.

### 6.5 Nested panel interactives
Panel interactives get compound prefix: `{parentId}.{panelName}.{childId}`. Partially working — `UIPanelHelper.open()` already registers with prefix.

### 6.6 Auto positioning with overflow
`Auto` position checks screen bounds and flips to opposite side. (Same as §3.1 above.)

### Current state

| Feature | Status |
|---------|--------|
| `tooltip`/`panel` metadata auto-wiring | Not implemented |
| Event-driven lifecycle | Not implemented |
| Parameter forwarding from parent | Not implemented |
| `tooltipText` shorthand | Not implemented |
| `Auto` positioning | Not implemented |
| Screen-level `enableTooltips()`/`enablePanels()` | Not implemented |
| Nested panel interactives | Partial |

---

## 7. Test Coverage Gaps

Tracked in `visualtests-todo.md` but repeated here for completeness:

- **UIRichInteractiveHelper** — no tests for `register()`, `handleEvent()`, `setDisabled()`
- **UITooltipHelper** — no tests for delay, show/hide, positioning
- **UIPanelHelper** — no tests for open/close, outside-click, deferred close, named panels
- **Event filtering** (`events: [hover, click, push]`) — no unit test
- **`bind` metadata** — no unit test
- **`UIClickOutside`** — no unit or visual test
- **Disabled interactive** gating events — no test

---

## Priority Ranking

| # | Item | Impact | Effort |
|---|------|--------|--------|
| 1 | Auto positioning with overflow (§3.1) | High — prevents clipped tooltips | Medium |
| 2 | Panel toggle (§4.2) | Medium — common UX pattern | Low |
| 3 | Named panel outside-click scope fix (§4.8) | Medium — correctness bug | Low |
| 4 | Batch setDisabled (§2.3) | Low — convenience | Low |
| 5 | closeAll convenience (§4.9) | Low — convenience | Low |
| 6 | Dedup open internals (§4.6) | Low — code quality | Low |
| 7 | Tooltip follow mouse (§3.4) | Low — niche use case | Low |
| 8 | UIClickOutside naming (§1.3) | Low — docs fix | Low |
