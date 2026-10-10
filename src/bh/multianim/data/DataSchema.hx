package bh.multianim.data;

import bh.multianim.MultiAnimParser.DataDef;
import bh.multianim.MultiAnimParser.DataFieldDef;
import bh.multianim.MultiAnimParser.DataMeta;
import bh.multianim.MultiAnimParser.DataPickDef;
import bh.multianim.MultiAnimParser.DataRecordDef;
import bh.multianim.MultiAnimParser.DataValue;
import bh.multianim.MultiAnimParser.DataValueType;

/** Where a table, a pick or a tree of a game's data comes from: a data block of a .manim file, or
	the game's own code, which built it and registered it (`DataRegistry.registerTable`). **/
typedef DataSource = {
	/** The .manim file, and the data block and the line in it. **/
	var ?manim:String;
	var ?block:String;
	/** The code that registered it: its file, class and method. **/
	var ?code:String;
	var ?className:String;
	var ?method:String;
	var line:Int;
}

/** A column of a table as a tool reads it. **/
typedef DataColumn = {
	var id:String;
	/** int, float, string, bool, enum, record or ref: of each value, when it is a list. **/
	var type:String;
	/** A row may leave it out. **/
	var ?optional:Bool;
	/** A list of values, not one. **/
	var ?many:Bool;
	/** The field rows are found by. **/
	var ?key:Bool;
	/** A whole number. **/
	var ?whole:Bool;
	/** An enum's values. **/
	var ?options:Array<String>;
	/** The enum, the record, or for a ref the record whose rows it names. **/
	var ?to:String;
	/** A record's own columns. **/
	var ?columns:Array<DataColumn>;
	/** Its `@unit(…)`. **/
	var ?unit:String;
	/** Its annotations, by name: `@range(0, 3)` is range: [0, 3], `@unit("energy")` is unit: "energy",
		`@whole` is whole: true. **/
	var ?meta:Dynamic;
}

/** What a table knows of itself besides its rows: its columns, where it is, the annotations of
	its field and of each row, and the record its rows are. **/
typedef DataTableInfo = {
	var ?columns:Array<DataColumn>;
	var ?source:DataSource;
	/** Each row's annotations, in the rows' order: `@by(claude) { … }` is {by: "claude"}. **/
	var ?rowMeta:Array<Dynamic>;
	/** The field's own annotations: `@says("…") all: card[] […]`. **/
	var ?meta:Dynamic;
	/** The record its rows are: a ref to it in its own rows makes it a tree. **/
	var ?record:String;
}

/** How a pick draws, besides the table and the share of each row. **/
typedef DataPickInfo = {
	/** The column the odds are read from, and the ref field it is read through, if any. **/
	var by:String;
	var ?through:String;
	/** By chance (each row at its chance, the otherwise row with what is left); else by weight. **/
	var chance:Bool;
	var ?draws:Int;
	var ?repeats:Bool;
	var ?otherwise:String;
	var ?source:DataSource;
	var ?meta:Dynamic;
}

/**
	What a data block says of its tables, for the code that reads and makes them: the parser's
	checks, `@:data` at compile time, `getData` at runtime, all from the same parse. No Heaps here,
	so each of them can use it.
**/
class DataSchema {
	/** The columns of a record, in its order; a record-typed column has the record's own. **/
	public static function columnsOf(def:DataRecordDef, data:DataDef):Array<DataColumn> {
		final columns:Array<DataColumn> = [];
		for (f in def.fields) {
			var type = f.type;
			var many = false;
			switch (type) {
				case DVTArray(e):
					many = true;
					type = e;
				default:
			}
			final column:DataColumn = {id: f.name, type: typeName(type)};
			if (many) column.many = true;
			if (f.optional) column.optional = true;
			if (f.key == true) column.key = true;
			switch (type) {
				case DVTInt:
					column.whole = true;
				case DVTEnum(e):
					column.to = e;
					final values = data.enums.get(e);
					if (values != null) column.options = values.values.copy();
				case DVTRecord(r):
					column.to = r;
					// A record is defined before a record that holds it, so this ends.
					final nested = data.records.get(r);
					if (nested != null) column.columns = columnsOf(nested, data);
				case DVTRef(r):
					column.to = r;
				default:
			}
			final meta = metaObject(f.meta);
			if (meta != null) {
				column.meta = meta;
				final unit:Dynamic = Reflect.field(meta, "unit");
				if (unit != null) column.unit = Std.string(unit);
			}
			columns.push(column);
		}
		return columns;
	}

	static function typeName(type:DataValueType):String {
		return switch (type) {
			case DVTInt: "int";
			case DVTFloat: "float";
			case DVTString: "string";
			case DVTBool: "bool";
			case DVTEnum(_): "enum";
			case DVTRecord(_): "record";
			case DVTRef(_): "ref";
			case DVTArray(e): typeName(e);
		};
	}

