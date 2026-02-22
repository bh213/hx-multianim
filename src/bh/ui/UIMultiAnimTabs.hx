package bh.ui;

import bh.multianim.MultiAnimMultiResult;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimParser.toh2dObject;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;

/**
 * Interface for components that can intercept screen element routing.
 * When set as the active content target on UIScreenBase, all addElement/addObjectToLayer
 * calls are redirected to this target instead of the screen's main element list.
 */
interface ContentTarget {
	function registerElement(element:UIElement):Void;
	function registerObject(object:h2d.Object):Void;
	function unregisterElement(element:UIElement):Void;

	/** When true, this content target manages its own scene graph.
	 * addObjectToLayer delegates to addToLayer() instead of the screen root. */
	function handlesSceneGraph():Bool;

	/** Add object to a layer within this content target's own layer hierarchy. */
	function addToLayer(object:h2d.Object, layerIndex:Int):Void;
}

/**
 * A single tab button. Uses the same combo pattern as UIStandardMultiCheckbox
 * (status/disabled/checked axes) but with tab-specific click behavior:
 * clicking a selected tab does nothing, clicking an unselected tab selects it.
 */
@:nullSafety
class UIMultiAnimTabButton implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementSyncRedraw {
	final multiResult:MultiAnimMultiResult;
	var checkboxObject:Null<h2d.Object>;

	var status(default, set):StandardUIElementStates = SUINormal;
	var root:h2d.Object;

	public var disabled(default, set):Bool = false;
	public var selected(default, set):Bool = false;
	public var requestRedraw = true;

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public function set_selected(value:Bool):Bool {
		if (this.selected != value) {
			this.selected = value;
			this.requestRedraw = true;
		}
		return value;
	}

	@:allow(bh.ui.UIMultiAnimTabs)
	function new(builder:MultiAnimBuilder, name:String, ?extraParams:Null<Map<String, Dynamic>>) {
		this.root = new h2d.Object();
		var params:Map<String, Dynamic> = [];
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);
		this.multiResult = builder.buildWithComboParameters(name, params, ["status", "disabled", "checked"]);
	}

	public function clear() {
		this.checkboxObject = null;
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.checkboxObject != null)
			this.checkboxObject.remove();

		var result = multiResult.findResultByCombo(standardUIElementStatusToString(status), '${disabled}', '${selected}');
		this.checkboxObject = result.object;
		root.addChild(result.object);
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
		switch wrapper.event {
			case OnPush(button):
				if (!selected) {
					this.status = SUIPressed;
					onInternalClick(wrapper.control);
				}
			case OnRelease(button):
				this.status = selected ? SUINormal : SUINormal;
			case OnReleaseOutside(_):
			case OnPushOutside(_):

			case OnEnter:
				this.status = SUIHover;
			case OnLeave:
				this.status = SUINormal;
			case OnKey(up, key):
			case OnWheel(dir):
			case OnMouseMove:
		}
	}

	@:allow(bh.ui.UIMultiAnimTabs)
	dynamic function onInternalClick(controllable:Controllable) {}
}

/**
 * Tab bar component with built-in content management.
 * Manages mutually exclusive tab buttons and controls which content elements
 * are visible and receive events.
 *
 * Uses UIElementSubElements.getSubElements() to expose only active tab content
 * to the controller — inactive tabs are automatically excluded from event dispatch.
 *
 * Content is registered via screen routing: tabs.beginTab(n) / tabs.endTab()
 * redirects screen's addElement/addObjectToLayer to this component.
 */
@:nullSafety
@:allow(bh.ui.screens.UIScreen.UIScreenBase)
class UIMultiAnimTabs implements UIElement implements UIElementDisablable implements UIElementListValue implements UIElementSubElements implements ContentTarget {
	public var disabled(default, set):Bool = false;

	final tabButtons:Array<UIMultiAnimTabButton> = [];
	final items:Array<UIElementListItem>;
	final builder:MultiAnimBuilder;
	final tabButtonBuilderName:String;
	var selectedIndex:Int;
	final builderResult:BuilderResult;

