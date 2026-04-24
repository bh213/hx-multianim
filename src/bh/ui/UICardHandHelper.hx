package bh.ui;

import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.paths.AnimatedPath;
import bh.paths.AnimatedPath.AnimatedPathState;
import bh.paths.MultiAnimPaths.Path;
import bh.ui.UICardHandLayout;
import bh.ui.UICardHandTargeting;
import bh.ui.UICardHandTypes;
import bh.ui.UICardHandTypes.TargetHighlightCallback;
import bh.ui.UICardHandTypes.TargetAcceptsCallback;
import bh.ui.UICardHandTypes.TargetingZone;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIHigherOrderComponent;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIComponentHost;
import bh.ui.UIRichInteractiveHelper;
import bh.ui.screens.UIScreen.LayersEnum;

private class CardEntry {
	public var descriptor:CardDescriptor;
	public var result:BuilderResult;
	public var container:h2d.Object;
	public var state:CardState = InHand;
	public var layoutPos:CardLayoutPosition;
	public var interactiveId:String;
	/** Deferred enable: if card is disabled during animation and re-enabled before it completes,
	 *  this flag causes the onComplete handler to restore InHand instead of staying Disabled. */
	public var enableAfterAnimation:Bool = false;
	/** Rebuild listener installed on the card's BuilderResult so that any `@switch` arm flip
	 *  or other structural rebuild inside the card resyncs `interactiveHelper`'s bindings.
	 *  Stored here so it can be removed when the card is discarded. Null if the card's result
	 *  is not in incremental mode. */
	public var rebuildListener:Null<Void -> Void> = null;

	public function new(descriptor:CardDescriptor, result:BuilderResult, container:h2d.Object, interactiveId:String) {
		this.descriptor = descriptor;
		this.result = result;
		this.container = container;
		this.interactiveId = interactiveId;
		this.layoutPos = {x: 0.0, y: 0.0, rotation: 0.0, scale: 1.0, normalX: 0.0, normalY: -1.0};
	}
}

private class ActiveAnimation {
	public var entry:CardEntry;
	public var anim:AnimatedPath;
	public var startRotation:Float;
	public var endRotation:Float;
	public var onComplete:() -> Void;

	/** When non-null, this is a tracking draw animation that re-stretches each frame
	 *  from `trackingFrom` toward `entry.layoutPos`. The AnimatedPath is built with
	 *  no normalization — `rawEndpoint` is the untransformed path endpoint used to
	 *  compute the stretch transform. */
	public var trackingFrom:Null<FPoint> = null;
	public var rawEndpoint:Null<FPoint> = null;

	public function new(entry:CardEntry, anim:AnimatedPath, startRotation:Float, endRotation:Float, onComplete:() -> Void) {
		this.entry = entry;
		this.anim = anim;
		this.startRotation = startRotation;
		this.endRotation = endRotation;
		this.onComplete = onComplete;
	}
}

/** Reusable card hand helper for Slay the Spire-style card interactions.
 *
 *  Leverages the `.manim` ecosystem:
 *  - **Card visuals**: `.manim` programmables with `interactive()` + `bind => "status"` for auto-wired hover/press states
 *  - **Animations**: `animatedPath` elements from `.manim` (draw, discard, rearrange, return) via `createProjectilePath()`
 *  - **Targeting arrow**: chain of `.manim` programmable instances placed along a `.manim` path from card to cursor
 *  - **Visual states**: filters (`glow`, `outline`, `brightness`) in `.manim` conditionals — no manual alpha/scale
 *  - **Hover/press**: `UIRichInteractiveHelper` auto-wires Normal→Hover→Pressed state machine from `interactive()` metadata
 *  - **Layout modes**: Fan (arc), Linear (horizontal), PathLayout (cards distributed along a `.manim` path)
 *  - **Card extensibility**: `onCardBuilt` callback for adding buttons, slots, or custom content to cards
 *
 *  The game provides a `.manim` file with:
 *  ```manim
 *  paths { #drawArc lineTo(0, -30), bezier(100, 0, 50, -60) }
 *  #drawPath animatedPath {
 *      path: drawArc, type: time, duration: 0.3, easing: easeOutBack
 *      0.0: scaleCurve: easeOutBack       // card grows from 0→1 during draw
 *      0.0: alphaCurve: easeOutQuad        // card fades in during draw
 *  }
 *  #discardPath animatedPath {
 *      path: drawArc, type: time, duration: 0.25, easing: easeInQuad
 *      0.0: alphaCurve: easeInQuad         // card fades out during discard (curve 0→1 maps to alpha 0→1; reverse path handles direction)
 *  }
 *  #returnPath animatedPath { path: drawArc, type: time, duration: 0.2, easing: easeOutCubic }
 *  #rearrangePath animatedPath { path: drawArc, type: time, duration: 0.15, easing: easeInOutCubic }
 *
 *  paths { #arrowCurve path { bezier(100, 0, 50, -30) } }
 *  #arrowSegment programmable(valid:bool=false) { ... }  // body segment
 *  #arrowHead programmable(valid:bool=false) { ... }      // arrowhead at end
 *
 *  #card programmable(status:[normal,hover,pressed,disabled]=normal, name:string="", cost:uint=0) {
 *      interactive(80, 110, "card", bind => "status", events: [hover, click, push])
 *      @(status=>normal) ninepatch(cards, cardBg, 80, 110): 0, 0
 *      @(status=>hover) filter: glow(#FFFF00, 0.6, 10)
 *      @(status=>disabled) filter: group(brightness(0.5), grayscale(0.8))
 *      // ... card content
 *  }
 *  ```
 *
 *  Usage:
 *  ```haxe
 *  var cardHand = new UICardHandHelper(screen, builder, {
 *      anchorX: 640, anchorY: 680,
 *      drawPathName: "drawPath",
 *      discardPathName: "discardPath",
 *      returnPathName: "returnPath",
 *      rearrangePathName: "rearrangePath",
 *      arrowSegmentName: "arrowSegment",
 *      arrowHeadName: "arrowHead",
 *      arrowPathName: "arrowCurve",
 *  });
 *  cardHand.onCardEvent = (event) -> switch event {
 *      case CardPlayed(id, target): playCard(id, target);
 *      default:
 *  };
 *  cardHand.drawCard({ id: "card1", buildName: "card", params: [...] });
 *  ``` */
class UICardHandHelper implements UIHigherOrderComponent {
	final screen:UIComponentHost;
	final builder:MultiAnimBuilder;
	final interactiveHelper:UIRichInteractiveHelper;

	// Config with defaults
	final layoutMode:HandLayoutMode;
	var anchorX:Float;
	var anchorY:Float;
	final cardWidth:Float;
	final cardHeight:Float;
	final fanRadius:Float;
	final fanMaxAngle:Float;
	final linearSpacing:Float;
	final linearMaxWidth:Float;
	final hoverPopDistance:Float;
	final hoverScale:Float;
	final hoverNeighborSpread:Float;
	final targetingThresholdY:Float;
	var targetingZones:Array<TargetingZone>;
	final allowCardToCard:Bool;
	final cardToCardHighlightScale:Float;
	final cardToCardHoverPop:Bool;
	final cardToCardHoverScale:Bool;
	final cardToCardSpread:Bool;
	final drawPilePosition:FPoint;
	final discardPilePosition:FPoint;
	final handLayer:LayersEnum;
	final dragLayer:LayersEnum;
	final interactivePrefix:String;

