package bh.multianim.dev.transport;

#if (MULTIANIM_DEV && (sys || hxnodejs))
import hxd.net.Socket;
import haxe.Json;
import bh.multianim.dev.DevBridgeConfig;
import bh.multianim.dev.transport.IDevBridgeTransport;

/**
	The DevBridge's HTTP server: one JSON POST per call, `GET /sse` for pushed events. This is the
	socket half of what used to be all of `DevBridge`, moved here unchanged; a browser page cannot
	listen on a port, so on JS the other transports stand in for it.

	Security (`HX_DEV_TOKEN`, `HX_DEV_ORIGIN`): with a token set, every request must carry it, as
	`X-HX-Dev-Token: <token>`, `Authorization: Bearer <token>`, or `?token=<token>` (for `/sse`,
	which `EventSource` cannot give headers). The CORS origin is `HX_DEV_ORIGIN` when set, `*` when
	no token is set, and absent otherwise; with `HX_DEV_ORIGIN` set, a request whose `Origin`
	differs is refused. With neither set, requests and responses are byte-for-byte as before.
**/
class HttpServerTransport implements IDevBridgeTransport {
	public final port:Int;
	public final bindAddress:String;
	public var actualPort(default, null):Int = 0;
	public var describe(get, never):String;

	var host:Null<IDevBridgeHost>;
	var serverSocket:Null<Socket>;
	var token:Null<String>;
	var allowedOrigin:Null<String>;
	var corsOrigin:Null<String>;

	// ---- SSE clients ----
	var sseClients:Array<Socket> = [];

	// ---- Pending HTTP connections (still receiving headers/body) ----
	var pendingConnections:Array<HttpConnection> = [];

	public function new(port:Int, bindAddress:String) {
		this.port = port;
		this.bindAddress = bindAddress;
	}

	function get_describe():String {
		return 'http $bindAddress:$actualPort';
	}

	public function start(host:IDevBridgeHost):Bool {
		if (serverSocket != null) {
			trace('[DevBridge] Error, Already started on port $actualPort');
			return false;
		}
		this.host = host;
		token = host.getToken();
		final originSetting = DevBridgeConfig.get("HX_DEV_ORIGIN");
		allowedOrigin = originSetting != null && originSetting != "" ? originSetting : null;
		corsOrigin = allowedOrigin != null ? allowedOrigin : (token == null ? "*" : null);

		serverSocket = new Socket();

		var bound = false;
		var tryPort = port;
		for (_ in 0...10) {
			try {
				serverSocket.bind(bindAddress, tryPort, onClientConnected);
				actualPort = tryPort;
				bound = true;
				trace('[DevBridge] Listening on port $tryPort (bind $bindAddress)');
				break;
			} catch (e:Dynamic) {
				trace('[DevBridge] Port $tryPort busy, trying next...');
				tryPort++;
			}
		}

		if (!bound) {
			trace('[DevBridge] Failed to bind after 10 attempts (tried ports $port-${port + 9})');
			serverSocket = null;
			return false;
		}
		if (token != null)
			trace('[DevBridge] Token required on every request (HX_DEV_TOKEN)');

		writeReadyFile();
		return true;
	}

	function writeReadyFile():Void {
		#if sys
		var readyFilePath = DevBridgeConfig.get("HX_DEV_READY_FILE");
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
		#end
	}

	public function stop():Void {
		closeSseClients();
		if (serverSocket != null) {
			serverSocket.close();
			serverSocket = null;
			trace("[DevBridge] Stopped");
		}
	}

	// ---- SSE ----

	function handleSseConnect(clientSocket:Socket):Void {
		var header = 'HTTP/1.1 200 OK\r\n'
			+ 'Content-Type: text/event-stream\r\n'
			+ 'Cache-Control: no-cache\r\n'
			+ 'Connection: keep-alive\r\n'
			+ corsHeaderLine()
			+ '\r\n';
		var headerBytes = haxe.io.Bytes.ofString(header);
		clientSocket.out.writeBytes(headerBytes, 0, headerBytes.length);
		clientSocket.out.flush();
		sseClients.push(clientSocket);
		clientSocket.onError = (msg) -> {
			sseClients.remove(clientSocket);
			try clientSocket.close() catch (_:Dynamic) {};
		};
		trace('[DevBridge] SSE client connected (${sseClients.length} total)');
	}

