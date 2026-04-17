# Runtime Systems

## Card Hand Helper

`UICardHandHelper` — Slay the Spire-style card hand with drag-to-play, targeting line, and card-to-card combining. Implements `UIHigherOrderComponent` for screen auto-wiring. Maximum `.manim` integration:

**Files:**
- `src/bh/ui/UICardHandHelper.hx` — main orchestrator (state machine, event routing, animation coordination)
- `src/bh/ui/UICardHandLayout.hx` — pure math for fan arc, linear, and path-based card positioning
- `src/bh/ui/UICardHandTargeting.hx` — targeting line visual + target zone management
- `src/bh/ui/UICardHandTypes.hx` — enums, typedefs, config

**`.manim` integration points:**
- **Card visuals**: programmables with `interactive(w, h, id, bind => "status")` — CardHandHelper's internal `UIRichInteractiveHelper` auto-wires Normal→Hover→Pressed state machine (uses `bind` metadata key, not `autoStatus`)
- **Visual states**: filters in `.manim` conditionals (`@(status=>hover) filter: glow(...)`, `@(status=>disabled) filter: grayscale(...)`) — no manual alpha/scale
- **Animations**: `animatedPath` elements via `createProjectilePath()` with Stretch normalization for draw/discard/rearrange/return
- **Targeting arrow**: chain of `.manim` programmable instances (`arrowSegmentName` + `arrowHeadName`, each receives `valid:bool`) placed evenly along a Stretch-normalized path from origin to cursor. Segments rotated to follow path tangent; head placed at endpoint. `arrowSegmentSpacing` controls density (default 25px, max 30 segments). Arrow endpoint snaps to target interactive center when hovering a valid target (coordinate-transformed via `localToGlobal`/`globalToLocal`); falls back to cursor position when no target hovered. No visual drawn when segment/head names are null (target detection still works)
- **Curves**: easing defined in `.manim` `animatedPath` `easing:` property — no hardcoded `EasingType` enums
- **Path-based layout**: cards distributed along a `.manim` `paths {}` path instead of hardcoded fan/linear

**Game provides a `.manim` file with:**
```manim
paths {
    #cardArc lineTo(0, -30), bezier(100, 0, 50, -60)
    #handShape bezier(0, 0, 400, -80, 800, 0)
}
#drawPath animatedPath { path: cardArc, type: time, duration: 0.3, easing: easeOutBack }
#discardPath animatedPath { path: cardArc, type: time, duration: 0.25, easing: easeInQuad }
#returnPath animatedPath { path: cardArc, type: time, duration: 0.2, easing: easeOutCubic }
#rearrangePath animatedPath { path: cardArc, type: time, duration: 0.15, easing: easeInOutCubic }

#arrowSegment programmable(valid:bool=false) {
    graphics(?(valid) #44FF44 : #FF4444, 2.0) { line(0, 0, 12, 0) }
}
#arrowHead programmable(valid:bool=false) {
    graphics(?(valid) #44FF44 : #FF4444, 2.0) { line(0, -4, 8, 0), line(0, 4, 8, 0) }
}

#card programmable(status:[normal,hover,pressed,disabled]=normal, name:string="") {
    interactive(80, 110, "card", bind => "status", events: [hover, click, push])
    @(status=>hover) filter: glow(#FFFF00, 0.6, 10)
    @(status=>disabled) filter: group(brightness(0.5), grayscale(0.8))
    ninepatch(cards, cardBg, 80, 110): 0, 0
}
```

**Constructor:** `new UICardHandHelper(host:UIComponentHost, builder, ?config)` — takes `UIComponentHost` interface (not `UIScreenBase` directly). `UIScreenBase` implements `UIComponentHost`. Use `addCardHand(builder, config)` on screen for auto-wiring.

**Config:** `CardHandConfig` typedef — layout mode (Fan/Linear/PathLayout), anchor position, card dimensions, fan radius/angle, linear spacing/maxWidth, hover pop/scale/neighborSpread, targeting zones/threshold, card-to-card (allow/highlightScale/hoverPop/hoverScale/spread), pile positions, hand/drag layers, `.manim` element names for paths, segmented arrow chain (segmentName/headName/pathName/segmentSpacing), interactive prefix, `onCardBuilt` callback. See `docs/manim-reference.md` "Card Hand Config" for full field reference.

