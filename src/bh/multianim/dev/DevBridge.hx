package bh.multianim.dev;

// MCP DevBridge — inspection and manipulation of running hx-multianim applications, for AI tools.
// What it does (every op, the game's own ops, the event buffers) lives here; how it is reached
// lives in bh.multianim.dev.transport: an HTTP server on HashLink, window.hxDevBridge and a
// WebSocket to a relay in a browser page.
// Only compiles when -D MULTIANIM_DEV is set.

#if MULTIANIM_DEV
import haxe.Json;
import bh.ui.screens.ScreenManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.DefinitionType;
import bh.multianim.MultiAnimParser.Definition;
import bh.multianim.MultiAnimParser.ParametersDefinitions;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.dev.HotReload;
import bh.multianim.dev.transport.IDevBridgeTransport;
import bh.base.TweenManager;

@:access(bh.ui.screens.ScreenManager)
@:access(bh.ui.screens.UIScreen.UIScreenBase)
@:access(bh.multianim.MultiAnimBuilder)
@:access(bh.base.TweenManager)
@:access(hxd.Window)
@:access(bh.base.CachingResourceLoader)
class DevBridge implements IDevBridgeHost {
	public static var autoStart:Bool = true;

	/** Every method `dispatch` answers, for discovery (`window.hxDevBridge.info()`, a relay's hello). */
	public static final METHODS:Array<String> = [
		"ping", "performance", "list_screens", "list_builders", "scene_graph", "screenshot", "inspect_element",
		"set_parameter", "set_visibility", "reload", "eval_manim", "list_resources", "send_event", "send_events",
		"pause", "step", "quit", "get_traces", "get_errors", "get_debugger_hits", "get_parameters",
		"list_interactives", "list_slots", "get_tween_state", "get_screen_state", "find_element_at",
		"inspect_programmable", "list_fonts", "list_atlases", "coordinate_transform", "wait_for_idle",
		"check_overlaps", "click_interactive", "click_button", "list_active_programmables", "list_game_ops",
		"game_op", "get_game_events",
	];

	final screenManager:ScreenManager;
	final port:Int;
	final bindAddress:String;
	final token:Null<String>;
	/** Identifies this run of the game to a relay; a page that reconnects keeps it. */
	public final session:String;

	// ---- Transports ----
	var transports:Array<IDevBridgeTransport> = [];
	var started:Bool = false;
	var eventBroadcasting:Bool = false;

	// ---- Startup ----
	var startTime:Float = 0;
	var actualPort:Int = 0;
	#if hxnodejs
	// On Node the transport can still move to the next port after start(); tick() follows it
	var http:Null<bh.multianim.dev.transport.HttpServerTransport> = null;
	#end

	// ---- Pause state ----
	var paused:Bool = false;
	var savedLoopFunc:Null<Void -> Void> = null;

	// ---- Trace capture ----
	static final TRACE_BUFFER_SIZE = 200;
	var traceBuffer:Array<String> = [];
	var traceDropped:Int = 0;
	var originalTrace:Dynamic = null;

	// ---- Error capture ----
	var errorBuffer:Array<{message:String, stack:String, timestamp:Float}> = [];

	// ---- Debugger hits capture ----
	static final DEBUGGER_BUFFER_SIZE = 100;
	var debuggerBuffer:Array<Dynamic> = [];
	var debuggerDropped:Int = 0;
	var nextDebuggerId:Int = 1;

	// ---- Custom game ops registry (queries, commands, events) ----
	static final GAME_EVENT_BUFFER_SIZE = 200;
	var queryRegistry:Map<String, RegisteredOp> = new Map();
	var commandRegistry:Map<String, RegisteredOp> = new Map();
	var eventRegistry:Map<String, RegisteredEvent> = new Map();
	var gameEventBuffer:Array<Dynamic> = [];
	var gameEventDropped:Int = 0;
	var nextGameEventId:Int = 1;

	#if (js && !hxnodejs)
	// ---- Browser error capture ----
	var browserErrorListener:Null<js.html.Event -> Void>;
	var browserRejectionListener:Null<js.html.Event -> Void>;
	var contextLostListener:Null<js.html.Event -> Void>;
	#end

