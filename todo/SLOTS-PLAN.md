# Slot Improvements Plan

## Current State

**Slots** are simple swappable containers (`SlotHandle`) with `setContent()`, `clear()`, `getContent()`. They have no parameters, no visual feedback, no events, and no awareness of drag-and-drop beyond the basic `addDropZoneFromSlot()` integration.

**SlotHandle** on `setContent(obj)`: hides all default children (built from `.manim` children), adds `obj` as a child of the container. On `clear()`: removes custom content, restores default children visibility.

**Draggable** (`UIMultiAnimDraggable`) supports drop zones that can optionally reference a slot. Visual feedback is limited to alpha changes on the *dragged item* — there's no way to highlight the *slot/zone itself*.

## Core Design Change: Slots as Mini-Programmables

The central idea: extend slots with **programmable-style parameters**. This gives slots declarative visual states, metadata, and a clean integration point for drag-and-drop and interactives — all using existing `.manim` conditionals and expressions.

### Syntax

```manim
#name slot(param:type=default, ...) {
    @(param => value) element(...): x, y
    ...
}
```

All parameter types supported by `programmable()` work on slots: `uint`, `int`, `float`, `bool`, `string`, `color`, enum (`[val1,val2]`), range, flags. Conditionals (`@()`, `@else`, `@default`) and expressions (`$param`) work inside the slot body.

### Content Root

When a slot has parameters, its children form the **slot decoration** (background, borders, state visuals). User content (`setContent`/`clear`) goes into a separate **content root** object inside the container:

```
container (h2d.Object)
├── decoration children (conditionals, ninepatch backgrounds, etc.)
└── contentRoot (h2d.Object)  ← setContent() adds here
```

- `setContent(obj)` adds `obj` to `contentRoot` (does NOT hide decoration children)
- `clear()` removes content from `contentRoot`
- Decoration children are always visible and controlled by parameter conditionals

For **plain slots without parameters** (`#name slot` or `#name slot { ... }`), behavior stays exactly as today — `setContent` hides default children, `clear` restores them. No content root is created.

### Runtime API

```haxe
class SlotHandle {
    // Existing
    public var container:h2d.Object;
    public function setContent(obj:h2d.Object):Void;
    public function clear():Void;
    public function getContent():Null<h2d.Object>;

    // New: parameter support (null for plain slots)
    public var incrementalContext:Null<IncrementalUpdateContext>;

    public function setParameter(name:String, value:Dynamic):Void {
        if (incrementalContext == null) throw 'Slot has no parameters';
        incrementalContext.setParameter(name, value);
    }

    // New: state tracking
    public var data:Dynamic = null;
    public function isEmpty():Bool { return currentContent == null; }
    public function isOccupied():Bool { return currentContent != null; }
}
```

Builder access:
```haxe
builderResult.getSlot("icon", 0).setParameter("highlight", true);
builderResult.getSlot("icon", 0).setParameter("state", "valid");
```

Codegen access:
```haxe
instance.getSlot_icon(0).setParameter("highlight", true);
```

### Implementation

Slot parameters reuse the existing incremental mode infrastructure (`IncrementalUpdateContext`), same as `dynamicRef`. During build:

1. Parse slot parameters with `parseDefines()` (same as programmable)
2. Build slot children with `incremental: true`
3. Create `IncrementalUpdateContext` and store it on `SlotHandle`
4. If parameters exist, create a `contentRoot` object inside the container

---

## Feature Plan

### 1. Slot Parameters (Core)

**Problem:** Slots have no way to change their visual appearance at runtime. Games need slot highlights, state indicators, locked visuals, etc.

**Proposal:** Extend slot syntax with programmable-style parameters.