	// Content management — per tab
	final tabContent:Map<Int, Array<UIElement>> = [];
	final tabObjects:Map<Int, Array<h2d.Object>> = [];

	// Which tab index is currently being populated (set by beginTab/endTab)
	var populatingTabIndex:Int = -1;

	// Screen reference for content routing
	final screen:bh.ui.screens.UIScreen.UIScreenBase;

	// Extra params forwarded to individual tab buttons (e.g. width, height from prefixed settings)
	final tabButtonExtraParams:Null<Map<String, Dynamic>>;

	// Relative mode — per-tab h2d.Layers for content, parented under contentRoot element
	final tabLayersRoots:Map<Int, h2d.Layers> = [];
	var relativeMode:Bool = false;

	public function new(builder:MultiAnimBuilder, tabBarBuildName:String, tabButtonBuildName:String, items:Array<UIElementListItem>, selectedIndex:Int,
			screen:bh.ui.screens.UIScreen.UIScreenBase, ?extraParams:Null<Map<String, Dynamic>>, ?tabButtonExtraParams:Null<Map<String, Dynamic>>,
			?contentRootName:Null<String>, ?screenLayers:Null<Map<bh.ui.screens.UIScreen.LayersEnum, Int>>) {
		this.builder = builder;
		this.items = items;
		this.tabButtonBuilderName = tabButtonBuildName;
		this.selectedIndex = selectedIndex;
		this.screen = screen;
		this.tabButtonExtraParams = tabButtonExtraParams;

		var params:Map<String, Dynamic> = ["count" => items.length];
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);

		this.builderResult = builder.buildWithParameters(tabBarBuildName, params, {callback: builderCallback});

		// Set up relative mode if contentRoot is specified
		if (contentRootName != null) {
			final namedItems = builderResult.names[contentRootName];
			if (namedItems == null || namedItems.length == 0)
				throw 'tabPanel.contentRoot: named element "$contentRootName" not found in tabBar programmable';
			final contentRootObj = toh2dObject(namedItems[0].object);
			// Create per-tab h2d.Layers as children of the content root point
			for (i in 0...items.length) {
				final tabLayers = new h2d.Layers();
				contentRootObj.addChild(tabLayers);
				tabLayersRoots.set(i, tabLayers);
			}
			this.relativeMode = true;
		} else {
			this.relativeMode = false;
		}