	public function pushEvent(event:String, data:Dynamic):Void {
		if (sseClients.length == 0) return;
		try {
			var json = Json.stringify(data);
			var payload = 'event: $event\ndata: $json\n\n';
			var bytes = haxe.io.Bytes.ofString(payload);
			var dead:Array<Socket> = [];
			for (client in sseClients) {
				try {
					client.out.writeBytes(bytes, 0, bytes.length);
					client.out.flush();
				} catch (e:Dynamic) {
					dead.push(client);
				}
			}
			for (d in dead) {
				sseClients.remove(d);
				try d.close() catch (_:Dynamic) {};
			}
		} catch (e:Dynamic) {
			trace('[DevBridge] SSE broadcast failed ($event): $e');
		}
	}

	function closeSseClients():Void {
		for (client in sseClients) {
			try client.close() catch (_:Dynamic) {};
		}
		sseClients = [];
	}

	// ---- HTTP handling ----

	function onClientConnected(clientSocket:Socket):Void {
		var conn = new HttpConnection(clientSocket);
		pendingConnections.push(conn);
		clientSocket.onData = () -> {
			try {
				if (conn.processIncoming()) {
					pendingConnections.remove(conn);
					if (conn.headerOversized) {
						sendJsonResponse(clientSocket, 431, {ok: false, error: "Request header fields too large"});
						return;
					}
					if (conn.bodyOversized) {
						sendJsonResponse(clientSocket, 413, {ok: false, error: "Payload too large"});
						return;
					}
					var httpMethod = conn.getHttpMethod();
					if (httpMethod == "OPTIONS") {
						// A CORS preflight carries no credentials; the real request that follows does.
						sendResponse(clientSocket, 204, "");
						return;
					}
					if (!originAllowed(conn)) {
						sendJsonResponse(clientSocket, 403, {ok: false, error: "Origin not allowed (HX_DEV_ORIGIN)", code: "forbidden"});
						return;
					}
					if (!tokenAccepted(conn)) {
						sendJsonResponse(clientSocket, 401, {
							ok: false,
							error: "Unauthorized: this DevBridge requires its token (HX_DEV_TOKEN). Send it as X-HX-Dev-Token, Authorization: Bearer, or ?token=",
							code: "unauthorized"
						});
						return;
					}
					if (httpMethod == "GET" && conn.getPath() == "/sse") {
						handleSseConnect(clientSocket);
					} else if (httpMethod == "POST") {
						final reply = host.handleRequestJson(conn.getBody());
						sendJsonResponse(clientSocket, reply.status, reply.body);
					} else {
						sendJsonResponse(clientSocket, 405, {ok: false, error: "Method not allowed. Use POST."});
					}
				}
			} catch (e:Dynamic) {
				pendingConnections.remove(conn);
				sendJsonResponse(clientSocket, 400, {ok: false, error: 'Bad request: $e'});
			}
		};
		clientSocket.onError = (msg) -> {
			pendingConnections.remove(conn);
		};
	}

	function tokenAccepted(conn:HttpConnection):Bool {
		if (token == null) return true;
		var given = conn.getHeader("x-hx-dev-token");
		if (given == null) {
			final auth = conn.getHeader("authorization");
			if (auth != null && StringTools.startsWith(auth.toLowerCase(), "bearer "))
				given = StringTools.trim(auth.substr(7));
		}
		if (given == null)
			given = conn.getQueryParam("token");
		return given != null && tokensEqual(given, token);
	}

	function originAllowed(conn:HttpConnection):Bool {
		if (allowedOrigin == null) return true;
		final origin = conn.getHeader("origin");
		return origin == null || origin == allowedOrigin;
	}

	/** Compares without returning early on the first differing character. */
	public static function tokensEqual(a:String, b:String):Bool {
		if (a.length != b.length) return false;
		var diff = 0;
		for (i in 0...a.length)
			diff |= StringTools.fastCodeAt(a, i) ^ StringTools.fastCodeAt(b, i);
		return diff == 0;
	}

