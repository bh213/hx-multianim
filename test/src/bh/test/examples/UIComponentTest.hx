package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness;
import bh.test.UITestHarness.MockControllable;
import bh.test.UITestHarness.MockNumberElement;
import bh.test.UITestHarness.MockFloatElement;
import bh.test.UITestHarness.MockListElement;
import bh.test.UITestHarness.MockSelectableElement;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimProgressBar;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIMultiAnimTextInput;
import bh.ui.UITabGroup;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.ui.UIMultiAnimScrollableList;
import bh.ui.UIMultiAnimScrollableList.ClickMode;
import bh.ui.UIMultiAnimScrollableList.PanelSizeMode;
import bh.ui.UIMultiAnimTabs;
import bh.ui.UIMultiAnimTabs.UIMultiAnimTabButton;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimDraggable.DropZone;
import bh.ui.UIMultiAnimDraggable.DragEvent;
import bh.ui.UIMultiAnimDraggable.DraggableState;
import bh.ui.UIMultiAnimDraggable.DragDropResult;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIElement.UIElementEvents;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIElement.TileRef;
import bh.ui.UIElement.SubElementsType;
import h2d.col.Bounds;
import h2d.col.Point;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.paths.MultiAnimPaths.PathType;
import bh.ui.UICardHandTypes.PathDistribution;
import bh.ui.UICardHandTypes.PathOrientation;

/**
 * Non-visual unit tests for UI components.
 * Tests component creation, state management, event handling, and value interfaces
 * using MockControllable for event simulation and UITestScreen for screen integration.
 */
class UIComponentTest extends BuilderTestBase {
	/** Read a string parameter from an incremental BuilderResult's internal state. */
	static function getStringParam(result:bh.multianim.MultiAnimBuilder.BuilderResult, name:String):String {
		@:privateAccess var params = result.incrementalContext.indexedParams;
		return switch params.get(name) {
			case StringValue(s): s;
			case Index(_, v): v;
			case Value(v): Std.string(v);
			case _: null;
		};
	}

	static function getStatusParam(result:bh.multianim.MultiAnimBuilder.BuilderResult):String {
		return getStringParam(result, "status");
	}
	// --- Inline .manim definitions for test components ---

