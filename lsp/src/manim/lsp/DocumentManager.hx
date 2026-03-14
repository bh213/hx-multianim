package manim.lsp;

/**
 * Manages open document contents in memory.
 * Provides text retrieval for parsing and analysis.
 */
class DocumentManager {
	final documents:Map<String, DocumentState> = new Map();

	public function new() {}

	public function open(uri:String, text:String, version:Int):Void {
		documents.set(uri, {text: text, version: version});
	}

	public function change(uri:String, text:String, version:Int):Void {
		documents.set(uri, {text: text, version: version});
	}

	public function close(uri:String):Void {
		documents.remove(uri);
	}

	public function getText(uri:String):Null<String> {
		final doc = documents.get(uri);
		return doc != null ? doc.text : null;
	}

	public function getVersion(uri:String):Int {
		final doc = documents.get(uri);
		return doc != null ? doc.version : 0;
	}

	public function allUris():Iterator<String> {
		return documents.keys();
	}
}

typedef DocumentState = {
	var text:String;
	var version:Int;
}