**Path layout config:** `layoutPathName` (name of path in `paths{}` block), `pathDistribution` (`EvenArcLength` for uniform visual spacing, `EvenRate` for equal rate increments), `pathOrientation` (`Tangent`, `Straight`, `TangentClamped(maxDeg)`).

**Events:** `CardHandEvent` enum — `CardPlayed(id, TargetZone(targetId)|NoTarget)`, `CardCombined(source, target)`, `CardHoverStart/End`, `CardDragStart/End`, `DrawAnimComplete`, `DiscardAnimComplete`.

**API:** `setHand(descriptors)`, `drawCard(descriptor)`, `discardCard(id)`, `updateCardParams(id, params)`, `setCardEnabled(id, bool)`, `getCardResult(id)`, `registerTargetInteractive(wrapper)`, `registerTargetInteractives(wrappers)`, `unregisterTargetInteractive(id)`, `setTargetHighlightCallback(cb)`, `setTargetAcceptsFilter(cb)`, `addTargetingZone(zone)`, `removeTargetingZone(id)`, `clearTargetingZones()`, `setArrowVisible(bool)`, `setArrowSnap(bool)`, `setArrowSnapPointProvider(cb)`, `getTargeting()`, `getTargetingObject()`, `invalidateLayoutCache()`, `handleScreenEvent(event)`, `onMouseMove(x,y)`, `onMouseRelease(x,y)`, `update(dt)`, `dispose()`.

**Construction validation:** Non-null `drawPathName`, `discardPathName`, `returnPathName`, `rearrangePathName` are validated against `builder.hasNode()` at construction time. Invalid names throw immediately instead of at first animation.

**Arrow control:** `setArrowVisible(visible)` enables/disables the targeting arrow visual (target detection still works when hidden). `setArrowSnap(snap)` enables/disables arrow endpoint snapping to target center. `setArrowSnapPointProvider((wrapper) -> FPoint)` customizes where the arrow endpoint snaps to on a target — returns a point in the target interactive's local space; default (null) snaps to interactive center. `getTargeting()` returns the underlying `UICardHandTargeting` instance for advanced control (e.g. integrating with other targeting systems). `getTargetingObject()` returns the arrow's scene object for reparenting into custom z-order hierarchies (e.g. `grid.addExternalObject(cardHand.getTargetingObject(), 8)`).

**Targeting zones:** `TargetingZone` typedef — `{id, x, y, w, h}` rectangles in handContainer local space. When cursor enters any zone during drag, targeting mode activates (card snaps to hand, arrow draws). Multiple zones supported (e.g., one per game panel). Fallback: if cursor is directly over a registered target interactive, targeting also activates regardless of zones. Legacy: if no explicit zones are set, `targetingThresholdY` creates an implicit full-width zone above `anchorY - threshold` (backward compatible). Config: `targetingZones` array in `CardHandConfig`, or runtime via `addTargetingZone()`/`removeTargetingZone()`/`clearTargetingZones()`.

**Callbacks:** `onCardEvent`, `canPlayCard:(CardId, TargetingResult)->Bool` (veto), `canDragCard:(CardId)->Bool` (veto). `onCardBuilt:(CardId, BuilderResult, h2d.Object)->Void` is set via `CardHandConfig` at construction time (final field, not assignable later) — customize card after build by adding buttons, slots, overlays via `result.getSlot()`, `result.getDynamicRef()`, `result.setParameter()`.

**Custom animation callbacks:** Override default card animations for play and discard:
- `customPlayAnimation:(cardId, container, fromX, fromY, onDone) -> Bool` — overrides the default discard-path animation when a card is played via drag-release. Container is in `dragContainer` at `(fromX, fromY)`. Return `true` to handle (MUST call `onDone()` when done), `false` to fall through to default.
- `customDiscardAnimation:(cardId, container, fromX, fromY, onDone) -> Bool` — overrides the default discard-path animation when `discardCard()` is called via API. Same convention.

**Concurrent animations:** Multiple cards can animate simultaneously (draw, discard, rearrange all run in parallel). Cards in `Animating` state skip layout positioning and reject drag, but do NOT block hover/drag of other `InHand` cards. Only one drag at a time (single mouse pointer). No global `HandState` lock — uses per-card `CardState` + `isDragging`/`isTargeting` flags.