		applySelectedIndex(selectedIndex);
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			for (btn in tabButtons)
				btn.disabled = value;
		}
		return value;
	}

	function builderCallback(request:CallbackRequest):CallbackResult {
		switch request {
			case NameWithIndex(name, index):
				return CBRString(items[index].name);
			case PlaceholderWithIndex(name, index):
				if (name == "tabButton") {
					var extraParams:Map<String, Dynamic> = ["buttonText" => items[index].name];
					if (tabButtonExtraParams != null)
						for (key => value in tabButtonExtraParams)
							extraParams.set(key, value);
					var btn = new UIMultiAnimTabButton(builder, tabButtonBuilderName, extraParams);
					tabButtons[index] = btn;
					btn.onInternalClick = onTabButtonClicked.bind(index);
					if (items[index].disabled == true)
						btn.disabled = true;
					return CBRObject(btn.getObject());
				} else
					throw 'invalid tab placeholder: ${name}';

			default:
				throw 'unsupported tab callback: ${request}';
		}
	}

	function onTabButtonClicked(index:Int, controllable:Controllable) {
		if (index == selectedIndex)
			return;
		setSelectedIndex(index);
		onTabChanged(index, items);
		controllable.pushEvent(UIChangeItem(index, items), this);
	}

	public dynamic function onTabChanged(index:Int, items:Array<UIElementListItem>) {}

	// --- UIElementListValue ---

	public function setSelectedIndex(idx:Int) {
		if (idx == selectedIndex)
			return;
		var oldIndex = selectedIndex;
		selectedIndex = idx;

		applySelectedIndex(idx);

		// Hide old tab content
		setTabContentVisible(oldIndex, false);

		// Show new tab content
		setTabContentVisible(idx, true);
	}

	function applySelectedIndex(idx:Int) {
		for (i => btn in tabButtons) {
			btn.selected = (i == idx);
		}
	}

	public function getSelectedIndex():Int {
		return selectedIndex;
	}

	public function getList():Array<UIElementListItem> {
		return items;
	}

	// --- Content registration (called by screen routing) ---

	public function registerElement(element:UIElement):Void {
		var list = tabContent.get(populatingTabIndex);
		if (list == null) {
			list = [];
			tabContent.set(populatingTabIndex, list);
		}
		list.push(element);
	}

	public function registerObject(object:h2d.Object):Void {
		var list = tabObjects.get(populatingTabIndex);
		if (list == null) {
			list = [];
			tabObjects.set(populatingTabIndex, list);
		}
		list.push(object);
	}

	public function unregisterElement(element:UIElement):Void {
		for (_ => list in tabContent) {
			if (list.remove(element))
				return;
		}
	}

	// --- ContentTarget scene graph ---

	public function handlesSceneGraph():Bool {
		return relativeMode;
	}

	public function addToLayer(object:h2d.Object, layerIndex:Int):Void {
		final tabLayers = tabLayersRoots.get(populatingTabIndex);
		if (tabLayers == null)
			throw 'no layers root for tab $populatingTabIndex';
		tabLayers.add(object, layerIndex);
	}

	// --- Tab content routing ---

	public function beginTab(tabIndex:Int) {
		if (populatingTabIndex != -1)
			throw 'already populating tab $populatingTabIndex';
		if (tabIndex < 0 || tabIndex >= items.length)
			throw 'tab index $tabIndex out of range (0..${items.length - 1})';
		populatingTabIndex = tabIndex;
		screen.setContentTarget(this);
	}

	public function endTab() {
		if (populatingTabIndex == -1)
			throw 'not populating any tab';
		// Hide content for non-selected tabs
		if (populatingTabIndex != selectedIndex)
			setTabContentVisible(populatingTabIndex, false);
		populatingTabIndex = -1;
		screen.clearContentTarget();
	}

	// --- Visibility ---

	function setTabContentVisible(tabIndex:Int, visible:Bool) {
		// In relative mode, toggle the tab's layers root for efficient show/hide
		if (relativeMode) {
			final tabLayers = tabLayersRoots.get(tabIndex);
			if (tabLayers != null)
				tabLayers.visible = visible;
			return;
		}
		var elements = tabContent.get(tabIndex);
		if (elements != null)
			for (el in elements)
				el.getObject().visible = visible;

		var objects = tabObjects.get(tabIndex);
		if (objects != null)
			for (obj in objects)
				obj.visible = visible;
	}

	// --- UIElementSubElements ---

	public function getSubElements(type:SubElementsType):Array<UIElement> {
		var result:Array<UIElement> = [];

		// Always include tab buttons (they always receive events)
		for (btn in tabButtons)
			result.push(cast btn);

		// Only include content from active tab
		var activeContent = tabContent.get(selectedIndex);
		if (activeContent != null) {
			for (element in activeContent) {
				result.push(element);
				// Recurse into sub-elements
				if (Std.isOfType(element, UIElementSubElements)) {
					var sub = cast(element, UIElementSubElements).getSubElements(type);
					for (s in sub)
						result.push(s);
				}
			}
		}

		return result;
	}

	// --- UIElement ---

	public function getObject():Object {
		return builderResult.object;
	}

	public function containsPoint(pos:Point):Bool {
		return false;
	}

	public function clear() {
		for (_ => list in tabContent)
			list.resize(0);
		for (_ => list in tabObjects)
			list.resize(0);
		tabButtons.resize(0);
	}

	// --- Disabled state refresh ---

	public function refreshDisabledState() {
		for (i => btn in tabButtons) {
			btn.disabled = disabled || (items[i].disabled == true);
		}
	}
}
