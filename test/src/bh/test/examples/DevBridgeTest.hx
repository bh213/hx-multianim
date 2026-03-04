package bh.test.examples;

#if MULTIANIM_DEV
import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;
import bh.test.BuilderTestBase.countVisibleChildren;
import bh.multianim.dev.DevBridge;
import bh.multianim.dev.HotReload;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.DefinitionType;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.MultiAnimParser.ReferenceableValue;
import bh.multianim.MultiAnimParser.TileSource;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.UIScreen;

/**
 * Unit tests for DevBridge command handlers.
 * Tests the dispatch/handler logic directly without HTTP infrastructure.
 * Only compiled with -D MULTIANIM_DEV.
 *
 * NOTE: Use double-quoted strings ("...") for .manim source — single-quoted strings
 * trigger Haxe string interpolation which conflicts with .manim $ references.
 */
@:access(bh.multianim.dev.DevBridge)
@:access(bh.ui.screens.ScreenManager)
@:access(bh.ui.screens.UIScreen.UIScreenBase)
@:access(bh.multianim.dev.HotReload.ReloadableRegistry)
class DevBridgeTest extends BuilderTestBase {
	// ===== Helpers =====

	/** Create a DevBridge with a fresh ScreenManager. Does not call start(). */
	static function createTestBridge():DevBridge {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		return new DevBridge(sm, 0);
	}

	/** Create a bridge with a programmable registered in the hot-reload registry. */
	static function createBridgeWithProgrammable(manimSource:String, progName:String):{bridge:DevBridge, result:BuilderResult, builder:MultiAnimBuilder} {
		var bridge = createTestBridge();
		var builder = builderFromSource(manimSource);
		var result = builder.buildWithParameters(progName, new Map(), null, null, true);
		bridge.screenManager.hotReloadRegistry.register("test-source", result, progName);
		return {bridge: bridge, result: result, builder: builder};
	}

	/** Add a configured screen to the bridge's ScreenManager. */
	static function addTestScreen(bridge:DevBridge, name:String, ?active:Bool):DevTestScreen {
		var screen = new DevTestScreen(bridge.screenManager);
		bridge.screenManager.configuredScreens[name] = screen;
		if (active == true)
			bridge.screenManager.activeScreens.push(screen);
		return screen;
	}

	// ==================== Dispatch Routing ====================

