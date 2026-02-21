# UIMultiAnimTabs — Design

## Overview

A tab bar component with built-in content management. Manages mutually exclusive tab buttons
and controls which content elements are visible and receive events.

Two concepts work together:
1. **UIMultiAnimTabs** — the tab bar widget, manages buttons + per-tab content lists,
   implements `UIElementSubElements` to control event filtering
2. **ContentTarget** — a generic interface on `UIScreenBase` that lets any component
   (tabs, accordion, etc.) intercept `addElement`/`addObjectToLayer` calls

The screen's existing helpers (`addButton`, `addSlider`, `addDropdown`, etc.) work
unchanged — the routing is transparent.

## Components

### UIMultiAnimTabButton

A single tab button. Like `UIStandardMultiAnimButton` but with a `selected` state.

**Combo parameters:** `["status", "disabled"]`

Where `status` values are: `normal`, `hover`, `pressed`, `selected`, `selectedHover`

```haxe
private enum TabButtonStatus {
    TBNormal;
    TBHover;
    TBPressed;
    TBSelected;
    TBSelectedHover;
}

class UIMultiAnimTabButton implements UIElement implements UIElementDisablable
        implements StandardUIElementEvents implements UIElementSyncRedraw {
    final multiResult:MultiAnimMultiResult;
    var status(default, set):TabButtonStatus = TBNormal;
    var root:h2d.Object;
    var currentObject:Null<h2d.Object>;
    public var disabled(default, set):Bool = false;
    public var selected(default, set):Bool = false;
    public var requestRedraw = true;
}
```

**Event handling:**
- When not selected: normal/hover/pressed like a button, click triggers selection
- When selected: shows `selected` state, hover shows `selectedHover`, clicks ignored

**Construction:**
```haxe
multiResult = builder.buildWithComboParameters(name, params, ["status", "disabled"]);
```

**doRedraw:**
```haxe
function doRedraw() {
    var statusStr = if (selected) {
        status == TBHover ? "selectedHover" : "selected";
    } else {
        switch status {
            case TBNormal: "normal";
            case TBHover: "hover";
            case TBPressed: "pressed";
            default: "normal";
        }
    };
    var result = multiResult.findResultByCombo(statusStr, '$disabled');
    // swap object on root
}
```

### ContentTarget interface

A generic interface that any component can implement to intercept screen element routing.
Lives on `UIScreenBase`, not specific to tabs.

```haxe
interface ContentTarget {
    function registerElement(element:UIElement):Void;
    function registerObject(object:h2d.Object):Void;
}
```

### UIMultiAnimTabs

Container that manages tab buttons + content elements per tab.
Implements `ContentTarget` — when a tab is being populated, it receives elements.

```haxe
class UIMultiAnimTabs implements UIElement implements UIElementDisablable
        implements StandardUIElementEvents implements UIElementListValue
        implements UIElementSubElements implements ContentTarget {

    final tabButtons:Array<UIMultiAnimTabButton>;
    final items:Array<UIElementListItem>;
    final builder:MultiAnimBuilder;
    final tabButtonBuilderName:String;
    final builderResult:BuilderResult;
    var selectedIndex:Int;
    public var disabled(default, set):Bool = false;

    // Content management — per tab
    final tabContent:Map<Int, Array<UIElement>> = [];
    final tabObjects:Map<Int, Array<h2d.Object>> = [];

    // Which tab index is currently being populated (set by beginTab/endTab)
    var populatingTabIndex:Int = -1;
}
```

**Interfaces:**
- `UIElement` — standard
- `UIElementDisablable` — disables all tab buttons
- `StandardUIElementEvents` — not used directly (events go to individual tab buttons)
- `UIElementListValue` — `getSelectedIndex()`, `setSelectedIndex()`, `getList()`
- `UIElementSubElements` — **the core mechanism for event filtering**
- `ContentTarget` — receives elements from screen routing

### beginTab / endTab

The user-facing API lives on `UIMultiAnimTabs`. It sets the screen's content target
and tracks which tab index is being populated:

