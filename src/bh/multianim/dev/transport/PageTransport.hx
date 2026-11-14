package bh.multianim.dev.transport;

#if (MULTIANIM_DEV && js && !hxnodejs)
import haxe.Json;
import bh.multianim.dev.transport.IDevBridgeTransport;

/**
	`window.hxDevBridge`: the DevBridge as a function the page calls, so anything that can run
	script in the page (the Playwright MCP's `browser_evaluate`, a test harness, the console) can
	drive a browser build with the same ops a HashLink build answers over HTTP.

	```js
	window.hxDevBridge = {
	  protocol: 1,
	  info: () => ({protocol, app, title, url, session, frame, transports, ops, gameOps}),
	  call: (request) => responseJson,   // request: JSON string or {method, params}; synchronous
	  poll: (sinceSeq) => '{"events":[{seq, event, data}], "lastSeq":N, "dropped":N, "missed":N}',
	};
	```

	`call` answers `{ok: true, result}` or `{ok: false, error, code}` as a JSON string, the same body
	the HTTP transport sends. Events are kept in a ring of the last 200: `dropped` counts every
	event pushed out of it since start, `missed` those newer than `sinceSeq` that were.
**/
@:keep
class PageTransport implements IDevBridgeTransport {
	public static inline final PROTOCOL = 1;
	public static inline final EVENT_BUFFER_SIZE = 200;

	public var describe(get, never):String;

	var host:Null<IDevBridgeHost>;
	var events:Array<{seq:Int, event:String, data:Dynamic}> = [];
	var nextSeq:Int = 1;
	var dropped:Int = 0;

	public function new() {}

	function get_describe():String {
		return "page window.hxDevBridge";
	}

	public function start(host:IDevBridgeHost):Bool {
		this.host = host;
		final api = {
			protocol: PROTOCOL,
			info: () -> host.describeInstance(),
			call: (request:Dynamic) -> Json.stringify(call(request)),
			poll: (sinceSeq:Dynamic) -> Json.stringify(poll(sinceSeq == null ? 0 : Std.int(sinceSeq))),
		};
		js.Syntax.code("window.hxDevBridge = {0}", api);
		return true;
	}

	public function stop():Void {
		if (host == null) return;
		js.Syntax.code("if (window.hxDevBridge) delete window.hxDevBridge");
		host = null;
	}

	public function tick():Void {}

	public function pushEvent(name:String, data:Dynamic):Void {
		if (events.length >= EVENT_BUFFER_SIZE) {
			events.shift();
			dropped++;
		}
		events.push({seq: nextSeq++, event: name, data: data});
	}

	/** A request as a JSON string (what `call` is documented to take) or as an object. */
	public function call(request:Dynamic):Dynamic {
		if (host == null)
			return {ok: false, error: "DevBridge stopped", code: "invalid_state"};
		if (Std.isOfType(request, String))
			return host.handleRequestJson(request).body;
		if (request == null || !Std.isOfType(request.method, String))
			return {ok: false, error: "Invalid request: expected {method, params}", code: "invalid_params"};
		return host.handleCall(request.method, request.params).body;
	}

	public function poll(sinceSeq:Int):Dynamic {
		final out = [for (e in events) if (e.seq > sinceSeq) e];
		final oldest = events.length > 0 ? events[0].seq : nextSeq;
		final missed = sinceSeq < oldest - 1 ? (oldest - 1 - sinceSeq) : 0;
		return {
			events: out,
			lastSeq: nextSeq - 1,
			dropped: dropped,
			missed: missed > dropped ? dropped : missed,
		};
	}
}
#end
