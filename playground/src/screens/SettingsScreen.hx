package screens;

import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.ui.UIMultiAnimCheckbox;
import bh.multianim.MultiAnimBuilder;
import bh.ui.*;
import bh.ui.screens.UIScreen;
using bh.base.BitUtils;
@:nullSafety
class SettingsScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;

	var fullScreen:Null<UIStandardMultiCheckbox>;
	var backgrounds:Null<UIStandardMultiAnimDropdown>;
	var currentDisplay:Null<Updatable>;


	public function load():Void {

			final window = hxd.Window.getInstance();
			this.builder = this.screenManager.buildFromResourceName("settings.manim", false);
			var stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);

			var ui = addBuilderResult(builder.buildWithParameters("ui", []));
			this.currentDisplay = ui.getUpdatable("resolution");

			final mainLayout = builder.getLayouts();
			var resolutionIterator = mainLayout.getIterator("resolution");

			fullScreen = addElementWithIterator(UIStandardMultiCheckbox.create(stdBuilder, "checkbox", false), resolutionIterator);
			fullScreen.onToggle = checked -> {
				window.displayMode = checked ? Borderless : Windowed;
				updateText();
			}

			#if hl
			var availResolutions = window.getDisplaySettings();
			var items:Array<UIElementListItem> = availResolutions.map(x-> cast {name:'${x.width}x${x.height}', data: x});
			var resolutions = addElementWithIterator(UIStandardMultiAnimDropdown.createWithSingleBuilder(stdBuilder, items), resolutionIterator);
			resolutions.onItemChanged = (newIndex, items) -> {
				var newItem = cast items[newIndex];
				window.resize(newItem.data.width, newItem.data.height);
				updateText();
			}
			#else
			resolutionIterator.next(); // skip resolution slot in JS mode
			#end

			var colors:Array<UIElementListItem> = [{name:"Black", data:0}, {name:"White", data:0xFFFFFF}, {name:"gray", data:0x808080}, {name:"silver", data:0xC0C0C0}, {name:"green-ish", data:0x507050}];
			this.backgrounds = addElementWithIterator(UIStandardMultiAnimDropdown.createWithSingleBuilder(stdBuilder, colors), resolutionIterator);
			this.backgrounds.onItemChanged = (newIndex, items) -> {
				screenManager.app.engine.backgroundColor = items[newIndex].data;
			}

			#if hl
			var monitors:Array<UIElementListItem> = cast hxd.Window.getMonitors().map(x->{name:'${x.name}', data:x});
			var monitorsDD = addElementWithIterator(UIStandardMultiAnimDropdown.createWithSingleBuilder(stdBuilder, monitors), resolutionIterator);

			monitorsDD.onItemChanged = (newIndex, items) -> {
				var window = hxd.Window.getInstance();
				window.monitor = newIndex;
				window.applyDisplay();
				updateText();
				trace('monitor changed to $newIndex ${items[newIndex].name}');
			}
			#end

			updateText();
	}

	function updateText() {
		final window = hxd.Window.getInstance();
		if (currentDisplay != null) {
			#if hl
			var dispSettings = window.getCurrentDisplaySetting();
			switch window.displayMode {
				case Windowed: currentDisplay.updateText('Windowed ${window.width} x ${window.height} @ ${dispSettings.framerate}');
				case Fullscreen: currentDisplay.updateText('Fullscreen ${window.width} x ${window.height} @ ${dispSettings.framerate}');
				case Borderless: currentDisplay.updateText('Borderless ${window.width} x ${window.height} @ ${dispSettings.framerate}');
			}
			#else
			currentDisplay.updateText('${window.width} x ${window.height}');
			#end
		}
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement):Void {
		switch event {
			case UIOnControllerEvent(event):
				trace(event);
			default:
		}
	}
}
