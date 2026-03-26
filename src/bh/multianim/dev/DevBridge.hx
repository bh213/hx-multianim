package bh.multianim.dev;

// MCP DevBridge — HTTP server for AI tool integration.
// Provides inspection and manipulation of running hx-multianim applications.
// Only compiles when -D MULTIANIM_DEV is set.

#if MULTIANIM_DEV
import hxd.net.Socket;
import haxe.Json;
import bh.ui.screens.ScreenManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.DefinitionType;
import bh.multianim.MultiAnimParser.Definition;
import bh.multianim.MultiAnimParser.ParametersDefinitions;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.dev.HotReload;
import bh.base.TweenManager;
import bh.ui.UIElement.UIScreenEvent;

@:access(bh.ui.screens.ScreenManager)
@:access(bh.ui.screens.UIScreen.UIScreenBase)
@:access(bh.multianim.MultiAnimBuilder)
@:access(bh.base.TweenManager)
@:access(hxd.Window)
@:access(bh.base.CachingResourceLoader)
class DevBridge {
	final screenManager:ScreenManager;
	final port:Int;
	var serverSocket:Null<Socket>;

	// ---- Startup ----
	var startTime:Float = 0;
	var actualPort:Int = 0;

	// ---- Pause state ----
	var paused:Bool = false;
	var savedLoopFunc:Null<Void -> Void> = null;
	var stepRemaining:Int = 0;

	// ---- Trace capture ----
	static final TRACE_BUFFER_SIZE = 200;
	var traceBuffer:Array<String> = [];
	var traceDropped:Int = 0;
	var originalTrace:Dynamic = null;

	// ---- Error capture ----
	var errorBuffer:Array<{message:String, stack:String, timestamp:Float}> = [];

	public function new(screenManager:ScreenManager, port:Int = 0) {
		this.screenManager = screenManager;
		this.port = if (port != 0) port else resolvePort();
	}

	static function resolvePort():Int {
		var envPort = Sys.getEnv("HX_DEV_PORT");
		if (envPort != null) {
			var parsed = Std.parseInt(envPort);
			if (parsed != null && parsed > 0 && parsed < 65536) return parsed;
			trace('[DevBridge] Invalid HX_DEV_PORT="$envPort", using default 9001');
		}
		return 9001;
	}

	public function start():Void {
		if (serverSocket != null) {
			trace('[DevBridge] Error, Already started on port $actualPort');
			return;
		}
		startTime = haxe.Timer.stamp();
		installTraceCapture();
		serverSocket = new Socket();

		var bound = false;
		var tryPort = port;
		for (_ in 0...10) {
			try {
				serverSocket.bind("0.0.0.0", tryPort, onClientConnected);
				actualPort = tryPort;
				bound = true;
				trace('[DevBridge] Listening on port $tryPort');
				break;
			} catch (e:Dynamic) {
				trace('[DevBridge] Port $tryPort busy, trying next...');
				tryPort++;
			}
		}

		if (!bound) {
			trace('[DevBridge] Failed to bind after 10 attempts (tried ports $port-${port + 9})');
			serverSocket = null;
			return;
		}

		// Write ready file if env var set
		var readyFilePath = Sys.getEnv("HX_DEV_READY_FILE");
		if (readyFilePath != null && readyFilePath != "") {
			try {
				var json = haxe.Json.stringify({
					port: actualPort,
					timestamp: Date.now().getTime() / 1000,
				});
				sys.io.File.saveContent(readyFilePath, json);
				trace('[DevBridge] Ready file written to $readyFilePath');
			} catch (e:Dynamic) {
				trace('[DevBridge] Failed to write ready file: $e');
			}
		}
	}

	public function stop():Void {
		if (serverSocket != null) {
			serverSocket.close();
			serverSocket = null;
			trace("[DevBridge] Stopped");
		}
		restoreTrace();
	}

	// ---- Trace capture ----

	function installTraceCapture():Void {
		originalTrace = haxe.Log.trace;
		var self = this;
		haxe.Log.trace = (v:Dynamic, ?infos:haxe.PosInfos) -> {
			// Call original trace
			var orig = self.originalTrace;
			if (orig != null) orig(v, infos);
			// Buffer the message
			var msg = if (infos != null)
				'${infos.fileName}:${infos.lineNumber}: $v'
			else
				'$v';
			if (self.traceBuffer.length >= TRACE_BUFFER_SIZE) {
				self.traceBuffer.shift();
				self.traceDropped++;
			}
			self.traceBuffer.push(msg);
		};
	}

	function restoreTrace():Void {
		if (originalTrace != null) {
			Reflect.setField(haxe.Log, "trace", originalTrace);
			originalTrace = null;
		}
	}

	// ---- HTTP handling ----

	function onClientConnected(clientSocket:Socket):Void {
		var conn = new HttpConnection(clientSocket);
		clientSocket.onData = () -> {
			try {
				if (conn.processIncoming()) {
					var httpMethod = conn.getHttpMethod();
					if (httpMethod == "OPTIONS") {
						sendResponse(clientSocket, 204, "");
					} else if (httpMethod == "POST") {
						handleRequest(conn.getBody(), clientSocket);
					} else {
						sendJsonResponse(clientSocket, 405, {ok: false, error: "Method not allowed. Use POST."});
					}
				}
			} catch (e:Dynamic) {
				sendJsonResponse(clientSocket, 400, {ok: false, error: 'Bad request: $e'});
			}
		};
		clientSocket.onError = (msg) -> {
			// Client disconnected or error — just ignore
		};
	}

	function handleRequest(body:String, clientSocket:Socket):Void {
		var request:Dynamic = null;
		try {
			request = Json.parse(body);
		} catch (e:Dynamic) {
			sendJsonResponse(clientSocket, 400, {ok: false, error: "Invalid JSON"});
			return;
		}

		var method:String = request.method;
		var params:Dynamic = request.params;
		if (params == null) params = {};

		trace('[DevBridge] << $method');
		try {
			var result = dispatch(method, params);
			trace('[DevBridge] >> $method OK');
			sendJsonResponse(clientSocket, 200, {ok: true, result: result});
		} catch (e:haxe.Exception) {
			var code = "internal";
			var httpStatus = 500;
			if (Std.isOfType(e, DevBridgeError)) {
				var de:DevBridgeError = cast e;
				code = de.code;
				httpStatus = de.httpStatus;
			}
			trace('[DevBridge] >> $method ERROR [$code]: ${e.message}');
			if (code == "internal") trace('[DevBridge]    Stack: ${e.stack}');
			sendJsonResponse(clientSocket, httpStatus, {ok: false, error: e.message, code: code});
		} catch (e:Dynamic) {
			trace('[DevBridge] >> $method ERROR (dynamic): $e');
			sendJsonResponse(clientSocket, 500, {ok: false, error: '$e', code: "internal"});
		}
	}

	function sendJsonResponse(clientSocket:Socket, statusCode:Int, body:Dynamic):Void {
		sendResponse(clientSocket, statusCode, Json.stringify(body));
	}

	function sendResponse(clientSocket:Socket, statusCode:Int, body:String):Void {
		var statusText = switch statusCode {
			case 200: "OK";
			case 204: "No Content";
			case 400: "Bad Request";
			case 405: "Method Not Allowed";
			case 500: "Internal Server Error";
			default: "Unknown";
		};

		var bodyBytes = haxe.io.Bytes.ofString(body);
		var header = 'HTTP/1.1 $statusCode $statusText\r\n'
			+ 'Content-Type: application/json\r\n'
			+ 'Access-Control-Allow-Origin: *\r\n'
			+ 'Access-Control-Allow-Methods: POST, OPTIONS\r\n'
			+ 'Access-Control-Allow-Headers: Content-Type\r\n'
			+ 'Connection: close\r\n'
			+ 'Content-Length: ${bodyBytes.length}\r\n'
			+ '\r\n';

		var headerBytes = haxe.io.Bytes.ofString(header);
		clientSocket.out.writeBytes(headerBytes, 0, headerBytes.length);
		if (bodyBytes.length > 0)
			clientSocket.out.writeBytes(bodyBytes, 0, bodyBytes.length);

		// Close after a short delay to allow data to flush
		haxe.Timer.delay(() -> clientSocket.close(), 50);
	}

