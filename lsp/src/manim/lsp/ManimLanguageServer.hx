package manim.lsp;

import haxe.Json;
import manim.lsp.LspTypes;

/**
 * .manim Language Server — LSP over stdio.
 *
 * Written in Haxe, compiled to JS, runs as Node.js process.
 * Reuses MacroManimParser directly for parsing (single source of truth).
 *
 * Supports: diagnostics, completions, hover, document symbols, go-to-definition.
 */
class ManimLanguageServer {
	var transport:LspTransport;
	var documents:DocumentManager;
	var initialized:Bool = false;

	public function new() {
		documents = new DocumentManager();
		transport = new LspTransport(onMessage);
	}

	public function start():Void {
		LspTransport.log("Starting .manim language server");
		transport.start();
	}

	function onMessage(msg:Dynamic):Void {
		final method:Null<String> = msg.method;
		final id:Dynamic = msg.id;

		if (method == null && id != null) {
			// Response to a request we sent — ignore
			return;
		}

		switch (method) {
			// ---- Lifecycle ----
			case "initialize":
				handleInitialize(id, msg.params);
			case "initialized":
				initialized = true;
				LspTransport.log("Client initialized");
			case "shutdown":
				transport.sendResponse(id, null);
			case "exit":
				js.Syntax.code("process.exit(0)");

			// ---- Document sync ----
			case "textDocument/didOpen":
				handleDidOpen(msg.params);
			case "textDocument/didChange":
				handleDidChange(msg.params);
			case "textDocument/didClose":
				handleDidClose(msg.params);
			case "textDocument/didSave":
				// Re-validate on save
				final uri:String = msg.params.textDocument.uri;
				validateDocument(uri);

			// ---- Language features ----
			case "textDocument/completion":
				handleCompletion(id, msg.params);
			case "textDocument/hover":
				handleHover(id, msg.params);
			case "textDocument/documentSymbol":
				handleDocumentSymbol(id, msg.params);
			case "textDocument/definition":
				handleDefinition(id, msg.params);

			default:
				if (id != null) {
					// Unknown request — respond with method not found
					transport.sendError(id, -32601, 'Method not found: $method');
				}
		}
	}

	// ---- Lifecycle handlers ----

	function handleInitialize(id:Dynamic, params:Dynamic):Void {
		transport.sendResponse(id, {
			capabilities: {
				textDocumentSync: {
					openClose: true,
					change: 1, // Full sync
					save: {includeText: false}
				},
				completionProvider: {
					triggerCharacters: ["$", "#", "@", ":", "("],
					resolveProvider: false
				},
				hoverProvider: true,
				documentSymbolProvider: true,
				definitionProvider: true
			},
			serverInfo: {
				name: "manim-language-server",
				version: "0.1.0"
			}
		});
	}

	// ---- Document sync handlers ----

	function handleDidOpen(params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final text:String = params.textDocument.text;
		final version:Int = params.textDocument.version;
		documents.open(uri, text, version);
		validateDocument(uri);
	}

	function handleDidChange(params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final version:Int = params.textDocument.version;
		// Full sync — take the last content change
		final changes:Array<Dynamic> = params.contentChanges;
		if (changes.length > 0) {
			final text:String = changes[changes.length - 1].text;
			documents.change(uri, text, version);
			validateDocument(uri);
		}
	}

	function handleDidClose(params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		documents.close(uri);
		// Clear diagnostics
		transport.sendNotification("textDocument/publishDiagnostics", {uri: uri, diagnostics: []});
	}

	function validateDocument(uri:String):Void {
		final text = documents.getText(uri);
		if (text == null) return;

		final diagnostics = isAnimFile(uri) ? AnimAnalyzer.getDiagnostics(text, uri) : ManimAnalyzer.getDiagnostics(text, uri);
		transport.sendNotification("textDocument/publishDiagnostics", {
			uri: uri,
			diagnostics: diagnostics
		});
	}

	static function isAnimFile(uri:String):Bool {
		return StringTools.endsWith(uri, ".anim");
	}

	// ---- Feature handlers ----

	function handleCompletion(id:Dynamic, params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final text = documents.getText(uri);
		if (text == null) {
			transport.sendResponse(id, []);
			return;
		}

		final line:Int = params.position.line;
		final character:Int = params.position.character;
		final items = isAnimFile(uri) ? AnimAnalyzer.getCompletions(text, line, character) : ManimAnalyzer.getCompletions(text, line, character);
		transport.sendResponse(id, items);
	}

	function handleHover(id:Dynamic, params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final text = documents.getText(uri);
		if (text == null) {
			transport.sendResponse(id, null);
			return;
		}

		final line:Int = params.position.line;
		final character:Int = params.position.character;
		final hover = isAnimFile(uri) ? AnimAnalyzer.getHover(text, uri, line, character) : ManimAnalyzer.getHover(text, uri, line, character);
		transport.sendResponse(id, hover);
	}

	function handleDocumentSymbol(id:Dynamic, params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final text = documents.getText(uri);
		if (text == null) {
			transport.sendResponse(id, []);
			return;
		}

		final symbols = isAnimFile(uri) ? AnimAnalyzer.getSymbols(text, uri) : ManimAnalyzer.getSymbols(text, uri);
		transport.sendResponse(id, symbols);
	}

	function handleDefinition(id:Dynamic, params:Dynamic):Void {
		final uri:String = params.textDocument.uri;
		final text = documents.getText(uri);
		if (text == null) {
			transport.sendResponse(id, null);
			return;
		}

		final line:Int = params.position.line;
		final character:Int = params.position.character;
		// .anim files don't support go-to-definition yet
		if (isAnimFile(uri)) {
			transport.sendResponse(id, null);
			return;
		}
		final location = ManimAnalyzer.getDefinition(text, uri, line, character);
		transport.sendResponse(id, location);
	}

	// ---- Entry point ----

	public static function main():Void {
		new ManimLanguageServer().start();
	}
}
