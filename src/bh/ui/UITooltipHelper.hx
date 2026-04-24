package bh.ui;

import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.ui.screens.UIScreen;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;

enum TooltipPosition {
	Above;
	Below;
	Left;
	Right;
}

@:structInit
@:nullSafety
typedef TooltipDefaults = {
	var ?delay:Float;
	var ?position:TooltipPosition;
	var ?offset:Int;
	var ?layer:LayersEnum;
	var ?fadeIn:Float;
	var ?fadeOut:Float;
}

@:nullSafety
class UITooltipHelper {
	final screen:UIComponentHost;
	final builder:MultiAnimBuilder;
	final defaultDelay:Float;
	final defaultPosition:TooltipPosition;
	final defaultOffset:Int;
	final layer:LayersEnum;
	final defaultFadeIn:Float;
	final defaultFadeOut:Float;
	var tweens:Null<TweenManager>;

	// Per-interactive overrides
	var delayOverrides:Map<String, Float> = [];
	var positionOverrides:Map<String, TooltipPosition> = [];
	var offsetOverrides:Map<String, Int> = [];

	// Current hover state
	var hoverInteractiveId:Null<String> = null;
	var hoverBuildName:Null<String> = null;
	var hoverParams:Null<Map<String, Dynamic>> = null;
	var hoverTimer:Float = 0;

	// Active tooltip
	var activeTooltipId:Null<String> = null;
	var activeResult:Null<BuilderResult> = null;
	var activeBuildName:Null<String> = null;
	var activeParams:Null<Map<String, Dynamic>> = null;

	// Fade state
	var fadeInTween:Null<Tween> = null;
	var fadingOutObj:Null<h2d.Object> = null;
	var fadeOutTween:Null<Tween> = null;

	public function new(screen:UIComponentHost, builder:MultiAnimBuilder, ?defaults:TooltipDefaults, ?tweens:TweenManager) {
		this.screen = screen;
		this.builder = builder;
		this.defaultDelay = defaults?.delay ?? 0.3;
		this.defaultPosition = defaults?.position ?? Above;
		this.defaultOffset = defaults?.offset ?? 4;
		this.layer = defaults?.layer ?? ModalLayer;
		this.defaultFadeIn = defaults?.fadeIn ?? 0.15;
		this.defaultFadeOut = defaults?.fadeOut ?? 0.1;
		this.tweens = tweens;
	}

	/** Start hover timer for an interactive. Call from UIInteractiveEvent(UIEntering, ...) handler. */
	public function startHover(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>):Void {
		// If already showing tooltip for this interactive with the same buildName, do nothing
		if (activeTooltipId == interactiveId && activeBuildName == buildName)
			return;

		// Hide any existing tooltip first
		hide();

		hoverInteractiveId = interactiveId;
		hoverBuildName = buildName;
		hoverParams = params;
		hoverTimer = 0;
	}

	/** Cancel hover timer or hide tooltip. Call from UIInteractiveEvent(UILeaving, ...) handler. */
	public function cancelHover(interactiveId:String):Void {
		if (hoverInteractiveId == interactiveId) {
			hoverInteractiveId = null;
			hoverBuildName = null;
			hoverParams = null;
			hoverTimer = 0;
		}
		if (activeTooltipId == interactiveId)
			hide();
	}

	/** Show tooltip immediately (bypasses delay). */
	public function show(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>):Void {
		hide();
		showTooltip(interactiveId, buildName, params);
	}

	/** Hide the currently active tooltip. */
	public function hide():Void {
		// Cancel any in-progress fade-in
		if (fadeInTween != null) {
			fadeInTween.cancel();
			fadeInTween = null;
		}

		// Cancel any in-progress fade-out of previous tooltip
		cancelFadeOut();

		if (activeResult != null) {
			final obj = activeResult.object;
			if (defaultFadeOut > 0 && tweens != null) {
				fadingOutObj = obj;
				fadeOutTween = tweens.tween(obj, defaultFadeOut, [Alpha(0.0)]);
				fadeOutTween.setOnComplete(() -> {
					obj.remove();
					fadingOutObj = null;
					fadeOutTween = null;
				});
			} else {
				obj.remove();
			}
			activeResult = null;
		}
		activeTooltipId = null;
		activeBuildName = null;
		activeParams = null;
		// Clear pending hover state so update() doesn't re-trigger the tooltip
		hoverInteractiveId = null;
		hoverBuildName = null;
		hoverParams = null;
		hoverTimer = 0;
	}