	// ---- Command dispatch ----

	function dispatch(method:String, params:Dynamic):Dynamic {
		return switch method {
			// v1 tools
			case "performance": handlePerformance(params);
			case "list_screens": handleListScreens(params);
			case "list_builders": handleListBuilders(params);
			case "scene_graph": handleSceneGraph(params);
			case "screenshot": handleScreenshot(params);
			case "inspect_element": handleInspectElement(params);
			case "set_parameter": handleSetParameter(params);
			case "set_visibility": handleSetVisibility(params);
			case "reload": handleReload(params);
			case "eval_manim": handleEvalManim(params);
			case "list_resources": handleListResources(params);
			case "send_event": handleSendEvent(params);
			// v2: game control
			case "pause": handlePause(params);
			case "step": handleStep(params);
			case "quit": handleQuit(params);
			// v2: trace & error capture
			case "get_traces": handleGetTraces(params);
			case "get_errors": handleGetErrors(params);
			// v2: deep inspection
			case "get_parameters": handleGetParameters(params);
			case "list_interactives": handleListInteractives(params);
			case "list_slots": handleListSlots(params);
			case "get_tween_state": handleGetTweenState(params);
			case "get_screen_state": handleGetScreenState(params);
			case "find_element_at": handleFindElementAt(params);
			case "inspect_programmable": handleInspectProgrammable(params);
			// v3: health, resources, coordinates, idle
			case "ping": handlePing(params);
			case "list_fonts": handleListFonts(params);
			case "list_atlases": handleListAtlases(params);
			case "coordinate_transform": handleCoordinateTransform(params);
			case "wait_for_idle": handleWaitForIdle(params);
			// v4: layout validation
			case "check_overlaps": handleCheckOverlaps(params);
			// v5: direct actions
			case "click_interactive": handleClickInteractive(params);
			// v6: batch events
			case "send_events": handleSendEvents(params);
			// v7: active programmables listing
			case "list_active_programmables": handleListActiveProgrammables(params);
			default: throw DevBridgeError.unknownMethod('Unknown method: $method');
		};
	}

	// ---- v1 tool handlers ----

	function handlePerformance(params:Dynamic):Dynamic {
		var engine = screenManager.app.engine;
		var objectCount = countObjects(screenManager.app.s2d, 0);
		return {
			fps: engine.fps,
			drawCalls: engine.drawCalls,
			drawTriangles: engine.drawTriangles,
			objectCount: objectCount,
			sceneWidth: screenManager.app.s2d.width,
			sceneHeight: screenManager.app.s2d.height,
		};
	}

	function handleListScreens(params:Dynamic):Dynamic {
		var screens:Array<Dynamic> = [];
		var activeSet = new Map<String, Bool>();
		for (s in screenManager.activeScreens) {
			for (name => screen in screenManager.configuredScreens) {
				if (screen == s) {
					activeSet[name] = true;
					break;
				}
			}
		}

		for (name => screen in screenManager.configuredScreens) {
			var entry:Dynamic = {name: name, active: activeSet.exists(name)};
			var failMsg = screenManager.failedScreens.get(name);
			if (failMsg != null) {
				entry.failed = true;
				entry.error = failMsg;
			} else {
				entry.failed = false;
			}
			screens.push(entry);
		}
		return {screens: screens};
	}

	function handleListBuilders(params:Dynamic):Dynamic {
		var builders:Array<Dynamic> = [];
		for (resource => builder in screenManager.builders) {
			var programmables:Array<Dynamic> = [];
			if (builder.multiParserResult != null && builder.multiParserResult.nodes != null) {
				for (nodeName => node in builder.multiParserResult.nodes) {
					var paramDefs = builder.getParameterDefinitions(nodeName);
					var paramList:Array<Dynamic> = [];
					for (paramName => def in paramDefs) {
						if (def != null) {
							paramList.push({
								name: paramName,
								type: defTypeToString(def.type),
							});
						}
					}
					programmables.push({
						name: nodeName,
						parameters: paramList,
					});
				}
			}
			builders.push({
				resource: resource.name,
				programmables: programmables,
			});
		}
		return {builders: builders};
	}

	function handleSceneGraph(params:Dynamic):Dynamic {
		var maxDepth:Int = params.depth != null ? Std.int(params.depth) : 10;
		return walkSceneGraph(screenManager.app.s2d, 0, maxDepth);
	}

	function handleScreenshot(params:Dynamic):Dynamic {
		var s2d = screenManager.app.s2d;

		// When paused, freeze elapsed time so render doesn't advance particles/animations
		if (paused)
			s2d.setElapsedTime(0);

		// Capture at the engine's native resolution (physical window size) so that
		// h2d.Mask scissor calculations (which use engine.width/height) stay correct.
		var engine = screenManager.app.engine;
		var width:Int = engine.width;
		var height:Int = engine.height;

		var renderTexture = new h3d.mat.Texture(width, height, [Target]);
		engine.pushTarget(renderTexture);
		engine.clear(0x1f1f1fff, 1);
		s2d.render(engine);
		var pixels = renderTexture.capturePixels(0, 0, h2d.col.IBounds.fromValues(0, 0, width, height));
		engine.popTarget();
		renderTexture.dispose();

		pixels.convert(BGRA);
		var rawLen = pixels.width * pixels.height * 4;
		var rawBytes:haxe.io.Bytes;
		if (pixels.offset == 0 && pixels.bytes.length == rawLen) {
			rawBytes = pixels.bytes;
		} else {
			rawBytes = haxe.io.Bytes.alloc(rawLen);
			rawBytes.blit(0, pixels.bytes, pixels.offset, rawLen);
		}
		var w = pixels.width;
		var h = pixels.height;
		pixels.dispose();

		var pngData = format.png.Tools.build32BGRA(w, h, rawBytes);
		var out = new haxe.io.BytesOutput();
		new format.png.Writer(out).write(pngData);
		var pngBytes = out.getBytes();

		return {
			base64: haxe.crypto.Base64.encode(pngBytes),
			width: w,
			height: h,
		};
	}

	function handleInspectElement(params:Dynamic):Dynamic {
		var screenName:String = params.screen;
		var elementName:String = params.element;
		if (screenName == null || elementName == null)
			throw DevBridgeError.invalidParams("Required params: screen, element");

		var screen = screenManager.configuredScreens.get(screenName);
		if (screen == null)
			throw DevBridgeError.notFound('Screen not found: $screenName');

		// Search through all builder results on the screen
		var root = screen.getSceneRoot();
		var obj = root.getObjectByName(elementName);
		if (obj == null)
			throw DevBridgeError.notFound('Element not found: $elementName');

		var result:Dynamic = {
			name: elementName,
			type: Type.getClassName(Type.getClass(obj)),
			x: obj.x,
			y: obj.y,
			visible: obj.visible,
			alpha: obj.alpha,
			scaleX: obj.scaleX,
			scaleY: obj.scaleY,
		};

		if (Std.isOfType(obj, h2d.Text)) {
			var t:h2d.Text = cast obj;
			result.text = t.text;
			result.textColor = t.textColor;
		}

		return result;
	}

	function handleSetParameter(params:Dynamic):Dynamic {
		var programmable:String = params.programmable;
		var paramName:String = params.param;
		var paramValue:Dynamic = params.value;
		if (programmable == null || paramName == null)
			throw DevBridgeError.invalidParams("Required params: programmable, param, value");

		// Search all live builder results via hot-reload registry
		var found = findBuilderResult(programmable);
		if (found == null)
			throw DevBridgeError.notFound('No live BuilderResult found for programmable: $programmable');

		found.setParameter(paramName, paramValue);
		return {success: true};
	}