	// Path layout config
	final layoutPathName:Null<String>;
	final pathDistribution:PathDistribution;
	final pathOrientation:PathOrientation;
	var resolvedPath:Null<Path> = null;

	// Card content customization
	final onCardBuilt:Null<(cardId:CardId, result:BuilderResult, container:h2d.Object) -> Void>;

	// .manim element names (null = skip animation / use fallback)
	public var drawPathName:Null<String>;
	public var discardPathName:Null<String>;
	public var returnPathName:Null<String>;
	public var rearrangePathName:Null<String>;

	// Duration overrides (0 = use animatedPath's own duration)
	public var drawDuration:Float = 0;
	public var discardDuration:Float = 0;
	public var returnDuration:Float = 0;
	public var rearrangeDuration:Float = 0;

	/** When true, the system cursor is hidden while in targeting mode (arrow replaces cursor). */
	public var hideCursorWhileTargeting:Bool = false;

	// Scene graph
	final handContainer:h2d.Layers;
	final dragContainer:h2d.Layers; // Same local space as handContainer, higher z-layer for dragged cards
	final targeting:UICardHandTargeting;

	// Card state — uses entry references instead of indices to avoid stale-index bugs
	// after array mutations (splice/insert)
	var cards:Array<CardEntry> = [];
	var isDragging:Bool = false;
	var isTargeting:Bool = false;
	var hoveredEntry:Null<CardEntry> = null;
	var draggedEntry:Null<CardEntry> = null;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;
	var cursorX:Float = 0; // local (handContainer) space — for drag, threshold, arrow
	var cursorY:Float = 0;
	var sceneCursorX:Float = 0; // scene space — for interactive containsPoint
	var sceneCursorY:Float = 0;
	// Reused scratch buffer for scene->local conversions on mouse events. globalToLocal mutates
	// its input in place, so a single Point is safe to reuse across calls — avoids per-event GC.
	var scratchPoint:h2d.col.Point = new h2d.col.Point();
	var cardToCardTarget:Null<CardEntry> = null;
	var currentTargetId:Null<String> = null;
	var nextCardSeq:Int = 0;

	// Animations
	var activeAnimations:Array<ActiveAnimation> = [];

	// Callbacks

	/** Called when a card event occurs. */
	public var onCardEvent:Null<(event:CardHandEvent) -> Void> = null;

	/** Called before a card is played. Return false to cancel the play. */
	public var canPlayCard:Null<(cardId:CardId, target:TargetingResult) -> Bool> = null;

	/** Called before a card drag starts. Return false to prevent dragging. */
	public var canDragCard:Null<(cardId:CardId) -> Bool> = null;

	/** Custom animation override for card PLAY (drag-release that succeeds).
	 *  When set and returns true, replaces the default discard animation after a card is played.
	 *  The container is already reparented to dragContainer at (fromX, fromY).
	 *  You MUST call onDone() when the animation finishes to clean up the container.
	 *  Return false to fall through to the default discardPath animation. */
	public var customPlayAnimation:Null<(cardId:CardId, container:h2d.Object, fromX:Float, fromY:Float, onDone:() -> Void) -> Bool> = null;

	/** Custom animation override for card DISCARD via API (end-of-turn, forced discard).
	 *  When set and returns true, replaces the default discard animation.
	 *  You MUST call onDone() when the animation finishes to clean up the container.
	 *  Return false to fall through to the default discardPath animation. */
	public var customDiscardAnimation:Null<(cardId:CardId, container:h2d.Object, fromX:Float, fromY:Float, onDone:() -> Void) -> Bool> = null;

	public function new(screen:UIComponentHost, builder:MultiAnimBuilder, ?config:CardHandConfig) {
		this.screen = screen;
		this.builder = builder;
		this.interactiveHelper = new UIRichInteractiveHelper(screen);

		// Apply config with defaults
		layoutMode = config != null && config.layoutMode != null ? config.layoutMode : Fan;
		anchorX = config != null && config.anchorX != null ? config.anchorX : 640.0;
		anchorY = config != null && config.anchorY != null ? config.anchorY : 680.0;
		cardWidth = config != null && config.cardWidth != null ? config.cardWidth : 80.0;
		cardHeight = config != null && config.cardHeight != null ? config.cardHeight : 110.0;
		fanRadius = config != null && config.fanRadius != null ? config.fanRadius : 800.0;
		fanMaxAngle = config != null && config.fanMaxAngle != null ? config.fanMaxAngle : 40.0;
		linearSpacing = config != null && config.linearSpacing != null ? config.linearSpacing : 8.0;
		linearMaxWidth = config != null && config.linearMaxWidth != null ? config.linearMaxWidth : 600.0;
		hoverPopDistance = config != null && config.hoverPopDistance != null ? config.hoverPopDistance : 30.0;
		hoverScale = config != null && config.hoverScale != null ? config.hoverScale : 1.15;
		hoverNeighborSpread = config != null && config.hoverNeighborSpread != null ? config.hoverNeighborSpread : 20.0;
		targetingThresholdY = config != null && config.targetingThresholdY != null ? config.targetingThresholdY : 100.0;

		// Targeting zones: explicit zones override the legacy Y-threshold
		if (config != null && config.targetingZones != null) {
			targetingZones = config.targetingZones.copy();
		} else {
			targetingZones = [];
		}

		allowCardToCard = config != null && config.allowCardToCard != null ? config.allowCardToCard : false;
		cardToCardHighlightScale = config != null && config.cardToCardHighlightScale != null ? config.cardToCardHighlightScale : 1.1;
		cardToCardHoverPop = config != null && config.cardToCardHoverPop != null ? config.cardToCardHoverPop : false;
		cardToCardHoverScale = config != null && config.cardToCardHoverScale != null ? config.cardToCardHoverScale : false;
		cardToCardSpread = config != null && config.cardToCardSpread != null ? config.cardToCardSpread : false;
		drawPilePosition = config != null && config.drawPilePosition != null ? config.drawPilePosition : new FPoint(50, 680);
		discardPilePosition = config != null && config.discardPilePosition != null ? config.discardPilePosition : new FPoint(1230, 680);
		handLayer = config != null && config.handLayer != null ? config.handLayer : DefaultLayer;
		dragLayer = config != null && config.dragLayer != null ? config.dragLayer : ModalLayer;
		interactivePrefix = config != null && config.interactivePrefix != null ? config.interactivePrefix : "card";

		// Path layout
		layoutPathName = config != null ? config.layoutPathName : null;
		pathDistribution = config != null && config.pathDistribution != null ? config.pathDistribution : EvenArcLength;
		pathOrientation = config != null && config.pathOrientation != null ? config.pathOrientation : Tangent;

		// Card content customization
		onCardBuilt = config != null ? config.onCardBuilt : null;

		drawPathName = config != null ? config.drawPathName : null;
		discardPathName = config != null ? config.discardPathName : null;
		returnPathName = config != null ? config.returnPathName : null;
		rearrangePathName = config != null ? config.rearrangePathName : null;

		// Validate path names exist in the builder (fail-fast vs deferred error at animation time)
		validatePathName(drawPathName, "drawPathName");
		validatePathName(discardPathName, "discardPathName");
		validatePathName(returnPathName, "returnPathName");
		validatePathName(rearrangePathName, "rearrangePathName");

		// Scene graph — both containers are added via screen.addObjectToLayer so they
		// end up in the same coordinate space (important when inside tab contentRoot).
		// dragContainer uses a higher layer so dragged cards render above the hand.
		handContainer = new h2d.Layers();
		screen.addObjectToLayer(handContainer, handLayer);
		dragContainer = new h2d.Layers();
		screen.addObjectToLayer(dragContainer, dragLayer);

		var segName = config != null ? config.arrowSegmentName : null;
		var headName = config != null ? config.arrowHeadName : null;
		var arrowPath = config != null ? config.arrowPathName : null;
		var arrowSpacing = config != null && config.arrowSegmentSpacing != null ? config.arrowSegmentSpacing : 25.0;
		targeting = new UICardHandTargeting(builder, segName, headName, arrowPath, arrowSpacing);
		// Targeting line goes into dragContainer so it shares the same local space
		dragContainer.addChild(targeting.getObject());
	}

