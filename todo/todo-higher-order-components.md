# Higher-Order Components for macroBuildWithParameters

## Goal

Bring `UIMultiAnimGrid` and `UICardHandHelper` into the `macroBuildWithParameters` ecosystem so they can be created declaratively from `.manim` files with overridable settings, auto-wired lifecycle management, and hot-reload support — similar to how `addButton()`, `addSlider()`, etc. work today.

## Current State

### Simple UIElements (Button, Slider, Checkbox, etc.)
- Implement `UIElement` interface
- Created via `addButton(builder, text)` factory methods on `UIScreenBase`
- Participate in `macroBuildWithParameters` as `PVFactory` entries
- Receive `ResolvedSettings` for `.manim`-driven configuration
- Auto-registered in `elements` array for event dispatch
- No manual `update(dt)` or mouse routing needed

### Higher-Order Components (Grid, CardHand)
- Do NOT implement `UIElement`
- Created manually with large config typedefs
- NOT usable in `macroBuildWithParameters`
- Require manual boilerplate in every screen:
  - `onMouseMove()` routing (priority ordering: card hand first, then grid)
  - `onMouseClick()` / `onMouseRelease()` routing
  - `handleScreenEvent()` forwarding (card hand only)
  - `update(dt)` call
  - `dispose()` in `onClear()`
  - Scene graph attachment via `addObjectToLayer(grid.getObject(), layer)`
- CardHand takes `screen:UIScreenBase` in constructor (tight coupling)
- Config is purely code-driven — no `.manim` settings integration

### Recent Dev Changes (08aacea)

New features that affect the design:

**Grid Layers** — Grid now uses `h2d.Layers` (was `h2d.Object`). New per-cell layer system:
- `addLayer(name, {buildName, zOrder})` — register named overlay layers
- `setLayer(col, row, layerName, ?params)` — build layer instance on a cell
- `clearLayer()`, `clearLayerAll()`, `clearAllLayers()`, `getLayerVisual()`, `hasLayer()`
- Base cells render at z-order 0, layers at custom z-orders
- Auto-cleared on `removeCell()`, `removeCellAnimated()`, `dispose()`

**External Objects** — Grid acts as a z-order manager for related objects:
- `addExternalObject(obj, zOrder)` — insert arbitrary object into grid's `h2d.Layers`
- `removeExternalObject(obj)` — remove it
- Key use case: `grid.addExternalObject(cardHand.getTargetingObject(), 8)` — arrow renders between grid layers

**DropContext** — Drop events now carry a context for accept/reject control:
- `CellDrop(cell, draggable, srcGrid, srcCell, ctx)` — breaking signature change
- `ctx.accept()` / `ctx.reject()` — control post-drop animation
- `ctx.acceptWithPath(name)` / `ctx.rejectWithPath(name)` — custom animation paths
- `ctx.onComplete(cb)` — callback after animation completes

**Arrow Snap Point Provider** — Custom arrow endpoint targeting:
- `setArrowSnapPointProvider(cb)` — callback returns snap point in target's local space
- `getTargetingObject()` — get arrow scene object for reparenting into grid layers

**DragSnapComplete** — New `DragEvent.DragSnapComplete` variant, fired when snap animation completes.

**GridSwapAccepts** — New `GridConfig` field for configurable swap decision logic (replaces string-based zone IDs with `DropZoneId` enum).

### Auto-Wired Helpers (PanelHelper — middle ground)
- NOT a UIElement, but has screen auto-wiring via `createPanelHelper()` / `registerPanelHelper()`
- Screen's `dispatchScreenEvent()` and `update()` automatically call helper methods
- No manual boilerplate for event routing
- Lightweight pattern worth extending

## Design

### Phase 1: Auto-Wiring (createGrid / createCardHand pattern)

Follow the `createPanelHelper()` model: add `createGrid()` and `createCardHand()` to `UIScreenBase` that auto-register the component for lifecycle management.

#### Screen API

```haxe
// In screen's load():
grid = createGrid(builder, {
    gridType: Rect(50, 50, 2),
    cellBuildName: "gridCell",
    originX: 100, originY: 100,
});
grid.addRectRegion(6, 4);
addObjectToLayer(grid.getObject(), DefaultLayer);

cardHand = createCardHand(builder, {
    anchorX: 640, anchorY: 680,
    drawPathName: "drawAnim",
    // ...
});
```

