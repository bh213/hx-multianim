package screens;

import bh.base.FPoint;
import bh.paths.AnimatedPath;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimDraggable.DragEvent;
import bh.ui.screens.UIScreen;
import h2d.col.Point;
import h2d.col.Bounds;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;

class DraggableTestScreen extends UIScreenBase {
	var builder:Null<MultiAnimBuilder>;
	var uiResult:Null<BuilderResult>;

	public function new(screenManager) {
		super(screenManager);
	}

	public function load() {
		this.builder = this.screenManager.buildFromResourceName("draggable.manim", false);
		this.uiResult = builder.buildWithParameters("ui", []);
		addBuilderResult(uiResult);

		// --- Draggable 1: Free drag with drop zones, snap & return animations ---
		var drag1 = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xff08ffff, 50, 50)));
		drag1.returnPathFactory = animPathFactory("returnAnim");
		drag1.snapPathFactory = animPathFactory("snapAnim");
		drag1.dragLayer = ModalLayer;
		drag1.dragAlpha = 0.6;
		drag1.zoneHighlightAlpha = 1.0;

		drag1.addDropZone({
			id: "zone1",
			bounds: Bounds.fromValues(300, 200, 180, 180),
			snapX: 365,
			snapY: 265,
		});
		drag1.addDropZone({
			id: "zone2",
			bounds: Bounds.fromValues(550, 240, 120, 120),
			snapX: 585,
			snapY: 275,
		});

		drag1.onDragEvent = (event, pos, wrapper) -> {
			switch event {
				case ZoneEnter(zone):
					trace('Entered zone: ${zone.id}');
				case ZoneLeave(zone):
					trace('Left zone: ${zone.id}');
				case DragStart:
					trace('Drag started');
				case DragEnd:
					trace('Drag ended (dropped on zone)');
				default:
			}
		};
		drag1.onDragCancel = (pos, wrapper) -> {
			trace('Drag cancelled - returning to origin');
		};

		addElementWithPos(drag1, 100, 150, DefaultLayer);

		// --- Draggable 2: Horizontal constraint — always bounces back to start ---
		var drag2 = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xff08ff00, 80, 30)));
		drag2.dragConstraint = (pos) -> new Point(Math.max(50, Math.min(pos.x, 550)), 480);
		drag2.returnToOrigin = false;
		drag2.dragAlpha = 0.7;
		addElementWithPos(drag2, 100, 480, DefaultLayer);

		// --- Draggable 3: Priority zones demo (overlapping zones) ---
		var drag3 = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xffff8800, 40, 40)));
		drag3.returnPathFactory = animPathFactory("returnAnim");
		drag3.snapPathFactory = animPathFactory("snapAnim");
		drag3.dragAlpha = 0.7;
		drag3.zoneHighlightAlpha = 1.0;

		drag3.addDropZone({
			id: "zone1-low",
			bounds: Bounds.fromValues(300, 200, 180, 180),
			snapX: 340,
			snapY: 340,
			priority: 0,
		});
		drag3.addDropZone({
			id: "zone2-high",
			bounds: Bounds.fromValues(380, 280, 120, 120),
			snapX: 410,
			snapY: 310,
			priority: 10,
		});

		addElementWithPos(drag3, 200, 150, DefaultLayer);

		// --- Draggable 4: Goes to BackgroundLayer (hides behind everything while dragging) ---
		var drag4 = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xffaa44ff, 50, 50)));
		drag4.dragLayer = BackgroundLayer;
		drag4.returnPathFactory = animPathFactory("linearReturn");
		drag4.dragAlpha = 0.8;
		addElementWithPos(drag4, 650, 150, DefaultLayer);
	}

	function animPathFactory(name:String):AnimatedPathFactory {
		return (from:FPoint, to:FPoint) -> builder.createAnimatedPath(name, from, to);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UICustomEvent(eventName, data):
				trace('Custom event: $eventName, data: $data');
			default:
		}
	}
}