	// === Public API: Card Management ===

	/** Set the full hand contents. Rebuilds all card visuals instantly (no animation). */
	public function setHand(descriptors:Array<CardDescriptor>):Void {
		clearHand();
		for (desc in descriptors) {
			var entry = buildCardEntry(desc);
			cards.push(entry);
			addToHandLayer(entry);
		}
		applyLayout(false);
	}

	/** Add a card to the hand with draw animation from the draw pile position.
	 *  The draw animation tracks the card's final layout position — if other cards
	 *  are drawn/discarded during the animation, the endpoint updates dynamically. */
	public function drawCard(descriptor:CardDescriptor, insertIndex:Int = -1):Void {
		var entry = buildCardEntry(descriptor);
		entry.state = Animating;

		if (insertIndex < 0 || insertIndex >= cards.length)
			cards.push(entry)
		else
			cards.insert(insertIndex, entry);
		addToHandLayer(entry);

		// Compute layout so entry.layoutPos is set for all cards (including the new one)
		var positions = computeLayout(-1);
		var targetIdx = cards.indexOf(entry);
		for (i in 0...cards.length)
			if (i < positions.length)
				cards[i].layoutPos = positions[i];

		// Position new card at draw pile
		entry.container.setPosition(drawPilePosition.x, drawPilePosition.y);
		entry.container.rotation = 0;

		// Animate using a tracking draw animation that re-stretches toward layoutPos each frame
		if (targetIdx >= 0 && targetIdx < positions.length) {
			animateCardToTracking(entry, new FPoint(drawPilePosition.x, drawPilePosition.y), 0,
				positions[targetIdx].rotation, drawPathName, () -> {
					resolveAnimationComplete(entry);
					entry.container.scaleX = entry.layoutPos.scale;
					entry.container.scaleY = entry.layoutPos.scale;
					emitEvent(DrawAnimComplete(descriptor.id));
					// Final layout pass to ensure position is exact
					applyLayout(true);
				});
		}

		// Rearrange existing cards to make room
		rearrangeCards(positions, targetIdx);
	}

	/** Remove a card from hand with discard animation. */
	public function discardCard(cardId:CardId):Void {
		var idx = findCardIndex(cardId);
		if (idx < 0)
			return;

		var entry = cards[idx];

		// Cancel drag if this card is being dragged
		if (draggedEntry == entry)
			cancelDrag();

		// Clear references to this card
		if (hoveredEntry == entry) {
			emitEvent(CardHoverEnd(entry.descriptor.id));
			hoveredEntry = null;
		}
		if (cardToCardTarget == entry)
			cardToCardTarget = null;

		entry.state = Animating;

		// Unregister interactive + screen wrapper + rebuild listener
		unregisterCardEntry(entry);

		cards.splice(idx, 1);

		var fromPos = new FPoint(entry.container.x, entry.container.y);
		if (customDiscardAnimation != null && customDiscardAnimation(cardId, entry.container, fromPos.x, fromPos.y, () -> {
			entry.container.remove();
			emitEvent(DiscardAnimComplete(cardId));
		})) {
			// Custom discard animation took over
		} else {
			animateCardTo(entry, fromPos, discardPilePosition, entry.container.rotation, 0, discardPathName, () -> {
				entry.container.remove();
				emitEvent(DiscardAnimComplete(cardId));
			});
		}

		// Rearrange remaining cards
		var positions = computeLayout(-1);
		rearrangeCards(positions, -1);
	}

	/** Update parameters on an existing card's programmable (incremental). */
	public function updateCardParams(cardId:CardId, params:Map<String, Dynamic>):Void {
		var idx = findCardIndex(cardId);
		if (idx < 0)
			return;
		for (key => value in params)
			cards[idx].result.setParameter(key, value);
	}

	/** Enable or disable a card. Uses UIRichInteractiveHelper.setDisabled for proper state. */
	public function setCardEnabled(cardId:CardId, enabled:Bool):Void {
		var idx = findCardIndex(cardId);
		if (idx < 0)
			return;
		var entry = cards[idx];

		// Cancel drag if disabling the dragged card
		if (!enabled && draggedEntry == entry)
			cancelDrag();

		// During animation or disabled-while-animating: defer state changes
		if (entry.state == Animating) {
			if (!enabled) {
				entry.state = Disabled;
				entry.enableAfterAnimation = false;
			} else {
				// Already animating and enabled — no state change needed
				entry.enableAfterAnimation = false;
			}
		} else if (entry.state == Disabled && isAnimatingEntry(entry)) {
			// Card was disabled mid-animation; re-enabling defers to onComplete
			entry.enableAfterAnimation = enabled;
		} else {
			entry.state = if (enabled) InHand else Disabled;
			entry.enableAfterAnimation = false;
		}

		interactiveHelper.setDisabled(entry.interactiveId, !enabled);
	}

	/** Get the number of cards in hand. */
	public function getCardCount():Int {
		return cards.length;
	}

	/** Get card IDs in current hand order. */
	public function getCardIds():Array<CardId> {
		return [for (entry in cards) entry.descriptor.id];
	}

	/** Hit-test hand cards at scene coordinates. Returns the card ID under the point, or null.
	 *  Uses base layout positions (no hover pop) for consistent detection. */
	public function getCardIdAtPosition(sceneX:Float, sceneY:Float):Null<CardId> {
		scratchPoint.x = sceneX;
		scratchPoint.y = sceneY;
		var local = handContainer.globalToLocal(scratchPoint);
		var entry = getCardAtBasePosition(local.x, local.y);
		return entry != null ? entry.descriptor.id : null;
	}

	/** Get the BuilderResult for a card (for direct parameter/slot access). */
	public function getCardResult(cardId:CardId):Null<BuilderResult> {
		var idx = findCardIndex(cardId);
		if (idx < 0)
			return null;
		return cards[idx].result;
	}

	/** Find card ID by interactive ID. Returns null if no card owns this interactive. */
	public function findCardIdByInteractiveId(interactiveId:String):Null<CardId> {
		var entry = findCardByInteractiveId(interactiveId);
		return entry != null ? entry.descriptor.id : null;
	}

	/** Check if a card is currently in hand (not animating, disabled, or dragging). */
	public function isCardInHand(cardId:CardId):Bool {
		var idx = findCardIndex(cardId);
		if (idx < 0)
			return false;
		return cards[idx].state == InHand || cards[idx].state == Hovered;
	}

	// === Public API: Targeting ===

	/** Register a single target interactive wrapper. */
	public function registerTargetInteractive(wrapper:UIInteractiveWrapper):Void {
		targeting.registerTarget(wrapper);
	}