```manim
#icon[$i] slot(state:[empty,occupied,highlight,error,locked]=empty, selected:bool=false) {
    @(state => empty)     ninepatch("ui", "slot-empty", 40, 40): 0, 0
    @(state => occupied)  ninepatch("ui", "slot-filled", 40, 40): 0, 0
    @(state => highlight) ninepatch("ui", "slot-glow", 40, 40): 0, 0
    @(state => error)     ninepatch("ui", "slot-red", 40, 40): 0, 0
    @(state => locked)    ninepatch("ui", "slot-locked", 40, 40): 0, 0
    @(selected => true)   bitmap(generated(color(42, 42, #FFFF0044))): -1, -1
}
```

The state values are **user-defined** — the framework assigns no meaning to them. A crafting UI might use `[empty, valid, invalid, crafting, done]`. An equipment screen might use `[empty, equipped, incompatible]`.

**Parser changes:** When parsing `slot`, check for `(` after the keyword. If present, parse parameters with `parseDefines()`. Store as `SLOT(parameters, paramOrder)` in `NodeType` (extend the enum variant).

**Builder changes:** When building a `SLOT` node with parameters:
- Build children with `incremental: true`
- Create `IncrementalUpdateContext` on the `SlotHandle`
- Create `contentRoot` child object inside the container

**Codegen changes:** When processing `SLOT` with parameters:
- Generate `IncrementalUpdateContext`-backed parameter support
- `SlotHandle` instance gets the context at construction

**Complexity:** Medium (reuses existing incremental infrastructure) | **Impact:** High

### 2. Slot Auto-Interactive

**Problem:** Slots have no built-in interactivity. To make a slot clickable (right-click, tooltip, drag start), you must manually overlay an `interactive()`.

**Proposal:** Slots automatically generate an interactive hit region, sized to the slot's container bounds. The interactive is registered in `BuilderResult.interactives` like any other `interactive()` element.

Interactive ID follows the pattern: `"slot.<name>"` for named slots, `"slot.<name>.<index>"` for indexed slots. Slot parameters are exposed as interactive metadata, so event handlers can read them.

```manim
// Auto-interactive by default:
#icon[$i] slot(state:[empty,occupied]=empty) {
    ninepatch("ui", "slot-bg", 40, 40): 0, 0
}
```

```haxe
// In screen code:
screen.addInteractives(result);  // picks up slot interactives too

screen.onEvent = (event, source) -> {
    if (event == UIClick) {
        switch Std.downcast(source, UIElementIdentifiable) {
            case ident if (ident != null && StringTools.startsWith(ident.id, "slot.")):
                // Slot was clicked
                trace(ident.id);      // "slot.icon.0"
                trace(ident.metadata); // slot parameters as metadata
        }
    }
};
```

The interactive is a transparent overlay sized to the slot bounds. It is added as the last child of the container so it sits on top.

**Opt-out:** If auto-interactive is undesirable, add a `noInteractive` flag:
```manim
#data slot(noInteractive) { ... }
```

**Complexity:** Medium | **Impact:** High — makes every slot event-aware without boilerplate.

### 3. Zone Highlight via Slot Parameters

**Problem:** Only the dragged item's alpha changes during drag-and-drop. No way to visually highlight target slots.

**Proposal:** Add callbacks on `DropZone` and `UIMultiAnimDraggable` that let game code update slot parameters during drag operations:

```haxe
// Per-zone callback: fires on ZoneEnter/ZoneLeave
// On DropZone:
public var onZoneHighlight:Null<(zone:DropZone, highlight:Bool) -> Void> = null;

// Global callbacks on UIMultiAnimDraggable:
// Called on drag start with all valid zones (filtered by accepts)
public var onDragStartHighlightZones:Null<(zones:Array<DropZone>) -> Void> = null;
// Called on drop/cancel to clear all highlights
public var onDragEndHighlightZones:Null<(zones:Array<DropZone>) -> Void> = null;
```