**Tracking draw animation:** `drawCard()` uses a tracking animation that dynamically re-stretches the draw path toward the card's current `layoutPos` each frame. The `AnimatedPath` is created with no normalization (raw path coordinates); the stretch transform (`from` → `layoutPos`) is recomputed per frame in `update(dt)`. This means concurrent draws naturally handle shifting hand positions — no stale endpoints. Rotation also tracks `layoutPos.rotation`. Scale/alpha curves from the `.manim` `animatedPath` are applied normally.

**Drag state machine:**
1. `interactive()` emits `UIPush` → helper starts drag, reparents card to `dragContainer`
2. Mouse move: card-to-card check first → targeting zone check (bounds + target fallback) → normal drag
3. Release: card-to-card hover → `CardCombined`; targeting mode + target → `CardPlayed(TargetZone)`; in zone no target → `CardPlayed(NoTarget)`; outside zones → return animation

**Hover detection:** Position-based via `getCardAtBasePosition()` in `onMouseMove` — uses base layout (no hover pop) with nearest-center selection among overlapping OBBs. Does NOT rely on Interactive UIEntering/UILeaving events (which would be blocked by z-order changes). Hovered card is brought to top render layer; z-order restored on un-hover. Card-to-card targets also z-reordered during highlight.

**Hit detection:** `UIInteractiveWrapper.containsPoint()` uses `globalToLocal()` for OBB (Oriented Bounding Box) hit testing — correctly handles rotated interactives via Heaps' transform hierarchy. Card-to-card hit test (`getCardAtPosition`) uses inverse-rotation OBB in reverse z-order (front card wins). Target zones use `UIInteractiveWrapper.containsPoint()` for automatic coordinate transforms.

**Target registration:** Targets are `UIInteractiveWrapper` instances registered via `registerTargetInteractive(wrapper)`. `TargetHighlightCallback(targetId, highlight, metadata)` includes interactive metadata. `TargetAcceptsCallback(cardId, targetId, metadata) -> Bool` filters which targets accept which cards.

## Interaction Controllers

Modal interaction controllers for common targeting/selection flows. Extend `UIDefaultController` to inherit all default behavior (hover, cursor, outside-click) while overriding specific interactions.

**Files:**
- `src/bh/ui/controllers/UIInteractionController.hx` — base class with deferred completion, lifecycle hooks, Escape/right-click cancel
- `src/bh/ui/controllers/UISelectFromHandController.hx` — "select N cards from hand"
- `src/bh/ui/controllers/UIPickTargetController.hx` — "pick a target" (interactive, grid cell, or card)
- `src/bh/ui/controllers/UIInteractionTypes.hx` — result types and config typedefs

**Architecture:** Controllers use the existing `pushController()`/`popController()` stack on `UIScreenBase`. When pushed, the interaction controller intercepts events via `onScreenEvent()` override — consuming card clicks for selection or target picks, while delegating everything else to `super` (default controller behavior). Result delivery is deferred to `update()` for safety (never fires mid-event-processing).

**UIInteractionController** (base class):
- `complete(result)` / `cancel()` — deferred to next `update()` frame
- `onActivate()` / `onDeactivate()` — lifecycle hooks for setup/teardown (restore card states, clear highlights)
- Escape key and right-click cancel built-in
- Callback-based result delivery — callback wraps `popController()` automatically via static `start()` methods

**UISelectFromHandController** — click cards to select/deselect:
- Config: `minCount`, `maxCount`, `filter`, `selectedParam`, `selectedValue`/`deselectedValue`, `autoConfirm`
- Suppresses card drag (`canDragCard = (_) -> false`) during selection
- Dims non-selectable cards via `setCardEnabled(false)` when filter provided
- Auto-confirms when `maxCount` reached (configurable)
- Restores all card visual states and drag on deactivation
- `confirm()` for manual confirmation, `getSelectedCards()`, `getRemainingCount()`

**UIPickTargetController** — pick a target from interactives, grid cells, or cards:
- Config: `validTargetIds`/`targetPrefix`/`filter` for interactives, `grid`+`cellFilter` for cells, `cardHand`+`cardFilter` for cards
- Highlights valid grid cells on activation via `setCellParameter()`
- Intercepts `UIInteractiveEvent(UIClick, ...)` for interactive/card targets
- Overrides `handleClick()` with `grid.cellAtPoint()` for grid cell targets
- Routes mouse move to grid for hover feedback
- Returns `PickTargetResult` enum: `TargetInteractive(id)`, `TargetCell(col, row)`, `TargetCard(cardId)`

