package bh.multianim;

import bh.multianim.CoordinateSystems;
import bh.multianim.MultiAnimParser;
import bh.stateanim.AnimParser;

/**
	What a `.manim` file needs of its host, from the parse alone: the outside names it reaches for.
	A tool that copies a file (a take from an art library) copies exactly these. Nothing is loaded:
	`ManimNeedsTools.needsOf(MacroManimParser.parseFile(text, name, null))` runs with no app, no
	window and no resource loader, on HashLink and on JS alike.

	A name written through a `$reference` is listed by every value it can have: an enum, bool or range
	parameter's values, a `@final`'s value, and for a parameter that can be given any value (a string,
	a number) its default and what this file's `staticRef`s and `dynamicRef`s pass it, with
	`fromParameters` set.

	- `sheets`: an atlas by name, with the cells named in it (`sheet("ui", "button")`, a nine-patch,
	  a text image, a cursor, a tileset's atlas with its terrain, side and layer cells, a stateanim
	  construct). `null` cells is the whole sheet: a cell that is an expression over a parameter that
	  can be given any value or over a loop variable, a `tiles($t, "sheet")` iterator, an autotile
	  `sheet:` + `prefix:`, an inline atlas drawn from a sheet. A sheet the file defines itself
	  (`#name atlas2`) is not a need.
	- `tiles`: image files reached for by name: `file("x.png")`, an autotile's or an inline atlas's
	  `file:`, a palette image.
	- `fonts`: `font("name")` of `text()`/`richText()`, their styles and `autoFit` fonts, a generated
	  tile's font, `$ctx.font("name")` where a value is written, a `font` setting (`font => "…"`,
	  `item.font => "…"`: what a widget is given).
	- `anims`: `.anim` files: `stateanim("file.anim")`, a particle group's `animFile`, a
	  `stateanim($b, "file.anim", …)` iterator, `extraPoint("file.anim", …)`.
	- `imports`: alias to path of every `import "file" as "alias"`, kept with or without a loader.
	- `filters`: custom filters by name (`filter: perlinNoise(…)`), registered in code.
	- `cursors`: cursors an interactive names (`cursor => "sword"`, `cursor.hover`, `cursor.disabled`)
	  that are neither `CursorManager`'s own (`pointer`, `move`, …) nor in the file's `cursor` blocks,
	  in lower case as `CursorManager` keeps them.
	- `fromParameters`: a name could not be listed whole: it is an expression over a parameter that
	  can be given values other than those listed, over a loop variable, or worked out in a way the
	  parse does not follow. A sheet whose own name cannot be known is not listed.
	- `sounds`: full names `bank.sound` the file plays: a widget's `settings { sound.<key> => "…" }`,
	  an interactive's `sound.<key> => "…"` metadata, a screen's `settings { ambience => "…" }` (not `none`).
	- `music`: full names `bank.track` a screen's programmable names with `settings { music => "…" }`.
	- `soundFiles`: the files the file's own `#name sounds { }` and `#name music { }` blocks name
	  (`file:`, `files:`, a layer's files, a track's file). A `#name mix { }` block names nothing.
	- `uiSounds`: the keys of the `#ui` sounds bank the file's widgets and interactives play by default,
	  having no `sound.<key>` of their own. The parse does not know which widget the host makes of a
	  programmable, so it goes by the parameters each widget passes: an `interactive()` plays `click`
	  (not with `events:` that leave clicks out); a programmable with `status` and `buttonText` (a
	  button) `hover` and `click`; with `status` and `checked` (a checkbox, or a tab or radio button,
	  whose tabs and radio group send a change) `toggle` and `change`; with `status` and `panel` (a
	  dropdown) `open`, `close` and `change`; with `status`, `value` and `size` (a slider), with
	  `scrollPosition`, `scrollableHeight` and `panelHeight` (a scrollbar), or with `status`, `title`
	  and `selected` (a list's item) `change`; any other (a text input, a card, a grid cell) none. The
	  runtime plays what the widget sends (`UIScreenBase.playWidgetSound`), so this lists at most the
	  keys a widget of it could play.
**/
@:nullSafety
typedef ManimNeeds = {
	sheets:Map<String, Null<Array<String>>>,
	tiles:Array<String>,
	fonts:Array<String>,
	anims:Array<String>,
	imports:Map<String, String>,
	filters:Array<String>,
	cursors:Array<String>,
	fromParameters:Bool,
	sounds:Array<String>,
	music:Array<String>,
	soundFiles:Array<String>,
	uiSounds:Array<String>,
};