#### What auto-wiring handles

| Lifecycle | Currently manual | Auto-wired |
|-----------|------------------|------------|
| `update(dt)` | Screen must call `grid.update(dt)` | `super.update(dt)` calls it |
| Mouse move | Screen must call `grid.onMouseMove()` | Auto-dispatched with priority |
| Mouse click | Screen must call `grid.onMouseClick()` | Auto-dispatched with priority |
| Screen events | Screen must call `cardHand.handleScreenEvent()` | Auto-dispatched |
| Dispose | Screen must call `dispose()` in `onClear()` | `clear()` handles it |
| Scene graph | Manual `addObjectToLayer()` | Still manual (position/layer varies) |

#### Priority ordering for auto-wired components

Mouse events need deterministic priority (card hand before grid, both before default):

```haxe
// Internal tracking in UIScreenBase:
var registeredComponents:Array<UIHigherOrderComponent> = [];

// In dispatchMouseMove():
for (comp in registeredComponents) {
    if (comp.onMouseMove(x, y)) return false; // consumed
}
// fall through to default handling
```

**DECISION NEEDED**: Should priority be implicit (registration order) or explicit (priority field on config)?

#### UIHigherOrderComponent interface

```haxe
interface UIHigherOrderComponent {
    function update(dt:Float):Void;
    function onMouseMove(sceneX:Float, sceneY:Float):Bool;
    function onMouseClick(sceneX:Float, sceneY:Float, button:Int):Bool;
    function onMouseRelease(sceneX:Float, sceneY:Float):Bool;
    function handleScreenEvent(event:UIScreenEvent):Bool;
    function getObject():h2d.Object;
    function dispose():Void;
}
```

Both `UIMultiAnimGrid` and `UICardHandHelper` would implement this. Existing methods mostly match already — gaps:
- Grid has no `onMouseRelease()` → return false
- Grid has no `handleScreenEvent()` → return false
- CardHand has `onMouseMove(x,y):Bool` but also needs `onMouseRelease(x,y):Bool`
- CardHand uses `handleScreenEvent()` already

**Note on Grid's root type**: Grid now uses `h2d.Layers` internally (for z-ordered layers + external objects). `getObject()` returns `h2d.Layers` which extends `h2d.Object` — no interface issue. But consumers should be aware that adding children directly to the returned object could break z-ordering.

#### CardHand screen decoupling

**Problem**: `UICardHandHelper` constructor takes `screen:UIScreenBase` and calls `screen.addInteractives()` / `screen.removeInteractives()` internally.

**Solution**: Extract an interface for interactive registration:

```haxe
interface UIInteractiveRegistry {
    function addInteractives(result:BuilderResult, prefix:String):Void;
    function removeInteractives(prefix:String):Void;
    function getInteractive(id:String):Null<UIInteractiveWrapper>;
}
```

`UIScreenBase` implements this. `UICardHandHelper` takes the interface instead of the concrete screen. This also enables standalone usage (e.g., in test harnesses without a full screen).

**DECISION NEEDED**: Is this decoupling worth the churn now, or can we keep the screen reference and just add auto-wiring?

#### Grid + CardHand z-order coordination

With grid layers and `addExternalObject()`, the grid now acts as a z-order manager. When auto-wiring both grid and card hand, the screen auto-wiring should handle the common pattern of reparenting the targeting arrow into the grid:

```haxe
// Current manual pattern:
grid.addExternalObject(cardHand.getTargetingObject(), 8);

// Auto-wired: if both grid and cardHand are registered, and grid has
// registerAsCardTarget(cardHand), auto-reparent arrow into grid layers
```

**DECISION NEEDED**: Should auto-wiring handle this automatically, or leave it to the screen? The z-order value (8 in the example) is game-specific.

### Phase 2: Settings Integration (overridable config from .manim)

Allow `.manim` `settings {}` blocks to override component config fields.

#### Which settings should be overridable?

**Grid — recommended overridable settings:**

| Setting | Type | Rationale |
|---------|------|-----------|
| `originX`, `originY` | float | Position varies by screen layout |
| `swapPathName` | string | Animation path reference |
| `swapEnabled` | bool | Enable/disable swap semantics |

**Grid — NOT overridable (code-only):**

