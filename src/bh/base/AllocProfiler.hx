package bh.base;

#if hl
import hl.Profile;

/**
	Lightweight wrapper around `hl.Profile` for tracking GC allocations.

	Usage:
	```haxe
	AllocProfiler.start();
	// ... code to profile ...
	AllocProfiler.report();        // trace top allocators
	AllocProfiler.dump("out.txt"); // or write to file
	```
**/
class AllocProfiler {
	static var running:Bool = false;

	/** Start tracking allocations. Resets any previous data. **/
	public static function start(maxDepth:Int = 15) {
		Profile.reset();
		Profile.setMaxDepth(maxDepth);
		var flags = new haxe.EnumFlags<hl.Profile.TrackKind>();
		flags.set(Alloc);
		Profile.globalBits = flags;
		running = true;
	}

	/** Stop tracking. Data is preserved for `report()` / `dump()` / `getData()`. **/
	public static function stop() {
		Profile.stop();
		running = false;
	}

	/** Get raw allocation results sorted by count (default) or size. Does NOT reset. **/
	public static function getData(sortBySize:Bool = false):Array<hl.Profile.Result> {
		return Profile.getData(sortBySize, false);
	}

	/** Trace top allocation sites to stdout. **/
	public static function report(top:Int = 20, sortBySize:Bool = false) {
		var data = Profile.getData(sortBySize, false);
		var totalAllocs = 0;
		var totalBytes = 0;
		for (r in data) {
			totalAllocs += r.count;
			totalBytes += r.info;
		}
		trace('=== Allocation Report: $totalAllocs allocs, $totalBytes bytes, ${data.length} unique sites ===');
		var shown = 0;
		for (r in data) {
			if (shown >= top)
				break;
			trace('  ${r.count}x ${r.t} (${r.info} bytes)');
			for (s in r.stack)
				trace('      $s');
			shown++;
		}
		if (data.length > top)
			trace('  ... and ${data.length - top} more');
	}

	/** Dump full report to a file (delegates to `hl.Profile.dump`). Does NOT reset. **/
	public static function dump(fileName:String = "alloc-report.txt", sortBySize:Bool = true) {
		Profile.dump(fileName, sortBySize, false);
	}

	/** Reset accumulated data without stopping. **/
	public static function reset() {
		Profile.reset();
	}

	/** Measure a block: start, run `fn`, stop, return results. **/
	public static function measure(fn:() -> Void, sortBySize:Bool = false):Array<hl.Profile.Result> {
		start();
		fn();
		stop();
		return getData(sortBySize);
	}

	/** Is profiling currently active? **/
	public static inline function isRunning():Bool {
		return running;
	}
}
#else

/** Stub — allocation profiling is only available on HashLink. **/
class AllocProfiler {
	public static inline function start(maxDepth:Int = 15) {}
	public static inline function stop() {}
	public static inline function getData(sortBySize:Bool = false):Array<Dynamic> return [];
	public static inline function report(top:Int = 20, sortBySize:Bool = false) {}
	public static inline function dump(fileName:String = "alloc-report.txt", sortBySize:Bool = true) {}
	public static inline function reset() {}
	public static inline function measure(fn:() -> Void, sortBySize:Bool = false):Array<Dynamic> {
		fn();
		return [];
	}
	public static inline function isRunning():Bool return false;
}
#end
