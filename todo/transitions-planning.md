# Transitions & Animation System — Planning

## Current State

**What exists:**
- `TweenUtils.hx` — 12+ easing functions (pure math, no scheduler)
- `AnimatedPath` — path-based property animation (position, alpha, scale, rotation, color, custom curves)
- Dropdown panel — only UI element with a transition (linear alpha fade, manual timer)
- `UIElementUpdatable.update(dt)` — per-frame hook, only used by dropdown and draggable
- `IncrementalUpdateContext` — instant parameter changes, no interpolation
- Combo-built elements (button, checkbox) — swap entire h2d.Object on state change

**What's missing:**
- Tween scheduler/manager
- UI state transition animations
- Screen transitions
- Floating text / damage numbers
- Tooltip show/hide animations (tooltip system itself planned separately in tooltip-planning.md)

---

## Design Options

### Option A: Standalone Tween Manager

A lightweight tween engine that operates directly on `h2d.Object` properties. Sits **outside** the builder/incremental system — doesn't touch .manim or codegen at all.

```haxe
// Core API
class Tween {
    public var target:h2d.Object;
    public var duration:Float;
    public var easing:EasingType;
    public var onComplete:Void->Void;
    // property targets
    public var toAlpha:Null<Float>;
    public var toX:Null<Float>;
    public var toY:Null<Float>;
    public var toScaleX:Null<Float>;
    public var toScaleY:Null<Float>;
    public var toRotation:Null<Float>;
}

class TweenManager {
    public function add(obj:h2d.Object, duration:Float, props:TweenProps, ?easing:EasingType):Tween;
    public function cancel(tween:Tween):Void;
    public function cancelAll(obj:h2d.Object):Void;
    public function update(dt:Float):Void; // called from ScreenManager.update()
}
```

Usage:
```haxe
// Fade out dialog
tweens.add(dialog.getObject(), 0.3, { alpha: 0, y: dialog.y - 20 }, easeOutCubic)
    .onComplete = () -> removeDialog();

// Checkbox flip (scale X from 1 to 0, swap content, then 0 to 1)
tweens.add(checkbox.getObject(), 0.1, { scaleX: 0 }, easeInQuad)
    .onComplete = () -> {
        checkbox.doRealRedraw(); // swap the underlying combo image
        tweens.add(checkbox.getObject(), 0.1, { scaleX: 1 }, easeOutQuad);
    };
```

**Pros:** Simple, no framework changes, works with any h2d.Object, familiar API.
**Cons:** Completely external to .manim, can't be declared in .manim files, manual wiring for every UI element.

---

### Option B: Transition Properties in .manim (Declarative)

Extend the .manim language with `transition` blocks on programmable elements. The builder generates transition-aware state switching.

```manim
#myCheckbox programmable(checked:bool=false, status:[normal,hover,pressed]=normal, disabled:bool=false) {
    transition {
        checked: flipX(0.15, easeOutQuad)     // horizontal flip effect
        status: crossfade(0.1)                 // alpha crossfade between states
        disabled: fade(0.2)                    // simple alpha fade
    }

    @(checked => true) bitmap(sheet("ui"), "check_on"): 0, 0
    @(checked => false) bitmap(sheet("ui"), "check_off"): 0, 0
}
```

The builder, instead of instantly swapping visibility, would:
1. Keep both old and new states in the scene graph
2. Animate alpha/scale/position between them over the specified duration
3. Remove the old state when transition completes

Transition types:
- `fade(duration, ?easing)` — alpha crossfade
- `flipX(duration, ?easing)` — scale X to 0, swap, scale X back to 1
- `flipY(duration, ?easing)` — same for Y
- `slide(duration, direction, ?easing)` — slide out old, slide in new
- `crossfade(duration, ?easing)` — simultaneous alpha blend
- `none` — instant (current behavior, default)

**Pros:** Declarative, lives in .manim, no application code needed for transitions.
**Cons:** Significant parser/builder changes, combo-build strategy needs rework to keep both states alive during transition, increases complexity of the incremental system.