	/** Called from ScreenManager.update — closes pending connections that
	 *  exceeded the idle deadline so half-open clients can't park sockets. */
	public function tick():Void {
		if (pendingConnections.length == 0) return;
		var now = haxe.Timer.stamp();
		var i = pendingConnections.length;
		while (i-- > 0) {
			var conn = pendingConnections[i];
			if (conn.isExpired(now)) {
				pendingConnections.splice(i, 1);
				try {
					sendJsonResponse(conn.socket, 408, {ok: false, error: "Request timeout"});
				} catch (_:Dynamic) {
					try conn.socket.close() catch (_:Dynamic) {};
				}
			}
		}
	}

	function corsHeaderLine():String {
		return corsOrigin != null ? 'Access-Control-Allow-Origin: $corsOrigin\r\n' : '';
	}

	function sendJsonResponse(clientSocket:Socket, statusCode:Int, body:Dynamic):Void {
		sendResponse(clientSocket, statusCode, Json.stringify(body));
	}

	function sendResponse(clientSocket:Socket, statusCode:Int, body:String):Void {
		var statusText = switch statusCode {
			case 200: "OK";
			case 204: "No Content";
			case 400: "Bad Request";
			case 401: "Unauthorized";
			case 403: "Forbidden";
			case 405: "Method Not Allowed";
			case 408: "Request Timeout";
			case 413: "Payload Too Large";
			case 431: "Request Header Fields Too Large";
			case 500: "Internal Server Error";
			case 501: "Not Implemented";
			default: "Unknown";
		};

		var bodyBytes = haxe.io.Bytes.ofString(body);
		var header = 'HTTP/1.1 $statusCode $statusText\r\n'
			+ 'Content-Type: application/json\r\n'
			+ corsHeaderLine()
			+ 'Access-Control-Allow-Methods: POST, OPTIONS\r\n'
			+ (token == null ? 'Access-Control-Allow-Headers: Content-Type\r\n' : 'Access-Control-Allow-Headers: Content-Type, Authorization, X-HX-Dev-Token\r\n')
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
}

// ---- HTTP connection state ----

class HttpConnection {
	public static final MAX_HEADER_BYTES = 64 * 1024;
	public static final MAX_BODY_BYTES = 16 * 1024 * 1024;
	public static final IDLE_TIMEOUT_SEC = 30.0;

	public final socket:Socket;
	public final connectedAt:Float;
	public var lastActivityAt:Float;
	public var headerOversized(default, null):Bool = false;
	public var bodyOversized(default, null):Bool = false;

	var headerBytes:haxe.io.Bytes;
	var headerLength:Int = 0;
	var headerSearchFrom:Int = 0;
	var headersDone:Bool = false;
	var headerText:String = "";
	var contentLength:Int = 0;
	var bodyBuf:haxe.io.BytesBuffer;
	var bodyReceived:Int = 0;
	var httpMethod:String = "";
	var httpPath:String = "/";
	var httpQuery:String = "";

	public function new(socket:Socket) {
		this.socket = socket;
		this.headerBytes = haxe.io.Bytes.alloc(MAX_HEADER_BYTES);
		this.bodyBuf = new haxe.io.BytesBuffer();
		this.connectedAt = haxe.Timer.stamp();
		this.lastActivityAt = this.connectedAt;
	}

	public inline function isExpired(now:Float):Bool {
		return (now - lastActivityAt) > IDLE_TIMEOUT_SEC;
	}

