package screens;

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
@:nullSafety
class SettingsScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	
	var fullScreen:Null<UIStandardMultiCheckbox>;
	var resolutions:Null<UIStandardMultiAnimDropdown>;
	var backgrounds:Null<UIStandardMultiAnimDropdown>;
	var currentDisplay:Null<Updatable>;
	

	public function load() {

			final window = hxd.Window.getInstance();
			this.builder = this.screenManager.buildFromResource(hxd.Res.settings, false);
			var stdBuilder = this.screenManager.buildFromResource(hxd.Res.std, false);


			var ui = addBuilderResult(builder.buildWithParameters("ui", []));
			this.currentDisplay = ui.getUpdatable("resolution");

			final mainLayout = builder.getLayouts();
			var resolutionIterator = mainLayout.getIterator("resolution");

			fullScreen = addElementWithIterator(UIStandardMultiCheckbox.create(stdBuilder, "checkbox", false), resolutionIterator);
			fullScreen.onToggle = checked -> {
				window.displayMode = checked ? Borderless : Windowed;
				updateText();
			}
			
			var availResolutions = window.getDisplaySettings();
			var items:Array<UIElementListItem> = availResolutions.map(x-> cast {name:'${x.width}x${x.height}', data: x});
			this.resolutions = addElementWithIterator(UIStandardMultiAnimDropdown.create(stdBuilder, "dropdown", "list-panel", "list-item-120", items), resolutionIterator);
			this.resolutions.onItemChanged = (newIndex, items) -> {
				var newItem = cast items[newIndex];
				window.resize(newItem.data.width, newItem.data.height);
				updateText();
			}
		
			var colors:Array<UIElementListItem> = [{name:"Black", data:0}, {name:"White", data:0xFFFFFF}, {name:"gray", data:0x808080}, {name:"silver", data:0xC0C0C0}, {name:"green-ish", data:0x507050}];
			this.backgrounds = addElementWithIterator(UIStandardMultiAnimDropdown.create(stdBuilder, "dropdown", "list-panel", "list-item-120", colors), resolutionIterator);
			this.backgrounds.onItemChanged = (newIndex, items) -> {
				screenManager.app.engine.backgroundColor = items[newIndex].data;
				
				
			}

			var monitors:Array<UIElementListItem> = cast hxd.Window.getMonitors().map(x->{name:'${x.name}', data:x});
			var monitorsDD = addElementWithIterator(UIStandardMultiAnimDropdown.create(stdBuilder, "dropdown", "list-panel", "list-item-120", monitors), resolutionIterator);
			
			monitorsDD.onItemChanged = (newIndex, items) -> {
				var window = hxd.Window.getInstance();
				window.monitor = newIndex;
				window.applyDisplay();
				//var monitor = hxd.Window.getMonitors()[newIndex];

				//@:privateAccess window.window.setPosition(monitor.x, monitor.y);
				updateText();
				trace('monitor changed to $newIndex ${items[newIndex].name}');
			}

			updateText();
	}

	function updateText() {
		final window = hxd.Window.getInstance();
		var dispSettings = window.getCurrentDisplaySetting();
		if (currentDisplay != null) {
			switch window.displayMode {
				case Windowed: currentDisplay.updateText('Windowed ${window.width} x ${window.height} @ ${dispSettings.framerate}');
				case Fullscreen: currentDisplay.updateText('Fullscreen ${window.width} x ${window.height} @ ${dispSettings.framerate}');
				case Borderless: currentDisplay.updateText('Borderless ${window.width} x ${window.height} @ ${dispSettings.framerate}');
			}
		}
		 
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIOnControllerEvent(event):
				trace(event);
			default:
		}
	}
}