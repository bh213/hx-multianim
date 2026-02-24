package bh.ui;

import bh.ui.UITooltipHelper.TooltipPosition;
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
}

@:nullSafety
class UIPanelHelper {
	final screen:UIScreenBase;
	final builder:MultiAnimBuilder;
	final defaultPosition:TooltipPosition;
	final defaultOffset:Int;
	final layer:LayersEnum;
	final defaultCloseMode:PanelCloseMode;

	// Active panel state
	var activeInteractiveId:Null<String> = null;
	var activeResult:Null<BuilderResult> = null;
	var activePanelPrefix:Null<String> = null;
	var activeCloseMode:PanelCloseMode;

	public function new(screen:UIScreenBase, builder:MultiAnimBuilder, ?defaults:PanelDefaults) {
		this.screen = screen;
		this.builder = builder;
		this.defaultPosition = defaults?.position ?? Below;
		this.defaultOffset = defaults?.offset ?? 4;
		this.layer = defaults?.layer ?? ModalLayer;
		this.defaultCloseMode = defaults?.closeOn ?? OutsideClick;
		this.activeCloseMode = this.defaultCloseMode;
	}

	/** Open a panel anchored to an interactive. Closes any existing panel first. */
	public function open(interactiveId:String, buildName:String, ?params:Map<String, Dynamic>, ?closeMode:PanelCloseMode):Void {
		close();

		final wrapper = screen.getInteractive(interactiveId);
		if (wrapper == null)
			return;

		final result = builder.buildWithParameters(buildName, params ?? [], null, null, true);
		final position = defaultPosition;
		final offset = defaultOffset;

		positionPanel(result.object, wrapper.interactive, position, offset);
		screen.addObjectToLayer(result.object, layer);

		// Register panel interactives with a prefix so the screen can identify them
		final prefix = '${interactiveId}.$buildName';
		if (result.interactives.length > 0)
			screen.addInteractives(result, prefix);

		activeInteractiveId = interactiveId;
		activeResult = result;
		activePanelPrefix = prefix;
		activeCloseMode = closeMode ?? defaultCloseMode;
	}

	/** Close the active panel. */
	public function close():Void {
		if (activeResult != null) {
			if (activePanelPrefix != null)
				screen.removeInteractives(activePanelPrefix);
			activeResult.object.remove();
			activeResult = null;
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
		if (activePanelPrefix == null)
			return false;
		return StringTools.startsWith(id, activePanelPrefix);
	}

	/**
	 * Call from onScreenEvent for every UIInteractiveEvent to handle outside-click close.
	 * Uses OutsideClickControl: the trigger interactive subscribes on push, so clicking
	 * elsewhere fires UIClickOutside. Because the controller sends OnReleaseOutside before
	 * OnRelease, we defer the close to allow panel's own interactives to cancel it.
	 * Call `checkPendingClose()` from the screen's update().
	 * Returns true if the panel was closed immediately (click on unrelated interactive).
	 */
	var _pendingClose:Bool = false;

	public function handleOutsideClick(event:UIScreenEvent):Bool {
		if (!isOpen() || activeCloseMode != OutsideClick)
			return false;
		switch event {
			case UIInteractiveEvent(UIClickOutside, id, _):
				// Trigger's outside click — defer in case a panel interactive click follows
				if (id == activeInteractiveId)
					_pendingClose = true;
				return false;
			case UIInteractiveEvent(UIClick, id, _):
				if (id == activeInteractiveId || isOwnInteractive(id)) {
					_pendingClose = false; // cancel — clicked our own
					return false;
				}
				// Clicked unrelated interactive — close immediately
				_pendingClose = false;
				close();
				return true;
			default:
				return false;
		}
	}

	/** Call from screen's update(). Resolves deferred outside-click close. Returns true if closed. */
	public function checkPendingClose():Bool {
		if (_pendingClose) {
			_pendingClose = false;
			close();
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
