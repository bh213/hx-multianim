# Tooltips & Panels on Interactives — Planning

## Core Idea

Interactives already carry typed metadata. Add two reserved metadata keys — `tooltip` and `panel` — that reference programmables in the same file. Tooltip/panel lifecycle flows through `onEvent` / `onScreenEvent`, giving screens full control to intercept, modify, or cancel.

---

## 1. .manim Declaration

```manim
version: 0.5

#shopButton programmable(item:string="sword", price:int=100) {
    // the main UI
    interactive(120, 40, "buyBtn", tooltip => "priceTooltip", panel => "itemDetail")
    interactive(80, 30, "info", tooltip => "helpTip")
}

// tooltip programmables — built on hover, receive parent's params
#priceTooltip programmable(price:int=0) {
    ninepatch(sheet("ui"), "tooltipBg", 100, 24): 0, 0
    text(small, "$price gold", #FFD700): 8, 4
}

// panel programmables — built on click, receive parent's params
#itemDetail programmable(item:string="", price:int=0) {
    ninepatch(sheet("ui"), "panelBg", 200, 150): 0, 0
    text(normal, "$item", #FFFFFF): 10, 10
    text(small, "Cost: $price", #FFD700): 10, 30
    interactive(80, 24, "buy"): 60, 110
}
```

Key points:
- `tooltip => "priceTooltip"` and `panel => "itemDetail"` are just metadata strings referencing programmable names
- The tooltip/panel programmables are standalone — they can have their own params
- Parent parameters are automatically forwarded by name-match (like how flow settings forward today)

---

## 2. Event-Driven Lifecycle (Revised)

Instead of the tooltip/panel controller acting autonomously, **all tooltip/panel actions flow through `onScreenEvent`**. The screen can intercept, modify, or cancel at every step.

### New UIScreenEvent variants

```haxe
enum UIScreenEvent {
    // ... existing ...
    UITooltipRequest(config:TooltipConfig);   // hover delay elapsed — about to show
    UITooltipHide;                            // tooltip being hidden (mouse left)
    UIPanelRequest(config:PanelConfig);       // click occurred — about to open panel
    UIPanelClose;                             // panel being closed
}
```

### TooltipConfig / PanelConfig — mutable request objects

```haxe
class TooltipConfig {
    public var buildName:String;       // programmable name (from metadata)
    public var params:Map<String, Dynamic>;  // params to pass (auto-forwarded from parent)
    public var position:Position;      // Above, Below, Left, Right, Auto
    public var offset:Int;             // gap in pixels
    public var cancelled:Bool;         // set true to prevent showing
}

class PanelConfig {
    public var buildName:String;
    public var params:Map<String, Dynamic>;
    public var position:Position;
    public var closeOn:CloseMode;      // OutsideClick, AnyClick, Manual
    public var cancelled:Bool;
}
```

### Screen-side usage

```haxe
override function onScreenEvent(event, source) {
    switch event {
        case UITooltipRequest(config):
            var src:UIElementIdentifiable = cast source;

            // Modify params dynamically
            config.params["price"] = getCurrentPrice(src.id);

            // Change position for specific interactive
            if (src.id == "bottomItem") config.position = Above;

            // Cancel tooltip entirely (e.g., during drag)
            if (isDragging) config.cancelled = true;

            // Swap to a different programmable
            if (src.id == "special") config.buildName = "specialTooltip";

        case UITooltipHide:
            // optional cleanup

        case UIPanelRequest(config):
            // same pattern — modify/cancel before panel opens
            config.params["item"] = getSelectedItem();

        case UIPanelClose:
            // panel closed — cleanup

        case UIClick:
            // regular click handling (still works for non-panel interactives)
    }
}
```

### Flow diagram

```
Hover enter → timer starts
                ↓ (delay elapsed)
        UITooltipRequest(config) → onScreenEvent()
                ↓                     ↓
          config.cancelled?     screen modifies config
                ↓ no
        controller builds & shows tooltip
                ↓
Hover leave → UITooltipHide → onScreenEvent()
                ↓
        controller hides tooltip


Click → UIPanelRequest(config) → onScreenEvent()
                ↓                     ↓
          config.cancelled?     screen modifies config
                ↓ no
        controller builds & shows panel
                ↓
Outside click → UIPanelClose → onScreenEvent()
                ↓
        controller hides panel
```

The controller handles mechanics (delay, positioning, building, layer management). The screen handles decisions (what to show, whether to show, dynamic data).

---

## 3. Screen API — Setup

```haxe
// Enable tooltip/panel support for this screen
enableTooltips(builder, {
    delay: 0.3,           // hover delay before UITooltipRequest fires (default 0.3s)
    position: Above,      // default position (overridable per-request in onScreenEvent)
    offset: 4,            // default gap
    layer: ModalLayer,    // which layer (default: one above interactive's layer)
});

enablePanels(builder, {
    closeOn: OutsideClick,// default close behavior
    position: Below,      // default position
    transition: Fade(0.15),
    layer: ModalLayer,
});
```

