package bh.test;

import sys.thread.Thread;
import sys.thread.Deque;
import sys.thread.Mutex;
import sys.thread.Lock;

using StringTools;

typedef RawPixels = {
	var bytes:haxe.io.Bytes;
	var width:Int;
	var height:Int;
}

typedef WorkItem = {
	var displayName:String;
	var orderIndex:Null<Int>;
	var referencePath:String;
	var actualPath:String;
	var ?actualPngBytes:haxe.io.Bytes;
	var ?actualRaw:RawPixels;
	var ?macroPath:String;
	var ?macroPngBytes:haxe.io.Bytes;
	var ?macroRaw:RawPixels;
	var threshold:Float;
	var ?macroThreshold:Float;
	var ?errorMessage:String;
}

typedef CompletedResult = {
	var testName:String;
	var referencePath:String;
	var actualPath:String;
	var passed:Bool;
	var similarity:Float;
	var ?errorMessage:String;
	var ?manimPath:String;
	var ?manimContent:String;
	var ?macroPath:String;
	var ?macroSimilarity:Float;
	var ?macroPassed:Bool;
	var ?threshold:Float;
	var ?macroThreshold:Float;
	var ?builderVsMacroSimilarity:Float;
	var ?orderIndex:Int;
}

class ImageProcessingPool {
	private static inline var NUM_WORKERS = 8;

	private var workQueue:Deque<WorkItem>;
	private var resultsMutex:Mutex;
	private var completedResults:Array<CompletedResult>;
	private var pendingCount:Int = 0;
	private var totalEnqueued:Int = 0;
	private var pendingMutex:Mutex;
	private var finishedLock:Lock;
	private var poisonCount:Int = 0;

	public function new() {
		workQueue = new Deque();
		resultsMutex = new Mutex();
		pendingMutex = new Mutex();
		finishedLock = new Lock();
		completedResults = [];

		for (i in 0...NUM_WORKERS) {
			Thread.create(workerLoop);
		}
	}

	public function enqueue(item:WorkItem):Void {
		pendingMutex.acquire();
		pendingCount++;
		totalEnqueued++;
		pendingMutex.release();
		workQueue.add(item);
	}

	public function shutdownAndWait():Void {
		// Send poison pills (null items)
		for (i in 0...NUM_WORKERS) {
			workQueue.add(null);
		}
		// Wait for all workers to signal done
		for (i in 0...NUM_WORKERS) {
			finishedLock.wait();
		}
	}

	public function isComplete():Bool {
		pendingMutex.acquire();
		var done = pendingCount <= 0;
		pendingMutex.release();
		return done;
	}

	public function getResults():Array<CompletedResult> {
		return completedResults;
	}

	public function getTotalEnqueued():Int {
		pendingMutex.acquire();
		var t = totalEnqueued;
		pendingMutex.release();
		return t;
	}

	public function getCompletedCount():Int {
		resultsMutex.acquire();
		var c = completedResults.length;
		resultsMutex.release();
		return c;
	}

	// ==================== Worker thread ====================

	private function workerLoop():Void {
		while (true) {
			var item:WorkItem = workQueue.pop(true);

			// Poison pill — null signals shutdown
			if (item == null) {
				finishedLock.release();
				return;
			}

			var result:CompletedResult = null;
			try {
				result = processWorkItem(item);
			} catch (e:Dynamic) {
				result = {
					testName: item.displayName,
					referencePath: item.referencePath,
					actualPath: item.actualPath,
					passed: false,
					similarity: 0.0,
					errorMessage: 'Worker exception: $e',
					orderIndex: item.orderIndex,
					threshold: item.threshold,
				};
			}

			resultsMutex.acquire();
			completedResults.push(result);
			resultsMutex.release();

			pendingMutex.acquire();
			pendingCount--;
			pendingMutex.release();
		}
	}