---

### Option C: Hybrid — Tween Manager + .manim Transition Hints

Lightweight tween manager (Option A) as core infrastructure. Then add optional `.manim` transition declarations that the builder auto-wires to the tween manager. Application code can also use the tween manager directly for ad-hoc animations.

```manim
#myCheckbox programmable(checked:bool=false, status:[normal,hover,pressed]=normal) {
    transition(checked): flipX(0.15)
    transition(status): crossfade(0.1)

    @(checked => true) bitmap(sheet("ui"), "check_on"): 0, 0
    @(checked => false) bitmap(sheet("ui"), "check_off"): 0, 0
}
```

The builder generates an `IncrementalUpdateContext` that, when `setParameter("checked", true)` is called:
1. Looks up the transition spec for `checked`
2. Creates a tween via the tween manager
3. Animates the visual swap

But the tween manager is also available standalone for screen transitions, floating text, etc.:
```haxe
// Screen transition — not in .manim, pure application code
screenManager.transition(newScreen, Fade(0.3, easeOutCubic));

// Floating damage number — pure application code
var text = new h2d.Text(font, scene);
text.text = "-42";
tweens.add(text, 1.0, { y: text.y - 60, alpha: 0 }, easeOutQuad)
    .onComplete = () -> text.remove();
```

**Pros:** Best of both worlds — declarative for common patterns, imperative for custom animations. Tween manager is useful across the entire application. .manim transitions are opt-in.
**Cons:** Two systems to understand. Moderate parser/builder changes.

---

### Option D: AnimatedPath-Based (Reuse Existing)

Instead of a new tween system, extend `AnimatedPath` to work as a general-purpose property animator. It already has curves, events, easing, alpha, scale, rotation, color, custom values.

```haxe
// Reuse AnimatedPath for UI transitions
var fadeOut = builder.createAnimatedPath("dialogFadeOut");
fadeOut.bindObject(dialog.getObject()); // new API: bind to arbitrary object
fadeOut.start();
// path definition in .manim drives alpha, y, scale curves
```

```manim
paths {
    dialogFadeOut: line(0,0, 0,-20)  // 20px upward movement
}

#dialogFadeOut animatedPath {
    path: dialogFadeOut
    duration: 0.3
    0.0: alphaCurve: easeOutCubic   // fade out
}
```

**Pros:** Reuses proven system, no new tween engine needed, already has curve infrastructure.
**Cons:** Paths are overkill for simple alpha/position tweens. Awkward to define a "checkbox flip" as a path. Path objects carry a lot of overhead for simple transitions.

---

## Recommendation

**Option C (Hybrid)** is the most practical:

1. **Phase 1: Tween Manager** — standalone, no .manim changes, immediately useful
   - Enables: screen transitions, floating text, dialog animations, tooltip fade-in/out
   - Small, testable, no regressions possible

2. **Phase 2: .manim transition declarations** — opt-in syntax for programmable state transitions
   - Enables: checkbox flip, button hover effects, parameter-driven transitions
   - Only changes builder behavior when `transition` is declared

3. **Phase 3: UI element integration** — built-in controls use transitions automatically
   - Checkbox, button, tabs get default transitions (overridable)

---

## Tween Manager Design (Phase 1)

### Core Classes

```
TweenManager          — owns tween list, update(dt), add/cancel API
Tween                 — single property animation: target, from->to, duration, easing, callbacks
TweenSequence         — chain of tweens (A then B then C)
TweenGroup            — parallel tweens (A and B together)
```

### Properties to Animate

```haxe
enum TweenProperty {
    Alpha(target:Float);
    X(target:Float);
    Y(target:Float);
    ScaleX(target:Float);
    ScaleY(target:Float);
    Scale(target:Float);        // both X and Y
    Rotation(target:Float);
    Custom(getter:Void->Float, setter:Float->Void, target:Float);
}
```

### Lifecycle

