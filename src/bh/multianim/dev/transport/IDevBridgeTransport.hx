package bh.multianim.dev.transport;

#if MULTIANIM_DEV
/**
	How a DevBridge is reached. The DevBridge does the work (every op, the game's own ops, the event
	buffers); a transport carries requests in and events out:

	- `HttpServerTransport` (HashLink): the HTTP server and `/sse` stream, as before the split.
	- `PageTransport` (browser): `window.hxDevBridge`, called from the page (Playwright).
	- `WebSocketTransport` (browser): dials out to a relay (the MCP server) and answers its calls.
**/
interface IDevBridgeTransport {
	/** Returns false when this transport could not start (no free port, nothing to dial). */
	function start(host:IDevBridgeHost):Bool;

	function stop():Void;

	/** Called every frame from `ScreenManager.update`; a no-op where nothing needs pumping. */
	function tick():Void;

	/** An unsolicited event (`trace`, `error`, `screen_change`, `reload`, `parameter_change`,
		`debugger`, `game_event`, `custom`), the same names the `/sse` stream uses. */
	function pushEvent(name:String, data:Dynamic):Void;

	/** For the startup trace, e.g. `http 0.0.0.0:9001`. */
	var describe(get, never):String;
}

/** What a transport asks of the DevBridge. `DevBridge` implements it. */
interface IDevBridgeHost {
	/** A request body `{"method": ..., "params": ...}`: parse, dispatch, reply. */
	function handleRequestJson(json:String):DevBridgeReply;

	/** An already-parsed call. */
	function handleCall(method:String, params:Dynamic):DevBridgeReply;

	/** `HX_DEV_TOKEN`, or null when none is set. */
	function getToken():Null<String>;

	/** Who this game is, for a relay's `hello` and the page API's `info()`. */
	function describeInstance():Dynamic;
}

/**
	A reply, the same whichever transport carried the call: `body` is `{ok: true, result}` or
	`{ok: false, error, code}`, and `status` is the HTTP status the HTTP transport answers with.
**/
typedef DevBridgeReply = {
	var status:Int;
	var body:Dynamic;
}
#end