	/** Returns true when the request is complete OR when an error flag
	 *  (`headerOversized` / `bodyOversized`) is set — caller must inspect
	 *  the flags and send the appropriate error response. */
	public function processIncoming():Bool {
		var input = socket.input;
		var avail = input.available;
		if (avail <= 0) return headersDone && bodyReceived >= contentLength;
		lastActivityAt = haxe.Timer.stamp();

		if (!headersDone) {
			var room = MAX_HEADER_BYTES - headerLength;
			var toRead = avail < room ? avail : room;
			if (toRead > 0) {
				headerLength += input.readBytes(headerBytes, headerLength, toRead);
			}

			// Search only the unscanned tail (back up needle.length-1 to catch a straddling boundary).
			// Headers are ASCII per RFC 7230, so byte offsets match string indices when decoded as UTF-8.
			var headers = headerBytes.getString(0, headerLength);
			var startSearch = headerSearchFrom - 3;
			if (startSearch < 0) startSearch = 0;
			var endIdx = headers.indexOf("\r\n\r\n", startSearch);
			if (endIdx >= 0) {
				headersDone = true;
				headerText = headers.substr(0, endIdx);
				httpMethod = parseHttpMethod(headers);
				httpPath = parseRequestPath(headers);
				httpQuery = parseRequestQuery(headers);
				contentLength = parseContentLength(headers);
				if (contentLength < 0) contentLength = 0;
				if (contentLength > MAX_BODY_BYTES) {
					bodyOversized = true;
					return true;
				}
				var bodyStartOffset = endIdx + 4;
				var bodyStartLen = headerLength - bodyStartOffset;
				if (bodyStartLen > 0) {
					bodyBuf.addBytes(headerBytes, bodyStartOffset, bodyStartLen);
					bodyReceived += bodyStartLen;
				}
			} else {
				headerSearchFrom = headerLength;
				if (headerLength >= MAX_HEADER_BYTES) {
					headerOversized = true;
					return true;
				}
				return false;
			}
		}

		if (headersDone) {
			var available = input.available;
			var remaining = contentLength - bodyReceived;
			var toRead = available < remaining ? available : remaining;
			if (toRead > 0) {
				var buf = haxe.io.Bytes.alloc(toRead);
				var read = input.readBytes(buf, 0, toRead);
				bodyBuf.addBytes(buf, 0, read);
				bodyReceived += read;
			}
		}
		return headersDone && bodyReceived >= contentLength;
	}

	public function getHttpMethod():String {
		return httpMethod;
	}

	public function getPath():String {
		return httpPath;
	}

	public function getBody():String {
		return bodyBuf.getBytes().toString();
	}

	/** A request header's value (name matched case-insensitively), or null. */
	public function getHeader(name:String):Null<String> {
		return findHeader(headerText, name);
	}

	/** A query-string parameter of the request path, URL-decoded, or null. */
	public function getQueryParam(key:String):Null<String> {
		return findQueryParam(httpQuery, key);
	}

	public static function findHeader(headers:String, name:String):Null<String> {
		final wanted = name.toLowerCase();
		final lines = headers.split("\r\n");
		// Line 0 is the request line.
		for (i in 1...lines.length) {
			final line = lines[i];
			final colon = line.indexOf(":");
			if (colon <= 0) continue;
			if (StringTools.trim(line.substr(0, colon)).toLowerCase() == wanted)
				return StringTools.trim(line.substr(colon + 1));
		}
		return null;
	}

	public static function findQueryParam(query:String, key:String):Null<String> {
		if (query == "") return null;
		for (pair in query.split("&")) {
			final eq = pair.indexOf("=");
			final k = eq >= 0 ? pair.substr(0, eq) : pair;
			if (StringTools.urlDecode(k) != key) continue;
			return eq >= 0 ? StringTools.urlDecode(StringTools.replace(pair.substr(eq + 1), "+", " ")) : "";
		}
		return null;
	}

	static function parseHttpMethod(headers:String):String {
		var spaceIdx = headers.indexOf(" ");
		if (spaceIdx < 0) return "GET";
		return headers.substr(0, spaceIdx);
	}

	static function parseRequestTarget(headers:String):String {
		var firstSpace = headers.indexOf(" ");
		if (firstSpace < 0) return "/";
		var secondSpace = headers.indexOf(" ", firstSpace + 1);
		if (secondSpace < 0) secondSpace = headers.indexOf("\r", firstSpace + 1);
		if (secondSpace < 0) return "/";
		return headers.substring(firstSpace + 1, secondSpace);
	}

	static function parseRequestPath(headers:String):String {
		var path = parseRequestTarget(headers);
		var queryIdx = path.indexOf("?");
		if (queryIdx >= 0) path = path.substr(0, queryIdx);
		return path;
	}

	static function parseRequestQuery(headers:String):String {
		final target = parseRequestTarget(headers);
		final queryIdx = target.indexOf("?");
		return queryIdx >= 0 ? target.substr(queryIdx + 1) : "";
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
