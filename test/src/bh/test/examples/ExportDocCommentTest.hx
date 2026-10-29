package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.MacroManimParser;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimBuilder.BuilderResult;

/**
 * `export` on a root block and `///` doc comments, kept by the parse (hx-multianim requests 19
 * and 20):
 * - `#name export kind…` marks a root block of any kind: `node.exported`, its name in
 *   `MultiAnimResult.exports` in the order written (`MultiAnimResultTools.exportedNames`,
 *   `builder.exportedNames()`); `export` takes no name (a block, element, parameter, choice or
 *   data field may still be called export); only a root block can be exported; an import
 *   reaches every block alike, in the builder and in codegen;
 * - a `///` keeps its text on what it documents: a root block (the lines above it), a parameter
 *   and a choice of an enum parameter (the lines above it, and one trailing it on its line), the
 *   lines joined with "\n" (`MultiAnimResultTools.docOf`, `builder.docOf`); one that documents
 *   nothing, or sits in an expression or a string, is a comment as before;
 * - a file with neither parses as before.
 *
 * Companion fixtures: test/examples/167-exportDocs/
 */
class ExportDocCommentTest extends BuilderTestBase {
	static inline var PACK = "test/examples/167-exportDocs/exportDocsPack.manim";
	static inline var FIXTURE = "test/examples/167-exportDocs/exportDocs.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function parse(source:String):MultiAnimResult {
		return MacroManimParser.parseFile("version: 1.0\n" + source, "export-doc-test", null);
	}

	static function errorOf(source:String):Null<String> {
		try {
			parse(source);
			return null;
		} catch (e:InvalidSyntax) {
			return e.toString();
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function defsOf(r:MultiAnimResult, name:String):ParametersDefinitions {
		return switch r.nodes.get(name).type {
			case PROGRAMMABLE(_, defs, _): defs;
			default: throw 'not a programmable: $name';
		};
	}

	static function serialized(r:MultiAnimResult):String {
		final s = new haxe.Serializer();
		s.useCache = true;
		s.useEnumIndex = false;
		s.serialize(r.nodes);
		return s.toString();
	}

	static function visibleBitmaps(root:h2d.Object):Int {
		return BuilderTestBase.findVisibleBitmapDescendants(root).length;
	}

	// ===== A file with neither =====

	@Test
	public function testAFileWithNeitherParsesAsBefore():Void {
		final plain = "
#a programmable(state:[idle, walk]=idle, hp:uint=3) {
	@(state=>idle) bitmap(generated(color(4, 4, #FF0000))): 0, 0
	@final half = $hp / 2
}
#d data { x: 1 }
";
		// The same lines with plain comments at their ends, and a ruled line of four slashes
		final commented = "
#a programmable(state:[idle, walk]=idle, hp:uint=3) { // a plain comment
	@(state=>idle) bitmap(generated(color(4, 4, #FF0000))): 0, 0 //// four slashes: plain
	@final half = $hp / 2 /* a block comment /// with slashes */
}
#d data { x: 1 } // the end
";
		final a = parse(plain);
		final b = parse(commented);
		Assert.equals(0, a.exports.length, "no block is exported");
		Assert.same([], MultiAnimResultTools.exportedNames(a));
		Assert.equals(serialized(a), serialized(b), "plain and four-slash comments change nothing in the parse");
		for (name => node in a.nodes) {
			Assert.isTrue(node.exported != true, '$name is not exported');
			Assert.isNull(node.doc, '$name has no doc');
		}
		for (def in defsOf(a, "a")) {
			Assert.isNull(def.doc, '${def.name} has no doc');
			Assert.isNull(def.choiceDocs, '${def.name} has no choice docs');
		}
		Assert.isNull(MultiAnimResultTools.docOf(a, "a"));
		Assert.isNull(MultiAnimResultTools.docOf(a, "a", "state"));
		Assert.isNull(MultiAnimResultTools.docOf(a, "a", "state", "idle"));
	}

	@Test
	public function testADocThatDocumentsNothingChangesNothing():Void {
		final plain = "
#a programmable(w:uint=8) {
	bitmap(generated(color($w, 2, #FF0000))): 0, 0
	@final half = $w / 2
	text(m3x6, \"x\", #FFFFFF): 0, 10
}
";
		// `///` on the same lines, where it documents no root block, parameter or choice
		final withDocs = "
#a programmable(w:uint=8) { /// trails the header
	bitmap(generated(color($w, 2, #FF0000))): 0, 0 /// trails an element
	@final half = $w / 2 /// trails an expression
	text(m3x6, \"x\", #FFFFFF): 0, 10 /// trails a text
} /// trails the block
";
		final a = parse(plain);
		final b = parse(withDocs);
		Assert.equals(serialized(a), serialized(b), "a `///` that documents nothing is a comment like any other");
		Assert.isNull(b.nodes.get("a").doc);
		Assert.isNull(defsOf(b, "a").get("w").doc, "a `///` after the header's ) is not the last parameter's");
	}

	// ===== export =====

	@Test
	public function testExportMarksEveryKindOfRootBlock():Void {
		final atlas = "#fp atlas2(\"x.png\") { grass: 0, 0, 8, 8 }\n";
		final tileset = "#ts tileset { tileSize: 8 atlas: \"fp\" terrain grass { cells: \"grass\" } }\n";
		// `before`: what the block needs written ahead of it; the doc goes right above #b
		final kinds:Array<{kind:String, before:String, block:String}> = [
			{kind: "PROGRAMMABLE", before: "", block: "#b export programmable() {\n\tbitmap(generated(color(2, 2, #FF0000))): 0, 0\n}"},
			{kind: "PROGRAMMABLE", before: "", block: "#b export programmable tileGroup() {\n\tbitmap(generated(color(2, 2, #FF0000))): 0, 0\n}"},
			{kind: "DATA", before: "", block: "#b export data { x: 1 }"},
			{kind: "PALETTE", before: "", block: "#b export palette { #FF0000 #00FF00 }"},
			{kind: "CURVES", before: "", block: "#b export curves { #grow curve { points: [(0, 0.5), (1, 2.0)] } }"},
			{kind: "PATHS", before: "", block: "#b export paths { #straight path { lineTo(100, 0) } }"},
			{kind: "ANIMATED_PATH", before: "paths { #straight path { lineTo(100, 0) } }\n", block: "#b export animatedPath { path: straight type: time duration: 1.0 }"},
			{kind: "PARTICLES", before: "", block: "#b export particles { count: 5 emit: point(dist: 0, distRand: 0) tiles: sheet(\"demo\", \"tile-center\") maxLife: 1.0 }"},
			{kind: "CURSORS", before: "", block: "#b export cursor { hand: sheet(\"ui\", \"icon_drop\"), hot: 2, 3 }"},
			{kind: "SOUNDS", before: "", block: "#b export sounds { click { file: \"sound/click.wav\" } }"},
			{kind: "MIX", before: "", block: "#b export mix { bus ui }"},
			{kind: "MUSIC", before: "", block: "#b export music { track a { file: \"music/a.mp3\" } }"},
			{kind: "ATLAS2", before: "", block: "#b export atlas2(\"x.png\") { c1: 0, 0, 8, 8 }"},
			{kind: "AUTOTILE", before: "", block: "#b export autotile { format: corner tileSize: 8 demo: #fff, #000 }"},
			{kind: "TILESET", before: atlas, block: "#b export tileset { tileSize: 8 atlas: \"fp\" terrain grass { cells: \"grass\" } }"},
			{kind: "TILEMAP", before: atlas + tileset, block: "#b export tilemap { tileset: ts size: 2, 1 legend { \".\": grass } terrain: [\"..\"] }"},
			{kind: "RELATIVE_LAYOUTS", before: "", block: "#b export layouts { #row list { point: 0, 0 } }"},
			{kind: "LAYERS", before: "", block: "#b export layers() {\n\tbitmap(generated(color(2, 2, #FF0000))): 0, 0\n}"},
		];
		for (k in kinds) {
			final source = k.before + "/// the " + k.kind + " block\n" + k.block;
			final err = errorOf(source);
			Assert.isNull(err, '${k.kind}: #b export … parses; got $err');
			if (err != null) continue;
			final r = parse(source);
			final node = r.nodes.get("b");
			Assert.notNull(node, '${k.kind}: the block is kept under its name');
			if (node == null) continue;
			Assert.equals(k.kind, Type.enumConstructor(node.type), '${k.kind}: the block is of its kind');
			Assert.isTrue(node.exported == true, '${k.kind}: the block is exported');
			Assert.same(["b"], r.exports, '${k.kind}: the only export');
			Assert.equals("the " + k.kind + " block", node.doc, '${k.kind}: the doc above #b export is the block\'s');
			for (name => other in r.nodes)
				if (name != "b") Assert.isTrue(other.exported != true, '${k.kind}: $name is not exported');
		}
	}

	@Test
	public function testExportedNamesAreInTheOrderWritten():Void {
		final source = "
#zeta export programmable() {}
#alpha programmable() {}
#mid export data { x: 1 }
#beta export palette { #FF0000 }
";
		final r = parse(source);
		Assert.same(["zeta", "mid", "beta"], MultiAnimResultTools.exportedNames(r));
		final names = MultiAnimResultTools.exportedNames(r);
		names.push("changed");
		Assert.same(["zeta", "mid", "beta"], MultiAnimResultTools.exportedNames(r), "a copy: the parse's list is kept");
		final builder = BuilderTestBase.builderFromSource(source);
		Assert.same(["zeta", "mid", "beta"], builder.exportedNames(), "the builder lists the same");
		Assert.same([], BuilderTestBase.builderFromSource("#a programmable() {}").exportedNames(), "none: empty");
	}

	@Test
	public function testExportTakesNoName():Void {
		// A block, an element, a parameter, a choice and a data field may all be called export
		final source = "
#export programmable(export:uint=1, mode:[export, other]=export) {
	#export bitmap(generated(color(2, 2, #FF0000))): 0, 0
	@(mode=>export) bitmap(generated(color(3, 3, #00FF00))): 0, 0
}
#d data { export: 1 }
";
		final err = errorOf(source);
		Assert.isNull(err, 'export is still a name; got $err');
		if (err != null) return;
		final r = parse(source);
		Assert.notNull(r.nodes.get("export"), "a block named export");
		Assert.isTrue(r.nodes.get("export").exported != true, "#export programmable(): named export, not exported");
		Assert.equals(0, r.exports.length);
		Assert.notNull(defsOf(r, "export").get("export"), "a parameter named export");
		Assert.isTrue(defsOf(r, "export").get("mode").type.match(PPTEnum(["export", "other"])), "a choice named export");
		final built = BuilderTestBase.buildFromSource(source, "export");
		Assert.equals(2, visibleBitmaps(built.object), "the block named export builds, its element named export with it");

		final both = parse("#export export programmable() {}");
		Assert.same(["export"], both.exports, "#export export programmable(): a block named export, exported");
		Assert.isTrue(both.nodes.get("export").exported == true);
	}

	@Test
	public function testOnlyARootBlockCanBeExported():Void {
		final nested = errorOf("#p programmable() {\n\t#child export bitmap(generated(color(2, 2, #FF0000))): 0, 0\n}");
		Assert.notNull(nested, "a named element inside a block cannot be exported");
		if (nested != null) Assert.stringContains("only a root block can be exported", nested);

		final unnamedElement = errorOf("#p programmable() {\n\texport bitmap(generated(color(2, 2, #FF0000))): 0, 0\n}");
		Assert.notNull(unnamedElement, "an element inside a block cannot be exported");
		if (unnamedElement != null) Assert.stringContains("only a root block can be exported", unnamedElement);

		final noName = errorOf("export curves { #c curve { easing: easeInQuad } }");
		Assert.notNull(noName, "export goes after a #name");
		if (noName != null) Assert.stringContains("export goes right after a root block's #name", noName);

		final beforeName = errorOf("export #b programmable() {}");
		Assert.notNull(beforeName, "export is not written before the #name");
	}

	@Test
	public function testExportChangesNothingAnImportReaches():Void {
		// The fixture imports the pack and places both its exported knight and its private helper
		var result:Null<BuilderResult> = null;
		var err:Null<String> = null;
		try result = BuilderTestBase.buildFromFile(FIXTURE, "exportDocs") catch (e:Dynamic) err = Std.string(e);
		Assert.isNull(err, 'the importer builds, placing a block the pack does not export; got $err');
		if (result != null)
			Assert.equals(6, visibleBitmaps(result.object), "the knight (1), its helper (3) and the helper placed alone (2)");

		final pack = BuilderTestBase.builderFromFile(PACK);
		Assert.same(["knight"], pack.exportedNames());
		final params:Map<String, Dynamic> = ["n" => 2];
		Assert.equals(2, visibleBitmaps(pack.buildWithParameters("helper", params).object), "a block not exported builds");
		Assert.equals(4, visibleBitmaps(pack.buildWithParameters("preview", new Map()).object), "so does one placing an exported one");
	}

	@Test
	public function testCodegenAcceptsExportAndDocs():Void {
		final mp = createMp();
		final importer:h2d.Object = cast mp.exportDocs.create();
		Assert.equals(6, visibleBitmaps(importer), "codegen: the importer places the knight and the pack's private helper");
		final knight:h2d.Object = cast mp.exportDocsKnight.create();
		Assert.equals(4, visibleBitmaps(knight), "codegen: the exported, documented knight builds as the builder's");
		final builderKnight = BuilderTestBase.buildFromFile(PACK, "knight");
		Assert.equals(visibleBitmaps(builderKnight.object), visibleBitmaps(knight), "the same in both backends");
	}

	// ===== /// doc comments =====

	@Test
	public function testABlocksDocIsTheLinesDirectlyAboveIt():Void {
		final r = parse("
/// line one
/// line two
#a programmable() {}

/// a header, with a blank line after it

#b programmable() {}

/// above a plain comment line
// a plain comment between
#c programmable() {}

//// four slashes are a plain comment
#d programmable() {}

///
/// first paragraph
///
/// second paragraph
///
#e programmable() {}
///tight
///   two spaces
#f programmable() {}
");
		Assert.equals("line one\nline two", r.nodes.get("a").doc, "several lines join with \\n");
		Assert.isNull(r.nodes.get("b").doc, "a blank line between breaks it");
		Assert.isNull(r.nodes.get("c").doc, "another line between breaks it");
		Assert.isNull(r.nodes.get("d").doc, "//// is not a doc comment");
		Assert.equals("first paragraph\n\nsecond paragraph", r.nodes.get("e").doc, "blank /// lines inside are kept, at the ends dropped");
		Assert.equals("tight\n  two spaces", r.nodes.get("f").doc, "the one space after /// is taken off, no more");
		Assert.equals("line one\nline two", MultiAnimResultTools.docOf(r, "a"));
	}

	@Test
	public function testDocsOfOtherRootDefinitionsAndOfNone():Void {
		final r = MacroManimParser.parseFile("/// above the version header: the file's, attached to nothing\nversion: 1.0\n"
			+ "/// the curves\ncurves { #c curve { easing: easeInQuad } }\n"
			+ "/// the limit\n@final LIMIT = 3\n"
			+ "/// an import's: dropped\nimport \"other.manim\" as \"other\"\n"
			+ "#a programmable() {}\n/// at the end of the file: attached to nothing\n", "docs-test", null);
		Assert.isNull(r.nodes.get("a").doc, "a doc above version: is no block's");
		Assert.equals("the curves", r.nodes.get("#defaultCurves").doc, "an unnamed root block's");
		Assert.equals("the limit", r.nodes.get("LIMIT").doc, "a root @final's");
	}

	@Test
	public function testCrlfSourceDocs():Void {
		final r = MacroManimParser.parseFile("version: 1.0\r\n/// crlf doc\r\n/// line two\r\n#a programmable(\r\n\t/// p's\r\n\tp:[x, /// ex\r\n\ty] = x\r\n) {}\r\n",
			"crlf-test", null);
		Assert.equals("crlf doc\nline two", r.nodes.get("a").doc, "no \\r in a CRLF file's doc");
		Assert.equals("p's", MultiAnimResultTools.docOf(r, "a", "p"));
		Assert.equals("ex", MultiAnimResultTools.docOf(r, "a", "p", "x"));
	}

	@Test
	public function testAParametersDoc():Void {
		final r = parse("
#a programmable(
	/// first line
	/// second line
	one:uint = 1,
	two:uint = 2, /// trails two
	/// leads three
	three:[x, y] = x, /// trails three
	four:string = \"a, b\" /// trails four, the last
) {}
#b programmable(p:uint = 1, q:uint = 2 /// q's
) {}
#c programmable(p:uint = 1, q:uint = 2) /// after the header: no parameter's
{}
");
		final a = defsOf(r, "a");
		Assert.equals("first line\nsecond line", a.get("one").doc, "the lines above a parameter");
		Assert.equals("trails two", a.get("two").doc, "a doc trailing a parameter, after its comma");
		Assert.equals("leads three\ntrails three", a.get("three").doc, "the lines above first, then the trailing one");
		Assert.isNull(a.get("three").choiceDocs, "a doc after the enum's ] is the parameter's, no choice's");
		Assert.equals("trails four, the last", a.get("four").doc, "a doc trailing the last parameter, before )");
		Assert.isNull(defsOf(r, "b").get("p").doc, "a doc trailing q on the line p is on is q's");
		Assert.equals("q's", defsOf(r, "b").get("q").doc);
		Assert.isNull(defsOf(r, "c").get("q").doc, "a doc after the ) is no parameter's");
		Assert.isNull(r.nodes.get("c").doc, "nor the block's");
		Assert.equals("trails two", MultiAnimResultTools.docOf(r, "a", "two"));
	}

	@Test
	public function testEachChoiceOfAnEnumParameterKeepsItsDoc():Void {
		final r = parse("
#a programmable(
	/// the state
	state:[
		/// leads idle
		idle,  /// trails idle
		walk,  /// trails walk
		run    /// trails run, the last
	] = idle,
	plain:[x, y] = x,
	level:[1, /// one
		2 /// two
	] = 1,
	size:[\"s m\", /// small and medium
		big] = big
) {}
");
		final defs = defsOf(r, "a");
		Assert.equals("the state", defs.get("state").doc);
		final state = defs.get("state").choiceDocs;
		Assert.notNull(state);
		if (state != null) {
			Assert.equals("leads idle\ntrails idle", state.get("idle"));
			Assert.equals("trails walk", state.get("walk"));
			Assert.equals("trails run, the last", state.get("run"));
		}
		Assert.isNull(defs.get("plain").choiceDocs, "no choice has a doc: no map");
		Assert.equals("one", MultiAnimResultTools.docOf(r, "a", "level", "1"), "a numeric choice's");
		Assert.equals("two", MultiAnimResultTools.docOf(r, "a", "level", "2"));
		Assert.equals("small and medium", MultiAnimResultTools.docOf(r, "a", "size", "s m"), "a quoted choice's");
		Assert.isNull(MultiAnimResultTools.docOf(r, "a", "size", "big"));
		Assert.isNull(defs.get("level").doc, "a choice's doc is not its parameter's");
	}

	@Test
	public function testASlotsParametersKeepTheirDocs():Void {
		final r = parse("
#a programmable() {
	#box slot(
		/// lit or not
		lit:[off, on /// glowing
		] = off
	) {
		bitmap(generated(color(2, 2, #FF0000))): 0, 0
	}
}
");
		final slot = r.nodes.get("a").children[0];
		switch slot.type {
			case SLOT(defs, _) if (defs != null):
				Assert.equals("lit or not", defs.get("lit").doc);
				Assert.equals("glowing", defs.get("lit").choiceDocs?.get("on"));
			default:
				Assert.fail('expected a parameterized slot, got ${slot.type}');
		}
	}

	@Test
	public function testDocsInExpressionsAndStringsAreNotMisread():Void {
		final source = "
#a programmable(w:uint = 8) {
	@final half = $w / 2 /// halves it
	@final quarter = $w / /// a comment, the expression goes on
		4
	text(m3x6, \"a /// b\", #FFFFFF): 0, 0
	text(m3x6, 'c /// ${$w} d', #FFFFFF): 0, 10
	bitmap(generated(color($half, 2, #FF0000))): 0, 20 /// trails an element
	bitmap(generated(color($quarter, 3, #FF0000))): 0, 30
}
";
		final err = errorOf(source);
		Assert.isNull(err, 'parses; got $err');
		if (err != null) return;
		final built = BuilderTestBase.buildFromSource(source, "a");
		final texts = [for (t in BuilderTestBase.findAllTextDescendants(built.object)) t.text];
		Assert.same(["a /// b", "c /// 8 d"], texts, "/// in a string is the string's");
		final widths = [for (b in BuilderTestBase.findVisibleBitmapDescendants(built.object)) Std.int(b.tile.width)];
		Assert.same([4, 2], widths, "/// in an expression is a comment: $w / 2, $w / 4");
		for (child in parse(source).nodes.get("a").children)
			Assert.isNull(child.doc, "no element keeps a doc");
	}

	@Test
	public function testPackDocsFromTheParseAndTheBuilder():Void {
		final r = MacroManimParser.parseFile(sys.io.File.getContent(PACK), PACK, null);
		Assert.same(["knight"], MultiAnimResultTools.exportedNames(r));
		Assert.equals("A knight that walks and stands.\nDrawn from two boxes.", MultiAnimResultTools.docOf(r, "knight"));
		Assert.equals("What the knight is doing", MultiAnimResultTools.docOf(r, "knight", "state"));
		Assert.equals("stands still", MultiAnimResultTools.docOf(r, "knight", "state", "idle"));
		Assert.equals("4 frames at 8 fps", MultiAnimResultTools.docOf(r, "knight", "state", "walk"));
		Assert.equals("hit points, at most 9", MultiAnimResultTools.docOf(r, "knight", "hp"));
		Assert.equals("how wide it is drawn", MultiAnimResultTools.docOf(r, "knight", "w"));
		Assert.equals("A private helper: not exported, placed by the knight and by the file importing this one.",
			MultiAnimResultTools.docOf(r, "helper"), "a block not exported keeps its doc");
		Assert.isNull(MultiAnimResultTools.docOf(r, "preview"));
		Assert.isNull(MultiAnimResultTools.docOf(r, "nothing"), "no such block");
		Assert.isNull(MultiAnimResultTools.docOf(r, "knight", "nothing"), "no such parameter");
		Assert.isNull(MultiAnimResultTools.docOf(r, "knight", "state", "run"), "no such choice");
		Assert.isNull(MultiAnimResultTools.docOf(r, "knight", "hp", "1"), "not an enum parameter");

		final builder = BuilderTestBase.builderFromFile(PACK);
		Assert.same(["knight"], builder.exportedNames());
		Assert.equals("A knight that walks and stands.\nDrawn from two boxes.", builder.docOf("knight"));
		Assert.equals("hit points, at most 9", builder.docOf("knight", "hp"));
		Assert.equals("4 frames at 8 fps", builder.docOf("knight", "state", "walk"));
		Assert.equals("hit points, at most 9", builder.getParameterDefinitions("knight").get("hp").doc, "on the definitions too");
	}
}
