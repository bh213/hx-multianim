# Suggestions

| # | Item | Summary | Area | Impact | Effort |
|---|------|---------|------|--------|--------|
| 1 | Auto positioning with overflow | Flip tooltip/panel when clipped by screen bounds | Tooltip/Panel | High | Medium |
| 2 | Panel toggle | Click to open/close instead of always re-opening | UIPanelHelper | Medium | Low |
| 3 | Batch `setDisabled` | Disable all interactives from one register() call at once | UIRichInteractiveHelper | Low | Low |
| 4 | `isDisabled()` query | Query disabled state on helper, not just wrapper | UIRichInteractiveHelper | Low | Low |
| 5 | Panel anchor tracking | Re-position panel when anchor moves (e.g. in scroll) | UIPanelHelper | Low | Low |
| 6 | Deduplicate open/openNamed | Extract shared positioning + registration logic | UIPanelHelper | Low | Low |
| 7 | `closeAll()` convenience | Single call to close single + all named panels | UIPanelHelper | Low | Low |
| 8 | `EVENT_PANEL_OPEN` for symmetry | Emit open event to match existing close event | UIPanelHelper | Low | Low |
| 9 | Declarative tooltip/panel system | Metadata auto-wiring, event lifecycle, screen-level setup | Tooltip/Panel | High | High |
| 10 | Password mode for text input | Mask input with dots/asterisks | TextInput | Low | Low |
| 11 | Auto-grow multiline text input | Notify parent flow of size changes on content grow | TextInput | Low | Medium |
| 12 | Modal tab groups | Push/pop tab groups for modal panels with text inputs | TextInput | Low | Low |

## UIRichInteractiveHelper

### Batch `setDisabled`
If you have 10 interactives from one `register()` call, disabling them all requires 10 individual `setDisabled()` calls. No batch API.
**Suggestion:** Add `setAllDisabled(disabled:Bool)` or `setDisabledByPrefix(prefix, disabled)`.

### `isDisabled()` query
Can check `wrapper.disabled` on the UIInteractiveWrapper but no API on the helper itself.
**Suggestion:** Add `isDisabled(interactiveId):Bool`.

## UIPanelHelper

### Panel toggle
Clicking an interactive that already has its panel open calls `open()` which does `close()` then re-opens. No built-in "click to toggle" pattern.
**Suggestion:** Add `toggle(interactiveId, buildName, ?params)` that closes if already open for that id, opens otherwise.

### Panel anchor tracking
If the anchor interactive moves (e.g. inside a scrollable list), the panel stays at its original position.
**Suggestion:** Optional `trackAnchor:Bool` that re-runs `positionPanel()` in an `update(dt)` method.

### Dedup open/openNamed internals
`open()` and `openNamed()` duplicate the positioning + registration logic.
**Suggestion:** Extract a private `openPanel()` that returns `PanelState`, with `open`/`openNamed` as thin wrappers.

### `closeAll()` convenience
No single call to close both the single panel and all named panels. Useful for screen transitions/cleanup.
**Suggestion:** Add `closeAll()` that calls `close()` + `closeAllNamed()`.

### `EVENT_PANEL_OPEN` for symmetry
`EVENT_PANEL_CLOSE` exists but no open event. Screens that want to react to panel lifecycle must wrap `open()`/`openNamed()`.
**Suggestion:** Emit `UICustomEvent(EVENT_PANEL_OPEN, interactiveId)` from `open()`/`openNamed()`.

## Declarative Event-Driven Tooltip/Panel System

The current helpers (`UITooltipHelper`, `UIPanelHelper`) are manual/imperative. The planned design is a declarative, event-driven system. Key pieces:

### Metadata auto-wiring
`tooltip => "progName"` and `panel => "progName"` metadata on interactives would auto-wire hover/click behavior without manual `startHover`/`cancelHover`/`open`/`close` calls. Parent parameters forwarded by name-match.

### Event-driven lifecycle
New `UIScreenEvent` variants: `UITooltipRequest(config)`, `UITooltipHide`, `UIPanelRequest(config)`, `UIPanelClose`. Config objects are mutable — screens can modify params, swap buildName, change position, or set `cancelled = true` before the tooltip/panel appears. All control flows through existing `onScreenEvent`.

### Screen-level setup
`enableTooltips(builder, {delay, position, offset, layer})` and `enablePanels(builder, {closeOn, position, layer})` — one-time setup per screen. Manual registration (`setTooltip`/`setPanel`) available for interactives without metadata.

### `tooltipText` shorthand
`tooltipText => "Click to purchase"` for simple text tooltips using a built-in default programmable.

### Nested panel interactives
Panel interactives get compound prefix: `{parentId}.{panelName}.{childId}`. Partially working — `UIPanelHelper.open()` already registers with prefix.

### Auto positioning with overflow
`Auto` position checks screen bounds and flips to opposite side.

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

## TextInput

### Password mode
Not in v1. If needed later: add `password:bool` setting, override `h2d.TextInput` to display dots/asterisks while keeping real text internally.

### Auto-grow multiline
Fixed-size multiline works now. Auto-grow would need to notify parent layout (Flow) of size changes. Start with fixed-size, add auto-grow later if needed.

### Modal tab groups
One `UITabGroup` per screen is the natural scope. For modal panels containing text inputs: modal gets its own tab group, pushed/popped with the panel.
