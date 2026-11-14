package manim.lsp.test;

import manim.lsp.ManimAnalyzer;
import manim.lsp.LspTypes;
import bh.multianim.MultiAnimParser;

class ManimAnalyzerTest {
	public static function run():Void {
		LspTestRunner.suite("ManimAnalyzer");

		testValidFileNoDiagnostics();
		testInvalidFileDiagnostics();
		testSymbols();
		testCompletions();
		testReferenceCompletionLabels();
		testPathCompletionsSuggestOnlyParserKeywords();
		testHover();
		testStateAnimArguments();
		testDefinition();
		testDataEnumSymbols();
		testIntegerLiteralsAreThirtyTwoBits();
		testExportAndDocComments();
		testExportKeywordCompletionAndHover();
		testDocCommentHover();
		testSoundDocHover();
		testTilesetTransitionIgnore();
	}

	/** A tileset's `transition a, b { autotile: … ignore: … }`: completed, hovered, and its errors said at the name ignored. */
	static function testTilesetTransitionIgnore():Void {
		final head = "version: 1.0\n#c autotile { format: blob47 tileSize: 8 demo: #E0C878, #00000000 }\n#t tileset {\n\ttileSize: 8\n\tatlas: \"fp\"\n\tterrain land { cells: \"grass\" }\n\tterrain sea { autotile: c }\n\tterrain shallows { autotile: c }\n\ttransition land, shallows {\n\t\t";
		final lines = head.split("\n");
		final items = ManimAnalyzer.getCompletions(head, lines.length - 1, lines[lines.length - 1].length);
		final labels = [for (item in items) item.label];
		LspTestRunner.assert(labels.contains("ignore") && labels.contains("autotile"), 'A tileset transition completes autotile and ignore (got ' + labels.join(", ") + ')');
		LspTestRunner.assert(!labels.contains("crossfade"), "and not a programmable transition's animations");
		final text = head + "autotile: c\n\t\tignore: sea\n\t}\n}\n";
		final ignoreLine = text.split("\n")[10];
		final hover = hoverText(text, 10, ignoreLine.indexOf("ignore") + 2);
		LspTestRunner.assert(hover != null && hover.indexOf("count as `b`") >= 0, 'Hover on ignore explains it (got $hover)');
		LspTestRunner.assertEqual(ManimAnalyzer.getDiagnostics(text, "t.manim").length, 0, "ignore: sea is a terrain below shallows: no diagnostics");
		final wrong = ManimAnalyzer.getDiagnostics(StringTools.replace(text, "ignore: sea", "ignore: lava"), "t.manim");
		LspTestRunner.assert(wrong.length > 0 && wrong[0].message.indexOf("tileset has no terrain lava") >= 0 && wrong[0].range.start.line == 10,
			'An ignored terrain the tileset has not is an error on its line (got ' + (wrong.length > 0 ? wrong[0].message + " at " + wrong[0].range.start.line : "none") + ')');
	}

	/** The parser on JS (the LSP, a browser build) reads integers as HashLink does. */
	static function testIntegerLiteralsAreThirtyTwoBits():Void {
		final result = bh.multianim.MacroManimParser.parseFile("version: 1.0\n#p programmable(c:color=0xFFFF0000) {\n\tbitmap(generated(color(1, 1, $c))): 0, 0\n}", "ints.manim", null);
		final colour:Null<Int> = switch result.nodes.get("p").type {
			case PROGRAMMABLE(_, defs, _): switch defs.get("c").defaultValue {
					case Value(v): v;
					default: null;
				}
			default: null;
		};
		LspTestRunner.assertEqual(colour, -65536, "0xFFFF0000 is opaque red, the same Int on JS as on HashLink");
		final diags = ManimAnalyzer.getDiagnostics("version: 1.0\n#p programmable(n:int=99999999999) {\n\tbitmap(generated(color(1, 1, #ffffff))): 0, 0\n}", "big.manim");
		LspTestRunner.assertGreater(diags.length, 0, "an integer past 32 bits is an error, not another number per target");
		// A hex number given to a float is its number on JS too (parseFloat reads "0x10" as 0 there)
		final floats = bh.multianim.MacroManimParser.parseFile("version: 1.0\n#p programmable(f:float=0x10) {\n\tbitmap(generated(color(1, 1, #ffffff))): 0, 0\n}", "floats.manim", null);
		final f:Null<Float> = switch floats.nodes.get("p").type {
			case PROGRAMMABLE(_, defs, _): switch defs.get("f").defaultValue {
					case ValueF(v): v;
					default: null;
				}
			default: null;
		};
		LspTestRunner.assertEqual(f, 16.0, "f:float=0x10 is 16 on JS as on HashLink");
	}