	/** Register multiple target interactive wrappers (batch). */
	public function registerTargetInteractives(wrappers:Array<UIInteractiveWrapper>):Void {
		targeting.registerTargets(wrappers);
	}

	/** Unregister a target by its interactive id. */
	public function unregisterTargetInteractive(id:String):Void {
		targeting.unregisterTarget(id);
	}

	/** Set callback for target highlight state changes. Includes metadata for programmatic updates. */
	public function setTargetHighlightCallback(cb:TargetHighlightCallback):Void {
		targeting.onTargetHighlight = cb;
	}

	/** Set filter callback to determine which targets accept which cards. */
	public function setTargetAcceptsFilter(cb:TargetAcceptsCallback):Void {
		targeting.acceptsFilter = cb;
	}

	// === Public API: Targeting Zones ===

	/** Add a targeting zone. When the cursor enters any zone during drag, targeting mode activates.
	 *  Coordinates are in handContainer's local space. */
	public function addTargetingZone(zone:TargetingZone):Void {
		// Replace existing zone with same id
		for (i in 0...targetingZones.length) {
			if (targetingZones[i].id == zone.id) {
				targetingZones[i] = zone;
				return;
			}
		}
		targetingZones.push(zone);
	}

	/** Remove a targeting zone by id. */
	public function removeTargetingZone(id:String):Void {
		var i = 0;
		while (i < targetingZones.length) {
			if (targetingZones[i].id == id) {
				targetingZones.splice(i, 1);
				return;
			}
			i++;
		}
	}

	/** Remove all targeting zones. Falls back to legacy Y-threshold behavior. */
	public function clearTargetingZones():Void {
		targetingZones = [];
	}

	// === Public API: Configuration ===

	/** Enable or disable the targeting arrow visual (target detection still works). */
	public function setArrowVisible(visible:Bool):Void {
		targeting.arrowEnabled = visible;
	}

	/** Enable or disable arrow snap-to-target (arrow endpoint locks to target center by default). */
	public function setArrowSnap(snap:Bool):Void {
		targeting.snapToTarget = snap;
	}

	/** Set a custom arrow snap point provider. The callback receives the target wrapper and returns
	 *  a point in the target's local space. When null (default), arrow snaps to interactive center.
	 *  Example: snap to top-center of a 48x48 hex cell: `(w) -> new FPoint(24, 0)` */
	public function setArrowSnapPointProvider(provider:Null<(UIInteractiveWrapper) -> FPoint>):Void {
		targeting.arrowSnapPointProvider = provider;
	}

	/** Get the underlying targeting instance for direct access (e.g., sharing targets
	 *  with other targeting systems like reactor click-to-target). */
	public function getTargeting():UICardHandTargeting {
		return targeting;
	}

	/** Get the targeting arrow's scene object for reparenting into a grid layer hierarchy.
	 *  Use with `grid.addExternalObject(cardHand.getTargetingObject(), zOrder)` to control
	 *  arrow z-ordering relative to grid layers. */
	public function getTargetingObject():h2d.Object {
		return targeting.getObject();
	}

	/** Show or hide the entire card hand (hand container + targeting arrow). */
	public function setVisible(visible:Bool):Void {
		handContainer.visible = visible;
		targeting.getObject().visible = visible;
	}

	/** Update anchor position (e.g., on screen resize). */
	public function setAnchor(x:Float, y:Float):Void {
		anchorX = x;
		anchorY = y;
		applyLayout(false);
	}

	/** Invalidate cached layout path (for hot-reload when .manim paths change). */
	public function invalidateLayoutCache():Void {
		resolvedPath = null;
	}

	// === Event Routing ===

	/** Handle screen events (UIInteractiveEvent from card interactives).
	 *  Call from screen's `onScreenEvent`. Returns true if consumed.
	 *  Note: hover detection is handled by position-based logic in `onMouseMove`,
	 *  not by Interactive UIEntering/UILeaving events. This avoids z-order issues
	 *  when the hovered card is brought to the top layer for rendering. */
	public function handleScreenEvent(event:UIScreenEvent):Bool {
		switch event {
			case UIInteractiveEvent(innerEvent, id, meta):
				var entry = findCardByInteractiveId(id);
				if (entry == null)
					return false;

				switch innerEvent {
					case UIPush:
						if (!isDragging)
							return startDragFromInteractive(entry);
					default:
				}
				return false;
			default:
				return false;
		}
	}

	/** Handle mouse move for drag tracking. Call from screen's mouse handling.
	 *  Coordinates are in scene space — automatically converted to handContainer's local space
	 *  so targeting, drag offsets, and bounds checks work correctly when the hand is inside
	 *  a tab panel or other offset container. */
	public function onMouseMove(screenX:Float, screenY:Float):Bool {
		sceneCursorX = screenX;
		sceneCursorY = screenY;
		scratchPoint.x = screenX;
		scratchPoint.y = screenY;
		var local = handContainer.globalToLocal(scratchPoint);
		cursorX = local.x;
		cursorY = local.y;

		if (isDragging) {
			updateDrag();
			return true;
		}

		// Position-based hover detection using base layout (no hover pop) so the
		// popped/scaled hovered card doesn't block neighbor detection
		var hit = getCardAtBasePosition(cursorX, cursorY);
		if (hit != hoveredEntry)
			setHoveredEntry(hit);

		return hoveredEntry != null;
	}

	/** Handle mouse release for ending drags. Call from screen's mouse handling. */
	public function onMouseRelease(screenX:Float, screenY:Float):Bool {
		sceneCursorX = screenX;
		sceneCursorY = screenY;
		scratchPoint.x = screenX;
		scratchPoint.y = screenY;
		var local = handContainer.globalToLocal(scratchPoint);
		cursorX = local.x;
		cursorY = local.y;

		if (isDragging)
			return endDrag();

		return false;
	}

	/** Route mouse click events. Card hand does not consume raw click events. */
	public function onMouseClick(sceneX:Float, sceneY:Float, button:Int):Bool {
		return false;
	}

	/** Update animations. Call from screen's update(dt). */
	public function update(dt:Float):Void {
		if (activeAnimations.length == 0)
			return;
		var i = activeAnimations.length - 1;
		while (i >= 0) {
			var anim = activeAnimations[i];
			if (anim == null) {
				i--;
				continue;
			}
			var state = anim.anim.update(dt);
			var rate = state.rate;

			if (anim.trackingFrom != null) {
				// Tracking draw animation: re-stretch raw position toward current layoutPos each frame
				var from = anim.trackingFrom;
				var target = anim.entry.layoutPos;
				var rawEp = anim.rawEndpoint;
				var rawDist = Math.sqrt(rawEp.x * rawEp.x + rawEp.y * rawEp.y);
				if (rawDist < 1e-10) {
					// Degenerate path — lerp directly
					anim.entry.container.setPosition(
						from.x + (target.x - from.x) * rate,
						from.y + (target.y - from.y) * rate
					);
				} else {
					var targetDist = Math.sqrt((target.x - from.x) * (target.x - from.x) + (target.y - from.y) * (target.y - from.y));
					var targetAngle = Math.atan2(target.y - from.y, target.x - from.x);
					var rawAngle = Math.atan2(rawEp.y, rawEp.x);
					var rotation = targetAngle - rawAngle;
					var scale = targetDist / rawDist;
					var cosR = Math.cos(rotation);
					var sinR = Math.sin(rotation);
					// Transform raw path point: rotate, scale, translate to from
					var rx = state.position.x;
					var ry = state.position.y;
					anim.entry.container.setPosition(
						from.x + (rx * cosR - ry * sinR) * scale,
						from.y + (rx * sinR + ry * cosR) * scale
					);
				}
			} else {
				anim.entry.container.setPosition(state.position.x, state.position.y);
			}

			// Interpolate rotation alongside path (tracking anims use dynamic end rotation from layoutPos)
			var effectiveEndRotation = if (anim.trackingFrom != null) anim.entry.layoutPos.rotation else anim.endRotation;
			anim.entry.container.rotation = anim.startRotation + (effectiveEndRotation - anim.startRotation) * rate + state.rotation;

			// Apply scale/alpha from animated path curves (defined in .manim)
			anim.entry.container.scaleX = state.scale;
			anim.entry.container.scaleY = state.scale;
			anim.entry.container.alpha = state.alpha;

			if (state.done) {
				activeAnimations.splice(i, 1);
				anim.onComplete();
			}
			i--;
		}
	}