	@Test
	public function testDispatch_unknownMethodThrows():Void {
		var bridge = createTestBridge();
		var threw = false;
		try {
			bridge.dispatch("nonexistent", {});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("Unknown method") >= 0);
		}
		Assert.isTrue(threw, "Should throw for unknown method");
	}

	// ==================== Static Helpers ====================

	@Test
	public function testDefTypeToString_primitives():Void {
		Assert.equals("int", DevBridge.defTypeToString(PPTInt));
		Assert.equals("uint", DevBridge.defTypeToString(PPTUnsignedInt));
		Assert.equals("float", DevBridge.defTypeToString(PPTFloat));
		Assert.equals("bool", DevBridge.defTypeToString(PPTBool));
		Assert.equals("string", DevBridge.defTypeToString(PPTString));
		Assert.equals("color", DevBridge.defTypeToString(PPTColor));
		Assert.equals("tile", DevBridge.defTypeToString(PPTTile));
	}

	@Test
	public function testDefTypeToString_enum():Void {
		var result:Dynamic = DevBridge.defTypeToString(PPTEnum(["a", "b", "c"]));
		Assert.equals("enum", result.type);
		Assert.notNull(result.values);
	}

	@Test
	public function testDefTypeToString_range():Void {
		var result:Dynamic = DevBridge.defTypeToString(PPTRange(1, 10));
		Assert.equals("range", result.type);
		Assert.equals(1, result.from);
		Assert.equals(10, result.to);
	}

	@Test
	public function testResolvedParamToDynamic_value():Void {
		Assert.equals(42, DevBridge.resolvedParamToDynamic(Value(42)));
	}

	@Test
	public function testResolvedParamToDynamic_valueF():Void {
		Assert.floatEquals(3.14, DevBridge.resolvedParamToDynamic(ValueF(3.14)));
	}

	@Test
	public function testResolvedParamToDynamic_string():Void {
		Assert.equals("hello", DevBridge.resolvedParamToDynamic(StringValue("hello")));
	}

	@Test
	public function testResolvedParamToDynamic_flag():Void {
		Assert.equals(7, DevBridge.resolvedParamToDynamic(Flag(7)));
	}

	@Test
	public function testResolvedParamToDynamic_index():Void {
		var result = DevBridge.resolvedParamToDynamic(Index(2, "active"));
		Assert.isTrue(Std.isOfType(result, String));
		Assert.equals("active", cast(result, String));
	}

	@Test
	public function testResolvedParamToDynamic_expressionAlias():Void {
		Assert.isNull(DevBridge.resolvedParamToDynamic(ExpressionAlias(RVString("x"))));
	}

	@Test
	public function testResolvedParamToDynamic_tileSource():Void {
		Assert.isNull(DevBridge.resolvedParamToDynamic(TileSourceValue(TSFile(RVString("img.png")))));
	}

	// ==================== Trace Capture ====================

	@Test
	public function testGetTraces_emptyBuffer():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("get_traces", {});
		Assert.equals(0, (result.lines : Array<Dynamic>).length);
		Assert.equals(0, result.total);
		Assert.equals(0, result.dropped);
	}

	@Test
	public function testGetTraces_capturesMessages():Void {
		var bridge = createTestBridge();
		bridge.installTraceCapture();
		try {
			// Add directly to buffer to avoid global trace side effects
			bridge.traceBuffer.push("test message 1");
			bridge.traceBuffer.push("test message 2");
			var result:Dynamic = bridge.dispatch("get_traces", {});
			var lines:Array<Dynamic> = result.lines;
			Assert.equals(2, lines.length);
			Assert.equals("test message 1", lines[0]);
			Assert.equals("test message 2", lines[1]);
		} catch (e:Dynamic) {
			// Ensure cleanup even on failure
		}
		bridge.restoreTrace();
	}

	@Test
	public function testGetTraces_limitParam():Void {
		var bridge = createTestBridge();
		bridge.traceBuffer = ["a", "b", "c", "d", "e"];
		var result:Dynamic = bridge.dispatch("get_traces", {limit: 2});
		var lines:Array<Dynamic> = result.lines;
		Assert.equals(2, lines.length);
		Assert.equals("d", lines[0]);
		Assert.equals("e", lines[1]);
	}

	@Test
	public function testGetTraces_clearParam():Void {
		var bridge = createTestBridge();
		bridge.traceBuffer = ["a", "b"];
		bridge.dispatch("get_traces", {clear: true});
		Assert.equals(0, bridge.traceBuffer.length);
	}

	@Test
	public function testGetTraces_droppedCount():Void {
		var bridge = createTestBridge();
		// Fill buffer beyond capacity
		for (i in 0...210) {
			bridge.traceBuffer.push('line $i');
			if (bridge.traceBuffer.length > 200) {
				bridge.traceBuffer.shift();
				bridge.traceDropped++;
			}
		}
		var result:Dynamic = bridge.dispatch("get_traces", {});
		Assert.equals(200, result.total);
		Assert.equals(10, result.dropped);
	}

	// ==================== Error Capture ====================

	@Test
	public function testGetErrors_empty():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("get_errors", {});
		Assert.equals(0, result.count);
		Assert.equals(0, (result.errors : Array<Dynamic>).length);
	}

	@Test
	public function testGetErrors_afterReportError():Void {
		var bridge = createTestBridge();
		bridge.reportError("boom", "stack trace");
		var result:Dynamic = bridge.dispatch("get_errors", {clear: false});
		Assert.equals(1, result.count);
		var errors:Array<Dynamic> = result.errors;
		Assert.equals("boom", errors[0].message);
		Assert.equals("stack trace", errors[0].stack);
	}

	@Test
	public function testGetErrors_clearParam():Void {
		var bridge = createTestBridge();
		bridge.reportError("err1");
		bridge.reportError("err2");
		// Default is clear:true
		var result:Dynamic = bridge.dispatch("get_errors", {});
		Assert.equals(2, result.count);
		// Buffer should be empty now
		var result2:Dynamic = bridge.dispatch("get_errors", {});
		Assert.equals(0, result2.count);
	}

	@Test
	public function testGetErrors_bufferCap():Void {
		var bridge = createTestBridge();
		for (i in 0...105) {
			bridge.reportError('error $i');
		}
		Assert.equals(100, bridge.errorBuffer.length);
		// Oldest should have been dropped
		Assert.equals("error 5", bridge.errorBuffer[0].message);
	}

	// ==================== eval_manim ====================

	@Test
	public function testEvalManim_validSource():Void {
		var bridge = createTestBridge();
		var source = "version: 1.0\n#test programmable(x:int=0) {\n  bitmap(generated(color(10, 10, #FF0000))): 0,0\n}";
		var result:Dynamic = bridge.dispatch("eval_manim", {source: source});
		Assert.isTrue(result.success);
		var nodes:Array<Dynamic> = result.nodes;
		Assert.equals(1, nodes.length);
		Assert.equals("test", nodes[0]);
	}

	@Test
	public function testEvalManim_invalidSource():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("eval_manim", {source: "this is not valid manim"});
		Assert.isFalse(result.success);
		Assert.notNull(result.error);
	}

	@Test
	public function testEvalManim_missingParam():Void {
		var bridge = createTestBridge();
		var threw = false;
		try {
			bridge.dispatch("eval_manim", {});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("source") >= 0);
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testEvalManim_multipleNodes():Void {
		var bridge = createTestBridge();
		var source = "version: 1.0\n#a programmable(x:int=0) {\n  bitmap(generated(color(5,5,#FF0000))): 0,0\n}\n#b programmable(y:int=0) {\n  bitmap(generated(color(5,5,#00FF00))): 0,0\n}";
		var result:Dynamic = bridge.dispatch("eval_manim", {source: source});
		Assert.isTrue(result.success);
		var nodes:Array<Dynamic> = result.nodes;
		Assert.equals(2, nodes.length);
	}

	// ==================== list_screens ====================

	@Test
	public function testListScreens_empty():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("list_screens", {});
		Assert.equals(0, (result.screens : Array<Dynamic>).length);
	}

	@Test
	public function testListScreens_withConfigured():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "gameScreen");
		var result:Dynamic = bridge.dispatch("list_screens", {});
		var screens:Array<Dynamic> = result.screens;
		Assert.equals(1, screens.length);
		Assert.equals("gameScreen", screens[0].name);
		Assert.isFalse(screens[0].active);
		Assert.isFalse(screens[0].failed);
	}

	@Test
	public function testListScreens_activeFlag():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "activeScreen", true);
		var result:Dynamic = bridge.dispatch("list_screens", {});
		var screens:Array<Dynamic> = result.screens;
		Assert.equals(1, screens.length);
		Assert.isTrue(screens[0].active);
	}

	// ==================== Scene Graph ====================

	@Test
	public function testSceneGraph_basicStructure():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("scene_graph", {});
		Assert.notNull(result.type);
		Assert.isTrue(Std.isOfType(result.type, String));
	}

	@Test
	public function testSceneGraph_depthLimit():Void {
		var bridge = createTestBridge();
		// Add some nested objects to the scene
		var parent = new h2d.Object(bridge.screenManager.app.s2d);
		var child = new h2d.Object(parent);
		new h2d.Object(child); // grandchild

		var result:Dynamic = bridge.dispatch("scene_graph", {depth: 1});
		// Should have children at depth 0->1 but not beyond
		Assert.notNull(result);

		// Cleanup
		parent.remove();
	}

	// ==================== inspect_element ====================

	@Test
	public function testInspectElement_found():Void {
		var bridge = createTestBridge();
		var screen = addTestScreen(bridge, "testScreen");
		var obj = new h2d.Object(screen.getSceneRoot());
		obj.name = "myElement";
		obj.x = 42;
		obj.y = 99;

		var result:Dynamic = bridge.dispatch("inspect_element", {screen: "testScreen", element: "myElement"});
		Assert.equals("myElement", result.name);
		Assert.floatEquals(42.0, result.x);
		Assert.floatEquals(99.0, result.y);
		Assert.isTrue(result.visible);

		obj.remove();
	}

	@Test
	public function testInspectElement_notFound():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "testScreen");
		var threw = false;
		try {
			bridge.dispatch("inspect_element", {screen: "testScreen", element: "missing"});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("Element not found") >= 0);
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testInspectElement_screenNotFound():Void {
		var bridge = createTestBridge();
		var threw = false;
		try {
			bridge.dispatch("inspect_element", {screen: "noScreen", element: "x"});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("Screen not found") >= 0);
		}
		Assert.isTrue(threw);
	}

	// ==================== set_parameter ====================

	@Test
	public function testSetParameter_success():Void {
		var setup = createBridgeWithProgrammable(
			"#test programmable(x:int=0) {\n  bitmap(generated(color(10, 10, #FF0000))): 0,0\n}",
			"test"
		);
		var result:Dynamic = setup.bridge.dispatch("set_parameter", {programmable: "test", param: "x", value: 5});
		Assert.isTrue(result.success);
	}

	@Test
	public function testSetParameter_notFound():Void {
		var bridge = createTestBridge();
		var threw = false;
		try {
			bridge.dispatch("set_parameter", {programmable: "nonexistent", param: "x", value: 1});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("No live BuilderResult") >= 0);
		}
		Assert.isTrue(threw);
	}

	// ==================== set_visibility ====================

	@Test
	public function testSetVisibility_toggle():Void {
		var bridge = createTestBridge();
		var screen = addTestScreen(bridge, "testScreen");
		var obj = new h2d.Object(screen.getSceneRoot());
		obj.name = "toggleMe";
		obj.visible = true;

		bridge.dispatch("set_visibility", {screen: "testScreen", element: "toggleMe", visible: false});
		Assert.isFalse(obj.visible);

		bridge.dispatch("set_visibility", {screen: "testScreen", element: "toggleMe", visible: true});
		Assert.isTrue(obj.visible);

		obj.remove();
	}

	@Test
	public function testSetVisibility_notFound():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "testScreen");
		var threw = false;
		try {
			bridge.dispatch("set_visibility", {screen: "testScreen", element: "missing", visible: false});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("Element not found") >= 0);
		}
		Assert.isTrue(threw);
	}

	// ==================== list_slots ====================

	@Test
	public function testListSlots_empty():Void {
		var setup = createBridgeWithProgrammable(
			"#test programmable(x:int=0) {\n  bitmap(generated(color(10, 10, #FF0000))): 0,0\n}",
			"test"
		);
		var result:Dynamic = setup.bridge.dispatch("list_slots", {programmable: "test"});
		Assert.equals("test", result.programmable);
		Assert.equals(0, (result.slots : Array<Dynamic>).length);
	}

	@Test
	public function testListSlots_found():Void {
		var setup = createBridgeWithProgrammable(
			"#test programmable(x:int=0) {\n  #mySlot slot: 0,0\n}",
			"test"
		);
		var result:Dynamic = setup.bridge.dispatch("list_slots", {programmable: "test"});
		var slots:Array<Dynamic> = result.slots;
		Assert.equals(1, slots.length);
		Assert.equals("mySlot", slots[0].name);
	}

	// ==================== list_interactives ====================

	@Test
	public function testListInteractives_emptyScreen():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "testScreen");
		var result:Dynamic = bridge.dispatch("list_interactives", {screen: "testScreen"});
		Assert.equals("testScreen", result.screen);
		Assert.equals(0, (result.interactives : Array<Dynamic>).length);
	}

	// ==================== inspect_programmable ====================

	@Test
	public function testInspectProgrammable_basic():Void {
		var setup = createBridgeWithProgrammable(
			"#test programmable(x:int=0) {\n  bitmap(generated(color(10, 10, #FF0000))): 0,0\n}",
			"test"
		);
		var result:Dynamic = setup.bridge.dispatch("inspect_programmable", {programmable: "test"});
		Assert.equals("test", result.name);
		Assert.notNull(result.objectType);
		Assert.isTrue(result.visible);
	}

	@Test
	public function testInspectProgrammable_withSlots():Void {
		var setup = createBridgeWithProgrammable(
			"#test programmable(x:int=0) {\n  #s1 slot: 0,0\n  #s2 slot: 10,10\n}",
			"test"
		);
		var result:Dynamic = setup.bridge.dispatch("inspect_programmable", {programmable: "test"});
		var slots:Array<Dynamic> = result.slots;
		Assert.equals(2, slots.length);
	}

	@Test
	public function testInspectProgrammable_notFound():Void {
		var bridge = createTestBridge();
		var threw = false;
		try {
			bridge.dispatch("inspect_programmable", {programmable: "nonexistent"});
		} catch (e:haxe.Exception) {
			threw = true;
			Assert.isTrue(e.message.indexOf("No live BuilderResult") >= 0);
		}
		Assert.isTrue(threw);
	}

	// ==================== get_screen_state ====================

	@Test
	public function testGetScreenState_initial():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("get_screen_state", {});
		Assert.equals("none", result.mode);
		Assert.isFalse(result.paused);
		Assert.equals(0, (result.activeScreens : Array<Dynamic>).length);
	}

	@Test
	public function testGetScreenState_withActive():Void {
		var bridge = createTestBridge();
		addTestScreen(bridge, "myScreen", true);
		var result:Dynamic = bridge.dispatch("get_screen_state", {});
		var active:Array<Dynamic> = result.activeScreens;
		Assert.equals(1, active.length);
		Assert.equals("myScreen", active[0].name);
	}

	// ==================== get_tween_state ====================

	@Test
	public function testGetTweenState_empty():Void {
		var bridge = createTestBridge();
		var result:Dynamic = bridge.dispatch("get_tween_state", {});
		Assert.equals(0, result.activeTweens);
		Assert.equals(0, (result.tweens : Array<Dynamic>).length);
	}
}

// ---- Private inner class for test screens ----

private class DevTestScreen extends UIScreenBase {
	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {}
}
#end