	function handleSetVisibility(params:Dynamic):Dynamic {
		var screenName:String = params.screen;
		var elementName:String = params.element;
		var visible:Bool = params.visible != null ? params.visible : true;
		if (screenName == null || elementName == null)
			throw DevBridgeError.invalidParams("Required params: screen, element, visible");

		var screen = screenManager.configuredScreens.get(screenName);
		if (screen == null)
			throw DevBridgeError.notFound('Screen not found: $screenName');

		var root = screen.getSceneRoot();
		var obj = root.getObjectByName(elementName);
		if (obj == null)
			throw DevBridgeError.notFound('Element not found: $elementName');

		obj.visible = visible;
		return {success: true, visible: visible};
	}

	function handleReload(params:Dynamic):Dynamic {
		var file:String = params.file;
		var resource:Null<hxd.res.Resource> = null;
		if (file != null) {
			try {
				resource = hxd.Res.load(file);
			} catch (e:Dynamic) {
				throw DevBridgeError.notFound('Resource not found: $file');
			}
		}

		var report = screenManager.hotReload(resource);
		if (report == null) {
			return {
				success: true,
				file: file,
				programmablesRebuilt: ([]:Array<String>),
				rebuiltCount: 0,
				elapsedMs: 0.0,
				needsFullRestart: null,
				paramsAdded: ([]:Array<String>),
				errors: ([]:Array<Dynamic>),
			};
		}
		return {
			success: report.success,
			file: report.file,
			programmablesRebuilt: report.programmablesRebuilt,
			rebuiltCount: report.rebuiltCount,
			elapsedMs: report.elapsedMs,
			needsFullRestart: report.needsFullRestart,
			paramsAdded: report.paramsAdded,
			errors: [
				for (err in report.errors)
					{
						message: err.message,
						file: err.file,
						line: err.line,
						col: err.col,
						errorType: switch err.errorType {
							case ParseError: "parse";
							case BuildError: "build";
							case SignatureIncompatible: "signatureIncompatible";
						},
						context: err.context,
					}
			],
		};
	}

	function handleEvalManim(params:Dynamic):Dynamic {
		var source:String = params.source;
		if (source == null)
			throw DevBridgeError.invalidParams("Required param: source");

		// Phase 1: Parse
		var parseResult:bh.multianim.MultiAnimParser.MultiAnimResult;
		try {
			parseResult = bh.multianim.MacroManimParser.parseFile(source, "<eval>");
		} catch (e:Dynamic) {
			return {success: false, parseError: '$e', nodes: ([]:Array<String>), buildErrors: ([]:Array<Dynamic>)};
		}

		var nodeNames:Array<String> = [];
		if (parseResult.nodes != null) {
			for (name => _ in parseResult.nodes)
				nodeNames.push(name);
		}

		// Phase 2: Attempt build for semantic validation
		var buildErrors:Array<Dynamic> = [];
		var builder = new MultiAnimBuilder(parseResult, screenManager.loader, "<eval>");

		for (nodeName in nodeNames) {
			try {
				var result = builder.buildWithParameters(nodeName, new Map());
				// Clean up built objects to avoid scene graph pollution
				if (result != null && result.object != null)
					result.object.remove();
			} catch (e:Dynamic) {
				buildErrors.push({
					node: nodeName,
					error: '$e',
				});
			}
		}

		return {
			success: buildErrors.length == 0,
			nodes: nodeNames,
			buildErrors: buildErrors,
		};
	}

	function handleListResources(params:Dynamic):Dynamic {
		return screenManager.loader.getCacheKeys();
	}

	function updateCursorPosition(window:hxd.Window, x:Float, y:Float):Void {
		window.curMouseX = Std.int(x);
		window.curMouseY = Std.int(y);
	}

	function handleSendEvent(params:Dynamic):Dynamic {
		var type:String = params.type;
		if (type == null)
			throw DevBridgeError.invalidParams("Required param: type (click, key_down, key_up, move, wheel)");

		var window = hxd.Window.getInstance();

		switch type {
			case "click":
				var x:Float = params.x != null ? params.x : 0;
				var y:Float = params.y != null ? params.y : 0;
				var button:Int = params.button != null ? Std.int(params.button) : 0;
				updateCursorPosition(window, x, y);
				window.event(new hxd.Event(EMove, x, y));
				var push = new hxd.Event(EPush, x, y);
				push.button = button;
				window.event(push);
				var release = new hxd.Event(ERelease, x, y);
				release.button = button;
				window.event(release);
				return {success: true, type: type, x: x, y: y, button: button};

			case "mouse_down":
				var x:Float = params.x != null ? params.x : 0;
				var y:Float = params.y != null ? params.y : 0;
				var button:Int = params.button != null ? Std.int(params.button) : 0;
				updateCursorPosition(window, x, y);
				var e = new hxd.Event(EPush, x, y);
				e.button = button;
				window.event(e);
				return {success: true, type: type, x: x, y: y, button: button};

			case "mouse_up":
				var x:Float = params.x != null ? params.x : 0;
				var y:Float = params.y != null ? params.y : 0;
				var button:Int = params.button != null ? Std.int(params.button) : 0;
				updateCursorPosition(window, x, y);
				var e = new hxd.Event(ERelease, x, y);
				e.button = button;
				window.event(e);
				return {success: true, type: type, x: x, y: y, button: button};

			case "move":
				var x:Float = params.x != null ? params.x : 0;
				var y:Float = params.y != null ? params.y : 0;
				updateCursorPosition(window, x, y);
				var e = new hxd.Event(EMove, x, y);
				window.event(e);
				return {success: true, type: type, x: x, y: y};

			case "key_down":
				var keyCode:Int = params.keyCode != null ? Std.int(params.keyCode) : 0;
				var e = new hxd.Event(EKeyDown);
				e.keyCode = keyCode;
				window.event(e);
				return {success: true, type: type, keyCode: keyCode};

			case "key_up":
				var keyCode:Int = params.keyCode != null ? Std.int(params.keyCode) : 0;
				var e = new hxd.Event(EKeyUp);
				e.keyCode = keyCode;
				window.event(e);
				return {success: true, type: type, keyCode: keyCode};

			case "key_press":
				var keyCode:Int = params.keyCode != null ? Std.int(params.keyCode) : 0;
				var down = new hxd.Event(EKeyDown);
				down.keyCode = keyCode;
				window.event(down);
				var up = new hxd.Event(EKeyUp);
				up.keyCode = keyCode;
				window.event(up);
				return {success: true, type: type, keyCode: keyCode};

			case "text":
				var charCode:Int = params.charCode != null ? Std.int(params.charCode) : 0;
				var e = new hxd.Event(ETextInput);
				e.charCode = charCode;
				window.event(e);
				return {success: true, type: type, charCode: charCode};

			case "wheel":
				var delta:Float = params.delta != null ? params.delta : 1.0;
				var x:Float = params.x != null ? params.x : 0;
				var y:Float = params.y != null ? params.y : 0;
				updateCursorPosition(window, x, y);
				var e = new hxd.Event(EWheel, x, y);
				e.wheelDelta = delta;
				window.event(e);
				return {success: true, type: type, delta: delta};

			default:
				throw DevBridgeError.invalidParams('Unknown event type: $type. Valid: click, mouse_down, mouse_up, move, key_down, key_up, key_press, text, wheel');
		}
	}

	// ---- v2: Game control ----

	function handlePause(params:Dynamic):Dynamic {
		var shouldPause:Bool = params.paused != null ? params.paused : true;

		if (shouldPause && !paused) {
			// Save current loop and replace with no-op (rendering continues via engine.present)
			savedLoopFunc = @:privateAccess hxd.System.loopFunc;
			@:privateAccess hxd.System.loopFunc = () -> {};
			paused = true;
			trace("[DevBridge] Game paused");
		} else if (!shouldPause && paused) {
			if (savedLoopFunc != null) {
				@:privateAccess hxd.System.loopFunc = savedLoopFunc;
				savedLoopFunc = null;
			}
			paused = false;
			trace("[DevBridge] Game resumed");
		}

		return {paused: paused};
	}