**Usage (static `start()` methods handle push/pop automatically):**
```haxe
// Select 2 cards to discard
UISelectFromHandController.start(this, cardHand, {maxCount: 2}, (result) -> {
    if (result != null) discardCards(result.cards);
});

// Pick a target hex
UIPickTargetController.start(this, {grid: hexGrid, cellFilter: (c, r) -> hexGrid.isOccupied(c, r)}, (result) -> {
    if (result != null) switch result { case TargetCell(c, r): attack(c, r); default: }
});

// Composable: select card, then pick target
UISelectFromHandController.start(this, cardHand, {maxCount: 1}, (sel) -> {
    if (sel != null) UIPickTargetController.start(this, {grid: hexGrid}, (tgt) -> {
        if (tgt != null) playCard(sel.cards[0], tgt);
    });
});
```

**CardHandHelper additions for controllers:**
- `findCardIdByInteractiveId(id):Null<CardId>` — maps interactive ID back to card ID
- `isCardInHand(cardId):Bool` — checks if card is in `InHand` or `Hovered` state (not animating/disabled/dragging)

## TweenManager

Lightweight tween/animation system for `h2d.Object` properties. Owned by `ScreenManager`, updated in `ScreenManager.update(dt)`.

**Files:** `src/bh/base/TweenManager.hx`

**Properties** (`TweenProperty` enum): `Alpha(to)`, `X(to)`, `Y(to)`, `ScaleX(to)`, `ScaleY(to)`, `Scale(to)` (both X+Y), `Rotation(to)`, `Custom(getter, setter, to)`.

**Core API:**
```haxe
// Single tween (starts immediately)
screenManager.tweens.tween(obj, 0.5, [Alpha(0.0), X(100.0)], EaseOutQuad);

// Create without starting (for sequences)
var t1 = mgr.createTween(obj, 0.3, [X(100.0)]);
var t2 = mgr.createTween(obj, 0.3, [X(200.0)]);

// Sequential (A then B)
mgr.sequence([t1, t2]).setOnComplete(() -> trace("done"));

// Parallel (A and B together)
mgr.group([t1, t2]).setOnComplete(() -> trace("done"));

// Convenience
mgr.fadeIn(obj, 0.5);
mgr.fadeOut(obj, 0.5, null, true); // removeOnComplete
mgr.moveTo(obj, 100, 200, 1.0);
mgr.scaleTo(obj, 2.0, 1.0);

// Cancellation
mgr.cancel(tween);
mgr.cancelAll(target);         // all tweens on target
mgr.cancelAllChildren(root);   // target + descendants
mgr.clear();                   // all tweens globally

// Query
mgr.hasTweens(obj);
```

**Key behaviors:**
- `Tween.init()` captures current property values as "from" (auto-called on first step)
- `skipFirstDt = true` — discard first `step()` dt to prevent jump after scene graph changes
- Sequence overflow: when a tween finishes mid-step, leftover dt passes to the next tween
- `finish()` jumps to final state immediately
- Cancelled tweens do not fire `onComplete`

**`.manim` transition integration:**
- `transition {}` block in programmable body declares animated transitions for parameter changes
- `IncrementalUpdateContext` uses TweenManager to animate visibility changes instead of instant toggling
- TweenManager auto-injected via `ScreenManager.buildFromResource()` (sets `MultiAnimBuilder.tweenManager`)
- Also injectable via `BuilderResult.setTweenManager()` or `IncrementalUpdateContext.setTweenManager()`
- Falls back to instant visibility without TweenManager (backward compatible)
- See `docs/manim-reference.md` "Transition Declarations" for syntax reference

## Screen Transitions

Animated transitions between screens and dialogs via `ScreenTransition` enum.

**File:** `src/bh/ui/screens/ScreenTransition.hx`

**Enum variants:**
```haxe
enum ScreenTransition {
    None;                                  // instant (default)
    Fade(duration:Float, ?easing:EasingType);
    SlideLeft(duration:Float, ?easing:EasingType);
    SlideRight(duration:Float, ?easing:EasingType);
    SlideUp(duration:Float, ?easing:EasingType);
    SlideDown(duration:Float, ?easing:EasingType);
    Custom(fn:(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
              onComplete:Void -> Void) -> Void);
}
```