	/** Annotations as an object: with no argument an annotation is true, with one its value, with more a list. **/
	public static function metaObject(meta:Null<Array<DataMeta>>):Null<Dynamic> {
		if (meta == null || meta.length == 0) return null;
		final result:Dynamic = {};
		for (m in meta) {
			final value:Dynamic = switch (m.args.length) {
				case 0: true;
				case 1: plainValue(m.args[0]);
				default: [for (a in m.args) plainValue(a)];
			};
			Reflect.setField(result, m.name, value);
		}
		return result;
	}

	/** Each row's annotations, in the rows' order: an empty object for a row with none. **/
	public static function rowMetaObjects(field:DataFieldDef):Null<Array<Dynamic>> {
		final rows = field.rowMeta;
		if (rows == null) return null;
		return [for (meta in rows) {
			final object = metaObject(meta);
			object == null ? {} : object;
		}];
	}

	/** A value as plain data: an enum's value and a ref's id as words, a record as an object. **/
	public static function plainValue(value:DataValue):Dynamic {
		return switch (value) {
			case DVInt(v): v;
			case DVFloat(v): v;
			case DVString(v): v;
			case DVBool(v): v;
			case DVEnumValue(_, v): v;
			case DVRef(_, id): id;
			case DVArray(elements): [for (e in elements) plainValue(e)];
			case DVRecord(_, fields):
				final object:Dynamic = {};
				for (name => v in fields)
					Reflect.setField(object, name, plainValue(v));
				object;
		};
	}

	/** The field of the block with this name, or null. **/
	public static function fieldNamed(data:DataDef, name:String):Null<DataFieldDef> {
		for (field in data.fields)
			if (field.name == name) return field;
		return null;
	}

	/** The record of a table field: an array of a record with a key. Null for any other field. **/
	public static function tableRecord(data:DataDef, field:DataFieldDef):Null<DataRecordDef> {
		return switch (field.type) {
			case DVTArray(DVTRecord(r)):
				final def = data.records.get(r);
				def != null && def.key != null ? def : null;
			default: null;
		};
	}

	/** Every table of a record in the block, in the block's order: a ref to the record names a row of one of them. **/
	public static function tablesOf(data:DataDef, recordName:String):Array<DataFieldDef> {
		final tables:Array<DataFieldDef> = [];
		for (field in data.fields) {
			final def = tableRecord(data, field);
			if (def != null && def.name == recordName) tables.push(field);
		}
		return tables;
	}

	/** The values of an array field: a table's rows. **/
	public static function rowsOf(field:DataFieldDef):Array<DataValue> {
		return switch (field.value) {
			case DVArray(rows): rows;
			default: [];
		};
	}

	/** A row's id, by its record's key. Null for a value that is not a row with one. **/
	public static function rowId(row:DataValue, def:DataRecordDef):Null<String> {
		final key = def.key;
		if (key == null) return null;
		return switch (row) {
			case DVRecord(_, fields):
				switch (fields.get(key)) {
					case DVString(id): id;
					default: null;
				}
			default: null;
		};
	}

	/** The record of the table a pick draws from, or null when `over` is not a table. **/
	public static function overRecord(data:DataDef, pick:DataPickDef):Null<DataRecordDef> {
		final table = fieldNamed(data, pick.over);
		return table == null ? null : tableRecord(data, table);
	}

	/** The record a pick reads its number from through a ref field (`weight: tier.weight` is tier):
		null when it reads the table's own rows, or when there is no such ref field. **/
	public static function throughRecord(data:DataDef, pick:DataPickDef):Null<String> {
		final through = pick.through;
		final over = overRecord(data, pick);
		if (through == null || over == null) return null;
		for (f in over.fields)
			if (f.name == through)
				switch (f.type) {
					case DVTRef(r): return r;
					default:
				}
		return null;
	}

	/** What a table field knows of itself besides its rows, as `new DataTable` takes it. **/
	public static function tableInfo(data:DataDef, field:DataFieldDef, record:DataRecordDef, manim:Null<String>, block:String):DataTableInfo {
		final info:DataTableInfo = {
			columns: columnsOf(record, data),
			source: {manim: manim, block: block, line: field.line != null ? field.line : 0},
			record: record.name,
		};
		final rowMeta = rowMetaObjects(field);
		if (rowMeta != null) info.rowMeta = rowMeta;
		final meta = metaObject(field.meta);
		if (meta != null) info.meta = meta;
		return info;
	}

	/** How a pick draws, besides its table and each row's share, as `new DataPick` takes it. **/
	public static function pickInfo(pick:DataPickDef, manim:Null<String>, block:String):DataPickInfo {
		final info:DataPickInfo = {
			by: pick.by,
			chance: pick.chance,
			draws: pick.draws,
			repeats: pick.repeats,
			source: {manim: manim, block: block, line: pick.line},
		};
		if (pick.through != null) info.through = pick.through;
		if (pick.otherwise != null) info.otherwise = pick.otherwise;
		final meta = metaObject(pick.meta);
		if (meta != null) info.meta = meta;
		return info;
	}
}
