package bh.multianim.data;

import bh.multianim.data.DataSchema.DataColumn;
import bh.multianim.data.DataSchema.DataSource;

/** A table a game builds in its own code, registered with where that code is. **/
private typedef CodeTable = {
	var name:String;
	var rows:Void->Array<Dynamic>;
	var key:String;
	var ?says:String;
	var ?columns:Array<DataColumn>;
	var source:DataSource;
}

/**
	Every table, pick and tree of the game's data, with where each is: the data blocks it loaded
	(each `DataTable` and `DataPick` made from one lists itself), and the tables its own code builds
	and registers. The DevBridge answers `data_list`, `data_get` and `data_pick` from here, so a
	tool reads what the game has whether it is in a .manim file or in code:

	```haxe
	// A catalogue the game keeps in code: the registry keeps this call's file and line as its place.
	DataRegistry.registerTable("AllCards", () -> [for (c in Cards.ALL) {id: c.id, name: c.name, cost: c.cost}]);
	```

	The rows are read when they are asked for, so a registered table is always what the game has.
**/
class DataRegistry {
	static final tables:Map<String, DataTable<Dynamic>> = new Map();
	static final picks:Map<String, DataPick<Dynamic>> = new Map();
	static final coded:Map<String, CodeTable> = new Map();

	/**
		A table the game builds in its own code. `rows` gives its rows as plain objects, each with its
		id under `key` ("id" when not given); it is called whenever the table is read. Registering the
		same name again replaces it.
	**/
	public static function registerTable(name:String, rows:Void->Array<Dynamic>,
			?options:{?key:String, ?says:String, ?columns:Array<DataColumn>}, ?pos:haxe.PosInfos):Void {
		final table:CodeTable = {
			name: name,
			rows: rows,
			key: options != null && options.key != null ? options.key : "id",
			source: pos == null ? {line: 0} : {
				code: pos.fileName,
				className: pos.className,
				method: pos.methodName,
				line: pos.lineNumber
			},
		};
		if (options != null && options.says != null) table.says = options.says;
		if (options != null && options.columns != null) table.columns = options.columns;
		coded.set(name, table);
	}

	/** A table made from a data block: it lists itself. **/
	public static function addTable(table:DataTable<Dynamic>):Void {
		tables.set(table.name, table);
	}

	/** A pick made from a data block, or by code over a table: it lists itself. **/
	public static function addPick(pick:DataPick<Dynamic>):Void {
		picks.set(pick.name, pick);
	}

	/** Takes one out, by name. **/
	public static function forget(name:String):Void {
		tables.remove(name);
		picks.remove(name);
		coded.remove(name);
	}

	/** Takes everything out: for tests. **/
	public static function clear():Void {
		tables.clear();
		picks.clear();
		coded.clear();
	}

	/** Every table, pick and tree: its name, kind, size and place, by name. **/
	public static function list():Array<Dynamic> {
		final out:Array<Dynamic> = [];
		for (table in tables)
			out.push(tableEntry(table));
		for (pick in picks)
			out.push(pickEntry(pick));
		for (table in coded)
			out.push(codeEntry(table, table.rows()));
		out.sort((a, b) -> Reflect.compare(Std.string(a.name), Std.string(b.name)));
		return out;
	}

	/**
		One table, pick or tree, in full: a table's columns and its rows as plain objects (an enum's
		value and a ref's id as words), a tree's edges besides, a pick's odds. Null when there is none
		of that name. It is what `list` says of it, with its rows (in place of their count) and the rest.
	**/
	public static function get(name:String):Null<Dynamic> {
		final table = tables.get(name);
		if (table != null) {
			final entry = tableEntry(table);
			entry.columns = table.columns;
			entry.rows = [for (row in table.rows) plainRow(row, table.columns)];
			if (table.meta != null) entry.meta = table.meta;
			final rowMeta:Dynamic = {};
			var anyMeta = false;
			for (id in table.ids()) {
				final meta = table.metaOf(id);
				if (meta != null) {
					Reflect.setField(rowMeta, id, meta);
					anyMeta = true;
				}
			}
			if (anyMeta) entry.rowMeta = rowMeta;
			final tree = treeColumn(table);
			if (tree != null) entry.tree = {by: tree, edges: edgesOf(table, tree)};
			return entry;
		}
		final pick = picks.get(name);
		if (pick != null) {
			final odds = pick.odds();
			final entry = pickEntry(pick);
			entry.odds = [for (id in pick.table.ids()) {id: id, share: shareOf(pick, id), chance: odds.chances.exists(id) ? odds.chances.get(id) : 0.0}];
			entry.nothing = odds.nothing;
			return entry;
		}
		final code = coded.get(name);
		if (code != null) {
			final rows = code.rows();
			final entry = codeEntry(code, rows);
			entry.columns = code.columns != null ? code.columns : [];
			entry.rows = [for (row in rows) plain(row, null)];
			return entry;
		}
		return null;
	}