	/** Get the hand container. Note: CardHand also has a dragContainer at a higher layer. */
	public function getObject():h2d.Object {
		return handContainer;
	}

	/** Clean up all resources. */
	public function dispose():Void {
		clearHand();
		chainedListeners.resize(0);
		handContainer.remove();
		dragContainer.remove();
		targeting.clearTargets();
		interactiveHelper.unbindAll();
	}

	// === Internal: Card building ===

	function buildCardEntry(descriptor:CardDescriptor):CardEntry {
		var result = builder.buildWithParameters(descriptor.buildName, descriptor.params, null, null, true);

		// Container is not parented here — caller adds it to handContainer (h2d.Layers)
		// at the correct layer index to maintain proper z-ordering
		var container = new h2d.Object();
		// Use a wrapper for centering so incremental updates can't overwrite the offset
		var pivotWrapper = new h2d.Object(container);
		pivotWrapper.setPosition(-cardWidth / 2.0, -cardHeight / 2.0);
		pivotWrapper.addChild(result.object);

		// Generate unique interactive ID and register with screen
		var interactiveId = '${interactivePrefix}_${nextCardSeq}';
		nextCardSeq++;

		// Register interactives from the card's BuilderResult
		screen.addInteractives(result, interactiveId);

		// Auto-wire hover/press state via UIRichInteractiveHelper
		interactiveHelper.register(result, interactiveId);

		var entry = new CardEntry(descriptor, result, container, interactiveId);

		// Install rebuild listener so the card hand's private `interactiveHelper` resyncs its
		// bindings when the card's BuilderResult rebuilds (e.g. `@switch` arm flip inside the
		// card's programmable). The screen's own resync listener is separately installed by
		// `screen.addInteractives` above. Skip on non-incremental results — those can't rebuild.
		if (result.isIncremental) {
			final capturedEntry = entry;
			final listener = () -> interactiveHelper.resync(capturedEntry.result, capturedEntry.interactiveId);
			result.addRebuildListener(listener);
			entry.rebuildListener = listener;
		}

		// Apply disabled state
		var enabled = descriptor.enabled != null ? descriptor.enabled : true;
		if (!enabled) {
			entry.state = Disabled;
			interactiveHelper.setDisabled(interactiveId, true);
		}

		// Allow game code to customize the card (add buttons, slots, custom content)
		if (onCardBuilt != null)
			onCardBuilt(descriptor.id, result, container);

		return entry;
	}

	/** Tear down all screen / helper / rebuild-listener bookkeeping for a card. Used by every
	 *  removal site (discard, hand clear, play). Does NOT remove the card from `cards` or touch
	 *  the scene graph — callers handle those site-specific steps around this call. */
	function unregisterCardEntry(entry:CardEntry):Void {
		interactiveHelper.unbind(entry.interactiveId);
		screen.removeInteractives(entry.interactiveId);
		if (entry.rebuildListener != null) {
			entry.result.removeRebuildListener(entry.rebuildListener);
			entry.rebuildListener = null;
		}
	}

	function clearHand():Void {
		if (isTargeting) {
			if (hideCursorWhileTargeting)
				hxd.System.setCursor(Default);
			// Hide the arrow visual and clear any lingering target highlight — otherwise
			// the arrow stays visible and `activeTargetId` outlives the cards it tracked.
			targeting.clearLine();
		}
		for (entry in cards) {
			unregisterCardEntry(entry);
			entry.container.remove();
		}
		cards = [];
		activeAnimations = [];
		hoveredEntry = null;
		draggedEntry = null;
		isDragging = false;
		isTargeting = false;
	}

	// === Internal: Layout ===

	function computeLayout(hoverIdx:Int):Array<CardLayoutPosition> {
		switch (layoutMode) {
			case Fan:
				// Convert pixel spread to degrees via arc: degrees = pixels / radius * (180/PI)
				var spreadDeg = if (fanRadius > 0) hoverNeighborSpread / fanRadius * (180.0 / Math.PI) else hoverNeighborSpread;
				return UICardHandLayout.computeFanLayout(cards.length, anchorX, anchorY, fanRadius, fanMaxAngle, hoverIdx, hoverPopDistance,
					hoverScale, spreadDeg);
			case Linear:
				return UICardHandLayout.computeLinearLayout(cards.length, anchorX, anchorY, cardWidth, linearSpacing, linearMaxWidth, hoverIdx,
					hoverPopDistance, hoverScale, hoverNeighborSpread);
			case PathLayout:
				// Convert pixel spread to rate: 20px → ~0.05 rate (path is typically ~400px)
				var spreadRate = hoverNeighborSpread * 0.0025;
				var positions = UICardHandLayout.computePathLayout(cards.length, getLayoutPath(), pathDistribution, pathOrientation, hoverIdx,
					hoverPopDistance, hoverScale, spreadRate);
				// Offset path-local coordinates by anchor so path (0,0) maps to (anchorX, anchorY)
				for (pos in positions) {
					pos.x += anchorX;
					pos.y += anchorY;
				}
				return positions;
		}
	}

	function getLayoutPath():Path {
		if (resolvedPath == null) {
			if (layoutPathName == null)
				throw "PathLayout mode requires layoutPathName in config";
			resolvedPath = builder.getPaths().getPath(layoutPathName);
		}
		return resolvedPath;
	}

	function applyLayout(animated:Bool):Void {
		var hoverIdx = if (hoveredEntry != null) cards.indexOf(hoveredEntry) else -1;
		var positions = computeLayout(hoverIdx);

		for (i in 0...cards.length) {
			if (i >= positions.length)
				break;
			var entry = cards[i];
			var pos = positions[i];
			entry.layoutPos = pos;

			if (entry.state == Dragging || entry.state == Targeting)
				continue;

			if (animated && entry.state == InHand) {
				animateCardTo(entry, new FPoint(entry.container.x, entry.container.y), new FPoint(pos.x, pos.y), entry.container.rotation,
					pos.rotation, rearrangePathName, () -> {});
			} else if (entry.state != Animating) {
				// Cancel any lingering rearrange animation so it doesn't override this instant position
				removeAnimationsForEntry(entry);
				entry.container.setPosition(pos.x, pos.y);
				entry.container.rotation = pos.rotation;
				entry.container.scaleX = pos.scale;
				entry.container.scaleY = pos.scale;
			}
		}
	}

