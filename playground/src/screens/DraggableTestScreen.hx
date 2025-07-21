package screens;

import bh.ui.UIMultiAnimDraggable;
import bh.ui.screens.UIScreen;
import h2d.Object;
import h2d.Bitmap;
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
		// Load the manim file for the UI layout
		this.builder = this.screenManager.buildFromResourceName("draggable.manim", false);
		
		// Build the UI from manim
		this.uiResult = builder.buildWithParameters("ui", []);
		addBuilderResult(uiResult);
		
		var draggableObject = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xff08ffff, 150, 150)));
		addElement(draggableObject, DefaultLayer);

		var draggableObject2 = UIMultiAnimDraggable.create(new h2d.Bitmap(h2d.Tile.fromColor(0xff08ff00, 200, 100)));
		addElement(draggableObject2, DefaultLayer);

		draggableObject.getObject().setPosition(100, 150);
		draggableObject2.getObject().setPosition(500, 350);

	}
	
	
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
				trace('UI element clicked');
			case UICustomEvent(eventName, data):
				trace('Custom event: ${eventName}');
			default:
				// Handle other events
		}
	}
} 