	/** Set custom delay for a specific interactive. */
	public function setDelay(interactiveId:String, delay:Float):Void {
		delayOverrides.set(interactiveId, delay);
	}

	/** Set custom position for a specific interactive. */
	public function setPosition(interactiveId:String, position:TooltipPosition):Void {
		positionOverrides.set(interactiveId, position);
	}

	/** Set custom offset for a specific interactive. */
	public function setOffset(interactiveId:String, offset:Int):Void {
		offsetOverrides.set(interactiveId, offset);
	}

	/** Call from screen's update(dt). Manages hover delay timer. */
	public function update(dt:Float):Void {
		if (hoverInteractiveId == null)
			return;

		final delay = delayOverrides.get(hoverInteractiveId) ?? defaultDelay;
		hoverTimer += dt;
		if (hoverTimer >= delay) {
			final id = hoverInteractiveId;
			final buildName = hoverBuildName;
			final params = hoverParams;
			// Clear hover state before showing (showTooltip may trigger events)
			hoverInteractiveId = null;
			hoverBuildName = null;
			hoverParams = null;
			hoverTimer = 0;
			if (id != null && buildName != null)
				showTooltip(id, buildName, params);
		}
	}

	/** Returns whether a tooltip is currently showing. */
	public function isActive():Bool {
		return activeTooltipId != null;
	}

	/** Returns the id of the interactive the tooltip is showing for. */
	public function getActiveId():Null<String> {
		return activeTooltipId;
	}

	/** Update parameters on the active tooltip (incremental update). Returns false if no tooltip is active. */
	public function updateParams(params:Map<String, Dynamic>):Bool {
		if (activeResult == null || activeTooltipId == null)
			return false;
		for (key => value in params)
			activeResult.setParameter(key, value);
		return true;
	}

	/** Rebuild the active tooltip with new parameters. Returns false if no tooltip is active. */
	public function rebuild(?params:Map<String, Dynamic>):Bool {
		if (activeTooltipId == null || activeBuildName == null)
			return false;
		final id = activeTooltipId;
		final buildName = activeBuildName;
		final buildParams = params ?? activeParams;
		hide();
		showTooltip(id, buildName, buildParams);
		return true;
	}

	function showTooltip(interactiveId:String, buildName:String, params:Null<Map<String, Dynamic>>):Void {
		// Cancel any in-progress fade-out of a previous tooltip
		cancelFadeOut();

		final wrapper = screen.getInteractive(interactiveId);
		if (wrapper == null)
			return;

		final result = builder.buildWithParameters(buildName, params ?? [], null, null, true);
		final position = positionOverrides.get(interactiveId) ?? defaultPosition;
		final offset = offsetOverrides.get(interactiveId) ?? defaultOffset;

		UIPositionHelper.position(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		// Apply fade-in
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			fadeInTween = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			fadeInTween.setOnComplete(() -> {
				fadeInTween = null;
			});
		}

		activeTooltipId = interactiveId;
		activeResult = result;
		activeBuildName = buildName;
		activeParams = params;
	}

	function cancelFadeOut():Void {
		if (fadeOutTween != null) {
			fadeOutTween.cancel();
			fadeOutTween = null;
		}
		if (fadingOutObj != null) {
			fadingOutObj.remove();
			fadingOutObj = null;
		}
	}

	/** Release all tween and scene resources. Call when the owning screen is torn down
	    (e.g. during hot reload or full rebuild) to prevent in-flight fade tween closures
	    from holding h2d.Object references past the screen's lifetime. */
	public function dispose():Void {
		if (fadeInTween != null) {
			fadeInTween.cancel();
			fadeInTween = null;
		}
		if (fadeOutTween != null) {
			fadeOutTween.cancel();
			fadeOutTween = null;
		}
		if (fadingOutObj != null) {
			fadingOutObj.remove();
			fadingOutObj = null;
		}
		if (activeResult != null) {
			activeResult.object.remove();
			activeResult = null;
		}
		activeTooltipId = null;
		activeBuildName = null;
		activeParams = null;
		hoverInteractiveId = null;
		hoverBuildName = null;
		hoverParams = null;
		hoverTimer = 0;
		delayOverrides.clear();
		positionOverrides.clear();
		offsetOverrides.clear();
	}

}