	function rearrangeCards(positions:Array<CardLayoutPosition>, skipIndex:Int):Void {
		for (i in 0...cards.length) {
			if (i == skipIndex || i >= positions.length)
				continue;
			var entry = cards[i];
			if (entry.state == Dragging || entry.state == Targeting || entry.state == Animating)
				continue;

			var pos = positions[i];
			entry.layoutPos = pos;
			animateCardTo(entry, new FPoint(entry.container.x, entry.container.y), new FPoint(pos.x, pos.y), entry.container.rotation,
				pos.rotation, rearrangePathName, () -> {
					resolveAnimationComplete(entry);
					entry.container.scaleX = pos.scale;
					entry.container.scaleY = pos.scale;
				});
		}
	}

	// === Internal: Hover ===

	function setHoveredEntry(entry:Null<CardEntry>):Void {
		if (entry == hoveredEntry)
			return;

		// Un-hover old
		if (hoveredEntry != null) {
			if (hoveredEntry.state == Hovered) {
				hoveredEntry.state = InHand;
				interactiveHelper.resetState(hoveredEntry.interactiveId); // Visual: normal
				addToHandLayer(hoveredEntry); // Restore z-order
				emitEvent(CardHoverEnd(hoveredEntry.descriptor.id));
			}
		}

		hoveredEntry = entry;

		// Hover new
		if (hoveredEntry != null) {
			if (hoveredEntry.state == InHand) {
				hoveredEntry.state = Hovered;
				interactiveHelper.setHoverState(hoveredEntry.interactiveId); // Visual: hover
				handContainer.add(hoveredEntry.container, cards.length); // Bring to top
				emitEvent(CardHoverStart(hoveredEntry.descriptor.id));
			}
		}

		applyLayout(true);
	}

	// === Internal: Drag ===

	function startDragFromInteractive(entry:CardEntry):Bool {
		if (isDragging)
			return false;

		if (entry.state == Disabled || entry.state == Animating)
			return false;

		if (canDragCard != null && !canDragCard(entry.descriptor.id))
			return false;

		draggedEntry = entry;
		dragOffsetX = entry.container.x - cursorX;
		dragOffsetY = entry.container.y - cursorY;

		entry.state = Dragging;
		// Reset "pressed" visual state — drag doesn't need pressed appearance
		interactiveHelper.resetState(entry.interactiveId);
		entry.container.rotation = 0;

		// Reparent to drag container (same local space, higher z-layer)
		dragContainer.addChild(entry.container);

		isDragging = true;
		hoveredEntry = null;
		emitEvent(CardDragStart(entry.descriptor.id));

		applyLayout(true);
		return true;
	}

	/** Restore visual effects applied by applyCardToCardEffects(). */
	function restoreCardToCardEffects():Void {
		if (cardToCardTarget == null)
			return;
		// Restore target scale + z-order
		cardToCardTarget.container.scaleX = cardToCardTarget.layoutPos.scale;
		cardToCardTarget.container.scaleY = cardToCardTarget.layoutPos.scale;
		addToHandLayer(cardToCardTarget);
		// Restore target position if pop was applied
		if (cardToCardHoverPop) {
			cardToCardTarget.container.setPosition(cardToCardTarget.layoutPos.x, cardToCardTarget.layoutPos.y);
			cardToCardTarget.container.rotation = cardToCardTarget.layoutPos.rotation;
		}
		// Restore neighbor positions if spread was applied
		if (cardToCardSpread) {
			for (entry in cards) {
				if (entry.state == Dragging || entry.state == Targeting || entry.state == Animating)
					continue;
				if (entry == cardToCardTarget)
					continue;
				entry.container.setPosition(entry.layoutPos.x, entry.layoutPos.y);
				entry.container.rotation = entry.layoutPos.rotation;
				entry.container.scaleX = entry.layoutPos.scale;
				entry.container.scaleY = entry.layoutPos.scale;
			}
		}
	}

	/** Apply hover-like effects to the current card-to-card target. */
	function applyCardToCardEffects():Void {
		if (cardToCardTarget == null)
			return;
		var targetIdx = cards.indexOf(cardToCardTarget);
		if (targetIdx < 0)
			return;

		if (cardToCardSpread || cardToCardHoverPop) {
			var hoverPositions = computeLayout(targetIdx);
			// Spread: move neighbors
			if (cardToCardSpread) {
				for (i in 0...cards.length) {
					if (i >= hoverPositions.length)
						break;
					var entry = cards[i];
					if (entry.state == Dragging || entry.state == Targeting || entry.state == Animating)
						continue;
					if (i == targetIdx)
						continue;
					entry.container.setPosition(hoverPositions[i].x, hoverPositions[i].y);
					entry.container.rotation = hoverPositions[i].rotation;
					entry.container.scaleX = hoverPositions[i].scale;
					entry.container.scaleY = hoverPositions[i].scale;
				}
			}
			// Pop: offset target position
			if (cardToCardHoverPop) {
				cardToCardTarget.container.setPosition(hoverPositions[targetIdx].x, hoverPositions[targetIdx].y);
				cardToCardTarget.container.rotation = hoverPositions[targetIdx].rotation;
			}
			// Scale: hoverScale or cardToCardHighlightScale
			var scale = if (cardToCardHoverScale) hoverPositions[targetIdx].scale else cardToCardTarget.layoutPos.scale * cardToCardHighlightScale;
			cardToCardTarget.container.scaleX = scale;
			cardToCardTarget.container.scaleY = scale;
		} else {
			// Only scale (existing behavior, possibly with hoverScale)
			var scale = if (cardToCardHoverScale) hoverScale else cardToCardTarget.layoutPos.scale * cardToCardHighlightScale;
			cardToCardTarget.container.scaleX = scale;
			cardToCardTarget.container.scaleY = scale;
		}

		// Z-order: bring to top
		handContainer.add(cardToCardTarget.container, cards.length);
	}

	function updateDrag():Void {
		if (draggedEntry == null)
			return;

		var entry = draggedEntry;

		// Priority 1: Card-to-card
		if (allowCardToCard) {
			var targetEntry = getCardAtPosition(cursorX, cursorY, entry);
			if (targetEntry != cardToCardTarget) {
				restoreCardToCardEffects();
				cardToCardTarget = targetEntry;
				applyCardToCardEffects();
			}
			if (cardToCardTarget != null) {
				entry.container.setPosition(cursorX + dragOffsetX, cursorY + dragOffsetY);
				if (isTargeting) {
					targeting.clearLine();
					exitTargetingMode(entry);
				}
				return;
			}
		}

		// Priority 2: Targeting zones / threshold (only when arrow enabled AND card supports targeting)
		var cardCanTarget = entry.descriptor.canTarget != null ? entry.descriptor.canTarget : true;
		if (targeting.arrowEnabled && cardCanTarget && isInTargetingZone(cursorX, cursorY)) {
			if (!isTargeting)
				enterTargetingMode(entry);
			// Card stays at hand position, arrow points from card to cursor
			var originX = entry.layoutPos.x + entry.layoutPos.normalX * hoverPopDistance;
			var originY = entry.layoutPos.y + entry.layoutPos.normalY * hoverPopDistance;
			currentTargetId = targeting.updateTargetingLine(originX, originY, cursorX, cursorY, sceneCursorX, sceneCursorY, entry.descriptor.id);
		} else {
			// Normal drag — card follows cursor
			entry.container.setPosition(cursorX + dragOffsetX, cursorY + dragOffsetY);
			if (isTargeting) {
				targeting.clearLine();
				exitTargetingMode(entry);
				currentTargetId = null;
			}
			// Highlight targets under cursor during normal drag (no arrow)
			if (!targeting.arrowEnabled || !cardCanTarget)
				currentTargetId = targeting.updateHighlight(sceneCursorX, sceneCursorY, entry.descriptor.id);
		}
		// Override the arrow's valid color via canPlayCard check, so the player
		// gets immediate red feedback over invalid targets (e.g. unboardable
		// tiles for shuttle cards). null = use default hover detection.
		if (canPlayCard != null && draggedEntry != null) {
			var result:TargetingResult = currentTargetId != null ? TargetZone(currentTargetId) : NoTarget;
			targeting.forceValid = canPlayCard(draggedEntry.descriptor.id, result);
		} else {
			targeting.forceValid = null;
		}
	}

