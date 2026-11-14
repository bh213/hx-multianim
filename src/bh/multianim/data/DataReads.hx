package bh.multianim.data;

/**
	The reads a `@:data` class counted of its values, when it counts them (`-D manim_data_reads`
	for every `@:data` of the build, or `reads` in one's `@:data`): what a tool asks to know which
	numbers a play really read. Each object of the data (the class itself, and each record in it,
	in an array or a table's row) is tracked at its path, `fear` or `all[agree]`, with a count for
	each of its fields; a field whose value is a record (or an array of them) is never counted, its
	record's fields are. So `readsSince()` says `fear.seconds`, `all[agree].cost`, `tiers[1].name`,
	`maxLevel`.

	The generated class has `readsSince()` and `resetReads()` whether it counts or not: without
	counting they say nothing, and its fields are plain finals as ever.
**/
class DataReads {
	final paths:Array<String> = [];
	final names:Array<Array<String>> = [];
	final counts:Array<Array<Int>> = [];

	public function new() {}

	/**
		Counts kept from now for the object at `path` ("" the class itself), a count a field of
		`fields`, in their order: the array the object's getters add one to.
	**/
	public function track(path:String, fields:Array<String>):Array<Int> {
		final c = [for (_ in fields) 0];
		paths.push(path);
		names.push(fields);
		counts.push(c);
		return c;
	}

	/** The field paths read since the last `reset`, with how many times; a path read of two copies of the data, the two added. **/
	public function since():Map<String, Int> {
		final out = new Map<String, Int>();
		for (i in 0...paths.length) {
			final c = counts[i];
			final n = names[i];
			final p = paths[i];
			for (j in 0...c.length) {
				if (c[j] <= 0)
					continue;
				final key = p == "" ? n[j] : p + "." + n[j];
				final had = out.get(key);
				out.set(key, (had == null ? 0 : had) + c[j]);
			}
		}
		return out;
	}

	/** Every count back to nothing. **/
	public function reset():Void {
		for (c in counts)
			for (j in 0...c.length)
				c[j] = 0;
	}
}