	private function processWorkItem(item:WorkItem):CompletedResult {
		// Error case: build failure, no images
		if (item.errorMessage != null) {
			return {
				testName: item.displayName,
				referencePath: item.referencePath,
				actualPath: item.actualPath,
				passed: false,
				similarity: 0.0,
				errorMessage: item.errorMessage,
				orderIndex: item.orderIndex,
				threshold: item.threshold,
			};
		}

		// Step 0: Encode raw pixels to PNG if provided (deferred from main thread)
		if (item.actualRaw != null && item.actualPngBytes == null) {
			item.actualPngBytes = encodePng(item.actualRaw);
			item.actualRaw = null;
		}
		if (item.macroRaw != null && item.macroPngBytes == null) {
			item.macroPngBytes = encodePng(item.macroRaw);
			item.macroRaw = null;
		}

		// Step 1: Save actual PNG to disk
		if (item.actualPngBytes != null) {
			ensureDirectory(item.actualPath);
			sys.io.File.saveBytes(item.actualPath, item.actualPngBytes);
		}

		// Step 2: Save macro PNG to disk
		if (item.macroPngBytes != null && item.macroPath != null) {
			sys.io.File.saveBytes(item.macroPath, item.macroPngBytes);
		}

		// Step 3: Load reference PNG from disk
		var refBytes = loadFileBytes(item.referencePath);

		// Step 4: Compute builder vs reference similarity
		var builderSim:Float = 0.0;
		if (item.actualPngBytes != null && refBytes != null) {
			builderSim = computeSimilarityFromBytes(item.actualPngBytes, refBytes);
		}

		// Step 5: Compute macro vs reference similarity
		var macroSim:Null<Float> = null;
		var macroPassed:Null<Bool> = null;
		if (item.macroPngBytes != null && refBytes != null) {
			macroSim = computeSimilarityFromBytes(item.macroPngBytes, refBytes);
			var mTh:Float = item.macroThreshold != null ? item.macroThreshold : 1.0;
			macroPassed = macroSim >= mTh;
		}

		// Step 6: Compute builder vs macro similarity
		var bvmSim:Null<Float> = null;
		if (item.actualPngBytes != null && item.macroPngBytes != null) {
			bvmSim = computeSimilarityFromBytes(item.actualPngBytes, item.macroPngBytes);
		}

		// Step 7: Generate diff images
		var diffBase:String = null;
		if (item.actualPath != null) {
			diffBase = item.actualPath.replace("_actual.png", "");
		}
		if (diffBase != null) {
			if (builderSim < 1.0 && item.actualPngBytes != null && refBytes != null)
				generateDiffImageFromBytes(item.actualPngBytes, refBytes, diffBase + "_diff_bref.png");
			if (macroSim != null && macroSim < 1.0 && item.macroPngBytes != null && refBytes != null)
				generateDiffImageFromBytes(item.macroPngBytes, refBytes, diffBase + "_diff_mref.png");
			if (bvmSim != null && bvmSim < 1.0 && item.actualPngBytes != null && item.macroPngBytes != null)
				generateDiffImageFromBytes(item.actualPngBytes, item.macroPngBytes, diffBase + "_diff_bm.png");
		}

		// Step 8: Find .manim file in reference directory
		var manimPath:String = null;
		var manimContent:String = null;
		if (item.referencePath != null && item.referencePath.endsWith("/reference.png")) {
			var dir = item.referencePath.substring(0, item.referencePath.length - "/reference.png".length);
			if (sys.FileSystem.exists(dir) && sys.FileSystem.isDirectory(dir)) {
				for (file in sys.FileSystem.readDirectory(dir)) {
					if (file.endsWith(".manim")) {
						manimPath = dir + "/" + file;
						try {
							manimContent = sys.io.File.getContent(manimPath);
						} catch (e:Dynamic) {
							manimContent = null;
						}
						break;
					}
				}
			}
		}

		// Step 9: Determine pass/fail
		var th:Float = item.threshold;
		var builderPassed = builderSim >= th;
		var overallPassed = builderPassed;
		if (macroPassed != null && !macroPassed)
			overallPassed = false;

		return {
			testName: item.displayName,
			referencePath: item.referencePath,
			actualPath: item.actualPath,
			passed: overallPassed,
			similarity: builderSim,
			errorMessage: null,
			manimPath: manimPath,
			manimContent: manimContent,
			macroPath: item.macroPath,
			macroSimilarity: macroSim,
			macroPassed: macroPassed,
			threshold: item.threshold,
			macroThreshold: item.macroThreshold,
			builderVsMacroSimilarity: bvmSim,
			orderIndex: item.orderIndex,
		};
	}

	// ==================== Pure-Haxe image utilities (thread-safe) ====================