	function enterTargetingMode(entry:CardEntry):Void {
		isTargeting = true;
		entry.state = Targeting;
		// Snap card back to hand position (raised) — reparent to correct layer in handContainer
		addToHandLayer(entry);
		entry.container.setPosition(entry.layoutPos.x + entry.layoutPos.normalX * hoverPopDistance,
			entry.layoutPos.y + entry.layoutPos.normalY * hoverPopDistance);
		entry.container.rotation = entry.layoutPos.rotation;
		entry.container.scaleX = hoverScale;
		entry.container.scaleY = hoverScale;
		// Arrow is already in dragContainer — no reparenting needed
		if (hideCursorWhileTargeting)
			hxd.System.setCursor(Hide);
	}

	function exitTargetingMode(entry:CardEntry):Void {
		isTargeting = false;
		entry.state = Dragging;
		// Reparent card back to drag container
		dragContainer.addChild(entry.container);
		entry.container.rotation = 0;
		if (hideCursorWhileTargeting)
			hxd.System.setCursor(Default);
	}

	function endDrag():Bool {
		if (draggedEntry == null)
			return false;

		var entry = draggedEntry;
		var cardId = entry.descriptor.id;

		var wasTargeting = isTargeting;
		targeting.clearLine();
		entry.container.alpha = 1.0;
		if (wasTargeting && hideCursorWhileTargeting)
			hxd.System.setCursor(Default);

		// Un-highlight card-to-card target
		restoreCardToCardEffects();

		var result:TargetingResult = NoTarget;
		var cardPlayed = false;

		if (cardToCardTarget != null) {
			var targetId = cardToCardTarget.descriptor.id;
			var canCombine = entry.descriptor.canCombineWith;
			if (canCombine == null || canCombine(targetId)) {
				emitEvent(CardCombined(cardId, targetId));
				cardPlayed = true;
			}
		} else if (wasTargeting) {
			result = if (currentTargetId != null) TargetZone(currentTargetId) else NoTarget;
			if (canPlayCard == null || canPlayCard(cardId, result)) {
				emitEvent(CardPlayed(cardId, result));
				cardPlayed = true;
			}
		} else {
			// Direct drag mode (arrow disabled or card canTarget=false) — check drop target or threshold
			var dropTarget = targeting.hitTestTargets(sceneCursorX, sceneCursorY, cardId);
			if (dropTarget != null) {
				result = TargetZone(dropTarget);
				if (canPlayCard == null || canPlayCard(cardId, result)) {
					emitEvent(CardPlayed(cardId, result));
					cardPlayed = true;
				}
			} else if (isInTargetingZone(cursorX, cursorY)) {
				// Card dragged past threshold without a specific target — play with NoTarget
				result = NoTarget;
				if (canPlayCard == null || canPlayCard(cardId, result)) {
					emitEvent(CardPlayed(cardId, result));
					cardPlayed = true;
				}
			}
		}

		cardToCardTarget = null;
		currentTargetId = null;
		draggedEntry = null;
		isDragging = false;
		isTargeting = false;

		emitEvent(CardDragEnd(cardId));

		if (cardPlayed) {
			entry.state = Animating;
			unregisterCardEntry(entry);
			var spliceIdx = cards.indexOf(entry);
			if (spliceIdx >= 0)
				cards.splice(spliceIdx, 1);

			// Move card to drag container for discard animation (same local space)
			dragContainer.addChild(entry.container);

			var fromPos = new FPoint(entry.container.x, entry.container.y);
			if (customPlayAnimation != null && customPlayAnimation(cardId, entry.container, fromPos.x, fromPos.y, () -> {
				entry.container.remove();
			})) {
				// Custom play animation took over
			} else {
				animateCardTo(entry, fromPos, discardPilePosition, 0, 0, discardPathName, () -> {
					entry.container.remove();
				});
			}
			applyLayout(true);
		} else {
			// Return to hand
			entry.state = Animating;
			if (!wasTargeting) {
				// Card was on drag layer — move back to correct layer (preserves z-order)
				addToHandLayer(entry);
			}
			// If wasTargeting, card is already in handContainer from enterTargetingMode

			var targetPos = entry.layoutPos;
			animateCardTo(entry, new FPoint(entry.container.x, entry.container.y), new FPoint(targetPos.x, targetPos.y),
				entry.container.rotation, targetPos.rotation, returnPathName, () -> {
					resolveAnimationComplete(entry);
					entry.container.scaleX = targetPos.scale;
					entry.container.scaleY = targetPos.scale;
					interactiveHelper.resetState(entry.interactiveId);
				});
		}

		return true;
	}

	/** Force-cancel any active drag without emitting play/combine events. Reparents card to hand. */
	function cancelDrag():Void {
		if (!isDragging || draggedEntry == null)
			return;

		var entry = draggedEntry;

		targeting.clearLine();
		if (isTargeting && hideCursorWhileTargeting)
			hxd.System.setCursor(Default);

		// Un-highlight card-to-card target
		restoreCardToCardEffects();
		cardToCardTarget = null;

		currentTargetId = null;
		isDragging = false;
		isTargeting = false;
		draggedEntry = null;
		entry.container.alpha = 1.0;

		// Reparent to correct layer (preserves z-order)
		addToHandLayer(entry);

		emitEvent(CardDragEnd(entry.descriptor.id));
	}

	// === Internal: Hit testing ===

	/** Hit-test using base layout (hoverIdx=-1) for hover detection.
	 *  Uses nearest-center selection: among all cards whose OBB contains the cursor,
	 *  the one with the closest center wins. This prevents the popped/scaled hovered
	 *  card from blocking neighbors and handles tightly stacked/overlapping cards
	 *  where multiple bounding boxes cover the same point. */
	function getCardAtBasePosition(x:Float, y:Float):Null<CardEntry> {
		var basePositions = computeLayout(-1);
		var bestEntry:Null<CardEntry> = null;
		var bestDistSq = Math.POSITIVE_INFINITY;

		for (i in 0...cards.length) {
			var entry = cards[i];
			if (i >= basePositions.length || entry.state == Animating || entry.state == Disabled)
				continue;

			var pos = basePositions[i];
			var halfW = cardWidth * pos.scale / 2.0;
			var halfH = cardHeight * pos.scale / 2.0;

			var dx = x - pos.x;
			var dy = y - pos.y;
			var cos = Math.cos(-pos.rotation);
			var sin = Math.sin(-pos.rotation);
			var localX = dx * cos - dy * sin;
			var localY = dx * sin + dy * cos;

			if (localX < -halfW || localX > halfW || localY < -halfH || localY > halfH)
				continue;

			// Among overlapping cards, pick nearest center
			var distSq = dx * dx + dy * dy;
			if (distSq < bestDistSq) {
				bestDistSq = distSq;
				bestEntry = entry;
			}
		}
		return bestEntry;
	}