| Setting | Rationale |
|---------|-----------|
| `gridType` (Rect/Hex + dimensions) | Structural — affects coordinate math, hit testing, everything |
| `cellVisualFactory` | Object reference, can't come from .manim |
| `tweenManager` | Runtime object reference |
| `snapPathName`, `returnPathName` | String references to .manim elements — could be overridable but low value |
| `swapAccepts` | Function reference |

**Note:** `cellBuildName`, `highlightParam`, `statusParam`, and delegates moved to `CellVisualFactoryConfig` (owned by `DefaultCellVisualFactory`). These are factory concerns, not grid config.

**Grid layers** — Layer configs (`addLayer()` calls) are structural and code-only. The layer build names and z-orders define the grid's layer architecture. However, individual layer _parameters_ (passed to `setLayer()`) could be settings-overridable in the future.

**CardHand — recommended overridable settings:**

| Setting | Type | Rationale |
|---------|------|-----------|
| `anchorX`, `anchorY` | float | Hand position varies by screen |
| `cardWidth`, `cardHeight` | float | Card visual size |
| `fanRadius` | float | Layout tuning |
| `fanMaxAngle` | float | Layout tuning |
| `hoverPopDistance` | float | Feel tuning |
| `hoverScale` | float | Feel tuning |
| `hoverNeighborSpread` | float | Feel tuning |
| `linearSpacing` | float | Layout tuning |
| `linearMaxWidth` | float | Layout tuning |
| `targetingThresholdY` | float | Zone tuning |
| `drawPilePosition.x/y` | float | Position tuning |
| `discardPilePosition.x/y` | float | Position tuning |
| `drawPathName` etc. | string | Path references |
| `arrowSegmentName` etc. | string | Programmable references |
| `interactivePrefix` | string | ID namespace |

**CardHand — NOT overridable (code-only):**

| Setting | Rationale |
|---------|-----------|
| `layoutMode` | Enum, structural |
| `allowCardToCard` | Boolean game logic |
| `onCardBuilt` | Callback |
| `handLayer`, `dragLayer` | Enum reference |
| `cardToCardHighlightScale` | Game logic tuning |

#### .manim syntax

```manim
#gameScreen programmable(...) {
    settings {
        // Grid settings (prefixed)
        grid.originX:float => 100,
        grid.originY:float => 200,
        grid.cellBuildName => "hexCell",

        // Card hand settings (prefixed)
        cardHand.anchorX:float => 640,
        cardHand.anchorY:float => 680,
        cardHand.fanRadius:float => 400,
        cardHand.hoverScale:float => 1.15,
        cardHand.drawPathName => "drawAnim",
    }
    placeholder(grid): 0, 0
    placeholder(cardHand): 0, 0
}
```

#### Implementation approach

Factory method pattern (like `addButton`):

```haxe
// In UIScreenBase:
public function addGrid(builder:MultiAnimBuilder, config:GridConfig, ?settings:ResolvedSettings):UIMultiAnimGrid {
    if (settings != null) {
        applySettingsToConfig(config, settings, "grid");
    }
    var grid = new UIMultiAnimGrid(builder, config);
    registerComponent(grid);
    return grid;
}

public function addCardHand(builder:MultiAnimBuilder, config:CardHandConfig, ?settings:ResolvedSettings):UICardHandHelper {
    if (settings != null) {
        applySettingsToConfig(config, settings, "cardHand");
    }
    var cardHand = new UICardHandHelper(this, builder, config);
    registerComponent(cardHand);
    return cardHand;
}
```

Then usable in `macroBuildWithParameters`:

```haxe
var ui = MacroUtils.macroBuildWithParameters(builder, "gameScreen", params, [
    okButton => addButton(okBuilder, "OK"),
    grid => addGrid(builder, gridConfig),
    cardHand => addCardHand(builder, cardHandConfig),
]);
// ui.grid : UIMultiAnimGrid
// ui.cardHand : UICardHandHelper
// ui.okButton : UIStandardMultiAnimButton
// ui.builderResults : BuilderResult
```

**ISSUE**: `macroBuildWithParameters` currently expects factory functions returning `UIElement` or `h2d.Object`. Grid/CardHand return neither. Options:
1. Extend macro to support a third return type (higher-order component)
2. Have `addGrid()` return an adapter that implements UIElement (wraps grid)
3. Have `addGrid()` return `h2d.Object` (grid.getObject()) and store the grid separately

