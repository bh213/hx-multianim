package manim.lsp.test;

import manim.lsp.ManimLanguageServer;
import manim.lsp.LspTransport;

/**
 * Transport double that records outgoing messages instead of writing to
 * process.stdout. `send()` is the single funnel for sendResponse /
 * sendError / sendNotification, so overriding it captures everything.
 */
class RecordingTransport extends LspTransport {
	public var sent:Array<Dynamic> = [];

	public function new() {
		super((_) -> {});
	}

	override public function send(msg:Dynamic):Void {
		sent.push(msg);
	}
}

/**
 * JSON-RPC contract tests for the language server dispatch:
 * every request (message with an id) must produce exactly one response —
 * a result or an error — even when a handler or provider throws.
 * A request that never gets a response leaves the client promise hanging
 * forever (VS Code shows a perpetually "loading" completion/hover).
 */
@:access(manim.lsp.ManimLanguageServer)
class ManimLanguageServerTest {
	public static function run():Void {
		LspTestRunner.suite("ManimLanguageServer");

		testWellFormedCompletionGetsResponse();
		testThrowingHandlerStillSendsResponse();
	}

	static function makeServer():{server:ManimLanguageServer, transport:RecordingTransport} {
		final server = new ManimLanguageServer();
		final transport = new RecordingTransport();
		server.transport = transport;
		return {server: server, transport: transport};
	}

	static function openDoc(server:ManimLanguageServer, uri:String, text:String):Void {
		server.onMessage({
			method: "textDocument/didOpen",
			params: {textDocument: {uri: uri, text: text, version: 1}}
		});
	}

	static function findResponse(transport:RecordingTransport, id:Int):Null<Dynamic> {
		for (m in transport.sent) {
			if (m.id == id && (m.result != null || m.error != null))
				return m;
		}
		return null;
	}

	static function testWellFormedCompletionGetsResponse():Void {
		final s = makeServer();
		openDoc(s.server, "file:///t.manim", "version: 1.0\n");
		s.server.onMessage({
			id: 1,
			method: "textDocument/completion",
			params: {textDocument: {uri: "file:///t.manim"}, position: {line: 1, character: 0}}
		});
		LspTestRunner.assert(findResponse(s.transport, 1) != null,
			"well-formed completion request gets a response");
	}

	static function testThrowingHandlerStillSendsResponse():Void {
		final s = makeServer();
		openDoc(s.server, "file:///t.manim", "version: 1.0\n");

		// Malformed request: params.position is missing, so the handler throws
		// (reads params.position.line). The dispatch must catch it and answer
		// with a JSON-RPC error — silence hangs the client promise forever.
		var escaped = false;
		try {
			s.server.onMessage({
				id: 42,
				method: "textDocument/completion",
				params: {textDocument: {uri: "file:///t.manim"}}
			});
		} catch (e:Dynamic) {
			// In production this escape is swallowed by the transport's JSON
			// catch (mislabeled as a parse failure) — the client still gets
			// nothing. Either way the response below must exist.
			escaped = true;
		}
		final response = findResponse(s.transport, 42);
		LspTestRunner.assert(response != null,
			"a request whose handler throws must still get a response (JSON-RPC error), got "
			+ (escaped ? "an uncaught exception" : "silence"));
		if (response != null)
			LspTestRunner.assert(response.error != null, "the response should be a JSON-RPC error, not a result");
	}
}
