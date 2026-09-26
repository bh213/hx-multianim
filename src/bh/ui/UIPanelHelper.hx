package bh.ui;

import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.ui.UITooltipHelper.TooltipPosition;
import bh.ui.UIElement.UIEventPriority;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.screens.UIScreen;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;

enum PanelCloseMode {
	OutsideClick;
	Manual;
}

@:structInit
@:nullSafety
typedef PanelDefaults = {
	var ?position:TooltipPosition;
	var ?offset:Int;
	var ?layer:LayersEnum;
	var ?closeOn:PanelCloseMode;
	var ?fadeIn:Float;
	var ?fadeOut:Float;
}

@:nullSafety
private typedef PanelState = {
	var interactiveId:String;
	var result:BuilderResult;
	var prefix:String;
	var closeMode:PanelCloseMode;
	var pendingClose:Bool;
	var fadeInTween:Null<Tween>;
	var fadeInGen:Int; // fadeInTween.generation when started (see Tween.generation)
}

/** One in-flight fade-out of a named panel slot. */
@:nullSafety
private typedef NamedFadeOut = {
	final tween:Tween;
	final gen:Int; // tween.generation when started (see Tween.generation)
	final obj:h2d.Object;
}

@:nullSafety
class UIPanelHelper {
	/** Event name used with UICustomEvent when a panel closes. Data is the interactiveId (String). */
	public static inline final EVENT_PANEL_CLOSE = "panelClose";
	final screen:UIComponentHost;
	final builder:MultiAnimBuilder;
	final defaultPosition:TooltipPosition;
	final defaultOffset:Int;
	final layer:LayersEnum;
	final defaultCloseMode:PanelCloseMode;
	final defaultFadeIn:Float;
	final defaultFadeOut:Float;
	var tweens:Null<TweenManager>;

	// Per-interactive overrides
	var positionOverrides:Map<String, TooltipPosition> = [];
	var offsetOverrides:Map<String, Int> = [];

	// Active panel state (single-panel API, backwards compatible)
	var activeInteractiveId:Null<String> = null;
	var activeResult:Null<BuilderResult> = null;
	var activePanelPrefix:Null<String> = null;
	var activeCloseMode:PanelCloseMode;

	// Single-panel fade state. The *Gen fields hold each tween's generation when it started: a
	// fade cancelled elsewhere (TweenManager.clear / cancelAll) goes back to the pool, and the
	// kept reference must not cancel whatever animation reuses it (see Tween.generation).
	var activeFadeInTween:Null<Tween> = null;
	var activeFadeInGen:Int = 0;
	var fadingOutObj:Null<h2d.Object> = null;
	var activeFadeOutTween:Null<Tween> = null;
	var activeFadeOutGen:Int = 0;

	// Named panel slots for multi-panel support
	var namedPanels:Map<String, PanelState> = [];
	// In-flight fade-out per slot (survives the panel's removal from namedPanels). `gen` is the
	// tween's generation when it started, so a fade cancelled elsewhere and reused from the pool is
	// left alone. `obj` is kept so dispose() can detach the panel directly: TweenManager.cancel()
	// suppresses onComplete, the only path that normally calls obj.remove(), so without it dispose()
	// would leak the panel into the scene. One record per fade, so a fade's own completion callback
	// can tell whether the slot still tracks it or a newer fade started in the meantime.
	var namedFadeOuts:Map<String, NamedFadeOut> = [];

	public function new(screen:UIComponentHost, builder:MultiAnimBuilder, ?defaults:PanelDefaults, ?tweens:TweenManager) {
		this.screen = screen;
		this.builder = builder;
		this.defaultPosition = defaults?.position ?? Below;
		this.defaultOffset = defaults?.offset ?? 4;
		this.layer = defaults?.layer ?? ModalLayer;
		this.defaultCloseMode = defaults?.closeOn ?? OutsideClick;
		this.activeCloseMode = this.defaultCloseMode;
		this.defaultFadeIn = defaults?.fadeIn ?? 0;
		this.defaultFadeOut = defaults?.fadeOut ?? 0;
		this.tweens = tweens;
	}

	/** Set custom position for a specific interactive. */
	public function setPosition(interactiveId:String, position:TooltipPosition):Void {
		positionOverrides.set(interactiveId, position);
	}

	/** Set custom offset for a specific interactive. */
	public function setOffset(interactiveId:String, offset:Int):Void {
		offsetOverrides.set(interactiveId, offset);
	}

	// ---- Single-panel API (backwards compatible) ----

