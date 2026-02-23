# Interactive Improvements — Remaining

## Must

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

## Optional

### Rich interactive with programmable backing

Connect an interactive to a programmable with `status:[normal,hover,pressed,disabled]` for automatic visual state management:

```manim
interactive(120, 40, "buyBtn", buildName => "shopButton")
```

The wrapper would manage state transitions like `UIStandardMultiAnimButton` does. Deferred — the simpler improvements cover most use cases.
