package bh.ui;

import bh.base.CursorManager;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.base.MAObject;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;

enum PanelSizeMode {
	FixedScroll;
	AutoSize;
}

enum ClickMode {
	SingleClick;
	DoubleClick;
}

// var allStates = hover, pressed, disabled, normal, selected
class UIMultiAnimScrollableList implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementUpdatable
		implements UIElementListValue implements UIElementCursor {
	final itemBuilder:UIElementBuilder;
	final panelBuilder:UIElementBuilder;
	final scrollbarBuilder:UIElementBuilder;
	final scrollbarInPanelName:String;

	final root:h2d.Object;
	final mask:h2d.Mask;

	var scrollbar:h2d.Object = null;
	var scrollbarResult:Null<BuilderResult> = null;

	var interactives:Array<MAObject> = [];

	public var disabled(default, set):Bool = false;

	var width:Int;
	var height:Int;
	var maxHeight:Int;
	var totalHeight:Float; // scrollable height
	var panelSizeMode:PanelSizeMode;
	var keyScrollingUp = false;
	var keyScrollingDown = false;

	public var scrollSpeed:Float = 100;
	public var scrollSpeedOverride:Null<Float> = null;
	public var doubleClickThreshold:Float = 0.3;
	public var wheelScrollMultiplier:Float = 10;
	public var clickMode:ClickMode = DoubleClick;

	final displayItems:Map<Int, BuilderResult> = [];
	final itemYPositions:Map<Int, Float> = [];

	public final items:Array<UIElementListItem> = [];
	@:isVar public var currentItemIndex(default, set):Int = 0;
	@:isVar public var currentHoverIndex(default, set):Int = -1;
	@:isVar public var currentPressedIndex(default, set):Int = -1;

	var hoverMode:Bool = false;
	var panelResults:BuilderResult;
	var lastClick = 0.;
	var lastClickIndex = -1;
	var topClearance = 0;

	function new(panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, width:Int, height:Int, items, topClearance, initialIndex = 0, panelSizeMode:PanelSizeMode = null) {
		this.panelBuilder = panelBuilder;
		this.itemBuilder = itemBuilder;
		this.scrollbarBuilder = scrollbarBuilder;
		this.scrollbarInPanelName = scrollbarInPanelName;
		this.root = new h2d.Object();
		this.panelSizeMode = panelSizeMode ?? FixedScroll;

		this.items = items;
		this.width = width;
		this.maxHeight = height;
		this.topClearance = topClearance;

		if (this.panelSizeMode == AutoSize) {
			this.height = computeAutoSizeHeight(items);
		} else {
			this.height = height;
		}

		this.mask = new h2d.Mask(width, this.height);
		this.panelResults = buildPanel();
		currentItemIndex = initialIndex;
		buildItems();
	}

	function computeAutoSizeHeight(items:Array<UIElementListItem>):Int {
		if (items.length == 0)
			return 0;
		final sampleResult = itemBuilder.buildItem(0, items[0], width, maxHeight);
		final singleHeight = sampleResult.rootSettings.getFloatOrException("height");
		sampleResult.object.remove();
		final totalItemsHeight = singleHeight * items.length;
		return Std.int(hxd.Math.min(totalItemsHeight, maxHeight));
	}

	public function clear() {
		this.scrollbar = null;
		this.scrollbarResult = null;
		this.interactives = [];
	}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
	}

	public function setItems(newItems:Array<UIElementListItem>, selectedIndex:Int = 0) {
		// Reset interaction state before changing items (setter validates bounds)
		this.currentHoverIndex = -1;
		this.currentPressedIndex = -1;

		// Clear and repopulate (items is final, can't reassign)
		this.items.resize(0);
		for (item in newItems)
			this.items.push(item);

		// Handle AutoSize mode
		if (panelSizeMode == AutoSize) {
			this.height = computeAutoSizeHeight(this.items);
			this.mask.height = this.height;
			this.panelResults = buildPanel();
		}

		// Reset scroll position
		this.mask.scrollY = 0;

		// Rebuild items and scrollbar
		buildItems();

		// Set selection — force-apply visual even if index hasn't changed (items were rebuilt)
		final idx = if (newItems.length > 0) selectedIndex else -1;
		this.currentItemIndex = -1;
		this.currentItemIndex = idx;
	}

	public static function createWithSingleBuilder(builder:MultiAnimBuilder, panelBuilderName:String, itemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, width:Int, height:Int, items, topClearance, initialIndex, ?panelSizeMode:PanelSizeMode) {
		return new UIMultiAnimScrollableList(builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(itemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, width, height, items, topClearance, initialIndex, panelSizeMode);
	}

	public static function create(builder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, width:Int, height:Int, items, topClearance, initialIndex, ?panelSizeMode:PanelSizeMode) {
		return new UIMultiAnimScrollableList(builder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, width, height, items, topClearance, initialIndex, panelSizeMode);
	}

	function buildPanel() {
		var builtPanel = this.panelBuilder.builder.buildWithParameters(this.panelBuilder.name, ["width" => width, "height" => height, "topClearance" => topClearance],
			{placeholderObjects: ["mask" => PVObject(mask)]});
		root.removeChildren();
		root.addChild(builtPanel.object);
		return builtPanel;
	}

	function buildItems() {
		mask.removeChildren();
		displayItems.clear();
		interactives = [];

		var y = 0.;
		for (index => value in this.items) {
			final result = itemBuilder.buildItem(index, value, width, height);

			var itemHeight = result.rootSettings.getFloatOrException("height");
			displayItems.set(index, result);
			itemYPositions.set(index, y);
			this.mask.addChild(result.object);
			result.object.setPosition(0, y);
			y += itemHeight;
			this.interactives = this.interactives.concat(result.interactives);
		}
		this.totalHeight = y;
		this.mask.height = this.height;
		this.mask.scrollBounds = h2d.col.Bounds.fromValues(0, 0, 0, hxd.Math.max(totalHeight, height));
		buildScrollbar();
	}

	function buildScrollbar() {
		if (this.scrollbar != null)
			this.scrollbar.remove();
		this.scrollbarResult = null;
		if (this.height < totalHeight) { // show scrollbar

			final buildResult = this.scrollbarBuilder.builder.buildWithParameters(this.scrollbarBuilder.name, [
				"panelHeight" => '${height}',
				"scrollableHeight" => '${totalHeight}',
				"scrollPosition" => '0'
			], null, null, true);
			this.scrollbarResult = buildResult;
			this.scrollbar = buildResult.object;
			this.scrollSpeed = scrollSpeedOverride ?? buildResult.rootSettings.getFloatOrDefault("scrollSpeed", 100);

			var objs = this.panelResults.names.get(scrollbarInPanelName);
			if (objs == null) {
				throw 'could not find scrollbar #${scrollbarInPanelName} in panel ${this.panelBuilder.name}';
			}
			else if (objs.length > 1) {
				throw 'found multiple scrollbars #${scrollbarInPanelName} in panel ${this.panelBuilder.name}';
			}
			else objs[0].getBuiltHeapsObject().toh2dObject().addChild(this.scrollbar);
		}
	}

	function repositionScrollbar() {
		if (this.scrollbarResult != null) {
			this.scrollbarResult.setParameter("scrollPosition", Std.int(this.mask.scrollY));
		}
	}

	public function scrollToIndex(idx:Int) {
		if (idx < 0 || idx >= items.length)
			return;
		final itemY = itemYPositions.get(idx);
		if (itemY == null)
			return;
		final result = displayItems.get(idx);
		if (result == null)
			return;
		final itemHeight = result.rootSettings.getFloatOrException("height");
		final scrollTop = mask.scrollY;
		final scrollBottom = scrollTop + height;
		if (itemY >= scrollTop && itemY + itemHeight <= scrollBottom)
			return; // already visible
		if (itemY < scrollTop)
			mask.scrollY = itemY
		else
			mask.scrollY = itemY + itemHeight - height;
		repositionScrollbar();
	}

	public function scrollToAndSelect(idx:Int) {
		scrollToIndex(idx);
		this.currentItemIndex = idx;
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	function findInteractiveIndex(point):Null<MAObject> {
		for (object in interactives) {
			if (object.getBounds().contains(point))
				return object;
		}
		return null;
	}

	function parseInteractiveId(obj:MAObject):Int {
		switch obj.multiAnimType {
			case MAInteractive(width, height, identifier, _):
				var ident = Std.parseInt(identifier);
				if (ident == null)
					throw 'could not parse interactive id ${identifier}';
				return ident;
			case MADraggable(width, height):
				// For draggable objects, we can use a default ID or throw an error
				// Since scrollable lists typically don't use draggable objects, we'll throw an error
				throw 'Draggable objects are not supported in scrollable lists';
		}
	}

	function getBaseStatus(index:Int):String {
		if (index < 0 || index >= items.length) return "normal";
		final item = items[index];
		if (item.baseStatus != null) return item.baseStatus;
		if (item.disabled == true) return "disabled";
		return "normal";
	}

	function setItemStatus(index:Int, status:String) {
		final item = displayItems.get(index);
		if (item != null)
			item.setParameter("status", status);
	}

	function setItemSelected(index:Int, selected:Bool) {
		final item = displayItems.get(index);
		if (item != null)
			item.setParameter("selected", selected ? "true" : "false");
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			if (value) {
				root.alpha = 0.5;
				this.currentHoverIndex = -1;
				this.currentPressedIndex = -1;
			} else {
				root.alpha = 1.0;
			}
		}
		return value;
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
		final time = haxe.Timer.stamp();
		var obj = findInteractiveIndex(wrapper.eventPos);
		final newIndex = obj == null ? null : parseInteractiveId(obj);
		switch wrapper.event {
			case OnPush(button):
				if (newIndex != null) {
					if (items[newIndex].disabled == null || items[newIndex].disabled == false) {
						if (clickMode == DoubleClick && time - lastClick < doubleClickThreshold && lastClickIndex == newIndex) {
							this.currentItemIndex = newIndex;
							triggerItemChanged(newIndex, wrapper);
							onItemDoubleClicked(newIndex, items, wrapper);
							wrapper.control.pushEvent(UIDoubleClickItem(newIndex, items), this);
						}
						hoverMode = false;
						this.currentPressedIndex = newIndex;
					}
				}
				lastClickIndex = newIndex;
				lastClick = time;

			case OnRelease(button):
				if (newIndex == currentPressedIndex && this.currentItemIndex != newIndex) {
					this.currentItemIndex = newIndex;
					triggerItemChanged(newIndex, wrapper);
					if (clickMode == SingleClick) {
						onItemClicked(newIndex, items, wrapper);
						wrapper.control.pushEvent(UIClickItem(newIndex, items), this);
					}
				}
				currentPressedIndex = -1;
				hoverMode = true;

			case OnReleaseOutside(_) | OnPushOutside(_):
				this.currentPressedIndex = -1;
				this.hoverMode = true;

			case OnEnter:
				wrapper.control.trackOutsideClick(true);

			case OnLeave:
				this.currentHoverIndex = -1;
			case OnMouseMove:
				if (newIndex != null && newIndex != this.currentHoverIndex) {
					this.currentHoverIndex = newIndex;
				}

			case OnKey(key, release):
				if (key == hxd.Key.UP)
					keyScrollingUp = !release;
				if (key == hxd.Key.DOWN)
					keyScrollingDown = !release;

			case OnWheel(dir):
				this.mask.scrollY += dir * wheelScrollMultiplier;
				repositionScrollbar();
		}
	}

	public function setSelectedIndex(idx:Int) {
		this.currentItemIndex = idx;
	}

	public function getSelectedIndex():Int {
		return currentItemIndex;
	}

	public function getList():Array<UIElementListItem> {
		return items;
	}

	function set_currentPressedIndex(value:Int):Int {
		if (value < -1 || value >= items.length)
			throw 'currentPressedIndex ${value} is out of bounds [-1..${items.length}].';
		if (this.currentPressedIndex != value) {
			if (this.currentPressedIndex != -1)
				setItemStatus(this.currentPressedIndex, getBaseStatus(this.currentPressedIndex));
			this.currentPressedIndex = value;
			if (value != -1)
				setItemStatus(value, "pressed");
		}

		return value;
	}

	function set_currentHoverIndex(value:Int):Int {
		if (value < -1 || value >= items.length)
			throw 'currentHoverIndex ${value} is out of bounds [-1..${items.length}].';
		if (this.currentHoverIndex != value) {
			if (this.currentHoverIndex != -1)
				setItemStatus(this.currentHoverIndex, getBaseStatus(this.currentHoverIndex));
			this.currentHoverIndex = value;
			if (value != -1)
				setItemStatus(value, "hover");
		}

		return value;
	}

	function set_currentItemIndex(value:Int):Int {
		if (value < -1 || value >= items.length)
			throw 'currentItemIndex ${value} is out of bounds [-1..${items.length - 1}].';
		if (this.currentItemIndex != value) {
			if (this.currentItemIndex != -1)
				setItemSelected(this.currentItemIndex, false);
			this.currentItemIndex = value;
			if (value != -1)
				setItemSelected(value, true);
		}

		return value;
	}

	public function update(dt:Float) {
		if (keyScrollingUp && !keyScrollingDown) {
			this.mask.scrollY -= scrollSpeed * dt;
			repositionScrollbar();
		} else if (!keyScrollingUp && keyScrollingDown) {
			this.mask.scrollY += scrollSpeed * dt;
			repositionScrollbar();
		}
	}

	function triggerItemChanged(newIndex:Int, wrapper:UIElementEventWrapper) {
		onItemChanged(newIndex, items, wrapper);
		wrapper.control.pushEvent(UIChangeItem(newIndex, items), this);
	}

	public dynamic function onItemChanged(newIndex:Int, items:Array<UIElementListItem>, wrapper:UIElementEventWrapper) {}

	public dynamic function onItemDoubleClicked(newIndex:Int, items:Array<UIElementListItem>, wrapper:UIElementEventWrapper) {}

	public dynamic function onItemClicked(newIndex:Int, items:Array<UIElementListItem>, wrapper:UIElementEventWrapper) {}
}