```haxe
function beginTab(tabIndex:Int) {
    if (populatingTabIndex != -1)
        throw 'already populating tab $populatingTabIndex';
    populatingTabIndex = tabIndex;
    screen.setContentTarget(this);
}

function endTab() {
    if (populatingTabIndex == -1)
        throw 'not populating any tab';
    // Hide content for non-selected tabs
    if (populatingTabIndex != selectedIndex)
        setTabContentVisible(populatingTabIndex, false);
    populatingTabIndex = -1;
    screen.clearContentTarget();
}
```

### ContentTarget implementation

```haxe
// ContentTarget — called by screen's addElement routing
function registerElement(element:UIElement):Void {
    var list = tabContent.get(populatingTabIndex);
    if (list == null) {
        list = [];
        tabContent.set(populatingTabIndex, list);
    }
    list.push(element);
}

// ContentTarget — called by screen's addObjectToLayer routing
function registerObject(object:h2d.Object):Void {
    var list = tabObjects.get(populatingTabIndex);
    if (list == null) {
        list = [];
        tabObjects.set(populatingTabIndex, list);
    }
    list.push(object);
}
```

### Event Filtering via getSubElements

The controller calls `getSubElements()` to discover what elements to dispatch events to
and update. Only active tab content is returned — inactive tabs are automatically excluded.

```haxe
function getSubElements(type:SubElementsType):Array<UIElement> {
    var result:Array<UIElement> = [];

    // Always include tab buttons (they always receive events)
    for (btn in tabButtons) result.push(cast btn);

    // Only include content from active tab
    var activeContent = tabContent.get(selectedIndex);
    if (activeContent != null) {
        for (element in activeContent) {
            result.push(element);
            // Recurse into sub-elements
            if (Std.isOfType(element, UIElementSubElements)) {
                var sub = cast(element, UIElementSubElements).getSubElements(type);
                for (s in sub) result.push(s);
            }
        }
    }

    return result;
}
```

### Visibility Management

On tab switch, content visibility is toggled automatically:

```haxe
function setSelectedIndex(idx:Int) {
    if (idx == selectedIndex) return;
    var oldIndex = selectedIndex;
    selectedIndex = idx;

    // Update button states
    for (i => btn in tabButtons) {
        btn.selected = (i == idx);
    }

    // Hide old tab content
    setTabContentVisible(oldIndex, false);

    // Show new tab content
    setTabContentVisible(idx, true);
}

function setTabContentVisible(tabIndex:Int, visible:Bool) {
    var elements = tabContent.get(tabIndex);
    if (elements != null)
        for (el in elements) el.getObject().visible = visible;

    var objects = tabObjects.get(tabIndex);
    if (objects != null)
        for (obj in objects) obj.visible = visible;
}
```

### Tab Button Callback

Individual tab buttons notify the parent via an internal callback (same pattern as
radio buttons with `onInternalToggle`):

```haxe
// In UIMultiAnimTabButton
dynamic function onInternalClick(controllable:Controllable) {}

// In UIMultiAnimTabs — wired during construction
function onTabButtonClicked(index:Int, controllable:Controllable) {
    if (index == selectedIndex) return;
    setSelectedIndex(index);
    onTabChanged(index, items);
    controllable.pushEvent(UIChangeItem(index, items), this);
}
```

### Construction (builder callback pattern)

Same pattern as radio buttons — the tab bar programmable has a repeatable with placeholders:

```haxe
function new(builder, tabBarBuildName, tabButtonBuildName, items, selectedIndex,
        screen, ?extraParams) {
    this.builder = builder;
    this.items = items;
    this.tabButtonBuilderName = tabButtonBuildName;
    this.selectedIndex = selectedIndex;
    this.screen = screen;

    var params:Map<String, Dynamic> = ["count" => items.length];
    if (extraParams != null)
        for (key => value in extraParams) params.set(key, value);

    this.builderResult = builder.buildWithParameters(tabBarBuildName, params,
        {callback: builderCallback});

    setSelectedIndex(selectedIndex);
}

function builderCallback(request:CallbackRequest):CallbackResult {
    switch request {
        case NameWithIndex(name, index):
            return CBRString(items[index].name);
        case PlaceholderWithIndex(name, index):
            if (name == "tabButton") {
                var btn = new UIMultiAnimTabButton(builder, tabButtonBuilderName, ...);
                tabButtons[index] = btn;
                btn.onInternalClick = onTabButtonClicked.bind(index);
                return CBRObject(btn.getObject());
            }
            throw 'invalid placeholder $name';
        default:
            throw 'unsupported callback $request';
    }
}
```

