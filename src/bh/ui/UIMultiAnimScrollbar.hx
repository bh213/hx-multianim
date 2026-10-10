package bh.ui;

import bh.base.CursorManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.NamedBuildResult;
import bh.ui.UIElement;
import h2d.Object;
import h2d.col.Bounds;
import h2d.col.Point;

enum ScrollbarDirection {
	Vertical;
	Horizontal;
}

/**
	A scrollbar that is dragged: a track, a thumb with `status` normal/hover/pressed and `disabled`,
	optional arrow buttons, clicked on the track to page, vertical or horizontal. Drawn by a
	programmable to this contract (`UIMultiAnimScrollbar.fits(builder, name)` says whether one does):

	- parameters: `status:[normal, hover, pressed]`, `panelHeight`, `scrollableHeight`,
	  `scrollPosition` (the lengths along the bar, whichever way it runs; the names of the old
	  position-only `#scrollbar`), and when declared `disabled:bool`, `direction:[vertical, horizontal]`
	- named elements: `#thumb` (what is dragged; its bounds are hit-tested, so the art decides its
	  size), optional `#track` (where the thumb travels; the whole bar when absent), optional `#up`
	  and `#down` (arrow regions: a click steps by `arrowStep`, from the root setting of that name
	  or 20)
	- root settings: `scrollSpeed` (for a list's keys), `arrowStep`

	The thumb's place is the art's own (`$scrollPosition * …` in the file); a drag reads the
	thumb's and the track's bounds on screen, so any art, any scale, works: a pixel of drag moves
	the content by `(scrollable - panel) / (track - thumb)` pixels. `UIMultiAnimScrollableList`
	and so a dropdown's panel use one of these when their scrollbar programmable fits the contract,
	and the position-only one otherwise.
**/
class UIMultiAnimScrollbar implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementNumberValue
		implements UIElementCursor {
	public final result:BuilderResult;
	public final direction:ScrollbarDirection;

	var root:h2d.Object;
	var status(default, set):StandardUIElementStates = SUINormal;

	public var disabled(default, set):Bool = false;
	public var panelLength(default, null):Int;
	public var scrollableLength(default, null):Int;
	/** Where the content is scrolled to, 0 … `scrollableLength - panelLength`. Setting it moves the
	 *  thumb and tells nobody; a drag, a page or an arrow step also calls `onChange`. */
	public var position(default, set):Int;
	/** What an arrow click scrolls by, in content pixels (`settings { arrowStep:int => 20 }`). */
	public var arrowStep:Int = 20;
	public var isDragging(default, null):Bool = false;

	var dragOffset:Float = 0;
	var hoverThumb:Bool = false;

	/** Called with the new position after a drag, a page or an arrow step (not after `position = `). */
	public dynamic function onChange(position:Int):Void {}

	function new(result:BuilderResult, panelLength:Int, scrollableLength:Int, position:Int, direction:ScrollbarDirection) {
		this.result = result;
		this.root = new h2d.Object();
		this.direction = direction;
		this.panelLength = panelLength;
		this.scrollableLength = scrollableLength;
		if (!result.hasParameter("status") || result.names.get("thumb") == null)
			throw 'a dragged scrollbar needs a programmable with a status parameter and a #thumb element';
		root.addChild(result.object);
		this.arrowStep = Std.int(result.rootSettings.getFloatOrDefault("arrowStep", 20));
		this.position = position;
	}

	/** The parameters the widget passes, for a build the caller makes itself (a list's). */
	public static function buildParams(builder:MultiAnimBuilder, name:String, panelLength:Int, scrollableLength:Int, position:Int,
			direction:ScrollbarDirection, ?extraParams:Map<String, Dynamic>):Map<String, Dynamic> {
		final defs = builder.getParameterDefinitions(name);
		final params:Map<String, Dynamic> = [
			"panelHeight" => '$panelLength',
			"scrollableHeight" => '$scrollableLength',
			"scrollPosition" => '$position',
		];
		if (defs.exists("status"))
			params.set("status", "normal");
		if (defs.exists("disabled"))
			params.set("disabled", "false");
		if (defs.exists("direction"))
			params.set("direction", direction == Vertical ? "vertical" : "horizontal");
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);
		return params;
	}

	/** Whether the programmable is drawn to this contract (a `status` parameter and a `#thumb`),
	 *  as against the position-only `#scrollbar`. */
	public static function fits(builder:MultiAnimBuilder, name:String):Bool {
		if (!builder.hasNode(name))
			return false;
		if (!builder.getParameterDefinitions(name).exists("status"))
			return false;
		return builder.hasNamedElement(name, "thumb");
	}

	public static function create(builder:MultiAnimBuilder, name:String, panelLength:Int, scrollableLength:Int, position:Int = 0,
			direction:ScrollbarDirection = Vertical, ?extraParams:Map<String, Dynamic>):UIMultiAnimScrollbar {
		final params = buildParams(builder, name, panelLength, scrollableLength, position, direction, extraParams);
		final result = builder.buildWithParameters(name, params, null, null, true);
		if (result == null)
			throw 'could not build #${name}';
		return new UIMultiAnimScrollbar(result, panelLength, scrollableLength, position, direction);
	}

	/** Wraps a result the caller built incrementally with `buildParams`. */
	public static function fromResult(result:BuilderResult, panelLength:Int, scrollableLength:Int, position:Int = 0,
			direction:ScrollbarDirection = Vertical):UIMultiAnimScrollbar {
		return new UIMultiAnimScrollbar(result, panelLength, scrollableLength, position, direction);
	}

	public function clear() {
		isDragging = false;
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return root.getBounds().contains(pos);
	}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			if (value) {
				isDragging = false;
				hoverThumb = false;
				status = SUINormal;
			}
			if (result.hasParameter("disabled"))
				result.setParameter("disabled", '$value');
		}
		return value;
	}

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			result.setParameter("status", standardUIElementStatusToString(value));
		}
		return value;
	}

	public function maxPosition():Int {
		return scrollableLength > panelLength ? scrollableLength - panelLength : 0;
	}

	function set_position(value:Int):Int {
		final clamped = Std.int(hxd.Math.clamp(value, 0, maxPosition()));
		this.position = clamped;
		result.setParameter("scrollPosition", clamped);
		return clamped;
	}

	/** New lengths (a list's items changed); the position is kept where it still fits. */
	public function setRange(panelLength:Int, scrollableLength:Int):Void {
		this.panelLength = panelLength;
		this.scrollableLength = scrollableLength;
		result.beginUpdate();
		result.setParameter("panelHeight", panelLength);
		result.setParameter("scrollableHeight", scrollableLength);
		final clamped = Std.int(hxd.Math.clamp(position, 0, maxPosition()));
		this.position = clamped;
		result.setParameter("scrollPosition", clamped);
		result.endUpdate();
	}

	public function setIntValue(v:Int):Void {
		position = v;
	}

	public function getIntValue():Int {
		return position;
	}

	// ---- Geometry, in scene space (bounds of what is drawn, so any art and scale work) ----

	/** The named element that is drawn: a design draws the thumb in one `@(status=>…)` arm at a
	 *  time, and an arm that does not match is out of the scene graph. */
	inline function named(name:String):Null<h2d.Object> {
		return result.getNamedDrawn(name);
	}

	function thumbBounds():Null<Bounds> {
		final thumb = named("thumb");
		return thumb == null ? null : thumb.getBounds();
	}

	function trackBounds():Bounds {
		final track = named("track");
		return track != null ? track.getBounds() : result.object.getBounds();
	}

	inline function along(b:Bounds):Float
		return direction == Vertical ? b.yMin : b.xMin;

	inline function length(b:Bounds):Float
		return direction == Vertical ? b.height : b.width;

	inline function coord(p:Point):Float
		return direction == Vertical ? p.y : p.x;

	function positionForThumbStart(thumbStart:Float):Int {
		final track = trackBounds();
		final thumb = thumbBounds();
		if (thumb == null)
			return position;
		final travel = length(track) - length(thumb);
		if (travel <= 0)
			return 0;
		final ratio = hxd.Math.clamp((thumbStart - along(track)) / travel, 0, 1);
		return Math.round(ratio * maxPosition());
	}

	function change(newPosition:Int, ?wrapper:UIElementEventWrapper):Void {
		final before = position;
		position = newPosition;
		if (position != before) {
			onChange(position);
			if (wrapper != null)
				wrapper.control.pushEvent(UIChangeValue(position), this);
		}
	}

	/** Scrolls by `delta` content pixels (a wheel, a key) and calls `onChange` when it moved. */
	public function scrollBy(delta:Int):Void {
		change(position + delta);
	}

	public function onEvent(wrapper:UIElementEventWrapper):Void {
		if (disabled)
			return;
		final pos = wrapper.eventPos;
		final thumb = thumbBounds();
		final overThumb = thumb != null && thumb.contains(pos);
		final capturing = wrapper.control.captureEvents.isCapturing();
		switch wrapper.event {
			case OnPush(button):
				if (button != 0)
					return;
				if (overThumb) {
					isDragging = true;
					dragOffset = coord(pos) - along(thumb);
					status = SUIPressed;
					if (!capturing)
						wrapper.control.captureEvents.startCapture();
				} else {
					final up = named("up");
					final down = named("down");
					if (up != null && up.getBounds().contains(pos))
						change(position - arrowStep, wrapper);
					else if (down != null && down.getBounds().contains(pos))
						change(position + arrowStep, wrapper);
					else if (thumb != null && trackBounds().contains(pos))
						change(coord(pos) < along(thumb) ? position - panelLength : position + panelLength, wrapper);
				}
			case OnRelease(_) | OnReleaseOutside(_) | OnPushOutside(_):
				if (isDragging) {
					isDragging = false;
					if (capturing)
						wrapper.control.captureEvents.stopCapture();
				}
				hoverThumb = overThumb && wrapper.event.match(OnRelease(_));
				status = hoverThumb ? SUIHover : SUINormal;
			case OnMouseMove:
				if (isDragging) {
					change(positionForThumbStart(coord(pos) - dragOffset), wrapper);
				} else if (overThumb != hoverThumb) {
					hoverThumb = overThumb;
					status = hoverThumb ? SUIHover : SUINormal;
				}
			case OnEnter:
				if (!isDragging && overThumb) {
					hoverThumb = true;
					status = SUIHover;
				}
			case OnLeave:
				if (!isDragging) {
					hoverThumb = false;
					status = SUINormal;
				}
			case OnWheel(dir):
				change(position + Std.int(dir * arrowStep), wrapper);
			case OnKey(_, _):
		}
	}
}