Option 1 is cleanest. Would add `PVComponent` to `PlaceholderValues`:

```haxe
enum PlaceholderValues {
    PVObject(obj:h2d.Object);
    PVFactory(factoryMethod:ResolvedSettings->h2d.Object);
    PVComponent(factory:ResolvedSettings->UIHigherOrderComponent); // NEW
}
```

Builder resolves `PVComponent` by calling factory, using `getObject()` for scene graph placement.

### Phase 3: macroBuildWithParameters integration

Full macro support so Grid/CardHand can be created declaratively:

```haxe
var ui = MacroUtils.macroBuildWithParameters(builder, "gameScreen", params, [
    grid => addGrid(builder, {
        gridType: Rect(50, 50, 2),
        cellBuildName: "gridCell",
    }),
    cardHand => addCardHand(builder, {
        drawPathName: "drawAnim",
        discardPathName: "discardAnim",
    }),
]);

// Settings from .manim override code config
// Auto-wired: update, mouse, events, dispose
// Grid positioned by .manim placeholder coordinates
```

#### Macro changes needed

1. Add return type detection for `UIHigherOrderComponent` in `MacroUtils.hx`
2. Generate `PVComponent` wrapper instead of `PVFactory`
3. Auto-call `registerComponent()` in the generated closure
4. Return typed field in the anonymous struct

#### Position from .manim placeholder

The `placeholder(grid): 100, 200` coordinates would set `originX/originY` for Grid or `anchorX/anchorY` for CardHand. This is a natural mapping — the placeholder position IS the component's origin.

**DECISION NEEDED**: Should placeholder coordinates override config origin, or add to it?

### Phase 4: CardHand Refactoring

CardHand needs structural cleanup before full integration:

#### 4a. Separate config from behavior

Current `CardHandConfig` mixes layout tuning with game logic callbacks. Split:

```haxe
// Layout/visual config (overridable from .manim)
typedef CardHandVisualConfig = {
    var ?anchorX:Float;
    var ?anchorY:Float;
    var ?cardWidth:Float;
    var ?cardHeight:Float;
    var ?fanRadius:Float;
    var ?fanMaxAngle:Float;
    var ?hoverPopDistance:Float;
    var ?hoverScale:Float;
    // ...
}

// Game logic config (code-only)
typedef CardHandBehaviorConfig = {
    var ?allowCardToCard:Bool;
    var ?onCardBuilt:CardBuildCallback;
    var ?canPlayCard:CardPlayGate;
    var ?canDragCard:CardDragGate;
    // ...
}
```

**DECISION NEEDED**: Is this split worth the API change, or should we keep one config and just document which fields are settings-overridable?

#### 4b. Extract interactive registry interface

As described in Phase 1 — decouple from `UIScreenBase`.

#### 4c. Consistent event model

CardHand uses callbacks (`onCardEvent`), Grid uses callbacks (`onGridEvent`). These should optionally push through the screen's `onScreenEvent` system for consistency:

```haxe
// Option A: New UIScreenEvent variants
case UIGridEvent(gridEvent:GridEvent, grid:UIMultiAnimGrid)
case UICardHandEvent(cardEvent:CardHandEvent, hand:UICardHandHelper)

// Option B: Keep callbacks, auto-wire is just for lifecycle
// (Simpler, no event system changes needed)
```

**DECISION NEEDED**: New event types, or keep callbacks?

## Hot Reload Considerations

### Current reload behavior

- Grid cells: Each cell is a `BuilderResult` with incremental mode. Hot reload replaces cell visuals in-place via `ReloadableRegistry`. Works automatically.
- Grid layers: Layer instances are `BuilderResult` objects but built WITHOUT incremental mode (no `true` flag in `setLayer()` — see `builder.buildWithParameters(config.buildName, buildParams)` with no incremental arg). **This means layers are NOT hot-reloadable today.** Should be fixed by passing `incremental:true`.
- CardHand cards: Each card is a `BuilderResult`. Same reload mechanism. Works automatically.
- Grid config: NOT reloadable. Changing `cellWidth` in `.manim` settings won't resize the grid.
- CardHand config: NOT reloadable. Changing `anchorX` won't move the hand.

### Desired reload behavior

