package screens;

import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder;
import bh.paths.*;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;


class FontsScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;

	public function load() {
			this.builder = this.screenManager.buildFromResourceName("std.manim", false);
			var fontsBuilder = this.screenManager.buildFromResourceName("fonts.manim", false);

			var fontsIterator = fontsBuilder.getLayouts().getIterator("fonts");
			var fontNamesIterator = fontsBuilder.getLayouts().getIterator("fontNames");

			var names = bh.base.FontManager.getRegisteredFontNames();
			
			for(fontName in names) {
				var font = bh.base.FontManager.getFontByName(fontName);
				var t = new h2d.Text(font);
				t.text = 'When zombies arrive, quickly fax Judge Pat.'
				+  "   The five boxing wizards jump quickly!?".toUpperCase()
				+ "73/124 0123456789  ! # / | (-)";
				addObjectToLayerWithIterator(t, fontsIterator);

				var tname = new h2d.Text(bh.base.FontManager.getFontByName("default"));
				tname.text = '$fontName';

				addObjectToLayerWithIterator(tname, fontNamesIterator);
			}

			
			
	}
	
	public override function update(dt:Float) {
		super.update(dt);
		
	}
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		
	}

}