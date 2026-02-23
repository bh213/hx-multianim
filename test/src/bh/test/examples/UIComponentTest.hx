package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness;
import bh.test.UITestHarness.MockControllable;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimProgressBar;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIInteractiveWrapper;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIElement.SubElementsType;

/**
 * Non-visual unit tests for UI components.
 * Tests component creation, state management, event handling, and value interfaces
 * using MockControllable for event simulation and UITestScreen for screen integration.
 */
class UIComponentTest extends BuilderTestBase {
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

		// requestRedraw starts true from constructor
		Assert.isTrue(button.requestRedraw);

		// Hover changes status — requestRedraw stays true
		UITestHarness.simulateEnter(button, mock);
		Assert.isTrue(button.requestRedraw);

		// Leave changes status — requestRedraw stays true
		UITestHarness.simulateLeave(button, mock);
		Assert.isTrue(button.requestRedraw);
	}

	@Test
	public function testButtonDisabledRedrawFlag():Void {
		var builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		var button = UIStandardMultiAnimButton.create(builder, "button", "Test");

		// requestRedraw starts true
		Assert.isTrue(button.requestRedraw);

		button.disabled = true;
		Assert.isTrue(button.disabled);
		Assert.isTrue(button.requestRedraw);
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
		Assert.isTrue(mock.hasInteractiveEvent(UIEntering));
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
	public function testSplitSettingsUnknownPrefixThrows():Void {
		var screen = new UITestScreen();
		var settings:Map<String, SettingValue> = new Map();
		settings.set("unknown.key", RSVString("val"));

		var threw = false;
		try {
			screen.testSplitSettings(settings, [], [], ["item"], [], "test");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
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
}
