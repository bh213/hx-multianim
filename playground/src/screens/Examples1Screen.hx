package screens;

import hxd.Rand;
import h3d.Vector;
import h3d.Vector4;
import h2d.Tile;
import haxe.Timer;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;
using bh.base.BitUtils;

class Examples1Screen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	
	var updatableText:Updatable;
	var updatableTile:Updatable;
	var last = 0.;
	var rand:Rand;


	public function load() {

			rand = new Rand(17);
			this.builder = this.screenManager.buildFromResourceName("examples1.manim", false);
			var stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);
			var ui = addBuilderResult(builder.buildWithParameters("ui", []));
			updatableText = ui.getUpdatable("textToUpdate");
			updatableTile = ui.getUpdatable("bitmapToUpdate");


	}
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIOnControllerEvent(event):
				trace(event);
			default:
		}
	}

	public override function update(dt:Float) {
		super.update(dt);
		var t = Timer.stamp();
		
		if (t - last > 1) {
			updatableText.updateText('${t}');
			var c = new Vector4(1., rand.rand(), rand.rand(), rand.rand()).toColor();
			updatableTile.updateTile(Tile.fromColor(c, 30, 30, 1.));
			last = t;
		}
	}
}