	private static function decodePng(pngBytes:haxe.io.Bytes):{bytes:haxe.io.Bytes, width:Int, height:Int} {
		var reader = new format.png.Reader(new haxe.io.BytesInput(pngBytes));
		var data = reader.read();
		var header = format.png.Tools.getHeader(data);
		var pixels = format.png.Tools.extract32(data);
		return {bytes: pixels, width: header.width, height: header.height};
	}

	public static function computeSimilarityFromBytes(png1:haxe.io.Bytes, png2:haxe.io.Bytes):Float {
		if (png1 == null || png2 == null)
			return 0.0;
		try {
			var p1 = decodePng(png1);
			var p2 = decodePng(png2);
			if (p1.width != p2.width || p1.height != p2.height)
				return 0.0;

			var b1 = p1.bytes;
			var b2 = p2.bytes;
			var totalPixels = p1.width * p1.height;
			var matchingPixels = 0;
			for (i in 0...totalPixels) {
				var p = i << 2;
				var c1 = b1.getInt32(p);
				var c2 = b2.getInt32(p);
				if (c1 == c2) {
					matchingPixels++;
				} else {
					var dr = ((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF);
					var dg = ((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF);
					var db = (c1 & 0xFF) - (c2 & 0xFF);
					var da = ((c1 >> 24) & 0xFF) - ((c2 >> 24) & 0xFF);
					if (dr < 0)
						dr = -dr;
					if (dg < 0)
						dg = -dg;
					if (db < 0)
						db = -db;
					if (da < 0)
						da = -da;
					var m = da;
					if (dr > m)
						m = dr;
					if (dg > m)
						m = dg;
					if (db > m)
						m = db;
					if (m < 5)
						matchingPixels++;
				}
			}
			return matchingPixels / totalPixels;
		} catch (e:Dynamic) {
			return 0.0;
		}
	}

	private static function generateDiffImageFromBytes(png1:haxe.io.Bytes, png2:haxe.io.Bytes, outputPath:String):Bool {
		try {
			var p1 = decodePng(png1);
			var p2 = decodePng(png2);
			if (p1.width != p2.width || p1.height != p2.height)
				return false;

			var w = p1.width;
			var h = p1.height;
			var b1 = p1.bytes;
			var b2 = p2.bytes;
			var total = w * h;
			var diffBytes = haxe.io.Bytes.alloc(total * 4);

			for (i in 0...total) {
				var p = i << 2;
				var c1 = b1.getInt32(p);
				var c2 = b2.getInt32(p);
				if (c1 == c2) {
					diffBytes.setInt32(p, 0xFF000000);
				} else {
					var dr = ((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF);
					var dg = ((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF);
					var db = (c1 & 0xFF) - (c2 & 0xFF);
					if (dr < 0)
						dr = -dr;
					if (dg < 0)
						dg = -dg;
					if (db < 0)
						db = -db;
					var v = dr;
					if (dg > v)
						v = dg;
					if (db > v)
						v = db;
					v = v * 5;
					if (v > 255)
						v = 255;
					diffBytes.setInt32(p, 0xFF000000 | (v << 16) | (v << 8) | v);
				}
			}

			// Encode to PNG using pure-Haxe format.png
			var pngData = format.png.Tools.build32BGRA(w, h, diffBytes);
			var out = new haxe.io.BytesOutput();
			new format.png.Writer(out).write(pngData);
			ensureDirectory(outputPath);
			sys.io.File.saveBytes(outputPath, out.getBytes());
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	/** Encode raw BGRA pixel data to PNG bytes (thread-safe, pure Haxe). */
	public static function encodePng(raw:RawPixels):haxe.io.Bytes {
		var pngData = format.png.Tools.build32BGRA(raw.width, raw.height, raw.bytes);
		var out = new haxe.io.BytesOutput();
		new format.png.Writer(out).write(pngData);
		return out.getBytes();
	}

	private static function loadFileBytes(path:String):Null<haxe.io.Bytes> {
		if (path == null || !sys.FileSystem.exists(path))
			return null;
		try {
			return sys.io.File.getBytes(path);
		} catch (e:Dynamic) {
			return null;
		}
	}

	private static function ensureDirectory(filePath:String):Void {
		var dir = haxe.io.Path.directory(filePath);
		if (dir != null && dir != "" && !sys.FileSystem.exists(dir)) {
			sys.FileSystem.createDirectory(dir);
		}
	}
}
