# Text Input Component — Design Plan

## Heaps Foundation: h2d.TextInput

Heaps provides `h2d.TextInput` (extends `h2d.Text`) with solid built-in support:

| Feature | Status |
|---------|--------|
| Cursor (blinking, navigable) | Built-in |
| Text selection (mouse + keyboard) | Built-in |
| Clipboard (Ctrl+C/X/V) | Built-in (platform-dependent) |
| Undo/Redo (Ctrl+Z/Y) | Built-in (100-entry history) |
| Multiline + line navigation | Built-in (`multiline: Bool`) |
| Input width masking + scroll | Built-in (`inputWidth`) |
| Read-only mode | Built-in (`canEdit: false`) |
| Double-click word select | Built-in |
| Cursor/selection tile skinning | Built-in (`cursorTile`, `selectionTile`) |
| `loadState()` transfer | Built-in (cursor, selection, undo, scroll) |
| `onChange()` callback | Built-in |
| `onFocus()` / `onFocusLost()` | Built-in |

**Not built-in** (we must implement): placeholder text, max length, character filtering, password masking, visual frame/background from .manim, focus styling.

---

## Component Design

### .manim Programmable Contract

The component requires two **reserved parameters** (driven internally) and one **named element**. Everything else is up to the .manim author and configurable via settings.

**Required by the component:**
- `status:[normal,hover,focused,disabled]=normal` — driven by focus/hover events
- `placeholder:bool=true` — driven by content/focus state
- `#textArea point` — anchor where h2d.TextInput is placed as child

**Optional design parameters** (controlled via pass-through settings):
- `width`, `height`, `placeholderText`, `frameColor`, custom tiles — whatever the .manim declares

Minimal example:
```manim
#textInput programmable(
    status:[normal,hover,focused,disabled]=normal,
    placeholder:bool=true,
    width:uint=200,
    height:uint=24,
    placeholderText:string=Type here...
) {
    @(status=>normal)   ninepatch(sheet, frameNormal, $width, $height): 0, 0
    @(status=>hover)    ninepatch(sheet, frameHover, $width, $height): 0, 0
    @(status=>focused)  ninepatch(sheet, frameFocused, $width, $height): 0, 0
    @(status=>disabled) ninepatch(sheet, frameDisabled, $width, $height): 0, 0

    @(placeholder=>true) text(font, $placeholderText, #888888): 4, 4

    #textArea point: 4, 4
}
```

Fancier example with configurable colors and an icon slot:
```manim
#textInput programmable(
    status:[normal,hover,focused,disabled]=normal,
    placeholder:bool=true,
    width:uint=200,
    height:uint=24,
    placeholderText:string=Search...,
    borderColor:color=#555555,
    bgColor:color=#222222,
    focusBorderColor:color=#4488FF
) {
    // Background
    bitmap(generated(color($width, $height, $bgColor))): 0, 0

    // Border (different color when focused)
    @(status=>focused) graphics(rect(0, 0, $width, $height, $focusBorderColor, 1)): 0, 0
    @(status=>normal)  graphics(rect(0, 0, $width, $height, $borderColor, 1)): 0, 0
    @(status=>hover)   graphics(rect(0, 0, $width, $height, $borderColor, 1)): 0, 0

    // Icon slot (optional — game can put a search icon here)
    #icon slot: 4, 4

    // Placeholder
    @(placeholder=>true) text(font, $placeholderText, #666666): 24, 4

    // Text input anchor (offset to leave room for icon)
    #textArea point: 24, 4
}
```

The component doesn't care about the visual structure — it only touches `status`, `placeholder`, and `#textArea`. All other parameters are fully controlled by settings pass-through.

### Why overlay h2d.TextInput instead of reimplementing?

`h2d.TextInput` handles cursor rendering, selection highlight, clipboard, undo/redo, mouse-to-character mapping, horizontal scrolling, and multiline navigation. Reimplementing any of this would be fragile and massive. The component's job is: skin the frame via .manim, manage focus/hover states, and add missing features (placeholder, filtering, max length) as thin wrappers.