/**
	What an `.anim` file needs of its host: its `sheet:` with every frame name its playlists and layers
	write (`${state}` expanded over the file's `states:` values; an indexed name once), the images
	its `file:` lines name, and the full names `bank.sound` its `sounds { }` block plays.
	From `ManimNeedsTools.animNeedsOf(AnimParser.parseString(text, name, null).loaded())`.
**/
@:nullSafety
typedef AnimNeeds = {
	sheets:Map<String, Null<Array<String>>>,
	files:Array<String>,
	sounds:Array<String>,
};

/** What a `$name` stands for where the walk is: every value it can have (null: not known), `open` when it can be given others. */
@:nullSafety
private typedef Binding = {values:Null<Array<String>>, open:Bool};

@:nullSafety
class ManimNeedsTools {
	/** The cursors `CursorManager` registers itself: no file needs them. */
	public static final BUILT_IN_CURSORS = [
		"default", "pointer", "button", "move", "text", "hide", "none", "resize-ns", "resize-we", "resize-nwse", "resize-nesw"
	];

	/** `UIInteractiveWrapper.EVENT_CLICK`: the bit of an interactive's `events:` that says it clicks. */
	static inline final EVENT_CLICK = 2;

	/** The most values a name is listed by; past it the name is not known (several parameters multiplied). */
	static inline final MAX_VALUES = 64;

	static final UNKNOWN:Binding = {values: null, open: true};

	/** Every outside name `result` reaches for; see `ManimNeeds`. */
	public static function needsOf(result:MultiAnimResult):ManimNeeds {
		final n = new ManimNeedsTools();
		n.rootNodes = result.nodes;
		for (name => node in result.nodes) {
			switch node.type {
				case ATLAS2(_):
					n.ownSheets.push(name);
				case CURSORS(cursors):
					for (c in cursors)
						n.ownCursors.push(c.name.toLowerCase());
				default:
			}
		}
		// a `staticRef` passes values to a programmable the walk may have been through already:
		// walk again until nothing new is passed (what is listed only grows)
		var passes = 0;
		do {
			n.passedGrew = false;
			for (name => node in result.nodes) {
				n.rootName = name;
				n.visit(node);
			}
		} while (n.passedGrew && ++passes < 8);
		for (ref in result.customFilterRefs)
			n.add(n.filters, ref.name);
		for (own in n.ownSheets)
			n.sheets.remove(own);
		final cursors = [
			for (c in n.cursors)
				if (BUILT_IN_CURSORS.indexOf(c) < 0 && n.ownCursors.indexOf(c) < 0) c
		];
		cursors.sort(Reflect.compare);
		for (_ => cells in n.sheets)
			if (cells != null)
				cells.sort(Reflect.compare);
		final imports:Map<String, String> = [];
		if (result.importPaths != null)
			for (alias => path in result.importPaths)
				imports.set(alias, path);
		n.tiles.sort(Reflect.compare);
		n.fonts.sort(Reflect.compare);
		n.anims.sort(Reflect.compare);
		n.filters.sort(Reflect.compare);
		n.sounds.sort(Reflect.compare);
		n.music.sort(Reflect.compare);
		n.soundFiles.sort(Reflect.compare);
		n.uiSounds.sort(Reflect.compare);
		return {
			sheets: n.sheets,
			tiles: n.tiles,
			fonts: n.fonts,
			anims: n.anims,
			imports: imports,
			filters: n.filters,
			cursors: cursors,
			fromParameters: n.fromParameters,
			sounds: n.sounds,
			music: n.music,
			soundFiles: n.soundFiles,
			uiSounds: n.uiSounds,
		};
	}