	public function new(screenManager:ScreenManager, port:Int = 0, ?bindAddress:String) {
		this.screenManager = screenManager;
		this.port = if (port != 0) port else resolvePort();
		this.bindAddress = if (bindAddress != null) bindAddress else resolveBindAddress();
		final configuredToken = DevBridgeConfig.get("HX_DEV_TOKEN");
		this.token = configuredToken != null && configuredToken != "" ? configuredToken : null;
		this.session = newSessionId();
	}

	static function resolvePort():Int {
		var envPort = DevBridgeConfig.get("HX_DEV_PORT");
		if (envPort != null) {
			var parsed = Std.parseInt(envPort);
			if (parsed != null && parsed > 0 && parsed < 65536) return parsed;
			trace('[DevBridge] Invalid HX_DEV_PORT="$envPort", using default 9001');
		}
		return 9001;
	}

	// Bind address for the HTTP server. Default is 0.0.0.0 (all interfaces) so
	// MCP clients on other LAN machines can connect; set HX_DEV_BIND=127.0.0.1
	// to restrict the bridge to the local machine. Without HX_DEV_TOKEN there is
	// no authentication — anything that can reach the port can inspect/manipulate the app.
	static function resolveBindAddress():String {
		var envBind = DevBridgeConfig.get("HX_DEV_BIND");
		if (envBind != null && envBind != "") return envBind;
		return "0.0.0.0";
	}

	static function newSessionId():String {
		final chars = "abcdefghijklmnopqrstuvwxyz0123456789";
		final buf = new StringBuf();
		for (_ in 0...12)
			buf.add(chars.charAt(Std.random(chars.length)));
		return buf.toString();
	}

	public function start():Void {
		if (started) {
			trace('[DevBridge] Error, Already started on port $actualPort');
			return;
		}
		startTime = haxe.Timer.stamp();
		installTraceCapture();

		#if (sys || hxnodejs)
		final http = new bh.multianim.dev.transport.HttpServerTransport(port, bindAddress);
		if (!http.start(this)) {
			restoreTrace();
			return;
		}
		actualPort = http.actualPort;
		#if hxnodejs
		this.http = http;
		#end
		transports.push(http);
		#elseif js
		final relay = DevBridgeConfig.get("HX_DEV_RELAY");
		final hasRelay = relay != null && relay != "";
		if (hasRelay) {
			final ws = new bh.multianim.dev.transport.WebSocketTransport(relay);
			if (ws.start(this)) transports.push(ws);
		}
		// window.hxDevBridge: on unless a relay is named, and then on request (HX_DEV_PAGE=1).
		final pageSetting = DevBridgeConfig.get("HX_DEV_PAGE");
		final wantPage = pageSetting != null && pageSetting != "" ? pageSetting != "0" && pageSetting != "false" : !hasRelay;
		if (wantPage) {
			final page = new bh.multianim.dev.transport.PageTransport();
			if (page.start(this)) transports.push(page);
		}
		if (transports.length == 0) {
			trace('[DevBridge] No transport started (relay "$relay" rejected, page API off)');
			restoreTrace();
			return;
		}
		installBrowserErrorCapture();
		trace('[DevBridge] Ready: ${[for (t in transports) t.describe].join(", ")}');
		#else
		trace('[DevBridge] No transport for this target');
		restoreTrace();
		return;
		#end
		started = true;
		registerListeners();
	}

	public function stop():Void {
		unregisterListeners();
		#if (js && !hxnodejs)
		removeBrowserErrorCapture();
		#end
		for (t in transports)
			t.stop();
		transports = [];
		#if hxnodejs
		http = null;
		#end
		started = false;
		restoreTrace();
	}

	/** Called from ScreenManager.update: lets each transport pump what it needs to (the HTTP
	 *  transport closes pending connections that exceeded the idle deadline). */
	public function tick():Void {
		#if hxnodejs
		final h = http;
		if (h != null)
			actualPort = h.actualPort;
		#end
		for (t in transports)
			t.tick();
	}