	function handleStep(params:Dynamic):Dynamic {
		var frames:Int = params.frames != null ? Std.int(params.frames) : 1;
		if (frames < 1) frames = 1;
		if (frames > 100) frames = 100;

		if (!paused)
			throw DevBridgeError.invalidState("Game is not paused. Call pause first.");

		if (savedLoopFunc == null)
			throw DevBridgeError.invalidState("No saved loop function — cannot step.");

		// Run N frames by temporarily restoring the loop
		var loopFn = savedLoopFunc;
		for (_ in 0...frames) {
			loopFn();
		}

		return {paused: true, framesAdvanced: frames};
	}

	function handleQuit(params:Dynamic):Dynamic {
		trace("[DevBridge] Quit requested — exiting in 100ms");
		// Delay exit so HTTP response can be sent
		haxe.Timer.delay(() -> {
			hxd.System.exit();
		}, 100);
		return {success: true};
	}

	// ---- v2: Trace & error capture ----

	function handleGetTraces(params:Dynamic):Dynamic {
		var clear:Bool = params.clear != null ? params.clear : false;
		var limit:Int = params.limit != null ? Std.int(params.limit) : 50;
		if (limit < 1) limit = 1;
		if (limit > TRACE_BUFFER_SIZE) limit = TRACE_BUFFER_SIZE;

		var lines:Array<String>;
		if (limit >= traceBuffer.length) {
			lines = traceBuffer.copy();
		} else {
			lines = traceBuffer.slice(traceBuffer.length - limit);
		}

		var total = traceBuffer.length;
		var dropped = traceDropped;

		if (clear) {
			traceBuffer = [];
			traceDropped = 0;
		}

		return {lines: lines, total: total, dropped: dropped};
	}

	function handleGetErrors(params:Dynamic):Dynamic {
		var clear:Bool = params.clear != null ? params.clear : true;
		var errors = [
			for (err in errorBuffer)
				{message: err.message, stack: err.stack, timestamp: err.timestamp}
		];
		var count = errorBuffer.length;
		if (clear) errorBuffer = [];
		return {errors: errors, count: count};
	}

	/** Called externally to report a caught runtime error. */
	public function reportError(message:String, ?stack:String):Void {
		errorBuffer.push({
			message: message,
			stack: stack != null ? stack : "",
			timestamp: haxe.Timer.stamp(),
		});
		// Cap buffer size
		if (errorBuffer.length > 100) errorBuffer.shift();
	}

	// ---- v2: Deep inspection ----

	function handleGetParameters(params:Dynamic):Dynamic {
		var programmable:String = params.programmable;
		if (programmable == null)
			throw DevBridgeError.invalidParams("Required param: programmable");

		var found = findBuilderResult(programmable);
		if (found == null)
			throw DevBridgeError.notFound('No live BuilderResult found for programmable: $programmable');

		var parameters:Array<Dynamic> = [];

		// Get definitions from the builder
		var handle = findHandle(programmable);
		if (handle != null) {
			var builder = findBuilderForHandle(handle);
			if (builder != null) {
				var defs = builder.getParameterDefinitions(programmable);
				var currentParams:Null<Map<String, ResolvedIndexParameters>> = null;
				if (found.incrementalContext != null)
					currentParams = found.incrementalContext.snapshotParams();

				for (paramName => def in defs) {
					if (def == null) continue;
					var entry:Dynamic = {
						name: paramName,
						type: defTypeToString(def.type),
					};
					// Add current value if available
					if (currentParams != null) {
						var resolved = currentParams.get(paramName);
						if (resolved != null) {
							entry.currentValue = resolvedParamToDynamic(resolved);
						}
					}
					parameters.push(entry);
				}
			}
		}

		return {programmable: programmable, parameters: parameters};
	}

	function handleListInteractives(params:Dynamic):Dynamic {
		var screenName:String = params.screen;

		if (screenName != null) {
			// Single screen mode
			var screen = screenManager.configuredScreens.get(screenName);
			if (screen == null)
				throw DevBridgeError.notFound('Screen not found: $screenName');
			return {screen: screenName, interactives: getScreenInteractives(screen, null)};
		}

		// Aggregate across all active screens
		var allInteractives:Array<Dynamic> = [];
		for (s in screenManager.activeScreens) {
			var name = "unknown";
			for (n => screen in screenManager.configuredScreens) {
				if (screen == s) {
					name = n;
					break;
				}
			}
			var screenInteractives = getScreenInteractives(s, name);
			for (entry in screenInteractives)
				allInteractives.push(entry);
		}
		return {interactives: allInteractives};
	}

	function getScreenInteractives(screen:bh.ui.screens.UIScreen.UIScreen, screenName:Null<String>):Array<Dynamic> {
		var interactives:Array<Dynamic> = [];
		var sb:bh.ui.screens.UIScreen.UIScreenBase = cast screen;
		var wrappers:Array<bh.ui.UIInteractiveWrapper> = @:privateAccess sb.interactiveWrappers;
		for (wrapper in wrappers) {
			var entry:Dynamic = {
				id: wrapper.id,
				x: wrapper.interactive.x,
				y: wrapper.interactive.y,
				disabled: wrapper.disabled,
			};
			if (screenName != null)
				entry.screen = screenName;

			// Add metadata key-values
			if (wrapper.metadata != null) {
				var meta:Dynamic = {};
				var hasMeta = false;
				for (key in wrapper.metadata.keys()) {
					Reflect.setField(meta, key, wrapper.metadata.getStringOrDefault(key, ""));
					hasMeta = true;
				}
				if (hasMeta) entry.metadata = meta;
			}
			interactives.push(entry);
		}

		// Also include UI elements that are buttons (implement UIElementText)
		var elements:Array<bh.ui.UIElement.UIElement> = @:privateAccess sb.elements;
		for (element in elements) {
			if (Std.isOfType(element, bh.ui.UIElement.UIElementText)) {
				var textElement:bh.ui.UIElement.UIElementText = cast element;
				var obj = element.getObject();
				var bounds = obj.getBounds();
				var entry:Dynamic = {
					id: textElement.getText(),
					type: "button",
					x: bounds.xMin,
					y: bounds.yMin,
					width: bounds.width,
					height: bounds.height,
				};
				if (Std.isOfType(element, bh.ui.UIElement.UIElementDisablable)) {
					var disablable:bh.ui.UIElement.UIElementDisablable = cast element;
					entry.disabled = disablable.disabled;
				}
				if (screenName != null)
					entry.screen = screenName;
				interactives.push(entry);
			}
		}
		return interactives;
	}

	function handleListSlots(params:Dynamic):Dynamic {
		var programmable:String = params.programmable;
		if (programmable == null)
			throw DevBridgeError.invalidParams("Required param: programmable");

		var found = findBuilderResult(programmable);
		if (found == null)
			throw DevBridgeError.notFound('No live BuilderResult found for programmable: $programmable');

		var slots:Array<Dynamic> = [];
		if (found.slots != null) {
			for (entry in found.slots) {
				var slotInfo:Dynamic = {
					occupied: entry.handle.isOccupied(),
				};
				switch entry.key {
					case Named(name):
						slotInfo.name = name;
					case Indexed(name, index):
						slotInfo.name = name;
						slotInfo.index = index;
					case Indexed2D(name, indexX, indexY):
						slotInfo.name = name;
						slotInfo.indexX = indexX;
						slotInfo.indexY = indexY;
				}
				if (entry.handle.incrementalContext != null)
					slotInfo.hasParameters = true;
				slots.push(slotInfo);
			}
		}

		return {programmable: programmable, slots: slots};
	}

