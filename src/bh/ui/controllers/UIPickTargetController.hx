package bh.ui.controllers;

import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes.CardId;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIMultiAnimGrid;
import bh.ui.controllers.UIController;
import bh.ui.controllers.UIInteractionTypes;
import h2d.col.Point;

/**
 * Controller for "pick a target" interactions.
 *
 * Supports three target sources (composable):
 * - **Interactives**: matched by ID list, prefix, or filter function
 * - **Grid cells**: cells in a UIMultiAnimGrid matched by cellFilter
 * - **Cards in hand**: cards in a UICardHandHelper matched by cardFilter
 *
 * When active:
 * - Valid targets are highlighted via parameter changes
 * - Click on a valid target completes with the appropriate PickTargetResult
 * - Card hand drag is suppressed (if cardHand is set)
 * - Escape/right-click cancels
 *
 * Usage:
 * ```haxe
 * UIPickTargetController.start(this, {grid: hexGrid, cellFilter: (c, r) -> hexGrid.isOccupied(c, r)}, (result) -> {
 *     if (result != null) switch result { case TargetCell(c, r): attack(c, r); default: }
 * });
 * ```
 */
@:nullSafety
class UIPickTargetController extends UIInteractionController {
	/** Push a pick-target controller onto the screen's controller stack.
	 *  Auto-pops on result/cancel. Callback receives PickTargetResult or null if cancelled. */
	public static function start(screen:bh.ui.screens.UIScreen.UIScreenBase, config:PickTargetConfig,
			callback:(Null<PickTargetResult>) -> Void):UIPickTargetController {
		final ctrl = new UIPickTargetController(screen, config, (result:Null<Dynamic>) -> {
			screen.popController();
			callback(result != null ? cast result : null);
		});
		screen.pushController(ctrl);
		return ctrl;
	}

	final config:PickTargetConfig;
	final highlightParam:String;
	final highlightValue:Dynamic;
	final highlightResetValue:Dynamic;

	var savedCanDragCard:Null<(CardId) -> Bool>;

	public function new(integration:UIControllerScreenIntegration, config:PickTargetConfig,
			resultCallback:(Null<Dynamic>) -> Void) {
		super(integration, resultCallback);
		this.config = config;
		this.highlightParam = config.highlightParam != null ? config.highlightParam : "highlight";
		this.highlightValue = config.highlightValue != null ? config.highlightValue : "valid";
		this.highlightResetValue = config.highlightResetValue != null ? config.highlightResetValue : "none";
	}

	override public function onActivate():Void {
		// Suppress card hand dragging if card hand is involved
		if (config.cardHand != null) {
			savedCanDragCard = config.cardHand.canDragCard;
			config.cardHand.canDragCard = (_) -> false;
		}

		// Highlight all valid grid cells
		final grid = config.grid;
		if (grid != null) {
			grid.forEach((col, row, _) -> {
				if (isCellValid(col, row)) {
					grid.setCellParameter(col, row, highlightParam, highlightValue);
				}
			});
		}
	}

	override public function onDeactivate():Void {
		// Restore card hand
		if (config.cardHand != null) {
			config.cardHand.canDragCard = savedCanDragCard;
			savedCanDragCard = null;
		}

		// Clear grid highlights
		final grid = config.grid;
		if (grid != null) {
			grid.forEach((col, row, _) -> {
				grid.setCellParameter(col, row, highlightParam, highlightResetValue);
			});
		}
	}

	/** Intercept interactive/card click events. */
	override public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		switch event {
			case UIInteractiveEvent(UIClick, id, _):
				// Check card hand first
				if (config.cardHand != null) {
					final cardId = config.cardHand.findCardIdByInteractiveId(id);
					if (cardId != null && isCardValid(cardId)) {
						complete(PickTargetResult.TargetCard(cardId));
						return;
					}
				}
				// Check if valid target interactive
				if (isInteractiveValid(id)) {
					complete(PickTargetResult.TargetInteractive(id));
					return;
				}
			case UIInteractiveEvent(UIPush, id, _):
				// Suppress card drag
				if (config.cardHand != null) {
					final cardId = config.cardHand.findCardIdByInteractiveId(id);
					if (cardId != null)
						return;
				}
			default:
		}

		super.onScreenEvent(event, source);
	}

	/** Handle grid cell clicks via direct hit-test. */
	override public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper):Void {
		if (release && button == 0 && config.grid != null) {
			final hit = config.grid.cellAtPoint(mousePoint.x, mousePoint.y);
			if (hit != null && isCellValid(hit.col, hit.row)) {
				complete(PickTargetResult.TargetCell(hit.col, hit.row));
				return;
			}
		}
		super.handleClick(mousePoint, button, release, eventWrapper);
	}

	/** Route mouse move to grid for hover feedback. */
	override public function handleMove(mousePoint:Point, eventWrapper:EventWrapper):Void {
		if (config.grid != null) {
			config.grid.onMouseMove(mousePoint.x, mousePoint.y);
		}
		super.handleMove(mousePoint, eventWrapper);
	}

	function isInteractiveValid(id:String):Bool {
		if (config.filter != null)
			return config.filter(id);
		if (config.validTargetIds != null)
			return config.validTargetIds.contains(id);
		if (config.targetPrefix != null)
			return StringTools.startsWith(id, config.targetPrefix);
		return false;
	}

	function isCellValid(col:Int, row:Int):Bool {
		if (config.grid == null)
			return false;
		if (config.cellFilter != null)
			return config.cellFilter(col, row);
		return config.grid.hasCell(col, row);
	}

	function isCardValid(cardId:String):Bool {
		if (config.cardHand == null)
			return false;
		if (config.cardFilter != null)
			return config.cardFilter(cardId);
		return config.cardHand.isCardInHand(cardId);
	}

	override public function getDebugName():String {
		return "pick-target";
	}
}
