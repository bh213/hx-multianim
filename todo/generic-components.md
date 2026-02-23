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

### Typed interactive event handler

Single callback for all interactive events. Eliminates `Std.isOfType` + cast boilerplate.

```haxe
// On UIScreenBase
var _interactiveHandler:Null<(UIScreenEvent, String, BuilderResolvedSettings) -> Void> = null;

function onInteractiveEvent(callback:(event:UIScreenEvent, id:String, metadata:BuilderResolvedSettings) -> Void):Void {
    _interactiveHandler = callback;
}
```

Checked in `onScreenEvent` before falling through to normal handling. Non-interactive events (sliders, lists, dialogs) still go through the regular `onScreenEvent` override.

---

## Phase 2: Screen-Driven Tooltip & Panel Helpers

The interactive is dumb — it just emits events. The **screen** decides what to do. Helper methods on `UIScreenBase` make common patterns easy while keeping full control in the screen's event handler.

### Design Principle

```
Interactive emits event → onInteractiveEvent handler → screen calls helpers
```

No magic. No auto-wiring from metadata. The screen explicitly decides what happens for each interactive. Metadata (`tooltip => "name"`, `panel => "name"`) is just data the screen can read — it doesn't trigger behavior automatically.

### Setup

```haxe
// In screen load() — provide builder once for tooltip/panel construction
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

    onInteractiveEvent((event, id, meta) -> {
        switch event {
            case UIEntering:
                // Read tooltip name from metadata, or hardcode it
                var tipName = meta.getString("tooltip");
                if (tipName != null)
                    tooltipHelper.startHover(id, tipName, meta.toMap());

            case UILeaving:
                tooltipHelper.cancelHover(id);

            case UIClick:
                var panelName = meta.getString("panel");
                if (panelName != null)
                    panelHelper.open(id, panelName, meta.toMap());

            default:
        }
    });
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

    // Access panel's interactives (for nested interactive events)
    function getPanelResult():Null<BuilderResult>;
}
```

### Why explicit over auto-wired

The screen controls everything:

```haxe
case UIEntering:
    // Conditional tooltip — don't show during drag
    if (!isDragging) {
        tooltipHelper.startHover(id, "priceTip", ["price" => getCurrentPrice(id)]);
    }

case UIClick:
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
| OnEnter | normal | hover | UIEntering |
| OnPush | hover | pressed | UIPush |
| OnRelease | pressed | hover | UIClick |
| OnLeave | hover/pressed | normal | UILeaving |
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
}
```

Usage — screen wires it in the event handler:

```haxe
richHelper = new UIRichInteractiveHelper(this, builder);
richHelper.bind("buyBtn", "shopButton");

onInteractiveEvent((event, id, meta) -> {
    // Rich helper auto-updates visual state for bound interactives
    richHelper.handleEvent(event, id);

    // Then screen does its own logic
    switch event {
        case UIClick:
            if (id == "buyBtn") purchase();
        default:
    }
});
```

Or if the screen wants full manual control, skip the helper and call `setParameter` directly:

```haxe
case UIEntering:
    myBuiltResult.setParameter("status", "hover");
case UILeaving:
    myBuiltResult.setParameter("status", "normal");
```

---

## Summary

| Phase | What | Pattern |
|-------|------|---------|
| 1 | Map lookup + typed event handler | Foundation for everything else |
| 2 | `UITooltipHelper` + `UIPanelHelper` | Screen calls helpers from event handler |
| 3 | `UIRichInteractiveHelper` | Screen calls helper to manage visual state |

All three follow the same principle: **interactive emits, screen decides, helpers do the work**.