```
TweenManager created per ScreenManager (or per Screen)
    │
    ├── ScreenManager.update(dt) calls tweenManager.update(dt)
    │
    ├── add() captures current property value as "from"
    │
    ├── update() interpolates: value = from + (to - from) * easing(elapsed / duration)
    │
    ├── onComplete callback fires when elapsed >= duration
    │
    └── cancel() / cancelAll() for cleanup
```

### Convenience Wrappers

```haxe
// On TweenManager or as extension methods
function fadeIn(obj, duration, ?easing):Tween;
function fadeOut(obj, duration, ?easing, ?removeOnComplete):Tween;
function moveTo(obj, x, y, duration, ?easing):TweenGroup;
function scaleTo(obj, scale, duration, ?easing):Tween;
function slideIn(obj, fromDir, distance, duration, ?easing):TweenGroup;
function slideOut(obj, toDir, distance, duration, ?easing):TweenGroup;

// Sequence helper
function sequence(tweens:Array<Tween>):TweenSequence;
function parallel(tweens:Array<Tween>):TweenGroup;
```

---

## Use Case Solutions

### 1. Checkbox Flip Switch

**Phase 1 (tween manager only):**
Override `doRedraw()` in UIMultiAnimCheckbox (or subclass) to animate instead of instant swap.

```haxe
override function doRedraw() {
    var oldObj = currentObject;
    var newObj = lookupComboObject(currentState);
    // Flip: scale X old to 0, replace, scale X new from 0 to 1
    tweens.add(oldObj, 0.08, { scaleX: 0 }, easeInQuad).onComplete = () -> {
        swapObject(newObj);
        newObj.scaleX = 0;
        tweens.add(newObj, 0.08, { scaleX: 1 }, easeOutQuad);
    };
}
```

**Phase 2 (.manim declarations):**
```manim
#flipCheck programmable(checked:bool=false) {
    transition(checked): flipX(0.15, easeOutQuad)
    @(checked) bitmap(sheet("ui"), "on"): 0, 0
    @default bitmap(sheet("ui"), "off"): 0, 0
}
```

**Alternative — stateAnim approach:**
Could also use `stateanim construct(...)` with an animation that plays through the flip frames. This already works today, just needs animation assets:
```manim
stateanim construct(sheet("flipSwitch"), frames: "flip_$checked$"): 0, 0
```
This approach uses sprite-sheet frame animation rather than property tweening. Good for hand-crafted pixel art transitions but requires dedicated art assets.

### 2. Dialog Fade Out + Move Up

```haxe
function closeDialog(dialog:UIScreen) {
    var root = dialog.root;
    tweens.parallel([
        tweens.add(root, 0.25, { alpha: 0 }, easeOutCubic),
        tweens.add(root, 0.25, { y: root.y - 30 }, easeOutCubic),
    ]).onComplete = () -> screenManager.removeDialog(dialog);
}
```

### 3. Screen Transitions

**Approach A — ScreenManager built-in transitions:**

```haxe
enum ScreenTransition {
    None;                          // instant (current behavior)
    Fade(duration:Float);          // crossfade
    SlideLeft(duration:Float);     // old slides left, new slides from right
    SlideRight(duration:Float);
    SlideUp(duration:Float);
    SlideDown(duration:Float);
    Custom(fn:TweenManager->h2d.Object->h2d.Object->Void); // full control
}

// Usage
screenManager.switchTo(newScreen, Fade(0.3));
screenManager.openDialog(dialog, SlideUp(0.2));
```

ScreenManager during transition:
1. Both old and new screen roots are in the scene
2. Old root animates out, new root animates in (or crossfade)
3. On complete, old root removed, new screen becomes active
4. Input blocked during transition (or routed to new screen)

**Approach B — Screen-level hooks:**

```haxe
// In UIScreenBase
function onShow(tweens:TweenManager):Null<Tween> { return null; } // override for custom
function onHide(tweens:TweenManager):Null<Tween> { return null; } // override for custom
```