	/** What an `.anim` file needs; see `AnimNeeds`. */
	public static function animNeedsOf(loaded:LoadedAnimation):AnimNeeds {
		final sheets:Map<String, Null<Array<String>>> = [];
		final files:Array<String> = [];
		final sounds:Array<String> = [];
		final cells:Array<String> = [];
		function frames(anims:Array<AnimPlaylistFrames>) {
			for (a in anims)
				switch a {
					case SheetFrameAnim(name, _, _) | SheetFrameAnimWithIndex(name, _, _, _, _):
						for (expanded in expandStates(name, loaded.states))
							if (cells.indexOf(expanded) < 0)
								cells.push(expanded);
					case FileSingleFrame(filename, _, _):
						if (files.indexOf(filename) < 0)
							files.push(filename);
					default:
				}
		}
		for (anim in loaded.animations) {
			for (p in anim.playlist)
				frames(p.anims);
			if (anim.layers != null)
				for (l in anim.layers)
					frames(l.anims);
		}
		cells.sort(Reflect.compare);
		files.sort(Reflect.compare);
		if (loaded.sheet != null && (cells.length > 0 || loaded.animations.length == 0))
			sheets.set(loaded.sheet, cells);
		for (_ => full in loaded.sounds)
			if (sounds.indexOf(full) < 0)
				sounds.push(full);
		for (_ => full in loaded.holds)
			if (sounds.indexOf(full) < 0)
				sounds.push(full);
		sounds.sort(Reflect.compare);
		return {sheets: sheets, files: files, sounds: sounds};
	}

	/** `"walk_${dir}"` over `dir: l, r` is `walk_l`, `walk_r`; a name with no `${}` is itself. */
	public static function expandStates(name:String, states:Map<String, Array<String>>):Array<String> {
		var out = [name];
		for (key => values in states) {
			final pattern = "${" + key + "}";
			final next = [];
			for (s in out) {
				if (s.indexOf(pattern) < 0) {
					next.push(s);
					continue;
				}
				for (v in values)
					next.push(StringTools.replace(s, pattern, v));
			}
			out = next;
		}
		return out;
	}

	// ---- the walk ----

	final sheets:Map<String, Null<Array<String>>> = [];
	final tiles:Array<String> = [];
	final fonts:Array<String> = [];
	final anims:Array<String> = [];
	final filters:Array<String> = [];
	final sounds:Array<String> = [];
	final music:Array<String> = [];
	final soundFiles:Array<String> = [];
	final uiSounds:Array<String> = [];
	final cursors:Array<String> = [];
	final ownSheets:Array<String> = [];
	final ownCursors:Array<String> = [];
	var fromParameters = false;

	/** What each `$name` stands for, a frame a body (a programmable's or slot's parameters, a loop's variable, the `@final`s); innermost last. */
	final scopes:Array<Map<String, Binding>> = [];
	/** Values this file's `staticRef`s and `dynamicRef`s pass a programmable: programmable, parameter, values. */
	final passed:Map<String, Map<String, Array<String>>> = [];
	var passedGrew = false;
	/** The root node being walked, by name: a programmable's, to find what is passed to it. */
	var rootName:Null<String> = null;
	/** Set by `valuesOf` when a value it read can be given others than those it returns. */
	var openSeen = false;

	function new() {}

	function add(list:Array<String>, s:String) {
		if (list.indexOf(s) < 0)
			list.push(s);
	}

	/** The sheet, with `cell` among its cells; `cell` null is the whole sheet. */
	function addSheet(sheet:String, cell:Null<String>) {
		if (cell == null) {
			sheets.set(sheet, null);
			return;
		}
		if (!sheets.exists(sheet)) {
			sheets.set(sheet, [cell]);
			return;
		}
		final cells = sheets.get(sheet);
		if (cells != null && cells.indexOf(cell) < 0)
			cells.push(cell);
	}

	// ---- what a value can be ----

	function binding(name:String):Null<Binding> {
		var i = scopes.length;
		while (i-- > 0) {
			final b = scopes[i].get(name);
			if (b != null)
				return b;
		}
		return null;
	}

	/**
		Every string `v` can be where the walk is, as the builder writes it (`+` joins, `${…}` is worked
		out as a number first); null when that is not known: a loop variable, a call, more than
		`MAX_VALUES`. Sets `openSeen` when a parameter it reads can be given other values.
	**/
	function valuesOf(v:Null<ReferenceableValue>):Null<Array<String>> {
		if (v == null)
			return null;
		return switch v {
			case RVString(s): [s];
			case RVInteger(i): [Std.string(i)];
			case RVReference(name):
				final b = binding(name);
				if (b == null)
					return null;
				if (b.open)
					openSeen = true;
				b.values;
			case RVParenthesis(e):
				final numbers = numbersOf(e);
				numbers != null ? [for (n in numbers) Std.string(n)] : valuesOf(e);
			case RVTernary(_, a, b): joined(valuesOf(a), valuesOf(b), (x, y) -> null);
			case EBinop(OpAdd, a, b): joined(valuesOf(a), valuesOf(b), (x, y) -> x + y);
			default: null;
		}
	}