	function handleGetTweenState(params:Dynamic):Dynamic {
		var tweenInfos:Array<Dynamic> = [];
		for (handle in screenManager.tweens.handles) {
			switch handle {
				case HTween(tween):
					if (!tween.cancelled)
						tweenInfos.push(tweenToInfo(tween));
				case HSequence(seq):
					if (!seq.cancelled) {
						for (t in seq.tweens)
							tweenInfos.push(tweenToInfo(t));
					}
				case HGroup(group):
					if (!group.cancelled) {
						for (t in group.tweens)
							tweenInfos.push(tweenToInfo(t));
					}
			}
		}
		return {activeTweens: tweenInfos.length, tweens: tweenInfos};
	}

	function handleGetScreenState(params:Dynamic):Dynamic {
		var modeStr = switch screenManager.mode {
			case None: "none";
			case Single(_): "single";
			case MasterAndSingle(_, _): "masterAndSingle";
			case Dialog(_, _, _, dialogName): 'dialog:$dialogName';
		};

		var activeNames:Array<String> = [];
		for (s in screenManager.activeScreens) {
			for (name => screen in screenManager.configuredScreens) {
				if (screen == s) {
					activeNames.push(name);
					break;
				}
			}
		}

		var screenDetails:Array<Dynamic> = [];
		for (s in screenManager.activeScreens) {
			var name = "unknown";
			for (n => screen in screenManager.configuredScreens) {
				if (screen == s) {
					name = n;
					break;
				}
			}
			var sb = (cast s : bh.ui.screens.UIScreen.UIScreenBase);
			screenDetails.push({
				name: name,
				elementCount: @:privateAccess sb.elements.length,
				interactiveCount: @:privateAccess sb.interactiveWrappers.length,
			});
		}

		return {
			mode: modeStr,
			isTransitioning: screenManager.isTransitioning,
			paused: paused,
			activeTweens: screenManager.tweens.handles.length,
			activeScreens: screenDetails,
		};
	}

	function handleFindElementAt(params:Dynamic):Dynamic {
		var x:Float = params.x != null ? params.x : 0;
		var y:Float = params.y != null ? params.y : 0;
		var relativeTo:String = params.relative_to;

		// Transform coordinates if relative_to is specified
		if (relativeTo != null) {
			var refObj = screenManager.app.s2d.getObjectByName(relativeTo);
			if (refObj == null)
				throw DevBridgeError.notFound('Element not found for relative_to: $relativeTo');
			var global = refObj.localToGlobal(new h2d.col.Point(x, y));
			x = global.x;
			y = global.y;
		}

		var hits:Array<Dynamic> = [];
		var root = screenManager.app.s2d;
		findObjectsAt(root, x, y, 0, hits);

		// Sort by depth descending (front-most first)
		hits.sort((a, b) -> {
			if (a.depth > b.depth) return -1;
			if (a.depth < b.depth) return 1;
			return 0;
		});

		return {x: x, y: y, elements: hits};
	}

	function handleInspectProgrammable(params:Dynamic):Dynamic {
		var programmable:String = params.programmable;
		if (programmable == null)
			throw DevBridgeError.invalidParams("Required param: programmable");

		var found = findBuilderResult(programmable);
		if (found == null)
			throw DevBridgeError.notFound('No live BuilderResult found for programmable: $programmable');

		var result:Dynamic = {
			name: found.name,
			objectType: Type.getClassName(Type.getClass(found.object)),
			x: found.object.x,
			y: found.object.y,
			visible: found.object.visible,
		};

		// Parameters (current values)
		if (found.incrementalContext != null) {
			var snapshot = found.incrementalContext.snapshotParams();
			var paramValues:Dynamic = {};
			for (paramName => resolved in snapshot) {
				var val = resolvedParamToDynamic(resolved);
				if (val != null)
					Reflect.setField(paramValues, paramName, val);
			}
			result.currentParameters = paramValues;
		}

		// Slots
		if (found.slots != null && found.slots.length > 0) {
			var slotList:Array<Dynamic> = [];
			for (entry in found.slots) {
				var slotInfo:Dynamic = {occupied: entry.handle.isOccupied()};
				switch entry.key {
					case Named(name): slotInfo.name = name;
					case Indexed(name, index):
						slotInfo.name = name;
						slotInfo.index = index;
					case Indexed2D(name, ix, iy):
						slotInfo.name = name;
						slotInfo.indexX = ix;
						slotInfo.indexY = iy;
				}
				slotList.push(slotInfo);
			}
			result.slots = slotList;
		}

		// Dynamic refs
		if (found.dynamicRefs != null) {
			var refs:Array<String> = [];
			for (name => _ in found.dynamicRefs)
				refs.push(name);
			if (refs.length > 0)
				result.dynamicRefs = refs;
		}

		// Named elements
		if (found.names != null) {
			var names:Array<String> = [];
			for (name => _ in found.names)
				names.push(name);
			if (names.length > 0)
				result.namedElements = names;
		}

		// Interactives
		if (found.interactives != null && found.interactives.length > 0)
			result.interactiveCount = found.interactives.length;

		// Settings
		if (found.rootSettings != null) {
			var settings:Dynamic = {};
			var hasSettings = false;
			for (key in found.rootSettings.keys()) {
				Reflect.setField(settings, key, found.rootSettings.getStringOrDefault(key, ""));
				hasSettings = true;
			}
			if (hasSettings) result.settings = settings;
		}

		return result;
	}

	// ---- v3: health, resources, coordinates, idle ----

	function handlePing(params:Dynamic):Dynamic {
		return {
			ok: true,
			uptime: haxe.Timer.stamp() - startTime,
			port: actualPort,
		};
	}

	function handleListFonts(params:Dynamic):Dynamic {
		return {fonts: bh.base.FontManager.getRegisteredFontNames()};
	}

	function handleListAtlases(params:Dynamic):Dynamic {
		var atlases:Array<Dynamic> = [];
		for (name => atlas in screenManager.loader.atlas2Cache) {
			var tileNames:Array<String> = [];
			try {
				var contents = atlas.getContents();
				if (contents != null) {
					for (tileName => _ in contents)
						tileNames.push(tileName);
				}
			} catch (e:Dynamic) {
				// Atlas may not be parsed yet; skip tile listing
			}
			tileNames.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
			atlases.push({name: name, tiles: tileNames});
		}
		return {atlases: atlases};
	}

	function handleCoordinateTransform(params:Dynamic):Dynamic {
		var elementName:String = params.element;
		var x:Float = params.x != null ? params.x : 0;
		var y:Float = params.y != null ? params.y : 0;
		var direction:String = params.direction;
		var screenName:String = params.screen;
		if (elementName == null || direction == null)
			throw DevBridgeError.invalidParams("Required params: element, direction (to_local|to_global)");

		// Find the element
		var obj:h2d.Object = null;
		if (screenName != null) {
			var screen = screenManager.configuredScreens.get(screenName);
			if (screen == null)
				throw DevBridgeError.notFound('Screen not found: $screenName');
			obj = screen.getSceneRoot().getObjectByName(elementName);
		} else {
			obj = screenManager.app.s2d.getObjectByName(elementName);
		}
		if (obj == null)
			throw DevBridgeError.notFound('Element not found: $elementName');

		var point = new h2d.col.Point(x, y);
		var result:h2d.col.Point;
		if (direction == "to_local") {
			result = obj.globalToLocal(point);
		} else if (direction == "to_global") {
			result = obj.localToGlobal(point);
		} else {
			throw DevBridgeError.invalidParams('Invalid direction: $direction. Use "to_local" or "to_global"');
		}

		return {
			element: elementName,
			direction: direction,
			inputX: x,
			inputY: y,
			resultX: result.x,
			resultY: result.y,
		};
	}

	function handleWaitForIdle(params:Dynamic):Dynamic {
		var activeTweenCount = 0;
		for (handle in screenManager.tweens.handles) {
			switch handle {
				case HTween(t):
					if (!t.cancelled) activeTweenCount++;
				case HSequence(s):
					if (!s.cancelled) activeTweenCount++;
				case HGroup(g):
					if (!g.cancelled) activeTweenCount++;
			}
		}
		return {
			idle: activeTweenCount == 0 && !screenManager.isTransitioning && !paused,
			activeTweens: activeTweenCount,
			isTransitioning: screenManager.isTransitioning,
			isPaused: paused,
		};
	}

