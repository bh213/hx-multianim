package bh.test.examples;

import utest.Assert;
import bh.multianim.data.DataRegistry;

/**
	A `@:data` class counting its values' reads (hx-multianim request 13): `readsSince()` says each
	path read and how often, a record's fields by its path (a field of a field, an array's item, a
	table's row by its id), never a value that holds records; `resetReads()` starts again; a class
	that does not count says nothing; the engine's own reads (a table finding its rows, the
	DevBridge's rows) are not counted.
**/
class DataReadsTest extends utest.Test {
	function counting() {
		return new bh.test.DataReadsData(null);
	}

	static function sorted(reads:Map<String, Int>):String {
		final keys = [for (k in reads.keys()) k];
		keys.sort(Reflect.compare);
		return [for (k in keys) '$k ${reads.get(k)}'].join(", ");
	}

	public function testAValueReadIsCountedByItsPath():Void {
		final data = counting();
		final game = data.gameData;
		bh.test.DataReadsData_GameData.resetReads();
		Assert.equals("", sorted(bh.test.DataReadsData_GameData.readsSince()), "nothing read since the reset");
		var sum = 0.0;
		sum += game.maxLevel;
		sum += game.maxLevel;
		sum += game.speed;
		sum += game.defaultTier.cost;
		sum += (game.tiers[1].dmg : Float);
		sum += game.costs[2];
		Assert.equals("Flame Sword", game.sword.name);
		Assert.floatEquals(5 + 5 + 3.5 + 0 + 1.5 + 40, sum);
		Assert.equals("costs 1, defaultTier.cost 1, maxLevel 2, speed 1, sword.name 1, tiers[1].dmg 1", sorted(bh.test.DataReadsData_GameData.readsSince()),
			"a record's field by its path; never the record itself, nor the array of them");
		bh.test.DataReadsData_GameData.resetReads();
		Assert.equals("", sorted(bh.test.DataReadsData_GameData.readsSince()), "the reset starts again");
		Assert.isTrue(game.items[0].rarity == bh.test.reads.GameDataRarity.Common);
		Assert.equals("items[0].rarity 1", sorted(bh.test.DataReadsData_GameData.readsSince()));
	}

	public function testATablesRowsAreCountedByTheirIds():Void {
		final cards = counting().cards;
		bh.test.DataReadsData_Cards.resetReads();
		Assert.equals(1, cards.all.get("agree").cost, "a table finds its row by its id: not a read of the id");
		Assert.equals(2, cards.relics.get("amulet").look.shine);
		Assert.equals("all[agree].cost 1, relics[amulet].look.shine 1", sorted(bh.test.DataReadsData_Cards.readsSince()),
			"a row by its id, a record of a row by its field");
		// the DevBridge's rows read the values without counting them
		final plain:Dynamic = DataRegistry.plainRow(cards.all.get("nod-along"), []);
		Assert.equals("Nod along", plain.name);
		Assert.isFalse(Reflect.hasField(plain, "__counts"), "the counts are no value of the row");
		Assert.equals("all[agree].cost 1, relics[amulet].look.shine 1", sorted(bh.test.DataReadsData_Cards.readsSince()));
		// each class its own counts
		bh.test.DataReadsData_GameData.resetReads();
		Assert.equals("", sorted(bh.test.DataReadsData_GameData.readsSince()));
	}

	public function testAClassThatDoesNotCountSaysNothing():Void {
		final game = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false)).gameData;
		Assert.equals(5, game.maxLevel);
		Assert.equals(10, game.tiers[0].cost);
		Assert.equals("", sorted(bh.test.MultiProgrammable_GameData.readsSince()));
		bh.test.MultiProgrammable_GameData.resetReads();
		Assert.isFalse(Reflect.hasField(game.tiers[0], "__counts"), "its records keep no counts");
	}

	public function testTwoCopiesOfTheDataAddTheirReads():Void {
		final one = counting().gameData;
		final two = counting().gameData;
		bh.test.DataReadsData_GameData.resetReads();
		Assert.isTrue(one.enabled && two.enabled);
		Assert.equals("enabled 2", sorted(bh.test.DataReadsData_GameData.readsSince()));
	}

	public function testMergedRecordsCountEachValueAtItsPath():Void {
		final shapes = counting().shapes;
		bh.test.DataReadsData_Shapes.resetReads();
		Assert.equals(Type.getClass(shapes.start), Type.getClass(shapes.end), "two records of one shape are one type");
		Assert.equals(1 + 4 + 8, shapes.start.x + shapes.end.y + shapes.corners[1].x);
		Assert.equals("corners[1].x 1, end.y 1, start.x 1", sorted(bh.test.DataReadsData_Shapes.readsSince()),
			"one type, each value counted at its own path");
	}

	public function testACountingTypeIsNeverMergedWithOneThatDoesNot():Void {
		final data = counting();
		final countingType = Type.getClass(data.shapes.start);
		final plainType = Type.getClass(data.shapesPlain.start);
		Assert.notEquals(Type.getClassName(countingType), Type.getClassName(plainType), "the same shape merged without counting is a type of its own");
		Assert.isTrue(Type.getInstanceFields(countingType).contains("__counts"), "the counting type keeps counts");
		Assert.isFalse(Type.getInstanceFields(plainType).contains("__counts"), "the other keeps none");
		bh.test.DataReadsData_ShapesPlain.resetReads();
		Assert.equals(2, data.shapesPlain.start.y);
		Assert.equals("", sorted(bh.test.DataReadsData_ShapesPlain.readsSince()));
	}
}
