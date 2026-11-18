package bh.multianim.data;

import bh.multianim.data.DataSchema.DataColumn;
import bh.multianim.data.DataSchema.DataSource;
import bh.multianim.data.DataSchema.DataTableInfo;

/**
	A table of a game's data: the rows of one record, each found by its key, in the order its data
	block writes them.

	```
	#cards data {
	    #card record(key id, name: string, cost: int @range(0, 3))
	    all: card[] [
	        { id: agree, name: "Agree in principle", cost: 1 }
	    ]
	}
	```

	`@:data` gives it typed (`DataTable<CardsCard>`), `getData` with Dynamic rows. Each table made
	is listed by `DataRegistry`, which the DevBridge answers `data_list` and `data_get` from.
**/
class DataTable<T> {
	/** `block.field`: cards.all. **/
	public final name:String;

	/** The field its rows are found by. **/
	public final key:String;

	/** Every row, in the file's order. **/
	public final rows:Array<T>;

	public final columns:Array<DataColumn>;
	public final source:Null<DataSource>;

	/** The field's own annotations (`@says("…")`), or null. **/
	public final meta:Null<Dynamic>;

	/** The record its rows are, when known. **/
	public final record:Null<String>;

	final byId:Map<String, T> = new Map();
	final metaById:Map<String, Dynamic> = new Map();

	public var length(get, never):Int;

	public function new(name:String, key:String, rows:Array<T>, ?info:DataTableInfo) {
		this.name = name;
		this.key = key;
		this.rows = rows;
		this.columns = info != null && info.columns != null ? info.columns : [];
		this.source = info != null ? info.source : null;
		this.meta = info != null ? info.meta : null;
		this.record = info != null ? info.record : null;
		final rowMeta = info != null ? info.rowMeta : null;
		for (i in 0...rows.length) {
			final id = idOf(rows[i]);
			if (id == null) continue;
			byId.set(id, rows[i]);
			if (rowMeta != null && i < rowMeta.length && rowMeta[i] != null && Reflect.fields(rowMeta[i]).length > 0)
				metaById.set(id, rowMeta[i]);
		}
		DataRegistry.addTable(cast this);
	}

	inline function get_length():Int {
		return rows.length;
	}

	/** A row's id. **/
	public function idOf(row:T):Null<String> {
		final value:Dynamic = Reflect.field(row, key);
		return value == null ? null : Std.string(value);
	}

	/** The row with this id, or null. **/
	public function get(id:Null<String>):Null<T> {
		return id == null ? null : byId.get(id);
	}

	public function has(id:String):Bool {
		return byId.exists(id);
	}

	/** Every id, in the file's order. **/
	public function ids():Array<String> {
		return [for (row in rows) Std.string(Reflect.field(row, key))];
	}

	/** A row's annotations (`@by(claude)` is {by: "claude"}), or null when it has none. **/
	public function metaOf(id:String):Null<Dynamic> {
		return metaById.get(id);
	}

	public function iterator():Iterator<T> {
		return rows.iterator();
	}

	/** The row with this id in whichever of the tables has it (the tables of one record, which a ref may name a row of), or null. **/
	public static function rowIn<R>(tables:Array<DataTable<R>>, id:Null<String>):Null<R> {
		if (id == null) return null;
		for (table in tables) {
			final row = table.byId.get(id);
			if (row != null) return row;
		}
		return null;
	}
}
