package bh.ui.screens;

import bh.ui.UIMultiAnimScrollableList.PanelSizeMode;
import bh.ui.UIMultiAnimScrollableList.ClickMode;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIMultiAnimProgressBar.UIMultiAnimProgressBar;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.ui.UIMultiAnimTextInput;
import bh.ui.UIMultiAnimTextInput.TextInputFilter;
import bh.ui.UITabGroup;
import bh.ui.UITabGroup.TabWireMode;
import bh.ui.UIMultiAnimTabs;
import bh.ui.UIMultiAnimTabs.ContentTarget;
import bh.ui.UIMultiAnimGrid;
import bh.ui.UIMultiAnimGridTypes;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.ui.UIElement;
import bh.ui.UIInteractiveWrapper;
import bh.base.MAObject;
import bh.multianim.MultiAnimBuilder;
import bh.stateanim.AnimParser;
import bh.ui.controllers.UIController;
import bh.base.FPoint;
import bh.base.TweenManager;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.ui.UIRichInteractiveHelper;
import bh.ui.UIPanelHelper;
import bh.ui.UIPanelHelper.PanelDefaults;

typedef ModalOverlayConfig = {
	var ?color:Int;
	var ?alpha:Float;
	var ?fadeIn:Float;
	var ?fadeOut:Float;
	var ?blur:Float;
}

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
	var tweens(get, never):TweenManager;
	var groups:Map<String, Array<UIElement>> = [];
	var postCustomAddToLayer:Map<h2d.Object, UIElementCustomAddToLayer> = [];
	var interactiveWrappers:Array<UIInteractiveWrapper> = [];
	var interactiveMap:Map<String, UIInteractiveWrapper> = [];
	var autoStatusHelper:Null<UIRichInteractiveHelper> = null;
	var panelHelpers:Array<UIPanelHelper> = [];
	var tabGroup:Null<UITabGroup> = null;
	var tabAutoWired:Bool = false;
	/** When set, ScreenManager creates a darkening overlay behind this dialog. */
	public var modalOverlayConfig:Null<ModalOverlayConfig> = null;
	private var _autoSyncInitialState:Bool = false;
	var autoSyncInitialState(never, set):Bool;
	var initialSyncDone:Bool = false;

	function set_autoSyncInitialState(value:Bool):Bool {
		if (initialSyncDone)
			throw 'autoSyncInitialState cannot be changed after initial sync has already run';
		return _autoSyncInitialState = value;
	}

	// Content routing for tabs and similar composite containers
	var contentTarget:Null<ContentTarget> = null;
	var contentTargetOwnership:Map<UIElement, ContentTarget> = [];
	var inElementRouting:Bool = false;

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

		this.controllersStack = [new bh.ui.controllers.UIDefaultController(this)];
	}

	function get_tweens():TweenManager {
		return screenManager.tweens;
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
		interactiveWrappers = [];
		interactiveMap.clear();
		if (autoStatusHelper != null)
			autoStatusHelper.unbindAll();
		autoStatusHelper = null;
		panelHelpers = [];
		postCustomAddToLayer.clear();
		contentTarget = null;
		contentTargetOwnership.clear();
		inElementRouting = false;
		initialSyncDone = false;
		for (c in controllersStack) {
			c.clearState();
		}
		getSceneRoot().removeChildren();
		onClear();
	}

	public function onClear() {}

	/** Override to provide a custom enter transition animation.
	 *  Return a Tween that controls the enter animation, or null to use the default.
	 *  The screen root is already in the scene when this is called. */
	public function onEnterTransition(tweens:TweenManager):Null<Tween> {
		return null;
	}

	/** Override to provide a custom exit transition animation.
	 *  Return a Tween that controls the exit animation, or null to use the default.
	 *  The returned Tween's onComplete should NOT be set — the ScreenManager handles cleanup. */
	public function onExitTransition(tweens:TweenManager):Null<Tween> {
		return null;
	}

	public abstract function load():Void;


	public abstract function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;

	/** Dispatch event with auto-wiring handled before onScreenEvent. Called by controllers. */
	public function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		if (autoStatusHelper != null)
			autoStatusHelper.handleEvent(event);
		for (helper in panelHelpers)
			helper.handleOutsideClick(event);
		onScreenEvent(event, source);
	}

	public function onMouseMove(pos:h2d.col.Point):Bool { return true;}
	public function onMouseClick(pos:h2d.col.Point, button:Int, release:Bool):Bool {return true;}
	public function onMouseWheel(pos:h2d.col.Point, delta:Float):Bool { return true;}
	public function onKey(keyCode:Int, release:Bool):Bool {
		if (tabAutoWired && !release && tabGroup != null) {
			if (keyCode == hxd.Key.TAB) {
				final shift = hxd.Key.isDown(hxd.Key.SHIFT) || hxd.Key.isDown(hxd.Key.LSHIFT) || hxd.Key.isDown(hxd.Key.RSHIFT);
				if (tabGroup.handleTab(shift))
					return false;
			}
		}
		return true;
	}

	public function update(dt:Float):Void {
		if (contentTarget != null)
			throw 'content target still set during update — missing endTab() call?';
		if (_autoSyncInitialState && !initialSyncDone) {
			initialSyncDone = true;
			for (el in elements)
				syncInitialState(el);
		}
		for (helper in panelHelpers)
			helper.checkPendingClose();
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
			case RSVColor(c): '$c';
			case RSVFloat(f): '$f';
			case RSVBool(b): b ? "true" : "false";
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
			case RSVColor(c): c;
			case RSVFloat(f): Std.int(f);
			case RSVBool(b): b ? 1 : 0;
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
			case RSVColor(c): c * 1.0;
			case RSVBool(b): b ? 1.0 : 0.0;
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
		return switch (val) {
			case RSVBool(b): b;
			case RSVString(s):
				switch (s.toLowerCase()) {
					case "true" | "1" | "yes": true;
					case "false" | "0" | "no": false;
					default: throw 'could not parse setting "$s" as bool';
				};
			case RSVInt(i): i != 0;
			case RSVColor(c): c != 0;
			case RSVFloat(f): f != 0;
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

	/** Parse modal overlay settings from a BuilderResult's root settings.
	 *  Recognized keys: overlay.color, overlay.alpha, overlay.fadeIn, overlay.fadeOut, overlay.blur. */
	function parseOverlaySettings(rootSettings:BuilderResolvedSettings):Null<ModalOverlayConfig> {
		if (rootSettings == null || !rootSettings.hasSettings())
			return null;
		var hasAny = false;
		var config:ModalOverlayConfig = {};
		if (rootSettings.has("overlay.color")) {
			config.color = rootSettings.getIntOrDefault("overlay.color", 0x000000);
			hasAny = true;
		}
		if (rootSettings.has("overlay.alpha")) {
			config.alpha = rootSettings.getFloatOrDefault("overlay.alpha", 0.5);
			hasAny = true;
		}
		if (rootSettings.has("overlay.fadeIn")) {
			config.fadeIn = rootSettings.getFloatOrDefault("overlay.fadeIn", 0.3);
			hasAny = true;
		}
		if (rootSettings.has("overlay.fadeOut")) {
			config.fadeOut = rootSettings.getFloatOrDefault("overlay.fadeOut", 0.3);
			hasAny = true;
		}
		if (rootSettings.has("overlay.blur")) {
			config.blur = rootSettings.getFloatOrDefault("overlay.blur", 0.0);
			hasAny = true;
		}
		return hasAny ? config : null;
	}

	function settingValueToDynamic(v:SettingValue):Dynamic {
		return switch (v) {
			case RSVInt(i): i;
			case RSVColor(c): c;
			case RSVFloat(f): f;
			case RSVString(s): s;
			case RSVBool(b): b;
		};
	}

	/**
	 * Splits settings into control/behavioral (handled by caller) and pass-through params.
	 * - Control and behavioral settings are skipped (caller handles them explicitly).
	 * - Dotted keys (e.g. "item.fontColor") are routed to the prefixed map.
	 * - Unprefixed keys that are not in multiForward go to the main map.
	 * - Keys listed in multiForward go to ALL registered prefix maps AND main.
	 */
	function splitSettings(settings:ResolvedSettings, controlSettings:Array<String>, behavioralSettings:Array<String>,
			registeredPrefixes:Array<String>, multiForwardSettings:Array<String>,
			elementName:String):{main:Null<Map<String, Dynamic>>, prefixed:Map<String, Map<String, Dynamic>>} {
		var main:Null<Map<String, Dynamic>> = null;
		var prefixed = new Map<String, Map<String, Dynamic>>();

		if (settings == null)
			return {main: main, prefixed: prefixed};

		for (key in settings.keys()) {
			if (controlSettings.contains(key) || behavioralSettings.contains(key))
				continue;

			final sv = settings.get(key);
			if (sv == null)
				continue;
			final value = settingValueToDynamic(sv);
			final dotIdx = key.indexOf(".");
			if (dotIdx > 0) {
				// Prefixed setting: "item.fontColor"
				final prefix = key.substr(0, dotIdx);
				final paramName = key.substr(dotIdx + 1);
				if (!registeredPrefixes.contains(prefix))
					continue; // Skip unknown prefixes (may be inherited from parent, e.g. overlay.*)
				var prefixMap = prefixed.get(prefix);
				if (prefixMap == null) {
					prefixMap = new Map<String, Dynamic>();
					prefixed.set(prefix, prefixMap);
				}
				prefixMap.set(paramName, value);
			} else if (multiForwardSettings.contains(key)) {
				// Multi-forward setting: goes to main AND all registered prefixes
				if (main == null)
					main = new Map<String, Dynamic>();
				main.set(key, value);
				for (prefix in registeredPrefixes) {
					var prefixMap = prefixed.get(prefix);
					if (prefixMap == null) {
						prefixMap = new Map<String, Dynamic>();
						prefixed.set(prefix, prefixMap);
					}
					prefixMap.set(key, value);
				}
			} else {
				// Unprefixed pass-through: goes to main builder
				if (main == null)
					main = new Map<String, Dynamic>();
				main.set(key, value);
			}
		}
		return {main: main, prefixed: prefixed};
	}

	function mergeExtraParams(existing:Null<Map<String, Dynamic>>, additional:Null<Map<String, Dynamic>>):Null<Map<String, Dynamic>> {
		if (additional == null)
			return existing;
		if (existing == null)
			return additional;
		for (key => value in additional)
			existing.set(key, value);
		return existing;
	}

	function addButtonWithSingleBuilder(builder:MultiAnimBuilder, buttonBuilderName:String, settings:ResolvedSettings, text:String):UIStandardMultiAnimButton {
		return addButton(builder.createElementBuilder(buttonBuilderName), text, settings);
	}

	function addButton(builder:UIElementBuilder, text:String, settings:ResolvedSettings):UIStandardMultiAnimButton {
		if (hasSettings(settings, "buildName"))
			builder = builder.withUpdatedName(getSettings(settings, "buildName", "button"));
		final buttonText = getSettings(settings, "text", text);
		final split = splitSettings(settings, ["buildName", "text"], [], [], [], "button");
		return UIStandardMultiAnimButton.create(builder.builder, builder.name, buttonText, split.main);
	}

	function addSlider(providedBuilder, settings:ResolvedSettings, initialValue:Float = 0) {
		final sliderBuildName = getSettings(settings, "buildName", "slider");
		final size = getIntSettings(settings, "size", 200);
		final split = splitSettings(settings, ["buildName", "size"], ["min", "max", "step"], [], [], "slider");
		final slider = UIStandardMultiAnimSlider.create(providedBuilder, sliderBuildName, size, initialValue, split.main);
		if (hasSettings(settings, "min"))
			slider.min = getFloatSettings(settings, "min", 0);
		if (hasSettings(settings, "max"))
			slider.max = getFloatSettings(settings, "max", 100);
		if (hasSettings(settings, "step"))
			slider.step = getFloatSettings(settings, "step", 0);
		return slider;
	}

	function addProgressBar(providedBuilder, settings:ResolvedSettings, initialValue:Int = 0) {
		final barBuildName = getSettings(settings, "buildName", "progressBar");
		final split = splitSettings(settings, ["buildName"], [], [], [], "progressBar");
		return UIMultiAnimProgressBar.create(providedBuilder, barBuildName, initialValue, split.main);
	}

	function addCheckbox(providedBuilder, settings:ResolvedSettings, checked:Null<Bool> = null) {
		final checkboxBuildName = getSettings(settings, "buildName", "checkbox");
		final checkBoxInitialValue = getBoolSettings(settings, "initialValue", checked ?? false);
		final split = splitSettings(settings, ["buildName"], ["initialValue"], [], [], "checkbox");
		return UIStandardMultiCheckbox.create(providedBuilder, checkboxBuildName, checkBoxInitialValue, split.main);
	}

	function addTextInput(providedBuilder:MultiAnimBuilder, settings:ResolvedSettings, ?initialText:String):UIMultiAnimTextInput {
		final buildName = getSettings(settings, "buildName", "textInput");
		final text = getSettings(settings, "text", initialText ?? "");
		final placeholderText = getSettings(settings, "placeholder", "");
		final fontName = getSettings(settings, "font", "");
		final fontColor = getIntSettings(settings, "fontColor", 0xFFFFFF);
		final cursorColor = getIntSettings(settings, "cursorColor", 0xFFFFFF);
		final selectionColor = getIntSettings(settings, "selectionColor", 0x3399FF);

		final split = splitSettings(settings, ["buildName", "text", "placeholder", "font", "fontColor", "cursorColor", "selectionColor"],
			["maxLength", "multiline", "readOnly", "disabled", "filter", "tabIndex", "inputWidth"], [], [], "textInput");

		var extraParams = split.main;
		if (placeholderText != "") {
			if (extraParams == null)
				extraParams = new Map<String, Dynamic>();
			extraParams.set("placeholderText", placeholderText);
		}

		final config:UIMultiAnimTextInput.TextInputConfig = {
			font: fontName,
			fontColor: fontColor,
			cursorColor: cursorColor,
			selectionColor: selectionColor,
			text: text,
			placeholder: placeholderText,
			maxLength: getIntSettings(settings, "maxLength", 0),
			multiline: getBoolSettings(settings, "multiline", false),
			readOnly: getBoolSettings(settings, "readOnly", false),
			inputWidth: getIntSettings(settings, "inputWidth", 0),
			extraParams: extraParams
		};

		final input = UIMultiAnimTextInput.create(providedBuilder, buildName, config);

		if (getBoolSettings(settings, "disabled", false))
			input.disabled = true;

		final filterStr = getSettings(settings, "filter", "none");
		switch filterStr {
			case "numeric":
				input.filter = FNumericOnly;
			case "alphanumeric":
				input.filter = FAlphanumeric;
			default:
		}

		if (tabGroup != null) {
			final tabIndex = getIntSettings(settings, "tabIndex", -1);
			tabGroup.add(input, tabIndex);
			input.tabGroup = tabGroup;
		}

		return input;
	}

	function enableTabNavigation(mode:TabWireMode = Autowire):UITabGroup {
		tabGroup = new UITabGroup();
		tabAutoWired = mode == Autowire;
		return tabGroup;
	}

	function addRadio(providedBuilder, settings:ResolvedSettings, items:Array<UIElementListItem>, vertical:Bool, selectedIndex:Int = 0) {
		final radioBuildName = getSettings(settings, "radioBuildName", vertical ? "radioButtonsVertical" : "radioButtonsHorizontal");
		final singleRadioButtonBuilderName = getSettings(settings, "radioButtonBuildName", "radio");
		final split = splitSettings(settings, ["radioBuildName", "radioButtonBuildName"], [], [], [], "radio");
		return UIMultiAnimRadioButtons.create(providedBuilder, radioBuildName, singleRadioButtonBuilderName, items, selectedIndex, split.main);
	}

	function addTabs(providedBuilder:MultiAnimBuilder, settings:ResolvedSettings, items:Array<UIElementListItem>, selectedIndex:Int = 0) {
		final tabBarBuildName = getSettings(settings, "buildName", "tabBar");
		final tabButtonBuildName = getSettings(settings, "tabButtonBuildName", "tab");
		final split = splitSettings(settings, ["buildName", "tabButtonBuildName"], [], ["tabButton", "tabPanel"], [], "tabs");
		final tabButtonParams = split.prefixed.get("tabButton");

		// Merge tabPanel.* prefix params into tab bar extra params (width→panelWidth, height→panelHeight, offset→panelOffset)
		var extraParams:Null<Map<String, Dynamic>> = cast split.main;
		final tabPanelParams = split.prefixed.get("tabPanel");
		// Extract contentRoot before merging — it's a behavioral setting, not forwarded to programmable
		var contentRootName:Null<String> = null;
		if (tabPanelParams != null) {
			final crValue = tabPanelParams.get("contentRoot");
			if (crValue != null) {
				contentRootName = Std.string(crValue);
				tabPanelParams.remove("contentRoot");
			}
			if (extraParams == null)
				extraParams = new Map();
			for (key => value in tabPanelParams)
				extraParams.set('panel${key.charAt(0).toUpperCase()}${key.substr(1)}', value);
		}

		// Forward tab button height to tabBar so .manim can compute panelOffset from it
		{
			if (extraParams == null)
				extraParams = new Map();
			var tabHeight:Dynamic = 30;
			if (tabButtonParams != null) {
				var h = tabButtonParams.get("height");
				if (h != null)
					tabHeight = h;
			}
			if (!extraParams.exists("tabButtonHeight"))
				extraParams.set("tabButtonHeight", tabHeight);
		}

		return new UIMultiAnimTabs(providedBuilder, tabBarBuildName, tabButtonBuildName, items, selectedIndex, this, extraParams, tabButtonParams,
			contentRootName, layers);
	}

	function addText(textValue:String, fontName:String, ?layer:LayersEnum) {
		final textObj = new h2d.Text(bh.base.FontManager.getFontByName(fontName));
		textObj.text = textValue;
		return addObjectToLayer(textObj, layer);
	}

	function addGrid(builder:MultiAnimBuilder, config:UIMultiAnimGridTypes.GridConfig, ?layer:LayersEnum):UIMultiAnimGrid {
		final grid = new UIMultiAnimGrid(builder, config);
		addObjectToLayer(grid.getObject(), layer);
		return grid;
	}

	/** Create a PanelHelper that is auto-wired for outside-click handling.
	 *  handleOutsideClick() runs in dispatchScreenEvent(), checkPendingClose() runs in update(). */
	function createPanelHelper(builder:MultiAnimBuilder, ?defaults:PanelDefaults, ?tweenManager:TweenManager):UIPanelHelper {
		final tw = tweenManager != null ? tweenManager : (screenManager != null ? tweens : null);
		final helper = new UIPanelHelper(this, builder, defaults, tw);
		registerPanelHelper(helper);
		return helper;
	}

	/** Register an existing PanelHelper for auto-wired outside-click handling. */
	function registerPanelHelper(helper:UIPanelHelper):Void {
		if (!panelHelpers.contains(helper))
			panelHelpers.push(helper);
	}

	/** Unregister a PanelHelper from auto-wired outside-click handling. */
	function unregisterPanelHelper(helper:UIPanelHelper):Void {
		panelHelpers.remove(helper);
	}

    function addScrollableListWithSingleBuilder(builder:MultiAnimBuilder, panelBuilderName:String, itemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
        return addScrollableList(builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(itemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex, width, height);
    }

	function addScrollableList(panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex:Int = 0, width:Int = 100, height:Int = 100):UIMultiAnimScrollableList {
		if (hasSettings(settings, "panelBuildName"))
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuildName", ""));
		if (hasSettings(settings, "itemBuildName"))
			itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuildName", ""));
		if (hasSettings(settings, "scrollbarBuildName"))
			scrollbarBuilder = scrollbarBuilder.withUpdatedName(getSettings(settings, "scrollbarBuildName", ""));
		if (hasSettings(settings, "scrollbarInPanelName"))
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", "scrollbar");
		final panelModeStr = getSettings(settings, "panelMode", "scrollable");
		final sizeMode:PanelSizeMode = if (panelModeStr == "scalable") AutoSize else FixedScroll;

		final split = splitSettings(settings,
			["panelBuildName", "itemBuildName", "scrollbarBuildName", "scrollbarInPanelName", "panelMode",
			 "width", "height", "topClearance"],
			["scrollSpeed", "doubleClickThreshold", "wheelScrollMultiplier", "clickMode"],
			["item", "scrollbar"],
			["font", "fontColor"],
			"scrollableList");

		// Apply prefixed and multi-forward params to sub-builders
		final itemPrefixed = split.prefixed.get("item");
		if (itemPrefixed != null)
			itemBuilder = itemBuilder.withExtraParams(itemPrefixed);
		final scrollbarPrefixed = split.prefixed.get("scrollbar");
		if (scrollbarPrefixed != null)
			scrollbarBuilder = scrollbarBuilder.withExtraParams(scrollbarPrefixed);

		final finalWidth = getIntSettings(settings, "width", width);
		final finalHeight = getIntSettings(settings, "height", height);
		final topClearance = getIntSettings(settings, "topClearance", 0);
		final list = UIMultiAnimScrollableList.create(panelBuilder, itemBuilder, scrollbarBuilder, scrollbarInPanelName, finalWidth, finalHeight, items, topClearance, initialIndex, sizeMode);
		if (hasSettings(settings, "scrollSpeed"))
			list.scrollSpeedOverride = getFloatSettings(settings, "scrollSpeed", 100);
		if (hasSettings(settings, "doubleClickThreshold"))
			list.doubleClickThreshold = getFloatSettings(settings, "doubleClickThreshold", 0.3);
		if (hasSettings(settings, "wheelScrollMultiplier"))
			list.wheelScrollMultiplier = getFloatSettings(settings, "wheelScrollMultiplier", 10);
		if (hasSettings(settings, "clickMode"))
			list.clickMode = if (getSettings(settings, "clickMode", "double") == "single") SingleClick else DoubleClick;
		return list;
	}



	 function addDropdownWithSingleBuilder(builder:MultiAnimBuilder, dropdownBuilderName:String, panelBuilderName:String, panelListItemBuilderName:String, scrollbarBuilderName:String, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		return addDropdown(builder.createElementBuilder(dropdownBuilderName), builder.createElementBuilder(panelBuilderName), builder.createElementBuilder(panelListItemBuilderName), builder.createElementBuilder(scrollbarBuilderName), scrollbarInPanelName, items, settings, initialIndex);
	}

	function addDropdown(dropdownBuilder:UIElementBuilder, panelBuilder:UIElementBuilder, itemBuilder:UIElementBuilder, scrollbarBuilder:UIElementBuilder, scrollbarInPanelName:String, items, settings:ResolvedSettings, initialIndex = 0) {
		if (hasSettings(settings, "panelBuildName"))
			panelBuilder = panelBuilder.withUpdatedName(getSettings(settings, "panelBuildName", ""));
		if (hasSettings(settings, "itemBuildName"))
			itemBuilder = itemBuilder.withUpdatedName(getSettings(settings, "itemBuildName", ""));
		if (hasSettings(settings, "dropdownBuildName"))
			dropdownBuilder = dropdownBuilder.withUpdatedName(getSettings(settings, "dropdownBuildName", ""));
		if (hasSettings(settings, "scrollbarBuildName"))
			scrollbarBuilder = scrollbarBuilder.withUpdatedName(getSettings(settings, "scrollbarBuildName", ""));
		if (hasSettings(settings, "scrollbarInPanelName"))
			scrollbarInPanelName = getSettings(settings, "scrollbarInPanelName", scrollbarInPanelName);
		final panelModeStr = getSettings(settings, "panelMode", "scrollable");
		final sizeMode:PanelSizeMode = if (panelModeStr == "scalable") AutoSize else FixedScroll;

		final split = splitSettings(settings,
			["dropdownBuildName", "panelBuildName", "itemBuildName", "scrollbarBuildName", "scrollbarInPanelName", "panelMode",
			 "width", "height", "topClearance"],
			["autoOpen", "autoCloseOnLeave", "closeOnOutsideClick", "transitionTimer",
			 "scrollSpeed", "doubleClickThreshold", "wheelScrollMultiplier"],
			["dropdown", "item", "scrollbar"],
			["font", "fontColor"],
			"dropdown");

		// Apply prefixed and multi-forward params to sub-builders
		final dropdownPrefixed = split.prefixed.get("dropdown");
		if (dropdownPrefixed != null)
			dropdownBuilder = dropdownBuilder.withExtraParams(dropdownPrefixed);
		final itemPrefixed = split.prefixed.get("item");
		if (itemPrefixed != null)
			itemBuilder = itemBuilder.withExtraParams(itemPrefixed);
		final scrollbarPrefixed = split.prefixed.get("scrollbar");
		if (scrollbarPrefixed != null)
			scrollbarBuilder = scrollbarBuilder.withExtraParams(scrollbarPrefixed);

		final autoOpen = getBoolSettings(settings, "autoOpen", true);
		final autoCloseOnLeave = getBoolSettings(settings, "autoCloseOnLeave", true);
		final closeOnOutsideClick = getBoolSettings(settings, "closeOnOutsideClick", true);
		final panelWidth = getIntSettings(settings, "width", 120);
		final panelHeight = getIntSettings(settings, "height", 300);
		final topClearance = getIntSettings(settings, "topClearance", 0);
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

	@:allow(bh.ui.UIMultiAnimTabs)
	function setContentTarget(target:ContentTarget) {
		if (contentTarget != null)
			throw 'content target already set';
		contentTarget = target;
	}

	@:allow(bh.ui.UIMultiAnimTabs)
	function clearContentTarget() {
		if (contentTarget == null)
			throw 'no content target set';
		contentTarget = null;
	}

	public function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum) {
		// Register standalone objects for visibility management.
		// Skip when called from addElement routing (element already registered).
		if (contentTarget != null && !inElementRouting) {
			contentTarget.registerObject(object);
		}
		final resolvedLayer = layer ?? DefaultLayer;
		final layerIdxN = layers.get(resolvedLayer);
		if (layerIdxN == null)
			throw 'layer not found $resolvedLayer';
		final layerIdx:Int = layerIdxN;
		// When content target handles its own scene graph, delegate to it
		if (contentTarget != null && contentTarget.handlesSceneGraph()) {
			contentTarget.addToLayer(object, layerIdx);
		} else {
			getSceneRoot().add(object, layerIdx);
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

	/** Wraps a single interactive MAObject as a UIElement. Events arrive in `onScreenEvent` as `UIInteractiveEvent(event, id, metadata)`. */
	public function addInteractive(obj:MAObject, ?prefix:String):UIInteractiveWrapper {
		var wrapper = new UIInteractiveWrapper(obj, prefix);
		interactiveWrappers.push(wrapper);
		interactiveMap.set(wrapper.id, wrapper);
		addElement(wrapper, null);
		return wrapper;
	}

	/** Registers all `interactive()` elements from a builder result. Events arrive in `onScreenEvent` as `UIInteractiveEvent(event, id, metadata)`.
	 *  Interactives with `autoStatus` metadata are automatically wired for Normal→Hover→Pressed state management. */
	public function addInteractives(r:BuilderResult, ?prefix:String):Array<UIInteractiveWrapper> {
		var wrappers:Array<UIInteractiveWrapper> = [];
		for (obj in r.interactives) {
			wrappers.push(addInteractive(obj, prefix));
		}
		// Auto-wire interactives with autoStatus metadata
		var hasAutoStatus = false;
		for (obj in r.interactives) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, _, meta):
					if (meta != null) {
						final brs = new BuilderResolvedSettings(meta);
						if (brs.getStringOrDefault(UIRichInteractiveHelper.RESERVED_KEY, "") != "") {
							hasAutoStatus = true;
							break;
						}
					}
				default:
			}
		}
		if (hasAutoStatus) {
			if (autoStatusHelper == null)
				autoStatusHelper = new UIRichInteractiveHelper(this);
			autoStatusHelper.registerAutoStatus(r, prefix);
		}
		return wrappers;
	}

	/** Wires hyperlink events from rich text `[link:id]` markup to UIInteractiveEvent.
	 *  Events arrive in `onScreenEvent` as `UIInteractiveEvent(UIClick/UIEntering/UILeaving, "link:<id>", emptyMeta)`.
	 *  Cursor is already handled at builder level; this method adds UIInteractiveEvent emission for screen integration. */
	@:nullSafety(Off)
	public function enableLinkEvents(r:BuilderResult, ?prefix:String):Void {
		if (r.htmlTextsWithLinks == null) return;
		final emptyMeta = new BuilderResolvedSettings(null);
		for (ht in r.htmlTextsWithLinks) {
			final prevClick = ht.onHyperlink;
			ht.onHyperlink = (url) -> {
				if (prevClick != null) prevClick(url);
				final id = prefix != null ? prefix + ".link:" + url : "link:" + url;
				getController().onScreenEvent(UIInteractiveEvent(UIClick, id, emptyMeta), null);
			};
			final prevOver = ht.onOverHyperlink;
			ht.onOverHyperlink = (url) -> {
				if (prevOver != null) prevOver(url);
				final id = prefix != null ? prefix + ".link:" + url : "link:" + url;
				getController().onScreenEvent(UIInteractiveEvent(UIEntering, id, emptyMeta), null);
			};
			final prevOut = ht.onOutHyperlink;
			ht.onOutHyperlink = (url) -> {
				if (prevOut != null) prevOut(url);
				final id = prefix != null ? prefix + ".link:" + url : "link:" + url;
				getController().onScreenEvent(UIInteractiveEvent(UILeaving, id, emptyMeta), null);
			};
		}
	}

	public function removeInteractives(?prefix:String):Void {
		var toRemove:Array<UIInteractiveWrapper> = [];
		for (w in interactiveWrappers) {
			if (prefix == null || w.prefix == prefix)
				toRemove.push(w);
		}
		for (w in toRemove) {
			interactiveWrappers.remove(w);
			interactiveMap.remove(w.id);
			removeElement(w);
		}
		// Auto-unregister from autoStatus helper
		if (autoStatusHelper != null) {
			if (prefix != null)
				autoStatusHelper.unregisterByPrefix(prefix);
			else
				autoStatusHelper.unbindAll();
		}
	}

	/** O(1) lookup of interactive wrapper by id. */
	public function getInteractive(id:String):Null<UIInteractiveWrapper> {
		return interactiveMap.get(id);
	}

	/** Returns all interactive wrappers with the given prefix. */
	public function getInteractivesByPrefix(prefix:String):Array<UIInteractiveWrapper> {
		return [for (w in interactiveWrappers) if (w.prefix == prefix) w];
	}

	/** Returns the screen's auto-wiring helper for `autoStatus` interactives, or null if none registered.
	 *  Use for advanced operations like `setDisabled()` or `setParameter()` on auto-wired interactives. */
	public function getAutoInteractiveHelper():Null<UIRichInteractiveHelper> {
		return autoStatusHelper;
	}

	public function addElement(element:UIElement, layer:Null<LayersEnum>) {
		if (contentTarget != null) {
			// Route to content target (tabs, etc.) instead of main element list
			contentTarget.registerElement(element);
			contentTargetOwnership.set(element, contentTarget);
			// Still add to scene graph for rendering — but suppress registerObject
			// since registerElement already covers this element's visibility
			inElementRouting = true;
			if (Std.isOfType(element, UIElementSubElements)) {
				subElementProviders.push(cast(element, UIElementSubElements));
			}
			if (Std.isOfType(element, UIElementCustomAddToLayer)) {
				final customElement:UIElementCustomAddToLayer = cast(element, UIElementCustomAddToLayer);
				final result = customElement.customAddToLayer(layer, this, false);
				switch result {
					case Added:
						inElementRouting = false;
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
			inElementRouting = false;
			return element;
		}

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
		var owner = contentTargetOwnership.get(element);
		if (owner != null) {
			owner.unregisterElement(element);
			contentTargetOwnership.remove(element);
		} else {
			elements.remove(element);
		}
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