**Usage with ScreenManager:**
```haxe
screenManager.switchTo(newScreen, null, Fade(0.3, EaseOutCubic));
screenManager.switchTo(newScreen, myData, Fade(0.3));  // pass data to entering screen
screenManager.switchScreen(MasterAndSingle(master, single), SlideLeft(0.5));
screenManager.modalDialogWithTransition(dialog, caller, "confirm", null, SlideUp(0.3));
screenManager.modalDialogWithTransition(dialog, caller, "confirm", myData, SlideUp(0.3));
screenManager.closeDialogWithTransition(Fade(0.2));
screenManager.finalizeTransition(); // jump to end immediately
```

**Layer ordering defaults** (configurable via `SceneLayerConfig`): `content=2`, `master=4`, `overlay=5`, `dialog=6`. Must satisfy `content < master < overlay < dialog`.

**Transition behavior:**
- Both old and new screen roots are in scene during transition
- Input routed to new screen only (`activeScreenControllers` updated immediately)
- `isTransitioning` flag true while animating
- All transition tweens use `skipFirstDt = true` to prevent stutter
- If a new transition starts while one is in progress, the current one finalizes immediately

## Modal Dialog Overlay

Configurable darkening/blur background behind modal dialogs. Overlay is an `h2d.Bitmap` at layer 5 (between master and dialog), animated via TweenManager.

**Config typedef** (`UIScreen.hx`):
```haxe
typedef ModalOverlayConfig = {
    var ?color:Int;      // 0xRRGGBB, default 0x000000
    var ?alpha:Float;    // 0.0-1.0, default 0.5
    var ?fadeIn:Float;   // seconds (overrides transition duration)
    var ?fadeOut:Float;  // seconds (overrides transition duration)
    var ?blur:Float;     // blur radius on underlying screens, 0 = none
}
```

**Setting in code:**
```haxe
class MyDialog extends UIScreenBase {
    public function load() {
        // ... build dialog ...
        modalOverlayConfig = { color: 0x000000, alpha: 0.7, fadeIn: 0.3, fadeOut: 0.2 };
    }
}
```

**Setting via `.manim` settings{}:**
```manim
#myDialog programmable(dialogText="Are you sure?",
    overlayColor:color=#000000, overlayAlpha:float=0.5,
    overlayFadeIn:float=0.3, overlayFadeOut:float=0.2) {
    settings {
        overlay.color:color => $overlayColor,
        overlay.alpha:float => $overlayAlpha,
        overlay.fadeIn:float => $overlayFadeIn,
        overlay.fadeOut:float => $overlayFadeOut
    }
    // dialog content...
}
```

**Reading from .manim in screen's load():**
```haxe
final overlayFromManim = parseOverlaySettings(dialog.builderResults.rootSettings);
if (overlayFromManim != null)
    modalOverlayConfig = overlayFromManim;
```

**Priority:** `.manim` settings override code-set config (set `modalOverlayConfig` before `load()`, then `.manim` settings overwrite in `load()`).

**Overlay lifecycle:** ScreenManager reads `modalOverlayConfig` after `dialog.load()` → creates overlay bitmap → tweens alpha in sync with transition → tweens alpha out on close → removes overlay in cleanup.

**Event routing while dialog is open** (known asymmetry): when a dialog opens over `MasterAndSingle`, `overrideActiveScreenControllers = [dialog, oldMaster]` — the dialog is first in the controller list but the underlying master still receives controller events. Opening a dialog over `Single` mode blocks instead (`overrideActiveScreenControllers = [dialog]`). There is no per-dialog `blockUnderlying:Bool` flag yet. If you need a fully input-blocking modal over a master/single layout, switch to `Single` before opening the dialog, or have the master screen gate its own input handlers. See the two `case Dialog(...)` branches under `Single(...)` vs `MasterAndSingle(...)` in `ScreenManager.updateScreenMode` for the asymmetry.

## Tooltip/Panel Fade Transitions

Both `UITooltipHelper` and `UIPanelHelper` support optional fade-in/fade-out animations via TweenManager.

