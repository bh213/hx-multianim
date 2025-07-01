package bh.ui.screens;

import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.ui.UIElement;
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
	function addElement(element:UIElement, ?layer:LayersEnum):UIElement;
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
	var controllersStack:Array<UIController> = [];
	var controller(get, never):UIController;
	final root:h2d.Layers;
	final screenManager:ScreenManager;
	final layers:Map<LayersEnum, Int>;
	var groups:Map<String, Array<UIElement>> = [];
	var postCustomAddToLayer:Map<h2d.Object, UIElementCustomAddToLayer> = [];

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
		getSceneRoot().removeChildren();
		onClear();
	}

	public function onClear() {}

	public abstract function load():Void;

	public abstract function onScreenEvent(event:UIScreenEvent, source:UIElement):Void;

	public function onMouseMove(pos:h2d.col.Point):Void {}

	public function update(dt:Float):Void {
		controller.update(dt);
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
		for (element in elements) {
			if (Std.isOfType(element, UIElementSubElements)) {
				final subElements = (cast(element, UIElementSubElements)).getSubElements(type);
				retVal = retVal.concat(subElements);
			}
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
		return val;
	}

	function getIntSettings(settings:ResolvedSettings, settingName:String, defaultValue:Int) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		var intVal = Std.parseInt(val);
		if (intVal == null)
			throw 'could not parse setting "$val" as integer';
		return intVal;
	}

	function getBoolSettings(settings:ResolvedSettings, settingName:String, defaultValue:Bool) {
		if (settings == null)
			return defaultValue;
		final val = settings.get(settingName);
		if (val == null)
			return defaultValue;
		return switch (val.toLowerCase()) {
			case "true" | "1" | "yes": true;
			case "false" | "0" | "no": false;
			default: throw 'could not parse setting "$val" as bool';
		}
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
		validateSettings(settings, ["builderName", "text"], "button");
		if (hasSettings(settings, "builderName")) {
			builder = builder.withUpdatedName(getSettings(settings, "builderName", "button"));
		}
		final buttonText = getSettings(settings, "text", text);
		return UIStandardMultiAnimButton.create(builder.builder, builder.name, buttonText);
	}

	function addSlider(providedBuilder, settings:ResolvedSettings, initialValue:Int = 0) {
		validateSettings(settings, ["buildName", "size"], "slider");
		final sliderBuildName = getSettings(settings, "buildName", "slider");
		final size = getIntSettings(settings, "size", 200);
		return UIStandardMultiAnimSlider.create(providedBuilder, sliderBuildName, size, initialValue);
	}

	function addCheckbox(providedBuilder, settings:ResolvedSettings, checked:Null<Bool> = null) {
		validateSettings(settings, ["checkboxBuildName", "initialValue"], "checkbox");
		final checkboxBuildName = getSettings(settings, "checkboxBuildName", "checkbox");
		final checkBoxInitialValue = getBoolSettings(settings, "initialValue", checked ?? false);
		return UIStandardMultiCheckbox.create(providedBuilder, checkboxBuildName, checkBoxInitialValue);
	}

	function addRadio(providedBuilder, settings:ResolvedSettings, items:Array<UIElementListItem>, vertical:Bool, selectedIndex:Int = 0) {
		validateSettings(settings, ["radioBuildName", "singleRadioButtonBuilderName"], "radio");
		final radioBuildName = getSettings(settings, "radioBuildName", vertical ? "radioButtonsVertical" : "radioButtonsHorizontal");
		final singleRadioButtonBuilderName = getSettings(settings, "singleRadioButtonBuilderName", "radio");
		return UIMultiAnimRadioButtons.create(providedBuilder, radioBuildName, singleRadioButtonBuilderName, items, 0);
	}

	// TODO: needs work
	function addCheckboxWithText(providedBuilder:MultiAnimBuilder, settings:ResolvedSettings, label:String, checked:Bool) {
		validateSettings(settings, ["buildName", "textColor", "font"], "checkboxWithText");
		var checkbox;
		final checkboxWithNameBuildName = getSettings(settings, "buildName", "checkboxWithText");
		final textColor = getIntSettings(settings, "textColor", 0xFFFFFFFF);
		final font = getSettings(settings, "font", "pikzel");

		final factory = (settings) -> {
			checkbox = addCheckbox(providedBuilder, settings, checked);
			addElement(checkbox);
			return checkbox.getObject();
		}
		var built = providedBuilder.buildWithParameters(checkboxWithNameBuildName, ["textColor" => textColor, "title" => label, "font" => font],
			{placeholderObjects: ["checkbox" => PVFactory(factory)]});
		return new UIElementContainer(checkbox, built.object);
	}



	// TODO: hardcoded dimensions
    function addScrollableListWithSingleBuilder(builder:MultiAnimBuilder, panelBuilderName:String, itemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
        return addScrollableList(builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(itemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex, width, height);
    }

	// TODO: hardcoded dimensions
	function addScrollableList(panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
		validateSettings(settings, ["panelBuilder", "itemBuilder", "scrollbarBuilder", "scrollbarInPanelName", "width", "height", "topClearance", "scrollSpeed"], "scrollableList");
		
		if (hasSettings(settings, "panelBuilder")) {
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuilder", ""));
		}
        if (hasSettings(settings, "itemBuilder")) {
            itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuilder", ""));
        }
		if (hasSettings(settings, "scrollbarBuilder")) {
			scrollbarBuilder = scrollbarBuilder.withUpdatedName(getSettings(settings, "scrollbarBuilder", ""));
		}
		if (hasSettings(settings, "scrollbarInPanelName")) {
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", "scrollbar");
		}
		final finalWidth = getIntSettings(settings, "width", width);
		final finalHeight = getIntSettings(settings, "height", height);
		final topClearance = getIntSettings(settings, "topClearance", 0);
		return UIMultiAnimScrollableList.create(panelBuilder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, finalWidth, finalHeight, items, topClearance, initialIndex);
	}



	 function addDropdownWithSingleBuilder(builder:MultiAnimBuilder, dropdownBuilderName:String, panelBuilderName:String, panelListItemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		return addDropdown(builder.createElementBuilder(dropdownBuilderName), builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(panelListItemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex);
	}

	function addDropdown(dropdownBuilder:UIElementBuilder, panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder,  scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		validateSettings(settings, ["panelBuilder", "itemBuilder", "dropdownBuilder", "autoOpen", "autoCloseOnLeave", "closeOnOutsideClick"], "dropdown");

        if (hasSettings(settings, "panelBuilder")) {
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuilder", ""));
		}
        if (hasSettings(settings, "itemBuilder")) {
            itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuilder", ""));
        }
        if (hasSettings(settings, "dropdownBuilder")) {
            dropdownBuilder = dropdownBuilder.withUpdatedName(getSettings(settings, "dropdownBuilder", ""));
        }
		if (hasSettings(settings, "scrollbarInPanelName")) {
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", scrollbarInPanelName);
		}

		final autoOpen = getBoolSettings(settings, "autoOpen", true);
		final autoCloseOnLeave = getBoolSettings(settings, "autoCloseOnLeave", true);
		final closeOnOutsideClick = getBoolSettings(settings, "closeOnOutsideClick", true);
        
		var panel = addScrollableList(panelBuilder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, items, settings, initialIndex);
		final retVal = UIStandardMultiAnimDropdown.createWithPrebuiltPanel(dropdownBuilder, panel, items, initialIndex);

		retVal.autoOpen = autoOpen;
		retVal.autoCloseOnLeave = autoCloseOnLeave;
		retVal.closeOnOutsideClick = closeOnOutsideClick;
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

	public function addElement(element:UIElement, ?layer:LayersEnum) {
		elements.push(element);
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
		if (layer != null) {
			addObjectToLayer(element.getObject(), layer);
		}
		return element;
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
