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
	var fadeOutTween:Null<Tween>;
}

@:nullSafety
class UIPanelHelper {
	/** Event name used with UICustomEvent when a panel closes. Data is the interactiveId (String). */
	public static inline final EVENT_PANEL_CLOSE = "panelClose";
	final screen:UIScreenBase;
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

	// Single-panel fade state
	var activeFadeInTween:Null<Tween> = null;
	var fadingOutObj:Null<h2d.Object> = null;
	var activeFadeOutTween:Null<Tween> = null;

	// Named panel slots for multi-panel support
	var namedPanels:Map<String, PanelState> = [];
	// In-flight fade-out tweens for named panels (keyed by slot, survives panel removal from namedPanels)
	var namedFadeOutTweens:Map<String, Tween> = [];

	public function new(screen:UIScreenBase, builder:MultiAnimBuilder, ?defaults:PanelDefaults, ?tweens:TweenManager) {
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

		positionPanel(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		// Register panel interactives with a prefix so the screen can identify them
		final prefix = '${interactiveId}.$buildName';
		if (result.interactives.length > 0)
			for (w in screen.addInteractives(result, prefix))
				w.eventPriority = UIEventPriority.Overlay;

		// Apply fade-in
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			activeFadeInTween = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			activeFadeInTween.setOnComplete(() -> {
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
			activeFadeInTween = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			activeFadeInTween.setOnComplete(() -> {
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
		if (activeFadeInTween != null) {
			activeFadeInTween.cancel();
			activeFadeInTween = null;
		}
		// Cancel any in-progress fade-out of previous panel
		cancelActiveFadeOut();

		if (activeResult != null) {
			final closedId = activeInteractiveId;
			if (activePanelPrefix != null)
				screen.removeInteractives(activePanelPrefix);

			final obj = activeResult.object;
			if (defaultFadeOut > 0 && tweens != null) {
				fadingOutObj = obj;
				activeFadeOutTween = tweens.tween(obj, defaultFadeOut, [Alpha(0.0)]);
				activeFadeOutTween.setOnComplete(() -> {
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

		positionPanel(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		final prefix = '${slot}.${interactiveId}.$buildName';
		if (result.interactives.length > 0)
			for (w in screen.addInteractives(result, prefix))
				w.eventPriority = UIEventPriority.Overlay;

		// Apply fade-in (tracked so closeNamed can cancel it)
		var fadeInTween:Null<Tween> = null;
		if (defaultFadeIn > 0 && tweens != null) {
			result.object.alpha = 0;
			fadeInTween = tweens.tween(result.object, defaultFadeIn, [Alpha(1.0)]);
			fadeInTween.setOnComplete(() -> {
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
			fadeOutTween: null,
		});
	}

	/** Close a specific named panel slot. */
	public function closeNamed(slot:String):Void {
		// Cancel any in-flight fade-out from a previous close of this slot
		final prevFadeOut = namedFadeOutTweens.get(slot);
		if (prevFadeOut != null) {
			prevFadeOut.finish();
			namedFadeOutTweens.remove(slot);
		}
		final panel = namedPanels.get(slot);
		if (panel == null)
			return;
		// Cancel any in-progress fade-in before starting fade-out
		if (panel.fadeInTween != null) {
			panel.fadeInTween.cancel();
			panel.fadeInTween = null;
		}
		// Cancel any in-progress fade-out from a previous close
		if (panel.fadeOutTween != null) {
			panel.fadeOutTween.cancel();
			panel.fadeOutTween = null;
		}
		screen.removeInteractives(panel.prefix);
		namedPanels.remove(slot);
		screen.onScreenEvent(UICustomEvent(EVENT_PANEL_CLOSE, panel.interactiveId), null);

		final obj = panel.result.object;
		if (defaultFadeOut > 0 && tweens != null) {
			final fadeOut = tweens.tween(obj, defaultFadeOut, [Alpha(0.0)]);
			namedFadeOutTweens.set(slot, fadeOut);
			fadeOut.setOnComplete(() -> {
				obj.remove();
				namedFadeOutTweens.remove(slot);
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

	function cancelActiveFadeOut():Void {
		if (activeFadeOutTween != null) {
			activeFadeOutTween.cancel();
			activeFadeOutTween = null;
		}
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

	function positionPanel(panel:h2d.Object, anchor:h2d.Object, position:TooltipPosition, offset:Int):Void {
		final anchorBounds = anchor.getBounds();
		final panelBounds = panel.getSize();

		switch position {
			case Above:
				panel.x = anchorBounds.x + (anchorBounds.width - panelBounds.width) / 2;
				panel.y = anchorBounds.y - panelBounds.height - offset;
			case Below:
				panel.x = anchorBounds.x + (anchorBounds.width - panelBounds.width) / 2;
				panel.y = anchorBounds.y + anchorBounds.height + offset;
			case Left:
				panel.x = anchorBounds.x - panelBounds.width - offset;
				panel.y = anchorBounds.y + (anchorBounds.height - panelBounds.height) / 2;
			case Right:
				panel.x = anchorBounds.x + anchorBounds.width + offset;
				panel.y = anchorBounds.y + (anchorBounds.height - panelBounds.height) / 2;
		}
	}
}
