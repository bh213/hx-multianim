package bh.ui;

import bh.base.CursorManager;
import bh.base.FontManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.NamedBuildResult;
import bh.ui.UIElement;
import h2d.Object;
import h2d.col.Point;

enum TextInputFilter {
	FNumericOnly;
	FAlphanumeric;
	FCustom(fn:String->String);
}

typedef TextInputConfig = {
	var font:String;
	var ?fontColor:Int;
	var ?cursorColor:Int;
	var ?selectionColor:Int;
	var ?text:String;
	var ?placeholder:String;
	var ?maxLength:Int;
	var ?multiline:Bool;
	var ?readOnly:Bool;
	var ?inputWidth:Int;
	var ?extraParams:Null<Map<String, Dynamic>>;
}

class UIMultiAnimTextInput implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementText
		implements UIElementCursor implements UIElementUpdatable {
	final result:BuilderResult;
	final textInput:h2d.TextInput;

	var focused:Bool = false;
	var lastPlaceholderState:Bool = true;
	var controllable:Null<Controllable> = null;
	var enterPending:Bool = false;

	public var disabled(default, set):Bool = false;
	public var placeholder:String;
	public var maxLength:Int;
	public var filter:Null<TextInputFilter> = null;
	public var tabGroup:Null<UITabGroup> = null;

	public dynamic function onChange() {}

	public dynamic function onSubmit() {}

	public dynamic function onFocusChange(focused:Bool) {}

	public static function create(builder:MultiAnimBuilder, name:String, config:TextInputConfig) {
		return new UIMultiAnimTextInput(builder, name, config);
	}

	function new(builder:MultiAnimBuilder, name:String, config:TextInputConfig) {
		var params:Map<String, Dynamic> = ["status" => "normal", "placeholder" => "true"];

		if (config.placeholder != null && config.placeholder != "")
			params.set("placeholderText", config.placeholder);

		if (config.extraParams != null)
			for (key => value in config.extraParams)
				params.set(key, value);

		this.result = builder.buildWithParameters(name, params, null, null, true);

		final font = FontManager.getFontByName(config.font);
		textInput = new h2d.TextInput(font);
		textInput.textColor = config.fontColor ?? 0xFFFFFF;

		final inputWidth = config.inputWidth ?? 0;
		if (inputWidth > 0)
			textInput.inputWidth = inputWidth;

		textInput.cursorTile = h2d.Tile.fromColor(config.cursorColor ?? 0xFFFFFF, 1, Std.int(font.lineHeight));
		textInput.selectionTile = h2d.Tile.fromColor(config.selectionColor ?? 0x3399FF, 0, Std.int(font.lineHeight));

		if (config.text != null && config.text != "")
			textInput.text = config.text;

		this.placeholder = config.placeholder ?? "";
		this.maxLength = config.maxLength ?? 0;
		textInput.multiline = config.multiline ?? false;
		textInput.canEdit = !(config.readOnly ?? false);
		textInput.insertTabs = null;

		final textAreaItem = result.getSingleItemByName("textArea");
		final pointObj = textAreaItem.getBuiltHeapsObject().toh2dObject();
		pointObj.addChild(textInput);

		wireCallbacks();
		syncPlaceholder();
	}

	function wireCallbacks() {
		textInput.onChange = function() {
			if (maxLength > 0 && textInput.text.length > maxLength) {
				var curPos = textInput.cursorIndex;
				textInput.text = textInput.text.substr(0, maxLength);
				if (curPos > maxLength)
					textInput.cursorIndex = maxLength;
			}

			if (filter != null)
				applyFilter();

			syncPlaceholder();
			onChange();
			pushScreenEvent(UITextChange(textInput.text));
		};

		textInput.onFocus = function(e:hxd.Event) {
			focused = true;
			result.setParameter("status", "focused");
			syncPlaceholder();
			onFocusChange(true);
			pushScreenEvent(UIFocusChange(true));
		};

		textInput.onFocusLost = function(e:hxd.Event) {
			focused = false;
			result.setParameter("status", "normal");
			syncPlaceholder();
			onFocusChange(false);
			pushScreenEvent(UIFocusChange(false));
			// enterPending handled in update() to defer past Heaps' event processing
		};

		textInput.onKeyDown = function(e:hxd.Event) {
			if (!textInput.multiline && (e.keyCode == hxd.Key.ENTER || e.keyCode == hxd.Key.NUMPAD_ENTER)) {
				onSubmit();
				pushScreenEvent(UITextSubmit(textInput.text));
				if (tabGroup != null && tabGroup.enterAdvances)
					enterPending = true;
			}
		};
	}

	function applyFilter() {
		if (filter == null)
			return;
		final original = textInput.text;
		final filtered = switch filter {
			case FNumericOnly: ~/[^0-9]/g.replace(original, "");
			case FAlphanumeric: ~/[^a-zA-Z0-9]/g.replace(original, "");
			case FCustom(fn): fn(original);
		};
		if (filtered != original) {
			var curPos = textInput.cursorIndex;
			var diff = original.length - filtered.length;
			textInput.text = filtered;
			textInput.cursorIndex = Std.int(Math.max(0, curPos - diff));
		}
	}

	function syncPlaceholder() {
		final shouldShow = textInput.text.length == 0 && !focused;
		if (shouldShow != lastPlaceholderState) {
			lastPlaceholderState = shouldShow;
			result.setParameter("placeholder", shouldShow ? "true" : "false");
		}
	}

	function pushScreenEvent(event:UIScreenEvent) {
		if (controllable != null)
			controllable.pushEvent(event, this);
	}

	// --- UIElement ---

	public function getObject():Object {
		return result.object;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	public function clear() {}

	// --- StandardUIElementEvents ---

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (controllable == null)
			controllable = wrapper.control;
		if (disabled)
			return;
		switch wrapper.event {
			case OnEnter:
				if (!focused)
					result.setParameter("status", "hover");
			case OnLeave:
				if (!focused)
					result.setParameter("status", "normal");
			case OnPush(_):
				if (!focused)
					textInput.focus();
			case OnRelease(_):
			case OnReleaseOutside(_):
			case OnPushOutside(_):
			case OnKey(_, _):
			case OnWheel(_):
			case OnMouseMove:
		}
	}

	// --- UIElementText ---

	public function setText(text:String) {
		textInput.text = text;
		syncPlaceholder();
	}

	public function getText():String {
		return textInput.text;
	}

	// --- UIElementDisablable ---

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			result.beginUpdate();
			result.setParameter("status", value ? "disabled" : "normal");
			result.setParameter("disabled", '${value}');
			result.endUpdate();
			textInput.canEdit = !value;
			if (value && focused)
				textInput.blur();
		}
		return value;
	}

	// --- UIElementCursor ---

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return hxd.Cursor.TextInput;
	}

	// --- UIElementUpdatable ---

	public function update(dt:Float) {
		if (enterPending) {
			enterPending = false;
			if (tabGroup != null)
				tabGroup.advanceFrom(this);
		}
		syncPlaceholder();
	}

	// --- Focus API ---

	public function focus() {
		if (!disabled)
			textInput.focus();
	}

	public function blur() {
		textInput.blur();
	}

	public function hasFocus():Bool {
		return textInput.hasFocus();
	}
}
