# Generic Components Plan

## Goal

Allow any programmable to be used as a reusable **UI component** via screen integration, with settings support. Currently, adding a custom programmable to a screen requires manual `buildWithParameters()` calls and hand-wiring events. The goal is to bridge the gap so that:

1. A **placeholder** in a parent `.manim` can embed any programmable and forward settings to it
2. Screen helpers make it easy to wire up interactives from any programmable
3. Interactives themselves become more capable (hover/press states, disable support)

---

## Part 1: Programmable as Component via Placeholder + Settings

### Current State

The infrastructure mostly exists:

- `placeholder(type, builderParameter("name")) { settings { key => val } }` — parser & builder support `PVFactory(settings -> h2d.Object)` where the factory receives `ResolvedSettings`
- `staticRef($ref, params)` / `dynamicRef($ref, params)` — embed programmable with compile-time or runtime parameters
- `UIScreenBase.splitSettings()` — separates control vs pass-through settings

### What's Missing

There's no **screen-level helper** that:
1. Takes a builder + a programmable name + settings
2. Builds the programmable with settings forwarded as extra parameters
3. Auto-discovers interactives in the result
4. Wraps them and registers them on the screen
5. Returns a handle for the component (object + interactives + slots + dynamic refs)

### Proposed Design

#### New screen method: `addComponent()`

```haxe
function addComponent(
    builder: MultiAnimBuilder,
    settings: ResolvedSettings,
    ?builderParams: BuilderParameters,
    ?layer: LayersEnum
): ComponentHandle {
    final buildName = getSettings(settings, "buildName", "component");
    final split = splitSettings(settings, ["buildName"], [], [], [], "component");

    final result = builder.buildWithParameters(buildName, split.main, builderParams);

    // Auto-register interactives from result
    final wrappers = addInteractives(result, buildName);

    addObjectToLayer(result.object, layer);

    return new ComponentHandle(result, wrappers);
}
```

#### `ComponentHandle` — unified access to a mounted component

```haxe
class ComponentHandle {
    public final result: BuilderResult;
    public final interactives: Array<UIInteractiveWrapper>;
    public final object: h2d.Object;

    // Convenience delegates
    public function getSlot(name, ?index) return result.getSlot(name, index);
    public function getDynamicRef(name) return result.getDynamicRef(name);
    public function setParameter(name, value) result.setParameter(name, value);
    public function getInteractiveById(id: String): Null<UIInteractiveWrapper>;
}
```

#### Usage in game code

```haxe
// .manim file defines a custom panel with interactives
// #inventoryPanel programmable(columns:uint=4, rows:uint=3) {
//     repeatable($row, $rows) {
//         repeatable($col, $columns) {
//             #slot[$row * $columns + $col] slot { ... }
//             interactive(32, 32, $row * $columns + $col, slotIndex:int => $row * $columns + $col)
//         }
//     }
// }

// In screen code:
var inventory = addComponent(builder, settings("buildName" => "inventoryPanel", "columns" => 5));
inventory.interactives; // all slot interactives, auto-registered
screen.onEvent(UIClick, (e) -> {
    if (Std.isOfType(e.source, UIElementIdentifiable)) {
        var id = cast(e.source, UIElementIdentifiable);
        var slotIdx = id.metadata.getIntOrDefault("slotIndex", -1);
        // handle click on slot
    }
});
```

### Placeholder Factory Integration

The existing `PVFactory` pattern already works for this. The `addComponent` approach complements it by handling the case where the **screen itself** wants to mount a programmable (not embed it inside another `.manim`).

For the placeholder-inside-manim case, the current flow works:
1. Parent `.manim` has `placeholder(source, builderParameter("panel")) { settings { ... } }`
2. Screen code provides `PVFactory(settings -> builder.buildWithParameters("inventoryPanel", settingsAsParams).object)`
3. Settings from the `.manim` are forwarded to the factory

**Potential improvement**: The factory currently receives raw `ResolvedSettings` but has to manually convert to `Map<String, Dynamic>` for `buildWithParameters`. Could add a helper:

```haxe
// On BuilderResolvedSettings or as utility
static function toParameterMap(settings: ResolvedSettings): Map<String, Dynamic>
```

---

## Part 2: Interactive Improvements

### Current Limitations

`UIInteractiveWrapper` is a minimal pass-through — it only forwards `OnRelease` → `UIClick`, `OnEnter` → `UIEntering`, `OnLeave` → `UILeaving`. Compared to buttons:

| Feature | Interactive | Button |
|---------|:-----------:|:------:|
| Click event | yes | yes |
| Press event | no | yes |
| Hover tracking | no | yes |
| Disabled state | no | yes |
| Visual state changes | no | yes |
| Keyboard support | no | no |

### Proposed Improvements

#### 2a. Add `OnPush` → `UIPress` event

Currently `OnPush` is silently ignored. Forward it as a new `UIPress` event (or reuse an existing event type). Useful for press-and-hold, drag initiation.

```haxe
// In UIInteractiveWrapper event handler:
case OnPush:
    emitEvent(UIPress);  // new event type, or UIClick with a "press" flag
```

#### 2b. Add `UIElementDisablable` support

```haxe
class UIInteractiveWrapper implements UIElementDisablable {
    public var disabled(default, set): Bool = false;

    function set_disabled(v) {
        disabled = v;
        interactive.alpha = v ? 0.5 : 1.0;  // Simple visual feedback
        return v;
    }

    // In event handler: if (disabled) return;
}
```

#### 2c. Hover state tracking

Track whether the interactive is currently hovered. Expose as a property. This enables visual feedback in game code without requiring the full programmable state machine.

```haxe
public var hovered(default, null): Bool = false;

// Updated in OnEnter/OnLeave handlers
```

#### 2d. Optional visual state via programmable backing (stretch goal)

For interactives that need hover/pressed visual states, allow connecting them to a programmable with `status` parameter (like buttons do). This would be a separate "rich interactive" concept:

```manim
// Instead of a plain interactive, define a mini-programmable with states
interactive(120, 40, "buyBtn", buildName => "shopButton")
```

Where `shopButton` is a programmable with `status:[normal,hover,pressed,disabled]`. The wrapper would manage state transitions like `UIStandardMultiAnimButton` does.

**This is the most complex change** and could be deferred. The simpler improvements (2a-2c) give 80% of the value.

---

## Part 3: Screen Integration Improvements

### 3a. Batch interactive event wiring

Currently, to handle interactive clicks, game code must check `Std.isOfType(e.source, UIElementIdentifiable)` on every event. Add a convenience:

```haxe
// On UIScreenBase or as helper
function onInteractiveClick(callback: (id: String, metadata: BuilderResolvedSettings) -> Void): Void {
    onEvent(UIClick, (e) -> {
        if (Std.isOfType(e.source, UIElementIdentifiable)) {
            var ident = cast(e.source, UIElementIdentifiable);
            callback(ident.id, ident.metadata);
        }
    });
}
```

#### 3b. Interactive lookup by ID

```haxe
function getInteractive(id: String): Null<UIInteractiveWrapper> {
    for (w in interactiveWrappers)
        if (w.id == id) return w;
    return null;
}

function getInteractivesByPrefix(prefix: String): Array<UIInteractiveWrapper> {
    return [for (w in interactiveWrappers) if (w.prefix == prefix) w];
}
```

---

## Implementation Order

| Phase | Change | Effort | Impact |
|-------|--------|--------|--------|
| 1 | `addComponent()` screen method + `ComponentHandle` | Medium | High — enables generic component pattern |
| 2 | `toParameterMap()` helper for settings → params | Small | Medium — simplifies factory code |
| 3 | Interactive: add `OnPush` forwarding | Small | Medium |
| 4 | Interactive: add `disabled` support | Small | Medium |
| 5 | Interactive: add `hovered` tracking | Small | Low |
| 6 | Screen: `onInteractiveClick()` convenience | Small | Medium |
| 7 | Screen: `getInteractive()` lookup | Small | Medium |
| 8 | Rich interactive with programmable backing | Large | High — but can defer |

### Phase 1 (Core)
Phases 1-2: Generic component mounting with settings

### Phase 2 (Interactive Polish)
Phases 3-7: Interactive improvements, all small/incremental

### Phase 3 (Advanced — optional)
Phase 8: Rich interactives backed by programmable state machines

---

## Open Questions

1. **Should `addComponent` support incremental mode?** — If yes, `ComponentHandle.setParameter()` is useful. If not, simpler.
2. **Event naming**: Should `OnPush` map to a new `UIPress` event or extend `UIClick` with a phase/type field?
3. **Rich interactives**: Should they be a new element type (`richInteractive(...)`) or an extension of `interactive()` via `buildName` setting?
4. **Prefix convention**: When `addComponent` registers interactives, should it auto-prefix with the buildName, or let the caller decide?
