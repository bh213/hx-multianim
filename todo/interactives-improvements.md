# Interactives Improvements

Suggestions based on reviewing the current interactive system (UIInteractiveWrapper, UIRichInteractiveHelper, UITooltipHelper, UIPanelHelper) and existing TODOs.

---

## 1. Bugs & Code Quality

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

## 8. Cursor Support Design

### Overview
Add cursor change on hover for all UI elements. Follow the `FontManager.registerFont()` pattern for custom cursors.

### 8.1 CursorManager — registration (like FontManager)

**File:** `src/bh/base/CursorManager.hx`

```haxe
class CursorManager {
    static var cursorRegistry:Map<String, hxd.Cursor> = [];
    static var defaultCursor:hxd.Cursor = Default;
    static var initialized = false;

    // Lazily registers all Heaps built-in cursors on first access
    static function ensureInit():Void;

    // Register a named cursor (like FontManager.registerFont)
    // Overwrites if name already exists (allows replacing built-ins)
    public static function registerCursor(name:String, cursor:hxd.Cursor):Void;

    // Remove a registered cursor by name
    public static function unregisterCursor(name:String):Bool;

    // Lookup by name, returns null if not found
    public static function getCursor(name:String):Null<hxd.Cursor>;

    // Set/get the default cursor for all interactive UI elements
    public static function setDefaultInteractiveCursor(cursor:hxd.Cursor):Void;
    public static function getDefaultInteractiveCursor():hxd.Cursor;
}
```

**Pre-registered Heaps cursors** (registered lazily on first `getCursor`/`registerCursor` call):

| Name | hxd.Cursor |
|------|-----------|
| `"default"` | `Default` |
| `"pointer"` | `Button` |
| `"button"` | `Button` |
| `"move"` | `Move` |
| `"text"` | `TextInput` |
| `"hide"` | `Hide` |
| `"none"` | `Hide` |
| `"resize-ns"` | `ResizeNS` |
| `"resize-we"` | `ResizeWE` |
| `"resize-nwse"` | `ResizeNWSE` |
| `"resize-nesw"` | `ResizeNESW` |

All pre-registered names can be overwritten via `registerCursor()` or removed via `unregisterCursor()`.

**Usage:**
```haxe
// Built-in names work out of the box — no setup needed for standard cursors
// In .manim: cursor => "pointer"  → resolves to hxd.Cursor.Button

// Register a game-specific cursor using Heaps CustomCursor (tile-based sprite)
var bmp = hxd.Res.cursors.crosshair.toBitmapData();
CursorManager.registerCursor("crosshair", Custom(new hxd.Cursor.CustomCursor([bmp], 1, 16, 16)));

// Replace a built-in with custom art
var handBmp = hxd.Res.cursors.hand.toBitmapData();
CursorManager.registerCursor("pointer", Custom(new hxd.Cursor.CustomCursor([handBmp], 1, 0, 0)));

// Animated custom cursor (multiple frames)
var frames = [for (f in sparkFrames) f.toBitmapData()];
CursorManager.registerCursor("magic", Custom(new hxd.Cursor.CustomCursor(frames, 10, 8, 8)));

// Remove a built-in you don't want resolved
CursorManager.unregisterCursor("move");

// Set default for all UI elements (typically Button — the pointer/hand cursor)
CursorManager.setDefaultInteractiveCursor(Button);
```

**Heaps `CustomCursor`** constructor: `new CustomCursor(frames:Array<BitmapData>, fps:Float, offsetX:Int, offsetY:Int)` — offsets are the hotspot position within the cursor image.

**Note:** hx-multianim's UI system uses `MAObject` + `UIControllerBase` for hit-testing, not Heaps' `h2d.Interactive`. So Heaps' automatic cursor management (`SceneEvents`) never kicks in for UI elements — cursor is set manually via `hxd.System.setCursor()` in `UIControllerBase.handleMove()`.

### 8.2 `cursor` keyword in interactive metadata

**Parser change** in `parseInteractiveMetadata()` (MacroManimParser.hx):

Add `cursor` as a recognized keyword (like `events`), parsed as a string value:

```manim
interactive(200, 30, "buyBtn", cursor => "pointer")
interactive(200, 30, "dragArea", cursor => "move")
interactive(200, 30, "label")  // no cursor => uses default from CursorManager
```

Stored as metadata: `{key: "cursor", type: SVTString, value: RVString("pointer")}`.

Name resolution goes through `CursorManager.getCursor(name)` — all built-in Heaps cursors are pre-registered (see §8.1). Custom names registered via `CursorManager.registerCursor()` also resolve here.

### 8.3 UIElementCursor interface

**File:** `src/bh/ui/UIElement.hx`

```haxe
interface UIElementCursor {
    function getCursor():Null<hxd.Cursor>;
}
```

- Returns `null` = no cursor change (leave current cursor alone)
- Returns a `hxd.Cursor` value = set this cursor on hover

**Who implements it:**
- **UIInteractiveWrapper** — reads `cursor` metadata, maps name → `hxd.Cursor`. Falls back to `CursorManager.getDefaultInteractiveCursor()` if no metadata.
- **UIMultiAnimButton** — returns `CursorManager.getDefaultInteractiveCursor()` (typically `Button`)
- **UIMultiAnimCheckbox** — same
- **UIMultiAnimSlider** — same
- **UIMultiAnimDropdown** — same
- **UIMultiAnimTabs** — same
- **UIMultiAnimScrollableList** — same

All built-in components return `getDefaultInteractiveCursor()` so the game controls the cursor centrally. If `setDefaultInteractiveCursor` was never called, it returns `Default` (no change).

### 8.4 Plumbing in UIControllerBase

**File:** `src/bh/ui/controllers/UIControllerBase.hx` — in `handleMove()`:

```
handleMove(mousePoint):
    element = getEventElement(mousePoint)
    ... existing OnEnter/OnLeave logic ...

    // After currentOver is updated:
    if currentOver changed:
        if currentOver != null && currentOver implements UIElementCursor:
            cursor = cast(currentOver, UIElementCursor).getCursor()
            if cursor != null: hxd.System.setCursor(cursor)
            else: hxd.System.setCursor(Default)
        else:
            hxd.System.setCursor(Default)
```

This is the only place cursor logic lives. No per-component cursor management needed.

**Disabled elements:** If `currentOver` implements `UIElementDisablable` and `disabled == true`, skip cursor change (leave Default).

### Summary

| Layer | What | Where |
|-------|------|-------|
| Registration | `CursorManager.registerCursor("name", cursor)` | `CursorManager.hx` (new) |
| Default | `CursorManager.setDefaultInteractiveCursor(Button)` | called at app startup |
| .manim declaration | `cursor => "pointer"` metadata | `MacroManimParser.hx` |
| Interface | `UIElementCursor.getCursor()` | `UIElement.hx` |
| Built-in components | implement `UIElementCursor`, return default | Button, Checkbox, Slider, etc. |
| Interactives | read `cursor` metadata or fall back to default | `UIInteractiveWrapper.hx` |
| Plumbing | check interface on hover enter/leave | `UIControllerBase.handleMove()` |

---

## Priority Ranking

| # | Item | Impact | Effort |
|---|------|--------|--------|
| 1 | Auto positioning with overflow (§3.1) | High — prevents clipped tooltips | Medium |
| 2 | Panel toggle (§4.2) | Medium — common UX pattern | Low |
| 3 | Batch setDisabled (§2.3) | Low — convenience | Low |
| 4 | Per-interactive panel position (§4.1) | Low — parity with tooltip | Low |
| 5 | Tooltip follow mouse (§3.4) | Low — niche use case | Low |
| 6 | Boolean metadata (§5.1) | Low — workaround exists | Low |
| 7 | UIClickOutside naming (§1.3) | Low — docs fix | Low |

## Done

- ~~1.1 outsideClick.handle guard~~ — guarded with switch on OnPush/OnRelease/OnReleaseOutside
- ~~3.2 Tooltip content update~~ — added `updateParams()` and `rebuild()` on UITooltipHelper
- ~~2.2 Cursor change~~ — CursorManager, UIElementCursor interface, per-state cursors on interactives, plumbing in UIControllerBase