	/** What `list` says of a table made from a data block: a tree when its record names its own rows. **/
	static function tableEntry(table:DataTable<Dynamic>):Dynamic {
		final entry:Dynamic = {
			name: table.name,
			kind: treeColumn(table) != null ? "tree" : "table",
			rows: table.length,
			key: table.key,
			source: table.source,
		};
		final says = saysOf(table.meta);
		if (says != null) entry.says = says;
		return entry;
	}

	/** What `list` says of a pick: the table it draws from and how. **/
	static function pickEntry(pick:DataPick<Dynamic>):Dynamic {
		final entry:Dynamic = {
			name: pick.name,
			kind: "pick",
			over: pick.table.name,
			by: pick.through != null ? '${pick.through}.${pick.by}' : pick.by,
			chance: pick.chance,
			draws: pick.draws,
			repeats: pick.repeats,
			source: pick.source,
		};
		if (pick.otherwise != null) entry.otherwise = pick.otherwise;
		return entry;
	}

	/** What `list` says of a table registered from code, whose rows were just read. **/
	static function codeEntry(code:CodeTable, rows:Array<Dynamic>):Dynamic {
		final entry:Dynamic = {
			name: code.name,
			kind: "table",
			rows: rows.length,
			key: code.key,
			source: code.source,
		};
		if (code.says != null) entry.says = code.says;
		return entry;
	}

	/**
		`n` rows drawn by a pick (its own `draws` when not given), from a seed: what the game draws
		from the same seed with `new DataRandom(seed).float`. Null when there is no pick of that name.
	**/
	public static function roll(name:String, seed:Int, ?n:Int):Null<Dynamic> {
		final pick = picks.get(name);
		if (pick == null) return null;
		final random = new DataRandom(seed);
		final drawn = pick.draw(n, random.float);
		return {
			name: name,
			seed: seed,
			draws: n != null ? n : pick.draws,
			picked: [for (row in drawn) pick.table.idOf(row)],
		};
	}

	static function shareOf(pick:DataPick<Dynamic>, id:String):Float {
		final row = pick.table.get(id);
		return row == null ? 0.0 : pick.shareOf(row);
	}

	static function saysOf(meta:Null<Dynamic>):Null<String> {
		if (meta == null) return null;
		final says:Dynamic = Reflect.field(meta, "says");
		return says == null ? null : Std.string(says);
	}

	/** The column of a table that names its own rows: a tree's edges. **/
	static function treeColumn(table:DataTable<Dynamic>):Null<String> {
		if (table.record == null) return null;
		for (column in table.columns)
			if (column.type == "ref" && column.to == table.record) return column.id;
		return null;
	}

	/** A tree's edges: each row to each row it names. **/
	static function edgesOf(table:DataTable<Dynamic>, column:String):Array<Dynamic> {
		final edges:Array<Dynamic> = [];
		for (row in table.rows) {
			final from = table.idOf(row);
			final value:Dynamic = Reflect.field(row, column);
			if (from == null || value == null) continue;
			final targets:Array<Dynamic> = Std.isOfType(value, Array) ? value : [value];
			for (to in targets)
				if (to != null) edges.push({from: from, to: Std.string(to)});
		}
		return edges;
	}

	/** A row as a plain object, by its columns: an enum's value as its word, a nested record as an object. **/
	public static function plainRow(row:Dynamic, columns:Array<DataColumn>):Dynamic {
		if (columns.length == 0) return plain(row, null);
		final out:Dynamic = {};
		for (column in columns) {
			final value:Dynamic = Reflect.field(row, column.id);
			if (value != null) Reflect.setField(out, column.id, plain(value, column));
		}
		return out;
	}

	/** A value as plain data. A Haxe enum made from a data enum is its value, by the column's options,
		and a record inside a row is read by its own columns, so its enums are as the file writes them. **/
	static function plain(value:Dynamic, column:Null<DataColumn>):Dynamic {
		if (value == null) return null;
		if (Std.isOfType(value, String) || Std.isOfType(value, Bool) || Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return value;
		if (Std.isOfType(value, Array)) {
			final items:Array<Dynamic> = value;
			return [for (item in items) plain(item, column)];
		}
		if (Reflect.isEnumValue(value)) {
			final index = Type.enumIndex(value);
			final options = column != null ? column.options : null;
			if (options != null && index < options.length) return options[index];
			final name = Type.enumConstructor(value);
			return name.charAt(0).toLowerCase() + name.substr(1);
		}
		if (Reflect.isObject(value)) {
			final nested = column != null ? column.columns : null;
			if (nested != null) return plainRow(value, nested);
			final out:Dynamic = {};
			final cls = Type.getClass(value);
			final names = cls != null ? Type.getInstanceFields(cls) : Reflect.fields(value);
			for (n in names) {
				final v:Dynamic = Reflect.field(value, n);
				if (v != null && !Reflect.isFunction(v)) Reflect.setField(out, n, plain(v, null));
			}
			return out;
		}
		return Std.string(value);
	}
}
