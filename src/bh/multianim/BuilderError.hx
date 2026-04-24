package bh.multianim;

import bh.multianim.MultiAnimParser.Node;

/**
	Runtime error raised by `MultiAnimBuilder` (and related builder code) while
	resolving a `.manim` tree. Carries the `Node` currently being processed so
	tools like DevBridge / LSP can point at the failing source location.

	The `code` field is an optional tag for programmatic filtering (e.g. the
	`resolveAsString` RVParenthesis site catches `code == "not_a_number"` to
	fall back to string conversion). Leave null for the common "just fail
	with a message" case.

	Use via `MultiAnimBuilder.builderError(msg, ?code)` — that helper injects
	the current node automatically.
**/
@:nullSafety
class BuilderError extends haxe.Exception {
	public final node:Null<Node>;
	public final code:Null<String>;

	public function new(message:String, ?node:Null<Node>, ?code:String) {
		super(message);
		this.node = node;
		this.code = code;
	}

	/** Static factory for sites without access to a `MultiAnimBuilder.builderError()`
	 *  member helper — use from helper classes (`BuilderResult`, `SlotHandle`,
	 *  `BuilderResolvedSettings`, etc.) that have no `currentNode` to attach. */
	public static inline function of(message:String, ?code:String):BuilderError
		return new BuilderError(message, null, code);

	override public function toString():String {
		#if MULTIANIM_DEV
		return node != null ? '$message at ${node.parserPos}' : message;
		#else
		return message;
		#end
	}

	/**
		Parses `node.parserPos` into structured `{file, line, col}` for tools
		(DevBridge, LSP, ScreenManager error reports). Returns null in non-DEV
		builds (Node has no parserPos field), when the node is null, or when
		the format is unrecognized.

		Format produced by the parser is `"file:line:col"` or (older sites)
		`"file:line"`. The "file" portion may itself contain colons on Windows
		(`C:/foo/bar.manim:42:8`), so we split from the right and only treat
		the trailing 1–2 segments as line/col.
	**/
	public function parsedPos():Null<{file:String, line:Int, col:Int}> {
		#if MULTIANIM_DEV
		if (node == null) return null;
		final raw = node.parserPos;
		if (raw == null || raw.length == 0) return null;

		final parts = raw.split(":");
		if (parts.length < 2) return null;

		final last = Std.parseInt(parts[parts.length - 1]);
		final secondLast = Std.parseInt(parts[parts.length - 2]);

		if (last != null && secondLast != null) {
			final file = parts.slice(0, parts.length - 2).join(":");
			return {file: file, line: secondLast, col: last};
		}
		if (last != null) {
			final file = parts.slice(0, parts.length - 1).join(":");
			return {file: file, line: last, col: 0};
		}
		return null;
		#else
		return null;
		#end
	}
}