Usage with slot parameters:
```haxe
draggable.onDragStartHighlightZones = (zones) -> {
    for (z in zones) z.slot.setParameter("state", "highlight");
};
draggable.onDragEndHighlightZones = (zones) -> {
    for (z in zones)
        z.slot.setParameter("state", z.slot.isEmpty() ? "empty" : "occupied");
};
zone.onZoneHighlight = (z, hovering) -> {
    z.slot.setParameter("state", hovering ? "hover" : "highlight");
};
```

The framework provides the **hooks** — the game decides **what to do** with them. This keeps drag-and-drop decoupled from slot visual semantics.

**Complexity:** Low | **Impact:** High

### 4. Batch `addDropZonesFromSlots` Helper

**Problem:** Creating slot-based drop zones for indexed slots (inventory grids) requires manually calling `addDropZoneFromSlot()` per slot.

**Proposal:** Add a batch helper on `UIMultiAnimDraggable`:

```haxe
public function addDropZonesFromSlots(baseName:String, builderResult:BuilderResult,
    ?accepts:(draggable:UIMultiAnimDraggable, zone:DropZone) -> Bool):UIMultiAnimDraggable {
    for (entry in builderResult.slots) {
        switch entry.key {
            case Indexed(name, index) if (name == baseName):
                addDropZoneFromSlot(baseName + "_" + index, entry.handle, accepts);
            case Named(name) if (name == baseName):
                addDropZoneFromSlot(baseName, entry.handle, accepts);
            default:
        }
    }
    return this;
}
```

**Complexity:** Low | **Impact:** Medium

### 5. SlotHandle State Tracking

**Problem:** `SlotHandle` only knows `null` vs non-null content. Games need to attach metadata.

**Proposal:** Extend `SlotHandle`:

```haxe
class SlotHandle {
    // Existing API...

    public var data:Dynamic = null;       // Arbitrary payload (item data, type tag, etc.)

    public function isEmpty():Bool { return currentContent == null; }
    public function isOccupied():Bool { return currentContent != null; }
}
```

The `data` field lets game code store item metadata on the slot itself, so `accepts` callbacks can check `zone.slot.data` without external tracking.

Note: `locked` is removed from this proposal — it's better expressed as a slot parameter (`locked:bool=false`) with conditional visuals, and the `accepts` callback can check `zone.slot` parameters.

**Complexity:** Low | **Impact:** Medium

### 6. Drag-from-Slot (Bidirectional)

**Problem:** `addDropZoneFromSlot` makes slots *receive* draggables, but there's no built-in way to *drag items out of* a slot.

**Proposal:** Track source slot on the draggable, with helpers:

```haxe
// On UIMultiAnimDraggable:
public var sourceSlot:Null<SlotHandle> = null;

// Creates a draggable from a slot's content
public static function createFromSlot(slot:SlotHandle, ?id:String):UIMultiAnimDraggable {
    var content = slot.getContent();
    if (content == null) return null;
    var drag = UIMultiAnimDraggable.create(content);
    drag.sourceSlot = slot;
    drag.returnToOrigin = true;
    return drag;
}
```

Behavior:
- On drag start: `sourceSlot.clear()` removes content from the slot (but keeps the slot decoration)
- On failed drop: content returns to `sourceSlot` via `sourceSlot.setContent(target)`
- On successful drop to another slot zone: content moves to the target slot

Screen-level helper for making all slots in a group draggable:
```haxe
screen.makeSlotsDraggable(builderResult, "icon", {
    accepts: (from, to) -> canEquip(from.data, to.data)
});
```

**Complexity:** Medium | **Impact:** High

### 7. Swap Mode

**Problem:** Dropping onto an occupied slot just overwrites. Games often want to *swap*.

**Proposal:** Add swap support:

```haxe
// On UIMultiAnimDraggable:
public var swapMode:Bool = false;
```

When `swapMode` is true and the target slot is occupied:
1. Store displaced content and its data from the target slot
2. Place dragged item in target slot
3. Place displaced item in source slot (with optional animation)

Requires `sourceSlot` tracking from feature 6.