	/** Every whole number `v` can be: `$i + 1` over a range parameter; null when not known. */
	function numbersOf(v:ReferenceableValue):Null<Array<Int>> {
		return switch v {
			case RVInteger(i): [i];
			case RVParenthesis(e): numbersOf(e);
			case RVReference(_):
				final values = valuesOf(v);
				if (values == null)
					return null;
				final out:Array<Int> = [];
				for (s in values) {
					final i = Std.parseInt(s);
					if (i == null || Std.string(i) != s)
						return null;
					out.push(i);
				}
				out;
			case EUnaryOp(OpNeg, e):
				final n = numbersOf(e);
				n == null ? null : [for (x in n) -x];
			case EBinop(op, a, b) if (op.match(OpAdd | OpSub | OpMul)):
				final l = numbersOf(a);
				final r = numbersOf(b);
				if (l == null || r == null)
					return null;
				if (l.length * r.length > MAX_VALUES)
					return null;
				final out:Array<Int> = [];
				for (x in l)
					for (y in r) {
						final z = switch op {
							case OpAdd: x + y;
							case OpSub: x - y;
							default: x * y;
						}
						if (out.indexOf(z) < 0)
							out.push(z);
					}
				out;
			default: null;
		}
	}

	/** `a` and `b` together: each pair joined by `join`, or, when it gives null, every value of both. */
	static function joined(a:Null<Array<String>>, b:Null<Array<String>>, join:(String, String) -> Null<String>):Null<Array<String>> {
		if (a == null || b == null)
			return null;
		if (a.length * b.length > MAX_VALUES)
			return null;
		final out:Array<String> = [];
		function put(s:String)
			if (out.indexOf(s) < 0)
				out.push(s);
		for (x in a)
			for (y in b) {
				final j = join(x, y);
				if (j != null)
					put(j);
				else {
					put(x);
					put(y);
				}
			}
		return out;
	}

	/** What `v` stands for as a `@final`'s value: its values, open when it reads a parameter that is. */
	function bindingOf(v:ReferenceableValue):Binding {
		final was = openSeen;
		openSeen = false;
		final values = valuesOf(v);
		final b:Binding = {values: values, open: openSeen};
		openSeen = was;
		return b;
	}

	/** Each name `v` can be; `fromParameters` set when these are not all it can be, null when none is known. */
	function names(v:Null<ReferenceableValue>):Null<Array<String>> {
		if (v == null)
			return null;
		rv(v);
		openSeen = false;
		final values = valuesOf(v);
		if (values == null || openSeen)
			fromParameters = true;
		return values;
	}

	/** A programmable's or slot's parameters: an enum's, bool's or range's every value; any other its default and what is passed to it. */
	function bindParameters(frame:Map<String, Binding>, defs:Null<ParametersDefinitions>, programmable:Null<String>) {
		if (defs == null)
			return;
		final given = programmable == null ? null : passed.get(programmable);
		for (name => def in defs) {
			final closed:Null<Array<String>> = switch def.type {
				case PPTEnum(values): values.copy();
				// a bool is 1 or 0 written as a string, in the builder and in codegen
				case PPTBool: ["0", "1"];
				case PPTRange(from, to) if (to - from < MAX_VALUES): [for (i in from...to + 1) Std.string(i)];
				default: null;
			}
			if (closed != null) {
				frame.set(name, {values: closed, open: false});
				continue;
			}
			final values:Array<String> = [];
			final d:Null<String> = switch def.defaultValue {
				case null: null;
				case Index(_, value): value;
				case Value(val): Std.string(val);
				case ValueF(val): Std.string(val);
				case Flag(f): Std.string(f);
				case StringValue(s): s;
				case ArrayString(_) | TileSourceValue(_) | ExpressionAlias(_): null;
			}
			// a string with no default is given "" by the parser: it names nothing
			if (d != null && d != "")
				values.push(d);
			final more = given == null ? null : given.get(name);
			if (more != null)
				for (m in more)
					if (values.indexOf(m) < 0)
						values.push(m);
			frame.set(name, {values: values.length > 0 ? values : null, open: true});
		}
	}