	// ---- IDevBridgeHost: what the transports call ----

	public function getToken():Null<String> {
		return token;
	}

	/** Who this game is: a relay's `hello` and `window.hxDevBridge.info()` carry this. */
	public function describeInstance():Dynamic {
		final info:Dynamic = {
			app: resolveAppName(),
			session: session,
			frame: hxd.Timer.frameCount,
			paused: paused,
			transports: [for (t in transports) t.describe],
			ops: METHODS.copy(),
			gameOps: [for (op in queryRegistry.keys()) op].concat([for (op in commandRegistry.keys()) op]),
		};
		#if (js && !hxnodejs)
		info.title = js.Browser.document.title;
		info.url = js.Browser.location.href;
		#end
		return info;
	}

	function resolveAppName():String {
		final configured = DevBridgeConfig.get("HX_DEV_APP");
		if (configured != null && configured != "") return configured;
		final app = screenManager.app;
		return app != null ? Type.getClassName(Type.getClass(app)) : "unknown";
	}

	/** A request body `{"method": ..., "params": ...}`: parse, dispatch, reply. */
	public function handleRequestJson(body:String):DevBridgeReply {
		var request:Dynamic = null;
		try {
			request = Json.parse(body);
		} catch (e:Dynamic) {
			return {status: 400, body: {ok: false, error: "Invalid JSON"}};
		}
		if (request == null || !Std.isOfType(request.method, String))
			return {status: 400, body: {ok: false, error: "Invalid request: expected {method, params}", code: "invalid_params"}};
		return handleCall(request.method, request.params);
	}

	/** An already-parsed call: dispatch it and shape the reply the same way for every transport. */
	public function handleCall(method:String, params:Dynamic):DevBridgeReply {
		if (!Std.isOfType(method, String))
			return {status: 400, body: {ok: false, error: "Invalid request: method must be a string", code: "invalid_params"}};
		if (params == null) params = {};

		trace('[DevBridge] << $method');
		try {
			var result = dispatch(method, params);
			trace('[DevBridge] >> $method OK');
			return {status: 200, body: {ok: true, result: result}};
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
			return {status: httpStatus, body: {ok: false, error: e.message, code: code}};
		} catch (e:Dynamic) {
			trace('[DevBridge] >> $method ERROR (dynamic): $e');
			return {status: 500, body: {ok: false, error: '$e', code: "internal"}};
		}
	}

	// ---- Trace capture ----