**Constructor:** Pass optional `TweenManager` as last parameter:
```haxe
var tooltip = new UITooltipHelper(screen, builder, {fadeIn: 0.15, fadeOut: 0.1}, screenManager.tweens);
var panel = new UIPanelHelper(screen, builder, {fadeIn: 0.2, fadeOut: 0.15}, screenManager.tweens);
```

**Auto-wired PanelHelper** (recommended): `createPanelHelper()` creates a `UIPanelHelper` that is auto-wired for outside-click handling. `handleOutsideClick()` runs in `dispatchScreenEvent()`, `checkPendingClose()` runs in `update()`. No manual boilerplate needed.
```haxe
// In screen's load():
panelHelper = createPanelHelper(builder, {fadeIn: 0.2});

// In onScreenEvent — just handle clicks, no handleOutsideClick() needed:
case UIInteractiveEvent(UIClick, id, _): panelHelper.open(id, "panel");

// No checkPendingClose() in update() needed — super.update(dt) handles it.
```
Manual wiring via `new UIPanelHelper(...)` still works. Auto-wiring only activates with `createPanelHelper()` or explicit `registerPanelHelper(helper)` / `unregisterPanelHelper(helper)`.

**TooltipDefaults:** `?fadeIn:Float` (default 0.15), `?fadeOut:Float` (default 0.1). Tooltip fades in on show, fades out on hide.

**PanelDefaults:** `?fadeIn:Float` (default 0), `?fadeOut:Float` (default 0). Panels default to instant (backward compatible).

**Behavior:**
- Interactives are unregistered immediately on close (before fade-out completes) — panel is logically dead during fade
- `EVENT_PANEL_CLOSE` fires immediately on close, not after fade
- If TweenManager is null or fade duration is 0, instant behavior is preserved (backward compatible)
- Edge cases handled: hide during fade-in cancels tween; show during fade-out cancels previous and removes immediately

## Scrollable Screen

`UIScrollableScreen` — abstract screen base class with whole-screen mousewheel scrolling. Extends `UIScreenBase`.

**File:** `src/bh/ui/screens/UIScrollableScreen.hx`

**Architecture:** Uses `scrollContent:h2d.Layers` as a child of `root`. All content is added to `scrollContent` (via `addObjectToLayer` override). Scroll adjusts `scrollContent.y` while `root.y` stays at 0, preventing conflicts with transition animations that tween `root`.

**Usage:**
```haxe
class MyScreen extends UIScrollableScreen {
    public function new(sm:ScreenManager) {
        super(sm, {scrollSpeed: 30, smoothing: 12});
    }
}
```

**Config:** `ScrollConfig` typedef — `?scrollSpeed:Float` (default 30), `?smoothing:Float` (default 12, 0 = instant).

**Auto-measure:** Content height auto-measured via `getBounds` each frame. Scroll disabled when content fits viewport. `setContentHeight(h)` for manual override (disables auto-measure).

**Key implementation detail:** `UIScreenBase.clear()` calls `root.removeChildren()` which detaches `scrollContent`. The `onClear()` override re-attaches it and resets scroll state. Subclasses MUST call `super.onClear()`.

**ScreenManager.sceneWidth/sceneHeight:** Getters returning actual visible scene dimensions (`s2d.width`/`s2d.height`). With AutoZoom integer scaling, these differ from configured dimensions (e.g., configured 1280×720 but actual 2310×1260 on hi-DPI).

**Standalone helper:** `UIScrollHelper` (`src/bh/ui/UIScrollHelper.hx`) — mask-based scroll for use outside the screen system. Shares `ScrollConfig` typedef.

## FloatingTextHelper

AnimatedPath-driven floating text manager for damage numbers, heal text, status effects, etc.

**File:** `src/bh/ui/FloatingTextHelper.hx`

**API:**
```haxe
var helper = new FloatingTextHelper(?parent);

// Spawn text driven by AnimatedPath
helper.spawn(text, font, x, y, animPath, ?color, absolutePosition);

// Spawn arbitrary h2d.Object
helper.spawnObject(obj, x, y, animPath, absolutePosition);

// Update all instances (call from game loop)
helper.update(dt);

// Remove all immediately
helper.clear();

// Instance count
helper.count;
```

**Position modes:**
- `absolutePosition = false` (default): path position is offset from spawn (x, y). Use with `Anchor` normalization.
- `absolutePosition = true`: path position IS world coordinates. Use with `Stretch(startPoint, endPoint)` normalization.

