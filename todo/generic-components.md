# Interactive Improvements Plan

## Goal

Make interactives capable enough that custom programmables + interactives cover most use cases without new abstractions. The existing `buildWithParameters()` + `addInteractives()` pattern is sufficient for mounting — the missing piece is interactive quality.

---

## Implemented

### UIPush event (`UIElement.hx`, `UIInteractiveWrapper.hx`)
- New `UIPush` entry in `UIScreenEvent` enum
- `UIInteractiveWrapper` forwards `OnPush` → `UIPush`
- Only on interactives — other controls already have semantic push events (`UIToggle`, `UIChangeValue`, `UIChangeItem`, etc.)
- Complements `UIClick` (release) — gives game code press vs release distinction

### UIElementDisablable (`UIInteractiveWrapper.hx`)
- `UIInteractiveWrapper` implements `UIElementDisablable`
- `disabled = true` blocks all events (early return in `onEvent`)
- No visual feedback — game code controls visuals via the backing programmable
- Matches button/checkbox/slider pattern

### Hovered tracking (`UIInteractiveWrapper.hx`)
- `hovered:Bool` property (`default, null`) on `UIInteractiveWrapper`
- Set `true` on `OnEnter`, `false` on `OnLeave`
- Game code can poll this or react to `UIEntering`/`UILeaving` events

---

## Still To Do

### Screen: interactive lookup by ID

Find interactives without iterating manually:

```haxe
// On UIScreenBase
function getInteractive(id: String): Null<UIInteractiveWrapper> {
    for (w in interactiveWrappers)
        if (w.id == id) return w;
    return null;
}

function getInteractivesByPrefix(prefix: String): Array<UIInteractiveWrapper> {
    return [for (w in interactiveWrappers) if (w.prefix == prefix) w];
}
```

### Screen: typed interactive event callback

Eliminate the `Std.isOfType` + cast boilerplate:

```haxe
// On UIScreenBase
function onInteractiveEvent(event: UIScreenEvent, callback: (id: String, metadata: BuilderResolvedSettings) -> Void): Void {
    // Registers a listener that filters for UIElementIdentifiable sources
    // and unwraps id + metadata before calling back
}
```

Usage: `onInteractiveEvent(UIClick, (id, meta) -> { ... })` instead of manual cast chain.

### Rich interactive with programmable backing (stretch goal)

Connect an interactive to a programmable with `status:[normal,hover,pressed,disabled]` for automatic visual state management:

```manim
interactive(120, 40, "buyBtn", buildName => "shopButton")
```

The wrapper would manage state transitions like `UIStandardMultiAnimButton` does. **Deferred** — the simpler improvements cover most use cases.

---

## Implementation Status

| Item | Status | Notes |
|------|--------|-------|
| `UIPush` event | done | Only on `UIInteractiveWrapper` |
| `UIElementDisablable` | done | No visual feedback, blocks events |
| `hovered` tracking | done | Property on wrapper |
| `getInteractive(id)` | todo | Small addition to UIScreenBase |
| `getInteractivesByPrefix()` | todo | Small addition to UIScreenBase |
| `onInteractiveEvent()` | todo | Convenience callback, eliminates cast boilerplate |
| Rich interactive (programmable backing) | deferred | Stretch goal |
