package bh.ui.screens;

import bh.ui.UIMultiAnimScrollableList.PanelSizeMode;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIMultiAnimProgressBar.UIMultiAnimProgressBar;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.ui.UIElement;
import bh.ui.UIInteractiveWrapper;
import bh.base.MAObject;
import bh.multianim.MultiAnimBuilder;
import bh.stateanim.AnimParser;
import bh.ui.controllers.UIController;
import bh.base.FPoint;

enum LayersEnum {
	ModalLayer;
	DefaultLayer;
	BackgroundLayer;
	NamedLayer(name:String);
}

interface UIScreen {
	function getElements(type:SubElementsType):Array<UIElement>;
	function update(dt:Float):Void;
	function addElement(element:UIElement, layer:Null<LayersEnum>):UIElement;
	function removeElement(element:UIElement):UIElement;
	function addBuilderResult(r:BuilderResult, layer:LayersEnum = DefaultLayer):BuilderResult;
	function addObjectToLayer(object:h2d.Object, ?layerName:LayersEnum):h2d.Object;
	function getController():UIController;
	function getSceneRoot():h2d.Layers;
	function load():Void;
	function clear():Void;
	function onClear():Void;
	function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;
	function getLayers():Map<LayersEnum, Int>;
	function getHigherLayer(currentLayer:LayersEnum):LayersEnum;
}

@:nullSafety
abstract class UIScreenBase implements UIScreen implements UIControllerScreenIntegration {
	var elements:Array<UIElement> = [];
	var subElementProviders:Array<UIElementSubElements> = [];
	var controllersStack:Array<UIController> = [];
	var controller(get, never):UIController;
	final root:h2d.Layers;
	final screenManager:ScreenManager;
	final layers:Map<LayersEnum, Int>;
	var groups:Map<String, Array<UIElement>> = [];
	var postCustomAddToLayer:Map<h2d.Object, UIElementCustomAddToLayer> = [];
	var interactiveWrappers:Array<UIInteractiveWrapper> = [];

	public function new(screenManager:ScreenManager, ?layers:Map<LayersEnum, Int>) {
		this.root = new h2d.Layers();
		this.screenManager = screenManager;
		if (layers == null) {
			this.layers = [BackgroundLayer => 1, DefaultLayer => 3, ModalLayer => 5];
		} else {
			if (layers.exists(BackgroundLayer) == false)
				throw 'BackgroundLayer not set';
			if (layers.exists(DefaultLayer) == false)
				throw 'DefaultLayer not set';
			if (layers.exists(ModalLayer) == false)
				throw 'ModalLayer not set';
			this.layers = layers;
		}

		this.controllersStack = [new DefaultUIController(this)];
	}

	public function setExitCode(exitResponse) {
		this.controller.exitResponse = exitResponse;
	}

	public function get_controller():UIController {
		if (controllersStack.length == 0)
			throw 'no controller in stack';
		return controllersStack[controllersStack.length - 1];
	}

	public function pushController(newController:UIController) {
		getController().lifecycleEvent(LifecycleControllerFinished);
		controllersStack.push(newController);
		newController.lifecycleEvent(LifecycleControllerStarted);
	}

	public function popController() {
		getController().lifecycleEvent(LifecycleControllerFinished);
		if (controllersStack.pop() == null)
			throw 'no controller in stack after pop';
		getController().lifecycleEvent(LifecycleControllerStarted);
	}

	final public function clear() {
		for (el in elements) {
			removeElement(el);
		}
		groups.clear();
		elements = [];
		subElementProviders = [];
		postCustomAddToLayer.clear();
		getSceneRoot().removeChildren();
		onClear();
	}

	public function onClear() {}

	public abstract function load():Void;

	public abstract function onScreenEvent(event:UIScreenEvent, source:UIElement):Void;

	public function onMouseMove(pos:h2d.col.Point):Bool { return true;}
	public function onMouseClick(pos:h2d.col.Point, button:Int, release:Bool):Bool {return true;}
	public function onMouseWheel(pos:h2d.col.Point, delta:Float):Bool { return true;}
	public function onKey(keyCode:Int, release:Bool):Bool { return true;}

