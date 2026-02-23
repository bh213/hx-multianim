# Interactive Improvements

## Phase 1: Foundation

### Interactive lookup by ID

`Map<String, UIInteractiveWrapper>` for O(1) lookup. Kept in sync by `addInteractive` / `removeInteractives`.

```haxe
// On UIScreenBase
var interactiveMap:Map<String, UIInteractiveWrapper> = [];

function getInteractive(id:String):Null<UIInteractiveWrapper> {
    return interactiveMap.get(id);
}

function getInteractivesByPrefix(prefix:String):Array<UIInteractiveWrapper> {
    return [for (w in interactiveWrappers) if (w.prefix == prefix) w];
}
```

### UIInteractiveEvent — new UIScreenEvent variant

Interactives emit a single wrapped event instead of raw UIClick/UIEntering/etc. No separate callback, no casting — just pattern match in `onScreenEvent`.

```haxe
enum UIScreenEvent {
    // ... existing (UIClick, UIEntering, UILeaving, UIPush stay for buttons/lifecycle) ...
    UIInteractiveEvent(event:UIScreenEvent, id:String, metadata:BuilderResolvedSettings);
}
```

UIInteractiveWrapper changes — emits `UIInteractiveEvent` wrapping the inner event:

```haxe
// UIInteractiveWrapper.onEvent()
case OnRelease(_):
    wrapper.control.pushEvent(UIInteractiveEvent(UIClick, this.id, this.metadata), this);
case OnPush(_):
    wrapper.control.pushEvent(UIInteractiveEvent(UIPush, this.id, this.metadata), this);
case OnEnter:
    hovered = true;
    wrapper.control.pushEvent(UIInteractiveEvent(UIEntering, this.id, this.metadata), this);
case OnLeave:
    hovered = false;
    wrapper.control.pushEvent(UIInteractiveEvent(UILeaving, this.id, this.metadata), this);
```

Screen usage — id and metadata available directly in the pattern match:

```haxe
override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
    switch event {
        case UIInteractiveEvent(UIClick, id, meta):
            trace('clicked $id');
        case UIInteractiveEvent(UIEntering, id, meta):
            trace('hover $id');
        case UIInteractiveEvent(UILeaving, id, meta):
            trace('leave $id');
        case UIChangeValue(v):
            // slider — unchanged
        default:
    }
}
```

No backward compat needed — no internal components consume UIClick/UIEntering/UILeaving from interactives. ScreenManager uses UIEntering/UILeaving for screen lifecycle with `source: null`, which is unrelated.

---

## Phase 2: Screen-Driven Tooltip & Panel Helpers

The interactive is dumb — it just emits events. The **screen** decides what to do. Helper methods make common patterns easy while keeping full control in the screen's event handler.

### Design Principle

```
Interactive emits UIInteractiveEvent → screen's onScreenEvent → screen calls helpers
```

No magic. No auto-wiring from metadata. The screen explicitly decides what happens for each interactive. Metadata (`tooltip => "name"`, `panel => "name"`) is just data the screen can read — it doesn't trigger behavior automatically.

### Setup

```haxe
var tooltipHelper:UITooltipHelper;
var panelHelper:UIPanelHelper;

override function load() {
    tooltipHelper = new UITooltipHelper(this, builder, {
        delay: 0.3,
        position: Above,
        offset: 4,
        layer: ModalLayer,
    });

    panelHelper = new UIPanelHelper(this, builder, {
        closeOn: OutsideClick,
        position: Below,
        layer: ModalLayer,
    });

    var result = builder.buildWithParameters("shopUI", params);
    addBuilderResult(result);
    addInteractives(result);
}

override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
    switch event {
        case UIInteractiveEvent(UIEntering, id, meta):
            var tipName = meta.getString("tooltip");
            if (tipName != null)
                tooltipHelper.startHover(id, tipName, meta.toMap());

        case UIInteractiveEvent(UILeaving, id, meta):
            tooltipHelper.cancelHover(id);

        case UIInteractiveEvent(UIClick, id, meta):
            var panelName = meta.getString("panel");
            if (panelName != null)
                panelHelper.open(id, panelName, meta.toMap());
            else
                handleClick(id, meta);

        default:
    }
}

override function update(dt:Float) {
    super.update(dt);
    tooltipHelper.update(dt);
}
```

### UITooltipHelper API

```haxe
class UITooltipHelper {
    function new(screen:UIScreenBase, builder:MultiAnimBuilder, defaults:TooltipDefaults);

    // Called from event handler
    function startHover(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>):Void;
    function cancelHover(interactiveId:String):Void;

    // Manual show/hide (bypasses delay)
    function show(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>):Void;
    function hide():Void;

    // Per-interactive overrides
    function setDelay(interactiveId:String, delay:Float):Void;
    function setPosition(interactiveId:String, position:Position):Void;

    // Called from screen update()
    function update(dt:Float):Void;
}
```

