package bh.ui;

import h2d.col.Point;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.base.CursorManager;
import bh.ui.UIElement;

@:nullSafety
class UIInteractiveWrapper implements UIElement implements StandardUIElementEvents implements UIElementIdentifiable implements UIElementDisablable implements UIElementCursor {
	public static inline final EVENT_HOVER = 1;
	public static inline final EVENT_CLICK = 2;
	public static inline final EVENT_PUSH = 4;
	public static inline final EVENT_ALL = 7;

	static final VALID_CURSOR_SUFFIXES = ["hover", "disabled"];

	public final interactive:MAObject;
	public final prefix:Null<String>;
	public final id:String;
	public final metadata:BuilderResolvedSettings;
	public final eventFlags:Int;
	public var disabled(default, set):Bool = false;
	public var hovered(default, null):Bool = false;

	// Per-state cursors resolved from metadata at construction time
	final cursorDefault:hxd.Cursor;
	final cursorHover:hxd.Cursor;
	final cursorDisabled:hxd.Cursor;

	public function new(interactive:MAObject, prefix:Null<String>) {
		this.interactive = interactive;
		this.prefix = prefix;
		final extracted = extractInteractiveData(interactive, prefix);
		this.id = extracted.id;
		this.metadata = extracted.metadata;
		this.eventFlags = extracted.eventFlags;
		// Resolve cursors from metadata
		final baseCursor = resolveCursorName(metadata.getStringOrDefault("cursor", ""), CursorManager.getDefaultInteractiveCursor());
		this.cursorDefault = baseCursor;
		this.cursorHover = resolveCursorName(metadata.getStringOrDefault("cursor.hover", ""), baseCursor);
		this.cursorDisabled = resolveCursorName(metadata.getStringOrDefault("cursor.disabled", ""), CursorManager.getDefaultCursor());
		validateCursorKeys(metadata);
	}

	static function resolveCursorName(name:String, fallback:hxd.Cursor):hxd.Cursor {
		if (name == "")
			return fallback;
		final resolved = CursorManager.getCursor(name);
		if (resolved == null)
			throw 'unknown cursor: "$name" — register it via CursorManager.registerCursor()';
		return resolved;
	}

	static function validateCursorKeys(metadata:BuilderResolvedSettings):Void {
		@:nullSafety(Off) if (!metadata.hasSettings())
			return;
		@:nullSafety(Off) for (key in metadata.keys()) {
			if (StringTools.startsWith(key, "cursor.")) {
				final suffix = key.substr(7);
				if (VALID_CURSOR_SUFFIXES.indexOf(suffix) == -1)
					throw 'unknown cursor state: "$key" — valid states: cursor.hover, cursor.disabled';
			}
		}
	}

	static function extractInteractiveData(obj:MAObject, prefix:Null<String>):{id:String, metadata:BuilderResolvedSettings, eventFlags:Int} {
		switch obj.multiAnimType {
			case MAInteractive(_, _, identifier, meta):
				final brs = new BuilderResolvedSettings(meta);
				final flags = brs.getIntOrDefault("events", EVENT_ALL);
				return {id: prefix != null ? '$prefix.$identifier' : identifier, metadata: brs, eventFlags: flags};
			default:
				throw "UIInteractiveWrapper requires MAInteractive";
		}
	}

	function set_disabled(v:Bool):Bool {
		disabled = v;
		return v;
	}

	public function getObject():h2d.Object {
		return interactive;
	}

	public function containsPoint(pos:Point):Bool {
		if (disabled) return false;
		switch interactive.multiAnimType {
			case MAInteractive(width, height, _, _):
				var local = interactive.globalToLocal(new Point(pos.x, pos.y));
				return local.x >= 0 && local.x <= width && local.y >= 0 && local.y <= height;
			default:
				return false;
		}
	}

	public function clear() {}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return cursorDisabled;
		if (hovered)
			return cursorHover;
		return cursorDefault;
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (disabled) return;
		switch wrapper.event {
			case OnPush(_):
				if (eventFlags & EVENT_PUSH != 0) {
					wrapper.control.trackOutsideClick(true);
					wrapper.control.pushEvent(UIInteractiveEvent(UIPush, this.id, this.metadata), this);
				}
			case OnRelease(_):
				if (eventFlags & EVENT_CLICK != 0)
					wrapper.control.pushEvent(UIInteractiveEvent(UIClick, this.id, this.metadata), this);
			case OnReleaseOutside(_):
				if (eventFlags & EVENT_PUSH != 0)
					wrapper.control.pushEvent(UIInteractiveEvent(UIClickOutside, this.id, this.metadata), this);
			case OnEnter:
				if (eventFlags & EVENT_HOVER != 0) {
					hovered = true;
					wrapper.control.pushEvent(UIInteractiveEvent(UIEntering(), this.id, this.metadata), this);
				}
			case OnLeave:
				if (eventFlags & EVENT_HOVER != 0) {
					hovered = false;
					wrapper.control.pushEvent(UIInteractiveEvent(UILeaving, this.id, this.metadata), this);
				}
			default:
		}
	}
}
