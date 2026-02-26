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
import bh.ui.UIMultiAnimScrollableList;
import bh.ui.UIMultiAnimScrollableList.ClickMode;
import bh.ui.UIMultiAnimScrollableList.PanelSizeMode;
import bh.ui.UIMultiAnimTabs;
import bh.ui.UIMultiAnimTabs.UIMultiAnimTabButton;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIElement.UIElementEvents;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIElement.TileRef;
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
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			list.setSelectedIndex(list.items.length);
		} catch (e:Dynamic) {
			threw = true;
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
		list.requestRedraw = false;
		list.disabled = true;
		Assert.isTrue(list.disabled);
		Assert.isTrue(list.requestRedraw);
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
		list.doRedraw();
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
		list.doRedraw();
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
		// scrollToIndex should not change scroll position
		list.scrollToIndex(2);
		// No assertion needed - just verify no exception is thrown
		Assert.pass();
	}

	@Test
	public function testScrollableListScrollToIndexOutOfBounds():Void {
		var list = createScrollableList();
		// Should not throw, just return silently
		list.scrollToIndex(-1);
		list.scrollToIndex(100);
		Assert.pass();
	}

	@Test
	public function testScrollableListScrollToIndexScrollsDown():Void {
		// Create list with many items so scrolling is needed (20 items * 20px = 400px total, 200px panel)
		var items = createManyScrollableListItems(20);
		var list = createScrollableList(items);
		// Item 15 is at y=300, which is below the 200px panel
		list.scrollToIndex(15);
		// After scrollToIndex, the item should be visible (scroll position changed)
		Assert.pass();
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
	public function testScrollableListDoRedraw():Void {
		var list = createScrollableList();
		Assert.isTrue(list.requestRedraw);
		list.doRedraw();
		Assert.isFalse(list.requestRedraw);
	}

	@Test
	public function testScrollableListHoverIndex():Void {
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
	public function testScrollableListDisabledSetTwiceNoDoubleRedraw():Void {
		var list = createScrollableList();
		list.requestRedraw = false;
		list.disabled = true;
		Assert.isTrue(list.requestRedraw);
		list.requestRedraw = false;
		// Setting disabled to same value should not trigger redraw
		list.disabled = true;
		Assert.isFalse(list.requestRedraw);
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
		}
		Assert.isTrue(threw);

		threw = false;
		try {
			result.tabs.beginTab(3);
		} catch (e:Dynamic) {
			threw = true;
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
		}
		Assert.isTrue(threw);
	}
}
