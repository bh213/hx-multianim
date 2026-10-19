package bh.multianim;

import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimBuilder.SlotKey;
import bh.multianim.MultiAnimBuilder.SlotHandle;

/** A programmable that is built and on hand, whatever built it: a `BuilderResult` from the
 *  runtime builder, or an instance of a class `ProgrammableCodeGen` generated for `@:manim`.
 *
 *  A tool holding one of these can ask what the programmable is made of without knowing which
 *  path built it: its `#name`d elements and where each is drawn, its slots, its dynamic refs,
 *  the value of every parameter. The DevBridge lists both kinds through this interface, and a
 *  studio that measures a screen's named elements against its wireframe reads them here.
 *
 *  Keys follow the builder's `names` map: `"name"` for a plain `#name`, `"name 3"` for
 *  `#name[$i]` at index 3, `"name 1 2"` for `#name[$x, $y]`. A name declared inside a `@switch`
 *  arm or a param-dependent `repeatable` is present while that arm or iteration is built.
 *
 *  Extends `UIInteractiveSource`, so the interactives, `setParameter`, `hasParameter` and the
 *  rebuild listeners come with it. */
@:nullSafety
interface LiveProgrammable extends bh.ui.UIInteractiveSource {
	/** The root object: `BuilderResult.object`, or the codegen instance itself. */
	function getRoot():h2d.Object;

	/** The programmable's name as declared in the `.manim` file. */
	function getProgrammableName():String;

	/** Every named-element key present now (see the class doc for the key forms). A plain name
	 *  given in several `@()` arms appears once. Order is not significant. */
	function getNamedKeys():Array<String>;

	/** The object of a `#name` that is drawn now — visible, under the root. A name given in several
	 *  `@()` arms has one object per arm; an arm that does not match is out of the scene graph (not
	 *  hidden), so only the matching one answers. `index` for `#name[$i]`, `index` and `indexY` for
	 *  `#name[$x, $y]`. Null when the name is unknown or none of its objects is drawn. */
	function getNamedDrawn(name:String, ?index:Null<Int>, ?indexY:Null<Int>):Null<h2d.Object>;

	/** Every slot present now, with its key and handle. */
	function getSlotEntries():Array<{key:SlotKey, handle:SlotHandle}>;

	/** Every dynamicRef key present now: an explicit `#name`, the target programmable's name for an
	 *  unnamed site, `"name idx"` for an indexed one. */
	function getDynamicRefKeys():Array<String>;

	/** The current value of every parameter, as a plain value: an enum as its value's name, a `bool`
	 *  as `1` or `0` (the builder's resolved form), numbers as `Int`/`Float`, a color as its
	 *  `0xAARRGGBB` `Int`, strings as `String`, a word list as `Array<String>`. A tile has no plain
	 *  form and is left out. A non-incremental `BuilderResult` keeps no values and answers an empty
	 *  map. */
	function getParameterValues():Map<String, Dynamic>;
}

/** Helpers shared by the implementations of `LiveProgrammable`. */
@:nullSafety
class LiveProgrammableTools {
	/** True when `obj` is `root` or under it, with every object on the way visible. */
	public static function isDrawnUnder(obj:h2d.Object, root:h2d.Object):Bool {
		var cur:Null<h2d.Object> = obj;
		while (cur != null) {
			if (!cur.visible)
				return false;
			if (cur == root)
				return true;
			cur = cur.parent;
		}
		return false;
	}

	/** The `names`-map key for a name with optional indices. */
	public static inline function namedKey(name:String, ?index:Null<Int>, ?indexY:Null<Int>):String {
		return if (indexY != null) '${name} ${index} ${indexY}' else if (index != null) '${name} ${index}' else name;
	}

	/** The plain-value form of a resolved parameter: the enum value's name, the number, the string,
	 *  the word list; null for a tile or an expression alias, which have none. */
	public static function resolvedToDynamic(p:bh.multianim.MultiAnimParser.ResolvedIndexParameters):Null<Dynamic> {
		return switch p {
			case Value(val): val;
			case ValueF(val): val;
			case StringValue(s): s;
			case Flag(f): f;
			case Index(_, name): name;
			case ArrayString(arr): arr;
			case ExpressionAlias(_): null;
			case TileSourceValue(_): null;
		};
	}
}
