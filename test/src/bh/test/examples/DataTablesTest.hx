package bh.test.examples;

import utest.Assert;
import bh.multianim.MultiAnimParser;
import bh.multianim.data.DataPick;
import bh.multianim.data.DataRandom;
import bh.multianim.data.DataRegistry;
import bh.multianim.data.DataTable;
import bh.test.CardsCardId;
import bh.test.CardsCategory;
import bh.test.CardsTierId;

/**
	Tables, picks and trees in data blocks (test/examples/62-dataBlock/dataTables.manim): rows found
	by id, refs between rows, annotations on fields and rows, defaults, and how a table is drawn
	from, through `@:data` and through `getData`; what the parser refuses; and DataRegistry, which
	the DevBridge answers data_list, data_get and data_pick from.
**/
class DataTablesTest extends utest.Test {
	static final FILE = "test/examples/62-dataBlock/dataTables.manim";

	function typed() {
		return new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false)).cardsData;
	}

	function dynamicData():Dynamic {
		final content = byte.ByteData.ofString(sys.io.File.getContent(FILE));
		final builder = bh.multianim.MultiAnimBuilder.load(content, bh.test.TestResourceLoader.createLoader(false), FILE);
		return builder.getData("cards");
	}

	static function parseExpectingError(source:String):Null<String> {
		try {
			MultiAnimParser.parseFile(byte.ByteData.ofString('version: 1.0\n$source'), "test-input",
				new bh.base.ResourceLoader.CachingResourceLoader());
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function lineHere(?pos:haxe.PosInfos):Int {
		return pos.lineNumber;
	}

	static function assertError(source:String, words:String, ?pos:haxe.PosInfos):Void {
		final error = parseExpectingError(source);
		Assert.notNull(error, 'should be refused: $words', pos);
		if (error != null) Assert.isTrue(error.indexOf(words) >= 0, 'error should say "$words", got: $error', pos);
	}

	// ==================== @:data, typed ====================

	@Test
	public function testTypedTableFindsRowsById():Void {
		final cards = typed();
		Assert.equals(4, cards.all.length);
		Assert.equals("Agree in principle", cards.all.get(CardsCardId.Agree).name);
		Assert.equals(CardsCategory.Chaos, cards.all.get("flip").category);
		Assert.isNull(cards.all.get("nobody"));
		// An id a word cannot be is a string in the file, and a constant of its own.
		Assert.equals("1-on-1", CardsCardId.Id1On1);
		Assert.equals("One on one", cards.all.get(CardsCardId.Id1On1).name);
		// Of any other character a quoted id holds, only letters and digits make the constant's name.
		Assert.equals("very rare!", CardsTierId.VeryRare);
		Assert.same(["agree", "nod-along", "flip", "1-on-1"], cards.all.ids());
	}

	@Test
	public function testTypedDefaultsAndRefs():Void {
		final cards = typed();
		// A field a row leaves out takes its @default.
		Assert.equals(0, cards.all.get("nod-along").starter);
		Assert.floatEquals(1.0, cards.all.get("1-on-1").weight);
		// A ref is the id of the row it names.
		Assert.same(["agree", "nod-along"], cards.all.get("flip").requires);
		Assert.equals("rare", cards.relics.get("crown").tier);
		Assert.equals(1, cards.tiers.get(cards.relics.get("crown").tier).weight);
	}

	@Test
	public function testTypedPickByWeightIsSeeded():Void {
		final cards = typed();
		Assert.equals(2, cards.reward.draws);
		// The draws this algorithm makes from these seeds with the JavaScript mulberry32.
		Assert.same(["agree", "nod-along"], [for (c in cards.reward.draw(new DataRandom(7).float)) c.id]);
		Assert.same(["agree", "1-on-1"], [for (c in cards.reward.draw(new DataRandom(11).float)) c.id]);
		// Without repeats a draw holds each row once; a weight of 0 never comes up.
		final random = new DataRandom(3).float;
		for (_ in 0...200) {
			final drawn = [for (c in cards.reward.draw(3, random)) c.id];
			Assert.equals(3, drawn.length);
			Assert.equals(-1, drawn.indexOf("flip"));
			Assert.isTrue(drawn[0] != drawn[1] && drawn[1] != drawn[2] && drawn[0] != drawn[2]);
		}
	}

	@Test
	public function testTypedPickComesUpAsItsOddsSay():Void {
		final cards = typed();
		final odds = cards.reward.odds();
		Assert.floatEquals(0.6, odds.chances.get("agree"));
		Assert.floatEquals(0.2, odds.chances.get("nod-along"));
		Assert.floatEquals(0.0, odds.chances.get("flip"));
		Assert.floatEquals(0.2, odds.chances.get("1-on-1"));
		final counts:Map<String, Int> = new Map();
		final random = new DataRandom(2026).float;
		final n = 10000;
		for (_ in 0...n) {
			final id = cards.reward.pick(random).id;
			counts.set(id, (counts.exists(id) ? counts.get(id) : 0) + 1);
		}
		for (id => chance in odds.chances) {
			final seen = (counts.exists(id) ? counts.get(id) : 0) / n;
			Assert.isTrue(Math.abs(seen - chance) < 0.01, '$id came up ${seen}, its odds are $chance');
		}
	}

	@Test
	public function testTypedPickByChanceAndThroughALink():Void {
		final cards = typed();
		final loot = cards.lootPick.odds();
		Assert.floatEquals(0.5, loot.chances.get("coin"));
		Assert.floatEquals(0.2, loot.chances.get("gem"));
		// The otherwise row takes what the others leave.
		Assert.floatEquals(0.3, loot.chances.get("nothing"));
		Assert.floatEquals(0.0, loot.nothing);
		// By the weight of the tier each relic links to: common 6, rare 1, and legendary 13 from the
		// second table of tiers.
		final relics = cards.relicPick.odds();
		Assert.floatEquals(6 / 26, relics.chances.get("amulet"));
		Assert.floatEquals(1 / 26, relics.chances.get("crown"));
		Assert.floatEquals(13 / 26, relics.chances.get("halo"));
		Assert.equals(5, cards.relicPick.draw(5, new DataRandom(9).float).length);
		// The ids of every table of a record are its constants.
		Assert.equals("legendary", CardsTierId.Legendary);
	}

	@Test
	public function testSameRandomAsJavaScriptMulberry32():Void {
		// The usual JavaScript mulberry32(42) gives these.
		final random = new DataRandom(42);
		Assert.floatEquals(0.601103751920, random.float(), 1e-9);
		Assert.floatEquals(0.448290558998, random.float(), 1e-9);
		Assert.floatEquals(0.852465793490, random.float(), 1e-9);
	}

	// ==================== getData, Dynamic ====================

	@Test
	public function testDynamicTableAndPick():Void {
		final data = dynamicData();
		final all:DataTable<Dynamic> = data.all;
		Assert.equals(4, all.length);
		Assert.equals("basic", all.get("agree").category);
		Assert.equals(0, all.get("nod-along").starter);
		Assert.same(["agree", "nod-along"], all.get("flip").requires);
		final reward:DataPick<Dynamic> = data.reward;
		Assert.same(["agree", "nod-along"], [for (c in reward.draw(new DataRandom(7).float)) c.id]);
		final relicPick:DataPick<Dynamic> = data.relicPick;
		Assert.floatEquals(1 / 26, relicPick.odds().chances.get("crown"));
		// A tier from the second table of tiers.
		Assert.floatEquals(13 / 26, relicPick.odds().chances.get("halo"));
	}

	// ==================== DataRegistry: what the DevBridge reads ====================

	@Test
	public function testRegistryListsWhereEachIs():Void {
		DataRegistry.clear();
		dynamicData();
		final list = DataRegistry.list();
		final names = [for (e in list) e.name];
		Assert.same([
			"cards.all", "cards.loot", "cards.lootPick", "cards.moreTiers", "cards.relicPick", "cards.relics", "cards.reward", "cards.tiers"
		], names);
		final all:Dynamic = list[0];
		// A card names the cards it requires: its table is a tree.
		Assert.equals("tree", all.kind);
		Assert.equals(4, all.rows);
		Assert.equals(FILE, all.source.manim);
		Assert.equals("cards", all.source.block);
		Assert.equals(12, all.source.line);
		Assert.equals("every card a meeting can deal", all.says);
		final pick:Dynamic = list[6];
		Assert.equals("pick", pick.kind);
		Assert.equals("cards.all", pick.over);
		Assert.equals(19, pick.source.line);
	}

	@Test
	public function testRegistryGivesRowsColumnsEdgesAndOdds():Void {
		DataRegistry.clear();
		typed();
		final all:Dynamic = DataRegistry.get("cards.all");
		Assert.notNull(all);
		// Rows as plain data: an enum's value as its word, whatever the typed rows hold.
		final rows:Array<Dynamic> = all.rows;
		Assert.equals("chaos", rows[2].category);
		Assert.same(["agree", "nod-along"], rows[2].requires);
		final cost:Dynamic = [for (c in (all.columns : Array<Dynamic>)) if (c.id == "cost") c][0];
		Assert.equals("int", cost.type);
		Assert.equals("energy", cost.unit);
		Assert.same([0, 3], cost.meta.range);
		final category:Dynamic = [for (c in (all.columns : Array<Dynamic>)) if (c.id == "category") c][0];
		Assert.same(["basic", "catalog", "chaos"], category.options);
		// An annotation whose arguments are a number and a string compiles, and reads as written.
		final weight:Dynamic = [for (c in (all.columns : Array<Dynamic>)) if (c.id == "weight") c][0];
		Assert.same([2, "by hand"], weight.meta.tuned);
		// A row's annotations, by its id.
		Assert.equals("claude", Reflect.field(all.rowMeta, "nod-along").by);
		Assert.equals("read from the game", Reflect.field(all.rowMeta, "nod-along").note);
		// A tree's edges: each card to the cards it requires.
		Assert.equals("requires", all.tree.by);
		Assert.equals(3, (all.tree.edges : Array<Dynamic>).length);
		final loot:Dynamic = DataRegistry.get("cards.lootPick");
		Assert.equals("nothing", loot.otherwise);
		Assert.floatEquals(0.3, [for (o in (loot.odds : Array<Dynamic>)) if (o.id == "nothing") o][0].chance);
		final rolled:Dynamic = DataRegistry.roll("cards.reward", 7);
		Assert.same(["agree", "nod-along"], rolled.picked);
		Assert.isNull(DataRegistry.get("cards.nothing-here"));
		// A record inside a row is read by its own columns: its enum as the file writes it (deep_red,
		// not the Haxe constructor's DeepRed lower-cased).
		final relics:Dynamic = DataRegistry.get("cards.relics");
		Assert.equals("deep_red", (relics.rows : Array<Dynamic>)[0].look.shade);
		Assert.equals(2, (relics.rows : Array<Dynamic>)[0].look.shine);
		final look:Dynamic = [for (c in (relics.columns : Array<Dynamic>)) if (c.id == "look") c][0];
		Assert.same(["deep_red", "pale_gold"], (look.columns : Array<Dynamic>)[0].options);
	}

	@Test
	public function testSameBlockTwiceInAPackageSharesItsIds():Void {
		// Both @:data of the block, merged into bh.test.merged: one ids class, one record type.
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final row:bh.test.merged.CardsCard = mp.cardsMerged2.all.get(bh.test.merged.CardsCardId.Agree);
		Assert.equals(mp.cardsMerged.all.get(bh.test.merged.CardsCardId.Agree).name, row.name);
	}

	@Test
	public function testRegistryTakesATableBuiltInCode():Void {
		DataRegistry.clear();
		final line = lineHere() + 1;
		DataRegistry.registerTable("Weapons", () -> [{id: "laser", damage: 4}, {id: "cannon", damage: 9}], {says: "the guns"});
		final entry:Dynamic = DataRegistry.list()[0];
		Assert.equals("Weapons", entry.name);
		Assert.equals(2, entry.rows);
		// Where it is: this file and the line of the call that registered it.
		Assert.isTrue(Std.string(entry.source.code).indexOf("DataTablesTest.hx") >= 0, 'source: ${entry.source.code}');
		Assert.equals(line, entry.source.line);
		Assert.equals("testRegistryTakesATableBuiltInCode", entry.source.method);
		final got:Dynamic = DataRegistry.get("Weapons");
		Assert.equals(9, (got.rows : Array<Dynamic>)[1].damage);
		Assert.equals("the guns", got.says);
	}

	// ==================== What the parser refuses ====================

	@Test
	public function testRefusesAnIdTwice():Void {
		assertError("#d data {\n #r record(key id, n: int)\n t: r[] [ { id: a, n: 1 } { id: a, n: 2 } ]\n}", '"a" is the id of two rows of r');
	}

	@Test
	public function testRefusesARefToNoRow():Void {
		assertError("#d data {\n #r record(key id, ?next: ref r)\n t: r[] [ { id: a, next: b } ]\n}", 'ref r "b": no r row has that id');
		assertError("#d data {\n #r record(key id)\n #s record(key id, of: ref r)\n t: s[] [ { id: a, of: x } ]\n}", 'has no table of r rows');
		// Two tables of the record with a row of that id: which one the ref names is not said.
		assertError("#d data {\n #r record(key id)\n #s record(key id, of: ref r)\n a: r[] [ { id: x } ]\n b: r[] [ { id: x } ]\n t: s[] [ { id: y, of: x } ]\n}",
			'a and b both have a row of that id');
		// One of them with it is enough, the second as well as the first.
		Assert.isNull(parseExpectingError("#d data {\n #r record(key id)\n #s record(key id, of: ref r)\n a: r[] [ { id: x } ]\n b: r[] [ { id: z } ]\n t: s[] [ { id: y, of: z } ]\n}"));
	}

	@Test
	public function testRefusesARefWithoutAKey():Void {
		assertError("#d data {\n #r record(name: string)\n #s record(key id, of: ref r)\n}", 'record "r" has no key');
		assertError("#d data {\n #r record(name: string, ?next: ref r)\n}", 'needs a key to name them by');
	}

	@Test
	public function testRefusesTwoKeysAndAnOptionalKey():Void {
		assertError("#d data {\n #r record(key id, key code)\n}", 'has two keys');
		assertError("#d data {\n #r record(?key id)\n}", 'a key cannot be optional');
	}

	@Test
	public function testRefusesANumberOutsideItsRange():Void {
		assertError("#d data {\n #r record(key id, cost: int @range(0, 3))\n t: r[] [ { id: a, cost: 4 } ]\n}", 'outside its @range(0, 3)');
		assertError("#d data {\n #r record(key id, name: string @range(0, 3))\n}", 'only a number has a range');
		// Before a field of the block, as before a field of a record.
		assertError("#d data {\n @range(0, 3) n: 5\n}", 'n is 5, outside its @range(0, 3)');
		assertError("#d data {\n @range(0, 3) ns: [1, 7]\n}", 'ns is 7, outside its @range(0, 3)');
		assertError("#d data {\n @range(0, 3) s: \"x\"\n}", 'only a number has a range');
		assertError("#d data {\n @step(0) n: 1\n}", 'takes one number above 0');
		assertError("#d data {\n @default(1) n: 1\n}", 'a default is for an optional field of a record');
		assertError("#d data {\n #r record(key id, w: int)\n t: r[] [ { id: a, w: 1 } ]\n @range(0, 1) p: pick(t, weight: w)\n}", 'only a number has a range');
		Assert.isNull(parseExpectingError("#d data {\n @range(0, 3) @unit(\"cards\") @owner(design) n: 2\n}"));
	}

	@Test
	public function testRefusesADefaultThatDoesNotFit():Void {
		assertError("#d data {\n #r record(key id, n: int @default(2))\n}", 'make it optional');
		assertError("#d data {\n #r record(key id, ?n: int @default(\"two\"))\n}", 'of the field\'s type');
		assertError("#d data {\n #r record(key id, ?n: int @range(0, 3) @default(5))\n}", 'outside its @range(0, 3)');
	}

	@Test
	public function testRefusesAPickThatCannotBeDrawn():Void {
		assertError("#d data {\n #r record(key id, c: float)\n t: r[] [ { id: a, c: 0.8 } { id: b, c: 0.5 } ]\n p: pick(t, chance: c)\n}", 'more than 1');
		assertError("#d data {\n #r record(name: string)\n t: r[] [ { name: \"x\" } ]\n p: pick(t, weight: w)\n}", 'is not a table');
		assertError("#d data {\n #r record(key id, w: string)\n t: r[] [ { id: a, w: \"x\" } ]\n p: pick(t, weight: w)\n}", 'is not a number');
		assertError("#d data {\n #r record(key id, w: int)\n t: r[] [ { id: a, w: 1 } ]\n p: pick(t, weight: w, otherwise: a)\n}", 'goes with chance');
		assertError("#d data {\n #r record(key id, c: float)\n t: r[] [ { id: a, c: 0.5 } ]\n p: pick(t, chance: c, otherwise: z)\n}", 'otherwise "z" is not a row');
	}

	@Test
	public function testRefusesAnnotationsWhereNoRowIs():Void {
		assertError("#d data {\n #r record(key id, xs: int[])\n t: r[] [ { id: a, xs: [ @by(claude) 1 ] } ]\n}", 'annotations go before a row');
	}

	@Test
	public function testKeepsAnnotationsItDoesNotKnow():Void {
		Assert.isNull(parseExpectingError("#d data {\n #r record(key id, n: int @tuned @owner(\"design\"))\n @whatever(1, 2) t: r[] [ @by(claude) { id: a, n: 1 } ]\n}"));
		// A field called key is still a field, not a key.
		Assert.isNull(parseExpectingError("#d data {\n #r record(key: string)\n x: r { key: \"k\" }\n}"));
	}
}
