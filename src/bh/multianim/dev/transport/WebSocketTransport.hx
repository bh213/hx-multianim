package bh.multianim.dev.transport;

#if (MULTIANIM_DEV && js && !hxnodejs)
import haxe.Json;
import bh.multianim.dev.transport.IDevBridgeTransport;

/**
	A browser page cannot listen on a port, so here the game dials out: to a relay (the MCP server
	in `--listen` mode, or `test/devbridge-relay.mjs`) at the URL named by `HX_DEV_RELAY`
	(`?devbridge=ws://127.0.0.1:9010`).

	The wire is one JSON object per message:

	```jsonc
	{"kind":"hello","protocol":1,"app":"…","title":"…","url":"…","session":"k3f9…","token":"…"}  // game → relay, on open
	{"kind":"call","id":7,"method":"list_screens","params":{}}                                 // relay → game
	{"kind":"result","id":7,"ok":true,"result":{…}}                                            // game → relay
	{"kind":"result","id":7,"ok":false,"error":"…","code":"not_found"}
	{"kind":"event","seq":42,"event":"trace","data":{…}}                                        // game → relay, unsolicited
	```

	`id` is the relay's and is echoed back. `seq` is the game's, from 1, and keeps counting while
	the socket is down (events pushed then are not kept), so the relay can tell it missed some.
	When the socket closes the transport dials again after 1 s, doubling to 30 s, and sends `hello`
	again: a page that outlives the relay comes back by itself. A relay that refuses the `hello`
	(wrong token) closes with code 4401; the transport keeps retrying at the slowest rate.
**/
@:keep
class WebSocketTransport implements IDevBridgeTransport {
	public static inline final PROTOCOL = 1;
	public static inline final MIN_BACKOFF_MS = 1000;
	public static inline final MAX_BACKOFF_MS = 30000;
	public static inline final CLOSE_UNAUTHORIZED = 4401;

	public final url:String;
	public var describe(get, never):String;
	public var connected(get, never):Bool;

	var host:Null<IDevBridgeHost>;
	var socket:Null<js.html.WebSocket>;
	var nextSeq:Int = 1;
	var backoffMs:Int = MIN_BACKOFF_MS;
	var reconnectTimer:Null<haxe.Timer>;
	var stopped:Bool = true;
	var loggedFailure:Bool = false;
	var pageHideListener:Null<js.html.Event -> Void>;
	var pageShowListener:Null<js.html.Event -> Void>;

	public function new(url:String) {
		this.url = url;
	}

	function get_describe():String {
		return 'websocket $url';
	}

	function get_connected():Bool {
		return socket != null && socket.readyState == js.html.WebSocket.OPEN;
	}

	public function start(host:IDevBridgeHost):Bool {
		if (!StringTools.startsWith(url, "ws://") && !StringTools.startsWith(url, "wss://")) {
			trace('[DevBridge] Relay URL must start with ws:// or wss:// (got "$url")');
			return false;
		}
		this.host = host;
		stopped = false;
		// Scripts may only close with 1000 or 3000-4999. A page kept in the back/forward cache
		// comes back through pageshow and dials again.
		pageHideListener = (_) -> closeSocket(1000, "page hidden");
		pageShowListener = (_) -> if (!stopped && socket == null && reconnectTimer == null) connect();
		js.Browser.window.addEventListener("pagehide", pageHideListener);
		js.Browser.window.addEventListener("pageshow", pageShowListener);
		connect();
		return true;
	}

	public function stop():Void {
		stopped = true;
		if (reconnectTimer != null) {
			reconnectTimer.stop();
			reconnectTimer = null;
		}
		if (pageHideListener != null) {
			js.Browser.window.removeEventListener("pagehide", pageHideListener);
			pageHideListener = null;
		}
		if (pageShowListener != null) {
			js.Browser.window.removeEventListener("pageshow", pageShowListener);
			pageShowListener = null;
		}
		closeSocket(1000, "DevBridge stopped");
		host = null;
	}