	function getCardAtPosition(x:Float, y:Float, ?skipEntry:CardEntry):Null<CardEntry> {
		var i = cards.length - 1;
		while (i >= 0) {
			var entry = cards[i];
			if (entry == skipEntry) {
				i--;
				continue;
			}
			if (entry.state == Animating || entry.state == Disabled) {
				i--;
				continue;
			}

			var pos = entry.layoutPos;
			var halfW = cardWidth * pos.scale / 2.0;
			var halfH = cardHeight * pos.scale / 2.0;

			// Inverse rotation for fan layout
			var dx = x - pos.x;
			var dy = y - pos.y;
			var cos = Math.cos(-pos.rotation);
			var sin = Math.sin(-pos.rotation);
			var localX = dx * cos - dy * sin;
			var localY = dx * sin + dy * cos;

			if (localX >= -halfW && localX <= halfW && localY >= -halfH && localY <= halfH)
				return entry;
			i--;
		}
		return null;
	}

	function validatePathName(name:Null<String>, configField:String):Void {
		if (name != null && !builder.hasNode(name))
			throw 'CardHandHelper: ${configField} "${name}" not found in .manim';
	}

	// === Internal: Animation via .manim paths ===

	function animateCardTo(entry:CardEntry, from:FPoint, to:FPoint, startRotation:Float, endRotation:Float, pathName:Null<String>,
			onComplete:() -> Void):Void {
		// Remove any existing animation for this entry
		removeAnimationsForEntry(entry);

		var dx = to.x - from.x;
		var dy = to.y - from.y;
		// Snap if positions are close — avoids degenerate Stretch-normalized paths
		// that produce NaN when from≈to (e.g. quick click-release)
		if (dx * dx + dy * dy < 1.0) {
			entry.container.setPosition(to.x, to.y);
			entry.container.rotation = endRotation;
			onComplete();
			return;
		}

		if (pathName != null) {
			// Use .manim animatedPath with Stretch normalization
			var ap = builder.createProjectilePath(pathName, from, to);
			// Apply duration override if set
			var durationOv = getDurationOverride(pathName);
			if (durationOv > 0)
				ap.durationOverride = durationOv;
			activeAnimations.push(new ActiveAnimation(entry, ap, startRotation, endRotation, onComplete));
		} else {
			// No path defined — instant snap
			entry.container.setPosition(to.x, to.y);
			entry.container.rotation = endRotation;
			onComplete();
		}
	}

	/** Create a tracking draw animation: the path is NOT pre-stretched. Instead, each frame
	 *  the stretch transform is recomputed from `from` toward `entry.layoutPos`, so the
	 *  endpoint follows layout changes dynamically. */
	function animateCardToTracking(entry:CardEntry, from:FPoint, startRotation:Float, endRotation:Float,
			pathName:Null<String>, onComplete:() -> Void):Void {
		removeAnimationsForEntry(entry);

		if (pathName != null) {
			// Create AnimatedPath with NO normalization — raw path coordinates
			var ap = builder.createAnimatedPath(pathName);
			var durationOv = getDurationOverride(pathName);
			if (durationOv > 0)
				ap.durationOverride = durationOv;
			var rawEndpoint = ap.path.getEndpoint();
			var anim = new ActiveAnimation(entry, ap, startRotation, endRotation, onComplete);
			anim.trackingFrom = from;
			anim.rawEndpoint = rawEndpoint;
			activeAnimations.push(anim);
		} else {
			// No path — snap to current layout position
			entry.container.setPosition(entry.layoutPos.x, entry.layoutPos.y);
			entry.container.rotation = endRotation;
			onComplete();
		}
	}

	// === Internal: Events ===

	/** Emit event to all listeners (including chained grid listeners). */
	function emitEvent(event:CardHandEvent):Void {
		// Notify chained listeners first (grids that convert CardPlayed → CellCardPlayed)
		for (listener in chainedListeners)
			listener(event);
		if (onCardEvent != null)
			onCardEvent(event);
	}

	/** Chained event listeners added by UIMultiAnimGrid for CellCardPlayed conversion. */
	@:allow(bh.ui.UIMultiAnimGrid)
	final chainedListeners:Array<(event:CardHandEvent) -> Void> = [];

	/** Resolve card state when animation completes.
	 *  Handles deferred enable/disable from setCardEnabled called during animation. */
	function resolveAnimationComplete(entry:CardEntry):Void {
		if (entry.state == Animating) {
			entry.state = InHand;
		} else if (entry.state == Disabled && entry.enableAfterAnimation) {
			entry.state = InHand;
			entry.enableAfterAnimation = false;
			interactiveHelper.setDisabled(entry.interactiveId, false);
		}
		// If Disabled without enableAfterAnimation, stay Disabled
	}

	/** Check whether an entry has an active animation running. */
	function isAnimatingEntry(entry:CardEntry):Bool {
		for (anim in activeAnimations)
			if (anim.entry == entry)
				return true;
		return false;
	}

	/** Remove all active animations for this entry in place (no array reallocation). */
	function removeAnimationsForEntry(entry:CardEntry):Void {
		var i = activeAnimations.length - 1;
		while (i >= 0) {
			if (activeAnimations[i].entry == entry)
				activeAnimations.splice(i, 1);
			i--;
		}
	}

	// === Internal: Targeting zone check ===

	/** Check whether cursor position is in a targeting zone.
	 *  If explicit zones are registered, checks those.
	 *  Otherwise falls back to legacy Y-threshold (full-width zone above anchorY - threshold). */
	function isInTargetingZone(x:Float, y:Float):Bool {
		if (targetingZones.length > 0) {
			for (zone in targetingZones) {
				if (x >= zone.x && x <= zone.x + zone.w && y >= zone.y && y <= zone.y + zone.h)
					return true;
			}
			// Fallback: also check registered targets directly (cursor over a target = targeting)
			return targeting.hitTestTargets(sceneCursorX, sceneCursorY, draggedEntry != null ? draggedEntry.descriptor.id : "") != null;
		}
		// Legacy: simple Y threshold
		return y < anchorY - targetingThresholdY;
	}

	// === Internal: Utilities ===

	/** Add/restore a card container to handContainer at the correct layer for its array index.
	 *  Uses h2d.Layers to maintain z-order: lower card index = lower layer = renders behind. */
	function addToHandLayer(entry:CardEntry):Void {
		handContainer.add(entry.container, cards.indexOf(entry));
	}

	function findCardIndex(cardId:CardId):Int {
		for (i in 0...cards.length)
			if (cards[i].descriptor.id == cardId)
				return i;
		return -1;
	}

	function findCardByInteractiveId(id:String):Null<CardEntry> {
		for (entry in cards)
			if (entry.interactiveId == id || id.indexOf(entry.interactiveId + ".") == 0)
				return entry;
		return null;
	}

	function getDurationOverride(pathName:String):Float {
		if (pathName == drawPathName) return drawDuration;
		if (pathName == discardPathName) return discardDuration;
		if (pathName == returnPathName) return returnDuration;
		if (pathName == rearrangePathName) return rearrangeDuration;
		return 0;
	}
}
