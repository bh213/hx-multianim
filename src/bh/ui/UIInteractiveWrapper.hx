package bh.ui;

import h2d.col.Point;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.base.CursorManager;
import bh.ui.UIElement;

@:nullSafety
class UIInteractiveWrapper implements UIElement implements StandardUIElementEvents implements UIElementIdentifiable implements UIElementDisablable implements UIElementCursor implements UIElementPriority {
	public static inline final EVENT_HOVER = 1;
	public static inline final EVENT_CLICK = 2;
	public static inline final EVENT_PUSH = 4;
	public static inline final EVENT_ALL = 7;

	static final VALID_CURSOR_SUFFIXES = ["hover", "disabled"];

	// Shared scratch for containsPoint: globalToLocal mutates its argument, but callers
	// (UICardHandTargeting, UIDefaultController.getEventElements) iterate multiple
	// wrappers with the same caller-owned Point, so we can't mutate pos directly.
	// Hit-testing is single-threaded — one static instance is enough.
	static var _scratchPt:Null<Point> = null;

	/** The wrapped object. A rebuild of the source can replace it (see `rebind`). */
	public var interactive(default, null):MAObject;
	public final prefix:Null<String>;
	public final id:String;
	public var metadata(default, null):BuilderResolvedSettings;
	public var eventFlags(default, null):Int;
	public var eventPriority:Int;
	public var disabled(default, set):Bool = false;
	public var hovered(default, null):Bool = false;
	/** The `BuilderResult` or codegen instance the interactive came from, when registered through
	 *  `UIScreenBase.addInteractives`; null for a wrapper built directly. */
	public final source:Null<bh.ui.UIInteractiveSource>;

	// Per-state cursors resolved from metadata
	var cursorDefault:hxd.Cursor;
	var cursorHover:hxd.Cursor;
	var cursorDisabled:hxd.Cursor;

	public function new(interactive:MAObject, prefix:Null<String>, ?source:bh.ui.UIInteractiveSource) {
		this.interactive = interactive;
		this.prefix = prefix;
		this.source = source;
		final extracted = extractInteractiveData(interactive, prefix);
		this.id = extracted.id;
		this.metadata = extracted.metadata;
		this.eventFlags = extracted.eventFlags;
		this.eventPriority = metadata.getIntOrDefault("eventPriority", 0);
		// Resolve cursors from metadata
		final baseCursor = resolveCursorName(metadata.getStringOrDefault("cursor", ""), CursorManager.getDefaultInteractiveCursor());
		this.cursorDefault = baseCursor;
		this.cursorHover = resolveCursorName(metadata.getStringOrDefault("cursor.hover", ""), baseCursor);
		this.cursorDisabled = resolveCursorName(metadata.getStringOrDefault("cursor.disabled", ""), CursorManager.getDefaultCursor());
		validateCursorKeys(metadata);
	}

	/** Point this wrapper at the object a rebuild made for the same interactive id (a `@switch` arm
	 *  or repeat rebuild recreates the object). The wrapper stays the element the screen and its
	 *  controller know, so hover, `disabled` and a priority set in code carry over; metadata,
	 *  event flags and cursors are read from the new object. */
	@:allow(bh.ui.screens.UIScreenBase)
	function rebind(obj:MAObject):Void {
		final extracted = extractInteractiveData(obj, prefix);
		if (extracted.id != id)
			throw 'UIInteractiveWrapper.rebind: "${extracted.id}" is not "$id"';
		final oldMetadataPriority = metadata.getIntOrDefault("eventPriority", 0);
		interactive = obj;
		metadata = extracted.metadata;
		eventFlags = extracted.eventFlags;
		final newMetadataPriority = metadata.getIntOrDefault("eventPriority", 0);
		if (newMetadataPriority != oldMetadataPriority)
			eventPriority = newMetadataPriority;
		final baseCursor = resolveCursorName(metadata.getStringOrDefault("cursor", ""), CursorManager.getDefaultInteractiveCursor());
		cursorDefault = baseCursor;
		cursorHover = resolveCursorName(metadata.getStringOrDefault("cursor.hover", ""), baseCursor);
		cursorDisabled = resolveCursorName(metadata.getStringOrDefault("cursor.disabled", ""), CursorManager.getDefaultCursor());
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
		if (!metadata.hasSettings())
			return;
		for (key in metadata.keys()) {
			if (StringTools.startsWith(key, "cursor.")) {
				final suffix = key.substr(7);
				if (VALID_CURSOR_SUFFIXES.indexOf(suffix) == -1)
					throw 'unknown cursor state: "$key" — valid states: cursor.hover, cursor.disabled';
			}
		}
	}

	/** The id a wrapper for `obj` gets under `prefix`: `'<prefix>.<identifier>'`, or the identifier alone. */
	public static function interactiveId(obj:MAObject, prefix:Null<String>):String {
		return switch obj.multiAnimType {
			case MAInteractive(_, _, identifier, _): prefix != null ? '$prefix.$identifier' : identifier;
			default: throw "UIInteractiveWrapper requires MAInteractive";
		};
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
				if (_scratchPt == null) _scratchPt = new Point();
				_scratchPt.set(pos.x, pos.y);
				var local = interactive.globalToLocal(_scratchPt);
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
