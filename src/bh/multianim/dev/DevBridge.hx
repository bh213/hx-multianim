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
import bh.multianim.dev.HotReload;

@:access(bh.ui.screens.ScreenManager)
@:access(bh.multianim.MultiAnimBuilder)
@:access(hxd.Window)
class DevBridge {
	final screenManager:ScreenManager;
	final port:Int;
	var serverSocket:Null<Socket>;

	public function new(screenManager:ScreenManager, port:Int = 9001) {
		this.screenManager = screenManager;
		this.port = port;
	}

	public function start():Void {
		if (serverSocket != null) return;
		serverSocket = new Socket();
		try {
			serverSocket.bind("0.0.0.0", port, onClientConnected);
			trace('[DevBridge] Listening on port $port');
		} catch (e:Dynamic) {
			trace('[DevBridge] Failed to bind port $port: $e');
			serverSocket = null;
		}
	}

	public function stop():Void {
		if (serverSocket != null) {
			serverSocket.close();
			serverSocket = null;
			trace("[DevBridge] Stopped");
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
			trace('[DevBridge] >> $method ERROR: ${e.message}');
			trace('[DevBridge]    Stack: ${e.stack}');
			sendJsonResponse(clientSocket, 500, {ok: false, error: e.message});
		} catch (e:Dynamic) {
			trace('[DevBridge] >> $method ERROR (dynamic): $e');
			sendJsonResponse(clientSocket, 500, {ok: false, error: '$e'});
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
			default: throw 'Unknown method: $method';
		};
	}

	// ---- Tool handlers ----

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
		var engine = screenManager.app.engine;
		var s2d = screenManager.app.s2d;
		var width:Int = params.width != null ? Std.int(params.width) : s2d.width;
		var height:Int = params.height != null ? Std.int(params.height) : s2d.height;

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
			throw "Required params: screen, element";

		var screen = screenManager.configuredScreens.get(screenName);
		if (screen == null)
			throw 'Screen not found: $screenName';

		// Search through all builder results on the screen
		var root = screen.getSceneRoot();
		var obj = root.getObjectByName(elementName);
		if (obj == null)
			throw 'Element not found: $elementName';

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
			throw "Required params: programmable, param, value";

		// Search all live builder results via hot-reload registry
		var found = findBuilderResult(programmable);
		if (found == null)
			throw 'No live BuilderResult found for programmable: $programmable';

		found.setParameter(paramName, paramValue);
		return {success: true};
	}

	function handleSetVisibility(params:Dynamic):Dynamic {
		var screenName:String = params.screen;
		var elementName:String = params.element;
		var visible:Bool = params.visible != null ? params.visible : true;
		if (screenName == null || elementName == null)
			throw "Required params: screen, element, visible";

		var screen = screenManager.configuredScreens.get(screenName);
		if (screen == null)
			throw 'Screen not found: $screenName';

		var root = screen.getSceneRoot();
		var obj = root.getObjectByName(elementName);
		if (obj == null)
			throw 'Element not found: $elementName';

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
				throw 'Resource not found: $file';
			}
		}

		var report = screenManager.hotReload(resource);
		return {
			success: report.success,
			file: report.file,
			programmablesRebuilt: report.programmablesRebuilt,
			rebuiltCount: report.rebuiltCount,
			elapsedMs: report.elapsedMs,
			errors: [
				for (err in report.errors)
					{
						message: err.message,
						file: err.file,
						line: err.line,
						col: err.col,
					}
			],
		};
	}

	function handleEvalManim(params:Dynamic):Dynamic {
		var source:String = params.source;
		if (source == null)
			throw "Required param: source";

		try {
			var result = bh.multianim.MacroManimParser.parseFile(source, "<eval>");
			var nodeNames:Array<String> = [];
			if (result.nodes != null) {
				for (name => _ in result.nodes) {
					nodeNames.push(name);
				}
			}
			return {success: true, nodes: nodeNames};
		} catch (e:Dynamic) {
			return {success: false, error: '$e'};
		}
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
			throw "Required param: type (click, key_down, key_up, move, wheel)";

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
				throw 'Unknown event type: $type. Valid: click, mouse_down, mouse_up, move, key_down, key_up, key_press, text, wheel';
		}
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
