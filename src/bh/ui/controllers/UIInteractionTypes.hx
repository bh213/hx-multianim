package bh.ui.controllers;

import bh.ui.UICardHandTypes.CardId;

/** Result of selecting cards from hand. */
@:structInit
typedef SelectFromHandResult = {
	var cards:Array<CardId>;
}

/** Result of picking a target. */
enum PickTargetResult {
	TargetInteractive(id:String);
	TargetCell(col:Int, row:Int);
	TargetCard(cardId:CardId);
}

/** Filter for which cards can be selected. */
typedef CardSelectFilter = (cardId:CardId) -> Bool;

/** Configuration for UISelectFromHandController. */
@:structInit
@:nullSafety
typedef SelectFromHandConfig = {
	/** Minimum cards to select (default: 1). */
	var ?minCount:Int;

	/** Maximum cards to select (default: 1). */
	var ?maxCount:Int;

	/** Filter — which cards are selectable (null = all enabled cards). */
	var ?filter:CardSelectFilter;

	/** Card parameter name for "selected" visual state (default: "selected"). */
	var ?selectedParam:String;

	/** Value to set on selectedParam when card is selected (default: true). */
	var ?selectedValue:Dynamic;

	/** Value to set on selectedParam when card is deselected (default: false). */
	var ?deselectedValue:Dynamic;

	/** Whether to auto-confirm when maxCount cards are selected (default: true when minCount==maxCount). */
	var ?autoConfirm:Bool;
}

/** Configuration for UIPickTargetController. */
@:structInit
@:nullSafety
typedef PickTargetConfig = {
	/** Interactive IDs that are valid targets. */
	var ?validTargetIds:Array<String>;

	/** Interactive ID prefix for valid targets (e.g., "enemy_"). */
	var ?targetPrefix:String;

	/** Dynamic filter function (overrides validTargetIds/targetPrefix). */
	var ?filter:(id:String) -> Bool;

	/** Grid to use for cell targeting (null = interactive-only targeting). */
	var ?grid:bh.ui.UIMultiAnimGrid;

	/** Grid cell filter — which cells are valid targets. */
	var ?cellFilter:(col:Int, row:Int) -> Bool;

	/** Card hand to use for card targeting (null = no card targeting). */
	var ?cardHand:bh.ui.UICardHandHelper;

	/** Card filter — which cards are valid targets. */
	var ?cardFilter:CardSelectFilter;

	/** Cell/interactive highlight parameter name (default: "highlight"). */
	var ?highlightParam:String;

	/** Highlight value for valid targets (default: "valid"). */
	var ?highlightValue:Dynamic;

	/** Cell highlight parameter to reset on deactivate (default: "none"). */
	var ?highlightResetValue:Dynamic;
}