| What changes | Desired behavior | Difficulty |
|-------------|------------------|------------|
| Cell/card programmable `.manim` | In-place visual update (WORKS TODAY) | Done |
| Grid layer programmable `.manim` | In-place visual update (**NOT WORKING** — needs incremental flag) | Easy fix |
| Settings values (originX, anchorY, etc.) | Apply new values, reposition | Medium |
| Grid dimensions (cellWidth, cellHeight) | Rebuild all cells with new layout | Hard |
| Grid type (Rect → Hex) | Not supported (structural) | N/A |
| CardHand layout mode | Not supported (structural) | N/A |

### Settings reload approach

When settings-overridable config values change during hot reload:

1. Parent programmable rebuilds (triggers `ReloadableRegistry` callback)
2. New `ResolvedSettings` are resolved
3. `applySettingsToConfig()` updates config fields
4. Component calls its own `refreshLayout()` / `recalculatePositions()`

Grid would need:
- `setOrigin(x, y)` — reposition all cells (and all layer instances on those cells)
- `refreshLayout()` — recalculate cell positions (if cellWidth/cellHeight changed)

CardHand would need:
- `setAnchor(x, y)` — already exists
- `refreshLayout()` — recalculate all card positions

### What SHOULDN'T be reloadable

- `gridType` (Rect vs Hex) — structural, requires full tear-down
- `cellBuildDelegate` — function reference
- `layoutMode` (Fan vs Linear vs Path) — could be reloadable but complex
- `allowCardToCard` — game logic flag, not visual

### Layer reload edge case

Grid layers add complexity to hot reload: if a cell is repositioned (origin change), all its layer objects must also move. The current `setLayer()` positions objects at `getCellLocalPosition()` — so a `setOrigin()` that moves `root` would automatically move all children (cells and layers) since they're children of `root`. This should work transparently.

But if cell dimensions change (cellWidth/cellHeight), cells need repositioning within `root`, and so do their layers. The `refreshLayout()` would need to iterate all cells AND all layers on each cell.

## Implementation Plan

### Step 1: UIHigherOrderComponent interface — DONE
- [x] Define interface in new file `src/bh/ui/UIHigherOrderComponent.hx`
- [x] Implement on `UIMultiAnimGrid` (added `onMouseRelease`, `handleScreenEvent` stubs)
- [x] Implement on `UICardHandHelper` (added `onMouseClick` stub, `getObject()`)
- [x] No behavior change, just interface compliance

### Step 2: Screen auto-wiring — DONE
- [x] Add `higherOrderComponents:Array<UIHigherOrderComponent>` to `UIScreenBase`
- [x] Add `registerComponent()` / `unregisterComponent()` methods
- [x] Wire into `update()`, `dispatchScreenEvent()`, `clear()`
- [x] Add `dispatchMouseMove()` and `dispatchMouseClick()` dispatch methods — components tried first, then fall through to screen overrides
- [x] Updated `UIControllerScreenIntegration` to use dispatch methods (`onMouseMove` → `dispatchMouseMove`, `onMouseClick` → `dispatchMouseClick`)
- [x] Updated `UIDefaultController` to call dispatch methods
- [x] Add `createGrid()` (no scene graph add) and `addGrid()` (creates + adds to layer)
- [x] Add `addCardHand()` convenience method
- [x] Priority: registration order (card hand registered before grid consumes first)

### Step 3: Settings integration — DONE
- [x] Add `applyGridSettings(config, settings)` — applies `originX`, `originY`, `swapPathName`, `swapEnabled` (cell build settings moved to `CellVisualFactoryConfig`)
- [x] Add `applyCardHandSettings(config, settings)` — applies `anchorX/Y`, card dimensions, fan/linear layout, hover/targeting params, pile positions, path/arrow names
- [x] Factory methods (`addGrid`, `addCardHand`, `createGrid`) accept and apply settings

### Step 4: PlaceholderValues extension — DONE
- [x] Add `PVComponent(factoryMethod:ResolvedSettings->h2d.Object, component:Dynamic)` to `PlaceholderValues` enum
- [x] Handle `PVComponent` in `MultiAnimBuilder` placeholder resolution
- [x] Handle `PVComponent` in `ProgrammableBuilder.buildPlaceholderViaSource`

