package bh.ui;

@:structInit
@:nullSafety
typedef ScrollConfig = {
	var ?scrollSpeed:Float;
	var ?smoothing:Float;
}

@:nullSafety
class UIScrollHelper {
	final mask:h2d.Mask;
	final content:h2d.Object;
	final viewWidth:Int;
	final viewHeight:Int;
	final smoothingFactor:Float;
	final scrollSpeed:Float;

	var scrollY:Float = 0;
	var targetScrollY:Float = 0;
	var contentHeight:Float = 0;
	var autoMeasure:Bool = true;

	public function new(width:Int, height:Int, ?config:ScrollConfig) {
		this.viewWidth = width;
		this.viewHeight = height;
		this.scrollSpeed = config != null && config.scrollSpeed != null ? config.scrollSpeed : 30.0;
		this.smoothingFactor = config != null && config.smoothing != null ? config.smoothing : 12.0;
		mask = new h2d.Mask(width, height);
		content = new h2d.Object(mask);
	}

	public function getContentRoot():h2d.Object {
		return content;
	}

	public function getObject():h2d.Object {
		return mask;
	}

	public function setContentHeight(h:Float):Void {
		contentHeight = h;
		autoMeasure = false;
		clampScroll();
	}

	public function onMouseWheel(delta:Float):Bool {
		if (contentHeight <= viewHeight)
			return true;
		targetScrollY = clampValue(targetScrollY + delta * scrollSpeed);
		if (smoothingFactor <= 0) {
			scrollY = targetScrollY;
			mask.scrollY = scrollY;
		}
		return false;
	}

	public function update(dt:Float):Void {
		if (autoMeasure)
			measureContentHeight();
		if (smoothingFactor > 0 && scrollY != targetScrollY) {
			scrollY += (targetScrollY - scrollY) * hxd.Math.min(1.0, dt * smoothingFactor);
			if (hxd.Math.abs(scrollY - targetScrollY) < 0.5)
				scrollY = targetScrollY;
			mask.scrollY = scrollY;
		}
	}

	public function canScroll():Bool {
		return contentHeight > viewHeight;
	}

	public function getScrollY():Float {
		return scrollY;
	}

	public function getMaxScrollY():Float {
		return hxd.Math.max(0, contentHeight - viewHeight);
	}

	public function getScrollRate():Float {
		final max = getMaxScrollY();
		return if (max <= 0) 0.0 else scrollY / max;
	}

	public function scrollTo(y:Float):Void {
		targetScrollY = clampValue(y);
		scrollY = targetScrollY;
		mask.scrollY = scrollY;
	}

	public function scrollToRate(rate:Float):Void {
		scrollTo(rate * getMaxScrollY());
	}

	public function reset():Void {
		scrollY = 0;
		targetScrollY = 0;
		mask.scrollY = 0;
	}

	function clampScroll():Void {
		final max = getMaxScrollY();
		targetScrollY = hxd.Math.clamp(targetScrollY, 0, max);
		scrollY = hxd.Math.clamp(scrollY, 0, max);
		mask.scrollY = scrollY;
	}

	inline function clampValue(v:Float):Float {
		return hxd.Math.clamp(v, 0, getMaxScrollY());
	}

	function measureContentHeight():Void {
		final bounds = content.getBounds();
		final measured = bounds.yMax;
		if (measured != contentHeight) {
			contentHeight = measured;
			clampScroll();
		}
	}
}
