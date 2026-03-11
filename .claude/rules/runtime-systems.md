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
- **Targeting arrow**: `.manim` programmable (receives `valid:bool` param, positioned+rotated+scaled between origin and target). Arrow endpoint snaps to target interactive center when hovering a valid target (coordinate-transformed via `localToGlobal`/`globalToLocal`); falls back to cursor position when no target hovered. Falls back to `h2d.Graphics` bezier if no programmable provided
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

#targetingArrow programmable(valid:bool=false) {
    graphics(?(valid) #44FF44 : #FF4444, 2.0) { line(0, 0, 100, 0) }
}

#card programmable(status:[normal,hover,pressed,disabled]=normal, name:string="") {
    interactive(80, 110, "card", bind => "status", events: [hover, click, push])
    @(status=>hover) filter: glow(#FFFF00, 0.6, 10)
    @(status=>disabled) filter: group(brightness(0.5), grayscale(0.8))
    ninepatch(cards, cardBg, 80, 110): 0, 0
}
```

**Constructor:** `new UICardHandHelper(host:UIComponentHost, builder, ?config)` — takes `UIComponentHost` interface (not `UIScreenBase` directly). `UIScreenBase` implements `UIComponentHost`. Use `addCardHand(builder, config)` on screen for auto-wiring.

**Config:** `CardHandConfig` typedef — layout mode (Fan/Linear/PathLayout), anchor position, fan radius/angle, hover pop/scale, targeting zones/threshold, pile positions, layers, `.manim` element names for paths/arrow, interactive prefix, `onCardBuilt` callback, `cardToCardHighlightScale`.

**Path layout config:** `layoutPathName` (name of path in `paths{}` block), `pathDistribution` (`EvenArcLength` for uniform visual spacing, `EvenRate` for equal rate increments), `pathOrientation` (`Tangent`, `Straight`, `TangentClamped(maxDeg)`).

**Events:** `CardHandEvent` enum — `CardPlayed(id, TargetZone(targetId)|NoTarget)`, `CardCombined(source, target)`, `CardHoverStart/End`, `CardDragStart/End`, `DrawAnimComplete`, `DiscardAnimComplete`.

**API:** `setHand(descriptors)`, `drawCard(descriptor)`, `discardCard(id)`, `updateCardParams(id, params)`, `setCardEnabled(id, bool)`, `getCardResult(id)`, `registerTargetInteractive(wrapper)`, `registerTargetInteractives(wrappers)`, `unregisterTargetInteractive(id)`, `setTargetHighlightCallback(cb)`, `setTargetAcceptsFilter(cb)`, `addTargetingZone(zone)`, `removeTargetingZone(id)`, `clearTargetingZones()`, `setArrowSnapPointProvider(cb)`, `getTargetingObject()`, `handleScreenEvent(event)`, `onMouseMove(x,y)`, `onMouseRelease(x,y)`, `update(dt)`, `dispose()`.

**Arrow snap point:** `setArrowSnapPointProvider((wrapper) -> FPoint)` customizes where the arrow endpoint snaps to on a target. Returns a point in the target interactive's local space. Default (null): snaps to interactive center. `getTargetingObject()` returns the arrow's scene object for reparenting into custom z-order hierarchies (e.g. `grid.addExternalObject(cardHand.getTargetingObject(), 8)`).

**Targeting zones:** `TargetingZone` typedef — `{id, x, y, w, h}` rectangles in handContainer local space. When cursor enters any zone during drag, targeting mode activates (card snaps to hand, arrow draws). Multiple zones supported (e.g., one per game panel). Fallback: if cursor is directly over a registered target interactive, targeting also activates regardless of zones. Legacy: if no explicit zones are set, `targetingThresholdY` creates an implicit full-width zone above `anchorY - threshold` (backward compatible). Config: `targetingZones` array in `CardHandConfig`, or runtime via `addTargetingZone()`/`removeTargetingZone()`/`clearTargetingZones()`.

**Callbacks:** `onCardEvent`, `canPlayCard:(CardId, TargetingResult)->Bool` (veto), `canDragCard:(CardId)->Bool` (veto), `onCardBuilt:(CardId, BuilderResult, h2d.Object)->Void` (customize card after build — add buttons, slots, overlays via `result.getSlot()`, `result.getDynamicRef()`, `result.setParameter()`).

**Concurrent animations:** Multiple cards can animate simultaneously (draw, discard, rearrange all run in parallel). Cards in `Animating` state skip layout and reject drag, but do NOT block hover/drag of other `InHand` cards. Only one drag at a time (single mouse pointer). No global `HandState` lock — uses per-card `CardState` + `isDragging`/`isTargeting` flags.

**Drag state machine:**
1. `interactive()` emits `UIPush` → helper starts drag, reparents card to `dragContainer`
2. Mouse move: card-to-card check first → targeting zone check (bounds + target fallback) → normal drag
3. Release: card-to-card hover → `CardCombined`; targeting mode + target → `CardPlayed(TargetZone)`; in zone no target → `CardPlayed(NoTarget)`; outside zones → return animation

**Hover detection:** Position-based via `getCardAtBasePosition()` in `onMouseMove` — uses base layout (no hover pop) with nearest-center selection among overlapping OBBs. Does NOT rely on Interactive UIEntering/UILeaving events (which would be blocked by z-order changes). Hovered card is brought to top render layer; z-order restored on un-hover. Card-to-card targets also z-reordered during highlight.

**Hit detection:** `UIInteractiveWrapper.containsPoint()` uses `globalToLocal()` for OBB (Oriented Bounding Box) hit testing — correctly handles rotated interactives via Heaps' transform hierarchy. Card-to-card hit test (`getCardAtPosition`) uses inverse-rotation OBB in reverse z-order (front card wins). Target zones use `UIInteractiveWrapper.containsPoint()` for automatic coordinate transforms.

**Target registration:** Targets are `UIInteractiveWrapper` instances registered via `registerTargetInteractive(wrapper)`. `TargetHighlightCallback(targetId, highlight, metadata)` includes interactive metadata. `TargetAcceptsCallback(cardId, targetId, metadata) -> Bool` filters which targets accept which cards.

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

**Layer ordering constants:** `layerContent=2`, `layerMaster=4`, `layerOverlay=5`, `layerDialog=6`

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
