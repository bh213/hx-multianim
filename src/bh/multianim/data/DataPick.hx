package bh.multianim.data;

import bh.multianim.data.DataSchema.DataPickInfo;
import bh.multianim.data.DataSchema.DataSource;

/**
	How a table is drawn from: `reward: pick(all, weight: weight, draws: 3)` in a data block.

	By weight, each row comes up as often as its weight against the others; a weight of 0 or less
	never comes up. By chance, each row comes up at its chance, the `otherwise` row takes what the
	others leave, and when the chances add up to less than 1 and no row says otherwise, nothing may
	come up. A draw is several picks; unless it repeats, a row drawn is out of the pool for the rest
	of the draw. With `DataRandom` as its random, the same seed draws the same rows on every target.
**/
class DataPick<T> {
	/** `block.field`: cards.reward. **/
	public final name:String;

	public final table:DataTable<T>;

	/** The column the odds are read from, and the ref field it is read through, if any. **/
	public final by:String;

	public final through:Null<String>;
	public final chance:Bool;

	/** How many rows one draw takes. **/
	public final draws:Int;

	public final repeats:Bool;
	public final otherwise:Null<String>;
	public final source:Null<DataSource>;
	public final meta:Null<Dynamic>;

	final share:T->Float;

	/** `share` is a row's weight or chance: its own cell, or its linked row's. **/
	public function new(name:String, table:DataTable<T>, share:T->Float, info:DataPickInfo) {
		this.name = name;
		this.table = table;
		this.share = share;
		this.by = info.by;
		this.through = info.through;
		this.chance = info.chance;
		this.draws = info.draws != null ? info.draws : 1;
		this.repeats = info.repeats == true;
		this.otherwise = info.otherwise;
		this.source = info.source;
		this.meta = info.meta;
		DataRegistry.addPick(cast this);
	}

	/** A row's weight or chance, as the pick reads it. **/
	public function shareOf(row:T):Float {
		return share(row);
	}

	/** A cell as a weight or a chance: its number, 0 when the row leaves it out. **/
	public static function shareValue(cell:Dynamic):Float {
		return cell == null ? 0.0 : (cell : Float);
	}

	/**
		One row, as the odds say, from the rows `allow` lets through (all of them without it). Null
		when nothing comes up. `random` gives numbers from 0 (included) to 1 (excluded):
		`new DataRandom(seed).float` to draw the same every time; Math.random when none is given.
	**/
	public function pick(?random:Void->Float, ?allow:T->Bool):Null<T> {
		return pickFrom(pool(allow), random != null ? random : Math.random);
	}

	/**
		`n` rows (the pick's `draws` when none is given), each picked as `pick` picks. Unless the
		pick repeats, a row drawn is out of the pool for the rest of the draw. Fewer than `n` when
		the pool runs out.
	**/
	public function draw(?n:Int, ?random:Void->Float, ?allow:T->Bool):Array<T> {
		final count = n != null ? n : draws;
		final next = random != null ? random : Math.random;
		final left = pool(allow);
		final out:Array<T> = [];
		for (_ in 0...count) {
			if (left.length == 0) break;
			final row = pickFrom(left, next);
			if (row == null) {
				// Nothing can come up from weights that are all 0, now or after.
				if (!chance) break;
				continue;
			}
			out.push(row);
			if (!repeats) left.remove(row);
		}
		return out;
	}

	/** Each row's chance of being the one picked, by id, and the chance of nothing. Exact. **/
	public function odds():{chances:Map<String, Float>, nothing:Float} {
		final chances:Map<String, Float> = new Map();
		if (!chance) {
			final total = totalWeight(table.rows);
			for (row in table.rows) {
				final w = share(row);
				final id = table.idOf(row);
				if (id != null) chances.set(id, total > 0 && w > 0 ? w / total : 0.0);
			}
			return {chances: chances, nothing: total > 0 ? 0.0 : 1.0};
		}
		var left = 1.0;
		for (row in table.rows) {
			final id = table.idOf(row);
			if (id == null || id == otherwise) continue;
			final c = Math.max(0, share(row));
			chances.set(id, c);
			left -= c;
		}
		left = Math.max(0, left);
		if (otherwise != null && table.has(otherwise)) {
			chances.set(otherwise, left);
			return {chances: chances, nothing: 0.0};
		}
		return {chances: chances, nothing: left};
	}

	function pool(allow:Null<T->Bool>):Array<T> {
		return allow == null ? table.rows.copy() : table.rows.filter(allow);
	}

	/** The weights of the rows that can come up (those above 0), added. **/
	function totalWeight(rows:Array<T>):Float {
		var total = 0.0;
		for (row in rows) {
			final w = share(row);
			if (w > 0) total += w;
		}
		return total;
	}

	function pickFrom(pool:Array<T>, random:Void->Float):Null<T> {
		if (!chance) {
			final total = totalWeight(pool);
			if (total <= 0) return null;
			var r = random() * total;
			var last:Null<T> = null;
			for (row in pool) {
				final w = share(row);
				if (w <= 0) continue;
				if (r < w) return row;
				r -= w;
				last = row;
			}
			// What rounding leaves at the very end belongs to the last row that could come up.
			return last;
		}
		var r = random();
		var rest:Null<T> = null;
		for (row in pool) {
			if (otherwise != null && table.idOf(row) == otherwise) {
				if (rest == null) rest = row;
				continue;
			}
			final c = share(row);
			if (c <= 0) continue;
			if (r < c) return row;
			r -= c;
		}
		return rest;
	}
}