## .manim Examples

### Tab button programmable

```manim
#tabButton programmable(buttonText:string, status:[normal,hover,pressed,selected,selectedHover], disabled:bool=false) {
    @(disabled => true) {
        bitmap(generated(color(100, 30, #222222)))
        text(font, $buttonText, #666666): 10, 5
    }
    @(disabled => false) {
        @(status => normal)        bitmap(generated(color(100, 30, #444444)))
        @(status => hover)         bitmap(generated(color(100, 30, #555555)))
        @(status => pressed)       bitmap(generated(color(100, 30, #333333)))
        @(status => selected)      bitmap(generated(color(100, 30, #0066cc)))
        @(status => selectedHover) bitmap(generated(color(100, 30, #0088ff)))
        text(font, $buttonText, #ffffff): 10, 5
    }
}
```

### Tab bar programmable

```manim
#tabBar programmable(count:uint) {
    flow(horizontal) {
        repeatable($i, $count) {
            placeholder(tabButton, $i)
        }
    }
}
```

### Vertical variant

```manim
#verticalTabBar programmable(count:uint) {
    flow(vertical) {
        repeatable($i, $count) {
            placeholder(tabButton, $i)
        }
    }
}
```

## Screen Integration

### UIScreenBase changes — generic ContentTarget

The screen gets a generic content target mechanism, not specific to tabs:

```haxe
// New on UIScreenBase
var contentTarget:Null<ContentTarget> = null;

@:allow(bh.ui.UIMultiAnimTabs)
function setContentTarget(target:ContentTarget) {
    if (contentTarget != null)
        throw 'content target already set';
    contentTarget = target;
}

@:allow(bh.ui.UIMultiAnimTabs)
function clearContentTarget() {
    if (contentTarget == null)
        throw 'no content target set';
    contentTarget = null;
}
```

### Modified addElement

The existing `addElement` gets a routing check at the top:

```haxe
public function addElement(element:UIElement, layer:Null<LayersEnum>) {
    if (contentTarget != null) {
        // Route to content target (tabs, etc.) instead of main element list
        contentTarget.registerElement(element);
        // Track ownership for removeElement
        contentTargetOwnership.set(element, contentTarget);
        // Still add to scene graph for rendering — but suppress registerObject
        // since registerElement already covers this element's visibility
        inElementRouting = true;
        if (Std.isOfType(element, UIElementCustomAddToLayer)) {
            // ... existing custom add logic ...
        }
        if (layer != null && element.getObject().parent == null) {
            addObjectToLayer(element.getObject(), layer);
        }
        inElementRouting = false;
        return element;
    }

    // ... existing addElement logic unchanged ...
    elements.push(element);
    // ...
}
```

### Modified addObjectToLayer

Layers are fully supported — objects always go to the correct scene graph layer.
The content target only registers **standalone** objects (not those already tracked
via `registerElement`), to avoid double visibility management.

```haxe
var inElementRouting = false;

public function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum) {
    // Register standalone objects for visibility management.
    // Skip when called from addElement routing (element already registered).
    if (contentTarget != null && !inElementRouting) {
        contentTarget.registerObject(object);
    }
    // Scene graph placement always happens — layers work normally
    if (layer == null) {
        getSceneRoot().add(object, layers.get(DefaultLayer));
    } else {
        var idx = layers.get(layer);
        if (idx == null) throw 'layer not found $layer';
        getSceneRoot().add(object, idx);
    }
    return object;
}
```