Each screen controls its own enter/exit animation. ScreenManager waits for `onHide` to complete before removing. More flexible, less centralized.

**Recommendation:** Both. ScreenManager has default transitions (Approach A), screens can override with hooks (Approach B).

### 4. Tooltips

Integrates with tooltip-planning.md. The tooltip controller uses tween manager for show/hide:

```haxe
// In UITooltipController
function showTooltip(obj:h2d.Object) {
    obj.alpha = 0;
    obj.y -= 4;  // slight upward entrance
    tweens.parallel([
        tweens.add(obj, 0.15, { alpha: 1 }, easeOutCubic),
        tweens.add(obj, 0.15, { y: obj.y + 4 }, easeOutCubic),
    ]);
}

function hideTooltip(obj:h2d.Object, onDone:Void->Void) {
    tweens.add(obj, 0.1, { alpha: 0 }, easeOutQuad).onComplete = onDone;
}
```

The `TooltipConfig` from tooltip-planning.md gets a `transition` field:
```haxe
class TooltipConfig {
    // ... existing fields ...
    public var showTransition:TooltipTransition; // Fade, SlideUp, Scale, None
    public var hideTransition:TooltipTransition;
}
```

### 5. Floating Text (Damage Numbers, Effects)

**Standalone utility class** that uses the tween manager:

```haxe
class FloatingText {
    public static function spawn(
        parent:h2d.Object,
        text:String,
        font:h2d.Font,
        x:Float, y:Float,
        config:FloatingTextConfig,  // color, duration, riseHeight, easing, scale curve, etc.
        tweens:TweenManager
    ):h2d.Text;
}

// Presets
FloatingText.damage(parent, "-42", x, y, tweens);        // red, rise + fade
FloatingText.heal(parent, "+15", x, y, tweens);           // green, rise + fade
FloatingText.crit(parent, "CRIT -128", x, y, tweens);    // large, shake, red
FloatingText.info(parent, "Level Up!", x, y, tweens);     // gold, scale bounce
```

**Config:**
```haxe
typedef FloatingTextConfig = {
    ?color:Int,
    ?duration:Float,          // total lifetime (default 1.0)
    ?riseHeight:Float,        // pixels to float upward (default 40)
    ?startScale:Float,        // initial scale (default 1.0)
    ?endScale:Float,          // final scale (default 1.0)
    ?fadeStart:Float,          // when to start fading (0.0-1.0, default 0.5)
    ?easing:EasingType,       // movement easing (default easeOutCubic)
    ?spreadX:Float,           // random horizontal spread
    ?stagger:Float,           // delay for batch spawning (avoids overlap)
}
```

**Alternative — .manim particle-based:**
Particles already support `animFile` and could be extended with text rendering. But this is over-engineered for damage numbers. A simple tween-based approach is more appropriate.

**Alternative — AnimatedPath-based:**
```manim
paths {
    floatUp: line(0, 0, 0, -50)
}
#floatingDmg animatedPath {
    path: floatUp
    duration: 1.0
    easing: easeOutCubic
    0.0: alphaCurve: linear
    0.6: alphaCurve: easeInQuad, 1.0, 0.0
    0.0: scaleCurve: easeOutBack
}
```
Then attach a text object to this animated path. Works but requires a path per text style.

---

## .manim Transition Syntax (Phase 2)

### Option 2A: Top-level `transition` block

```manim
#button programmable(status:[normal,hover,pressed]=normal) {
    transition(status): crossfade(0.1)

    @(status => normal)  bitmap(...): 0, 0
    @(status => hover)   bitmap(...): 0, 0
    @(status => pressed) bitmap(...): 0, 0
}
```

Parser adds `transitions: Map<String, TransitionSpec>` to the programmable node.
Builder checks transitions map when `setParameter` changes a value that has a transition spec.

### Option 2B: Per-conditional `transition` modifier

