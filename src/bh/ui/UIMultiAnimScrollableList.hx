package bh.ui;

import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimMultiResult;
import bh.base.MAObject;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;

// var allStates = hover, pressed, disabled, normal, selected
class UIMultiAnimScrollableList implements UIElement implements StandardUIElementEvents implements UIElementSyncRedraw implements UIElementUpdatable
		implements UIElementListValue {
	final itemBuilder:UIElementItemBuilder;
	final panelBuilder:MultiAnimBuilder;
	final panelName:String;

	final root:h2d.Object;
	final mask:h2d.Mask;

	var scrollbar:h2d.Object = null;

	var interactives:Array<MAObject> = [];

	public var requestRedraw = true;

	var width:Int;
	var height:Int;
	var totalHeight:Float; // scrollable height
	var keyScrollingUp = false;
	var keyScrollingDown = false;

	public var scrollSpeed:Float = 100;

	final displayItems:Map<Int, MultiAnimMultiResult> = [];
	final itemYPositions:Map<Int, Float> = [];

	public final items:Array<UIElementListItem> = [];
	@:isVar public var currentItemIndex(default, set):Int = 0;
	@:isVar public var currentHoverIndex(default, set):Int = -1;
	@:isVar public var currentPressedIndex(default, set):Int = -1;

	var selectedItem:Null<h2d.Object> = null;
	var hoverItem:Null<h2d.Object> = null;
	var pressedItem:Null<h2d.Object> = null;
	var hoverMode:Bool = false;
	var panelResults:BuilderResult;
	var lastClick = 0.;
	var lastClickIndex = -1;
	var topClearance = 0;


	function new(builder:MultiAnimBuilder, itemBuilder:UIElementItemBuilder, panelName:String, width:Int, height:Int, items, topClearance, initialIndex = 0) {
		this.panelBuilder = builder;
		this.panelName = panelName;
		this.itemBuilder = itemBuilder;
		this.root = new h2d.Object();

		this.items = items;
		this.width = width;
		this.height = height;
		this.topClearance = topClearance;
		this.mask = new h2d.Mask(width, height);
		this.panelResults = buildPanel();
		currentItemIndex = initialIndex;
		buildItems();
	}


	public function clear() {
		this.selectedItem = null;
		this.hoverItem = null;
		this.pressedItem = null;
		this.scrollbar = null;
		this.interactives = [];
	}


	public static function create(builder:MultiAnimBuilder, itemBuilder, panelName:String, width:Int, height:Int, items, topClearance, initialIndex) {
		return new UIMultiAnimScrollableList(builder, itemBuilder, panelName, width, height, items, topClearance, initialIndex);
	}

	function buildPanel() {
		var builtPanel = panelBuilder.buildWithParameters(panelName, ["width" => width, "height" => height, "topClearance" => topClearance],
			{placeholderObjects: ["mask" => PVObject(mask)]});
		root.removeChildren();

		root.addChild(builtPanel.object);

		return builtPanel;
	}

	function getBuiltItem(multi:MultiAnimMultiResult, state:String, selected:Bool, disabled:Bool) {
		return multi.findResultByCombo(state, selected, disabled);
	}

	function buildItems() {
		mask.removeChildren();
		displayItems.clear();
		interactives = [];

		var y = 0.;
		for (index => value in this.items) {
			final builtMultiItem = itemBuilder.buildItem(index, value, width, height);

			var result = getBuiltItem(builtMultiItem, "normal", false, value.disabled == true);
			var height = result.rootSettings.getFloatOrException("height");
			displayItems.set(index, builtMultiItem);
			itemYPositions.set(index, y);
			this.mask.addChild(result.object);
			result.object.setPosition(0, y);
			y += height;
			this.interactives = this.interactives.concat(result.interactives);
		}
		this.totalHeight = y;
		this.mask.height = this.height;
		this.mask.scrollBounds = h2d.col.Bounds.fromValues(0, 0, 0, hxd.Math.max(totalHeight, height));
		updateScrollbar();
	}

	function updateScrollbar() {
		if (this.scrollbar != null)
			this.scrollbar.remove();
		if (this.height < totalHeight) { // show scrollbar

			final buildResult = panelBuilder.buildWithParameters("scrollbar", [
				"panelHeight" => '${height}',
				"scrollableHeight" => '${totalHeight}',
				"scrollPosition" => '${this.mask.scrollY}'
			]);
			this.scrollbar = buildResult.object;
			this.scrollSpeed = buildResult.rootSettings.getFloatOrDefault("scrollSpeed", 100);

			var objs = this.panelResults.names.get("scrollbar");
			objs[0].getBuiltHeapsObject().toh2dObject().addChild(this.scrollbar);
		}
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
			case MAInteractive(width, height, identifier):
				var ident = Std.parseInt(identifier);
				if (ident == null)
					throw 'could not parse interactive id ${identifier}';
				return ident;
		}
	}

	public function doRedraw() {
		this.requestRedraw = false;

		if (hoverItem != null)
			hoverItem.remove();
		if (selectedItem != null)
			selectedItem.remove();
		if (pressedItem != null)
			pressedItem.remove();

		var stateName = "normal";
		if (currentHoverIndex == currentItemIndex)
			stateName = "hover";
		if (currentPressedIndex == currentItemIndex)
			stateName = "pressed";

		final builtMultiItem = this.displayItems.get(currentItemIndex);
		if (currentItemIndex != -1) {
			this.selectedItem = getBuiltItem(builtMultiItem, stateName, true, false).object;
			this.mask.addChild(this.selectedItem);
			this.selectedItem.y = this.itemYPositions.get(currentItemIndex);
		}

		if (currentHoverIndex != -1) {
			final builtMultiItem = this.displayItems.get(currentHoverIndex);
			this.hoverItem = getBuiltItem(builtMultiItem, "hover", false, false).object;
			this.mask.addChild(this.hoverItem);
			this.hoverItem.y = this.itemYPositions.get(currentHoverIndex);
		}

		if (currentPressedIndex != -1) {
			final builtMultiItem = this.displayItems.get(currentPressedIndex);
			this.pressedItem = getBuiltItem(builtMultiItem, "pressed", false, false).object;
			this.mask.addChild(this.pressedItem);
			this.pressedItem.y = this.itemYPositions.get(currentPressedIndex);
		}
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		final time = haxe.Timer.stamp();
		var obj = findInteractiveIndex(wrapper.eventPos);
		final newIndex = obj == null ? null : parseInteractiveId(obj);
		switch wrapper.event {
			case OnPush(button):
				if (newIndex != null) {
					if (items[newIndex].disabled == null || items[newIndex].disabled == false) {
						if (time - lastClick < 0.3 && lastClickIndex == newIndex) {
							onItemDoubleClicked(newIndex, items, wrapper);
						}
						hoverMode = false;
						this.requestRedraw = true;
						this.currentPressedIndex = newIndex;
					}
				}
				lastClickIndex = newIndex;
				lastClick = time;

			case OnRelease(button):
				if (newIndex == currentPressedIndex && this.currentItemIndex != newIndex) {
					this.currentItemIndex = newIndex;
					triggerItemChanged(newIndex, wrapper);
				}
				currentPressedIndex = -1;
				hoverMode = true;

			case OnReleaseOutside(_) | OnPushOutside(_):
				this.currentPressedIndex = -1;
				this.hoverMode = true;

			case OnEnter:
				wrapper.control.outsideClick.trackOutsideClick(true);

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

				updateScrollbar();

			case OnWheel(dir):
				this.mask.scrollY += dir * 10;
				updateScrollbar();
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
			this.currentPressedIndex = value;
			requestRedraw = true;
		}

		return value;
	}

	function set_currentHoverIndex(value:Int):Int {
		if (value < -1 || value >= items.length)
			throw 'currentHoverIndex ${value} is out of bounds [-1..${items.length}].';
		if (this.currentHoverIndex != value) {
			this.currentHoverIndex = value;
			requestRedraw = true;
		}

		return value;
	}

	function set_currentItemIndex(value:Int):Int {
		if (value < -1 || value >= items.length)
			throw 'currentItemIndex ${value} is out of bounds [0..${items.length}].';
		if (this.currentItemIndex != value) {
			this.currentItemIndex = value;
			requestRedraw = true;
			// mainPartImages.updateAllText("selectedName", items[this.currentItemIndex].name);
		}

		return value;
	}

	public function update(dt:Float) {
		if (keyScrollingUp && !keyScrollingDown) {
			this.mask.scrollY -= scrollSpeed * dt;
			updateScrollbar();
		} else if (!keyScrollingUp && keyScrollingDown) {
			this.mask.scrollY += scrollSpeed * dt;
			updateScrollbar();
		}
	}

	function triggerItemChanged(newIndex:Int, wrapper:UIElementEventWrapper) {
		onItemChanged(newIndex, items, wrapper);
		wrapper.control.pushEvent(UIChangeItem(newIndex, items), this);
	}

	public dynamic function onItemChanged(newIndex:Int, items:Array<UIElementListItem>, wrapper:UIElementEventWrapper) {}

	public dynamic function onItemDoubleClicked(newIndex:Int, items:Array<UIElementListItem>, wrapper:UIElementEventWrapper) {}
}