	// ---- v4: layout validation ----

	function handleCheckOverlaps(params:Dynamic):Dynamic {
		var screenName:String = params.screen;
		var mode:String = params.mode != null ? params.mode : "all";
		var minArea:Int = params.min_overlap_area != null ? Std.int(params.min_overlap_area) : 1;
		var includeHidden:Bool = params.include_hidden != null ? params.include_hidden : false;

		var overlaps:Array<Dynamic> = [];

		// Collect interactives with their global bounds
		if (mode == "all" || mode == "interactives") {
			var interactiveBounds:Array<{id:String, x:Float, y:Float, w:Float, h:Float, disabled:Bool, screen:String}> = [];

			var screensToCheck:Array<{screen:bh.ui.screens.UIScreen.UIScreen, name:String}> = [];
			if (screenName != null) {
				var screen = screenManager.configuredScreens.get(screenName);
				if (screen == null)
					throw DevBridgeError.notFound('Screen not found: $screenName');
				screensToCheck.push({screen: screen, name: screenName});
			} else {
				for (s in screenManager.activeScreens) {
					var name = "unknown";
					for (n => screen in screenManager.configuredScreens) {
						if (screen == s) {
							name = n;
							break;
						}
					}
					screensToCheck.push({screen: s, name: name});
				}
			}

			for (entry in screensToCheck) {
				var wrappers:Array<bh.ui.UIInteractiveWrapper> = @:privateAccess (cast entry.screen : bh.ui.screens.UIScreen.UIScreenBase).interactiveWrappers;
				for (wrapper in wrappers) {
					if (!includeHidden && !wrapper.interactive.visible) continue;
					if (!includeHidden && wrapper.disabled) continue;

					switch wrapper.interactive.multiAnimType {
						case MAInteractive(width, height, _, _):
							// Transform local corners to global
							var topLeft = wrapper.interactive.localToGlobal(new h2d.col.Point(0, 0));
							var bottomRight = wrapper.interactive.localToGlobal(new h2d.col.Point(width, height));
							var gx = Math.min(topLeft.x, bottomRight.x);
							var gy = Math.min(topLeft.y, bottomRight.y);
							var gw = Math.abs(bottomRight.x - topLeft.x);
							var gh = Math.abs(bottomRight.y - topLeft.y);
							interactiveBounds.push({
								id: wrapper.id,
								x: gx,
								y: gy,
								w: gw,
								h: gh,
								disabled: wrapper.disabled,
								screen: entry.name,
							});
						default:
					}
				}
			}

			// Pairwise intersection test
			for (i in 0...interactiveBounds.length) {
				for (j in (i + 1)...interactiveBounds.length) {
					var a = interactiveBounds[i];
					var b = interactiveBounds[j];
					var ox = Math.max(0, Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x));
					var oy = Math.max(0, Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y));
					var area = Std.int(ox * oy);
					if (area >= minArea) {
						overlaps.push({
							type: "interactive",
							severity: "high",
							elementA: {id: a.id, screen: a.screen, bounds: {x: round2(a.x), y: round2(a.y), w: round2(a.w), h: round2(a.h)}},
							elementB: {id: b.id, screen: b.screen, bounds: {x: round2(b.x), y: round2(b.y), w: round2(b.w), h: round2(b.h)}},
							overlapArea: area,
							overlapRect: {
								x: round2(Math.max(a.x, b.x)),
								y: round2(Math.max(a.y, b.y)),
								w: round2(ox),
								h: round2(oy),
							},
						});
					}
				}
			}
		}

		// Collect visual siblings with overlapping bounds
		if (mode == "all" || mode == "visual") {
			collectVisualOverlaps(screenManager.app.s2d, overlaps, minArea, includeHidden);
		}

		// Build summary
		var interactiveCount = 0;
		var visualCount = 0;
		for (o in overlaps) {
			if (o.type == "interactive")
				interactiveCount++;
			else
				visualCount++;
		}

		return {
			overlaps: overlaps,
			summary: {total: overlaps.length, interactive_overlaps: interactiveCount, visual_overlaps: visualCount},
		};
	}

	// ---- v5: Direct Actions ----

	function handleClickInteractive(params:Dynamic):Dynamic {
		var id:String = params.id;
		if (id == null)
			throw DevBridgeError.invalidParams("Required param: id (interactive identifier)");
		var screenName:String = params.screen;

		// Search for the interactive wrapper by id across screens
		var screensToSearch:Array<{screen:bh.ui.screens.UIScreen.UIScreen, name:String}> = [];
		if (screenName != null) {
			var screen = screenManager.configuredScreens.get(screenName);
			if (screen == null)
				throw DevBridgeError.notFound('Screen not found: $screenName');
			screensToSearch.push({screen: screen, name: screenName});
		} else {
			for (s in screenManager.activeScreens) {
				var name = "unknown";
				for (n => screen in screenManager.configuredScreens) {
					if (screen == s) {
						name = n;
						break;
					}
				}
				screensToSearch.push({screen: s, name: name});
			}
		}

		for (entry in screensToSearch) {
			var sb:bh.ui.screens.UIScreen.UIScreenBase = cast entry.screen;
			var wrapper = sb.getInteractive(id);
			if (wrapper != null) {
				if (wrapper.disabled)
					return {success: false, error: 'Interactive "$id" is disabled', id: id, screen: entry.name};
				var emptyMeta = new bh.multianim.MultiAnimBuilder.BuilderResolvedSettings(null);
				sb.dispatchScreenEvent(UIInteractiveEvent(UIClick, id, wrapper.metadata), wrapper);
				return {success: true, id: id, screen: entry.name};
			}

			// Also search UI elements (buttons) by text
			var elements:Array<bh.ui.UIElement.UIElement> = @:privateAccess sb.elements;
			for (element in elements) {
				if (Std.isOfType(element, bh.ui.UIElement.UIElementText)) {
					var textElement:bh.ui.UIElement.UIElementText = cast element;
					if (textElement.getText() == id) {
						if (Std.isOfType(element, bh.ui.UIElement.UIElementDisablable)) {
							var disablable:bh.ui.UIElement.UIElementDisablable = cast element;
							if (disablable.disabled)
								return {success: false, error: 'Button "$id" is disabled', id: id, screen: entry.name};
						}
						sb.dispatchScreenEvent(UIClick, element);
						return {success: true, id: id, screen: entry.name, type: "button"};
					}
				}
			}
		}

		throw DevBridgeError.notFound('Interactive not found: $id');
	}

	// ---- v6: Batch events ----

	function handleSendEvents(params:Dynamic):Dynamic {
		var events:Array<Dynamic> = params.events;
		if (events == null)
			throw DevBridgeError.invalidParams("Required param: events (array of event/step objects)");
		if (events.length == 0)
			throw DevBridgeError.invalidParams("events array must not be empty");
		if (events.length > 200)
			throw DevBridgeError.invalidParams("events array too large (max 200 entries)");

		var autoPause:Bool = params.auto_pause != null ? params.auto_pause : false;
		var wasAlreadyPaused = paused;

		// Auto-pause if requested and not already paused
		if (autoPause && !paused) {
			savedLoopFunc = @:privateAccess hxd.System.loopFunc;
			@:privateAccess hxd.System.loopFunc = () -> {};
			paused = true;
		}

		var window = hxd.Window.getInstance();
		var results:Array<Dynamic> = [];
		var totalFramesStepped = 0;

		try {
			for (entry in events) {
				if (entry.step != null) {
					// Step: run N game frames
					var frames:Int = Std.int(entry.step);
					if (frames < 1) frames = 1;
					if (frames > 100) frames = 100;

					if (!paused)
						throw DevBridgeError.invalidState("Cannot step frames when not paused. Use auto_pause:true or pause first.");
					if (savedLoopFunc == null)
						throw DevBridgeError.invalidState("No saved loop function — cannot step.");

					for (_ in 0...frames) {
						savedLoopFunc();
					}
					totalFramesStepped += frames;
					results.push({step: frames});
				} else if (entry.type != null) {
					// Event: dispatch via same logic as send_event
					var result = handleSendEvent(entry);
					results.push(result);
				} else {
					throw DevBridgeError.invalidParams("Each entry must have either 'type' (event) or 'step' (frame count)");
				}
			}
		} catch (e:haxe.Exception) {
			// Resume if we auto-paused, even on error
			if (autoPause && !wasAlreadyPaused && paused) {
				if (savedLoopFunc != null) {
					@:privateAccess hxd.System.loopFunc = savedLoopFunc;
					savedLoopFunc = null;
				}
				paused = false;
			}
			throw e;
		}

		// Auto-resume if we auto-paused
		if (autoPause && !wasAlreadyPaused && paused) {
			if (savedLoopFunc != null) {
				@:privateAccess hxd.System.loopFunc = savedLoopFunc;
				savedLoopFunc = null;
			}
			paused = false;
		}

		return {
			success: true,
			eventsProcessed: events.length,
			totalFramesStepped: totalFramesStepped,
			results: results,
			paused: paused,
		};
	}

	function collectVisualOverlaps(parent:h2d.Object, overlaps:Array<Dynamic>, minArea:Int, includeHidden:Bool):Void {
		if (parent.numChildren < 2) {
			// Still recurse into single children
			for (i in 0...parent.numChildren)
				collectVisualOverlaps(parent.getChildAt(i), overlaps, minArea, includeHidden);
			return;
		}

		// Collect sibling bounds
		var siblings:Array<{obj:h2d.Object, bounds:h2d.col.Bounds, name:String}> = [];
		for (i in 0...parent.numChildren) {
			var child = parent.getChildAt(i);
			if (!includeHidden && !child.visible) continue;
			if (!includeHidden && child.alpha == 0) continue;
			var bounds = child.getBounds();
			if (bounds == null || bounds.isEmpty()) continue;
			var name = child.name != null ? child.name : '[$i]${Type.getClassName(Type.getClass(child))}';
			siblings.push({obj: child, bounds: bounds, name: name});
		}

		// Pairwise test siblings
		for (i in 0...siblings.length) {
			for (j in (i + 1)...siblings.length) {
				var a = siblings[i];
				var b = siblings[j];
				var ax = a.bounds.xMin;
				var ay = a.bounds.yMin;
				var aw = a.bounds.xMax - a.bounds.xMin;
				var ah = a.bounds.yMax - a.bounds.yMin;
				var bx = b.bounds.xMin;
				var by = b.bounds.yMin;
				var bw = b.bounds.xMax - b.bounds.xMin;
				var bh = b.bounds.yMax - b.bounds.yMin;

				var ox = Math.max(0, Math.min(ax + aw, bx + bw) - Math.max(ax, bx));
				var oy = Math.max(0, Math.min(ay + ah, by + bh) - Math.max(ay, by));
				var area = Std.int(ox * oy);
				if (area >= minArea) {
					overlaps.push({
						type: "visual",
						severity: "low",
						elementA: {name: a.name, bounds: {x: round2(ax), y: round2(ay), w: round2(aw), h: round2(ah)}},
						elementB: {name: b.name, bounds: {x: round2(bx), y: round2(by), w: round2(bw), h: round2(bh)}},
						overlapArea: area,
						overlapRect: {
							x: round2(Math.max(ax, bx)),
							y: round2(Math.max(ay, by)),
							w: round2(ox),
							h: round2(oy),
						},
					});
				}
			}
		}

		// Recurse into children
		for (i in 0...parent.numChildren) {
			collectVisualOverlaps(parent.getChildAt(i), overlaps, minArea, includeHidden);
		}
	}

	static function round2(v:Float):Float {
		return Math.round(v * 100) / 100;
	}

	// ---- v7: active programmables listing ----

	function handleListActiveProgrammables(params:Dynamic):Dynamic {
		// Only programmables built with incremental:true are tracked in the registry
		// (via ReloadSentinel auto-registration). Non-incremental builds will not appear.
		var handles = screenManager.hotReloadRegistry.getAllHandles();

		var programmableName:Null<String> = params.programmable;
		var includeSceneGraph:Bool = params.sceneGraph == true;
		var sceneGraphDepth:Int = params.depth != null ? Std.int(params.depth) : 6;

		var entries:Array<Dynamic> = [];
		for (handle in handles) {
			if (programmableName != null && handle.programmableName != programmableName)
				continue;

			var entry:Dynamic = {
				name: handle.programmableName,
				source: handle.sourcePath,
				x: handle.result.object.x,
				y: handle.result.object.y,
				visible: handle.result.object.visible,
			};

			// Current parameter values (from incremental context)
			if (handle.result.incrementalContext != null) {
				var snapshot = handle.result.incrementalContext.snapshotParams();
				var paramValues:Dynamic = {};
				var hasParams = false;
				for (paramName => resolved in snapshot) {
					var val = resolvedParamToDynamic(resolved);
					if (val != null) {
						Reflect.setField(paramValues, paramName, val);
						hasParams = true;
					}
				}
				if (hasParams)
					entry.currentParameters = paramValues;
			}

			// Parameter definitions (types and defaults) from the builder
			var builder = findBuilderForHandle(handle);
			if (builder != null) {
				var defs = builder.getParameterDefinitions(handle.programmableName);
				var defList:Array<Dynamic> = [];
				for (pName => def in defs) {
					if (def == null) continue;
					defList.push({name: pName, type: defTypeToString(def.type)});
				}
				if (defList.length > 0)
					entry.parameterDefinitions = defList;
			}

			// Named elements summary
			if (handle.result.names != null) {
				var names:Array<String> = [];
				for (name => _ in handle.result.names)
					names.push(name);
				if (names.length > 0)
					entry.namedElements = names;
			}

			// Slot summary
			if (handle.result.slots != null && handle.result.slots.length > 0) {
				var slotList:Array<Dynamic> = [];
				for (s in handle.result.slots) {
					var slotInfo:Dynamic = {occupied: s.handle.isOccupied()};
					switch s.key {
						case Named(name): slotInfo.name = name;
						case Indexed(name, index):
							slotInfo.name = name;
							slotInfo.index = index;
						case Indexed2D(name, ix, iy):
							slotInfo.name = name;
							slotInfo.indexX = ix;
							slotInfo.indexY = iy;
					}
					slotList.push(slotInfo);
				}
				entry.slots = slotList;
			}

			// Interactive count
			if (handle.result.interactives != null && handle.result.interactives.length > 0)
				entry.interactiveCount = handle.result.interactives.length;

			// Optional: scene graph for this programmable's object tree
			if (includeSceneGraph)
				entry.sceneGraph = walkSceneGraph(handle.result.object, 0, sceneGraphDepth);

			entries.push(entry);
		}

		return {
			count: entries.length,
			note: "Only incremental-mode programmables are tracked (built with incremental:true via screen helpers or ReloadableRegistry)",
			programmables: entries,
		};
	}

	// ---- Helpers ----

	function walkSceneGraph(obj:h2d.Object, depth:Int, maxDepth:Int):Dynamic {
		var node:Dynamic = {};
		node.type = Type.getClassName(Type.getClass(obj));
		if (obj.name != null) node.name = obj.name;
		node.x = obj.x;
		node.y = obj.y;
		node.visible = obj.visible;
		if (obj.alpha != 1.0) node.alpha = obj.alpha;
		if (obj.scaleX != 1.0 || obj.scaleY != 1.0) {
			node.scaleX = obj.scaleX;
			node.scaleY = obj.scaleY;
		}

		if (Std.isOfType(obj, h2d.Text)) {
			var t:h2d.Text = cast obj;
			node.text = t.text;
		} else if (Std.isOfType(obj, h2d.Bitmap)) {
			var b:h2d.Bitmap = cast obj;
			if (b.tile != null) {
				node.tileW = b.tile.width;
				node.tileH = b.tile.height;
			}
		}

		if (depth < maxDepth && obj.numChildren > 0) {
			var children:Array<Dynamic> = [];
			for (i in 0...obj.numChildren) {
				children.push(walkSceneGraph(obj.getChildAt(i), depth + 1, maxDepth));
			}
			node.children = children;
		} else if (obj.numChildren > 0) {
			node.childCount = obj.numChildren;
		}

		return node;
	}

	function countObjects(obj:h2d.Object, count:Int):Int {
		count++;
		for (i in 0...obj.numChildren) {
			count = countObjects(obj.getChildAt(i), count);
		}
		return count;
	}

	function findBuilderResult(programmableName:String):Null<BuilderResult> {
		// Search all live builder results via hot-reload registry
		for (handle in screenManager.hotReloadRegistry.getAllHandles()) {
			if (handle.programmableName == programmableName)
				return handle.result;
		}
		return null;
	}

	function findHandle(programmableName:String):Null<HotReload.ReloadableHandle> {
		for (handle in screenManager.hotReloadRegistry.getAllHandles()) {
			if (handle.programmableName == programmableName)
				return handle;
		}
		return null;
	}

	function findBuilderForHandle(handle:HotReload.ReloadableHandle):Null<MultiAnimBuilder> {
		for (resource => builder in screenManager.builders) {
			if (resource.name == handle.sourcePath)
				return builder;
		}
		return null;
	}

	function tweenToInfo(tween:bh.base.TweenManager.Tween):Dynamic {
		var info:Dynamic = {
			duration: tween.duration,
			elapsed: tween.elapsed,
			progress: if (tween.duration > 0) tween.elapsed / tween.duration else 1.0,
		};
		if (tween.target != null && tween.target.name != null)
			info.target = tween.target.name;
		return info;
	}

	function findObjectsAt(obj:h2d.Object, x:Float, y:Float, depth:Int, hits:Array<Dynamic>):Void {
		if (!obj.visible) return;

		var bounds = obj.getBounds();
		if (bounds != null && bounds.contains(new h2d.col.Point(x, y))) {
			var entry:Dynamic = {
				type: Type.getClassName(Type.getClass(obj)),
				depth: depth,
				x: obj.x,
				y: obj.y,
			};
			if (obj.name != null) entry.name = obj.name;
			if (Std.isOfType(obj, h2d.Text)) {
				var t:h2d.Text = cast obj;
				entry.text = t.text;
			}
			// Check if this is an interactive MAObject
			if (Std.isOfType(obj, bh.base.MAObject)) {
				var ma:bh.base.MAObject = cast obj;
				switch ma.multiAnimType {
					case MAInteractive(_, _, identifier, _):
						entry.isInteractive = true;
						entry.interactiveId = identifier;
						var wrapperDisabled = lookupInteractiveDisabled(identifier);
						if (wrapperDisabled != null)
							entry.disabled = wrapperDisabled;
					default:
				}
			}
			hits.push(entry);
		}

		for (i in 0...obj.numChildren) {
			findObjectsAt(obj.getChildAt(i), x, y, depth + 1, hits);
		}
	}

	function lookupInteractiveDisabled(id:String):Null<Bool> {
		for (s in screenManager.activeScreens) {
			var sb = (cast s : bh.ui.screens.UIScreen.UIScreenBase);
			var wrappers:Array<bh.ui.UIInteractiveWrapper> = @:privateAccess sb.interactiveWrappers;
			for (w in wrappers) {
				if (w.id == id) return w.disabled;
			}
		}
		return null;
	}

	static function resolvedParamToDynamic(p:ResolvedIndexParameters):Null<Dynamic> {
		return switch p {
			case Value(val): val;
			case ValueF(val): val;
			case StringValue(s): s;
			case Flag(f): f;
			case Index(_, name): name;
			case ArrayString(arr): arr;
			case ExpressionAlias(_): null;
			case TileSourceValue(_): null;
		};
	}

	static function defTypeToString(t:DefinitionType):Dynamic {
		return switch t {
			case PPTInt: "int";
			case PPTUnsignedInt: "uint";
			case PPTFloat: "float";
			case PPTBool: "bool";
			case PPTString: "string";
			case PPTColor: "color";
			case PPTTile: "tile";
			case PPTArray: "array";
			case PPTHexDirection: "hexDirection";
			case PPTGridDirection: "gridDirection";
			case PPTEnum(values): {type: "enum", values: values};
			case PPTRange(from, to): {type: "range", from: from, to: to};
			case PPTFlags(bits): {type: "flags", bits: bits};
		};
	}
}