That's still the only setup needed. But now all control flows through events.

### Manual registration (for interactives without metadata)

```haxe
// Register tooltip for an interactive that doesn't have tooltip metadata
setTooltip("buyBtn", "priceTooltip");

// Register panel
setPanel("buyBtn", "itemDetail");

// Runtime removal
removeTooltip("buyBtn");
removePanel("buyBtn");
```

Simpler than before — no params/callbacks in the registration. All dynamic behavior lives in `onScreenEvent`.

---

## 4. Panel Events — Nested Interactives

Panels can contain their own interactives. Events bubble up through the same `onScreenEvent`:

```haxe
case UIClick:
    var src:UIElementIdentifiable = cast source;
    switch src.id {
        case "buyBtn.itemDetail.buy":
            // click on "buy" interactive inside the "itemDetail" panel
            // prefix chain: interactive.panel.nestedInteractive
    }
```

The panel's interactives get a compound prefix: `{parentId}.{panelName}.{childId}`.

Nested tooltips also work — a panel interactive with `tooltip` metadata fires its own `UITooltipRequest`.

---

## 5. Implementation Architecture

Reuses existing patterns:

| Concern | Existing Pattern | Reuse |
|---------|-----------------|-------|
| Floating layer | Dropdown's `UIElementCustomAddToLayer` | Tooltip/panel placed on higher layer |
| Position anchoring | Dropdown's `PositionLinkObject` | Anchor tooltip to interactive's position |
| Outside click close | `Controllable.outsideClick.trackOutsideClick()` | Panels close on outside click |
| Content building | `builder.buildWithParameters()` | Build tooltip/panel programmable on demand |
| Hover detection | `UIInteractiveWrapper.hovered` + events | Already exists |
| Timer/delay | New — in `update(dt)` | Small addition to screen |
| Event flow | `pushEvent(UIScreenEvent, source)` | Existing event pipeline |

New classes needed:
- **`UITooltipController`** — manages hover timers, fires `UITooltipRequest`/`UITooltipHide`, builds/positions/shows/hides if not cancelled
- **`UIPanelController`** — manages click-to-open, fires `UIPanelRequest`/`UIPanelClose`, builds/positions, outside-click-to-close
- Both owned by `UIScreenBase`, updated in `update(dt)`

---

## 6. Positioning Logic

```
        ┌─────────┐
        │ tooltip  │  ← Above (default for tooltips)
        └─────────┘
             ↕ offset
    ┌────────────────────┐
    │    interactive      │
    └────────────────────┘
             ↕ offset
        ┌─────────────┐
        │   panel     │  ← Below (default for panels)
        │             │
        └─────────────┘
```

`Auto` positioning checks screen bounds and flips if the tooltip/panel would overflow. Same logic handles Left/Right.

---

## 7. Optional: Tooltip-only Shorthand

For simple text tooltips that don't need a full programmable:

```manim
interactive(120, 40, "buyBtn", tooltipText => "Click to purchase")
```

The screen uses a built-in default tooltip programmable with a text parameter. The screen can still intercept `UITooltipRequest` to modify the text dynamically.

---

## 8. Why Event-Driven is Better

| Concern | Old approach (callbacks) | Event-driven (onScreenEvent) |
|---------|------------------------|------------------------------|
| Dynamic params | `updateTooltipParams()` API | Modify `config.params` in event handler |
| Cancel tooltip | `removeTooltip()` before show | `config.cancelled = true` |
| Swap content | `setTooltip()` with new buildName | `config.buildName = "other"` |
| Context-aware | Separate callback per interactive | Single `onScreenEvent` switch, full screen state available |
| Learning curve | New API to learn | Same `onScreenEvent` pattern screens already use |
| Composability | Callbacks don't compose well | Events compose naturally with existing UIClick/UIEntering handlers |

---

## Summary

| Feature | Declaration | Setup | Control |
|---------|------------|-------|---------|
| Simple text tooltip | `tooltipText => "..."` | `enableTooltips(builder)` | `UITooltipRequest` in onScreenEvent |
| Rich tooltip | `tooltip => "progName"` | `enableTooltips(builder)` | `UITooltipRequest` — modify config |
| Panel/popup | `panel => "progName"` | `enablePanels(builder)` | `UIPanelRequest` — modify config |
| Cancel | — | — | `config.cancelled = true` |
| Manual registration | — | `setTooltip(id, buildName)` | same event flow |

Key benefits:
- **Zero new .manim syntax** — just interactive metadata
- **Zero new screen patterns** — uses existing `onScreenEvent`
- **Full control** — screen can modify, cancel, or swap any tooltip/panel at the moment it's about to appear
- **Composable** — tooltip/panel events sit alongside UIClick/UIEntering in the same handler