This means layers work correctly during tab content routing:
```haxe
tabs.beginTab(1);
    addBuilderResult(bgResult, BackgroundLayer);     // BackgroundLayer in scene graph
    addElementWithPos(btn, 100, 80, DefaultLayer);   // DefaultLayer in scene graph
    addElementWithPos(dropdown, 100, 160, ModalLayer); // ModalLayer in scene graph
tabs.endTab();
// All three are in their correct layers. Tab only toggles visibility.
```

### addTabs helper

```haxe
function addTabs(builder:MultiAnimBuilder, settings:ResolvedSettings,
        items:Array<UIElementListItem>, selectedIndex:Int = 0):UIMultiAnimTabs {
    final tabBarBuildName = getSettings(settings, "buildName", "tabBar");
    final tabButtonBuildName = getSettings(settings, "tabButtonBuildName", "tabButton");
    final split = splitSettings(settings,
        ["buildName", "tabButtonBuildName"], [],
        ["tabButton"], [],
        "tabs");
    return new UIMultiAnimTabs(builder, tabBarBuildName, tabButtonBuildName,
        items, selectedIndex, this, split.main);
}
```

### Usage — identical to normal screen code

```haxe
override function load() {
    var items:Array<UIElementListItem> = [
        {name: "Inventory"},
        {name: "Stats"},
        {name: "Skills"},
    ];

    tabs = addTabs(builder, settings, items, 0);
    addElementWithPos(tabs, 50, 20);

    // --- Tab 0: Inventory ---
    tabs.beginTab(0);
        var buyBtn = addButton(builder, null, "Buy");
        addElementWithPos(buyBtn, 100, 80);

        var quantitySlider = addSlider(builder, null, 1);
        addElementWithPos(quantitySlider, 100, 120);

        var categoryDropdown = addDropdown(...);
        addElementWithPos(categoryDropdown, 100, 160);

        addBuilderResult(builder.buildWithParameters("inventoryGrid", []), DefaultLayer);
    tabs.endTab();

    // --- Tab 1: Stats ---
    tabs.beginTab(1);
        var statsPanel = buildStatsPanel(builder);
        addElementWithPos(statsPanel, 100, 80);

        addBuilderResult(builder.buildWithParameters("statsBg", []), BackgroundLayer);
    tabs.endTab();

    // --- Tab 2: Skills ---
    tabs.beginTab(2);
        var skillTree = buildSkillTree(builder);
        addElementWithPos(skillTree, 100, 80);
    tabs.endTab();
}

override function onScreenEvent(event, source) {
    switch event {
        case UIChangeItem(index, _) if (source == tabs):
            trace('switched to tab $index');
        case UIClick if (source == buyBtn):
            // works — only fires when tab 0 is active
            buyItem();
        default:
    }
}
```

All the normal screen methods — `addButton`, `addSlider`, `addDropdown`, `addElementWithPos`,
`addBuilderResult` — work unchanged inside `tabs.beginTab()` / `tabs.endTab()`.

### How it all connects

```
tabs.beginTab(1)
  └─ sets screen.contentTarget = tabs (with populatingTabIndex = 1)

Screen.addElement(btn)                          Screen.addObjectToLayer(obj)
  └─ contentTarget set?                           └─ contentTarget set?
      ├─ YES → contentTarget.registerElement(btn)     ├─ YES → contentTarget.registerObject(obj)
      │         └─ tabs.tabContent[1].push(btn)       │         └─ tabs.tabObjects[1].push(obj)
      │        contentTargetOwnership[btn] = tabs      │        (always adds to scene graph too)
      │        addObjectToLayer(btn.getObject())       │
      └─ NO  → elements.push(btn)  // normal     └─ NO  → (normal scene graph add)

tabs.endTab()
  └─ hides tab 1 content if tab 1 is not selected
     clears screen.contentTarget

Controller.getEventElement(pos)
  └─ iterates integration.getElements(SETReceiveEvents)
      └─ UIScreenBase.getElements()
          ├─ screen.elements  (tabs component is here)
          └─ subElementProviders → tabs.getSubElements()
              ├─ always: tab buttons
              └─ only active tab's content elements
```