	static final DOCUMENTED = "version: 1.0\n"
		+ "/// A knight that walks and stands.\n"
		+ "#knight export programmable(\n"
		+ "\t/// What the knight is doing\n"
		+ "\tstate:[idle, /// stands still\n"
		+ "\t\twalk] = idle,\n"
		+ "\thp:uint = 3 /// hit points\n"
		+ ") {\n"
		+ "\t@(state=>walk) bitmap(generated(color($hp, 10, #FF0000))): 0, 0\n"
		+ "}\n"
		+ "#helper programmable(hp:uint = 1 /// the helper's own hp\n"
		+ ") {\n"
		+ "\tbitmap(generated(color($hp, 2, #FFFFFF))): 0, 0\n"
		+ "}\n"
		+ "#plain programmable(hp:uint = 1) {\n"
		+ "\tbitmap(generated(color($hp, 2, #FFFFFF))): 0, 0\n"
		+ "}\n";

	static function hoverText(text:String, line:Int, character:Int):Null<String> {
		final hover = ManimAnalyzer.getHover(text, "test.manim", line, character);
		return hover == null ? null : hover.contents.value;
	}

	static function testExportAndDocComments():Void {
		final diags = ManimAnalyzer.getDiagnostics(DOCUMENTED, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "A file with export and /// docs produces no diagnostics");

		var knightDetail:Null<String> = null;
		var helperDetail:Null<String> = null;
		for (s in ManimAnalyzer.getSymbols(DOCUMENTED, "test.manim")) {
			if (s.name == "knight") knightDetail = s.detail;
			if (s.name == "helper") helperDetail = s.detail;
		}
		LspTestRunner.assert(knightDetail != null && StringTools.startsWith(knightDetail, "export"), 'An exported block says so in the outline (got $knightDetail)');
		LspTestRunner.assert(helperDetail == null || !StringTools.startsWith(helperDetail, "export"), "A block not exported does not");

		final misplaced = ManimAnalyzer.getDiagnostics("version: 1.0\n#a programmable() {\n\t#b export bitmap(generated(color(2, 2, #FF0000))): 0, 0\n}", "test.manim");
		LspTestRunner.assertGreater(misplaced.length, 0, "export on an element inside a block is an error");
	}

	static function testExportKeywordCompletionAndHover():Void {
		var hasExport = false;
		for (item in ManimAnalyzer.getCompletions("version: 1.0\n", 1, 0))
			if (item.label == "export") hasExport = true;
		LspTestRunner.assert(hasExport, "Top-level completions include 'export'");

		// line 2 is "#knight export programmable(": "export" at characters 8..13
		final hover = hoverText(DOCUMENTED, 2, 10);
		LspTestRunner.assert(hover != null && hover.indexOf("Marks a root block as exported") >= 0, 'Hover on export explains it (got $hover)');
	}

	static function testDocCommentHover():Void {
		final lines = DOCUMENTED.split("\n");
		final block = hoverText(DOCUMENTED, 2, 3); // on "#knight"
		LspTestRunner.assert(block != null && block.indexOf("A knight that walks and stands.") >= 0, 'Hover on a block shows its /// doc (got $block)');
		LspTestRunner.assert(block != null && block.indexOf("exported") >= 0, "and that it is exported");
		LspTestRunner.assert(block != null && block.indexOf("hit points") >= 0, "and its parameters' docs");

		final bodyLine = 8; // "\t@(state=>walk) bitmap(generated(color($hp, ..."
		final hpRef = hoverText(DOCUMENTED, bodyLine, lines[bodyLine].indexOf("$hp") + 2);
		LspTestRunner.assert(hpRef != null && hpRef.indexOf("hit points") >= 0, 'Hover on $$hp shows the parameter\'s doc (got $hpRef)');

		final hpDecl = hoverText(DOCUMENTED, 6, 2); // "\thp:uint = 3 /// hit points"
		LspTestRunner.assert(hpDecl != null && hpDecl.indexOf("hit points") >= 0, 'Hover on a parameter where it is declared shows its doc (got $hpDecl)');

		final stateDecl = hoverText(DOCUMENTED, 4, 3); // "\tstate:[idle, /// stands still"
		LspTestRunner.assert(stateDecl != null && stateDecl.indexOf("What the knight is doing") >= 0, 'Hover on an enum parameter shows its doc (got $stateDecl)');
		LspTestRunner.assert(stateDecl != null && stateDecl.indexOf("stands still") >= 0, "and its choices' docs");

		final idle = hoverText(DOCUMENTED, 4, lines[4].indexOf("idle") + 1);
		LspTestRunner.assert(idle != null && idle.indexOf("stands still") >= 0, 'Hover on a choice shows its doc (got $idle)');

		final helperLine = 12; // "\tbitmap(generated(color($hp, 2, ..." in #helper
		final helperHp = hoverText(DOCUMENTED, helperLine, lines[helperLine].indexOf("$hp") + 2);
		LspTestRunner.assert(helperHp != null && helperHp.indexOf("the helper's own hp") >= 0 && helperHp.indexOf("hit points") < 0,
			'Hover on $$hp in another block shows that block\'s parameter (got $helperHp)');

		final plainLine = 15; // "\tbitmap(generated(color($hp, 2, ..." in #plain, no docs
		final plainHp = hoverText(DOCUMENTED, plainLine, lines[plainLine].indexOf("$hp") + 2);
		LspTestRunner.assert(plainHp != null && plainHp.indexOf("**Parameter**") >= 0, 'A parameter without a doc keeps the plain hover (got $plainHp)');
	}