	/** A `staticRef`/`dynamicRef` of this file: what it passes, as values its target's parameters can have. */
	function passTo(ref:ReferenceableValue, parameters:Map<String, ReferenceableValue>) {
		// `$name` that is no parameter here is the programmable of that name
		final targets = switch ref {
			case RVReference(name) if (binding(name) == null): [name];
			default: valuesOf(ref);
		}
		if (targets == null)
			return;
		for (target in targets) {
			var byParameter = passed.get(target);
			if (byParameter == null) {
				byParameter = [];
				passed.set(target, byParameter);
			}
			for (param => v in parameters) {
				final values = valuesOf(v);
				if (values == null)
					continue;
				var list = byParameter.get(param);
				if (list == null) {
					list = [];
					byParameter.set(param, list);
				}
				for (s in values)
					if (list.indexOf(s) < 0 && list.length < MAX_VALUES) {
						list.push(s);
						passedGrew = true;
					}
			}
		}
	}

	// ---- needs ----

	function sheetRV(sheet:Null<ReferenceableValue>, cell:Null<ReferenceableValue>) {
		if (sheet == null)
			return;
		final sheetNames = names(sheet);
		// a cell that can be given values other than those known takes the whole sheet
		var cells:Null<Array<String>> = null;
		if (cell != null) {
			rv(cell);
			openSeen = false;
			cells = valuesOf(cell);
			if (cells == null || openSeen) {
				fromParameters = true;
				cells = null;
			}
		}
		if (sheetNames == null)
			return;
		for (s in sheetNames) {
			if (cells == null)
				addSheet(s, null);
			else
				for (c in cells)
					addSheet(s, c);
		}
	}

	function fileRV(v:ReferenceableValue) {
		final files = names(v);
		if (files != null)
			for (f in files)
				add(tiles, f);
	}

	function fontRV(v:Null<ReferenceableValue>) {
		final fontNames = names(v);
		if (fontNames != null)
			for (f in fontNames)
				add(fonts, f);
	}

	function cursorRV(v:ReferenceableValue) {
		final cursorNames = names(v);
		// `CursorManager` keeps a name in lower case
		if (cursorNames != null)
			for (c in cursorNames)
				if (c != "")
					add(cursors, c.toLowerCase());
	}

	/** A value anywhere: `$ctx.font("name")` in it is a font. */
	function rv(v:Null<ReferenceableValue>) {
		if (v == null)
			return;
		switch v {
			case RVMethodCall(ref, method, args):
				if (ref == "ctx" && method == "font" && args.length == 1)
					fontRV(args[0]);
				else
					for (a in args)
						rv(a);
			case RVChainedMethodCall(base, _, args):
				rv(base);
				for (a in args)
					rv(a);
			case RVElementOfArray(_, index): rv(index);
			case RVArray(arr): for (a in arr) rv(a);
			case RVParenthesis(e): rv(e);
			case RVCallbacksWithIndex(name, index, def): rv(name); rv(index); rv(def);
			case RVCallbacks(name, def): rv(name); rv(def);
			case RVColorXY(_, _, x, y): rv(x); rv(y);
			case RVColor(_, _, index): rv(index);
			case RVTernary(c, a, b): rv(c); rv(a); rv(b);
			case EBinop(_, a, b): rv(a); rv(b);
			case EUnaryOp(_, e): rv(e);
			case RVString(_) | RVInteger(_) | RVFloat(_) | RVReference(_) | RVArrayReference(_) | RVPropertyAccess(_, _):
		}
	}