	public function update(dt:Float):Void {
		// controller.update(dt) is already called by ScreenManager.update() before screen.update()
		for (obj => v in postCustomAddToLayer) {
			var insertedLayer = findLayerFromObject(obj);
			if (insertedLayer == null)
				throw 'could not find layer for object $obj';
			v.customAddToLayer(insertedLayer, this, true);
		}
		postCustomAddToLayer.clear();
	}

	public function getElements(type:SubElementsType):Array<UIElement> {
		var retVal = elements.copy();
		for (provider in subElementProviders) {
			retVal = retVal.concat(provider.getSubElements(type));
		}
		return retVal;
	}

    function hasSettings(settings:ResolvedSettings, settingName:String) {
        if (settings == null)
            return false;
        return settings.exists(settingName);
    }

	function getSettings(settings:ResolvedSettings, settingName:String, defaultValue:String) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		return switch (val) {
			case RSVString(s): s;
			case RSVInt(i): '$i';
			case RSVFloat(f): '$f';
		};
	}

	function getIntSettings(settings:ResolvedSettings, settingName:String, defaultValue:Int) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		return switch (val) {
			case RSVInt(i): i;
			case RSVFloat(f): Std.int(f);
			case RSVString(s):
				var intVal = Std.parseInt(s);
				if (intVal == null)
					throw 'could not parse setting "$s" as integer';
				intVal;
		};
	}

	function getFloatSettings(settings:ResolvedSettings, settingName:String, defaultValue:Float) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		return switch (val) {
			case RSVFloat(f): f;
			case RSVInt(i): i * 1.0;
			case RSVString(s):
				var floatVal = Std.parseFloat(s);
				if (Math.isNaN(floatVal))
					throw 'could not parse setting "$s" as float';
				floatVal;
		};
	}

	function getBoolSettings(settings:ResolvedSettings, settingName:String, defaultValue:Bool) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		final strVal = switch (val) {
			case RSVString(s): s;
			case RSVInt(i): '$i';
			case RSVFloat(f): '$f';
		};
		return switch (strVal.toLowerCase()) {
			case "true" | "1" | "yes": true;
			case "false" | "0" | "no": false;
			default: throw 'could not parse setting "$strVal" as bool';
		};
	}

	function validateSettings(settings:ResolvedSettings, allowedSettings:Array<String>, elementName:String) {
		if (settings == null)
			return;
		for (key in settings.keys()) {
			if (!allowedSettings.contains(key)) {
				throw 'Unknown setting "$key" for ${elementName}';
			}
		}
	}

	function addButtonWithSingleBuilder(builder:MultiAnimBuilder, buttonBuilderName:String, settings:ResolvedSettings, text:String):UIStandardMultiAnimButton {
		return addButton(builder.createElementBuilder(buttonBuilderName), text, settings);
	}

	function addButton(builder:UIElementBuilder, text:String, settings:ResolvedSettings):UIStandardMultiAnimButton {
		validateSettings(settings, ["buildName", "text", "width", "height", "font", "fontColor"], "button");
		if (hasSettings(settings, "buildName")) {
			builder = builder.withUpdatedName(getSettings(settings, "buildName", "button"));
		}
		final buttonText = getSettings(settings, "text", text);
		var extraParams:Null<Map<String, Dynamic>> = null;
		if (hasSettings(settings, "width") || hasSettings(settings, "height") || hasSettings(settings, "font") || hasSettings(settings, "fontColor")) {
			extraParams = new Map();
			if (hasSettings(settings, "width"))
				extraParams.set("width", getIntSettings(settings, "width", 200));
			if (hasSettings(settings, "height"))
				extraParams.set("height", getIntSettings(settings, "height", 30));
			if (hasSettings(settings, "font"))
				extraParams.set("font", getSettings(settings, "font", "dd"));
			if (hasSettings(settings, "fontColor"))
				extraParams.set("fontColor", getIntSettings(settings, "fontColor", 0xffffff12));
		}
		return UIStandardMultiAnimButton.create(builder.builder, builder.name, buttonText, extraParams);
	}

	function addSlider(providedBuilder, settings:ResolvedSettings, initialValue:Float = 0) {
		validateSettings(settings, ["buildName", "size", "min", "max", "step"], "slider");
		final sliderBuildName = getSettings(settings, "buildName", "slider");
		final size = getIntSettings(settings, "size", 200);
		final slider = UIStandardMultiAnimSlider.create(providedBuilder, sliderBuildName, size, initialValue);
		if (hasSettings(settings, "min"))
			slider.min = getFloatSettings(settings, "min", 0);
		if (hasSettings(settings, "max"))
			slider.max = getFloatSettings(settings, "max", 100);
		if (hasSettings(settings, "step"))
			slider.step = getFloatSettings(settings, "step", 0);
		return slider;
	}

	function addProgressBar(providedBuilder, settings:ResolvedSettings, initialValue:Int = 0) {
		validateSettings(settings, ["buildName"], "progressBar");
		final barBuildName = getSettings(settings, "buildName", "progressBar");
		return UIMultiAnimProgressBar.create(providedBuilder, barBuildName, initialValue);
	}

	function addCheckbox(providedBuilder, settings:ResolvedSettings, checked:Null<Bool> = null) {
		validateSettings(settings, ["buildName", "initialValue"], "checkbox");
		final checkboxBuildName = getSettings(settings, "buildName", "checkbox");
		final checkBoxInitialValue = getBoolSettings(settings, "initialValue", checked ?? false);
		return UIStandardMultiCheckbox.create(providedBuilder, checkboxBuildName, checkBoxInitialValue);
	}

	function addRadio(providedBuilder, settings:ResolvedSettings, items:Array<UIElementListItem>, vertical:Bool, selectedIndex:Int = 0) {
		validateSettings(settings, ["radioBuildName", "radioButtonBuildName"], "radio");
		final radioBuildName = getSettings(settings, "radioBuildName", vertical ? "radioButtonsVertical" : "radioButtonsHorizontal");
		final singleRadioButtonBuilderName = getSettings(settings, "radioButtonBuildName", "radio");
		return UIMultiAnimRadioButtons.create(providedBuilder, radioBuildName, singleRadioButtonBuilderName, items, selectedIndex);
	}
	
	function addText(textValue:String, fontName:String, ?layer:LayersEnum) {
		final textObj = new h2d.Text(bh.base.FontManager.getFontByName(fontName));
		textObj.text = textValue;
		return addObjectToLayer(textObj, layer);
	}

	// TODO: needs work
	function addCheckboxWithText(providedBuilder:MultiAnimBuilder, settings:ResolvedSettings, label:String, fontName:String, checked:Bool) {
		validateSettings(settings, ["buildName", "textColor", "font"], "checkboxWithText");
		var checkbox;
		final checkboxWithNameBuildName = getSettings(settings, "buildName", "checkboxWithText");
		final textColor = getIntSettings(settings, "textColor", 0xFFFFFFFF);
		final font = getSettings(settings, "font", fontName);

		final factory = (settings) -> {
			checkbox = addCheckbox(providedBuilder, settings, checked);
			addElement(checkbox, null);
			return checkbox.getObject();
		}
		var built = providedBuilder.buildWithParameters(checkboxWithNameBuildName, ["textColor" => textColor, "title" => label, "font" => font],
			{placeholderObjects: ["checkbox" => PVFactory(factory)]});
		return new UIElementContainer(checkbox, built.object);
	}



    function addScrollableListWithSingleBuilder(builder:MultiAnimBuilder, panelBuilderName:String, itemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
        return addScrollableList(builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(itemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex, width, height);
    }

	function addScrollableList(panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
		validateSettings(settings, ["panelBuildName", "itemBuildName", "scrollbarBuildName", "scrollbarInPanelName", "width", "height", "topClearance", "scrollSpeed", "doubleClickThreshold", "wheelScrollMultiplier", "panelMode", "font", "fontColor"], "scrollableList");

		if (hasSettings(settings, "panelBuildName")) {
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuildName", ""));
		}
        if (hasSettings(settings, "itemBuildName")) {
            itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuildName", ""));
        }
		if (hasSettings(settings, "scrollbarBuildName")) {
			scrollbarBuilder = scrollbarBuilder.withUpdatedName(getSettings(settings, "scrollbarBuildName", ""));
		}
		if (hasSettings(settings, "scrollbarInPanelName")) {
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", "scrollbar");
		}
		final finalWidth = getIntSettings(settings, "width", width);
		final finalHeight = getIntSettings(settings, "height", height);
		final topClearance = getIntSettings(settings, "topClearance", 0);
		final panelModeStr = getSettings(settings, "panelMode", "scrollable");
		final sizeMode:PanelSizeMode = if (panelModeStr == "scalable") AutoSize else FixedScroll;
		if (hasSettings(settings, "font") || hasSettings(settings, "fontColor")) {
			var itemExtraParams = new Map<String, Dynamic>();
			if (hasSettings(settings, "font"))
				itemExtraParams.set("font", getSettings(settings, "font", "m6x11"));
			if (hasSettings(settings, "fontColor"))
				itemExtraParams.set("fontColor", getIntSettings(settings, "fontColor", 0xffffff12));
			itemBuilder = itemBuilder.withExtraParams(itemExtraParams);
		}
		final list = UIMultiAnimScrollableList.create(panelBuilder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, finalWidth, finalHeight, items, topClearance, initialIndex, sizeMode);
		if (hasSettings(settings, "scrollSpeed"))
			list.scrollSpeedOverride = getFloatSettings(settings, "scrollSpeed", 100);
		if (hasSettings(settings, "doubleClickThreshold"))
			list.doubleClickThreshold = getFloatSettings(settings, "doubleClickThreshold", 0.3);
		if (hasSettings(settings, "wheelScrollMultiplier"))
			list.wheelScrollMultiplier = getFloatSettings(settings, "wheelScrollMultiplier", 10);
		return list;
	}



	 function addDropdownWithSingleBuilder(builder:MultiAnimBuilder, dropdownBuilderName:String, panelBuilderName:String, panelListItemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		return addDropdown(builder.createElementBuilder(dropdownBuilderName), builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(panelListItemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex);
	}

	function addDropdown(dropdownBuilder:UIElementBuilder, panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder,  scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		validateSettings(settings, [
			// dropdown settings
			"dropdownBuildName", "autoOpen", "autoCloseOnLeave", "closeOnOutsideClick", "transitionTimer",
			// scrollable list settings (passed through)
			"panelBuildName", "itemBuildName", "scrollbarBuildName", "scrollbarInPanelName",
			"width", "height", "topClearance", "scrollSpeed", "doubleClickThreshold", "wheelScrollMultiplier",
			"panelMode", "font", "fontColor"
		], "dropdown");

        if (hasSettings(settings, "panelBuildName")) {
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuildName", ""));
		}
        if (hasSettings(settings, "itemBuildName")) {
            itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuildName", ""));
        }
        if (hasSettings(settings, "dropdownBuildName")) {
            dropdownBuilder = dropdownBuilder.withUpdatedName(getSettings(settings, "dropdownBuildName", ""));
        }
		if (hasSettings(settings, "scrollbarBuildName")) {
			scrollbarBuilder = scrollbarBuilder.withUpdatedName(getSettings(settings, "scrollbarBuildName", ""));
		}
		if (hasSettings(settings, "scrollbarInPanelName")) {
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", scrollbarInPanelName);
		}

		final autoOpen = getBoolSettings(settings, "autoOpen", true);
		final autoCloseOnLeave = getBoolSettings(settings, "autoCloseOnLeave", true);
		final closeOnOutsideClick = getBoolSettings(settings, "closeOnOutsideClick", true);
		final panelWidth = getIntSettings(settings, "width", 120);
		final panelHeight = getIntSettings(settings, "height", 300);
		final topClearance = getIntSettings(settings, "topClearance", 0);
		final panelModeStr = getSettings(settings, "panelMode", "scrollable");
		final sizeMode:PanelSizeMode = if (panelModeStr == "scalable") AutoSize else FixedScroll;
		if (hasSettings(settings, "font") || hasSettings(settings, "fontColor")) {
			var itemExtraParams = new Map<String, Dynamic>();
			if (hasSettings(settings, "font"))
				itemExtraParams.set("font", getSettings(settings, "font", "m6x11"));
			if (hasSettings(settings, "fontColor"))
				itemExtraParams.set("fontColor", getIntSettings(settings, "fontColor", 0xffffff12));
			itemBuilder = itemBuilder.withExtraParams(itemExtraParams);
			dropdownBuilder = dropdownBuilder.withExtraParams(itemExtraParams);
		}
		var panel = UIMultiAnimScrollableList.create(panelBuilder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, panelWidth, panelHeight, items, topClearance, initialIndex, sizeMode);
		if (hasSettings(settings, "scrollSpeed"))
			panel.scrollSpeedOverride = getFloatSettings(settings, "scrollSpeed", 100);
		if (hasSettings(settings, "doubleClickThreshold"))
			panel.doubleClickThreshold = getFloatSettings(settings, "doubleClickThreshold", 0.3);
		if (hasSettings(settings, "wheelScrollMultiplier"))
			panel.wheelScrollMultiplier = getFloatSettings(settings, "wheelScrollMultiplier", 10);
		final retVal = UIStandardMultiAnimDropdown.createWithPrebuiltPanel(dropdownBuilder, panel, items, initialIndex);

		retVal.autoOpen = autoOpen;
		retVal.autoCloseOnLeave = autoCloseOnLeave;
		retVal.closeOnOutsideClick = closeOnOutsideClick;
		if (hasSettings(settings, "transitionTimer"))
			retVal.transitionTimerOverride = getFloatSettings(settings, "transitionTimer", 1.0);
		return retVal;
	}

	public function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum) {
		if (layer == null) {
			getSceneRoot().add(object, layers.get(DefaultLayer));
		} else {
			var idx = layers.get(layer);
			if (idx == null)
				throw 'layer not found $layer';
			getSceneRoot().add(object, idx);
		}

		return object;
	}

	public function addObjectToLayerWithIterator(object:h2d.Object, iterator:Iterator<FPoint>, ?layer:LayersEnum) {
		addObjectToLayer(object, layer);
		if (iterator.hasNext() == false)
			throw 'no more iterations';
		final pt = iterator.next();
		object.setPosition(pt.x, pt.y);
	}

	public function addBuilderResult(r:BuilderResult, ?layer:LayersEnum):BuilderResult {
		addObjectToLayer(r.object, layer);
		return r;
	}

	public function addBuilderResultWithPos(r:BuilderResult, pos:FPoint, ?layer:LayersEnum):BuilderResult {
		addObjectToLayer(r.object, layer);
		r.object.setPosition(pos.x, pos.y);
		return r;
	}

	public function addBuilderResultWithIterator(r:BuilderResult, ?layer:LayersEnum, iterator):BuilderResult {
		addObjectToLayerWithIterator(r.object, iterator, layer);
		return r;
	}

	public function addInteractive(obj:MAObject, ?prefix:String):UIInteractiveWrapper {
		var wrapper = new UIInteractiveWrapper(obj, prefix);
		interactiveWrappers.push(wrapper);
		addElement(wrapper, null);
		return wrapper;
	}

	public function addInteractives(r:BuilderResult, ?prefix:String):Array<UIInteractiveWrapper> {
		var wrappers:Array<UIInteractiveWrapper> = [];
		for (obj in r.interactives) {
			wrappers.push(addInteractive(obj, prefix));
		}
		return wrappers;
	}

	public function removeInteractives(?prefix:String):Void {
		var toRemove:Array<UIInteractiveWrapper> = [];
		for (w in interactiveWrappers) {
			if (prefix == null || w.prefix == prefix)
				toRemove.push(w);
		}
		for (w in toRemove) {
			interactiveWrappers.remove(w);
			removeElement(w);
		}
	}

	public function addElement(element:UIElement, layer:Null<LayersEnum>) {
		elements.push(element);
		if (Std.isOfType(element, UIElementSubElements)) {
			subElementProviders.push(cast(element, UIElementSubElements));
		}
		if (Std.isOfType(element, UIElementCustomAddToLayer)) {
			final customElement:UIElementCustomAddToLayer = cast(element, UIElementCustomAddToLayer);
			final result = customElement.customAddToLayer(layer, this, false);
			switch result {
				case Added:
					return element;
				case Postponed:
					if (postCustomAddToLayer.exists(element.getObject()))
						throw 'element already is in postCustomAddToLayer';
					postCustomAddToLayer.set(element.getObject(), customElement);
			}
		}
		if (layer != null && element.getObject().parent == null) {
			addObjectToLayer(element.getObject(), layer);
		}
		return element;
	}

	/**
	 * Sends the current state of a UI element as an event to onScreenEvent.
	 * Call after adding elements to sync initial state with application logic.
	 */
	function syncInitialState(element:UIElement) {
		if (Std.isOfType(element, UIElementFloatValue)) {
			final floatEl = cast(element, UIElementFloatValue);
			onScreenEvent(UIChangeFloatValue(floatEl.getFloatValue()), element);
		}
		if (Std.isOfType(element, UIElementNumberValue)) {
			final numEl = cast(element, UIElementNumberValue);
			onScreenEvent(UIChangeValue(numEl.getIntValue()), element);
		} else if (Std.isOfType(element, UIElementListValue)) {
			final listEl = cast(element, UIElementListValue);
			onScreenEvent(UIChangeItem(listEl.getSelectedIndex(), listEl.getList()), element);
		} else if (Std.isOfType(element, UIElementSelectable)) {
			final selEl = cast(element, UIElementSelectable);
			onScreenEvent(UIToggle(selEl.selected), element);
		}
	}

	function getGroup(groupName:String):Array<UIElement> {
		final group = groups.get(groupName);
		if (group == null)
			throw 'unknown group $groupName';
		return group;
	}

	public function addElementToGroup(groupName:String, element:UIElement) {
		final group = getGroup(groupName);
		if (group.contains(element))
			throw 'element already member of the group';
		group.push(element);
	}

	public function createGroup(groupName:String, throwIfExists = true) {
		final group = groups.get(groupName);
		if (group != null) {
			if (throwIfExists)
				throw 'group $groupName already exists';
			else
				return;
		}
		groups.set(groupName, []);
	}

	public function removeGroupElements(groupName:String) {
		final group = getGroup(groupName);
		for (element in group) {
			removeElement(element);
		}
	}

	public function removeElement(element:UIElement) {
		element.getObject().remove();
		element.clear();
		elements.remove(element);
		if (Std.isOfType(element, UIElementSubElements)) {
			subElementProviders.remove(cast(element, UIElementSubElements));
		}
		return element;
	}

	public function addElementWithPos<T:UIElement>(element:T, x:Float, y:Float, layer:LayersEnum = DefaultLayer):T {
		addElement(element, layer);
		element.getObject().setPosition(x, y);
		return element;
	}

	public function addElementWithPoint<T:UIElement>(element:T, point:FPoint, layer:LayersEnum = DefaultLayer):T {
		return addElementWithPos(element, point.x, point.y, layer);
	}

	public function addElementWithIterator<T:UIElement>(element:T, iterator:Iterator<FPoint>, layer:LayersEnum = DefaultLayer, ?groupName:String):T {
		if (iterator.hasNext() == false)
			throw 'no more iterations';
		final pt = iterator.next();
		if (groupName != null)
			addElementToGroup(groupName, element);
		return addElementWithPos(element, pt.x, pt.y, layer);
	}

	public function getController():UIController {
		return controller;
	}

	public function getSceneRoot():h2d.Layers {
		return root;
	}

	public function getLayers() {
		return layers;
	}

	public function getLowerLayer(originalLayer:LayersEnum):LayersEnum {
		final currentIndex = layers.get(originalLayer);
		if (currentIndex == null)
			throw 'layer not found $originalLayer';
		var bestIndex = -1;
		var bestLayer = originalLayer;

		for (layer => layerIndex in layers) {
			if (layerIndex < currentIndex && layerIndex > bestIndex) {
				bestIndex = layerIndex;
				bestLayer = layer;
			}
		}
		if (bestLayer == originalLayer)
			throw 'no higher layer found for $originalLayer';
		return bestLayer;
	}

	public function getHigherLayer(originalLayer:LayersEnum):LayersEnum {
		final currentIndex = layers.get(originalLayer);
		if (currentIndex == null)
			throw 'layer not found $originalLayer';
		var bestIndex = 999999;
		var bestLayer = originalLayer;

		for (layer => layerIndex in layers) {
			if (layerIndex > currentIndex && layerIndex < bestIndex) {
				bestIndex = layerIndex;
				bestLayer = layer;
			}
		}
		if (bestLayer == originalLayer)
			throw 'no higher layer found for $originalLayer';
		return bestLayer;
	}

	public function findLayerFromObject(obj:h2d.Object):LayersEnum {
		var current = obj;
		while (current != null) {
			var layerIndex = root.getChildLayer(current);
			current = current.parent;
			if (layerIndex == -1)
				continue;

			for (enumLayer => index in this.layers) {
				if (layerIndex == index)
					return enumLayer;
			}
		}
		throw 'layer not found for object $obj. layers ${this.layers}';
	}
}