---

## Class: UIMultiAnimTextInput

```
UIElement
├── StandardUIElementEvents      (hover/click/focus dispatch)
├── UIElementDisablable          (disabled state)
├── UIElementText                (setText/getText for the input value)
├── UIElementCursor              (I-beam cursor on hover)
├── UIElementUpdatable           (cursor blink, placeholder sync)
```

### Proposed API

```haxe
class UIMultiAnimTextInput implements UIElement
    implements StandardUIElementEvents
    implements UIElementDisablable
    implements UIElementText
    implements UIElementCursor
    implements UIElementUpdatable
{
    // --- State ---
    public var text(get, set):String;          // current input value
    public var placeholder:String;              // hint text shown when empty+unfocused
    public var maxLength:Int;                   // 0 = unlimited
    public var readOnly:Bool;                   // delegates to textInput.canEdit
    public var multiline:Bool;                  // delegates to textInput.multiline

    // --- Filtering ---
    public var filter:Null<TextInputFilter>;    // optional character filter

    // --- Callbacks ---
    public dynamic function onChange():Void;          // text content changed
    public dynamic function onSubmit():Void;          // Enter pressed (single-line mode)
    public dynamic function onFocusChange(focused:Bool):Void;

    // --- UIElement ---
    public function getObject():h2d.Object;
    public function containsPoint(x:Float, y:Float):Bool;
    public function clear():Void;

    // --- UIElementText ---
    public function setText(text:String):Void;
    public function getText():String;

    // --- UIElementDisablable ---
    public var disabled(default, set):Bool;

    // --- UIElementCursor ---
    public function getCursor():hxd.Cursor;    // TextInput cursor (I-beam)

    // --- UIElementUpdatable ---
    public function update(dt:Float):Void;     // placeholder visibility sync

    // --- Focus ---
    public function focus():Void;
    public function blur():Void;
    public function hasFocus():Bool;
}
```

### TextInputFilter

```haxe
enum TextInputFilter {
    FNumericOnly;                    // digits only
    FAlphanumeric;                   // letters + digits
    FCustom(fn:String->String);      // arbitrary transform (applied in onChange)
}
```

Filter is applied in `onChange` — if the filter rejects characters, text is corrected and cursor repositioned. This avoids fighting with `h2d.TextInput`'s internal char insertion.

---

## Settings (UIScreen.addTextInput)

Uses the standard `splitSettings()` pattern. Settings are split into three categories:

### Control Settings (consumed by `addTextInput`, not forwarded)

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `buildName` | string | `"textInput"` | Programmable name |
| `text` | string | `""` | Initial text value |
| `placeholder` | string | `""` | Placeholder hint text |
| `font` | string | (required) | Font name for h2d.TextInput |
| `fontColor` | color | `white` | h2d.TextInput text color |
| `cursorColor` | color | `white` | Cursor tile color |
| `selectionColor` | color | `#3399FF` | Selection highlight color |

### Behavioral Settings (consumed by `addTextInput`, not forwarded)

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `maxLength` | int | `0` | Max characters (0 = unlimited) |
| `multiline` | bool | `false` | Allow newlines |
| `readOnly` | bool | `false` | Read-only mode |
| `disabled` | bool | `false` | Disabled state |
| `filter` | string | `none` | `"numeric"`, `"alphanumeric"`, or `"none"` |
| `tabIndex` | int | (auto) | Tab navigation order |

### Pass-Through Settings (forwarded to .manim programmable)

Everything else is forwarded as extra parameters to `buildWithParameters()`, exactly like button/slider/checkbox. The .manim programmable must declare matching parameters.