**AnimatedPath state applied:** position, alpha, scale, rotation. Color applied to `h2d.Text` only when colorCurve is active.

**Usage pattern:**
```haxe
// In .manim:
paths { #dmgPath path { bezier(60, -25, 30, -50) } }
curves { #dmgAlpha curve { points: [(0, 1.0), (0.6, 0.8), (1.0, 0.0)] } }
#dmgAnim animatedPath { path: dmgPath, duration: 1.0, 0.0: alphaCurve: dmgAlpha }

// In game code:
var floatingText = new FloatingTextHelper(overlayRoot);
var ap = builder.createAnimatedPath("dmgAnim", Stretch(startPos, endPos));
floatingText.spawn("-42", font, startPos.x, startPos.y, ap, 0xFF0000, true);
```

**Instance lifecycle:** `onComplete` callback fires when AnimatedPath is done. Completed instances auto-removed from manager and object removed from scene.

## ScreenShakeHelper

Lightweight additive screen shake for impact feedback. Multiple concurrent shakes stack naturally.

**File:** `src/bh/ui/ScreenShakeHelper.hx`

**API:**
```haxe
var shake = new ScreenShakeHelper(target);

// Basic shake with linear decay
shake.shake(intensity, duration);

// Directional (e.g. horizontal recoil, vertical landing)
shake.shakeDirectional(intensity, duration, dirX, dirY);

// Custom decay curve (receives 0..1 remaining ratio, returns factor)
shake.shakeWithCurve(intensity, duration, (remaining) -> remaining * remaining);

// Call from game loop
shake.update(dt);

// Immediate stop (removes residual offset)
shake.stop();

// Query
shake.isShaking;
```

**Usage in screen:**
```haxe
var shake:ScreenShakeHelper;

override public function load() {
    shake = new ScreenShakeHelper(root);
}

override public function update(dt:Float) {
    super.update(dt);
    shake.update(dt);
}

// On damage:
shake.shake(8.0, 0.4);

// Horizontal recoil:
shake.shakeDirectional(6.0, 0.2, 1.0, 0.0);

// With .manim curve:
var curve = builder.getCurve("heavyImpact");
shake.shakeWithCurve(10.0, 0.5, curve);
```

**Key behaviors:**
- **Additive** — concurrent shakes stack (explosion + hit at same time)
- **Decay** — linear by default, pluggable curve for custom feel
- **Directional** — `dirX`/`dirY` mask axes (1.0 = full, 0.0 = none)
- **Non-destructive** — applies per-frame offsets as *deltas* relative to the previous frame, so gameplay can freely move the target (camera scroll, layout changes, animation) without the shake fighting it back to a captured baseline. `stop()` removes the residual offset
- **Uniform jitter** — `hxd.Rand` (seeded from startup time) produces proper uniform angles
- **No allocations per frame** — reuses array, swap-removes on completion

## HeapsUtils

Small Haxe helpers on top of Heaps.

**File:** `src/bh/base/HeapsUtils.hx`

- `solidTile(color:Int, w:Int, h:Int):h2d.Tile` — pixel-perfect solid-color tile, strict-D semantics (top byte of `color` = alpha). Top-byte=0 is treated as opaque to keep bare `0xRRGGBB` callers (e.g. `TileHelper.generatedRectColor(16, 16, 0x00FFFF)`) rendering as before. For fully transparent, use `h2d.Tile.fromColor` directly. Backed by a shared 1×1 GPU texture stretched to `(w, h)`.
- `solidBitmap(color:Int, w:Int, h:Int, ?parent:h2d.Object):h2d.Bitmap` — thin `h2d.Bitmap` wrapper around `solidTile`. Same alpha handling.
- `safeDetach(obj)` — detach from parent without triggering Heaps' `onRemove()` cascade (which destroys `h2d.Graphics` content). Use when reparenting live scene objects.
- `traceH2dObjectTreeString(obj)` / `getH2dObjectTreeString(obj)` — debug dump of an h2d subtree.

Both `solidTile` and `solidBitmap` are the same primitive the builder (`generatePlaceholderBitmap`) and codegen (`SolidColor` / `Cross`) use for `generated(color(...))` — use them in game code when you need a tinted rect and want strict-D alpha to Just Work.