	/** Open a panel anchored to an interactive. Closes any existing panel first. */
	public function open(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>, ?closeMode:PanelCloseMode):Void {
		close();

		final wrapper = screen.getInteractive(interactiveId);
		if (wrapper == null)
			return;

		final result = builder.buildWithParameters(buildName, params ?? [], null, null, true);
		final position = positionOverrides.get(interactiveId) ?? defaultPosition;
		final offset = offsetOverrides.get(interactiveId) ?? defaultOffset;

		UIPositionHelper.position(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		// Register panel interactives with a prefix so the screen can identify them
		final prefix = '${interactiveId}.$buildName';
		if (result.interactives.length > 0)
			for (w in screen.addInteractives(result, prefix))
				w.eventPriority = UIEventPriority.Overlay;

		// Apply fade-in
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			final fadeIn = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			activeFadeInTween = fadeIn;
			activeFadeInGen = fadeIn.generation;
			fadeIn.setOnComplete(() -> {
				activeFadeInTween = null;
			});
		}

		activeInteractiveId = interactiveId;
		activeResult = result;
		activePanelPrefix = prefix;
		activeCloseMode = closeMode ?? defaultCloseMode;
	}

	/** Open a panel at an explicit position. Closes any existing panel first. */
	public function openAt(x:Float, y:Float, buildName:String, ?params:Map<String, Dynamic>, ?closeMode:PanelCloseMode):Void {
		close();

		final result = builder.buildWithParameters(buildName, params ?? [], null, null, true);
		result.object.setPosition(x, y);
		screen.addObjectToLayer(result.object, layer);

		// Register panel interactives with a prefix so the screen can identify them
		final prefix = 'pos.$buildName';
		if (result.interactives.length > 0)
			for (w in screen.addInteractives(result, prefix))
				w.eventPriority = UIEventPriority.Overlay;

		// Apply fade-in
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			final fadeIn = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			activeFadeInTween = fadeIn;
			activeFadeInGen = fadeIn.generation;
			fadeIn.setOnComplete(() -> {
				activeFadeInTween = null;
			});
		}

