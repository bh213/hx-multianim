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
import bh.ui.UIMultiAnimTextInput;
import bh.ui.UITabGroup;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIElement.UIElementEvents;
import bh.ui.UIElement.UIElementListItem;
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

		// Hover applies immediately via setParameter (no redraw cycle)
		UITestHarness.simulateEnter(button, mock);
		Assert.notNull(button.getObject());

		// Leave applies immediately
		UITestHarness.simulateLeave(button, mock);
		Assert.notNull(button.getObject());
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

		UITestHarness.simulateEnter(input, mock);
		// Disabled should not process hover
		Assert.notNull(input.getObject());
	}

	@Test
	public function testTextInputHoverState():Void {
		ensureTestFont();
		var builder = BuilderTestBase.builderFromSource(TEXTINPUT_MANIM);
		var input = UIMultiAnimTextInput.create(builder, "textInput", {font: "testfont"});
		var mock = new MockControllable();

		UITestHarness.simulateEnter(input, mock);
		Assert.notNull(input.getObject());

		UITestHarness.simulateLeave(input, mock);
		Assert.notNull(input.getObject());
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
	public function testTextInputOnChangeCallback():Void {
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
		// Object exists and getBounds works
		var bounds = input.getObject().getBounds();
		Assert.notNull(bounds);
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
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			dropdown.setSelectedIndex(dropdown.items.length);
		} catch (e:Dynamic) {
			threw = true;
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
		dropdown.requestRedraw = false;
		dropdown.disabled = true;
		Assert.isTrue(dropdown.disabled);
		Assert.isTrue(dropdown.requestRedraw);
	}

	@Test
	public function testDropdownDisabledBlocksAllEvents():Void {
		var dropdown = createDropdown();
		dropdown.doRedraw();
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
		dropdown.doRedraw();
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
}
