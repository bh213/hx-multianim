package bh.ui;

import bh.base.CursorManager;
import bh.ui.screens.UIScreen;
import bh.base.PositionLinkObject;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import hxd.Rand;
import bh.base.MAObject;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;
import bh.ui.UIMultiAnimScrollableList.PanelSizeMode;

private enum AnimState {
	Opening;
	Closing;
	Open;
	Closed;
}

@:nullSafety
class UIStandardMultiAnimDropdown implements UIElement implements UIElementDisablable implements UIElementUpdatable implements StandardUIElementEvents
		implements UIElementListValue implements UIElementSubElements implements UIElementCustomAddToLayer
		implements UIElementCursor {
	final result:BuilderResult;
	var status(default, set):StandardUIElementStates = SUINormal;
	var root:h2d.Object;
	final builder:UIElementBuilder;
	var panel:UIMultiAnimScrollableList;
	var panelObject:h2d.Object;
	var panelStatus:AnimState = Closed;
	var timer:Float = 0;
	var timerTotal:Float = 0;

	var transitionTimerBase = 1.0;
	public var transitionTimerOverride:Null<Float> = null;

	public var disabled(default, set):Bool = false;
	public var items:Array<UIElementListItem> = [];
	@:isVar public var currentItemIndex(default, set):Int = 0;
	public var autoOpen:Bool = true;
	public var autoCloseOnLeave:Bool = true;
	public var closeOnOutsideClick:Bool = true;
	var panelScreen:Null<UIScreen> = null;
	var panelLayer:Null<LayersEnum> = null;

	@:nullSafety(Off)
	function new(builder:UIElementBuilder, builtPanel, items, initialIndex = 0) {
		this.builder = builder;

		this.root = new h2d.Object();
		this.items = items;

		var inputParams:Map<String, Dynamic> = ["status" => "normal", "panel" => "closed"];
		if (builder.extraParams != null) {
			for (key => value in builder.extraParams)
				inputParams.set(key, value);
		}
		this.result = this.builder.builder.buildWithParameters(builder.name, inputParams, {callback: @:nullSafety(Off) callback}, null, true);

		transitionTimerBase = result.rootSettings.getFloatOrDefault("transitionTimer", 1.0);
		root.addChild(result.object);

		var updatable = result.getUpdatable("panelPoint");

		this.panelStatus = Closed;
		this.panel = builtPanel;
		this.panelObject = this.panel.getObject();
		this.panelObject.visible = false;
		updatable.setObject(new PositionLinkObject(panelObject));
		this.panel.onItemChanged = onPanelItemChanged;
		@:nullSafety(Off) this.currentItemIndex = initialIndex;
	}

	public function clear() {
		this.items = [];
		this.panelScreen = null;
		this.panelLayer = null;
	}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
	}

	function set_currentItemIndex(value:Int):Int {
		if (value < 0 || value >= items.length)
			throw 'currentItemIndex ${value} is out of bounds [0..${items.length}].';
		if (this.currentItemIndex != value) {
			this.currentItemIndex = value;
			result.getUpdatable("selectedName").updateText(items[this.currentItemIndex].name);
		}
		return value;
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			result.setParameter("status", value ? "disabled" : standardUIElementStatusToString(status));
		}
		return value;
	}

	function isOpen() {
		return switch panelStatus {
			case Opening | Open: true;
			case Closing | Closed: false;
		}
	}

	public static function createWithPrebuiltPanel(builder:UIElementBuilder, panel:UIMultiAnimScrollableList, items, initialIndex = 0) {
		return new UIStandardMultiAnimDropdown(builder, panel, items, initialIndex);
	}

	public static function create(builder:UIElementBuilder, panelBuilder:UIElementBuilder, panelListItemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, initialIndex = 0, panelWidth = 120, panelHeight = 300, ?panelSizeMode:PanelSizeMode) {
		var panel = buildPanel(panelBuilder, panelListItemBuilder, scrollbarBuilder, scrollbarInPanelName, items, initialIndex, panelWidth, panelHeight, panelSizeMode);
		return new UIStandardMultiAnimDropdown(builder, panel, items, initialIndex);
	}

	/**
	 * Convenience factory that takes a single MultiAnimBuilder and component names.
	 * Uses standard component names by default (dropdown, list-panel, list-item-120, scrollbar).
	 */
	public static function createWithSingleBuilder(builder:MultiAnimBuilder, items:Array<UIElementListItem>, initialIndex = 0, dropdownName = "dropdown", panelName = "list-panel", itemName = "list-item-120", scrollbarName = "scrollbar", scrollbarInPanelName = "scrollbar", panelWidth = 120, panelHeight = 300, ?panelSizeMode:PanelSizeMode) {
		return create(builder.createElementBuilder(dropdownName), builder.createElementBuilder(panelName), builder.createElementBuilder(itemName), builder.createElementBuilder(scrollbarName), scrollbarInPanelName, items, initialIndex, panelWidth, panelHeight, panelSizeMode);
	}

	function callback(input:CallbackRequest):CallbackResult {
		switch input {
			case Name(name):
				return switch (name) {
					case "selectedName": CBRString(this.items[currentItemIndex].name);
					default: throw 'unexpected name ${name}';
				}

			case NameWithIndex(name, index):
				return switch (name) {
					case "itemName": CBRString(this.items[index].name);
					default: throw 'unexpected name ${name}';
				}
			case Placeholder(name):
			case PlaceholderWithIndex(name, index):
		}
		return CBRNoResult;
	}

	static function buildPanel(builder:UIElementBuilder, panelListItemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, initialIndex, panelWidth = 120, panelHeight = 300, ?panelSizeMode:PanelSizeMode) {
		return UIMultiAnimScrollableList.create(builder, panelListItemBuilder, scrollbarBuilder, scrollbarInPanelName, panelWidth, panelHeight, items, 0, initialIndex, panelSizeMode);
	}

	function onPanelItemChanged(newIndex, items, wrapper) {
		if (this.currentItemIndex != newIndex) {
			this.currentItemIndex = newIndex;

			triggerItemChanged(newIndex, wrapper.control);
			if (isOpen())
				startClose();
		}
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos) || (isOpen() && panel.containsPoint(pos));
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;

		if (isOpen() && this.panelObject.getBounds().contains(wrapper.eventPos)) {
			this.panel.onEvent(wrapper);
			return;
		}
		switch wrapper.event {
			case OnPush(button):
				this.status = SUIPressed;
			case OnRelease(button):
				this.status = SUINormal;
				if (!isOpen())
					startOpen()
				else
					startClose();

			case OnReleaseOutside(_) | OnPushOutside(_):
				this.status = SUINormal;
				if (closeOnOutsideClick && isOpen()) {
					startClose();
				}

			case OnEnter:
				if (autoOpen && !isOpen()) {
					startOpen();
					if (closeOnOutsideClick)
						wrapper.control.outsideClick.trackOutsideClick(true);
				}
				this.status = SUIHover;
			case OnLeave:
				if (autoCloseOnLeave && isOpen()) {
					startClose();
				}
				this.status = SUINormal;
			case OnKey(up, key):
			case OnWheel(dir):
			case OnMouseMove:
				if (!isOpen())
					return;
		}
	}

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			if (!disabled)
				result.setParameter("status", standardUIElementStatusToString(value));
		}
		return value;
	}

	function startOpen() {
		if (this.panelObject == null)
			return;
		panel.currentHoverIndex = -1;
		panel.currentItemIndex = this.currentItemIndex;
		panel.currentPressedIndex = -1;

		final effectiveTimer = transitionTimerOverride ?? transitionTimerBase;
		this.panelObject.visible = true;
		this.panelObject.alpha = 0;
		this.panelStatus = Opening;
		this.timer = effectiveTimer;
		this.timerTotal = this.timer;
		result.setParameter("panel", "open");
	}

	function startClose() {
		if (this.panelObject == null)
			return;
		final effectiveTimer = transitionTimerOverride ?? transitionTimerBase;
		this.panelObject.alpha = 1.0;
		this.panelStatus = Closing;
		this.timer = effectiveTimer;
		this.timerTotal = this.timer;
		result.setParameter("panel", "closed");
	}

	public function update(dt:Float) {
		this.panel.update(dt);
		timer -= dt;
		switch panelStatus {
			case Opening:
				if (this.panelObject == null)
					return;
				panelObject.alpha = hxd.Math.clamp(1.0 - timer / timerTotal, 0.0, 1.0);
				if (timer < 0) {
					panelObject.alpha = 1.0;
					panelStatus = Open;
				}

			case Closing:
				if (this.panelObject == null)
					return;
				panelObject.alpha = hxd.Math.clamp(timer / timerTotal, 0.0, 1.0);
				if (timer < 0) {
					panelStatus = Closed;
					this.panelObject.visible = false;
				}
			case Open | Closed:
		}
	}

	function triggerItemChanged(newIndex:Int, controllable:Controllable) {
		onItemChanged(newIndex, items);
		controllable.pushEvent(UIChangeItem(newIndex, items), this);
	}

	public dynamic function onItemChanged(newIndex:Int, items:Array<UIElementListItem>) {}

	public function setSelectedIndex(idx:Int) {
		this.currentItemIndex = idx;
	}

	public function getSelectedIndex():Int {
		return currentItemIndex;
	}

	public function getList():Array<UIElementListItem> {
		return items;
	}

	public function getSubElements(type:SubElementsType):Array<UIElement> {
		return switch type {
			case SETReceiveUpdates:
				[this.panel];
			case SETReceiveEvents:
				[];
		}
	}

	public function customAddToLayer(requestedLayer:Null<LayersEnum>, screen:UIScreen, updateMode:Bool) {
		if (requestedLayer == null) {
			if (updateMode)
				throw 'customAddToLayer update mode had no layer';
			else
				return Postponed;
		}
		if (!updateMode && this.root.parent == null)
			screen.addObjectToLayer(this.root, requestedLayer);
		panelScreen = screen;
		panelLayer = requestedLayer;
		var higherLayer = screen.getHigherLayer(requestedLayer);
		screen.addObjectToLayer(this.panel.getObject(), higherLayer);
		return Added;
	}
}
