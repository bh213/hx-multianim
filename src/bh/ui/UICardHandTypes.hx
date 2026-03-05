package bh.ui;

import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.ui.screens.UIScreen.LayersEnum;

typedef CardId = String;

enum CardState {
	InHand;
	Hovered;
	Dragging;
	Targeting;
	Animating;
	Disabled;
}

enum HandLayoutMode {
	Fan;
	Linear;
	PathLayout;
}

/** How cards are distributed along a path in PathLayout mode. */
enum PathDistribution {
	/** Uniform visual spacing along the curve (default). */
	EvenArcLength;

	/** Equal rate increments — cards may bunch up on sharp curves. */
	EvenRate;
}

/** How cards are rotated relative to the path tangent in PathLayout mode. */
enum PathOrientation {
	/** Cards rotated to follow curve tangent. */
	Tangent;

	/** No rotation, cards always upright. */
	Straight;

	/** Tangent rotation clamped to ±maxDeg degrees. */
	TangentClamped(maxDeg:Float);
}

@:structInit
class CardLayoutPosition {
	public var x:Float;
	public var y:Float;
	public var rotation:Float;
	public var scale:Float;
	public var normalX:Float;
	public var normalY:Float;
}

enum TargetingResult {
	TargetZone(targetId:String);
	NoTarget;
}

enum CardHandEvent {
	CardPlayed(cardId:CardId, target:TargetingResult);
	CardCombined(sourceCardId:CardId, targetCardId:CardId);
	CardHoverStart(cardId:CardId);
	CardHoverEnd(cardId:CardId);
	CardDragStart(cardId:CardId);
	CardDragEnd(cardId:CardId);
	DrawAnimComplete(cardId:CardId);
	DiscardAnimComplete(cardId:CardId);
}

/** Callback for target highlight state changes. Receives the interactive id, highlight on/off, and the interactive's metadata. */
typedef TargetHighlightCallback = (targetId:String, highlight:Bool, metadata:BuilderResolvedSettings) -> Void;

/** Callback to filter which targets accept a card. Return true to accept. */
typedef TargetAcceptsCallback = (cardId:CardId, targetId:String, metadata:BuilderResolvedSettings) -> Bool;

/** Configuration for UICardHandHelper.
 *
 *  `.manim` element names (the game's `.manim` file must define these):
 *  - `drawPath` — animatedPath for card draw animation (Stretch-normalized from drawPile→hand)
 *  - `discardPath` — animatedPath for discard animation (Stretch-normalized from hand→discardPile)
 *  - `returnPath` — animatedPath for cancelled drag return (Stretch-normalized)
 *  - `rearrangePath` — animatedPath for hand rearrange slides (Stretch-normalized)
 *  - arrow segment/head — programmables for targeting arrow chain (receives `valid:bool` parameter)
 *  - arrow path — path defining the arrow curve shape
 *
 *  Card programmables should contain:
 *  - `interactive(w, h, cardId, bind => "status")` for hover/click auto-wiring
 *  - `@(status=>hover) filter: glow(...)` etc. for visual states via filters
 */
@:structInit
@:nullSafety
typedef CardHandConfig = {
	// Layout
	var ?layoutMode:HandLayoutMode;
	var ?anchorX:Float;
	var ?anchorY:Float;
	var ?cardWidth:Float;
	var ?cardHeight:Float;

	// Fan layout
	var ?fanRadius:Float;
	var ?fanMaxAngle:Float;

	// Linear layout
	var ?linearSpacing:Float;
	var ?linearMaxWidth:Float;

	// Path layout
	var ?layoutPathName:String;
	var ?pathDistribution:PathDistribution;
	var ?pathOrientation:PathOrientation;

	// Hover
	var ?hoverPopDistance:Float;
	var ?hoverScale:Float;
	var ?hoverNeighborSpread:Float;

	// Drag
	var ?targetingThresholdY:Float;

	// Card-to-card
	var ?allowCardToCard:Bool;
	var ?cardToCardHighlightScale:Float;
	var ?cardToCardHoverPop:Bool;
	var ?cardToCardHoverScale:Bool;
	var ?cardToCardSpread:Bool;

	// Pile positions
	var ?drawPilePosition:FPoint;
	var ?discardPilePosition:FPoint;

	// Layers
	var ?handLayer:LayersEnum;
	var ?dragLayer:LayersEnum;

	// .manim element names for animated paths (null = no animation, instant)
	var ?drawPathName:String;
	var ?discardPathName:String;
	var ?returnPathName:String;
	var ?rearrangePathName:String;

	// .manim element names for targeting arrow (chain of programmable instances along a path)
	var ?arrowSegmentName:String;
	var ?arrowHeadName:String;
	var ?arrowPathName:String;
	var ?arrowSegmentSpacing:Float;

	// Interactive prefix for card interactives (default: "card")
	var ?interactivePrefix:String;

	// Card content customization callback — called after each card is built
	var ?onCardBuilt:(cardId:CardId, result:BuilderResult, container:h2d.Object) -> Void;
}

@:structInit
@:nullSafety
typedef CardDescriptor = {
	var id:CardId;
	var buildName:String;
	var ?params:Map<String, Dynamic>;
	var ?enabled:Bool;
	var ?canTarget:Bool;
	var ?canCombineWith:(targetCardId:CardId) -> Bool;
}
