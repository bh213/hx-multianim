package bh.ui.screens;

import bh.ui.screens.UIScreen;

@:nullSafety
abstract class UIScrollableScreen extends UIScreenBase {
	var scrollY:Float = 0;
	var targetScrollY:Float = 0;
	var scrollSpeed:Float = 30;
	var scrollSmoothing:Float = 12;
	var scrollContentHeight:Float = 0;
	var scrollAutoMeasure:Bool = true;
	final scrollContent:h2d.Layers;

	public function new(screenManager:ScreenManager, ?scrollConfig:bh.ui.UIScrollHelper.ScrollConfig, ?layers:Map<LayersEnum, Int>) {
		super(screenManager, layers);
		scrollContent = new h2d.Layers(root);
		if (scrollConfig != null) {
			if (scrollConfig.scrollSpeed != null)
				scrollSpeed = scrollConfig.scrollSpeed;
			if (scrollConfig.smoothing != null)
				scrollSmoothing = scrollConfig.smoothing;
		}
	}

	public function setContentHeight(h:Float):Void {
		scrollContentHeight = h;
		scrollAutoMeasure = false;
		clampScroll();
	}

	override public function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum):h2d.Object {
		if (contentTarget != null && !inElementRouting) {
			contentTarget.registerObject(object);
		}
		final resolvedLayer = layer ?? DefaultLayer;
		final layerIdxN = layers.get(resolvedLayer);
		if (layerIdxN == null)
			throw 'layer not found $resolvedLayer';
		final layerIdx:Int = layerIdxN;
		if (contentTarget != null && contentTarget.handlesSceneGraph()) {
			contentTarget.addToLayer(object, layerIdx);
		} else {
			scrollContent.add(object, layerIdx);
		}
		return object;
	}

	override public function onMouseWheel(pos:h2d.col.Point, delta:Float):Bool {
		final viewH = screenManager.sceneHeight;
		if (scrollContentHeight <= viewH)
			return true;
		targetScrollY = hxd.Math.clamp(targetScrollY + delta * scrollSpeed, 0, scrollContentHeight - viewH);
		if (scrollSmoothing <= 0) {
			scrollY = targetScrollY;
			scrollContent.y = -scrollY;
		}
		return false;
	}

	override public function update(dt:Float):Void {
		super.update(dt);
		if (scrollAutoMeasure)
			measureContentHeight();
		if (scrollSmoothing > 0 && scrollY != targetScrollY) {
			scrollY += (targetScrollY - scrollY) * hxd.Math.min(1.0, dt * scrollSmoothing);
			if (hxd.Math.abs(scrollY - targetScrollY) < 0.5)
				scrollY = targetScrollY;
			scrollContent.y = -scrollY;
		}
	}

	function measureContentHeight():Void {
		final bounds = scrollContent.getBounds(scrollContent);
		final measured = bounds.yMax;
		if (measured != scrollContentHeight) {
			scrollContentHeight = measured;
			clampScroll();
		}
	}

	function clampScroll():Void {
		final viewH = screenManager.sceneHeight;
		final max = hxd.Math.max(0, scrollContentHeight - viewH);
		targetScrollY = hxd.Math.clamp(targetScrollY, 0, max);
		scrollY = hxd.Math.clamp(scrollY, 0, max);
		scrollContent.y = -scrollY;
	}

	override public function onClear():Void {
		// clear() calls root.removeChildren() which detaches scrollContent.
		// Re-attach it so the next load() can add content into it.
		root.addChild(scrollContent);
		scrollY = 0;
		targetScrollY = 0;
		scrollContentHeight = 0;
		scrollAutoMeasure = true;
	}
}