### Step 5: Macro support — DONE
- [x] Added `componentType` detection in `MacroUtils.macroBuildWithParameters`
- [x] Generates `PVComponent` wrappers for `UIHigherOrderComponent`-returning factories
- [x] Component factory closure calls `getObject()` for scene graph placement
- [x] Decision: Grid-only macro support; CardHand stays as `addCardHand()` only (multi-layer architecture prevents single-placeholder representation)

### Step 6: CardHand decoupling — DONE
- [x] Created `UIComponentHost` interface (`src/bh/ui/UIComponentHost.hx`) with 5 methods: `addObjectToLayer`, `addInteractives`, `removeInteractives`, `getInteractive`, `getAutoInteractiveHelper`
- [x] `UIScreenBase` implements `UIComponentHost`
- [x] `UICardHandHelper` constructor takes `UIComponentHost` instead of `UIScreenBase`
- [x] `UIRichInteractiveHelper` constructor takes `UIComponentHost` instead of `UIScreenBase`
- Config split and screen event integration deferred — not needed for current goals

### Step 7: Hot reload for settings — DONE
- [x] Grid: `setOrigin(x, y)` — repositions root, all children move automatically
- [x] Grid layers: fixed incremental flag in `setLayer()` for hot-reload of layer programmables
- [x] CardHand: `setAnchor(x, y)` already existed with `applyLayout(false)`
- [x] `wireGridReload(parentResult, grid)` — `#if MULTIANIM_DEV` helper on UIScreenBase that hooks `onReload` to re-apply origin from settings
- [x] `wireCardHandReload(parentResult, cardHand)` — same for card hand anchor

### Step 8: Fix grid layer hot-reload — DONE
- [x] `setLayer()` now calls `buildWithParameters(config.buildName, buildParams, null, null, true)` — incremental flag enables hot-reload of layer programmables

## Open Questions

1. ~~**Priority model**: Registration order vs explicit priority field for mouse event consumption?~~ **DECIDED**: Registration order. Card hand registered before grid → consumes first.
2. ~~**CardHand decoupling**: Extract `UIInteractiveRegistry` now or later?~~ **DEFERRED**: Keep screen reference for now.
3. ~~**Config split**: Separate visual from behavioral config, or annotate which fields are settings-overridable?~~ **DEFERRED**: Keep single config, settings apply to known fields.
4. ~~**Event integration**: New `UIScreenEvent` variants for grid/card events, or keep callbacks?~~ **DEFERRED**: Keep callbacks.
5. **Placeholder coordinates**: Override component origin, or add offset? (Not yet needed — Grid macro uses `createGrid` which doesn't auto-position from placeholder)
6. **Scope**: Should other helpers (DraggableHelper, FloatingTextHelper) also become higher-order components?
7. **Arrow z-order auto-wiring**: Left manual — z-order value is game-specific.
8. **DropContext pattern**: Should the DropContext accept/reject pattern be extended to other event types?

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| CardHand API change breaks proto-game | High | Keep backward compat constructor, add new interface-based one |
| Macro complexity growth | Medium | Keep PVComponent handling minimal, delegate to runtime |
| Hot reload edge cases with settings | Medium | Start with position-only reload, add dimensions later |
| Priority ordering bugs | Medium | Explicit priority enum, not registration order |
| Grid/CardHand interaction ordering | Low | Already solved in proto-game screens, just formalize |
| Grid layers + reload | Low | Layer repositioning inherits from root — test to confirm |
| DropContext in event signature | Low | Already shipped in dev, breaking change already done |

## Files to Modify

| File | Changes |
|------|---------|
| `src/bh/ui/UIHigherOrderComponent.hx` | NEW — interface definition |
| `src/bh/ui/UIMultiAnimGrid.hx` | Implement interface, fix layer incremental flag |
| `src/bh/ui/UICardHandHelper.hx` | Implement interface, optional decoupling |
| `src/bh/ui/screens/UIScreen.hx` | Add registeredComponents, createGrid, createCardHand, auto-wiring in update/mouse/events/clear |
| `src/bh/multianim/MultiAnimBuilder.hx` | Add PVComponent to PlaceholderValues, handle in buildWithParameters |
| `src/bh/base/MacroUtils.hx` | Detect UIHigherOrderComponent, generate PVComponent |
| `src/bh/ui/UIInteractiveRegistry.hx` | NEW — interface (if decoupling CardHand) |
