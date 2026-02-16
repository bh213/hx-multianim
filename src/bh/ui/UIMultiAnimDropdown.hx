package bh.ui;

import bh.ui.screens.UIScreen;
import bh.base.PositionLinkObject;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import hxd.Rand;
import bh.multianim.MultiAnimMultiResult;
import bh.base.MAObject;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;

private enum AnimState {
	Opening;
	Closing;
	Open;
	Closed;
}

@:nullSafety
class UIStandardMultiAnimDropdown implements UIElement implements UIElementDisablable implements UIElementUpdatable implements StandardUIElementEvents
		implements UIElementSyncRedraw implements UIElementListValue implements UIElementSubElements implements UIElementCustomAddToLayer {
	final mainPartImages:MultiAnimMultiResult;
	var status(default, set):StandardUIElementStates = SUINormal;
	var root:h2d.Object;
	var currentMainPart:Null<h2d.Object> = null;
	final builder:UIElementBuilder;
	var panel:UIMultiAnimScrollableList;
	var panelObject:h2d.Object;
	var panelStatus:AnimState = Closed;
	var timer:Float = 0;
	var timerTotal:Float = 0;

	public var requestRedraw = true;

	var transitionTimer = 1.0;
	public var transitionTimerOverride:Null<Float> = null;

	public var disabled(default, set):Bool = false;
	public var items:Array<UIElementListItem> = [];
	@:isVar public var currentItemIndex(default, set):Int = 0;
	public var autoOpen:Bool = true;
	public var autoCloseOnLeave:Bool = true;
	public var closeOnOutsideClick:Bool = true;

	@:nullSafety(Off)
	function new(builder:UIElementBuilder, builtPanel, items, initialIndex = 0) {
		this.builder = builder;

		this.root = new h2d.Object();
		this.items = items;

		this.mainPartImages = this.builder.builder.buildWithComboParameters(builder.name, [], ["status", "panel"], {callback: @:nullSafety(Off) callback});

		if (this.mainPartImages == null)
			throw 'could not build combo #${builder.name}';

		this.panelStatus = Closed;
		this.panel = builtPanel;
		this.panelObject = this.panel.getObject();
		this.panelObject.visible = false;
		this.panel.onItemChanged = onPanelItemChanged;
		@:nullSafety(Off) this.currentItemIndex = initialIndex;
	}

	public function clear() {
		this.items = [];
		this.currentMainPart = null;
	}

	function set_currentItemIndex(value:Int):Int {
		if (value < 0 || value >= items.length)
			throw 'currentItemIndex ${value} is out of bounds [0..${items.length}].';
		if (this.currentItemIndex != value) {
			this.currentItemIndex = value;
			requestRedraw = true;
			mainPartImages.updateAllText("selectedName", items[this.currentItemIndex].name);
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

	function isOpen() {
		return switch panelStatus {
			case Opening | Open: true;
			case Closing | Closed: false;
		}
	}

	public static function createWithPrebuiltPanel(builder:UIElementBuilder, panel:UIMultiAnimScrollableList, items, initialIndex = 0) {
		return new UIStandardMultiAnimDropdown(builder, panel, items, initialIndex);
	}

	public static function create(builder:UIElementBuilder, panelBuilder:UIElementBuilder, panelListItemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, initialIndex = 0, panelWidth = 120, panelHeight = 300) {
		var panel = buildPanel(panelBuilder, panelListItemBuilder, scrollbarBuilder, scrollbarInPanelName, items, initialIndex, panelWidth, panelHeight);
		return new UIStandardMultiAnimDropdown(builder, panel, items, initialIndex);
	}

	/**
	 * Convenience factory that takes a single MultiAnimBuilder and component names.
	 * Uses standard component names by default (dropdown, list-panel, list-item-120, scrollbar).
	 */
	public static function createWithSingleBuilder(builder:MultiAnimBuilder, items:Array<UIElementListItem>, initialIndex = 0, dropdownName = "dropdown", panelName = "list-panel", itemName = "list-item-120", scrollbarName = "scrollbar", scrollbarInPanelName = "scrollbar", panelWidth = 120, panelHeight = 300) {
		return create(builder.createElementBuilder(dropdownName), builder.createElementBuilder(panelName), builder.createElementBuilder(itemName), builder.createElementBuilder(scrollbarName), scrollbarInPanelName, items, initialIndex, panelWidth, panelHeight);
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

	static function buildPanel(builder:UIElementBuilder, panelListItemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, initialIndex, panelWidth = 120, panelHeight = 300) {
		return UIMultiAnimScrollableList.create(builder, panelListItemBuilder, scrollbarBuilder, scrollbarInPanelName, panelWidth, panelHeight, items, 0, initialIndex);
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
			// var obj = findInteractiveIndex(eventPos);
			// if (obj != null) {
			//     final newIndex = parseInteractiveId(obj);
			//     if (this.currentItemIndex != newIndex) {
			//         this.currentItemIndex = newIndex;
			//         triggerItemChanged(newIndex, control);
			//     }
			//     startClose();
			// }
			// else if (!isOpen()) startOpen() else startClose(); // toggle

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
				// final obj = findInteractiveIndex(eventPos);

				// if (obj != null) {
				//     final newIndex = parseInteractiveId(obj);
				//     if (newIndex != this.hoverIndex) {
				//         this.hoverIndex = newIndex;
				//         buildPanel(newIndex);
				//     }
				// }
		}
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (currentMainPart != null)
			currentMainPart.remove();

		var pStatus = switch this.panelStatus {
			case Opening: "open";
			case Closing: "closed";
			case Open: "open";
			case Closed: "closed";
		}
		// trace('${standardUIElementStatusToString(this.status)} ${pStatus}');
		final currentResult = mainPartImages.findResultByCombo(standardUIElementStatusToString(this.status), pStatus);
		var updatable = currentResult.getUpdatable("panelPoint");

		transitionTimer = transitionTimerOverride ?? currentResult.rootSettings.getFloatOrDefault("transitionTimer", 1.0);
		currentMainPart = currentResult.object;
		root.addChild(currentMainPart);
		if (panelObject != null)
			updatable.setObject(new PositionLinkObject(panelObject)); // TODO: Set modal layer
	}

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			this.requestRedraw = true;
		}
		return value;
	}

	function startOpen() {
		if (this.panelObject == null)
			return;
		panel.currentHoverIndex = -1;
		panel.currentItemIndex = this.currentItemIndex;
		panel.currentPressedIndex = -1;
		// panel.

		this.panelObject.visible = true;
		this.panelObject.alpha = 0;
		this.panelStatus = Opening;
		this.timer = transitionTimer;
		this.timerTotal = this.timer;
	}

	function startClose() {
		if (this.panelObject == null)
			return;
		this.panelObject.alpha = 1.0;
		this.panelStatus = Closing;
		this.timer = transitionTimer;
		this.timerTotal = this.timer;
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
		if (!updateMode)
			screen.addObjectToLayer(this.root, requestedLayer);
		var higherLayer = screen.getHigherLayer(requestedLayer);
		screen.addObjectToLayer(this.panel.getObject(), higherLayer);
		return Added;
	}
}
