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
**Suggestion:** Add `Auto` position that checks screen bounds and flips to the opposite side.

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
**Issue:** Tooltip appears/disappears instantly.
**Suggestion:** A simple alpha tween (0→1 over ~0.15s) would improve feel. Could later integrate with a transitions system if one is built.

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
**Suggestion:** Push a `UIPanelClose` event when the panel closes, so screens can react in `onScreenEvent` like they do for other UI events.

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
