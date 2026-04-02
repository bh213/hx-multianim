package manim.lsp;

import haxe.Json;

/**
 * LSP stdio transport: reads/writes Content-Length framed JSON-RPC messages
 * over Node.js process.stdin/stdout.
 */
class LspTransport {
	var buffer:String = "";
	var onMessage:Dynamic->Void;

	// Node.js process reference
	static var nodeProcess:Dynamic = js.Syntax.code("(typeof process !== 'undefined' ? process : null)");

	public function new(onMessage:Dynamic->Void) {
		this.onMessage = onMessage;
	}

	public function start():Void {
		final stdin:Dynamic = nodeProcess.stdin;
		stdin.setEncoding("utf8");
		stdin.on("data", function(chunk:String) {
			onData(chunk);
		});
		stdin.on("end", function() {
			nodeProcess.exit(0);
		});
	}

	function onData(chunk:String):Void {
		buffer += chunk;
		while (true) {
			final headerEnd = buffer.indexOf("\r\n\r\n");
			if (headerEnd == -1) break;

			// Parse Content-Length from headers
			final headerBlock = buffer.substr(0, headerEnd);
			var contentLength = -1;
			for (line in headerBlock.split("\r\n")) {
				if (StringTools.startsWith(line, "Content-Length:")) {
					final val = StringTools.trim(line.substr("Content-Length:".length));
					contentLength = Std.parseInt(val);
				}
			}

			if (contentLength < 0) {
				// Malformed header — skip it
				buffer = buffer.substr(headerEnd + 4);
				continue;
			}

			final bodyStart = headerEnd + 4;
			// Use Buffer.byteLength for correct byte count
			final bufferObj:Dynamic = js.Syntax.code("Buffer.from({0}, 'utf8')", buffer.substr(bodyStart));
			final availableBytes:Int = bufferObj.length;

			if (availableBytes < contentLength) break; // Wait for more data

			// Extract exactly contentLength bytes
			final bodyBytes:Dynamic = js.Syntax.code("Buffer.from({0}, 'utf8').slice(0, {1}).toString('utf8')", buffer.substr(bodyStart), contentLength);
			final body:String = bodyBytes;

			// Advance buffer past consumed bytes
			final consumedChars:Int = js.Syntax.code("Buffer.from({0}, 'utf8').slice(0, {1}).toString('utf8').length", buffer.substr(bodyStart), contentLength);
			buffer = buffer.substr(bodyStart + consumedChars);

			try {
				final msg = Json.parse(body);
				onMessage(msg);
			} catch (e:Dynamic) {
				logError('Failed to parse JSON-RPC message: $e');
			}
		}
	}

	public function send(msg:Dynamic):Void {
		final json = Json.stringify(msg);
		final byteLength:Int = js.Syntax.code("Buffer.byteLength({0}, 'utf8')", json);
		final header = 'Content-Length: $byteLength\r\n\r\n';
		final stdout:Dynamic = nodeProcess.stdout;
		stdout.write(header);
		stdout.write(json);
	}

	public function sendResponse(id:Dynamic, result:Dynamic):Void {
		send({jsonrpc: "2.0", id: id, result: result});
	}

	public function sendError(id:Dynamic, code:Int, message:String):Void {
		send({jsonrpc: "2.0", id: id, error: {code: code, message: message}});
	}

	public function sendNotification(method:String, params:Dynamic):Void {
		send({jsonrpc: "2.0", method: method, params: params});
	}

	public static function logError(msg:String):Void {
		final stderr:Dynamic = nodeProcess.stderr;
		stderr.write('[manim-lsp] $msg\n');
	}

	public static function log(msg:String):Void {
		final stderr:Dynamic = nodeProcess.stderr;
		stderr.write('[manim-lsp] $msg\n');
	}
}