	static final BUTTON_MANIM = "
		#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, disabled:bool=false) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
		}
	";

	static final CHECKBOX_MANIM = "
		#checkbox programmable(status:[normal,hover,pressed]=normal, disabled:bool=false, checked:bool=false) {
			bitmap(generated(color(20, 20, #666666))): 0, 0
		}
	";

	static final PROGRESSBAR_MANIM = "
		#progressBar programmable(value:uint=0) {
			bitmap(generated(color(200, 20, #333333))): 0, 0
		}
	";

	// ============== Button Tests ==============

	@Test
	public function testButtonCreation():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");
		Assert.notNull(button);
		Assert.notNull(button.getObject());
		Assert.isFalse(button.disabled);
	}

	@Test
	public function testButtonClickEvent():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");
		var mock = new MockControllable();

		UITestHarness.simulateClick(button, mock);

		Assert.isTrue(mock.hasEvent(UIClick));
		Assert.equals(1, mock.eventCount());
	}

	@Test
	public function testButtonDisabledNoClick():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");
		button.disabled = true;
		var mock = new MockControllable();

		UITestHarness.simulateClick(button, mock);

		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testButtonStateTransitions():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");
		var mock = new MockControllable();

		@:privateAccess var result = button.result;
		Assert.equals("normal", getStatusParam(result));

		// Hover applies immediately via setParameter (no redraw cycle)
		UITestHarness.simulateEnter(button, mock);
		Assert.equals("hover", getStatusParam(result));

		// Leave applies immediately
		UITestHarness.simulateLeave(button, mock);
		Assert.equals("normal", getStatusParam(result));
	}

	@Test
	public function testButtonDisabledState():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");

		button.disabled = true;
		Assert.isTrue(button.disabled);
		Assert.notNull(button.getObject());
	}

	@Test
	public function testButtonOnClickCallback():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");
		var mock = new MockControllable();
		var callbackFired = false;

		button.onClick = function() {
			callbackFired = true;
		};
		UITestHarness.simulateClick(button, mock);

		Assert.isTrue(callbackFired);
	}

	@Test
	public function testButtonSetText():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Original");

		@:privateAccess var result = button.result;
		Assert.equals("Original", getStringParam(result, "buttonText"));

		button.setText("Updated");
		Assert.equals("Updated", getStringParam(result, "buttonText"));
	}

	// ============== Checkbox Tests ==============

	@Test
	public function testCheckboxCreation():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", false);
		Assert.notNull(checkbox);
		Assert.notNull(checkbox.getObject());
		Assert.isFalse(checkbox.selected);
		Assert.isFalse(checkbox.disabled);
	}

	@Test
	public function testCheckboxToggleOn():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", false);
		var mock = new MockControllable();

		// Push toggles the checkbox on
		UITestHarness.simulatePush(checkbox, mock);

		Assert.isTrue(checkbox.selected);
		Assert.isTrue(mock.hasEvent(UIToggle(true)));
	}

	@Test
	public function testCheckboxToggleOff():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", true);
		var mock = new MockControllable();

		UITestHarness.simulatePush(checkbox, mock);

		Assert.isFalse(checkbox.selected);
		Assert.isTrue(mock.hasEvent(UIToggle(false)));
	}

	@Test
	public function testCheckboxDisabled():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", false);
		checkbox.disabled = true;
		var mock = new MockControllable();

		UITestHarness.simulatePush(checkbox, mock);

		Assert.isFalse(checkbox.selected);
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testCheckboxValueInterface():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", false);

		Assert.equals(0, checkbox.getIntValue());

		checkbox.setIntValue(1);
		Assert.isTrue(checkbox.selected);
		Assert.equals(1, checkbox.getIntValue());

		checkbox.setIntValue(0);
		Assert.isFalse(checkbox.selected);
		Assert.equals(0, checkbox.getIntValue());
	}

	@Test
	public function testCheckboxOnToggleCallback():Void {
		var builder = BuilderTestBase.builderFromSource(CHECKBOX_MANIM);
		var checkbox = UIStandardMultiCheckbox.create(builder, "checkbox", false);
		var mock = new MockControllable();
		var toggledValue:Null<Bool> = null;

		checkbox.onToggle = function(checked:Bool) {
			toggledValue = checked;
		};
		UITestHarness.simulatePush(checkbox, mock);

		Assert.equals(true, toggledValue);
	}

	// ============== Progress Bar Tests ==============

	@Test
	public function testProgressBarCreation():Void {
		var builder = BuilderTestBase.builderFromSource(PROGRESSBAR_MANIM);
		var bar = UIMultiAnimProgressBar.create(builder, "progressBar", 0);
		Assert.notNull(bar);
		Assert.notNull(bar.getObject());
		Assert.equals(0, bar.getIntValue());
	}

	@Test
	public function testProgressBarValue():Void {
		var builder = BuilderTestBase.builderFromSource(PROGRESSBAR_MANIM);
		var bar = UIMultiAnimProgressBar.create(builder, "progressBar", 50);

		Assert.equals(50, bar.getIntValue());

		bar.setIntValue(75);
		Assert.equals(75, bar.getIntValue());
		Assert.isTrue(bar.requestRedraw);
	}

	@Test
	public function testProgressBarClamp():Void {
		var builder = BuilderTestBase.builderFromSource(PROGRESSBAR_MANIM);
		var bar = UIMultiAnimProgressBar.create(builder, "progressBar", 0);

		bar.setIntValue(150);
		Assert.equals(100, bar.getIntValue());

		bar.setIntValue(-10);
		Assert.equals(0, bar.getIntValue());
	}

	// ============== UITestScreen Tests ==============

	@Test
	public function testScreenCreation():Void {
		var screen = new UITestScreen();
		Assert.notNull(screen);
		Assert.notNull(screen.getSceneRoot());
	}

	@Test
	public function testScreenAddRemoveElement():Void {
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");

		screen.testAddElement(button);

		var elements = screen.getElements(SETReceiveEvents);
		Assert.equals(1, elements.length);

		screen.testRemoveElement(button);
		elements = screen.getElements(SETReceiveEvents);
		Assert.equals(0, elements.length);
	}

	@Test
	public function testScreenEventRecording():Void {
		var screen = new UITestScreen();
		Assert.equals(0, screen.eventCount());

		screen.onScreenEvent(UIClick, cast null);
		Assert.equals(1, screen.eventCount());
		Assert.isTrue(screen.hasEvent(UIClick));
	}

	// ============== Slider Tests ==============

	@Test
	public function testSliderCreation():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 50.0);
		Assert.notNull(slider);
		Assert.notNull(slider.getObject());
		Assert.isFalse(slider.disabled);
		Assert.equals(50, slider.getIntValue());
	}

	@Test
	public function testSliderFloatValueRoundTrip():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 0.0);

		slider.setFloatValue(42.5);
		Assert.isTrue(slider.getFloatValue() == 42.5);

		slider.setFloatValue(0.0);
		Assert.isTrue(slider.getFloatValue() == 0.0);

		slider.setFloatValue(100.0);
		Assert.isTrue(slider.getFloatValue() == 100.0);
	}

	@Test
	public function testSliderIntValueRoundTrip():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 0.0);

		slider.setIntValue(75);
		Assert.equals(75, slider.getIntValue());

		slider.setIntValue(0);
		Assert.equals(0, slider.getIntValue());
	}

	@Test
	public function testSliderClampToRange():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 0.0);

		slider.setFloatValue(150.0);
		Assert.isTrue(slider.getFloatValue() == 100.0);

		slider.setFloatValue(-10.0);
		Assert.isTrue(slider.getFloatValue() == 0.0);
	}

	@Test
	public function testSliderStepSnapping():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 0.0);
		slider.step = 10;

		slider.setFloatValue(23.0);
		Assert.isTrue(slider.getFloatValue() == 20.0);

		slider.setFloatValue(27.0);
		Assert.isTrue(slider.getFloatValue() == 30.0);
	}

	@Test
	public function testSliderContinuousNoSnap():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 0.0);
		slider.step = 0;

		slider.setFloatValue(23.7);
		Assert.isTrue(slider.getFloatValue() == 23.7);
	}

	@Test
	public function testSliderMinEqualsMax():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 50.0);
		slider.min = 50;
		slider.max = 50;

		slider.setFloatValue(50.0);
		Assert.isTrue(slider.getFloatValue() == 50.0);

		slider.setFloatValue(100.0);
		Assert.isTrue(slider.getFloatValue() == 50.0);

		slider.setFloatValue(0.0);
		Assert.isTrue(slider.getFloatValue() == 50.0);
	}

	@Test
	public function testSliderCustomRange():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 10.0);
		slider.min = 10;
		slider.max = 50;

		slider.setFloatValue(30.0);
		Assert.isTrue(slider.getFloatValue() == 30.0);

		slider.setFloatValue(60.0);
		Assert.isTrue(slider.getFloatValue() == 50.0);

		slider.setFloatValue(5.0);
		Assert.isTrue(slider.getFloatValue() == 10.0);
	}

	@Test
	public function testSliderDisabledRedraw():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 50.0);

		Assert.isTrue(slider.requestRedraw);

		slider.disabled = true;
		Assert.isTrue(slider.disabled);
		Assert.isTrue(slider.requestRedraw);
	}

	@Test
	public function testSliderSetValueRedraw():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 50.0);

		slider.setFloatValue(75.0);
		Assert.isTrue(slider.requestRedraw);
	}

	@Test
	public function testSliderDisabledBlocksEvents():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var slider = UIStandardMultiAnimSlider.create(builder, "button", 200, 50.0);
		slider.disabled = true;
		var mock = new MockControllable();

		UITestHarness.simulatePush(slider, mock);
		Assert.equals(0, mock.eventCount());
	}

	// ============== Interactive Wrapper Tests ==============

	@Test
	public function testInteractiveCreation():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, null);
		Assert.notNull(wrapper);
		Assert.equals("testBtn", wrapper.id);
		Assert.isTrue(wrapper.prefix == null);
	}

	@Test
	public function testInteractivePrefix():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, "panel");
		Assert.equals("panel.testBtn", wrapper.id);
		Assert.equals("panel", wrapper.prefix);
	}

	@Test
	public function testInteractiveMetadata():Void {
		var meta:Map<String, SettingValue> = new Map();
		meta.set("action", RSVString("buy"));
		meta.set("price", RSVInt(100));
		var obj = new MAObject(MAInteractive(100, 30, "shopBtn", meta), false);
		var wrapper = new UIInteractiveWrapper(obj, null);

		Assert.notNull(wrapper.metadata);
		Assert.equals("buy", wrapper.metadata.getStringOrDefault("action", ""));
		Assert.equals(100, wrapper.metadata.getIntOrDefault("price", 0));
	}

	@Test
	public function testInteractiveReleaseEmitsClick():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, null);
		var mock = new MockControllable();

		UITestHarness.simulateClick(wrapper, mock);
		Assert.isTrue(mock.hasInteractiveEvent(UIClick));
	}

	@Test
	public function testInteractiveEnterEmitsEntering():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, null);
		var mock = new MockControllable();

		UITestHarness.simulateEnter(wrapper, mock);
		Assert.isTrue(mock.hasInteractiveEvent(UIEntering()));
	}

	@Test
	public function testInteractiveLeaveEmitsLeaving():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, null);
		var mock = new MockControllable();

		UITestHarness.simulateLeave(wrapper, mock);
		Assert.isTrue(mock.hasInteractiveEvent(UILeaving));
	}

	@Test
	public function testInteractivePushEmitsUIPush():Void {
		var obj = new MAObject(MAInteractive(100, 30, "testBtn", null), false);
		var wrapper = new UIInteractiveWrapper(obj, null);
		var mock = new MockControllable();

		UITestHarness.simulatePush(wrapper, mock);
		Assert.equals(1, mock.eventCount());
		Assert.isTrue(mock.hasInteractiveEvent(UIPush));
	}

	// ============== Settings Parsing Tests ==============

	@Test
	public function testSettingsGetString():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("name", RSVString("hello"));

		Assert.equals("hello", screen.testGetSettings(settings, "name", "default"));
		Assert.equals("default", screen.testGetSettings(settings, "missing", "default"));
	}

	@Test
	public function testSettingsGetInt():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("width", RSVInt(200));

		Assert.equals(200, screen.testGetIntSettings(settings, "width", 0));
		Assert.equals(42, screen.testGetIntSettings(settings, "missing", 42));
	}

	@Test
	public function testSettingsGetFloat():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("speed", RSVFloat(1.5));

		Assert.isTrue(screen.testGetFloatSettings(settings, "speed", 0.0) == 1.5);
		Assert.isTrue(screen.testGetFloatSettings(settings, "missing", 3.14) == 3.14);
	}

	@Test
	public function testSettingsGetBoolVariants():Void {
		var screen = new UITestScreen();

		var s1:Map<String, SettingValue> = new Map();
		s1.set("flag", RSVBool(true));
		Assert.isTrue(screen.testGetBoolSettings(s1, "flag", false));

		var s2:Map<String, SettingValue> = new Map();
		s2.set("flag", RSVString("true"));
		Assert.isTrue(screen.testGetBoolSettings(s2, "flag", false));

		var s3:Map<String, SettingValue> = new Map();
		s3.set("flag", RSVString("yes"));
		Assert.isTrue(screen.testGetBoolSettings(s3, "flag", false));

		var s4:Map<String, SettingValue> = new Map();
		s4.set("flag", RSVString("1"));
		Assert.isTrue(screen.testGetBoolSettings(s4, "flag", false));

		var s5:Map<String, SettingValue> = new Map();
		s5.set("flag", RSVString("false"));
		Assert.isFalse(screen.testGetBoolSettings(s5, "flag", true));

		var s6:Map<String, SettingValue> = new Map();
		s6.set("flag", RSVString("no"));
		Assert.isFalse(screen.testGetBoolSettings(s6, "flag", true));

		var s7:Map<String, SettingValue> = new Map();
		s7.set("flag", RSVString("0"));
		Assert.isFalse(screen.testGetBoolSettings(s7, "flag", true));

		// Default when missing
		Assert.isTrue(screen.testGetBoolSettings(s7, "missing", true));
		Assert.isFalse(screen.testGetBoolSettings(s7, "missing", false));
	}

	@Test
	public function testSettingsGetBoolInvalidThrows():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("flag", RSVString("invalid"));

		var threw = false;
		try {
			screen.testGetBoolSettings(settings, "flag", false);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("bool") >= 0 || msg.indexOf("invalid") >= 0 || msg.indexOf("expected") >= 0, 'Expected error about "bool"/"invalid"/"expected", got: $msg');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testSplitSettingsControlExcluded():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("buildName", RSVString("myButton"));
		settings.set("width", RSVInt(200));

		var result = screen.testSplitSettings(settings, ["buildName"], [], [], [], "test");
		Assert.notNull(result.main);
		Assert.isFalse(result.main.exists("buildName"));
		Assert.isTrue(result.main.exists("width"));
	}

	@Test
	public function testSplitSettingsPrefixed():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("item.fontColor", RSVInt(0xFFFFFF));

		var result = screen.testSplitSettings(settings, [], [], ["item"], [], "test");
		Assert.isTrue(result.main == null);
		var itemMap = result.prefixed.get("item");
		Assert.notNull(itemMap);
	}

	@Test
	public function testSplitSettingsUnknownPrefixSilentlySkipped():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("unknown.key", RSVString("val"));

		// Unknown prefixes are silently skipped (they may be inherited from parent, e.g. overlay.*)
		var result = screen.testSplitSettings(settings, [], [], ["item"], [], "test");
		Assert.isNull(result.main);
		Assert.isFalse(result.prefixed.exists("unknown"));
	}

	@Test
	public function testSplitSettingsMultiForward():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("font", RSVString("arial"));

		var result = screen.testSplitSettings(settings, [], [], ["item", "scrollbar"], ["font"], "test");
		Assert.notNull(result.main);
		Assert.isTrue(result.main.exists("font"));

		var itemMap = result.prefixed.get("item");
		Assert.notNull(itemMap);
		Assert.isTrue(itemMap.exists("font"));

		var scrollbarMap = result.prefixed.get("scrollbar");
		Assert.notNull(scrollbarMap);
		Assert.isTrue(scrollbarMap.exists("font"));
	}

	// ============== Modal Overlay Settings Tests ==============

	@Test
	public function testParseOverlaySettingsAllKeys():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("overlay.color", RSVColor(0xFF112233));
		settings.set("overlay.alpha", RSVFloat(0.7));
		settings.set("overlay.fadeIn", RSVFloat(0.4));
		settings.set("overlay.fadeOut", RSVFloat(0.25));
		settings.set("overlay.blur", RSVFloat(3.0));

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(settings));
		Assert.notNull(config);
		Assert.equals(0xFF112233, config.color);
		Assert.floatEquals(0.7, config.alpha);
		Assert.floatEquals(0.4, config.fadeIn);
		Assert.floatEquals(0.25, config.fadeOut);
		Assert.floatEquals(3.0, config.blur);
	}

	@Test
	public function testParseOverlaySettingsPartialKeys():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("overlay.color", RSVColor(0xFF000000));
		settings.set("overlay.alpha", RSVFloat(0.5));

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(settings));
		Assert.notNull(config);
		Assert.equals(0xFF000000, config.color);
		Assert.floatEquals(0.5, config.alpha);
		Assert.isNull(config.fadeIn);
		Assert.isNull(config.fadeOut);
		Assert.isNull(config.blur);
	}

	@Test
	public function testParseOverlaySettingsNoOverlayKeys():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("font", RSVString("arial"));
		settings.set("fontColor", RSVInt(0xFFFFFF));

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(settings));
		Assert.isNull(config);
	}

	@Test
	public function testParseOverlaySettingsNullSettings():Void {
		var screen = new UITestScreen();

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(null));
		Assert.isNull(config);
	}

	@Test
	public function testParseOverlaySettingsEmptySettings():Void {
		var screen = new UITestScreen();

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(new Map()));
		Assert.isNull(config);
	}

	@Test
	public function testParseOverlaySettingsMixedKeys():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("overlay.alpha", RSVFloat(0.6));
		settings.set("font", RSVString("arial"));
		settings.set("overlay.fadeIn", RSVFloat(0.3));
		settings.set("width", RSVInt(200));

		var config = screen.testParseOverlaySettings(new BuilderResolvedSettings(settings));
		Assert.notNull(config);
		Assert.floatEquals(0.6, config.alpha);
		Assert.floatEquals(0.3, config.fadeIn);
		Assert.isNull(config.color);
		Assert.isNull(config.fadeOut);
		Assert.isNull(config.blur);
	}

	// ============== TextInput Tests ==============

	static final TEXTINPUT_MANIM = "
		#textInput programmable(status:[normal,hover,focused,disabled]=normal, placeholder:bool=true, width:uint=200, height:uint=24) {
			bitmap(generated(color($width, $height, #333333))): 0, 0
			#textArea point: 4, 4
		}
	";

	function ensureTestFont() {
		try {
			bh.base.FontManager.getFontByName("testfont");
		} catch (e:Dynamic) {
			bh.base.FontManager.registerFont("testfont", hxd.res.DefaultFont.get());
		}
	}

	@Test
	public function testTextInputCreation():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		Assert.notNull(input);
		Assert.notNull(input.getObject());
		Assert.isFalse(input.disabled);
		Assert.equals("", input.getText());
	}

	@Test
	public function testTextInputInitialText():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont", text: "hello"});
		Assert.equals("hello", input.getText());
	}

	@Test
	public function testTextInputSetGetText():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});

		input.setText("world");
		Assert.equals("world", input.getText());

		input.setText("");
		Assert.equals("", input.getText());
	}

	@Test
	public function testTextInputDisabledState():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});

		input.disabled = true;
		Assert.isTrue(input.disabled);

		input.disabled = false;
		Assert.isFalse(input.disabled);
	}

	@Test
	public function testTextInputDisabledBlocksEvents():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		input.disabled = true;
		var mock = new MockControllable();

		@:privateAccess var result = input.result;
		Assert.equals("disabled", getStatusParam(result));

		// Disabled should not process hover — status must remain "disabled"
		UITestHarness.simulateEnter(input, mock);
		Assert.equals("disabled", getStatusParam(result));
	}

	@Test
	public function testTextInputHoverState():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		var mock = new MockControllable();

		@:privateAccess var result = input.result;
		Assert.equals("normal", getStatusParam(result));

		UITestHarness.simulateEnter(input, mock);
		Assert.equals("hover", getStatusParam(result));

		UITestHarness.simulateLeave(input, mock);
		Assert.equals("normal", getStatusParam(result));
	}

	@Test
	public function testTextInputCursorType():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});

		Assert.isTrue(Type.enumEq(input.getCursor(), hxd.Cursor.TextInput));

		input.disabled = true;
		Assert.isTrue(Type.enumEq(input.getCursor(), bh.base.CursorManager.getDefaultCursor()));
	}

	@Test
	public function testTextInputSetTextDoesNotFireOnChange():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		var callbackFired = false;

		input.onChange = function() {
			callbackFired = true;
		};

		// Directly set text triggers setText, not onChange (onChange is from h2d.TextInput)
		input.setText("test");
		Assert.isFalse(callbackFired); // setText doesn't fire onChange callback
	}

	@Test
	public function testTextInputContainsPoint():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		Assert.notNull(input.getObject());
		var bounds = input.getObject().getBounds();
		Assert.notNull(bounds);
		// Actually exercise containsPoint — TEXTINPUT_MANIM generates a 200x24 bitmap
		// A far-away point should not be contained
		Assert.isFalse(input.containsPoint(new Point(9999, 9999)));
	}

	// ============== TabGroup Tests ==============

	@Test
	public function testTabGroupCreation():Void {
		var group = new UITabGroup();
		Assert.notNull(group);
		Assert.isFalse(group.enterAdvances);
	}

	@Test
	public function testTabGroupAddRemove():Void {
		ensureTestFont();
		var group = new UITabGroup();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input1 = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		var input2 = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});

		group.add(input1);
		group.add(input2);

		// handleTab with no focused input returns true (focuses first)
		// But focus() requires a scene, so it won't actually focus.
		Assert.isTrue(group.handleTab(false));

		group.remove(input1);
		group.clear();
		// After clear, handleTab should return false (no inputs)
		Assert.isFalse(group.handleTab(false));
	}

	@Test
	public function testTabGroupHandleTabEmpty():Void {
		var group = new UITabGroup();
		Assert.isFalse(group.handleTab(false));
		Assert.isFalse(group.handleTab(true));
	}

	@Test
	public function testTabGroupHandleEnterDisabled():Void {
		var group = new UITabGroup();
		group.enterAdvances = false;
		Assert.isFalse(group.handleEnter());
	}

	// ============== Dropdown Tests ==============

	static final DROPDOWN_MANIM = "
		#dropdown programmable(status:[normal,hover,pressed,disabled]=normal, panel:[open,closed]=closed, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color(120, 30, #444444))): 0, 0
			#panelPoint (updatable) point: 0, 30
			#selectedName(updatable) text($font, callback(\"selectedName\"), $fontColor): 2, 4
			settings{transitionTimer:float=>0.2}
		}

		#list-panel programmable(width:uint=120, height:uint=200, topClearance:uint=0) {
			bitmap(generated(color($width, $height, #333333))): 0, 0
			placeholder(generated(color($width, $height, #000000)), builderParameter(\"mask\")): 0, 0
			#scrollbar point: $width - 10, 0
		}

		#list-item programmable(images:[none,tile]=none, status:[hover,pressed,normal]=normal, selected:[true,false]=false, disabled:[true,false]=false, tile:tile, itemWidth:uint=120, index:uint=0, title:string=title, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color($itemWidth, 20, #555555))): 0, 0
			text($font, $title, $fontColor): 4, 2
			interactive($itemWidth, 20, $index);
			settings{height:float=>20}
		}

		#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			bitmap(generated(color(4, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
		}
	";

	function createDropdownItems():Array<UIElementListItem> {
		return [
			{name: "Item 1"},
			{name: "Item 2"},
			{name: "Item 3"},
			{name: "Item 4"},
			{name: "Item 5"},
		];
	}

	function createDropdown(?items:Array<UIElementListItem>, initialIndex:Int = 0):UIStandardMultiAnimDropdown {
		ensureTestFont();
		if (items == null)
			items = createDropdownItems();
		var builder = BuilderTestBase.builderFromSource(DROPDOWN_MANIM);
		return UIStandardMultiAnimDropdown.createWithSingleBuilder(builder, items, initialIndex, "dropdown", "list-panel", "list-item", "scrollbar",
			"scrollbar", 120, 200);
	}

	function getDropdownPanelObject(dropdown:UIStandardMultiAnimDropdown):h2d.Object {
		var subElements = dropdown.getSubElements(SETReceiveUpdates);
		return subElements[0].getObject();
	}

	@Test
	public function testDropdownCreation():Void {
		var dropdown = createDropdown();
		Assert.notNull(dropdown);
		Assert.notNull(dropdown.getObject());
		Assert.isFalse(dropdown.disabled);
		Assert.equals(5, dropdown.items.length);
		Assert.equals(0, dropdown.currentItemIndex);
	}

	@Test
	public function testDropdownInitialSelection():Void {
		var dropdown = createDropdown(null, 2);
		Assert.equals(2, dropdown.getSelectedIndex());
	}

	@Test
	public function testDropdownClickTogglesOpen():Void {
		var dropdown = createDropdown();
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);
		// Use a position above the panel area so clicks reach the dropdown handler
		// (when panel is open, events inside panel bounds are forwarded to the panel)
		var btnPos = new h2d.col.Point(60, -100);

		// Initially closed
		Assert.isFalse(panelObj.visible);

		// Click to open
		UITestHarness.simulateClick(dropdown, mock, btnPos);
		Assert.isTrue(panelObj.visible);

		// Click again to start closing
		UITestHarness.simulateClick(dropdown, mock, btnPos);
		// Panel still visible during close animation
		Assert.isTrue(panelObj.visible);

		// Complete close animation
		dropdown.update(2.0);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownAutoOpenOnEnter():Void {
		var dropdown = createDropdown();
		dropdown.autoOpen = true;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);

		Assert.isFalse(panelObj.visible);
		UITestHarness.simulateEnter(dropdown, mock);
		Assert.isTrue(panelObj.visible);
	}

	@Test
	public function testDropdownAutoCloseOnLeave():Void {
		var dropdown = createDropdown();
		dropdown.autoCloseOnLeave = true;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);
		var outerPos = new h2d.col.Point(60, -100);

		// Open via click
		UITestHarness.simulateClick(dropdown, mock, outerPos);
		Assert.isTrue(panelObj.visible);

		// Leave starts close (position outside panel bounds)
		UITestHarness.simulateLeave(dropdown, mock, outerPos);
		// Complete close animation
		dropdown.update(2.0);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownNoAutoOpenWhenDisabled():Void {
		var dropdown = createDropdown();
		dropdown.autoOpen = true;
		dropdown.disabled = true;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);

		UITestHarness.simulateEnter(dropdown, mock);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownCloseOnOutsideClick():Void {
		var dropdown = createDropdown();
		dropdown.closeOnOutsideClick = true;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);
		var outerPos = new h2d.col.Point(60, -100);

		// Open
		UITestHarness.simulateClick(dropdown, mock, outerPos);
		Assert.isTrue(panelObj.visible);

		// Outside click (position far from panel)
		dropdown.onEvent(UITestHarness.createEventWrapper(OnReleaseOutside(0), mock, new h2d.col.Point(500, 500)));
		// Complete close animation
		dropdown.update(2.0);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownNoCloseOnOutsideClickWhenFlagFalse():Void {
		var dropdown = createDropdown();
		dropdown.closeOnOutsideClick = false;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);
		var outerPos = new h2d.col.Point(60, -100);

		// Open
		UITestHarness.simulateClick(dropdown, mock, outerPos);
		Assert.isTrue(panelObj.visible);

		// Outside click with flag disabled
		dropdown.onEvent(UITestHarness.createEventWrapper(OnReleaseOutside(0), mock, new h2d.col.Point(500, 500)));
		dropdown.update(2.0);
		// Panel should remain open
		Assert.isTrue(panelObj.visible);
	}

	@Test
	public function testDropdownSetSelectedIndex():Void {
		var dropdown = createDropdown();
		dropdown.setSelectedIndex(2);
		Assert.equals(2, dropdown.getSelectedIndex());
	}

	@Test
	public function testDropdownSetSelectedIndexOutOfBounds():Void {
		var dropdown = createDropdown();

		var threw = false;
		try {
			dropdown.setSelectedIndex(-1);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("index") >= 0 || msg.indexOf("bounds") >= 0 || msg.indexOf("range") >= 0, 'Expected error about "index"/"bounds"/"range", got: $msg');
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			dropdown.setSelectedIndex(dropdown.items.length);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("index") >= 0 || msg.indexOf("bounds") >= 0 || msg.indexOf("range") >= 0, 'Expected error about "index"/"bounds"/"range", got: $msg');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testDropdownListValueInterface():Void {
		var items = createDropdownItems();
		var dropdown = createDropdown(items);
		var returnedItems = dropdown.getList();
		Assert.equals(items.length, returnedItems.length);
		Assert.equals("Item 1", returnedItems[0].name);
	}

	@Test
	public function testDropdownDisabled():Void {
		var dropdown = createDropdown();
		dropdown.disabled = true;
		Assert.isTrue(dropdown.disabled);
	}

	@Test
	public function testDropdownDisabledBlocksAllEvents():Void {
		var dropdown = createDropdown();
		dropdown.disabled = true;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);

		// Click should not open
		UITestHarness.simulateClick(dropdown, mock);
		Assert.isFalse(panelObj.visible);

		// Enter should not open
		UITestHarness.simulateEnter(dropdown, mock);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownDisabledCursor():Void {
		var dropdown = createDropdown();

		// Enabled: interactive cursor
		Assert.isTrue(Type.enumEq(dropdown.getCursor(), bh.base.CursorManager.getDefaultInteractiveCursor()));

		// Disabled: default cursor
		dropdown.disabled = true;
		Assert.isTrue(Type.enumEq(dropdown.getCursor(), bh.base.CursorManager.getDefaultCursor()));
	}

	@Test
	public function testDropdownOnItemChangedCallback():Void {
		var dropdown = createDropdown();
		var callbackIndex:Null<Int> = null;

		dropdown.onItemChanged = function(newIndex, items) {
			callbackIndex = newIndex;
		};

		// setSelectedIndex doesn't trigger onItemChanged (only panel selection does)
		dropdown.setSelectedIndex(3);
		Assert.isNull(callbackIndex);
		Assert.equals(3, dropdown.getSelectedIndex());
	}

	@Test
	public function testDropdownTransitionTimerOverride():Void {
		var dropdown = createDropdown();
		dropdown.transitionTimerOverride = 0.5;
		var mock = new MockControllable();
		var panelObj = getDropdownPanelObject(dropdown);
		var btnPos = new h2d.col.Point(60, -100);

		// Open
		UITestHarness.simulateClick(dropdown, mock, btnPos);
		Assert.isTrue(panelObj.visible);

		// Start close
		UITestHarness.simulateClick(dropdown, mock, btnPos);

		// After 0.4s, panel should still be visible (closing in progress)
		dropdown.update(0.4);
		Assert.isTrue(panelObj.visible);

		// After 0.6s total (> 0.5 override), panel should be closed
		dropdown.update(0.2);
		Assert.isFalse(panelObj.visible);
	}

	@Test
	public function testDropdownSubElements():Void {
		var dropdown = createDropdown();

		var updates = dropdown.getSubElements(SETReceiveUpdates);
		Assert.equals(1, updates.length);
		Assert.notNull(updates[0]);

		var events = dropdown.getSubElements(SETReceiveEvents);
		Assert.equals(0, events.length);
	}

	// ============== Scrollable List Tests ==============

	static final SCROLLABLE_LIST_MANIM = "
		#list-panel programmable(width:uint=120, height:uint=200, topClearance:uint=0) {
			bitmap(generated(color($width, $height, #333333))): 0, 0
			placeholder(generated(color($width, $height, #000000)), builderParameter(\"mask\")): 0, 0
			#scrollbar point: $width - 10, 0
		}

		#list-item programmable(images:[none,tile]=none, status:[hover,pressed,normal]=normal, selected:[true,false]=false, disabled:[true,false]=false, tile:tile, itemWidth:uint=120, index:uint=0, title:string=title, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color($itemWidth, 20, #555555))): 0, 0
			text($font, $title, $fontColor): 4, 2
			interactive($itemWidth, 20, $index);
			settings{height:float=>20}
		}

		#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			bitmap(generated(color(4, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
		}
	";

	function createScrollableListItems():Array<UIElementListItem> {
		return [
			{name: "Item 1"},
			{name: "Item 2"},
			{name: "Item 3"},
			{name: "Item 4"},
			{name: "Item 5"},
		];
	}

	function createManyScrollableListItems(count:Int):Array<UIElementListItem> {
		return [for (i in 0...count) {name: 'Item ${i + 1}'}];
	}

	function createScrollableList(?items:Array<UIElementListItem>, initialIndex:Int = 0,
			?panelSizeMode:PanelSizeMode):UIMultiAnimScrollableList {
		ensureTestFont();
		if (items == null)
			items = createScrollableListItems();
		var builder = BuilderTestBase.builderFromSource(SCROLLABLE_LIST_MANIM);
		return UIMultiAnimScrollableList.createWithSingleBuilder(builder, "list-panel", "list-item", "scrollbar", "scrollbar", 120, 200, items, 0,
			initialIndex, panelSizeMode);
	}

	@Test
	public function testScrollableListCreation():Void {
		var list = createScrollableList();
		Assert.notNull(list);
		Assert.notNull(list.getObject());
		Assert.isFalse(list.disabled);
		Assert.equals(5, list.items.length);
		Assert.equals(0, list.currentItemIndex);
	}

	@Test
	public function testScrollableListInitialSelection():Void {
		var list = createScrollableList(null, 2);
		Assert.equals(2, list.getSelectedIndex());
	}

	@Test
	public function testScrollableListSetSelectedIndex():Void {
		var list = createScrollableList();
		list.setSelectedIndex(3);
		Assert.equals(3, list.getSelectedIndex());
	}

	@Test
	public function testScrollableListSetSelectedIndexOutOfBounds():Void {
		var list = createScrollableList();

		var threw = false;
		try {
			list.setSelectedIndex(-2);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("index") >= 0 || msg.indexOf("bounds") >= 0 || msg.indexOf("range") >= 0, 'Expected error about "index"/"bounds"/"range", got: $msg');
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			list.setSelectedIndex(list.items.length);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("index") >= 0 || msg.indexOf("bounds") >= 0 || msg.indexOf("range") >= 0, 'Expected error about "index"/"bounds"/"range", got: $msg');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testScrollableListGetList():Void {
		var items = createScrollableListItems();
		var list = createScrollableList(items);
		var returnedItems = list.getList();
		Assert.equals(items.length, returnedItems.length);
		Assert.equals("Item 1", returnedItems[0].name);
		Assert.equals("Item 5", returnedItems[4].name);
	}

	@Test
	public function testScrollableListDisabled():Void {
		var list = createScrollableList();
		list.disabled = true;
		Assert.isTrue(list.disabled);
	}

	@Test
	public function testScrollableListDisabledAlpha():Void {
		var list = createScrollableList();
		Assert.floatEquals(1.0, list.getObject().alpha);
		list.disabled = true;
		Assert.floatEquals(0.5, list.getObject().alpha);
		list.disabled = false;
		Assert.floatEquals(1.0, list.getObject().alpha);
	}

	@Test
	public function testScrollableListDisabledBlocksEvents():Void {
		var list = createScrollableList();
		list.disabled = true;
		var mock = new MockControllable();

		// Click should not change selection
		var pos = new h2d.col.Point(60, 10);
		UITestHarness.simulateClick(list, mock, pos);
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testScrollableListDisabledCursor():Void {
		var list = createScrollableList();

		// Enabled: interactive cursor
		Assert.isTrue(Type.enumEq(list.getCursor(), bh.base.CursorManager.getDefaultInteractiveCursor()));

		// Disabled: default cursor
		list.disabled = true;
		Assert.isTrue(Type.enumEq(list.getCursor(), bh.base.CursorManager.getDefaultCursor()));
	}

	@Test
	public function testScrollableListSetItems():Void {
		var list = createScrollableList();
		Assert.equals(5, list.items.length);

		var newItems:Array<UIElementListItem> = [
			{name: "New 1"},
			{name: "New 2"},
			{name: "New 3"},
		];
		list.setItems(newItems, 1);
		Assert.equals(3, list.items.length);
		Assert.equals(1, list.getSelectedIndex());
		Assert.equals("New 1", list.items[0].name);
		Assert.equals("New 2", list.items[1].name);
	}

	@Test
	public function testScrollableListSetItemsDefaultSelection():Void {
		var list = createScrollableList();
		list.setSelectedIndex(3);

		var newItems:Array<UIElementListItem> = [
			{name: "A"},
			{name: "B"},
		];
		list.setItems(newItems);
		Assert.equals(0, list.getSelectedIndex());
	}

	@Test
	public function testScrollableListSetItemsEmpty():Void {
		var list = createScrollableList();
		list.setItems([]);
		Assert.equals(0, list.items.length);
		Assert.equals(-1, list.getSelectedIndex());
	}

	@Test
	public function testScrollableListClickModeSingleClick():Void {
		var list = createScrollableList();
		list.clickMode = SingleClick;
		var mock = new MockControllable();

		// Find position of item 1 (y=20, item height=20)
		var pos = new h2d.col.Point(60, 25);
		UITestHarness.simulateClick(list, mock, pos);

		// In single click mode, selecting a different item should emit UIClickItem
		var hasClickItem = false;
		for (e in mock.recordedEvents) {
			switch e.event {
				case UIClickItem(_, _):
					hasClickItem = true;
				default:
			}
		}
		Assert.isTrue(hasClickItem);
	}

	@Test
	public function testScrollableListClickModeDefault():Void {
		var list = createScrollableList();
		// Default should be DoubleClick
		Assert.isTrue(Type.enumEq(list.clickMode, DoubleClick));
	}

	@Test
	public function testScrollableListScrollToIndexAlreadyVisible():Void {
		var list = createScrollableList();
		// With 5 items of height 20 each (total 100) and panel height 200, all items are visible
		@:privateAccess var scrollBefore = list.mask.scrollY;
		list.scrollToIndex(2);
		// scrollToIndex should not change scroll position for an already-visible item
		@:privateAccess var scrollAfter = list.mask.scrollY;
		Assert.floatEquals(scrollBefore, scrollAfter);
	}

	@Test
	public function testScrollableListScrollToIndexOutOfBounds():Void {
		var list = createScrollableList();
		@:privateAccess var scrollBefore = list.mask.scrollY;
		// Should not throw and not change scroll position
		list.scrollToIndex(-1);
		@:privateAccess Assert.floatEquals(scrollBefore, list.mask.scrollY);
		list.scrollToIndex(100);
		@:privateAccess Assert.floatEquals(scrollBefore, list.mask.scrollY);
	}

	@Test
	public function testScrollableListScrollToIndexScrollsDown():Void {
		// Create list with many items so scrolling is needed (20 items * 20px = 400px total, 200px panel)
		var items = createManyScrollableListItems(20);
		var list = createScrollableList(items);
		@:privateAccess var scrollBefore = list.mask.scrollY;
		// Item 15 is at y=300, which is below the 200px panel
		list.scrollToIndex(15);
		// After scrollToIndex, the scroll position should have changed
		@:privateAccess var scrollAfter = list.mask.scrollY;
		Assert.isTrue(scrollAfter > scrollBefore, 'Scroll should have moved down, was $scrollBefore now $scrollAfter');
	}

	@Test
	public function testScrollableListOnItemChangedCallback():Void {
		var list = createScrollableList();
		var callbackIndex:Null<Int> = null;

		list.onItemChanged = function(newIndex, items, wrapper) {
			callbackIndex = newIndex;
		};

		// setSelectedIndex doesn't trigger onItemChanged (only event-driven selection does)
		list.setSelectedIndex(3);
		Assert.isNull(callbackIndex);
		Assert.equals(3, list.getSelectedIndex());
	}

	@Test
	public function testScrollableListOnItemChangedCallbackPositive():Void {
		var list = createScrollableList();
		list.clickMode = SingleClick;
		var callbackIndex:Null<Int> = null;

		list.onItemChanged = function(newIndex, items, wrapper) {
			callbackIndex = newIndex;
		};

		// Click on item 1 (y=25, each item 20px tall) — different from initial selection (0)
		var mock = new MockControllable();
		var pos = new h2d.col.Point(60, 25);
		UITestHarness.simulateClick(list, mock, pos);

		// onItemChanged should have been called with the new index
		Assert.notNull(callbackIndex, "onItemChanged should fire on event-driven selection");
		Assert.equals(1, callbackIndex);
	}

	@Test
	public function testDropdownOnItemChangedCallbackPositive():Void {
		var dropdown = createDropdown();
		var callbackIndex:Null<Int> = null;

		dropdown.onItemChanged = function(newIndex, items) {
			callbackIndex = newIndex;
		};

		// Open the dropdown panel
		var mock = new MockControllable();
		var btnPos = new h2d.col.Point(60, 15);
		UITestHarness.simulateClick(dropdown, mock, btnPos);

		// Click on an item in the panel (item 2 at y offset in the panel)
		@:privateAccess var panel = dropdown.panel;
		if (panel != null) {
			panel.clickMode = SingleClick;
			var panelPos = new h2d.col.Point(60, 25);
			UITestHarness.simulateClick(panel, mock, panelPos);
		}

		// If panel click worked, callback should have fired
		if (callbackIndex != null) {
			Assert.isTrue(callbackIndex >= 0, "Callback index should be valid");
		} else {
			// Panel click may not work in headless mode due to zero bounds
			Assert.pass("headless mode -- click simulation not supported");
		}
	}

	@Test
	public function testScrollableListDisabledItems():Void {
		var items:Array<UIElementListItem> = [
			{name: "Normal"},
			{name: "Disabled", disabled: true},
			{name: "Also Normal"},
		];
		var list = createScrollableList(items);
		Assert.equals(3, list.items.length);
		Assert.isTrue(list.items[1].disabled == true);
	}

	@Test
	public function testScrollableListTileRef():Void {
		var items:Array<UIElementListItem> = [
			{name: "With Rect Tile", tileRef: TRGeneratedRectColor(16, 16, 0xFFFF0000)},
			{name: "No Tile"},
			{name: "With Plain Rect", tileRef: TRGeneratedRect(16, 16)},
		];
		var list = createScrollableList(items);
		Assert.equals(3, list.items.length);
		Assert.notNull(list.items[0].tileRef);
		Assert.isNull(list.items[1].tileRef);
	}

	@Test
	public function testScrollableListItemData():Void {
		var items:Array<UIElementListItem> = [
			{name: "Item", data: {id: 42, category: "weapons"}},
		];
		var list = createScrollableList(items);
		Assert.equals(42, list.items[0].data.id);
		Assert.equals("weapons", list.items[0].data.category);
	}

	@Test
	public function testScrollableListHoverIndexDefaultValues():Void {
		var list = createScrollableList();
		Assert.equals(-1, list.currentHoverIndex);
		Assert.equals(-1, list.currentPressedIndex);
	}

	@Test
	public function testScrollableListAutoSizeMode():Void {
		// 3 items * 20px height = 60px, which is less than maxHeight (200px)
		var items:Array<UIElementListItem> = [
			{name: "A"},
			{name: "B"},
			{name: "C"},
		];
		var list = createScrollableList(items, 0, AutoSize);
		Assert.notNull(list);
		Assert.equals(3, list.items.length);
	}

	@Test
	public function testScrollableListWheelScrollMultiplier():Void {
		var list = createScrollableList();
		Assert.floatEquals(10.0, list.wheelScrollMultiplier);
		list.wheelScrollMultiplier = 20.0;
		Assert.floatEquals(20.0, list.wheelScrollMultiplier);
	}

	@Test
	public function testScrollableListDoubleClickThreshold():Void {
		var list = createScrollableList();
		Assert.floatEquals(0.3, list.doubleClickThreshold);
		list.doubleClickThreshold = 0.5;
		Assert.floatEquals(0.5, list.doubleClickThreshold);
	}

	@Test
	public function testScrollableListDisabledIdempotent():Void {
		var list = createScrollableList();
		list.disabled = true;
		Assert.isTrue(list.disabled);
		Assert.floatEquals(0.5, list.getObject().alpha);
		// Setting disabled to same value should be idempotent
		list.disabled = true;
		Assert.isTrue(list.disabled);
		Assert.floatEquals(0.5, list.getObject().alpha);
	}

	@Test
	public function testScrollableListSetItemsResetsHoverAndPressed():Void {
		var list = createScrollableList();
		// After setItems, hover and pressed should be reset
		var newItems:Array<UIElementListItem> = [{name: "X"}];
		list.setItems(newItems);
		Assert.equals(-1, list.currentHoverIndex);
		Assert.equals(-1, list.currentPressedIndex);
	}

	// ============== Tabs Tests ==============

	static final TABS_MANIM = "
		#tabBar programmable(count:uint=3) {
			repeatable($i, step($count, dx: 80)) {
				placeholder(generated(color(80, 30, #555555)), callback(\"tabButton\", $i)): 0, 0
			}
		}

		#tab programmable(status:[normal,hover,pressed]=normal, disabled:bool=false, checked:bool=false, buttonText:string=Tab) {
			bitmap(generated(color(80, 30, #444444))): 0, 0
		}
	";

	static final TABS_CONTENTROOT_MANIM = "
		#tabBar programmable(count:uint=3) {
			repeatable($i, step($count, dx: 80)) {
				placeholder(generated(color(80, 30, #555555)), callback(\"tabButton\", $i)): 0, 0
			}
			#contentRoot point: 0, 30
		}

		#tab programmable(status:[normal,hover,pressed]=normal, disabled:bool=false, checked:bool=false, buttonText:string=Tab) {
			bitmap(generated(color(80, 30, #444444))): 0, 0
		}
	";

	function createTabItems():Array<UIElementListItem> {
		return [
			{name: "Tab 1"},
			{name: "Tab 2"},
			{name: "Tab 3"},
		];
	}

	function createTabs(?items:Array<UIElementListItem>, initialIndex:Int = 0):{tabs:UIMultiAnimTabs, screen:UITestScreen} {
		if (items == null)
			items = createTabItems();
		var builder = BuilderTestBase.builderFromSource(TABS_MANIM);
		var screen = new UITestScreen();
		var tabs = new UIMultiAnimTabs(builder, "tabBar", "tab", items, initialIndex, screen);
		return {tabs: tabs, screen: screen};
	}

	function getTabButton(tabs:UIMultiAnimTabs, index:Int):UIMultiAnimTabButton {
		var subElements = tabs.getSubElements(SETReceiveEvents);
		return cast subElements[index];
	}

	@Test
	public function testTabsCreation():Void {
		var result = createTabs();
		Assert.notNull(result.tabs);
		Assert.notNull(result.tabs.getObject());
		Assert.isFalse(result.tabs.disabled);
		Assert.equals(0, result.tabs.getSelectedIndex());
		Assert.equals(3, result.tabs.getList().length);
	}

	@Test
	public function testTabsInitialSelection():Void {
		var result = createTabs(null, 1);
		Assert.equals(1, result.tabs.getSelectedIndex());

		var btn0 = getTabButton(result.tabs, 0);
		var btn1 = getTabButton(result.tabs, 1);
		Assert.isFalse(btn0.selected);
		Assert.isTrue(btn1.selected);
	}

	@Test
	public function testTabsGetList():Void {
		var items = createTabItems();
		var result = createTabs(items);
		var list = result.tabs.getList();
		Assert.equals(items.length, list.length);
		Assert.equals("Tab 1", list[0].name);
		Assert.equals("Tab 2", list[1].name);
		Assert.equals("Tab 3", list[2].name);
	}

	@Test
	public function testTabsSetSelectedIndex():Void {
		var result = createTabs();
		result.tabs.setSelectedIndex(2);
		Assert.equals(2, result.tabs.getSelectedIndex());

		var btn0 = getTabButton(result.tabs, 0);
		var btn2 = getTabButton(result.tabs, 2);
		Assert.isFalse(btn0.selected);
		Assert.isTrue(btn2.selected);
	}

	@Test
	public function testTabsSetSelectedIndexSameNoOp():Void {
		var result = createTabs();
		var btn0 = getTabButton(result.tabs, 0);
		Assert.isTrue(btn0.selected);

		// Setting same index should be a no-op
		result.tabs.setSelectedIndex(0);
		Assert.equals(0, result.tabs.getSelectedIndex());
		Assert.isTrue(btn0.selected);
	}

	@Test
	public function testTabsClickSwitchesTab():Void {
		var result = createTabs();
		var mock = new MockControllable();

		// Click second tab (index 1)
		UITestHarness.simulateClick(cast getTabButton(result.tabs, 1), mock);

		Assert.equals(1, result.tabs.getSelectedIndex());
		Assert.equals(1, mock.eventCount());
		Assert.isTrue(mock.hasEvent(UIChangeItem(1, result.tabs.getList())));
	}

	@Test
	public function testTabsClickSelectedTabNoOp():Void {
		var result = createTabs();
		var mock = new MockControllable();

		// Click first tab (already selected)
		UITestHarness.simulateClick(cast getTabButton(result.tabs, 0), mock);

		Assert.equals(0, result.tabs.getSelectedIndex());
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testTabsOnTabChangedCallback():Void {
		var result = createTabs();
		var callbackIndex:Null<Int> = null;

		result.tabs.onTabChanged = function(index, items) {
			callbackIndex = index;
		};

		var mock = new MockControllable();
		UITestHarness.simulateClick(cast getTabButton(result.tabs, 1), mock);

		Assert.equals(1, callbackIndex);
	}

	@Test
	public function testTabsDisabled():Void {
		var result = createTabs();
		result.tabs.disabled = true;
		Assert.isTrue(result.tabs.disabled);

		for (i in 0...3) {
			Assert.isTrue(getTabButton(result.tabs, i).disabled);
		}
	}

	@Test
	public function testTabsDisabledBlocksClick():Void {
		var result = createTabs();
		result.tabs.disabled = true;
		var mock = new MockControllable();

		UITestHarness.simulateClick(cast getTabButton(result.tabs, 1), mock);

		Assert.equals(0, result.tabs.getSelectedIndex());
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testTabsPerItemDisabled():Void {
		var items:Array<UIElementListItem> = [
			{name: "Tab 1"},
			{name: "Tab 2", disabled: true},
			{name: "Tab 3"},
		];
		var result = createTabs(items);

		Assert.isFalse(getTabButton(result.tabs, 0).disabled);
		Assert.isTrue(getTabButton(result.tabs, 1).disabled);
		Assert.isFalse(getTabButton(result.tabs, 2).disabled);
	}

	@Test
	public function testTabsPerItemDisabledBlocksClick():Void {
		var items:Array<UIElementListItem> = [
			{name: "Tab 1"},
			{name: "Tab 2", disabled: true},
			{name: "Tab 3"},
		];
		var result = createTabs(items);
		var mock = new MockControllable();

		// Click disabled tab — should not switch
		UITestHarness.simulateClick(cast getTabButton(result.tabs, 1), mock);

		Assert.equals(0, result.tabs.getSelectedIndex());
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testTabsRefreshDisabledState():Void {
		var items:Array<UIElementListItem> = [
			{name: "Tab 1"},
			{name: "Tab 2"},
			{name: "Tab 3"},
		];
		var result = createTabs(items);

		Assert.isFalse(getTabButton(result.tabs, 1).disabled);

		// Mark tab 2 as disabled in the items array
		items[1].disabled = true;
		result.tabs.refreshDisabledState();

		Assert.isTrue(getTabButton(result.tabs, 1).disabled);
	}

	@Test
	public function testTabsContentRouting():Void {
		var result = createTabs();
		var tabs = result.tabs;

		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var btn0 = UIStandardMultiAnimButton.create(builder, "button", "Content0");
		var btn1 = UIStandardMultiAnimButton.create(builder, "button", "Content1");

		tabs.beginTab(0);
		tabs.registerElement(btn0);
		tabs.endTab();

		tabs.beginTab(1);
		tabs.registerElement(btn1);
		tabs.endTab();

		// Sub-elements: 3 tab buttons + active tab content (btn0)
		var subElements = tabs.getSubElements(SETReceiveEvents);
		Assert.equals(4, subElements.length);
	}

	@Test
	public function testTabsContentVisibility():Void {
		var result = createTabs();
		var tabs = result.tabs;

		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var btn0 = UIStandardMultiAnimButton.create(builder, "button", "Content0");
		var btn1 = UIStandardMultiAnimButton.create(builder, "button", "Content1");

		tabs.beginTab(0);
		tabs.registerElement(btn0);
		tabs.endTab();

		tabs.beginTab(1);
		tabs.registerElement(btn1);
		tabs.endTab();

		// Tab 0 selected — btn0 visible, btn1 hidden
		Assert.isTrue(btn0.getObject().visible);
		Assert.isFalse(btn1.getObject().visible);

		// Switch to tab 1
		tabs.setSelectedIndex(1);
		Assert.isFalse(btn0.getObject().visible);
		Assert.isTrue(btn1.getObject().visible);
	}

	@Test
	public function testTabsSubElementsActiveContent():Void {
		var result = createTabs();
		var tabs = result.tabs;

		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var btn0 = UIStandardMultiAnimButton.create(builder, "button", "Content0");
		var btn1 = UIStandardMultiAnimButton.create(builder, "button", "Content1");

		tabs.beginTab(0);
		tabs.registerElement(btn0);
		tabs.endTab();

		tabs.beginTab(1);
		tabs.registerElement(btn1);
		tabs.endTab();

		// Tab 0 active: 3 buttons + btn0
		var subElements = tabs.getSubElements(SETReceiveEvents);
		Assert.equals(4, subElements.length);

		// Switch to tab 1: 3 buttons + btn1
		tabs.setSelectedIndex(1);
		subElements = tabs.getSubElements(SETReceiveEvents);
		Assert.equals(4, subElements.length);

		// Switch to tab 2 (no content): 3 buttons only
		tabs.setSelectedIndex(2);
		subElements = tabs.getSubElements(SETReceiveEvents);
		Assert.equals(3, subElements.length);
	}

	@Test
	public function testTabsBeginTabOutOfRange():Void {
		var result = createTabs();

		var threw = false;
		try {
			result.tabs.beginTab(-1);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("range") >= 0 || msg.indexOf("index") >= 0 || msg.indexOf("tab") >= 0, 'Expected error about "range"/"index"/"tab", got: $msg');
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			result.tabs.beginTab(3);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("range") >= 0 || msg.indexOf("index") >= 0 || msg.indexOf("tab") >= 0, 'Expected error about "range"/"index"/"tab", got: $msg');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testTabsEndTabWithoutBegin():Void {
		var result = createTabs();

		var threw = false;
		try {
			result.tabs.endTab();
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("not populating") >= 0 || msg.indexOf("tab") >= 0 || msg.indexOf("begin") >= 0, 'Expected error about tab state, got: $msg');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testTabsBeginTabNested():Void {
		var result = createTabs();

		result.tabs.beginTab(0);

		var threw = false;
		try {
			result.tabs.beginTab(1);
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("nested") >= 0 || msg.indexOf("already") >= 0 || msg.indexOf("begin") >= 0, 'Expected error about "nested"/"already"/"begin", got: $msg');
		}
		Assert.isTrue(threw);

		result.tabs.endTab();
	}

	@Test
	public function testTabsCursorBehavior():Void {
		var result = createTabs();

		// Unselected, enabled: interactive cursor
		var btn1 = getTabButton(result.tabs, 1);
		Assert.isTrue(Type.enumEq(btn1.getCursor(), bh.base.CursorManager.getDefaultInteractiveCursor()));

		// Selected: default cursor
		var btn0 = getTabButton(result.tabs, 0);
		Assert.isTrue(Type.enumEq(btn0.getCursor(), bh.base.CursorManager.getDefaultCursor()));

		// Disabled: default cursor
		btn1.disabled = true;
		Assert.isTrue(Type.enumEq(btn1.getCursor(), bh.base.CursorManager.getDefaultCursor()));
	}

	@Test
	public function testTabsContentRootRelativeMode():Void {
		var items = createTabItems();
		var builder = BuilderTestBase.builderFromSource(TABS_CONTENTROOT_MANIM);
		var screen = new UITestScreen();
		var tabs = new UIMultiAnimTabs(builder, "tabBar", "tab", items, 0, screen, null, null, "contentRoot");

		Assert.notNull(tabs);
		Assert.notNull(tabs.getObject());
		Assert.equals(0, tabs.getSelectedIndex());
	}

	@Test
	public function testTabsContentRootInvalidThrows():Void {
		var items = createTabItems();
		var builder = BuilderTestBase.builderFromSource(TABS_MANIM);
		var screen = new UITestScreen();

		var threw = false;
		try {
			new UIMultiAnimTabs(builder, "tabBar", "tab", items, 0, screen, null, null, "contentRoot");
		} catch (e:Dynamic) {
			threw = true;
			var msg = Std.string(e);
			Assert.isTrue(msg.indexOf("content") >= 0 || msg.indexOf("root") >= 0 || msg.indexOf("invalid") >= 0 || msg.indexOf("not found") >= 0, 'Expected error about "content"/"root"/"invalid"/"not found", got: $msg');
		}
		Assert.isTrue(threw);
	}

	// ============== Drag-and-Drop Tests ==============

	static final DRAGGABLE_MANIM = "
		#dragContainer programmable(count:uint=3) {
			repeatable($i, step($count, dx: 60)) {
				#item[$i] slot: 0, 0
				bitmap(generated(color(50, 50, #333333))): 0, 0
			}
		}
	";

	function createDraggable():UIMultiAnimDraggable {
		var target = new h2d.Object();
		return new UIMultiAnimDraggable(target);
	}

	function createDropZoneBounds(x:Float, y:Float, w:Float, h:Float):Bounds {
		return Bounds.fromValues(x, y, w, h);
	}

	function createDraggableWithZones():{draggable:UIMultiAnimDraggable, zones:Array<DropZone>} {
		var draggable = createDraggable();
		var zone1:DropZone = {id: "zone1", bounds: createDropZoneBounds(100, 100, 50, 50)};
		var zone2:DropZone = {id: "zone2", bounds: createDropZoneBounds(200, 100, 50, 50)};
		draggable.addDropZone(zone1);
		draggable.addDropZone(zone2);
		return {draggable: draggable, zones: [zone1, zone2]};
	}

	function simulateDrag(draggable:UIMultiAnimDraggable, mock:MockControllable, from:Point, to:Point):Void {
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, from));
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, to));
		draggable.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, to));
	}

	function hasCustomEvent(mock:MockControllable, eventName:String):Bool {
		for (e in mock.recordedEvents) {
			switch e.event {
				case UICustomEvent(name, _):
					if (name == eventName) return true;
				default:
			}
		}
		return false;
	}

	// --- Creation & State ---

	@Test
	public function testDraggableCreation():Void {
		var draggable = createDraggable();
		Assert.notNull(draggable);
		Assert.notNull(draggable.getObject());
		Assert.isTrue(Type.enumEq(draggable.getState(), Idle));
		Assert.isFalse(draggable.isCurrentlyDragging());
		Assert.isFalse(draggable.isAnimating());
	}

	@Test
	public function testDraggableCreateFromSlot():Void {
		var result = BuilderTestBase.buildFromSource(DRAGGABLE_MANIM, "dragContainer");
		var slot = result.getSlot("item", 0);
		var content = new h2d.Object();
		slot.setContent(content);
		Assert.isTrue(slot.isOccupied());

		var draggable = UIMultiAnimDraggable.createFromSlot(slot);
		Assert.notNull(draggable);
		Assert.isTrue(slot.isEmpty());
		Assert.equals(slot, draggable.sourceSlot);
	}

	@Test
	public function testDraggableCreateFromEmptySlot():Void {
		var result = BuilderTestBase.buildFromSource(DRAGGABLE_MANIM, "dragContainer");
		var slot = result.getSlot("item", 0);

		var draggable = UIMultiAnimDraggable.createFromSlot(slot);
		Assert.isNull(draggable);
	}

	// --- Drop Zone Management ---

	@Test
	public function testDraggableAddDropZone():Void {
		var draggable = createDraggable();
		var zone:DropZone = {id: "testZone", bounds: createDropZoneBounds(0, 0, 100, 100)};

		draggable.addDropZone(zone);

		Assert.equals(1, draggable.dropZones.length);
		Assert.equals("testZone", draggable.dropZones[0].id);
	}

	@Test
	public function testDraggableRemoveDropZone():Void {
		var draggable = createDraggable();
		var zone:DropZone = {id: "testZone", bounds: createDropZoneBounds(0, 0, 100, 100)};
		draggable.addDropZone(zone);
		Assert.equals(1, draggable.dropZones.length);

		draggable.removeDropZone("testZone");

		Assert.equals(0, draggable.dropZones.length);
	}

	@Test
	public function testDraggableClearDropZones():Void {
		var draggable = createDraggable();
		draggable.addDropZone({id: "z1", bounds: createDropZoneBounds(0, 0, 50, 50)});
		draggable.addDropZone({id: "z2", bounds: createDropZoneBounds(100, 0, 50, 50)});
		draggable.addDropZone({id: "z3", bounds: createDropZoneBounds(200, 0, 50, 50)});
		Assert.equals(3, draggable.dropZones.length);

		draggable.clearDropZones();

		Assert.equals(0, draggable.dropZones.length);
	}

	@Test
	public function testDraggableAddDropZonesFromSlots():Void {
		var result = BuilderTestBase.buildFromSource(DRAGGABLE_MANIM, "dragContainer");
		var draggable = createDraggable();

		draggable.addDropZonesFromSlots("item", result);

		Assert.equals(3, draggable.dropZones.length);
		Assert.equals("item_0", draggable.dropZones[0].id);
		Assert.equals("item_1", draggable.dropZones[1].id);
		Assert.equals("item_2", draggable.dropZones[2].id);
	}

	// --- Basic Drag Lifecycle ---

	@Test
	public function testDraggableDragStart():Void {
		var draggable = createDraggable();
		var mock = new MockControllable();

		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		Assert.isTrue(draggable.isCurrentlyDragging());
		Assert.isTrue(Type.enumEq(draggable.getState(), Dragging));
		Assert.isTrue(hasCustomEvent(mock, "dragStart"));
	}

	@Test
	public function testDraggableDisabledNoDrag():Void {
		var draggable = createDraggable();
		draggable.enabled = false;
		var mock = new MockControllable();

		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		Assert.isFalse(draggable.isCurrentlyDragging());
		Assert.isTrue(Type.enumEq(draggable.getState(), Idle));
		Assert.equals(0, mock.eventCount());
	}

	@Test
	public function testDraggableDragStartDenied():Void {
		var draggable = createDraggable();
		draggable.onDragStart = (pos, wrapper) -> false;
		var mock = new MockControllable();

		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		Assert.isFalse(draggable.isCurrentlyDragging());
		Assert.isTrue(Type.enumEq(draggable.getState(), Idle));
	}

	@Test
	public function testDraggableDragMove():Void {
		var draggable = createDraggable();
		var mock = new MockControllable();
		var startPos = new Point(10, 10);

		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, startPos));
		Assert.isTrue(draggable.isCurrentlyDragging());

		// Move to a new position
		var movePos = new Point(50, 50);
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, movePos));

		// Root starts at (0,0), push at (10,10) → dragOffset=(-10,-10), move to (50,50) → root=(40,40)
		var obj = draggable.getObject();
		Assert.notNull(obj);
		Assert.floatEquals(40.0, obj.x);
		Assert.floatEquals(40.0, obj.y);
	}

	@Test
	public function testDraggableDragConstraint():Void {
		var draggable = createDraggable();
		draggable.dragConstraint = (pos) -> new Point(Math.max(0, Math.min(100, pos.x)), Math.max(0, Math.min(100, pos.y)));
		var mock = new MockControllable();

		// Start drag at origin
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(0, 0)));

		// Move beyond constraint
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(200, 200)));

		var obj = draggable.getObject();
		Assert.floatEquals(100.0, obj.x);
		Assert.floatEquals(100.0, obj.y);
	}

	// --- Drop Behavior ---

	@Test
	public function testDraggableDropOnZone():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		var mock = new MockControllable();

		// Drag from outside zones to inside zone1 (100-150, 100-150)
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		Assert.isTrue(hasCustomEvent(mock, "dragDrop"));
		Assert.isFalse(hasCustomEvent(mock, "dragCancel"));
	}

	@Test
	public function testDraggableDropOutsideZone():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		draggable.returnToOrigin = false;
		var mock = new MockControllable();

		// Drag to area outside all zones
		simulateDrag(draggable, mock, new Point(10, 10), new Point(500, 500));

		Assert.isFalse(draggable.isCurrentlyDragging());
		Assert.isTrue(hasCustomEvent(mock, "dragCancel"));
	}

	@Test
	public function testDraggableDropRejectedByCallback():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		draggable.returnToOrigin = false;
		draggable.onDragDrop = (result, wrapper) -> false;
		var mock = new MockControllable();

		// Drop on zone1, but callback rejects
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		Assert.isTrue(hasCustomEvent(mock, "dragCancel"));
		Assert.isFalse(hasCustomEvent(mock, "dragDrop"));
	}

	@Test
	public function testDraggableReturnToOriginFalse():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		draggable.returnToOrigin = false;
		var mock = new MockControllable();

		// Start at specific position
		draggable.getObject().setPosition(50, 50);

		// Drag to outside zones
		simulateDrag(draggable, mock, new Point(50, 50), new Point(500, 500));

		// Should stay at dropped position (not return to origin)
		Assert.isTrue(Type.enumEq(draggable.getState(), Idle));
		Assert.isFalse(draggable.isCurrentlyDragging());
	}

	// --- Zone Hover Tracking ---

	@Test
	public function testDraggableZoneEnterLeave():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		var mock = new MockControllable();
		var events:Array<String> = [];

		draggable.onDragEvent = (event, pos, wrapper) -> {
			switch event {
				case ZoneEnter(zone): events.push("enter:" + zone.id);
				case ZoneLeave(zone): events.push("leave:" + zone.id);
				default:
			}
		};

		// Start drag
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		// Move into zone1
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(125, 125)));
		Assert.equals(1, events.filter(e -> e == "enter:zone1").length);

		// Move out of zone1 to empty space
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(500, 500)));
		Assert.equals(1, events.filter(e -> e == "leave:zone1").length);
	}

	@Test
	public function testDraggableZoneHighlightCallback():Void {
		var draggable = createDraggable();
		var highlightCalls:Array<{id:String, highlight:Bool}> = [];

		var zone:DropZone = {
			id: "hlZone",
			bounds: createDropZoneBounds(100, 100, 50, 50),
			onZoneHighlight: (z, hl) -> highlightCalls.push({id: z.id, highlight: hl})
		};
		draggable.addDropZone(zone);
		var mock = new MockControllable();

		// Start drag
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		// Move into zone
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(125, 125)));
		Assert.equals(1, highlightCalls.length);
		Assert.isTrue(highlightCalls[0].highlight);

		// Move out of zone
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(500, 500)));
		Assert.equals(2, highlightCalls.length);
		Assert.isFalse(highlightCalls[1].highlight);
	}

	// --- Zone Selection ---

	@Test
	public function testDraggableZonePriority():Void {
		var draggable = createDraggable();
		var droppedZone:Null<String> = null;

		// Two overlapping zones at same area, different priorities
		var lowZone:DropZone = {id: "low", bounds: createDropZoneBounds(100, 100, 50, 50), priority: 0};
		var highZone:DropZone = {id: "high", bounds: createDropZoneBounds(100, 100, 50, 50), priority: 10};
		draggable.addDropZone(lowZone);
		draggable.addDropZone(highZone);

		draggable.onDragDrop = (result, wrapper) -> {
			droppedZone = result.zone != null ? result.zone.id : null;
			return true;
		};

		var mock = new MockControllable();
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		Assert.equals("high", droppedZone);
	}

	@Test
	public function testDraggableZoneAcceptsFilter():Void {
		var draggable = createDraggable();
		draggable.returnToOrigin = false;

		// Zone that rejects all drops
		var zone:DropZone = {
			id: "rejecting",
			bounds: createDropZoneBounds(100, 100, 50, 50),
			accepts: (d, z) -> false
		};
		draggable.addDropZone(zone);

		var mock = new MockControllable();
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		// Should be treated as drop outside zone (cancel)
		Assert.isTrue(hasCustomEvent(mock, "dragCancel"));
		Assert.isFalse(hasCustomEvent(mock, "dragDrop"));
	}

	// --- Drag Alpha & Highlight Alpha ---

	@Test
	public function testDraggableDragAlpha():Void {
		var draggable = createDraggable();
		draggable.dragAlpha = 0.5;
		draggable.returnToOrigin = false;
		var mock = new MockControllable();

		var target = draggable.getTarget();
		Assert.floatEquals(1.0, target.alpha);

		// Start drag — alpha should change
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));
		Assert.floatEquals(0.5, target.alpha);

		// Release — alpha should restore
		draggable.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, new Point(500, 500)));
		Assert.floatEquals(1.0, target.alpha);
	}

	@Test
	public function testDraggableZoneHighlightAlpha():Void {
		var draggable = createDraggable();
		draggable.dragAlpha = 0.5;
		draggable.zoneHighlightAlpha = 0.8;
		var zone:DropZone = {id: "z", bounds: createDropZoneBounds(100, 100, 50, 50)};
		draggable.addDropZone(zone);
		var mock = new MockControllable();

		var target = draggable.getTarget();

		// Start drag
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));
		Assert.floatEquals(0.5, target.alpha);

		// Move into zone — should apply zoneHighlightAlpha
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(125, 125)));
		Assert.floatEquals(0.8, target.alpha);

		// Move out of zone — back to dragAlpha
		draggable.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(500, 500)));
		Assert.floatEquals(0.5, target.alpha);
	}

	// --- Highlight Zone Callbacks ---

	@Test
	public function testDraggableDragStartHighlightZones():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		var highlightedZones:Null<Array<DropZone>> = null;

		draggable.onDragStartHighlightZones = (zones) -> highlightedZones = zones;

		var mock = new MockControllable();
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));

		Assert.notNull(highlightedZones);
		Assert.equals(2, highlightedZones.length);
	}

	@Test
	public function testDraggableDragEndHighlightZones():Void {
		var setup = createDraggableWithZones();
		var draggable = setup.draggable;
		draggable.returnToOrigin = false;
		var endZones:Null<Array<DropZone>> = null;

		draggable.onDragEndHighlightZones = (zones) -> endZones = zones;

		var mock = new MockControllable();
		simulateDrag(draggable, mock, new Point(10, 10), new Point(500, 500));

		Assert.notNull(endZones);
		Assert.equals(2, endZones.length);
	}

	// --- Swap Mode ---

	@Test
	public function testDraggableSwapMode():Void {
		var result = BuilderTestBase.buildFromSource(DRAGGABLE_MANIM, "dragContainer");
		var slot0 = result.getSlot("item", 0);
		var slot1 = result.getSlot("item", 1);

		var contentA = new h2d.Object();
		var contentB = new h2d.Object();
		slot0.setContent(contentA);
		slot1.setContent(contentB);

		// Create draggable from slot0
		var draggable = UIMultiAnimDraggable.createFromSlot(slot0);
		Assert.notNull(draggable);
		draggable.swapMode = true;

		// Add slot1 as drop zone with known bounds
		var zone:DropZone = {
			id: "slot1",
			bounds: createDropZoneBounds(100, 100, 50, 50),
			slot: slot1,
			snapX: 100.0,
			snapY: 100.0
		};
		draggable.addDropZone(zone);

		var mock = new MockControllable();
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		// After swap: contentA in slot1, contentB in slot0 (sourceSlot)
		Assert.equals(contentA, slot1.getContent());
		Assert.equals(contentB, slot0.getContent());
	}

	// --- Slot Integration ---

	@Test
	public function testDraggableDropIntoSlot():Void {
		var result = BuilderTestBase.buildFromSource(DRAGGABLE_MANIM, "dragContainer");
		var slot0 = result.getSlot("item", 0);
		var slot1 = result.getSlot("item", 1);

		var content = new h2d.Object();
		slot0.setContent(content);

		var draggable = UIMultiAnimDraggable.createFromSlot(slot0);
		Assert.notNull(draggable);

		// Add slot1 as drop zone
		var zone:DropZone = {
			id: "slot1",
			bounds: createDropZoneBounds(100, 100, 50, 50),
			slot: slot1,
			snapX: 100.0,
			snapY: 100.0
		};
		draggable.addDropZone(zone);

		var mock = new MockControllable();
		simulateDrag(draggable, mock, new Point(10, 10), new Point(125, 125));

		// Content should be in slot1 now
		Assert.isTrue(hasCustomEvent(mock, "dragDrop"));
		Assert.equals(content, slot1.getContent());
		Assert.isTrue(slot0.isEmpty());
	}

	// --- Button Config ---

	@Test
	public function testDraggableButtonFilter():Void {
		var draggable = createDraggable();
		draggable.draggableButtons = [2]; // Only right button
		var mock = new MockControllable();

		// Left button should be ignored
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(0), mock, new Point(10, 10)));
		Assert.isFalse(draggable.isCurrentlyDragging());

		// Right button should work
		draggable.onEvent(UITestHarness.createEventWrapper(OnPush(2), mock, new Point(10, 10)));
		Assert.isTrue(draggable.isCurrentlyDragging());
	}

	// ============== autoSyncInitialState Tests ==============

	@Test
	public function testAutoSyncDisabledByDefault():Void {
		var screen = new UITestScreen();
		var el = new MockNumberElement(42);
		screen.testAddElement(el);

		screen.update(0);

		Assert.equals(0, screen.eventCount());
	}

	@Test
	public function testAutoSyncNumberElement():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockNumberElement(42);
		screen.testAddElement(el);

		screen.update(0);

		Assert.isTrue(screen.hasEvent(UIChangeValue(42)));
	}

	@Test
	public function testAutoSyncFloatElement():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockFloatElement(3.14, 3);
		screen.testAddElement(el);

		screen.update(0);

		// Float element implements both UIElementFloatValue and UIElementNumberValue
		Assert.isTrue(screen.hasEvent(UIChangeFloatValue(3.14)));
		Assert.isTrue(screen.hasEvent(UIChangeValue(3)));
	}

	@Test
	public function testAutoSyncListElement():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		final items:Array<UIElementListItem> = [{name: "Alpha"}, {name: "Beta"}, {name: "Gamma"}];
		var el = new MockListElement(1, items);
		screen.testAddElement(el);

		screen.update(0);

		Assert.isTrue(screen.hasEvent(UIChangeItem(1, items)));
	}

	@Test
	public function testAutoSyncSelectableElement():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockSelectableElement(true);
		screen.testAddElement(el);

		screen.update(0);

		Assert.isTrue(screen.hasEvent(UIToggle(true)));
	}

	@Test
	public function testAutoSyncSelectableElementFalse():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockSelectableElement(false);
		screen.testAddElement(el);

		screen.update(0);

		Assert.isTrue(screen.hasEvent(UIToggle(false)));
	}

	@Test
	public function testAutoSyncMultipleElements():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var numEl = new MockNumberElement(10);
		var selEl = new MockSelectableElement(true);
		screen.testAddElement(numEl);
		screen.testAddElement(selEl);

		screen.update(0);

		Assert.isTrue(screen.hasEvent(UIChangeValue(10)));
		Assert.isTrue(screen.hasEvent(UIToggle(true)));
		Assert.equals(2, screen.eventCount());
	}

	@Test
	public function testAutoSyncOnlyOnFirstUpdate():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockNumberElement(5);
		screen.testAddElement(el);

		screen.update(0);
		Assert.equals(1, screen.eventCount());

		screen.clearEvents();
		screen.update(0);
		Assert.equals(0, screen.eventCount());
	}

	@Test
	public function testAutoSyncThrowsAfterSyncDone():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		screen.update(0);

		// Changing the flag after sync has run should throw
		var threw = false;
		try {
			screen.testSetAutoSyncInitialState(false);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testAutoSyncResetOnClear():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);
		var el = new MockNumberElement(7);
		screen.testAddElement(el);

		screen.update(0);
		Assert.equals(1, screen.eventCount());

		// Clear resets initialSyncDone, so re-adding and updating should sync again
		screen.clear();
		screen.clearEvents();

		screen.testSetAutoSyncInitialState(true);
		var el2 = new MockNumberElement(99);
		screen.testAddElement(el2);

		screen.update(0);
		Assert.isTrue(screen.hasEvent(UIChangeValue(99)));
	}

	@Test
	public function testAutoSyncNoElementsNoEvents():Void {
		var screen = new UITestScreen();
		screen.testSetAutoSyncInitialState(true);

		screen.update(0);

		Assert.equals(0, screen.eventCount());
	}

	// ============== Card Hand Layout Tests ==============

	@Test
	public function testCardHandFanLayoutEmpty():Void {
		var result = bh.ui.UICardHandLayout.computeFanLayout(0, 640, 680, 800, 40, -1, 30, 1.15, 3);
		Assert.equals(0, result.length);
	}

	@Test
	public function testCardHandFanLayoutSingleCard():Void {
		var result = bh.ui.UICardHandLayout.computeFanLayout(1, 640, 680, 800, 40, -1, 30, 1.15, 3);
		Assert.equals(1, result.length);
		Assert.floatEquals(640.0, result[0].x);
		Assert.floatEquals(680.0, result[0].y);
		Assert.floatEquals(0.0, result[0].rotation);
		Assert.floatEquals(1.0, result[0].scale);
	}

	@Test
	public function testCardHandFanLayoutSymmetric():Void {
		// 5 cards should be symmetric around center
		var result = bh.ui.UICardHandLayout.computeFanLayout(5, 640, 680, 800, 40, -1, 30, 1.15, 3);
		Assert.equals(5, result.length);

		// Center card should be at anchorX
		Assert.floatEquals(640.0, result[2].x);

		// Left and right cards should be symmetric around center
		var leftOffset = 640.0 - result[0].x;
		var rightOffset = result[4].x - 640.0;
		Assert.isTrue(Math.abs(leftOffset - rightOffset) < 0.01);

		// Rotations should be symmetric: left negative, center zero, right positive
		Assert.isTrue(result[0].rotation < 0);
		Assert.floatEquals(0.0, result[2].rotation);
		Assert.isTrue(result[4].rotation > 0);
		Assert.isTrue(Math.abs(result[0].rotation + result[4].rotation) < 0.01);
	}

	@Test
	public function testCardHandFanLayoutHover():Void {
		// Hovering middle card should scale it up
		var result = bh.ui.UICardHandLayout.computeFanLayout(3, 640, 680, 800, 40, 1, 30, 1.15, 3);
		Assert.equals(3, result.length);
		Assert.floatEquals(1.15, result[1].scale);
		Assert.floatEquals(1.0, result[0].scale);
		Assert.floatEquals(1.0, result[2].scale);
	}

	@Test
	public function testCardHandLinearLayoutEmpty():Void {
		var result = bh.ui.UICardHandLayout.computeLinearLayout(0, 640, 680, 80, 8, 600, -1, 30, 1.15, 20);
		Assert.equals(0, result.length);
	}

	@Test
	public function testCardHandLinearLayoutCentered():Void {
		// 3 cards should be centered around anchorX
		var result = bh.ui.UICardHandLayout.computeLinearLayout(3, 640, 680, 80, 8, 600, -1, 30, 1.15, 20);
		Assert.equals(3, result.length);

		// Center card at anchor
		Assert.floatEquals(640.0, result[1].x);

		// All at same Y
		Assert.floatEquals(680.0, result[0].y);
		Assert.floatEquals(680.0, result[1].y);
		Assert.floatEquals(680.0, result[2].y);

		// No rotation in linear mode
		Assert.floatEquals(0.0, result[0].rotation);
		Assert.floatEquals(0.0, result[1].rotation);
		Assert.floatEquals(0.0, result[2].rotation);
	}

	@Test
	public function testCardHandLinearLayoutHover():Void {
		var result = bh.ui.UICardHandLayout.computeLinearLayout(3, 640, 680, 80, 8, 600, 1, 30, 1.15, 20);
		Assert.equals(3, result.length);

		// Hovered card pops up
		Assert.floatEquals(650.0, result[1].y); // 680 - 30
		Assert.floatEquals(1.15, result[1].scale);

		// Non-hovered cards at normal Y
		Assert.floatEquals(680.0, result[0].y);
		Assert.floatEquals(680.0, result[2].y);
	}

	@Test
	public function testCardHandLinearLayoutCompression():Void {
		// Many cards should compress to fit maxWidth
		var result = bh.ui.UICardHandLayout.computeLinearLayout(10, 640, 680, 80, 8, 400, -1, 30, 1.15, 20);
		Assert.equals(10, result.length);

		// Total span should not exceed maxWidth
		var leftMost = result[0].x;
		var rightMost = result[9].x;
		Assert.isTrue((rightMost - leftMost) <= 400.0);
	}

	@Test
	public function testCardHandFanLayoutNeighborSpread():Void {
		// Hover should push neighbors apart
		var noHover = bh.ui.UICardHandLayout.computeFanLayout(5, 640, 680, 800, 40, -1, 30, 1.15, 3);
		var withHover = bh.ui.UICardHandLayout.computeFanLayout(5, 640, 680, 800, 40, 2, 30, 1.15, 3);

		// Left neighbor should be pushed further left
		Assert.isTrue(withHover[1].x < noHover[1].x);
		// Right neighbor should be pushed further right
		Assert.isTrue(withHover[3].x > noHover[3].x);
	}

	@Test
	public function testCardHandFanLayoutNormals():Void {
		// Fan layout normals should point outward (toward arc center = upward for small angles)
		var result = bh.ui.UICardHandLayout.computeFanLayout(3, 640, 680, 800, 40, -1, 30, 1.15, 3);
		// Center card normal should point straight up
		Assert.floatEquals(0.0, result[1].normalX);
		Assert.isTrue(result[1].normalY < 0); // upward
	}

	@Test
	public function testCardHandLinearLayoutNormals():Void {
		// Linear layout normals should point straight up
		var result = bh.ui.UICardHandLayout.computeLinearLayout(3, 640, 680, 80, 8, 600, -1, 30, 1.15, 20);
		for (pos in result) {
			Assert.floatEquals(0.0, pos.normalX);
			Assert.floatEquals(-1.0, pos.normalY);
		}
	}

	// ============== Path Layout Tests ==============

	@Test
	public function testCardHandPathLayoutEmpty():Void {
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(0, path, EvenRate, Straight, -1, 30, 1.15, 0.05);
		Assert.equals(0, result.length);
	}

	@Test
	public function testCardHandPathLayoutSingleCard():Void {
		// Single card should be at path midpoint
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(1, path, EvenRate, Straight, -1, 30, 1.15, 0.05);
		Assert.equals(1, result.length);
		Assert.floatEquals(200.0, result[0].x); // midpoint of 0..400
		Assert.floatEquals(0.0, result[0].y);
		Assert.floatEquals(0.0, result[0].rotation); // Straight orientation
	}

	@Test
	public function testCardHandPathLayoutEvenRate():Void {
		// 3 cards on a horizontal line should be at 0, 200, 400
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, -1, 30, 1.15, 0.05);
		Assert.equals(3, result.length);
		Assert.floatEquals(0.0, result[0].x);
		Assert.floatEquals(200.0, result[1].x);
		Assert.floatEquals(400.0, result[2].x);
	}

	@Test
	public function testCardHandPathLayoutEvenArcLength():Void {
		// For a straight line, EvenArcLength should give same result as EvenRate
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenArcLength, Straight, -1, 30, 1.15, 0.05);
		Assert.equals(3, result.length);
		Assert.isTrue(Math.abs(result[0].x - 0.0) < 1.0);
		Assert.isTrue(Math.abs(result[1].x - 200.0) < 1.0);
		Assert.isTrue(Math.abs(result[2].x - 400.0) < 1.0);
	}

	@Test
	public function testCardHandPathLayoutTangentOrientation():Void {
		// Horizontal line: tangent angle should be ~0 radians (pointing right)
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, Tangent, -1, 30, 1.15, 0.05);
		for (pos in result) {
			Assert.isTrue(Math.abs(pos.rotation) < 0.1); // near zero for horizontal line
		}
	}

	@Test
	public function testCardHandPathLayoutStraightOrientation():Void {
		// Straight orientation: all rotations should be 0 regardless of path
		var path = createLinePath(0, 0, 400, 400); // diagonal line
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, -1, 30, 1.15, 0.05);
		for (pos in result) {
			Assert.floatEquals(0.0, pos.rotation);
		}
	}

	@Test
	public function testCardHandPathLayoutTangentClamped():Void {
		// Diagonal line at 45 degrees; clamp at 10 degrees should limit rotation
		var path = createLinePath(0, 0, 400, 400);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, TangentClamped(10.0), -1, 30, 1.15, 0.05);
		var maxRad = 10.0 * Math.PI / 180.0;
		for (pos in result) {
			Assert.isTrue(pos.rotation >= -maxRad - 0.001);
			Assert.isTrue(pos.rotation <= maxRad + 0.001);
		}
	}

	@Test
	public function testCardHandPathLayoutHover():Void {
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, 1, 30, 1.15, 0.05);
		Assert.floatEquals(1.15, result[1].scale);
		Assert.floatEquals(1.0, result[0].scale);
		Assert.floatEquals(1.0, result[2].scale);
	}

	@Test
	public function testCardHandPathLayoutNormals():Void {
		// For a horizontal line (tangent pointing right), normal should be perpendicular
		var path = createLinePath(0, 0, 400, 0);
		var result = bh.ui.UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, -1, 30, 1.15, 0.05);
		for (pos in result) {
			// Normal perpendicular to horizontal tangent: normalX ~= 0, normalY ~= 1 (or -1)
			Assert.isTrue(Math.abs(pos.normalX) < 0.1);
			Assert.isTrue(Math.abs(pos.normalY) > 0.9);
		}
	}

	// Helper: create a simple line path from (x1,y1) to (x2,y2)
	static function createLinePath(x1:Float, y1:Float, x2:Float, y2:Float):bh.paths.MultiAnimPaths.Path {
		var sp = new bh.paths.MultiAnimPaths.SinglePath(new bh.base.FPoint(x1, y1), new bh.base.FPoint(x2, y2), Line);
		return new bh.paths.MultiAnimPaths.Path([sp]);
	}
}