		activeInteractiveId = null;
		activeResult = result;
		activePanelPrefix = prefix;
		activeCloseMode = closeMode ?? defaultCloseMode;
	}

	/** Close the active panel. Pushes `UICustomEvent(EVENT_PANEL_CLOSE, interactiveId)` to the screen. */
	public function close():Void {
		// Cancel any in-progress fade-in
		Tween.cancelIfCurrent(activeFadeInTween, activeFadeInGen);
		activeFadeInTween = null;
		// Cancel any in-progress fade-out of previous panel
		cancelActiveFadeOut();

		if (activeResult != null) {
			final closedId = activeInteractiveId;
			if (activePanelPrefix != null)
				screen.removeInteractives(activePanelPrefix);

			final obj = activeResult.object;
			if (defaultFadeOut > 0 && tweens != null) {
				fadingOutObj = obj;
				final fadeOut = tweens.tween(obj, defaultFadeOut, [Alpha(0.0)]);
				activeFadeOutTween = fadeOut;
				activeFadeOutGen = fadeOut.generation;
				fadeOut.setOnComplete(() -> {
					obj.remove();
					fadingOutObj = null;
					activeFadeOutTween = null;
				});
			} else {
				obj.remove();
			}

			activeResult = null;
			activeInteractiveId = null;
			activePanelPrefix = null;
			if (closedId != null)
				screen.onScreenEvent(UICustomEvent(EVENT_PANEL_CLOSE, closedId), null);
			return;
		}
		activeInteractiveId = null;
		activePanelPrefix = null;
	}

	/** Whether a panel is currently open. */
	public function isOpen():Bool {
		return activeResult != null;
	}

	/** Returns the id of the interactive the panel was opened for. */
	public function getActiveId():Null<String> {
		return activeInteractiveId;
	}

	/** Returns the builder result of the active panel (for accessing named elements, slots, etc). */
	public function getPanelResult():Null<BuilderResult> {
		return activeResult;
	}

	/** Returns the prefix used for the active panel's interactives. */
	public function getActivePrefix():Null<String> {
		return activePanelPrefix;
	}

	/** Check if an interactive id belongs to the current panel's interactives. */
	public function isOwnInteractive(id:String):Bool {
		if (activePanelPrefix != null && StringTools.startsWith(id, activePanelPrefix))
			return true;
		for (_ => panel in namedPanels) {
			if (StringTools.startsWith(id, panel.prefix))
				return true;
		}
		return false;
	}

	// ---- Named multi-panel API ----

	/** Open a named panel slot. Closes previous panel in the same slot (if any), other slots stay open. */
	public function openNamed(slot:String, interactiveId:String, buildName:String, ?params:Map<String, Dynamic>,
			?closeMode:PanelCloseMode):Void {
		closeNamed(slot);

		final wrapper = screen.getInteractive(interactiveId);
		if (wrapper == null)
			return;

		final result = builder.buildWithParameters(buildName, params ?? [], null, null, true);
		final position = positionOverrides.get(interactiveId) ?? defaultPosition;
		final offset = offsetOverrides.get(interactiveId) ?? defaultOffset;

		UIPositionHelper.position(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		final prefix = '${slot}.${interactiveId}.$buildName';
		if (result.interactives.length > 0)
			for (w in screen.addInteractives(result, prefix))
				w.eventPriority = UIEventPriority.Overlay;

		// Apply fade-in (tracked so closeNamed can cancel it)
		var fadeInTween:Null<Tween> = null;
		var fadeInGen = 0;
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			final fadeIn = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			fadeInTween = fadeIn;
			fadeInGen = fadeIn.generation;
			fadeIn.setOnComplete(() -> {
				// Clear reference once complete so closeNamed doesn't cancel a finished tween
				final panel = namedPanels.get(slot);
				if (panel != null)
					panel.fadeInTween = null;
			});
		}

		namedPanels.set(slot, {
			interactiveId: interactiveId,
			result: result,
			prefix: prefix,
			closeMode: closeMode ?? defaultCloseMode,
			pendingClose: false,
			fadeInTween: fadeInTween,
			fadeInGen: fadeInGen,
		});
	}

	/** Close a specific named panel slot. */
	public function closeNamed(slot:String):Void {
		// Finish any in-flight fade-out from a previous close of this slot. finish() only snaps the
		// tween to its end: its completion callback still runs on the next update(), and must then
		// find the slot no longer tracking it (see the identity check below).
		final prevFadeOut = namedFadeOuts.get(slot);
		if (prevFadeOut != null) {
			if (prevFadeOut.tween.generation == prevFadeOut.gen)
				prevFadeOut.tween.finish();
			namedFadeOuts.remove(slot);
		}
		final panel = namedPanels.get(slot);
		if (panel == null)
			return;
		// Cancel any in-progress fade-in before starting fade-out
		Tween.cancelIfCurrent(panel.fadeInTween, panel.fadeInGen);
		panel.fadeInTween = null;
		screen.removeInteractives(panel.prefix);
		namedPanels.remove(slot);
		screen.onScreenEvent(UICustomEvent(EVENT_PANEL_CLOSE, panel.interactiveId), null);

		final obj = panel.result.object;
		if (defaultFadeOut > 0 && tweens != null) {
			final fadeOut = tweens.tween(obj, defaultFadeOut, [Alpha(0.0)]);
			final entry:NamedFadeOut = {tween: fadeOut, gen: fadeOut.generation, obj: obj};
			namedFadeOuts.set(slot, entry);
			fadeOut.setOnComplete(() -> {
				obj.remove();
				// Only drop the slot's tracking while it is still this fade's. A close, reopen and
				// close of the same slot within one fade finishes this tween (which still completes
				// on the next update) and starts a newer fade whose tracking must survive.
				if (namedFadeOuts.get(slot) == entry)
					namedFadeOuts.remove(slot);
			});
		} else {
			obj.remove();
		}
	}

	/** Close all named panels. */
	public function closeAllNamed():Void {
		final slots = [for (slot in namedPanels.keys()) slot];
		for (slot in slots)
			closeNamed(slot);
	}

	/** Whether a named panel slot is open. */
	public function isOpenNamed(slot:String):Bool {
		return namedPanels.exists(slot);
	}

	/** Returns the builder result of a named panel slot. */
	public function getNamedPanelResult(slot:String):Null<BuilderResult> {
		final panel = namedPanels.get(slot);
		return panel?.result;
	}

	// ---- Outside-click handling ----

	/**
	 * Handle outside-click close for UIInteractiveEvents.
	 * The trigger interactive subscribes on push, so clicking elsewhere fires UIClickOutside.
	 * Because the controller sends OnReleaseOutside before OnRelease, we defer the close
	 * to allow panel's own interactives to cancel it.
	 * Auto-wired when created via `createPanelHelper()`, or call manually from onScreenEvent.
	 * Returns true if any panel was closed immediately (click on unrelated interactive).
	 */
	var _pendingClose:Bool = false;

	public function handleOutsideClick(event:UIScreenEvent):Bool {
		var closed = false;
		// Handle single-panel
		if (isOpen() && activeCloseMode == OutsideClick) {
			switch event {
				case UIInteractiveEvent(UIClickOutside, id, _):
					if (id == activeInteractiveId)
						_pendingClose = true;
				case UIInteractiveEvent(UIClick, id, _):
					if (id == activeInteractiveId || (activePanelPrefix != null && StringTools.startsWith(id, activePanelPrefix))) {
						_pendingClose = false;
					} else if (!isNamedPanelInteractive(id)) {
						_pendingClose = false;
						close();
						closed = true;
					}
				default:
			}
		}
		// Handle named panels
		for (_ => panel in namedPanels) {
			if (panel.closeMode != OutsideClick)
				continue;
			switch event {
				case UIInteractiveEvent(UIClickOutside, id, _):
					if (id == panel.interactiveId)
						panel.pendingClose = true;
				case UIInteractiveEvent(UIClick, id, _):
					if (id == panel.interactiveId || StringTools.startsWith(id, panel.prefix)
						|| isOwnInteractive(id) || isNamedPanelTrigger(id)) {
						panel.pendingClose = false;
					} else {
						// Defer named panel close to checkPendingClose to avoid iterator invalidation
						panel.pendingClose = true;
					}
				default:
			}
		}
		return closed;
	}

	/** Call from screen's update(). Resolves deferred outside-click close. Returns true if any panel was closed. */
	public function checkPendingClose():Bool {
		var closed = false;
		if (_pendingClose) {
			_pendingClose = false;
			close();
			closed = true;
		}
		// Collect named slots to close (avoid modifying map during iteration)
		var toClose:Null<Array<String>> = null;
		for (slot => panel in namedPanels) {
			if (panel.pendingClose) {
				if (toClose == null) toClose = [];
				toClose.push(slot);
			}
		}
		if (toClose != null)
			for (slot in toClose) {
				closeNamed(slot);
				closed = true;
			}
		return closed;
	}

	// IMPORTANT: This relies on TweenManager.cancel() only setting a flag without firing onComplete.
	// If cancel() ever fires onComplete, the remove() below would double-remove with the tween's callback.
	function cancelActiveFadeOut():Void {
		Tween.cancelIfCurrent(activeFadeOutTween, activeFadeOutGen);
		activeFadeOutTween = null;
		if (fadingOutObj != null) {
			fadingOutObj.remove();
			fadingOutObj = null;
		}
	}

	function isNamedPanelInteractive(id:String):Bool {
		for (_ => panel in namedPanels) {
			if (StringTools.startsWith(id, panel.prefix))
				return true;
		}
		return false;
	}

	function isNamedPanelTrigger(id:String):Bool {
		for (_ => panel in namedPanels) {
			if (id == panel.interactiveId)
				return true;
		}
		return false;
	}

	/** Release all tween and scene resources. Call when the owning screen is torn down
	    (e.g. during hot reload or full rebuild) to prevent in-flight fade tween closures
	    from holding h2d.Object references past the screen's lifetime. */
	public function dispose():Void {
		// Single-panel fade tweens
		Tween.cancelIfCurrent(activeFadeInTween, activeFadeInGen);
		activeFadeInTween = null;
		Tween.cancelIfCurrent(activeFadeOutTween, activeFadeOutGen);
		activeFadeOutTween = null;
		if (fadingOutObj != null) {
			fadingOutObj.remove();
			fadingOutObj = null;
		}
		if (activeResult != null) {
			if (activePanelPrefix != null)
				screen.removeInteractives(activePanelPrefix);
			activeResult.object.remove();
			activeResult = null;
		}
		activeInteractiveId = null;
		activePanelPrefix = null;
		_pendingClose = false;

		// Named-panel fades — both in-flight fade-in on open panels and
		// orphaned fade-out tweens tracked in namedFadeOutTweens.
		for (_ => panel in namedPanels) {
			Tween.cancelIfCurrent(panel.fadeInTween, panel.fadeInGen);
			panel.fadeInTween = null;
			screen.removeInteractives(panel.prefix);
			panel.result.object.remove();
		}
		namedPanels.clear();
		// Detach each fading-out object and cancel its tween. Cancel suppresses the onComplete
		// that owns obj.remove(), so without the detach the panel's h2d.Object would stay
		// parented to the scene.
		for (_ => fadeOut in namedFadeOuts) {
			fadeOut.obj.remove();
			Tween.cancelIfCurrent(fadeOut.tween, fadeOut.gen);
		}
		namedFadeOuts.clear();

		positionOverrides.clear();
		offsetOverrides.clear();
	}

}