	function coord(c:Null<Coordinates>) {
		if (c == null)
			return;
		switch c {
			case ZERO:
			case OFFSET(x, y): rv(x); rv(y);
			case LAYOUT(_, index): rv(index);
			case SELECTED_GRID_POSITION(x, y): rv(x); rv(y);
			case SELECTED_HEX_CORNER(a, b) | SELECTED_HEX_EDGE(a, b) | SELECTED_HEX_PIXEL(a, b) | SELECTED_HEX_DOUBLED(a, b): rv(a); rv(b);
			case SELECTED_HEX_CUBE(q, r, s): rv(q); rv(r); rv(s);
			case SELECTED_HEX_OFFSET(col, row, _): rv(col); rv(row);
			case SELECTED_HEX_CELL_CORNER(cell, a, b) | SELECTED_HEX_CELL_EDGE(cell, a, b): coord(cell); rv(a); rv(b);
			case NAMED_COORD(_, inner): coord(inner);
			case WITH_OFFSET(base, x, y): coord(base); rv(x); rv(y);
			case EXTRA_POINT_REF(_, _, fallback): coord(fallback);
			case EXTRA_POINT_ANIM(filename, _, _, _, fallback):
				add(anims, filename);
				coord(fallback);
		}
	}

	function tile(t:TileSource) {
		switch t {
			case TSFile(filename): fileRV(filename);
			case TSSheet(sheet, name): sheetRV(sheet, name);
			case TSSheetWithIndex(sheet, name, index): sheetRV(sheet, name); rv(index);
			case TSGenerated(type):
				switch type {
					case SolidColorWithText(_, _, _, _, _, font): fontRV(font);
					case AutotileRegionSheet(_, _, font, _): fontRV(font);
					case Cross(_, _, _, _) | SolidColor(_, _, _) | AutotileRef(_, _):
				}
			#if (!macro && !noheaps)
			case TSTile(_):
			#end
			case TSReference(_):
			case TSPivot(_, _, inner): tile(inner);
		}
	}

	function filter(f:Null<FilterType>) {
		if (f == null)
			return;
		switch f {
			case FilterCustom(name, _): add(filters, name);
			case FilterGroup(fs): for (g in fs) filter(g);
			default:
		}
	}

	function params(defs:Null<ParametersDefinitions>) {
		if (defs == null)
			return;
		for (_ => def in defs)
			switch def.defaultValue {
				case TileSourceValue(ts): tile(ts);
				case ExpressionAlias(e): rv(e);
				default:
			}
	}

	function text(def:TextDef) {
		fontRV(def.fontName);
		rv(def.text);
		if (def.styles != null)
			for (s in def.styles)
				fontRV(s.fontName);
		if (def.images != null)
			for (i in def.images)
				tile(i.tileSource);
		if (def.autoFitFonts != null)
			for (f in def.autoFitFonts)
				fontRV(f);
	}

	/** `sound.<key> => "bank.sound" | none`: the sound named (not `none`); the keys given are returned. */
	function soundSetting(key:String, value:ReferenceableValue, own:Array<String>) {
		if (key.indexOf("sound.") != 0)
			return;
		own.push(key.substr(6));
		final soundNames = names(value);
		if (soundNames != null)
			for (s in soundNames)
				if (s != "none" && s != "")
					add(sounds, s);
	}

	function settings(node:Node, own:Array<String>) {
		if (node.settings == null)
			return;
		for (key => sv in node.settings) {
			if (key == "music") {
				final tracks = names(sv.value);
				if (tracks != null)
					for (t in tracks)
						if (t != "none" && t != "")
							add(music, t);
			} else if (key == "ambience") {
				// a screen's held sound, a sound of a bank like any other
				final held = names(sv.value);
				if (held != null)
					for (s in held)
						if (s != "none" && s != "")
							add(sounds, s);
			} else if (key == "font" || StringTools.endsWith(key, ".font"))
				// what a widget is given (`font`, `item.font`), passed to its programmable's `text()`
				fontRV(sv.value);
			else
				soundSetting(key, sv.value, own);
		}
	}

	function widgetKeys(keys:Array<String>, own:Array<String>) {
		for (k in keys)
			if (own.indexOf(k) < 0)
				add(uiSounds, k);
	}

	/**
		The keys of the `ui` bank a widget drawn with a programmable of these parameters plays: each
		widget is told apart by the parameters it passes (`UIScreenBase.widgetSoundKey` for which of its
		events plays which key).
	**/
	static function widgetSounds(p:ParametersDefinitions):Array<String> {
		// a scrollbar's `status` is optional
		if (p.exists("scrollPosition") && p.exists("scrollableHeight") && p.exists("panelHeight"))
			return ["change"];
		if (!p.exists("status"))
			return [];
		if (p.exists("buttonText"))
			return ["hover", "click"];
		// a checkbox toggles; a tab or radio button is drawn the same and its tabs or radio group sends a change
		if (p.exists("checked"))
			return ["toggle", "change"];
		// a dropdown
		if (p.exists("panel"))
			return ["open", "close", "change"];
		// a slider, a scrollable list's item
		if ((p.exists("value") && p.exists("size")) || (p.exists("title") && p.exists("selected")))
			return ["change"];
		// a text input, a card, a grid cell
		return [];
	}