## Edge Cases

### Nesting safety

`beginTab` throws if `populatingTabIndex != -1`. `setContentTarget` throws if already set.
No nested routing.

### removeElement for tab-owned elements

A `contentTargetOwnership` map on the screen tracks which elements were routed:

```haxe
// On UIScreenBase
var contentTargetOwnership:Map<UIElement, ContentTarget> = [];

// In removeElement:
public function removeElement(element:UIElement) {
    var owner = contentTargetOwnership.get(element);
    if (owner != null) {
        owner.unregisterElement(element);
        contentTargetOwnership.remove(element);
    } else {
        elements.remove(element);
    }
    element.getObject().remove();
    element.clear();
    if (Std.isOfType(element, UIElementSubElements))
        subElementProviders.remove(cast(element, UIElementSubElements));
    return element;
}
```

`ContentTarget` needs an `unregisterElement` method:
```haxe
interface ContentTarget {
    function registerElement(element:UIElement):Void;
    function registerObject(object:h2d.Object):Void;
    function unregisterElement(element:UIElement):Void;
}
```

### Screen reference

`UIMultiAnimTabs` needs a reference to the screen to call `setContentTarget`/`clearContentTarget`.
Passed via constructor (from `addTabs` helper which has `this`).

### Disabled individual tabs

```haxe
items[2].disabled = true;
tabs.refreshDisabledState(); // updates tab button disabled flags
```

Or the whole tab bar:
```haxe
tabs.disabled = true; // all buttons disabled, no switching
```

### Dynamic tab add/remove

Not in initial implementation. Would require rebuilding the tab bar programmable
(changing `count` param). Can be added later if needed.

### Leave event on tab switch

When switching tabs, if the mouse is hovering over a content element in the old tab,
that element should receive an `OnLeave` event. The controller's `currentOver` may still
reference the now-hidden element.

Rely on natural leave behavior — on next mouse move, `containsPoint` returns false for
invisible objects, controller sends `OnLeave`. Slight delay (one frame) but no coupling
to controller internals.

### clear() on screen

`UIScreenBase.clear()` already removes all elements and clears the scene graph. The tabs
component's `clear()` should also clear all registered tab content. Since the tabs component
is in `screen.elements`, the screen's `clear()` loop calls `tabs.clear()` which handles it.
The `contentTargetOwnership` map should also be cleared in `UIScreenBase.clear()`.

## Summary

| Aspect | Design |
|--------|--------|
| Tab buttons | `UIMultiAnimTabButton` — button with selected state, combo params `["status", "disabled"]` |
| Container | `UIMultiAnimTabs` — manages buttons + content, implements `UIElementSubElements` + `ContentTarget` |
| Event filtering | `getSubElements()` only returns active tab content |
| Visibility | Automatic show/hide on tab switch |
| Screen helper | `addTabs()` on `UIScreenBase` |
| Content routing | `tabs.beginTab(index)` / `tabs.endTab()` — sets generic `ContentTarget` on screen |
| Screen mechanism | `ContentTarget` interface — generic, reusable for accordion etc. |
| Event | `UIChangeItem(index, items)` on tab switch |
| .manim | `#tabButton` programmable + `#tabBar` programmable (repeatable + placeholder) |
| Key principle | All existing screen helpers work unchanged inside `beginTab`/`endTab` |

## Files to Create/Modify

| File | Change |
|------|--------|
| `src/bh/ui/UIMultiAnimTabs.hx` | **New** — `UIMultiAnimTabButton`, `UIMultiAnimTabs`, `ContentTarget` interface |
| `src/bh/ui/screens/UIScreen.hx` | Add `contentTarget`, `contentTargetOwnership`, `setContentTarget()`, `clearContentTarget()` to `UIScreenBase`; routing check in `addElement` and `addObjectToLayer`; `addTabs()` helper |
| `test/examples/N-tabs/` | Visual test with tab bar + content switching |