**Complexity:** Medium (depends on feature 6) | **Impact:** High

### 8. Slot Metadata in .manim (droptarget and custom)

**Problem:** Filtering which draggables go where requires hand-writing `accepts` callbacks with external state.

**Proposal:** Slot parameters already solve this. The `data` field on `SlotHandle` or a dedicated parameter covers the use case:

```manim
#weapon slot(slotType:"weapon", state:[empty,highlight]=empty) {
    @(state => empty)     ninepatch("ui", "slot-weapon", 40, 40): 0, 0
    @(state => highlight) ninepatch("ui", "slot-weapon-hl", 40, 40): 0, 0
}
```

Since slot parameters are exposed as interactive metadata, and are readable from `SlotHandle`:

```haxe
// In accepts callback:
accepts: (drag, zone) -> {
    // Read slot parameter value via incrementalContext
    zone.slot.data.slotType == drag.itemType;
}
```

This doesn't need a separate feature — it's a natural consequence of features 1 (slot parameters) and 5 (data field).

**Complexity:** N/A (covered by features 1 + 5) | **Impact:** Medium

---

## Implementation Priority

| # | Feature | Complexity | Impact | Dependencies |
|---|---------|------------|--------|-------------|
| 1 | Slot parameters (core) | Medium | High | None |
| 2 | Slot auto-interactive | Medium | High | Feature 1 |
| 3 | Zone highlight callbacks | Low | High | None (better with 1) |
| 4 | Batch `addDropZonesFromSlots` | Low | Medium | None |
| 5 | `SlotHandle.data` + `isEmpty()`/`isOccupied()` | Low | Medium | None |
| 6 | Drag-from-slot | Medium | High | Feature 5 |
| 7 | Swap mode | Medium | High | Feature 6 |

**Phase 1 — Foundation:** Features 1, 3, 4, 5 (slot parameters, zone callbacks, batch helper, data tracking)
**Phase 2 — Drag & Drop:** Features 2, 6, 7 (auto-interactive, bidirectional drag, swap)

Feature 8 (droptarget) is dropped as a separate item — covered by slot parameters + data field.

---

## Example: Complete Inventory Slot

```manim
#inventorySlot[$i] slot(
    state:[empty, occupied, highlight, hover, invalid] = empty,
    slotType: "general"
) {
    @(state => empty)     ninepatch("ui", "slot-empty", 48, 48): 0, 0
    @(state => occupied)  ninepatch("ui", "slot-normal", 48, 48): 0, 0
    @(state => highlight) ninepatch("ui", "slot-glow", 48, 48): 0, 0
    @(state => hover)     ninepatch("ui", "slot-hover", 48, 48): 0, 0
    @(state => invalid)   ninepatch("ui", "slot-red", 48, 48): 0, 0
}
```

```haxe
// Game code:
var result = builder.buildProgrammable("inventory", ...);

// Auto-interactives are already in result.interactives
screen.addInteractives(result, "inv");

// Set up drag-and-drop for all slots
var drag = UIMultiAnimDraggable.create(itemIcon);
drag.addDropZonesFromSlots("inventorySlot", result, (d, z) -> {
    return z.slot.isEmpty() || drag.swapMode;
});

// Visual feedback via slot parameters
drag.onDragStartHighlightZones = (zones) -> {
    for (z in zones) z.slot.setParameter("state", "highlight");
};
drag.onDragEndHighlightZones = (zones) -> {
    for (z in zones)
        z.slot.setParameter("state", z.slot.isEmpty() ? "empty" : "occupied");
};

// Tooltip on right-click via interactive events
screen.onEvent = (event, source) -> {
    if (Std.isOfType(source, UIElementIdentifiable)) {
        var ident:UIElementIdentifiable = cast source;
        if (event == UIClick && StringTools.startsWith(ident.id, "slot.inventorySlot."))
            showTooltip(ident);
    }
};
```