	static function testSoundDocHover():Void {
		final text = "version: 1.0\n#fx sounds {\n\t/// a sword hitting armour\n\thit { file: \"hit.wav\" }\n}\n#tunes music {\n\t/// the title theme\n\ttrack title { file: \"title.mp3\" }\n}\n";
		final hit = hoverText(text, 3, 2); // "\thit { …"
		LspTestRunner.assert(hit != null && hit.indexOf("a sword hitting armour") >= 0 && hit.indexOf("sound of") >= 0, 'Hover on a sound shows its /// doc (got $hit)');
		final title = hoverText(text, 7, 9); // "\ttrack title { …"
		LspTestRunner.assert(title != null && title.indexOf("the title theme") >= 0 && title.indexOf("track of") >= 0, 'Hover on a track shows its /// doc (got $title)');
	}

	static function testValidFileNoDiagnostics():Void {
		final text = "version: 1.0\n#test programmable(status:[normal,hover]=normal) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}";
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "Valid .manim produces no diagnostics");
	}

	static function testInvalidFileDiagnostics():Void {
		final text = "version: 1.0\n#test programmable() {\n\tunknownElement(\n}";
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertGreater(diags.length, 0, "Invalid .manim produces diagnostics");
		LspTestRunner.assertEqual(diags[0].severity, DiagnosticSeverity.Error, "Diagnostic is error severity");
	}

	static function testSymbols():Void {
		final text = "version: 1.0\n#myWidget programmable(count:int=0) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}\n#myData data {\n\tkey: 42\n}\n@final MAX_SIZE = 100";
		final syms = ManimAnalyzer.getSymbols(text, "test.manim");
		LspTestRunner.assertGreater(syms.length, 0, "Symbols extracted from valid .manim");

		var foundProg = false;
		var foundData = false;
		var foundFinal = false;
		for (s in syms) {
			if (s.name == "myWidget" && s.kind == SymbolKind.Class) foundProg = true;
			if (s.name == "myData" && s.kind == SymbolKind.Struct) foundData = true;
			if (s.name == "MAX_SIZE" && s.kind == SymbolKind.Constant) foundFinal = true;
		}
		LspTestRunner.assert(foundProg, "Symbol: programmable 'myWidget' found as Class");
		LspTestRunner.assert(foundData, "Symbol: data 'myData' found as Struct");
		LspTestRunner.assert(foundFinal, "Symbol: @final 'MAX_SIZE' found as Constant");
	}

	static function testCompletions():Void {
		final text = "version: 1.0\n";
		final items = ManimAnalyzer.getCompletions(text, 1, 0);
		LspTestRunner.assertGreater(items.length, 0, "Top-level completions returned");

		var hasProgrammable = false;
		for (item in items) {
			if (item.label == "programmable") hasProgrammable = true;
		}
		LspTestRunner.assert(hasProgrammable, "Top-level completions include 'programmable'");
	}

	static function testReferenceCompletionLabels():Void {
		// Each declared parameter must complete as "$<paramName>". A string-
		// interpolation escape bug ('$$name' == literal "$name") once labeled
		// every parameter completion with the same literal string.
		final text = "version: 1.0\n#w programmable(hp:int=0, mode:[a,b]=a) {\n\tbitmap(generated(color($";
		final lines = text.split("\n");
		final items = ManimAnalyzer.getCompletions(text, 2, lines[2].length);
		LspTestRunner.assertGreater(items.length, 0, "Reference completions returned after '$'");

		var hasHp = false;
		var hasMode = false;
		var hasLiteralName = false;
		for (item in items) {
			if (item.label == "$hp") hasHp = true;
			if (item.label == "$mode") hasMode = true;
			if (item.label == "$name") hasLiteralName = true;
		}
		LspTestRunner.assert(hasHp, "Reference completions include '$hp' for param hp");
		LspTestRunner.assert(hasMode, "Reference completions include '$mode' for param mode");
		LspTestRunner.assert(!hasLiteralName, "No completion may carry the literal label '$name'");
	}

	static function testPathCompletionsSuggestOnlyParserKeywords():Void {
		// Every suggested path command must be accepted by the parser.
		// "quadratic" is not a parser keyword — quadratic curves are the
		// 2-point form of bezier(...).
		final text = "version: 1.0\npaths {\n\t\n}";
		final items = ManimAnalyzer.getCompletions(text, 2, 1);
		LspTestRunner.assertGreater(items.length, 0, "Path completions returned inside paths block");

		var hasQuadratic = false;
		var hasBezier = false;
		for (item in items) {
			if (item.label == "quadratic") hasQuadratic = true;
			if (item.label == "bezier") hasBezier = true;
		}
		LspTestRunner.assert(hasBezier, "Path completions include 'bezier'");
		LspTestRunner.assert(!hasQuadratic, "'quadratic' is not parseable and must not be suggested");
	}

	static function testHover():Void {
		final text = "version: 1.0\nprogrammable";
		final hover = ManimAnalyzer.getHover(text, "test.manim", 1, 5);
		LspTestRunner.assert(hover != null, "Hover returned for 'programmable' keyword");
	}

	/** stateanim's frame:, progress: and hide => [...]: parsed without diagnostics, explained on hover. */
	static function testStateAnimArguments():Void {
		final text = "version: 1.0\n"
			+ "#fig programmable(k:int=0) {\n"
			+ "\tstateanim(\"hero.anim\", \"walk\", direction=>l, frame: $k, hide => [weapon_front, weapon_back]): 0, 0\n"
			+ "\tstateanim(\"hero.anim\", \"walk\", progress: 0.5): 0, 0\n"
			+ "}\n"
			+ "#p programmable() {\n"
			+ "\tstaticRef(fig, hide => [weapon_front]): 0, 0\n"
			+ "}\n";
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "frame:, progress: and hide => [...] parse with no diagnostics");
		final lines = text.split("\n");
		final frame = hoverText(text, 2, lines[2].indexOf("frame") + 1);
		LspTestRunner.assert(frame != null && frame.indexOf("seekFrame") >= 0, 'Hover on frame explains it (got $frame)');
		final hide = hoverText(text, 2, lines[2].indexOf("hide") + 1);
		LspTestRunner.assert(hide != null && hide.indexOf("layers") >= 0, 'Hover on hide explains it (got $hide)');
		final progress = hoverText(text, 3, lines[3].indexOf("progress") + 1);
		LspTestRunner.assert(progress != null && progress.indexOf("seekProgress") >= 0, 'Hover on progress explains it (got $progress)');
		final twice = ManimAnalyzer.getDiagnostics("version: 1.0\n#p programmable() {\n\tstateanim(\"a.anim\", \"s\", frame: 1, progress: 0.5): 0, 0\n}", "test.manim");
		LspTestRunner.assertGreater(twice.length, 0, "frame: and progress: together are an error");
	}

	static function testDataEnumSymbols():Void {
		final text = 'version: 1.0\n#items data {\n\t#rarity enum(common, rare, legendary)\n\t#stats record(hp:int, atk:int)\n\tname: "sword"\n\tgrade: rarity common\n}';
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "Data block with enum produces no diagnostics");

		final syms = ManimAnalyzer.getSymbols(text, "test.manim");
		var foundData = false;
		var foundEnum = false;
		var foundRecord = false;
		var foundField = false;
		for (s in syms) {
			if (s.name == "items" && s.kind == SymbolKind.Struct) {
				foundData = true;
				if (s.children != null) {
					for (c in s.children) {
						if (c.name == "#rarity" && c.kind == SymbolKind.Enum) foundEnum = true;
						if (c.name == "#stats" && c.kind == SymbolKind.Struct) foundRecord = true;
						if (c.name == "name" && c.kind == SymbolKind.Field) foundField = true;
					}
				}
			}
		}
		LspTestRunner.assert(foundData, "Symbol: data 'items' found");
		LspTestRunner.assert(foundEnum, "Symbol: enum '#rarity' found as child of data");
		LspTestRunner.assert(foundRecord, "Symbol: record '#stats' found as child of data");
		LspTestRunner.assert(foundField, "Symbol: field 'name' found as child of data");
	}

	static function testDefinition():Void {
		final text = "version: 1.0\n#test programmable(myParam:int=0) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}";
		// Try go-to-definition — should not crash
		final loc = ManimAnalyzer.getDefinition(text, "test.manim", 2, 29);
		LspTestRunner.assert(true, "Definition lookup does not crash");
	}
}