	function repeat(r:RepeatType) {
		switch r {
			case StepIterator(dx, dy, count): rv(dx); rv(dy); rv(count);
			case LayoutIterator(_) | ArrayIterator(_, _):
			case RangeIterator(start, end, step): rv(start); rv(end); rv(step);
			case StateAnimIterator(_, animFilename, animationName, _):
				add(anims, animFilename);
				rv(animationName);
			case TilesIterator(_, _, sheetName, _): addSheet(sheetName, null);
		}
	}

	function visit(node:Node) {
		// what the node's names can read: a programmable's or slot's parameters (its own settings
		// read them too), a loop's variable, and the `@final`s of its body as they come
		final frame:Map<String, Binding> = [];
		switch node.type {
			case PROGRAMMABLE(_, parameters, _): bindParameters(frame, parameters, rootName);
			case SLOT(parameters, _): bindParameters(frame, parameters, null);
			case REPEAT(v, _): frame.set(v, UNKNOWN);
			case REPEAT2D(vx, vy, _, _):
				frame.set(vx, UNKNOWN);
				frame.set(vy, UNKNOWN);
			default:
		}
		scopes.push(frame);
		coord(node.pos);
		rv(node.scale);
		rv(node.rotation);
		rv(node.alpha);
		rv(node.tint);
		filter(node.filter);
		if (node.flowProperties != null) {
			rv(node.flowProperties.offsetX);
			rv(node.flowProperties.offsetY);
		}
		final own:Array<String> = [];
		settings(node, own);
		switch node.type {
			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, _, pt, pb, pl, pr, hs, vs, _, _, bgSheet, bgTile, _, _, _, _, _, _, _):
				for (v in [maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, pt, pb, pl, pr, hs, vs])
					rv(v);
				if (bgSheet != null)
					sheetRV(bgSheet, bgTile);
			case SPACER(w, h): rv(w); rv(h);
			case BITMAP(ts, _, _): tile(ts);
			case STATEANIM(filename, initial, selector):
				add(anims, filename);
				rv(initial);
				for (_ => v in selector)
					rv(v);
			case STATEANIM_CONSTRUCT(initial, construct, _):
				rv(initial);
				for (_ => c in construct)
					switch c {
						case IndexedSheet(sheet, name, fps, _, _):
							sheetRV(RVString(sheet), name);
							rv(fps);
					}
			case TEXT(def) | RICHTEXT(def): text(def);
			case PROGRAMMABLE(_, parameters, _):
				params(parameters);
				widgetKeys(widgetSounds(parameters), own);
			case PARTICLES(p):
				for (t in p.tiles)
					tile(t);
				if (p.animFile != null)
					add(anims, p.animFile);
			case MASK(w, h): rv(w); rv(h);
			case REPEAT(_, r): repeat(r);
			case REPEAT2D(_, _, rx, ry): repeat(rx); repeat(ry);
			case STATIC_REF(external, ref, parameters) | DYNAMIC_REF(external, ref, parameters):
				rv(ref);
				for (_ => v in parameters)
					rv(v);
				// an imported programmable's needs are the import's own
				if (external == null)
					passTo(ref, parameters);
			case PLACEHOLDER(type, _):
				switch type {
					case PHTileSource(source): tile(source);
					case PHError | PHNothing:
				}
			case NINEPATCH(sheet, tilename, w, h, _, index, fps):
				sheetRV(sheet, tilename);
				rv(w); rv(h); rv(index); rv(fps);
			case INTERACTIVE(w, h, id, _, metadata):
				rv(w); rv(h); rv(id);
				var clicks = true;
				if (metadata != null)
					for (m in metadata)
						switch m.key {
							case RVString("events"):
								switch m.value {
									case RVInteger(flags): clicks = flags & EVENT_CLICK != 0;
									default:
								}
							case RVString(key) if (key == "cursor" || StringTools.startsWith(key, "cursor.")):
								cursorRV(m.value);
							case RVString(key): soundSetting(key, m.value, own);
							default:
						}
				if (clicks)
					widgetKeys(["click"], own);
			case PALETTE(paletteType):
				switch paletteType {
					case PaletteImageFile(filename): fileRV(filename);
					case PaletteColors(colors): for (c in colors) rv(c);
					case PaletteColors2D(colors, _): for (c in colors) rv(c);
				}
			case CURSORS(cursors):
				for (c in cursors)
					tile(c.tile);
			case SOUNDS(def):
				for (s in def.sounds)
					for (l in s.layers)
						for (f in l.files)
							add(soundFiles, f);
			case MUSIC(def):
				for (t in def.tracks)
					add(soundFiles, t.file);
			case MIX(_):
			case AUTOTILE(def):
				switch def.source {
					case ATSAtlas(sheet, prefix): sheetRV(sheet, null); rv(prefix);
					case ATSAtlasIndexed(sheet, name): sheetRV(sheet, name);
					case ATSFile(filename): fileRV(filename);
					case ATSTiles(ts): for (t in ts) tile(t);
					case ATSDemo(_, _):
				}
			case ATLAS2(def):
				// the file's own sheet, cut from an image or out of another sheet
				switch def.source {
					case A2SFile(filename): fileRV(filename);
					case A2SSheet(sheetName): sheetRV(sheetName, null);
				}
			case TILESET(def):
				var any = false;
				for (t in def.terrains)
					if (t.cells != null) {
						addSheet(def.atlas, t.cells);
						any = true;
					}
				for (r in def.rises) {
					for (s in r.sides)
						addSheet(def.atlas, s);
					if (r.sides.length == 0)
						addSheet(def.atlas, r.side);
					if (r.left != null) addSheet(def.atlas, r.left);
					if (r.right != null) addSheet(def.atlas, r.right);
					if (r.single != null) addSheet(def.atlas, r.single);
					any = true;
				}
				if (!any && !sheets.exists(def.atlas))
					sheets.set(def.atlas, []);
			case TILEMAP(def):
				// a layer's cells are in its own sheet, else the tileset's atlas (of this file; an
				// import's tileset lists its atlas in the import's own needs)
				for (l in def.layers) {
					var sheet = l.sheet;
					if (sheet == null && def.tilesetImport == null)
						sheet = atlasOfTileset(def.tileset);
					if (sheet == null)
						continue;
					for (_ => cell in l.legend)
						addSheet(sheet, cell);
				}
			case FINAL_VAR(_, value): rv(value);
			case SWITCH(_, arms):
				for (arm in arms) {
					final armFrame:Map<String, Binding> = [];
					scopes.push(armFrame);
					for (c in arm.children)
						child(c, armFrame);
					scopes.pop();
				}
			case POINT | PIXELS(_) | TILEGROUP | RELATIVE_LAYOUTS(_) | PATHS(_) | ANIMATED_PATH(_) | CURVES(_) | APPLY | LAYERS | GRAPHICS(_) | TILEMAP_REF(_, _) | DATA(_) | SLOT_CONTENT:
			case TILEMAP_FILL(_, _, terrain, cols, rows):
				// as tilemap(name): the tileset's sheets and autotiles are listed with the tileset (an
				// import's in the import's own needs); a terrain is a name in it, not a sheet's
				rv(terrain); rv(cols); rv(rows);
			case SLOT(parameters, _): params(parameters);
		}
		for (c in node.children)
			child(c, frame);
		scopes.pop();
	}

	/** A node of a body: a `@final` is bound in the body's frame, for the nodes after it. */
	function child(c:Node, frame:Map<String, Binding>) {
		switch c.type {
			case FINAL_VAR(name, value):
				rv(value);
				frame.set(name, bindingOf(value));
			default:
				visit(c);
		}
	}

	var rootNodes:Null<Map<String, Node>> = null;

	/** The atlas of a tileset of this file, by name (a tileset is always a root node); null when it is not here. */
	function atlasOfTileset(name:String):Null<String> {
		if (rootNodes != null) {
			final ts = rootNodes.get(name);
			if (ts != null)
				switch ts.type {
					case TILESET(def): return def.atlas;
					default:
				}
		}
		return null;
	}
}
