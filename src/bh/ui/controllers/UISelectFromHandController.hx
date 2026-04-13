package bh.ui.controllers;

import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes.CardId;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.controllers.UIController;
import bh.ui.controllers.UIInteractionTypes;
import h2d.col.Point;

/**
 * Controller for "select N cards from hand" interactions.
 *
 * When active:
 * - Card drag is suppressed (UIPush events for cards are intercepted)
 * - Card clicks toggle selection state
 * - Selected cards get a visual parameter change (e.g., `selected: true`)
 * - Auto-confirms when maxCount reached (configurable)
 * - Escape/right-click cancels, restoring all card visuals
 *
 * Usage:
 * ```haxe
 * UISelectFromHandController.start(this, cardHand, {maxCount: 2}, (result) -> {
 *     if (result != null) discardCards(result.cards);
 * });
 * ```
 */
@:nullSafety
class UISelectFromHandController extends UIInteractionController {
	/** Push a select-from-hand controller onto the screen's controller stack.
	 *  Auto-pops on result/cancel. Callback receives SelectFromHandResult or null if cancelled. */
	public static function start(screen:bh.ui.screens.UIScreen.UIScreenBase, cardHand:UICardHandHelper, config:SelectFromHandConfig,
			callback:(Null<SelectFromHandResult>) -> Void):UISelectFromHandController {
		final ctrl = new UISelectFromHandController(screen, cardHand, config, (result:Null<Dynamic>) -> {
			screen.popController();
			callback(result != null ? cast result : null);
		});
		screen.pushController(ctrl);
		return ctrl;
	}

	final cardHand:UICardHandHelper;
	final selectedCards:Array<CardId> = [];
	final minCount:Int;
	final maxCount:Int;
	final selectedParam:String;
	final selectedValue:Dynamic;
	final deselectedValue:Dynamic;
	final autoConfirm:Bool;
	final filter:Null<CardSelectFilter>;

	var savedCanDragCard:Null<(CardId) -> Bool>;

	public function new(integration:UIControllerScreenIntegration, cardHand:UICardHandHelper, config:SelectFromHandConfig,
			resultCallback:(Null<Dynamic>) -> Void) {
		super(integration, resultCallback);
		this.cardHand = cardHand;
		this.minCount = config.minCount != null ? config.minCount : 1;
		this.maxCount = config.maxCount != null ? config.maxCount : 1;
		this.selectedParam = config.selectedParam != null ? config.selectedParam : "selected";
		this.selectedValue = config.selectedValue != null ? config.selectedValue : true;
		this.deselectedValue = config.deselectedValue != null ? config.deselectedValue : false;
		this.filter = config.filter;
		final min = this.minCount;
		final max = this.maxCount;
		this.autoConfirm = config.autoConfirm != null ? config.autoConfirm : (min == max);
	}

	override public function onActivate():Void {
		// Suppress card dragging while selecting
		savedCanDragCard = cardHand.canDragCard;
		cardHand.canDragCard = (_) -> false;

		// Dim non-selectable cards
		if (filter != null) {
			for (cardId in cardHand.getCardIds()) {
				if (!cardHand.isCardInHand(cardId))
					continue;
				if (!filter(cardId)) {
					cardHand.setCardEnabled(cardId, false);
				}
			}
		}
	}

	override public function onDeactivate():Void {
		// Restore drag behavior
		cardHand.canDragCard = savedCanDragCard;
		savedCanDragCard = null;

		// Clear all selection visuals
		for (cardId in selectedCards) {
			cardHand.updateCardParams(cardId, [selectedParam => deselectedValue]);
		}
		selectedCards.resize(0);

		// Re-enable cards that were disabled by filter
		if (filter != null) {
			for (cardId in cardHand.getCardIds()) {
				cardHand.setCardEnabled(cardId, true);
			}
		}
	}

	/** Intercept card interactive events for selection behavior. */
	override public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		switch event {
			case UIInteractiveEvent(UIClick, id, _):
				final cardId = cardHand.findCardIdByInteractiveId(id);
				if (cardId != null && cardHand.isCardInHand(cardId)) {
					toggleCard(cardId);
					return; // consumed — don't dispatch to screen
				}
			case UIInteractiveEvent(UIPush, id, _):
				// Suppress card drag initiation
				final cardId = cardHand.findCardIdByInteractiveId(id);
				if (cardId != null)
					return;
			default:
		}

		super.onScreenEvent(event, source);
	}

	function toggleCard(cardId:CardId):Void {
		if (selectedCards.contains(cardId)) {
			// Deselect
			selectedCards.remove(cardId);
			cardHand.updateCardParams(cardId, [selectedParam => deselectedValue]);
		} else {
			if (selectedCards.length >= maxCount)
				return;
			if (filter != null && !filter(cardId))
				return;

			// Select
			selectedCards.push(cardId);
			cardHand.updateCardParams(cardId, [selectedParam => selectedValue]);

			if (autoConfirm && selectedCards.length >= maxCount) {
				complete({cards: selectedCards.copy()});
			}
		}
	}

	/** Confirm current selection manually (e.g., from a confirm button). */
	public function confirm():Void {
		if (selectedCards.length >= minCount)
			complete({cards: selectedCards.copy()});
	}

	/** Get currently selected card IDs. */
	public function getSelectedCards():Array<CardId> {
		return selectedCards.copy();
	}

	/** Get how many more cards can be selected. */
	public function getRemainingCount():Int {
		return maxCount - selectedCards.length;
	}

	override public function getDebugName():String {
		return 'select-from-hand(${selectedCards.length}/$maxCount)';
	}
}