// ---- Structured error for MCP error categorization ----

private class DevBridgeError extends haxe.Exception {
	public final code:String;
	public final httpStatus:Int;

	public function new(code:String, message:String, httpStatus:Int = 400) {
		super(message);
		this.code = code;
		this.httpStatus = httpStatus;
	}

	public static inline function notFound(message:String):DevBridgeError
		return new DevBridgeError("not_found", message, 404);

	public static inline function invalidParams(message:String):DevBridgeError
		return new DevBridgeError("invalid_params", message, 400);

	public static inline function invalidState(message:String):DevBridgeError
		return new DevBridgeError("invalid_state", message, 409);

	public static inline function unknownMethod(message:String):DevBridgeError
		return new DevBridgeError("unknown_method", message, 404);
}

// ---- HTTP connection state ----

private class HttpConnection {
	var socket:Socket;
	var headerBuf:StringBuf;
	var headersDone:Bool = false;
	var contentLength:Int = 0;
	var bodyBuf:StringBuf;
	var bodyReceived:Int = 0;
	var httpMethod:String = "";

	public function new(socket:Socket) {
		this.socket = socket;
		this.headerBuf = new StringBuf();
		this.bodyBuf = new StringBuf();
	}

	public function processIncoming():Bool {
		var input = socket.input;
		while (input.available > 0) {
			if (!headersDone) {
				var b = input.readByte();
				headerBuf.addChar(b);
				var headers = headerBuf.toString();
				var endIdx = headers.indexOf("\r\n\r\n");
				if (endIdx >= 0) {
					headersDone = true;
					httpMethod = parseHttpMethod(headers);
					contentLength = parseContentLength(headers);
					// Anything after \r\n\r\n is body
					var bodyStart = headers.substr(endIdx + 4);
					if (bodyStart.length > 0) {
						bodyBuf.addSub(bodyStart, 0, bodyStart.length);
						bodyReceived += bodyStart.length;
					}
				}
			} else {
				// Read body bytes
				var available = input.available;
				var remaining = contentLength - bodyReceived;
				var toRead = available < remaining ? available : remaining;
				if (toRead > 0) {
					var buf = haxe.io.Bytes.alloc(toRead);
					var read = input.readBytes(buf, 0, toRead);
					bodyBuf.addSub(buf.toString(), 0, read);
					bodyReceived += read;
				}
			}
		}
		return headersDone && bodyReceived >= contentLength;
	}

	public function getHttpMethod():String {
		return httpMethod;
	}

	public function getBody():String {
		return bodyBuf.toString();
	}

	static function parseHttpMethod(headers:String):String {
		var spaceIdx = headers.indexOf(" ");
		if (spaceIdx < 0) return "GET";
		return headers.substr(0, spaceIdx);
	}

	static function parseContentLength(headers:String):Int {
		var lower = headers.toLowerCase();
		var idx = lower.indexOf("content-length:");
		if (idx < 0) return 0;
		var valueStart = idx + 15;
		var lineEnd = headers.indexOf("\r\n", valueStart);
		if (lineEnd < 0) lineEnd = headers.length;
		var value = StringTools.trim(headers.substring(valueStart, lineEnd));
		var parsed = Std.parseInt(value);
		return parsed != null ? parsed : 0;
	}
}
#end