Flow:
```
startHover("buyBtn", "priceTooltip", params)
  → internal timer starts (0.3s default)
  → timer elapses → builds programmable, positions relative to interactive, adds to layer
cancelHover("buyBtn")
  → timer cancelled OR tooltip hidden
```

### UIPanelHelper API

```haxe
class UIPanelHelper {
    function new(screen:UIScreenBase, builder:MultiAnimBuilder, defaults:PanelDefaults);

    // Called from event handler
    function open(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>):Void;
    function close():Void;
    function isOpen():Bool;

    // Auto-close on outside click — pass event from onScreenEvent, returns true if closed
    // Handles UIClickOutside (via controller's trackOutsideClick) and UIClick on unrelated interactive
    function handleOutsideClick(event:UIScreenEvent):Bool;

    // Access panel's interactives (for nested interactive events)
    function getPanelResult():Null<BuilderResult>;
}
```

### Why explicit over auto-wired

The screen controls everything:

```haxe
case UIInteractiveEvent(UIEntering, id, meta):
    // Conditional tooltip — don't show during drag
    if (!isDragging)
        tooltipHelper.startHover(id, "priceTip", ["price" => getCurrentPrice(id)]);

case UIInteractiveEvent(UIClick, id, meta):
    // Different panel based on game state
    if (isShopOpen)
        panelHelper.open(id, "buyConfirm", ["item" => id]);
    else
        panelHelper.open(id, "shopClosed");
```

No config objects to mutate, no `cancelled` flags. The screen just doesn't call the helper if it doesn't want the behavior.

---

## Phase 3: Rich Interactive (Visual State)

### Concept

Connect an interactive to a programmable that provides visual feedback via `status` parameter. Same event-driven pattern — the screen (or a helper) manages the state transitions.

### .manim declaration

```manim
#shopButton programmable(status:[normal,hover,pressed,disabled]=normal, width:int=120, height:int=40) {
    @(status => normal)   ninepatch(sheet("ui"), "btnNormal", $width, $height): 0, 0
    @(status => hover)    ninepatch(sheet("ui"), "btnHover", $width, $height): 0, 0
    @(status => pressed)  ninepatch(sheet("ui"), "btnPress", $width, $height): 0, 0
    @(status => disabled) ninepatch(sheet("ui"), "btnDim", $width, $height): 0, 0
}
```

### State transitions

| Input | From | To | Event emitted |
|-------|------|----|---------------|
| OnEnter | normal | hover | UIInteractiveEvent(UIEntering, ...) |
| OnPush | hover | pressed | UIInteractiveEvent(UIPush, ...) |
| OnRelease | pressed | hover | UIInteractiveEvent(UIClick, ...) |
| OnLeave | hover/pressed | normal | UIInteractiveEvent(UILeaving, ...) |
| programmatic | any | disabled | — |

### UIRichInteractiveHelper

```haxe
class UIRichInteractiveHelper {
    function new(screen:UIScreenBase, builder:MultiAnimBuilder);

    // Bind a visual programmable to an interactive
    function bind(interactiveId:String, buildName:String, ?extraParams:Map<String, Dynamic>):Void;

    // Unbind
    function unbind(interactiveId:String):Void;

    // Programmatic state
    function setDisabled(interactiveId:String, disabled:Bool):Void;

    // Call from onScreenEvent for bound interactives
    function handleEvent(event:UIScreenEvent, id:String):Void;
}
```

Usage:

```haxe
richHelper = new UIRichInteractiveHelper(this, builder);
richHelper.bind("buyBtn", "shopButton");

override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
    switch event {
        case UIInteractiveEvent(_, id, meta):
            richHelper.handleEvent(event, id);

        case UIInteractiveEvent(UIClick, id, meta):
            if (id == "buyBtn") purchase();

        default:
    }
}
```

Or full manual control without the helper:

```haxe
case UIInteractiveEvent(UIEntering, id, _):
    myBuiltResult.setParameter("status", "hover");
case UIInteractiveEvent(UILeaving, id, _):
    myBuiltResult.setParameter("status", "normal");
```

---

## Summary

| Phase | What | Pattern |
|-------|------|---------|
| 1 | Map lookup + `UIInteractiveEvent` variant | Foundation — no casting, pattern match |
| 2 | `UITooltipHelper` + `UIPanelHelper` | Screen calls helpers from onScreenEvent |
| 3 | `UIRichInteractiveHelper` | Screen calls helper to manage visual state |

All three follow the same principle: **interactive emits `UIInteractiveEvent`, screen decides, helpers do the work**.
