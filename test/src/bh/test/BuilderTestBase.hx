package bh.test;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser;

enum BuildMode {
	Builder;
	Incremental;
}

/**
 * Base class for non-visual builder tests.
 * Provides static helpers for parsing/building .manim content and inspecting h2d object trees.
 * Does NOT require Scene, App, or any rendering infrastructure.
 *
 * Build modes:
 *   - Builder: standard runtime build (default)
 *   - Incremental: incremental mode (supports setParameter after build)
 *   - Macro: not supported for inline strings (requires .manim file + compile-time @:manim annotation)
 */
class BuilderTestBase extends utest.Test {
	// ===== Parse + Build from inline string =====

	/**
	 * Parse and build a programmable from inline .manim source.
	 * Automatically prepends version header.
	 */
	public static function buildFromSource(manimSource:String, programmableName:String, ?params:Map<String, Dynamic>,
			?mode:BuildMode):BuilderResult {
		var builder = builderFromSource(manimSource);
		if (params == null) params = new Map();
		var incremental = mode == Incremental;
		return builder.buildWithParameters(programmableName, params, null, null, incremental);
	}

	/**
	 * Parse inline .manim source and return the builder (for getData, getPaths, getCurves, etc.).
	 */
	public static function builderFromSource(manimSource:String):MultiAnimBuilder {
		var source = 'version: 0.5\n$manimSource';
		var input = byte.ByteData.ofString(source);
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		return MultiAnimBuilder.load(input, loader, "test-input");
	}

	// ===== Parse + Build from file =====

	/**
	 * Load and build from a .manim file path.
	 */
	public static function buildFromFile(filePath:String, programmableName:String, ?params:Map<String, Dynamic>,
			?mode:BuildMode):BuilderResult {
		var builder = builderFromFile(filePath);
		if (params == null) params = new Map();
		var incremental = mode == Incremental;
		return builder.buildWithParameters(programmableName, params, null, null, incremental);
	}

	/**
	 * Load builder from file (for getData, getPaths, getCurves, etc.).
	 */
	public static function builderFromFile(filePath:String):MultiAnimBuilder {
		var fileContent = byte.ByteData.ofString(sys.io.File.getContent(filePath));
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		return MultiAnimBuilder.load(fileContent, loader, filePath);
	}

	// ===== Data block helpers =====

	/**
	 * Parse inline .manim and get data block by name.
	 */
	public static function getDataFromSource(manimSource:String, dataName:String):Dynamic {
		var builder = builderFromSource(manimSource);
		return builder.getData(dataName);
	}

	// ===== Parse-only helpers =====

	/**
	 * Parse a .manim string and expect it to throw.
	 * Returns the error message string, or null if no error was thrown.
	 */
	public static function parseExpectingError(manimSource:String):String {
		try {
			var source = 'version: 0.5\n$manimSource';
			var input = byte.ByteData.ofString(source);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			MultiAnimParser.parseFile(input, "test-input", loader);
			return null;
		} catch (e:InvalidSyntax) {
			return e.toString();
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	/**
	 * Parse a .manim string and expect success (no error).
	 */
	public static function parseExpectingSuccess(manimSource:String):Bool {
		try {
			var source = 'version: 0.5\n$manimSource';
			var input = byte.ByteData.ofString(source);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			MultiAnimParser.parseFile(input, "test-input", loader);
			return true;
		} catch (e:Dynamic) {
			trace('Unexpected parse error: $e');
			return false;
		}
	}

	// ===== Scene-graph inspection helpers =====

	public static function countVisibleChildren(obj:h2d.Object):Int {
		var count = 0;
		for (i in 0...obj.numChildren) {
			if (obj.getChildAt(i).visible)
				count++;
		}
		return count;
	}

	public static function findTextChild(obj:h2d.Object):Null<h2d.Text> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Text)) {
				final t:h2d.Text = cast child;
				if (t.visible)
					return t;
			}
		}
		return null;
	}

	public static function findAllTextDescendants(obj:h2d.Object):Array<h2d.Text> {
		var result:Array<h2d.Text> = [];
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Text))
				result.push(cast child);
			for (t in findAllTextDescendants(child))
				result.push(t);
		}
		return result;
	}

	public static function findVisibleBitmapDescendants(obj:h2d.Object):Array<h2d.Bitmap> {
		var result:Array<h2d.Bitmap> = [];
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (child.visible) {
				if (Std.isOfType(child, h2d.Bitmap))
					result.push(cast child);
				for (b in findVisibleBitmapDescendants(child))
					result.push(b);
			}
		}
		return result;
	}

	public static function countAllDescendants(obj:h2d.Object):Int {
		var count = obj.numChildren;
		for (i in 0...obj.numChildren) {
			count += countAllDescendants(obj.getChildAt(i));
		}
		return count;
	}

	public static function countVisibleDescendants(obj:h2d.Object):Int {
		var count = 0;
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (child.visible) {
				count++;
				count += countVisibleDescendants(child);
			}
		}
		return count;
	}
}