	public function tick():Void {}

	public function pushEvent(name:String, data:Dynamic):Void {
		final seq = nextSeq++;
		if (!connected) return;
		send({kind: "event", seq: seq, event: name, data: data});
	}

	function connect():Void {
		if (stopped) return;
		final ws = try new js.html.WebSocket(url) catch (e:Dynamic) {
			logFailure('cannot open $url: $e');
			scheduleReconnect();
			return;
		};
		socket = ws;
		ws.onopen = () -> {
			if (socket != ws) return;
			backoffMs = MIN_BACKOFF_MS;
			loggedFailure = false;
			final hello:Dynamic = host.describeInstance();
			hello.kind = "hello";
			hello.protocol = PROTOCOL;
			final token = host.getToken();
			if (token != null) hello.token = token;
			send(hello);
		};
		ws.onmessage = (e:js.html.MessageEvent) -> {
			if (socket != ws) return;
			onFrame(Std.string(e.data));
		};
		ws.onclose = (e:js.html.CloseEvent) -> {
			if (socket != ws) return;
			socket = null;
			if (e.code == CLOSE_UNAUTHORIZED) {
				backoffMs = MAX_BACKOFF_MS;
				logFailure('relay $url refused this game: ${e.reason} (check HX_DEV_TOKEN / ?token=)');
			} else if (!stopped) {
				logFailure('relay $url closed (code ${e.code}), retrying');
			}
			scheduleReconnect();
		};
		// An error is always followed by close, which reconnects.
		ws.onerror = (_) -> {};
	}

	function onFrame(text:String):Void {
		var frame:Dynamic;
		try {
			frame = Json.parse(text);
		} catch (e:Dynamic) {
			trace('[DevBridge] Relay sent a frame that is not JSON; ignored');
			return;
		}
		if (frame == null) return;
		switch (frame.kind : String) {
			case "call":
				final reply = host.handleCall(frame.method, frame.params);
				final result:Dynamic = {kind: "result", id: frame.id};
				final body:Dynamic = reply.body;
				for (field in Reflect.fields(body))
					Reflect.setField(result, field, Reflect.field(body, field));
				send(result);
			case "welcome":
				// The relay accepted the hello; calls follow.
				trace('[DevBridge] Connected to relay $url as ${frame.instance}');
			default:
				trace('[DevBridge] Relay sent an unknown frame kind "${frame.kind}"; ignored');
		}
	}

	function send(frame:Dynamic):Void {
		final ws = socket;
		if (ws == null || ws.readyState != js.html.WebSocket.OPEN) return;
		var text:String;
		try {
			text = Json.stringify(frame);
		} catch (e:Dynamic) {
			// A result that cannot be serialised (a cycle in a game op's answer) still gets an answer.
			if (frame.kind == "result")
				text = Json.stringify({kind: "result", id: frame.id, ok: false, error: 'Result is not JSON-serialisable: $e', code: "internal"});
			else
				return;
		}
		try ws.send(text) catch (_:Dynamic) {}
	}

	function scheduleReconnect():Void {
		if (stopped || reconnectTimer != null) return;
		final delay = backoffMs;
		backoffMs = backoffMs * 2 > MAX_BACKOFF_MS ? MAX_BACKOFF_MS : backoffMs * 2;
		reconnectTimer = haxe.Timer.delay(() -> {
			reconnectTimer = null;
			connect();
		}, delay);
	}

	function closeSocket(code:Int, reason:String):Void {
		final ws = socket;
		socket = null;
		if (ws != null) try ws.close(code, reason) catch (_:Dynamic) {}
	}

	/** Logs a connection problem once per outage, not on every retry. */
	function logFailure(message:String):Void {
		if (loggedFailure) return;
		loggedFailure = true;
		trace('[DevBridge] $message');
	}
}
#end