```manim
#button programmable(status:[normal,hover,pressed]=normal) {
    @(status => normal, transition: crossfade(0.1))  bitmap(...): 0, 0
    @(status => hover, transition: crossfade(0.1))   bitmap(...): 0, 0
    @(status => pressed, transition: none)            bitmap(...): 0, 0  // instant
}
```

More granular — different transitions per state. But more verbose.

### Option 2C: Element-level `transition` property

```manim
#dialog programmable(visible:bool=true) {
    transition: fade(0.3, easeOutCubic)   // applies to entire root

    @(visible) {
        ninepatch(...): 0, 0
        text(...): 10, 10
    }
}
```

The `transition` property on a group or root means "when this element's visibility changes (due to conditionals), animate the transition instead of instant show/hide."

**Recommendation:** Option 2A for parameter-level transitions (checkbox flip, button states). Option 2C for visibility transitions (dialog show/hide). Both can coexist.

---

## Implementation Phases

### Phase 1: TweenManager (foundation) ✅ DONE
- `src/bh/base/TweenManager.hx` — Tween, TweenSequence, TweenGroup, TweenManager
- Uses `FloatTools.applyEasing()` (existing easing functions)
- Integration: `ScreenManager.update(dt)` calls `tweens.update(dt)`
- Access: `screenManager.tweens`
- 57 unit tests in `TweenManagerTest.hx`

### Phase 2: Screen Transitions + Modal Overlay ✅ DONE
- `ScreenTransition` enum: None, Fade, SlideLeft/Right/Up/Down, Custom
- `switchScreen()`, `switchTo()`, `modalDialogWithTransition()`, `closeDialogWithTransition()`
- `ModalOverlayConfig` typedef + `parseOverlaySettings()` for `.manim` settings integration
- Overlay at layer 5 (between master=4 and dialog=6), blur filter support
- `OkCancelDialog` reads overlay from `.manim`, supports `closeTransition`

### Phase 3: Tooltip/Panel Transitions
- Integrate with tooltip-planning.md
- Tooltip controller uses tween manager for show/hide
- Default: fade-in 0.15s, fade-out 0.1s

### Phase 4: FloatingText Utility
- `FloatingText` class with presets
- Uses tween manager internally
- Or: consider if AnimatedPath is a better fit

### Phase 5: .manim Transition Declarations (optional)
- Parser: `transition` keyword in programmable body
- Builder: transition-aware `setParameter` in IncrementalUpdateContext
- Both combo-built and incremental elements supported

### Phase 6: Built-in UI Control Transitions (optional)
- Default transitions in checkbox, button, tabs
- Configurable via settings (`transition => "flipX(0.15)"`)
- Opt-out with `transition => "none"`

---

## Open Questions

1. **TweenManager ownership** — ✅ Resolved: one on ScreenManager (global), accessed via `screenManager.tweens`

2. **Combo-build transition** — combo-built elements pre-build all permutations. During transition, both old and new need to be in scene. Currently `doRedraw()` removes old and adds new. Need to keep old temporarily.
   - Solution: `doRedraw()` checks for transition spec. If present, adds new alongside old, starts tween, removes old on complete.

3. **Transition + incremental** — incremental updates toggle visibility instantly. A transition-aware version would need to animate alpha instead of toggling `.visible`.
   - Solution: wrap `obj.visible = true/false` with `obj.alpha = 0 -> tween to 1` / `tween alpha to 0 -> visible = false`.

4. **Interrupted transitions** — ✅ Resolved: `Tween.init()` captures current property value as "from", so interrupted tweens pick up from current state. `finalizeTransition()` immediately completes any in-progress transition if a new one starts.

5. **Floating text pooling** — for damage numbers in a game, creating/destroying h2d.Text objects per hit is wasteful.
   - Solution: optional object pool in FloatingText. Or leave to application code.

6. **Codegen support** — should Phase 5 .manim transitions work with `@:manim` macro codegen?
   - Probably yes, but can defer. Builder-mode transitions are sufficient for most use cases.