	function installTraceCapture():Void {
		// Once only: a second install would record the hook itself as the "original", and the
		// hook would call itself on every trace
		if (originalTrace != null)
			return;
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
			// Push to connected clients
			self.pushEvent("trace", {message: msg, timestamp: haxe.Timer.stamp()});
		};
	}

	function restoreTrace():Void {
		if (originalTrace != null) {
			Reflect.setField(haxe.Log, "trace", originalTrace);
			originalTrace = null;
		}
	}

	#if (js && !hxnodejs)
	// ---- Browser error capture ----
	// Failures the Haxe side never sees (an uncaught exception from a callback, a failed promise, a
	// lost WebGL context, a resource that failed to load) go into the error buffer, prefixed
	// "[browser]" so get_errors tells them apart.

	function installBrowserErrorCapture():Void {
		final window = js.Browser.window;
		browserErrorListener = (event:js.html.Event) -> {
			final e:Dynamic = event;
			final target:Dynamic = event.target;
			if (e.message == null && target != null && target != window) {
				// A resource that failed to load (seen in the capture phase: img, script, link).
				final src:Dynamic = target.src != null ? target.src : target.href;
				reportError('[browser] failed to load ${target.tagName} $src', "");
				return;
			}
			final where = e.filename != null && e.filename != "" ? ' (${e.filename}:${e.lineno}:${e.colno})' : "";
			final err:Dynamic = e.error;
			final stack:String = err != null && err.stack != null ? Std.string(err.stack) : "";
			reportError('[browser] ${e.message}$where', stack);
		};
		browserRejectionListener = (event:js.html.Event) -> {
			final reason:Dynamic = (event : Dynamic).reason;
			final message = reason != null && reason.message != null ? Std.string(reason.message) : Std.string(reason);
			final stack:String = reason != null && reason.stack != null ? Std.string(reason.stack) : "";
			reportError('[browser] unhandled promise rejection: $message', stack);
		};
		window.addEventListener("error", browserErrorListener, true);
		window.addEventListener("unhandledrejection", browserRejectionListener);
		final canvas:Null<js.html.CanvasElement> = @:privateAccess hxd.Window.getInstance().canvas;
		if (canvas != null) {
			contextLostListener = (_) -> reportError("[browser] WebGL context lost", "");
			canvas.addEventListener("webglcontextlost", contextLostListener);
		}
	}

	function removeBrowserErrorCapture():Void {
		final window = js.Browser.window;
		if (browserErrorListener != null) {
			window.removeEventListener("error", browserErrorListener, true);
			browserErrorListener = null;
		}
		if (browserRejectionListener != null) {
			window.removeEventListener("unhandledrejection", browserRejectionListener);
			browserRejectionListener = null;
		}
		if (contextLostListener != null) {
			final canvas:Null<js.html.CanvasElement> = @:privateAccess hxd.Window.getInstance().canvas;
			if (canvas != null) canvas.removeEventListener("webglcontextlost", contextLostListener);
			contextLostListener = null;
		}
	}
	#end

	// ---- Event push ----

	/** Sends an event to every transport: `/sse` subscribers, a relay socket, the page's event ring.
	 *  Guarded against re-entry, since a transport that fails traces, and a trace is an event. */
	function pushEvent(event:String, data:Dynamic):Void {
		if (eventBroadcasting || transports.length == 0) return;
		eventBroadcasting = true;
		try {
			for (t in transports)
				t.pushEvent(event, data);
		} catch (e:Dynamic) {
			trace('[DevBridge] Event push failed ($event): $e');
		}
		eventBroadcasting = false;
	}

	// ---- Event sources ----

	var screenChangeListener:Null<bh.ui.screens.ScreenChangeListener> = null;
	var reloadListener:Null<HotReload.ReloadListener> = null;

	function registerListeners():Void {
		screenChangeListener = onScreenChange;
		screenManager.addScreenChangeListener(screenChangeListener);
		reloadListener = onReloadEvent;
		screenManager.addReloadListener(reloadListener);
	}

	function unregisterListeners():Void {
		if (screenChangeListener != null) {
			screenManager.removeScreenChangeListener(screenChangeListener);
			screenChangeListener = null;
		}
		if (reloadListener != null) {
			screenManager.removeReloadListener(reloadListener);
			reloadListener = null;
		}
	}

	function onScreenChange(event:bh.ui.screens.ScreenChangeEvent):Void {
		pushEvent("screen_change", {
			action: event.action,
			mode: event.mode,
			previousMode: event.previousMode,
			entering: event.entering,
			leaving: event.leaving,
			dialogName: event.dialogName,
			timestamp: haxe.Timer.stamp(),
		});
	}

	function onReloadEvent(event:HotReload.ReloadEvent):Void {
		switch event {
			case ReloadStarted(file, fileType):
				pushEvent("reload", {
					status: "started",
					file: file,
					fileType: switch fileType {
						case Manim: "manim";
						case Anim: "anim";
					},
					timestamp: haxe.Timer.stamp(),
				});
			case ReloadSucceeded(report):
				var payload = reloadReportToPayload(report);
				payload.status = "succeeded";
				payload.timestamp = haxe.Timer.stamp();
				pushEvent("reload", payload);
			case ReloadFailed(report):
				var payload = reloadReportToPayload(report);
				payload.status = "failed";
				payload.timestamp = haxe.Timer.stamp();
				pushEvent("reload", payload);
			case ReloadNeedsRestart(report):
				var payload = reloadReportToPayload(report);
				payload.status = "needs_restart";
				payload.timestamp = haxe.Timer.stamp();
				pushEvent("reload", payload);
		}
	}

	/** Broadcast a custom debug event to all connected MCP clients.
	 *  Use from game code for debugging: `screenManager.devBridge.broadcastCustomEvent("myEvent", {key: "value"})` */
	public function broadcastCustomEvent(name:String, data:Dynamic):Void {
		pushEvent("custom", {name: name, data: data, timestamp: haxe.Timer.stamp()});
	}

	// ---- Custom game ops: registration API ----

	/** Register a read-only game query op, callable via the MCP `game_op` tool.
	 *  `params` is a schema-lite metadata hint (e.g. `{team: "string?"}`) surfaced to the MCP client.
	 *  `handler(params)` must return a JSON-serializable value; throw `haxe.Exception` on failure. */
	public function registerQuery(op:String, description:String, params:Dynamic, handler:Dynamic->Dynamic):Void {
		assertOpNameFree(op);
		queryRegistry.set(op, {description: description, params: params, handler: handler});
	}

	/** Register a mutating/trigger game command op, callable via the MCP `game_op` tool.
	 *  See `registerQuery` for param/handler semantics. */
	public function registerCommand(op:String, description:String, params:Dynamic, handler:Dynamic->Dynamic):Void {
		assertOpNameFree(op);
		commandRegistry.set(op, {description: description, params: params, handler: handler});
	}

	/** Declare a game-emitted event type. Registration is metadata-only (for discovery via `list_game_ops`);
	 *  `emitEvent` does not require pre-registration but will warn if the name is unknown. */
	public function registerEvent(name:String, description:String, payload:Dynamic):Void {
		if (eventRegistry.exists(name))
			throw new haxe.Exception('DevBridge: event "$name" already registered');
		eventRegistry.set(name, {description: description, payload: payload});
	}

	/** Emit a custom game event: pushes into the ring buffer for polling via `get_game_events` and
	 *  broadcasts as SSE `game_event`. Safe to call without prior `registerEvent`. */
	public function emitEvent(name:String, data:Dynamic):Void {
		if (!eventRegistry.exists(name))
			trace('[DevBridge] emitEvent: unregistered event name "$name" (call registerEvent for discovery)');
		var entry:Dynamic = {
			id: nextGameEventId++,
			name: name,
			data: data,
			timestamp: haxe.Timer.stamp(),
		};
		if (gameEventBuffer.length >= GAME_EVENT_BUFFER_SIZE) {
			gameEventBuffer.shift();
			gameEventDropped++;
		}
		gameEventBuffer.push(entry);
		pushEvent("game_event", entry);
	}

	function assertOpNameFree(op:String):Void {
		if (queryRegistry.exists(op) || commandRegistry.exists(op))
			throw new haxe.Exception('DevBridge: op "$op" already registered');
	}

	/** JS-`debugger;`-style breakpoint: snapshot `data`, optionally pause the game loop,
	 *  push an SSE `debugger` event, and store the hit in a ring buffer for polling via get_debugger_hits.
	 *  File/line/method are auto-captured from the call site.
	 *  Resume with the `pause` RPC ({paused:false}). */
	public function debugger(data:Dynamic, pause:Bool = true, ?pos:haxe.PosInfos):Void {
		var entry:Dynamic = {
			id: nextDebuggerId++,
			data: data,
			paused: pause,
			file: pos != null ? pos.fileName : null,
			line: pos != null ? pos.lineNumber : 0,
			method: pos != null ? (pos.className + "." + pos.methodName) : null,
			timestamp: haxe.Timer.stamp(),
		};
		if (debuggerBuffer.length >= DEBUGGER_BUFFER_SIZE) {
			debuggerBuffer.shift();
			debuggerDropped++;
		}
		debuggerBuffer.push(entry);
		pushEvent("debugger", entry);
		if (pause) setPaused(true);
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
			case "get_debugger_hits": handleGetDebuggerHits(params);
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
			case "click_interactive" | "click_button": handleClickInteractive(params);
			// v6: batch events
			case "send_events": handleSendEvents(params);
			// v7: active programmables listing
			case "list_active_programmables": handleListActiveProgrammables(params);
			// v8: custom game ops (query/command/event)
			case "list_game_ops": handleListGameOps(params);
			case "game_op": handleGameOp(params);
			case "get_game_events": handleGetGameEvents(params);
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
		var activeNames = resolveScreenNames(screenManager.activeScreens);

		for (name => screen in screenManager.configuredScreens) {
			var entry:Dynamic = {name: name, active: activeNames.contains(name)};
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

		#if (js && !hxnodejs)
		// format.png needs haxe.zip.Compress, which the browser target lacks; the browser has its own
		// PNG encoder. The size is the render target's, so device pixel ratio does not change it.
		return {
			base64: encodePngInBrowser(pixels),
			width: pixels.width,
			height: pixels.height,
		};
		#else
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
		#end
	}

	#if (js && !hxnodejs)
	/** PNG-encodes captured pixels with a 2D canvas and returns the base64 payload. */
	static function encodePngInBrowser(pixels:hxd.Pixels):String {
		pixels.convert(RGBA);
		final w = pixels.width;
		final h = pixels.height;
		final canvas = js.Browser.document.createCanvasElement();
		canvas.width = w;
		canvas.height = h;
		final ctx = canvas.getContext2d();
		final image = ctx.createImageData(w, h);
		final src = new js.lib.Uint8Array(pixels.bytes.getData(), pixels.offset, w * h * 4);
		image.data.set(cast src);
		pixels.dispose();
		ctx.putImageData(image, 0, 0);
		final url = canvas.toDataURL("image/png");
		return url.substr(url.indexOf(",") + 1);
	}
	#end

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
		pushEvent("parameter_change", {
			programmable: programmable,
			param: paramName,
			value: paramValue,
			timestamp: haxe.Timer.stamp(),
		});
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
		var content:Null<String> = params.content;
		if (content != null) {
			// Reload from text the caller supplies. On JS this is the only way: a page cannot
			// read the file, so the host (the MCP server, a test) sends what is on disk.
			if (file == null)
				throw DevBridgeError.invalidParams("reload with content needs file: the resource path it replaces (e.g. \"ui/menu.manim\")");
			var contentReport = screenManager.hotReloadContent(file, content);
			if (contentReport == null)
				throw DevBridgeError.notFound('No loaded .manim with resource path "$file". Loaded: ${screenManager.loadedManimPaths().join(", ")}');
			return reloadReportToPayload(contentReport);
		}
		#if (js && !hxnodejs)
		throw DevBridgeError.notSupported("reload needs {file, content} on JS: a browser page cannot read the file itself");
		#else
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
		return reloadReportToPayload(report);
		#end
	}

	static function reloadReportToPayload(report:HotReload.ReloadReport):Dynamic {
		return {
			success: report.success,
			file: report.file,
			fileType: switch report.fileType {
				case Manim: "manim";
				case Anim: "anim";
			},
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

		// Validate custom filter references
		if (parseResult.customFilterRefs.length > 0) {
			try {
				bh.base.FilterManager.validateCustomFilters(parseResult.customFilterRefs);
			} catch (e:Dynamic) {
				buildErrors.push(buildErrorPayload("<filters>", e));
			}
		}

		for (nodeName in nodeNames) {
			try {
				var result = builder.buildWithParameters(nodeName, new Map());
				// Clean up built objects to avoid scene graph pollution
				if (result != null && result.object != null)
					result.object.remove();
			} catch (e:Dynamic) {
				buildErrors.push(buildErrorPayload(nodeName, e));
			}
		}

		return {
			success: buildErrors.length == 0,
			nodes: nodeNames,
			buildErrors: buildErrors,
		};
	}

	/** Builds a structured error payload for `eval_manim` build errors. When
	 *  the error is a `BuilderError`, file/line/col/code are extracted so MCP
	 *  clients can present clickable diagnostics. */
	static function buildErrorPayload(nodeName:String, e:Dynamic):Dynamic {
		if (Std.isOfType(e, BuilderError)) {
			final err = cast(e, BuilderError);
			final pos = err.parsedPos();
			return {
				node: nodeName,
				error: err.toString(),
				file: pos != null ? pos.file : null,
				line: pos != null ? pos.line : null,
				col: pos != null ? pos.col : null,
				code: err.code,
			};
		}
		return {
			node: nodeName,
			error: '$e',
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
		setPaused(shouldPause);
		return {paused: paused};
	}

	function setPaused(shouldPause:Bool):Void {
		if (shouldPause && !paused) {
			// Save the real mainLoop and replace with a render-only loop. Skipping render
			// entirely lets the swap chain surface stale buffers (DXGI flip-model in particular
			// leaves buffer contents undefined after Present), causing visible flicker between
			// old frames whenever the OS invalidates the window.
			savedLoopFunc = @:privateAccess hxd.System.loopFunc;
			var app = screenManager.app;
			@:privateAccess hxd.System.loopFunc = () -> {
				hxd.Timer.update();
				if (app.s2d != null) app.s2d.setElapsedTime(0);
				if (app.s3d != null) app.s3d.setElapsedTime(0);
				app.engine.render(app);
			};
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
		#if (js && !hxnodejs)
		// The host page owns the game; closing it is the host's business, never hxd.System.exit().
		throw DevBridgeError.notSupported("quit is not supported in a browser page: the page owns the game. Close the tab instead");
		#end
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

	function handleGetDebuggerHits(params:Dynamic):Dynamic {
		var clear:Bool = params.clear != null ? params.clear : false;
		var limit:Int = params.limit != null ? Std.int(params.limit) : 50;
		if (limit < 1) limit = 1;
		if (limit > DEBUGGER_BUFFER_SIZE) limit = DEBUGGER_BUFFER_SIZE;
		var sinceId:Int = params.since_id != null ? Std.int(params.since_id) : -1;

		var filtered:Array<Dynamic> = sinceId >= 0
			? [for (h in debuggerBuffer) if ((h.id : Int) > sinceId) h]
			: debuggerBuffer.copy();

		var hits:Array<Dynamic> = filtered.length > limit
			? filtered.slice(filtered.length - limit)
			: filtered;

		var total = debuggerBuffer.length;
		var dropped = debuggerDropped;
		var lastId = debuggerBuffer.length > 0 ? (debuggerBuffer[debuggerBuffer.length - 1].id : Int) : 0;

		if (clear) {
			debuggerBuffer = [];
			debuggerDropped = 0;
		}

		return {hits: hits, total: total, dropped: dropped, lastId: lastId};
	}

	// ---- v8: Custom game ops handlers ----

	function handleListGameOps(params:Dynamic):Dynamic {
		var queries:Array<Dynamic> = [];
		for (op => spec in queryRegistry)
			queries.push({op: op, description: spec.description, params: spec.params});
		var commands:Array<Dynamic> = [];
		for (op => spec in commandRegistry)
			commands.push({op: op, description: spec.description, params: spec.params});
		var events:Array<Dynamic> = [];
		for (name => spec in eventRegistry)
			events.push({name: name, description: spec.description, payload: spec.payload});
		return {queries: queries, commands: commands, events: events};
	}

	function handleGameOp(params:Dynamic):Dynamic {
		var op:String = params.op;
		if (op == null) throw DevBridgeError.invalidParams("Required param: op");
		var handlerParams:Dynamic = params.params != null ? params.params : {};

		var spec:Null<RegisteredOp> = queryRegistry.get(op);
		var kind = "query";
		if (spec == null) {
			spec = commandRegistry.get(op);
			kind = "command";
		}
		if (spec == null)
			throw DevBridgeError.notFound('Unknown game op: $op. Call list_game_ops to discover registered ops.');

		try {
			return {kind: kind, op: op, result: spec.handler(handlerParams)};
		} catch (e:DevBridgeError) {
			throw e;
		} catch (e:haxe.Exception) {
			throw new DevBridgeError("internal", 'Handler for "$op" threw: ${e.message}', 500);
		}
	}

	function handleGetGameEvents(params:Dynamic):Dynamic {
		var clear:Bool = params.clear != null ? params.clear : false;
		var limit:Int = params.limit != null ? Std.int(params.limit) : 50;
		if (limit < 1) limit = 1;
		if (limit > GAME_EVENT_BUFFER_SIZE) limit = GAME_EVENT_BUFFER_SIZE;
		var sinceId:Int = params.since_id != null ? Std.int(params.since_id) : -1;
		var typesFilter:Null<Array<String>> = null;
		if (params.types != null) {
			var raw:Array<Dynamic> = params.types;
			typesFilter = [for (t in raw) Std.string(t)];
		}

		var filtered:Array<Dynamic> = [
			for (e in gameEventBuffer)
				if ((sinceId < 0 || (e.id : Int) > sinceId) && (typesFilter == null || typesFilter.indexOf(e.name) >= 0)) e
		];

		var events:Array<Dynamic> = filtered.length > limit
			? filtered.slice(filtered.length - limit)
			: filtered;

		var total = gameEventBuffer.length;
		var dropped = gameEventDropped;
		var lastId = gameEventBuffer.length > 0 ? (gameEventBuffer[gameEventBuffer.length - 1].id : Int) : 0;

		if (clear) {
			gameEventBuffer = [];
			gameEventDropped = 0;
		}

		return {events: events, total: total, dropped: dropped, lastId: lastId};
	}

	/** Called externally to report a caught runtime error. */
	public function reportError(message:String, ?stack:String):Void {
		var stackStr = stack != null ? stack : "";
		var timestamp = haxe.Timer.stamp();
		errorBuffer.push({
			message: message,
			stack: stackStr,
			timestamp: timestamp,
		});
		// Cap buffer size
		if (errorBuffer.length > 100) errorBuffer.shift();
		// Push to SSE clients
		pushEvent("error", {message: message, stack: stackStr, timestamp: timestamp});
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
							entry.currentValue = StateRestorer.resolvedToDynamic(resolved);
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
			var screenInteractives = getScreenInteractives(s, resolveScreenName(s));
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

	// ---- Shared helpers ----

	function resolveScreenName(s:bh.ui.screens.UIScreen):String {
		for (name => screen in screenManager.configuredScreens) {
			if (screen == s) return name;
		}
		return "unknown";
	}

	function resolveScreenNames(screens:Iterable<bh.ui.screens.UIScreen>):Array<String> {
		return [for (s in screens) resolveScreenName(s)];
	}

	function handleGetScreenState(params:Dynamic):Dynamic {
		var screenDetails:Array<Dynamic> = [];
		for (s in screenManager.activeScreens) {
			var sb = (cast s : bh.ui.screens.UIScreen.UIScreenBase);
			screenDetails.push({
				name: resolveScreenName(s),
				elementCount: @:privateAccess sb.elements.length,
				interactiveCount: @:privateAccess sb.interactiveWrappers.length,
			});
		}

		return {
			mode: screenManager.modeToString(screenManager.mode),
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
				var val = StateRestorer.resolvedToDynamic(resolved);
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
				for (s in screenManager.activeScreens)
					screensToCheck.push({screen: s, name: resolveScreenName(s)});
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
			for (s in screenManager.activeScreens)
				screensToSearch.push({screen: s, name: resolveScreenName(s)});
		}

		for (entry in screensToSearch) {
			var sb:bh.ui.screens.UIScreen.UIScreenBase = cast entry.screen;
			var wrapper = sb.getInteractive(id);
			if (wrapper != null) {
				if (wrapper.disabled)
					return {success: false, error: 'Interactive "$id" is disabled', id: id, screen: entry.name};
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
			setPaused(true);
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
				setPaused(false);
			}
			throw e;
		}

		// Auto-resume if we auto-paused
		if (autoPause && !wasAlreadyPaused && paused) {
			setPaused(false);
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
					var val = StateRestorer.resolvedToDynamic(resolved);
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

// ---- Custom game op registry shapes ----

private typedef RegisteredOp = {
	description:String,
	params:Dynamic,
	handler:Dynamic->Dynamic,
};

private typedef RegisteredEvent = {
	description:String,
	payload:Dynamic,
};

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

	/** An op this target cannot do (on JS: `quit`, `reload` without `content`). */
	public static inline function notSupported(message:String):DevBridgeError
		return new DevBridgeError("not_supported", message, 501);
}
#end
