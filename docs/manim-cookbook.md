# .manim Cookbook: Practical Guide

A pattern-based guide for building UIs and game elements. Always start with `.manim` — push as much as possible into the declarative DSL before writing Haxe code.

## Table of Contents
- [Core Principles](#core-principles)
- [Buttons](#buttons)
- [Checkboxes, Toggles, Radio Buttons](#checkboxes-toggles-radio)
- [Sliders](#sliders)
- [Dropdowns](#dropdowns)
- [Text Inputs](#text-inputs)
- [Tabs](#tabs)
- [Tooltips](#tooltips)
- [Panels and Sidebars](#panels-and-sidebars)
- [Progress / Health Bars](#progress-bars)
- [Inventory Grids](#inventory-grids)
- [Drag and Drop](#drag-and-drop)
- [Card Hand System](#card-hand-system)
- [Interaction Controllers](#interaction-controllers-modal-card-selection--targeting)
- [Grid Component](#grid-component)
- [Dialogue System](#dialogue-system)
- [Skill Trees](#skill-trees)
- [Particles](#particles)
- [Animated Paths and Floating Text](#animated-paths)
- [Character Sheets](#character-sheets)
- [Status Effects Bar](#status-effects)
- [Data Blocks for Game Config](#data-blocks)
- [Standard Widget Library](#standard-widget-library)
- [Common Visual Patterns](#common-patterns)
- [Wiring .manim to Haxe Code](#wiring-to-code)

---

## Core Principles

1. **.manim first** — Define all visuals, layouts, state switching, and static data in `.manim`. Code should only handle logic, event routing, and dynamic data.
2. **Incremental mode** — Use `buildWithParameters(..., true)` for anything updated at runtime. Avoid full rebuilds.
3. **`beginUpdate()`/`endUpdate()`** — Batch correlated parameter changes to avoid redundant layout passes.
4. **Slots for dynamic content** — Use `#name slot` for content injected from code; use parameterized slots (`#name slot(state:...)`) for visual state switching.
5. **`dynamicRef` for reusable sub-components** — Define once, embed many times with different params. Each instance is independently updatable.
6. **`updatable` for text labels** — Mark text elements `#name(updatable)` when their content changes at runtime via `getUpdatable("name").updateText(...)`.
7. **`placeholder` + `builderParameter` for standard controls** — Buttons, checkboxes, sliders, dropdowns are injected into placeholders from code via `MacroUtils.macroBuildWithParameters`.

---

## Buttons

### .manim Definition

```manim
#button programmable(status:[hover,pressed,normal]=normal,
    disabled:[true,false]=false, buttonText:string="Button",
    width:uint=200, height:uint=30) {
    // Background per state
    @(status=>normal, disabled=>false)  ninepatch("ui", "button-idle", $width, $height): 0, 0
    @(status=>hover, disabled=>false)   ninepatch("ui", "button-hover", $width, $height): 0, 0
    @(status=>pressed, disabled=>false) ninepatch("ui", "button-pressed", $width, $height): 0, 0
    @(status=>*, disabled=>true)        ninepatch("ui", "button-disabled", $width, $height): 0, 0
    // Text
    @(disabled=>false) text(dd, $buttonText, #ffffff, center, $width): 0, 8
    @(disabled=>true)  text(dd, $buttonText, #888888, center, $width): 0, 8
}
```

**Key patterns:**
- `@(status=>*, disabled=>true)` — wildcard matches any status when disabled
- Text color switches between white and gray based on disabled state
- Width/height are parameterized for reuse at different sizes

### .manim Usage (as placeholder in a screen)

```manim
#myScreen programmable() {
    placeholder(generated(cross(200, 30, #FF0000)), builderParameter("startBtn")) {
        pos: 100, 400
        settings{width:int=>200, height:int=>30, font=>"dd", fontColor=>0xffffff}
    }
}
```

### Haxe Wiring

```haxe
var ui = MacroUtils.macroBuildWithParameters(builder, "myScreen", [], [
    startBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Start Game"),
]);
startButton = ui.startBtn;
addBuilderResult(ui.builderResults);

// In onScreenEvent:
case UIClick:
    if (source == startButton) startGame();
```

### Graphics-Only Button (no sprite sheet)

```manim
#simpleBtn programmable(status:[normal,hover,pressed]=normal) {
    interactive(120, 40, "btn", autoStatus => "status")
    @(status=>normal)  graphics(rect(#334466, filled, 120, 40)): 0, 0
    @(status=>hover)   graphics(rect(#445588, filled, 120, 40)): 0, 0
    @(status=>pressed) graphics(rect(#283a54, filled, 120, 40)): 0, 0
    text(m6x11, "Click Me", white, center, 120): 0, 12
}
```

---

## Checkboxes, Toggles, Radio

### Checkbox .manim

```manim
#checkbox programmable(status:[hover,pressed,normal]=normal,
    checked:[true,false]=false, disabled:[true,false]=false) {
    @(checked=>false, status=>normal)  bitmap(sheet("ui", "checkbox-off-idle")): 0, 0
    @(checked=>false, status=>hover)   bitmap(sheet("ui", "checkbox-off-hover")): 0, 0
    @(checked=>true, status=>normal)   bitmap(sheet("ui", "checkbox-on-idle")): 0, 0
    @(checked=>true, status=>hover)    bitmap(sheet("ui", "checkbox-on-hover")): 0, 0
    @(disabled=>true)                  bitmap(sheet("ui", "checkbox-disabled")): 0, 0
}
```

### Toggle .manim

Same pattern but with on/off visual states (e.g. a switch graphic that slides left/right).

### Radio Buttons (repeatable group)

```manim
#radioButtons programmable(count:uint=3) {
    flow(layout:vertical, verticalSpacing:4) {
        repeatable($index, step($count, dx:0)) {
            flow(layout:horizontal, horizontalSpacing:6) {
                placeholder(nothing, callback("checkbox", $index)): 0, 0
                placeholder(nothing, callback("label", $index)): 0, 0
            }
        }
    }
}
```

### Haxe Usage

```haxe
// In onScreenEvent:
case UIToggle(pressed):
    if (source == myCheckbox) onToggle(pressed);
```

---

## Sliders

### .manim Definition

```manim
#slider programmable(status:[hover,pressed,normal]=normal,
    disabled:[true,false]=false, value:0..100=50, sliderWidth:uint=200) {
    grid: $sliderWidth / 100, 1
    // Track
    ninepatch("ui", "slider-track", $sliderWidth, 8): 0, 4
    // Thumb positioned by grid
    @(status=>normal) #slider(updatable) bitmap(sheet("ui", "thumb-idle")): $grid.pos($value, -1)
    @(status=>hover)  #slider(updatable) bitmap(sheet("ui", "thumb-hover")): $grid.pos($value, -1)
    settings { scrollSpeed:int => 1 }
}
```

### Haxe Wiring

```haxe
case UIChangeValue(value):
    if (source == mySlider) setVolume(value);
case UIChangeFloatValue(value):
    if (source == mySlider) setSpeed(value);
```

---

## Dropdowns

### .manim Definition

```manim
#dropdown programmable(status:[hover,pressed,normal]=normal,
    disabled:[true,false]=false, panel:[open,closed]=closed,
    font:string="dd", fontColor:color=white) {
    // Closed state: button-like appearance
    @(status=>normal) ninepatch("ui", "dropdown-idle", 200, 24): 0, 0
    @(status=>hover)  ninepatch("ui", "dropdown-hover", 200, 24): 0, 0
    // Arrow icon
    @(panel=>closed) bitmap(sheet("ui", "arrow-down")): 180, 6
    @(panel=>open)   bitmap(sheet("ui", "arrow-up")): 180, 6
    // Selected item text
    #selectedName(updatable) text($font, "", $fontColor): 8, 4
    // Panel attachment point
    #panelPoint point: 0, 26
    settings { transitionTimer:float => 0.15 }
}
```

### List Panel

```manim
#list-panel programmable(panelWidth:uint=200, panelHeight:uint=200) {
    ninepatch("ui", "Window_3x3_idle", $panelWidth, $panelHeight): 0, 0
    placeholder(nothing, builderParameter("maskPlaceholder")): 4, 4
    #scrollbar point: $panelWidth - 10, 4
}
```

### List Item

```manim
#list-item-120 programmable(status:[normal,selected,hover,pressed,disabled]=normal,
    itemWidth:uint=120) {
    @(status=>normal)   bitmap(generated(color($itemWidth, 20, #222233))): 0, 0
    @(status=>selected) bitmap(generated(color($itemWidth, 20, #334455))): 0, 0
    @(status=>hover)    bitmap(generated(color($itemWidth, 20, #2a2a44))): 0, 0
    #text(updatable) text(dd, "", white): 4, 2
}
```

### Haxe Usage

```haxe
placeholder(generated(cross(200, 24, #FF0000)), builderParameter("myDropdown")) {
    pos: 50, 100
    settings{panelBuildName=>list-panel, itemBuildName=>list-item-120,
             panelMode=>scalable, height:int=>200}
}

// In macro:
myDropdown => addDropdownWithSingleBuilder(stdBuilder, "dropdown",
    "list-panel", "list-item-120", "scrollbar", "scrollbar",
    ["Option A", "Option B", "Option C"], 0),

// In onScreenEvent:
case UIChangeItem(index, items):
    if (source == myDropdown) switchOption(index);
```

---

## Text Inputs

### .manim Definition

```manim
#textInput programmable(status:[normal,hover,focused,disabled]=normal,
    placeholder:bool=true, width:uint=200, height:uint=24,
    placeholderText:string="Enter text...") {
    @(status=>normal)   ninepatch("ui", "input-idle", $width, $height): 0, 0
    @(status=>hover)    ninepatch("ui", "input-hover", $width, $height): 0, 0
    @(status=>focused)  ninepatch("ui", "input-focus", $width, $height): 0, 0
    @(status=>disabled) ninepatch("ui", "input-disabled", $width, $height): 0, 0
    @(placeholder=>true) text(dd, $placeholderText, #888888): 4, 4
    #textArea point: 4, 4
}
```

### Settings

```manim
placeholder(generated(cross(200, 24, #FF0000)), builderParameter("nameInput")) {
    settings{buildName=>textInput, font=>"dd", fontColor=>0xffffff,
             placeholder=>"Enter name...", maxLength:int=>20, tabIndex:int=>1}
}
```

### Tab Navigation

```haxe
// Enable Tab/Shift+Tab cycling between text inputs
enableTabNavigation(Autowire);  // auto-discovers tabIndex order
```

---

## Tabs

### .manim Definition

```manim
#tab programmable(status:[hover,pressed,normal]=normal,
    checked:[true,false]=false, disabled:[true,false]=false, tabText:string="Tab") {
    @(checked=>true)  ninepatch("ui", "tab-active", 100, 28): 0, 0
    @(checked=>false, status=>normal) ninepatch("ui", "tab-idle", 100, 28): 0, 0
    @(checked=>false, status=>hover)  ninepatch("ui", "tab-hover", 100, 28): 0, 0
    text(dd, $tabText, ?($checked) white : #888888, center, 100): 0, 6
}
```

### .manim Usage

```manim
placeholder(generated(cross(800, 40, #FF0000)), builderParameter("myTabs")) {
    pos: 0, 48
    settings{tabButtonBuildName=>tab,
             tabPanel.width=>1280, tabPanel.height=>600,
             tabPanel.contentRoot=>contentArea}
}
```

### Haxe Wiring

```haxe
var ui = MacroUtils.macroBuildWithParameters(builder, "myScreen", [], [
    myTabs => addTabs(stdBuilder, ["Inventory", "Stats", "Map"]),
]);

// Add content per tab
ui.myTabs.beginTab(0);
addBuilderResult(inventoryResult);
ui.myTabs.endTab();

ui.myTabs.beginTab(1);
addBuilderResult(statsResult);
ui.myTabs.endTab();

// Tab change:
case UIChangeItem(index, items):
    if (source == ui.myTabs) onTabChanged(index);
```

---

## Tooltips

### .manim Tooltip Programmable

```manim
#myTooltip programmable(name:string="", desc:string="", accentColor:color=#7fdbda) {
    ninepatch("ui", "Window_3x3_idle", 200, 60): 0, 0
    bitmap(generated(color(190, 2, $accentColor))): 5, 2
    text(exo2_14, $name, $accentColor, left, 180): 10, 8
    text(m5x7, $desc, #bbbbbb, left, 180): 10, 28
}
```

### .manim Hover Trigger (hover-only interactive)

```manim
interactive(50, 14, "hlpItem", events: [hover]): 100, 200
```

### Haxe Setup

```haxe
tooltipHelper = new UITooltipHelper(this, builder,
    {delay: 0.15, position: Right, offset: 8},
    screenManager.tweens  // optional: enables fade transitions
);
// Per-interactive position override
tooltipHelper.setPosition("hlpItem", Above);

// In onScreenEvent:
case UIInteractiveEvent(UIEntering(_), id, meta):
    var data = getTooltipData(id);
    if (data != null) tooltipHelper.startHover(id, "myTooltip", data);
case UIInteractiveEvent(UILeaving, id, _):
    tooltipHelper.cancelHover(id);

// In update(dt):
tooltipHelper.update(dt);
```

---

## Panels and Sidebars

### Sidebar Pattern (from production game)

```manim
#sidebar programmable() {
    // Background
    bitmap(generated(color(250, 716, #1A1A2E))): 0, 0
    bitmap(generated(color(1, 716, #333355))): 250, 0  // right edge line

    // Sections as updatable flows
    #wave(updatable) flow(layout:vertical): 5, 5
    #heroList(updatable) flow(layout:vertical, verticalSpacing:4): 5, 80
}
```

### Panel Helper (popup panel on click)

```manim
#infoPanel programmable(title:string="Info") {
    ninepatch("ui", "Window_3x3_idle", 300, 200): 0, 0
    text(exo2_14, $title, #7fdbda): 10, 8
    // Panel content...
    interactive(20, 20, "closeBtn"): 270, 8
}
```

```haxe
// Auto-wired (recommended) — no manual handleOutsideClick/checkPendingClose needed:
panelHelper = createPanelHelper(builder, {fadeIn: 0.2, fadeOut: 0.15});

// Open panel on interactive click:
case UIInteractiveEvent(UIClick, id, _):
    panelHelper.open(id, "infoPanel", ["title" => "Item Details"]);

// Close programmatically:
panelHelper.close();
```

### Top Bar Pattern

```manim
#topbar programmable() {
    bitmap(generated(color(1280, 34, #1A1A2E))): 0, 0
    bitmap(generated(color(1280, 1, #333355))): 0, 34   // bottom edge
    #level(updatable) text(exo2_black_16, "Level 1", white): 10, 8
    #gold(updatable) text(exo2_black_16, "Gold: 100", #FFD700, right, 200): 1070, 8
    #upgrades(updatable) flow(layout:horizontal, horizontalSpacing:4): 120, 8
}
```

### Section Dividers

```manim
// Thin teal line
bitmap(generated(color(360, 1, #7fdbda33))): 20, 110

// Or using graphics
graphics(line(#333355, 1, 0, 0, 300, 0)): 20, 110
```

---

## Progress Bars

### Range-Colored Health Bar

```manim
#healthBar programmable(value:0..100=75, maxValue:uint=100) {
    // Background
    bitmap(generated(color(200, 16, #1a1a1a))): 0, 0
    // Fill — color changes by range
    @(value => 61..100) bitmap(generated(color($value * 200 / $maxValue, 14, #44cc44))): 1, 1
    @(value => 26..60)  bitmap(generated(color($value * 200 / $maxValue, 14, #eecc00))): 1, 1
    @(value => 1..25)   bitmap(generated(color($value * 200 / $maxValue, 14, #cc3322))): 1, 1
    // Text overlay
    text(m6x11, '${$value} / ${$maxValue}', #ffffff, center, 200): 0, 2
}
```

### With Damage Trail

```manim
#hpBar programmable(hp:uint=80, maxHp:uint=100, trail:float=90) {
    bitmap(generated(color(310, 20, #222222))): 0, 0
    // Trail (behind fill)
    graphics(rect(#cc332244, filled, $trail * 310 / $maxHp, 20): 0, 0): 0, 0
    // Fill
    @(hp => 61..100) graphics(rect(#44cc44, filled, $hp * 310 / $maxHp, 20): 0, 0): 0, 0
    @(hp => 26..60)  graphics(rect(#eecc00, filled, $hp * 310 / $maxHp, 20): 0, 0): 0, 0
    @(hp => 1..25)   graphics(rect(#cc3322, filled, $hp * 310 / $maxHp, 20): 0, 0): 0, 0
}
```

### Vertical Bar (fills from bottom)

```manim
#verticalBar programmable(value:uint=80, maxValue:uint=100, barColor:color=#44cc44) {
    bitmap(generated(color(20, 100, #222222))): 0, 0
    bitmap(generated(color(18, $value * 100 / $maxValue, $barColor))):
        1, 100 - $value * 100 / $maxValue
}
```

### Haxe Update

```haxe
result.beginUpdate();
result.setParameter("hp", currentHp);
result.setParameter("trail", trailHp);
result.endUpdate();

// Trail interpolation in update(dt):
if (hpTrail > hp) hpTrail = Math.max(hp, hpTrail - TRAIL_SPEED * dt);
```

---

## Inventory Grids

### Layout-Based Grid

```manim
layouts {
    offset: 0, 155 {
        #invGrid cells(cols: 4, rows: 3, cellWidth: 58, cellHeight: 58)
    }
}

#inventoryDemo programmable() {
    // Grid slots
    repeatable($i, layout("invGrid")) {
        bitmap(generated(color(52, 52, #1a1a2e88))): 0, 0
        #inv[$i] slot(state:[normal,disabled,highlight]=normal) {
            @(state=>normal)    bitmap(generated(color(52, 52, #2a2a4400))): 0, 0
            @(state=>highlight) graphics(
                line(#ffffff, 1, 0, 0, 51, 0);
                line(#ffffff, 1, 0, 51, 51, 51);
                line(#ffffff, 1, 0, 0, 0, 51);
                line(#ffffff, 1, 51, 0, 51, 51)
            ): 0, 0
            @(state=>disabled)  bitmap(generated(color(52, 52, #55555599))): 0, 0
        }
    }
}
```

### Item Visual

```manim
#invItem programmable(itemType:[empty,hpot,sword,shield]=empty) {
    @(itemType=>empty) bitmap(generated(color(48, 48, #1a1a2e))): 0, 0
    @(itemType=>hpot)  bitmap(generated(color(48, 48, #cc3333))): 0, 0
    @(itemType=>hpot)  scale(3) bitmap(sheet("items", "potion", 0)): 8, 4
    @(itemType=>hpot)  text(m5x7, "H.Pot", #ff8888, center, 48): 0, 32
    @(itemType=>sword) bitmap(generated(color(48, 48, #3344aa))): 0, 0
    @(itemType=>sword) scale(3) bitmap(sheet("items", "weapon", 9)): 8, 4
    @(itemType=>sword) text(m5x7, "Sword", #8888ff, center, 48): 0, 32
}
```

### Haxe Slot Manipulation

```haxe
// Fill slot with item
final slot = result.getSlot("inv", i);
final item = builder.buildWithParameters("invItem", ["itemType" => key]);
slot.setContent(item.object);
slot.data = itemKey;  // store game data

// Clear slot
slot.clear();
slot.data = null;

// Highlight during drag
slot.setParameter("state", "highlight");
```

---

## Drag and Drop

### .manim Animated Paths for Drag

```manim
curves { #elasticBounce curve { points: [(0, 0.4), (0.5, 1.2), (0.7, 0.9), (1, 1.0)] } }
paths { #straightLine path { lineTo(100, 0) } }

#returnAnim animatedPath {
    path: straightLine
    type: time
    duration: 0.4
    0.0: progressCurve: elasticBounce
}

#snapAnim animatedPath {
    path: straightLine
    type: time
    duration: 0.12
    0.0: progressCurve: easeOutQuad
}
```

### .manim Drop Target Highlight

```manim
#slotTarget programmable(state:[valid,invalid]=valid) {
    @(state=>valid)   graphics(rect(#44FF44, 3, 52, 52)): 0, 0
    @(state=>invalid) graphics(rect(#FF4444, 3, 52, 52)): 0, 0
}
```

### Haxe Drag Setup

```haxe
var drag = UIMultiAnimDraggable.create(slotContent);
drag.setReturnAnimPath(builder, "returnAnim");
drag.setSnapAnimPath(builder, "snapAnim");
drag.dragAlpha = 0.7;
drag.returnToOrigin = true;

// Register drop zones from slots (zone IDs are DropZoneId enums: SlotZone, Named, GridCell, etc.)
drag.addDropZonesFromSlots("inv", result);
drag.addDropZonesFromSlots("equip", result, (d, zone) -> {
    return switch zone.id { case SlotZone(_, idx): EQUIP_ACCEPTS[idx] == itemDef.equipType; default: false; };
});

// Highlight callbacks
drag.onDragStartHighlightZones = (zones) -> {
    for (z in zones) z.slot.setParameter("state", "highlight");
};
drag.onDragEndHighlightZones = (zones) -> refreshUI();

// Drop logic
drag.onDragDrop = (result, wrapper) -> {
    var targetSlot = result.zone.slot;
    // Move item, update game state
    return false;
};

addElementWithPos(drag, x, y, DefaultLayer);
```

---

## Card Hand System

### .manim Curves, Paths, and Cards

```manim
curves {
    #fadeOut curve { easing: easeInQuad }
    #growIn curve { points: [(0, 0), (1, 1)] }
    #scaleBounce curve { points: [(0, 0.4), (0.5, 1.2), (0.7, 0.9), (1, 1.0)] }
}

paths {
    #cardArc path { bezier(0, -60, 50, -80) }
    #handCurve path { bezier(0, 0, 300, -40, 600, 0) }
}

#drawPath animatedPath {
    path: cardArc
    type: time
    duration: 0.35
    0.0: progressCurve: easeOutCubic, scaleCurve: growIn, alphaCurve: quickFadeIn
}

#discardPath animatedPath {
    path: cardArc
    type: time
    duration: 0.25
    0.0: progressCurve: easeInQuad, scaleCurve: shrinkOut, alphaCurve: fadeOut
}

#card programmable(status:[normal,hover,pressed,disabled]=normal,
    cardName:string="Card", cost:uint=1, cardColor:color=#3366AA) {
    interactive(140, 200, "card", bind => "status", events: [hover, click, push])
    @(status=>normal)  graphics(rect($cardColor, filled, 140, 200)): 0, 0
    @(status=>hover)   graphics(rect(#FFDD44, 2, 138, 198)): 1, 1
    @(status=>disabled) apply { filter: group(grayscale(0.9), brightness(0.5)) }
    #cardIcon slot: 20, 20
    text(m6x11, $cardName, white, center, 140): 0, 160
    text(m5x7, '${$cost}', #FFDD44, center, 30): 5, 5
}

// Targeting arrow — chain of segment programmables + head at endpoint
// Both receive valid:bool for valid/invalid target visual state
#arrowSegment programmable(valid:bool=false) {
    graphics(?($valid) #44FF44 : #FF4444, 2.0) { line(0, 0, 12, 0) }
}
#arrowHead programmable(valid:bool=false) {
    graphics(?($valid) #44FF44 : #FF4444, 2.0) { line(0, -4, 8, 0), line(0, 4, 8, 0) }
}

#targetZone programmable(highlighted:bool=false) {
    @(highlighted=>false) graphics(rect(#445566, 1, 100, 100)): 0, 0
    @(highlighted=>true)  graphics(rect(#FFDD44, 2, 100, 100)): 0, 0
}
```

### Haxe Setup

```haxe
cardHand = new UICardHandHelper(this, builder, {
    drawPathName: "drawPath",
    discardPathName: "discardPath",
    returnPathName: "returnPath",
    rearrangePathName: "rearrangePath",
    arrowSegmentName: "arrowSegment",
    arrowHeadName: "arrowHead",
    arrowSegmentSpacing: 20.0,   // px between segments (default: 25)
    layoutPathName: "handCurve",
    pathDistribution: EvenArcLength,
    interactivePrefix: "card",
    hoverPopDistance: 30,
    hoverScale: 1.05,
    // Targeting zones: rects where dragging activates targeting arrow
    // (cursor over a registered target also activates targeting as fallback)
    targetingZones: [
        {id: "board", x: 50, y: 50, w: 600, h: 400},
    ],
    // Legacy alternative: targetingThresholdY: 380 (full-width zone above anchor)
});
cardHand.onCardEvent = onCardEvent;
cardHand.canPlayCard = (id, target) -> true;

// Draw cards
cardHand.drawCard({id: "card1", params: ["cardName" => "Fireball", "cost" => 3]});

// Auto-wired via addCardHand() — no manual event routing needed.
// Or with manual wiring (if not using addCardHand):
// onScreenEvent -> cardHand.handleScreenEvent(event)
// onMouseMove -> cardHand.onMouseMove(x, y)
// onMouseClick -> cardHand.onMouseRelease(x, y)
// update(dt) -> cardHand.update(dt)
// onClear -> cardHand.dispose()
```

### Interaction Controllers (Modal Card Selection & Targeting)

Instead of tracking selection/targeting state manually in `onScreenEvent()`, use interaction controllers. They push onto the controller stack, handle the interaction, and auto-pop with a typed result.

**Select cards from hand** (exhaust, discard, sacrifice):
```haxe
// Card programmable needs a "selected" param for visual feedback:
// #card programmable(status:..., selected:bool=false) { ... }

// "Exhaust 1 card" — auto-confirms when 1 card clicked
UISelectFromHandController.start(this, cardHand, {maxCount: 1, selectedParam: "selected"}, (result) -> {
    if (result != null) exhaustCard(result.cards[0]);
    // else: cancelled (Escape or right-click)
});

// "Discard 2 cards" — auto-confirms when 2 cards clicked
UISelectFromHandController.start(this, cardHand, {maxCount: 2}, (result) -> {
    if (result != null) for (id in result.cards) discardCard(id);
});

// "Select 1-3 cards" with manual confirm button
var ctrl = UISelectFromHandController.start(this, cardHand, {
    minCount: 1, maxCount: 3, autoConfirm: false,
    filter: (id) -> getCardCost(id) <= currentEnergy,
}, (result) -> {
    if (result != null) playCards(result.cards);
});
// Call ctrl.confirm() from a confirm button click
```

**Pick a target** (grid cell, interactive, or card):
```haxe
// Pick a grid cell
UIPickTargetController.start(this, {
    grid: hexGrid,
    cellFilter: (col, row) -> hexGrid.isOccupied(col, row),
    highlightParam: "highlight", highlightValue: "valid",
}, (result) -> {
    if (result != null) switch result {
        case TargetCell(col, row): castSpellAt(col, row);
        default:
    }
});

// Pick an interactive (button, slot, etc.)
UIPickTargetController.start(this, {targetPrefix: "enemy_"}, (result) -> {
    if (result != null) switch result {
        case TargetInteractive(id): attackTarget(id);
        default:
    }
});

// Pick a card in hand (for card-to-card effects)
UIPickTargetController.start(this, {
    cardHand: cardHand,
    cardFilter: (id) -> id != sourceCardId,
}, (result) -> {
    if (result != null) switch result {
        case TargetCard(targetId): combineCards(sourceCardId, targetId);
        default:
    }
});
```

**Composable flows** (select then target):
```haxe
// "Select a card, then pick where to play it"
UISelectFromHandController.start(this, cardHand, {maxCount: 1}, (sel) -> {
    if (sel != null) UIPickTargetController.start(this, {grid: hexGrid}, (tgt) -> {
        if (tgt != null) playCard(sel.cards[0], tgt);
    });
});
```

---

## Grid Component

### .manim Cell Programmables

```manim
// Rect grid cell
#rectCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:bool=false) {
    @(highlight=>true)  bitmap(generated(color(52, 52, #2a3a2a))): 0, 0
    @(highlight=>false)  bitmap(generated(color(52, 52, #1a1a2e))): 0, 0
    @(status=>hover) apply { filter: glow(#FFFF00, 0.3, 4) }
    graphics(rect(#333355, 1.0, 52, 52)): 0, 0
}

// Hex grid cell
#hexCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:bool=false,
                      occupied:bool=false, cellColor:color=#222244) {
    @(highlight=>true)  graphics(polygon(#2a3a2a, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
    @(highlight=>false) graphics(polygon(#1a1a2e, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
    @(occupied=>true)   graphics(polygon($cellColor, filled, 24, 6, 39, 15, 39, 33, 24, 42, 9, 33, 9, 15)): -24, -24
    @(status=>hover) apply { filter: glow(#44FFFF, 0.3, 4) }
    graphics(polygon(#334466, 1.0, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
}
```

**Key patterns:**
- `col:int=0, row:int=0` — auto-set by grid, useful for per-cell customization
- `status:[normal,hover]=normal` — driven by `onMouseMove` hover detection
- `highlight:bool=false` — driven by drag-drop zone highlight system
- Extra params like `occupied`, `cellColor` — game-specific, set via `set()` with params

### Basic Rect Grid

```haxe
var grid = new UIMultiAnimGrid(builder, {
    gridType: Rect(52, 52, 4),
    cellBuildName: "rectCell",
});
grid.addRectRegion(5, 4);  // 5 columns × 4 rows
grid.onGridEvent = (event) -> switch event {
    case CellClick(cell, _): trace('Clicked (${cell.col}, ${cell.row})');
    case CellHoverEnter(cell): trace('Hover ${cell.col}, ${cell.row}');
    default:
};
grid.getObject().setPosition(100, 100);
addObjectToLayer(grid.getObject(), DefaultLayer);

// Route mouse events from screen
override public function onMouseMove(pos:Point):Bool {
    grid.onMouseMove(pos.x, pos.y);
    return super.onMouseMove(pos);
}
override public function onMouseClick(pos:Point, button:Int, release:Bool):Bool {
    if (release) grid.onMouseClick(pos.x, pos.y, button);
    return super.onMouseClick(pos, button, release);
}
```

### Hex Grid

```haxe
var hexGrid = new UIMultiAnimGrid(builder, {
    gridType: Hex(POINTY, 30, 30),
    cellBuildName: "hexCell",
});
hexGrid.addHexRegion(0, 0, 2);  // radius 2 = 19 cells

// Set cell data with visual params
hexGrid.set(0, 0, {color: 0xFF0000},
    ["occupied" => (true : Dynamic), "cellColor" => (0xFF0000 : Dynamic)]);

// Clear cell
hexGrid.clear(0, 0);
hexGrid.getCellResult(0, 0).setParameter("occupied", false);
```

### Internal Drag-Drop (within one grid)

```haxe
// Create draggable for each occupied cell
grid.forEach((col, row, data) -> {
    if (data == null) return;
    var itemObj = buildItemVisual(data);
    var drag = UIMultiAnimDraggable.create(itemObj);
    drag.setReturnAnimPath(builder, "returnAnim");
    drag.setSnapAnimPath(builder, "snapAnim");
    drag.dragAlpha = 0.7;
    drag.returnToOrigin = true;

    drag.onDragEvent = (event, _, _) -> switch event {
        case DragStart: grid.clear(col, row);  // clear source on drag start
        case DragCancel: grid.set(col, row, data);  // restore on cancel
        default:
    };
    grid.acceptDrops(drag, (cell, _) -> !grid.isOccupied(cell.col, cell.row));

    var pos = grid.cellPosition(col, row);
    addElementWithPos(drag, pos.x, pos.y, DefaultLayer);
});

// Handle drop event
grid.onGridEvent = (event) -> switch event {
    case CellDrop(cell, _, _, _):
        grid.set(cell.col, cell.row, dragSourceData);
        rebuildDraggables();  // rebuild after state change
    default:
};
```

### Grid-to-Grid Transfer

```haxe
// Both grids accept drops from the same draggable
storageGrid.acceptDrops(drag, (cell, _) -> !storageGrid.isOccupied(cell.col, cell.row));
loadoutGrid.acceptDrops(drag, (cell, _) -> !loadoutGrid.isOccupied(cell.col, cell.row));

// Grid handles chaining: if drop zone doesn't match first grid's prefix, tries second grid
```

### Hex Grid + Card Targeting

```haxe
// Register hex grid cells as card play targets
hexGrid.registerAsCardTarget(cardHand, (cell, cardId) -> !hexGrid.isOccupied(cell.col, cell.row));

// Card hand consumes mouse events during drag — check before grid
override public function onMouseMove(pos:Point):Bool {
    if (cardHand.onMouseMove(pos.x, pos.y)) return false;
    hexGrid.onMouseMove(pos.x, pos.y);
    return super.onMouseMove(pos);
}

// Handle card play in onCardEvent
case CardPlayed(cardId, TargetZone(targetId)):
    // targetId format: "gridN_col_row"
    var parts = targetId.split("_");
    var col = Std.parseInt(parts[parts.length - 2]);
    var row = Std.parseInt(parts[parts.length - 1]);
    hexGrid.set(col, row, itemData, visualParams);
```

---

## Dialogue System

### .manim Layout

```manim
#dialogueDemo programmable() {
    // Scene description
    ninepatch("ui", "Window_3x3_idle", 700, 120): 0, 35
    #sceneText(updatable) text(exo2_light_14, "", #aaaaaa, left, 660): 15, 70

    // Portrait
    ninepatch("ui", "Window_3x3_idle", 100, 100): 0, 170
    #portraitColor(updatable) bitmap(generated(color(80, 80, #4a90a4))): 10, 180

    // Speech bubble
    ninepatch("ui", "Window_3x3_idle", 580, 120): 120, 170
    #speakerText(updatable) text(exo2_16, "", #ffeb3b, left, 300): 135, 180
    #dialogueText(updatable) text(exo2_14, "", #ffffff, left, 540): 135, 205
    #continueText(updatable) text(exo2_light_14, "", #7fdbda, right, 560): 135, 265

    // Choice buttons (visibility controlled from code)
    placeholder(generated(cross(270, 30, #FF0000)), builderParameter("choice1Button")) {
        pos: 120, 305
    }
    #choice1Visible(updatable) point: 120, 305
}
```

### Haxe Typewriter Effect

```haxe
override function update(dt:Float) {
    super.update(dt);
    if (isTyping) {
        typewriterTimer += dt;
        if (typewriterTimer >= CHAR_DELAY) {
            typewriterTimer -= CHAR_DELAY;
            displayedChars++;
            var text = fullText.substr(0, displayedChars);
            result.getUpdatable("dialogueText").updateText(text);
            if (displayedChars >= fullText.length) {
                isTyping = false;
                result.getUpdatable("continueText").updateText("[Click to continue]");
            }
        }
    }
}
```

---

## Skill Trees

### .manim Layout with Named Lists

```manim
layouts {
    #warNodes list {
        point: 60, 65
        point: 160, 65
        point: 260, 65
        point: 360, 65
    }
    #rogNodes list {
        point: 60, 140
        point: 160, 140
        point: 260, 140
        point: 360, 140
    }
}
```

### Two-Parameter Slots (state + hover)

```manim
repeatable($n, layout("warNodes")) {
    #warNode[$n] slot(state:[upgraded,upgradable,hidden,notEnoughPoints]=hidden,
                      hover:[off,on]=off) {
        @(state=>upgraded)   bitmap(generated(color(36, 36, #ff7f50))): 0, 0
        @(state=>upgradable) bitmap(generated(color(36, 36, #2a4a2a))): 0, 0
        @(state=>hidden)     bitmap(generated(color(36, 36, #222222))): 0, 0
        bitmap(generated(color(32, 32, #1a1a1a))): 2, 2
        slotContent: 2, 2
        @(state=>hidden) text(m6x11, "?", #444444, center, 36): 0, 12
        @(state=>upgradable) @alpha(0.5) text(m6x11, "+", #ffffff, center, 16): 10, 12
        @(hover=>on) graphics(
            line(#ffffff, 1, 0, 0, 35, 0); line(#ffffff, 1, 35, 0, 35, 35);
            line(#ffffff, 1, 35, 35, 0, 35); line(#ffffff, 1, 0, 35, 0, 0)
        ): 0, 0
    }
}

// Per-node interactives
interactive(36, 36, "0"):  60, 65
interactive(36, 36, "1"): 160, 65
```

### Haxe Node Click

```haxe
case UIInteractiveEvent(UIClick, id, _):
    final nodeIdx = Std.parseInt(id);
    if (nodeIdx != null) onNodeClick(nodeIdx);

function onNodeClick(idx:Int) {
    if (skillPoints <= 0) return;
    final slot = result.getSlot("warNode", idx);
    var icon = builder.buildWithParameters("eqIcon", ["icon" => "helm", "style" => "full"]);
    slot.setContent(icon.object);
    slot.setParameter("state", "upgraded");
    skillPoints--;
}
```

---

## Particles

### Loop Particles (ambient effect)

```manim
#buffSparkle particles {
    count: 10
    emit: circle(r: 36, rRand: 6, angle: 0, angleSpread: 360deg)
    tiles: file("circle_soft.png")
    loop: true
    maxLife: 1.8
    speed: 8
    speedRandom: 0.5
    size: 0.2
    sizeRandom: 0.1
    fadeIn: 0.2
    fadeOut: 0.7
    colorStops: 0.0 #FFEE88, 0.5 #88FFAA, 1.0 #44CC4400
    blendMode: add
}
```

### One-Shot Burst

```manim
#explosionBurst particles {
    count: 40
    loop: false
    emit: circle(r: 24, rRand: 10, angle: 0, angleSpread: 360deg)
    tiles: file("circle_soft.png")
    maxLife: 0.6
    speed: 100
    speedRandom: 0.4
    size: 0.4
    fadeOut: 0.8
    colorStops: 0.0 #FFFFFF, 0.3 #FFEE44, 1.0 #FF880000
    blendMode: add
}
```

### Directional Emitter (smoke rising)

```manim
#smoke particles {
    count: 15
    emit: box(w: 60, h: 2, angle: 270deg, angleSpread: 20deg)
    tiles: file("smoke.png")
    loop: true
    maxLife: 2.0
    speed: 20
    gravity: -10
    gravityAngle: 270deg
    size: 0.3
    sizeRandom: 0.15
    fadeIn: 0.3
    fadeOut: 0.6
    colorStops: 0.0 #88666688, 0.5 #66444466, 1.0 #44222200
    blendMode: alpha
}
```

### Cone Emitter (projectile trail)

```manim
#sparks particles {
    count: 60
    emit: cone(dist: 0, distRand: 0, angle: 270deg, angleSpread: 45deg)
    maxLife: 2.0
    speed: 120
    gravity: 80
    gravityAngle: 90deg
    tiles: sheet("demo", "tile-center")
    fadeOut: 0.7
}
```

### Haxe Instantiation

```haxe
var particles = builder.createParticles("buffSparkle");
container.addChild(particles);
particles.setPosition(x, y);

// One-shot burst:
var burst = builder.createParticles("explosionBurst");
container.addChild(burst);
burst.setPosition(hitX, hitY);
// burst auto-removes after maxLife when loop:false? No — remove manually:
// schedule removal after maxLife duration
```

---

## Animated Paths

### Damage Number Float-Up

```manim
curves {
    #dmgAlpha curve { easing: easeInQuad }
    #dmgProgress curve { easing: easeOutCubic }
}

paths {
    #dmgPath path { lineTo(0, -60) }
}

#dmgAnim animatedPath {
    path: dmgPath
    type: time
    duration: 1.0
    0.0: alphaCurve: dmgAlpha, progressCurve: dmgProgress
}
```

### Explosion Text (scale up + fade)

```manim
curves {
    #boomAlpha curve { points: [(0, 1.0), (0.6, 1.0), (1, 0)] }
    #boomScale curve { points: [(0, 1.0), (1, 3.0)] }
    #boomProgress curve { easing: easeOutQuad }
}

#boomAnim animatedPath {
    path: dmgPath
    type: time
    duration: 1.0
    0.0: alphaCurve: boomAlpha, scaleCurve: boomScale, progressCurve: boomProgress
}
```

### Haxe FloatingTextHelper

```haxe
var floatingText = new FloatingTextHelper(overlayRoot);

// Damage number
var ap = builder.createAnimatedPath("dmgAnim");
floatingText.spawn("-42", font, worldX, worldY, ap, 0xFF0000, false);

// Heal number with wave path
var ap = builder.createAnimatedPath("healAnim");
floatingText.spawn("+15", font, worldX, worldY, ap, 0x44FF44, false);

// In update(dt):
floatingText.update(dt);
```

### Haxe ScreenShakeHelper

```haxe
var shake = new ScreenShakeHelper(root);

// Basic shake (e.g. on taking damage)
shake.shake(8.0, 0.4);

// Horizontal recoil (e.g. gun kickback)
shake.shakeDirectional(6.0, 0.2, 1.0, 0.0);

// Vertical landing impact
shake.shakeDirectional(4.0, 0.15, 0.0, 1.0);

// With .manim curve for custom decay feel
var curve = builder.getCurve("heavyImpact");
shake.shakeWithCurve(10.0, 0.5, curve);

// In update(dt):
shake.update(dt);
```

---

## Character Sheets

### Reusable Sub-Components via dynamicRef

```manim
#resourceBar programmable(value:uint=50, maxValue:uint=100,
    barColor:color=#ff4444, label:string="HP") {
    text(m6x11, $label, #aaaaaa): 0, 4
    bitmap(generated(color(300, 16, #1a1a1a))): 30, 0
    bitmap(generated(color($value * 300 / $maxValue, 16, $barColor))): 30, 0
    text(m6x11, '${$value} / ${$maxValue}', #ffffff, center, 300): 30, 2
}

#statBar programmable(statName:string="STR", statValue:uint=10,
    barColor:color=#ff7f50, maxStat:uint=30) {
    text(m5x7, $statName, #888888): 0, 2
    bitmap(generated(color(80, 8, #222222))): 30, 2
    bitmap(generated(color($statValue * 80 / $maxStat, 6, $barColor))): 31, 3
    text(m5x7, $statValue, #ffffff): 115, 2
}

#characterSheet programmable(hp:uint=80, maxHp:uint=100,
    mp:uint=40, maxMp:uint=60, strStat:uint=15, dexStat:uint=12, intStat:uint=8) {
    ninepatch("ui", "Window_3x3_idle", 400, 350): 0, 0
    text(exo2_16, "Character", #7fdbda): 20, 10
    bitmap(generated(color(360, 1, #7fdbda33))): 20, 32

    dynamicRef($resourceBar, value=>$hp, maxValue=>$maxHp,
        barColor=>#ff4444, label=>"HP"): 20, 50
    dynamicRef($resourceBar, value=>$mp, maxValue=>$maxMp,
        barColor=>#4a90a4, label=>"MP"): 20, 75

    bitmap(generated(color(360, 1, #7fdbda33))): 20, 100
    dynamicRef($statBar, statName=>"STR", statValue=>$strStat): 30, 115
    dynamicRef($statBar, statName=>"DEX", statValue=>$dexStat): 30, 135
    dynamicRef($statBar, statName=>"INT", statValue=>$intStat): 30, 155

    text(exo2_16, 'Power: ${$strStat + $dexStat + $intStat}', #ffeb3b): 130, 180
}
```

---

## Status Effects

### Flow-Based Effect Bar

```manim
#statusCard programmable(pct:0..100=100, kind:[buff,debuff]=buff,
    accentColor:color=#44cc44) {
    @(kind=>buff)   bitmap(generated(color(64, 88, #12261a))): 0, 0
    @(kind=>debuff) bitmap(generated(color(64, 88, #261216))): 0, 0
    bitmap(generated(color(64, 2, $accentColor))): 0, 0
    #cardIcon slot { bitmap(generated(color(1, 1, #00000000))): 0, 0 }
    #cardName(updatable) text(m5x7, "", white, center, 64): 0, 50
    #cardTimer(updatable) text(m5x7, "", #ffeb3b, center, 64): 0, 64
    // Progress bar
    bitmap(generated(color(60, 6, #111111))): 2, 79
    bitmap(generated(color($pct * 58 / 100, 4, $accentColor))): 3, 80
}

#statusBarDemo programmable() {
    flow(layout: horizontal, horizontalSpacing: 8) {
        repeatable($i, range(0, 8)) {
            point {
                bitmap(generated(color(64, 88, #111122))): 0, 0
                #effectSlot[$i] slot {
                    bitmap(generated(color(1, 1, #00000000))): 0, 0
                }
            }
        }
    }
}
```

---

## Data Blocks

### Game Configuration in .manim

```manim
#gameData data {
    #creep record(name:string, hp:int, damage:int, speed:float, isRanged:bool)

    maxLevel: 5
    startGold: 100

    units: creep[] [
        { name: "Swordsman", hp: 80, damage: 12, speed: 1.0, isRanged: false }
        { name: "Archer",    hp: 50, damage: 15, speed: 1.2, isRanged: true }
        { name: "Knight",    hp: 150, damage: 8,  speed: 0.8, isRanged: false }
    ]
}
```

### Haxe Access

```haxe
var data = builder.getDataBlock("gameData");
var maxLevel = data.getInt("maxLevel");
var units = data.getRecordArray("units");
for (unit in units) {
    var name = unit.getString("name");
    var hp = unit.getInt("hp");
}
```

---

## Standard Widget Library

Every project should have a `std.manim` with reusable widgets. Import it:

```manim
import "manim/std.manim" as "std"
```

Minimal `std.manim` should contain:
- `#button` — full state machine button with width/height/font params
- `#checkbox` — checked/unchecked × status × disabled
- `#slider` — horizontal slider with grid-based thumb
- `#dropdown` — with arrow icon, selectedName text, panelPoint
- `#list-panel` — scrollable panel container
- `#list-item-120` — list row with status states
- `#scrollbar` — thin scrollbar track/thumb
- `#okCancelDialog` — modal dialog with text + two button placeholders

Load `std.manim` as a separate builder (`stdBuilder`) and pass it to `addButtonWithSingleBuilder`, `addCheckbox`, `addSlider`, `addDropdownWithSingleBuilder`.

---

## Common Patterns

### Background + Title

```manim
#myScreen programmable() {
    bitmap(generated(color(1280, 720, #1A1A2E))): 0, 0
    text(exo2_16, "Screen Title", #7fdbda): 20, 10
    bitmap(generated(color(1240, 1, #7fdbda33))): 20, 32
}
```

### Debug-Safe Colors (no sprites needed)

```manim
// Solid rectangle
bitmap(generated(color(80, 40, #446688))): 0, 0

// With text label
bitmap(generated(colorwithtext(80, 40, #446688, "Label", white, m3x6))): 0, 0

// Cross placeholder
bitmap(generated(cross(80, 40, #FF0000))): 0, 0
```

### Repeatable Grid (1D → 2D)

```manim
repeatable($i, step(20, dx:0)) {
    bitmap(generated(color(12, 12, #ff4444))): ($i % 5) * 16, ($i div 5) * 16
}
```

### Conditional Border (hover highlight)

```manim
@(hover=>on) graphics(
    line(#ffffff, 1, 0, 0, W-1, 0);
    line(#ffffff, 1, W-1, 0, W-1, H-1);
    line(#ffffff, 1, W-1, H-1, 0, H-1);
    line(#ffffff, 1, 0, H-1, 0, 0)
): 0, 0
```

### Dead/Disabled Grayscale

```manim
@(dead=>true) apply { filter: grayscale(1.0) }
@(status=>disabled) apply { filter: group(grayscale(0.9), brightness(0.5)) }
```

### Glow on Hover

```manim
@(status=>hover) apply {
    filter: glow(color:#FFFF00, alpha:0.6, radius:10)
}
```

### Rich Text with Markup

```manim
richText(dd, "Deal [damage]50[/] for [gold]100g[/]", white, left, 600,
    styles: {damage: color(#FF0000), gold: color(#FFD700) font("dd")})
```

### Transitions (parameter change animation)

```manim
#panel programmable(mode:[a,b]=a) {
    transition { mode: crossfade(0.3, easeOutQuad) }
    @(mode=>a) bitmap(generated(color(100, 60, #ff4444))): 0, 0
    @(mode=>b) bitmap(generated(color(100, 60, #4444ff))): 0, 0
}
```

---

## Wiring .manim to Haxe Code

### Complete Screen Template

```haxe
class MyScreen extends UIScreenBase {
    var builder:MultiAnimBuilder;
    var result:BuilderResult;
    var startButton:UIElement;
    var tooltipHelper:UITooltipHelper;

    override public function load() {
        builder = screenManager.buildFromResourceName("manim/myscreen.manim", false);
        var stdBuilder = screenManager.buildFromResourceName("manim/std.manim", false);

        var ui = MacroUtils.macroBuildWithParameters(builder, "myScreen", [], [
            startBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Start"),
        ]);
        result = ui.builderResults;
        startButton = ui.startBtn;
        addBuilderResult(result);

        // Tooltips
        tooltipHelper = new UITooltipHelper(this, builder,
            {delay: 0.2, position: Right, offset: 8},
            screenManager.tweens);

        // Register interactives
        addInteractives(result);
    }

    override public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>) {
        switch event {
            case UIClick:
                if (source == startButton) onStart();
            case UIInteractiveEvent(UIEntering(_), id, meta):
                tooltipHelper.startHover(id, "tooltip", getTooltipParams(id));
            case UIInteractiveEvent(UILeaving, id, _):
                tooltipHelper.cancelHover(id);
            case UIInteractiveEvent(UIClick, id, meta):
                onInteractiveClick(id, meta);
            default:
        }
        super.onScreenEvent(event, source);
    }

    override public function update(dt:Float) {
        super.update(dt);
        tooltipHelper.update(dt);
    }

    override public function onClear() {
        super.onClear();
        builder = null;
        result = null;
        startButton = null;
        tooltipHelper = null;
    }
}
```

### Passing Data Between Screens

Use the optional `data` parameter on `switchTo()` / `modalDialogWithTransition()` to pass context to the target screen. The data arrives via the `UIEntering(?data)` event.

```haxe
// Navigating with data:
screenManager.switchTo(shopScreen, {itemId: 42, category: "weapons"}, Fade(0.3));

// Opening a dialog with data:
screenManager.modalDialogWithTransition(confirmDialog, this, "confirm",
    {action: "delete", targetId: selectedId}, SlideUp(0.3));

// Receiving data in the target screen:
override public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>) {
    switch event {
        case UIEntering(data):
            if (data != null) applyScreenData(data);
        default:
    }
    super.onScreenEvent(event, source);
}

function applyScreenData(data:Dynamic) {
    var itemId:Int = data.itemId;
    var category:String = data.category;
    // populate UI with received data...
}
```

### Key API Cheatsheet

| Task | API |
|------|-----|
| Build static | `builder.buildWithParameters("name", params)` |
| Build incremental | `builder.buildWithParameters("name", params, null, null, true)` |
| Set parameter | `result.setParameter("param", value)` |
| Batch update | `result.beginUpdate()` ... `result.endUpdate()` |
| Update text | `result.getUpdatable("name").updateText("new text")` |
| Get slot | `result.getSlot("name")` or `result.getSlot("name", index)` |
| Fill slot | `slot.setContent(obj)` / `slot.clear()` |
| Slot visual state | `slot.setParameter("state", "highlight")` |
| Get dynamic ref | `result.getDynamicRef("name").setParameter("param", value)` |
| Create particles | `builder.createParticles("name")` |
| Create anim path | `builder.createAnimatedPath("name")` |
| Read settings | `result.rootSettings.getIntOrDefault("key", default)` |
| Register interactives | `addInteractives(result, ?prefix)` |
| Get interactive | `getInteractive(id)` |