```haxe
// Example: the programmable declares width/height/placeholderText params
addTextInput(builder, [
    "buildName" => "textInput",          // control — consumed
    "font" => "main",                    // control — consumed
    "text" => "hello",                   // control — consumed
    "placeholder" => "Type here...",     // control — consumed, but also forwarded as "placeholderText"
    "maxLength" => "50",                 // behavioral — consumed
    "width" => "200",                    // pass-through → programmable $width
    "height" => "30",                    // pass-through → programmable $height
    "frameColor:color" => "#334455",     // pass-through → programmable $frameColor
]);
```

This means the .manim programmable fully controls the visual design. A simple frame:

```manim
#textInput programmable(
    status:[normal,hover,focused,disabled]=normal,
    placeholder:bool=true,
    width:uint=200,
    height:uint=24,
    placeholderText:string=Type here...
) {
    @(status=>normal)   ninepatch(sheet, frameNormal, $width, $height): 0, 0
    @(status=>hover)    ninepatch(sheet, frameHover, $width, $height): 0, 0
    @(status=>focused)  ninepatch(sheet, frameFocused, $width, $height): 0, 0
    @(status=>disabled) ninepatch(sheet, frameDisabled, $width, $height): 0, 0

    @(placeholder=>true) text(font, $placeholderText, #888888): 4, 4

    #textArea point: 4, 4
}
```

Or a fancy one with icons, different backgrounds, border colors — whatever the .manim author wants. The component doesn't care about the visual structure, it only needs:
- `status` and `placeholder` parameters (driven by the component)
- `#textArea` named point (where h2d.TextInput is placed)

### Placeholder text forwarding

The `placeholder` *setting* (string, the hint text) is forwarded to the programmable as `placeholderText` parameter so the .manim can render it. The `placeholder` *programmable parameter* (bool) is driven by the component to show/hide it. These are separate: one is content, the other is visibility.

---

## Events

| Event | When |
|-------|------|
| `UITextChange(text:String)` | Text content changed by user |
| `UITextSubmit(text:String)` | Enter pressed (single-line) / Ctrl+Enter (multiline) |
| `UIFocusChange(focused:Bool)` | Input gained/lost focus |

These would be added to the `UIScreenEvent` enum.

---

## Internal Wiring

### Construction Flow

```
addTextInput(builder, settings)
  → splitSettings(settings,
        control: ["buildName", "text", "placeholder", "font", "fontColor",
                  "cursorColor", "selectionColor"],
        behavioral: ["maxLength", "multiline", "readOnly", "disabled",
                     "filter", "tabIndex"])
  → pass-through params (split.main) include: width, height, placeholderText, etc.
  → forward placeholder string → "placeholderText" in pass-through params
  → builder.buildWithParameters(buildName, passThrough, incremental:true)
  → create h2d.TextInput with resolved font from FontManager
  → configure: inputWidth (from #textArea to frame edge), cursorTile, selectionTile
  → place TextInput at #textArea named point position
  → wire events:
      h2d.TextInput.onChange → apply filter, push UITextChange
      h2d.TextInput.onFocus → setParameter("status", "focused"), push UIFocusChange(true)
      h2d.TextInput.onFocusLost → setParameter("status", "normal"), push UIFocusChange(false)
  → wire hover (from outer interactive or containsPoint):
      enter → if !focused: setParameter("status", "hover")
      leave → if !focused: setParameter("status", "normal")
  → set up placeholder visibility sync in update(dt)
  → if tabGroup exists: tabGroup.add(input, tabIndex)
```

### Placeholder Logic

```
update(dt):
  showPlaceholder = text.length == 0 && !hasFocus()
  result.setParameter("placeholder", showPlaceholder ? "true" : "false")
```

Placeholder is a .manim text element controlled by the `placeholder` parameter. When the user types or focuses, it hides. When blur + empty, it shows. This avoids swapping the actual TextInput text (which would break undo history).

### Focus Management

`h2d.TextInput` manages its own focus via `h2d.Interactive` internally. The component listens to `onFocus`/`onFocusLost` callbacks to drive the .manim `status` parameter. No custom focus management needed — Heaps handles it.

### Cursor/Selection Skinning

```haxe
// In construction:
var font = FontManager.getFont(fontName);
textInput = new h2d.TextInput(font);
textInput.textColor = fontColor;
textInput.inputWidth = width;
textInput.cursorTile = h2d.Tile.fromColor(cursorColor, 1, font.lineHeight);
textInput.selectionTile = h2d.Tile.fromColor(selectionColor, 0, font.lineHeight);
```

### State Transfer on Rebuild

If the component needs to be rebuilt (e.g., hot-reload), use `h2d.TextInput.loadState(oldInput)` to preserve cursor position, selection, undo history, and scroll state.

---

## Password Mode (Future Extension)

Not in v1. If needed later:
- Add `password:bool` setting
- Override `h2d.TextInput` to display dots/asterisks while keeping real text internally
- Or maintain a shadow `realText` string and set `textInput.text` to `"***"` on every change

---

## Implementation Phases

### Phase 1: Core Single-Line Input
- `UIMultiAnimTextInput` class with incremental .manim frame
- Settings: `buildName`, `text`, `placeholder`, `font`, `fontColor`, `width`, `maxLength`
- Events: `UITextChange`, `UITextSubmit`, `UIFocusChange`
- `UIScreen.addTextInput()` helper
- Hover/focus/disabled status cycling
- Placeholder show/hide logic
- Character cursor (I-beam) on hover
- Tab key suppression in TextInput (don't consume Tab)

### Phase 2: Tab Navigation
- `UITabGroup` helper class
- `UIScreenBase.enableTabNavigation()` + auto-registration in `addTextInput()`
- Tab/Shift+Tab cycling with wrap-around
- `tabIndex` setting for explicit ordering
- Escape to blur
- `enterAdvances` option for submit-to-next

### Phase 3: Filtering & Validation
- `TextInputFilter` enum + `filter` setting
- Max length enforcement
- Visual error state? (needs design — could be a `status` value like `error` driven by game code)

### Phase 4: Multiline
- `multiline` setting → `h2d.TextInput.multiline = true`
- Ctrl+Enter for submit in multiline mode
- Height auto-grow or fixed with scroll (fixed+mask is simpler, auto-grow needs layout integration)

### Phase 5: Codegen Support
- `@:manim` field generates typed factory with `createTextInput()` returning `UIMultiAnimTextInput`
- `ProgrammableCodeGen` emits construction code similar to button/slider pattern

---

## Tab Navigation Between Inputs

### Problem

Heaps has no built-in tab order. `h2d.TextInput` consumes Tab as a key event (inserts tab chars if `insertTabs` is set, otherwise ignores). Multiple text inputs on a screen need Tab/Shift+Tab to cycle focus — standard form behavior users expect.

### Scope: Text Inputs Only

Tab navigation targets only `UIMultiAnimTextInput` elements, not buttons/checkboxes/sliders. Rationale: text inputs are the only focusable UI elements (they own a `h2d.TextInput` with real keyboard focus). Buttons etc. are click-only — adding keyboard focus to them is a separate, larger feature (full keyboard/gamepad navigation) that doesn't belong here.

### Design: UITabGroup

A lightweight helper owned by `UIScreenBase`, similar to `UITooltipHelper`/`UIPanelHelper`. Not a framework-level change — screens opt in.

```haxe
class UITabGroup {
    var inputs:Array<UIMultiAnimTextInput>;  // ordered by tabIndex

    function add(input:UIMultiAnimTextInput, ?tabIndex:Int):Void;
    function remove(input:UIMultiAnimTextInput):Void;
    function clear():Void;

    // Called from screen's onScreenEvent on UIKeyPress(Tab, false)
    function handleTab(shift:Bool):Bool;  // returns true if consumed

    function focusFirst():Void;           // focus lowest tabIndex
    function focusByIndex(tabIndex:Int):Void;
}
```

### Tab Index Assignment

Two modes:

**Explicit** — `tabIndex` setting on `addTextInput()`:
```haxe
addTextInput(builder, ["tabIndex" => "1", "font" => "main", ...]);
addTextInput(builder, ["tabIndex" => "2", "font" => "main", ...]);
```

**Automatic** — if no `tabIndex`, assigned in `add()` order (insertion order = tab order). This is the common case — most forms just want top-to-bottom tab cycling without numbering.

### Integration with Controller

The controller already dispatches `UIKeyPress(keyCode, release)` to the screen via `handleKey()` in `UIControllerBase`. The screen intercepts Tab:

```haxe
// In UIScreenBase or screen subclass:
override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
    switch event {
        case UIKeyPress(keyCode, false):
            if (keyCode == hxd.Key.TAB && tabGroup != null) {
                if (tabGroup.handleTab(hxd.Key.isDown(hxd.Key.SHIFT)))
                    return;  // consumed
            }
        default:
    }
    // ... rest of event handling
}
```

### Key Handling Detail

**Problem:** `h2d.TextInput` receives the `EKeyDown(Tab)` event *before* the controller's `handleKey` fires (Heaps interactive events propagate bottom-up through the scene). The TextInput may consume it.

**Solution:** `UIMultiAnimTextInput` intercepts `onKeyDown` on its internal `h2d.TextInput` and suppresses Tab:

```haxe
// Inside UIMultiAnimTextInput construction:
textInput.onKeyDown = function(e:hxd.Event) {
    if (e.keyCode == hxd.Key.TAB) {
        // Don't let TextInput consume Tab — let it bubble to controller
        // The controller's handleKey will fire UIKeyPress, screen handles it
        return;
    }
};
```

This way Tab never inserts characters or gets swallowed. The controller picks it up and the screen routes it to `UITabGroup.handleTab()`.

### Wrap-Around & Escape

- Tab on last input → wraps to first
- Shift+Tab on first → wraps to last
- Escape while focused → blur current input (no focus cycling)

### UIScreen Helper

```haxe
// Convenience on UIScreenBase:
public function addTextInput(builder, settings):UIMultiAnimTextInput {
    var input = /* ... create ... */;
    // Auto-add to tab group if it exists
    if (tabGroup != null) {
        tabGroup.add(input, settings.getIntOrDefault("tabIndex", -1));
    }
    return input;
}

public function enableTabNavigation():UITabGroup {
    tabGroup = new UITabGroup();
    return tabGroup;
}
```

### Submit-to-Next Pattern

Common UX: pressing Enter in a single-line input moves focus to the next input instead of (or in addition to) firing submit. Supported via a flag:

```haxe
class UITabGroup {
    public var enterAdvances:Bool = false;  // Enter moves to next input
}
```

When `enterAdvances` is true, `UITextSubmit` still fires, but focus also advances. Game code can set this per-screen.

---

## Open Questions

1. **Height sizing** — Should the .manim programmable control the height, or should height be derived from font metrics + padding? Leaning toward .manim controls the frame size, TextInput is placed inside at `#textArea` with `inputWidth` from settings.

2. **Scroll for long single-line text** — `h2d.TextInput` handles horizontal scroll via `inputWidth` automatically. Just need to make sure the mask/clip is correctly aligned with the .manim frame.

3. **Integration with existing interactive system** — TextInput could implement `UIElementIdentifiable` for interactive metadata access (e.g., `id`, `prefix`). Useful if a screen has multiple text inputs and needs to distinguish them in `onScreenEvent`.

4. **Auto-grow multiline** — Worth doing? Would need to notify parent layout (Flow) of size changes. Could start with fixed-size multiline and add auto-grow later if needed.

5. **Tab group per-screen vs global** — One `UITabGroup` per screen is the natural scope (screens already own their elements). But what about modal panels that contain text inputs? Probably: modal gets its own tab group, pushed/popped with the panel.
