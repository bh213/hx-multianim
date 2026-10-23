package bh.test.examples;

#if MULTIANIM_DEV
import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.dev.DevBridge;
import bh.multianim.dev.HotReload;
import bh.ui.screens.ScreenManager;

/**
 * In-place hot reload as the game sees it, and the dev services a screen manager owns.
 * Only compiled with -D MULTIANIM_DEV.
 *
 * After an in-place reload the handles the game kept (the result, its slots, its dynamicRef
 * children) stay live; only build inputs and values set through setParameter survive the reload,
 * at every depth of nested dynamicRefs, so a default or a dynamicRef argument edited in the file
 * applies.
 *
 * NOTE: Use double-quoted strings ("...") for .manim source — single-quoted strings trigger Haxe
 * string interpolation which conflicts with .manim $ references.
 */
@:access(bh.ui.screens.ScreenManager)
@:access(bh.multianim.dev.DevBridge)
class HotReloadReviewTest extends BuilderTestBase {
	// ===== Helpers =====

	static final managers:Array<ScreenManager> = [];

	/** A screen manager disposed after the test, so it stops hearing the window's input. */
	static function newManager():ScreenManager {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		managers.push(sm);
		return sm;
	}

	function teardown():Void {
		for (sm in managers)
			sm.dispose();
		managers.resize(0);
	}

	static final ITEM_V1 = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
	static final ITEM_V2 = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";
	// Fails to parse: `bitmapp` is no element
	static final ITEM_BROKEN = "version: 1.0\n#item programmable() {\n\tbitmapp(generated(color(99, 10, #ff0000))): 0, 0\n}\n";

	/** Runs `body` with `test/res/<fileName>` holding `content`; the file is deleted afterwards. */
	static function withTempManim(fileName:String, content:String, body:String -> Void):Void {
		final filePath = "test/res/" + fileName;
		sys.io.File.saveContent(filePath, content);
		var caught:Null<Dynamic> = null;
		try {
			body(filePath);
		} catch (e:Dynamic) {
			caught = e;
		}
		if (sys.FileSystem.exists(filePath))
			sys.FileSystem.deleteFile(filePath);
		if (caught != null)
			throw caught;
	}

	/** A root marked as on stage. Heaps fires onAdd/onRemove only under an allocated scene, and the
	 *  test app's s2d is allocated only after its first render — later than the unit tests run. */
	static function allocatedStage():h2d.Object {
		final stage = new h2d.Object();
		@:privateAccess stage.onAdd();
		return stage;
	}

	/** Builds `name` from `v1` through a screen manager (on stage), lets `setup` act on it, then
	 *  writes `v2` and hot-reloads it in place. */
	static function reloadInPlace(fileName:String, v1:String, v2:String, name:String,
			check:(sm:ScreenManager, result:BuilderResult, report:ReloadReport) -> Void, ?params:Map<String, Dynamic>,
			?setup:BuilderResult -> Void):Void {
		withTempManim(fileName, v1, filePath -> {
			final sm = newManager();
			final result = sm.buildFromResourceName(fileName, false).buildWithParameters(name, params ?? new Map(), null, null, true);
			final stage = allocatedStage();
			stage.addChild(result.object);
			if (setup != null)
				setup(result);
			sys.io.File.saveContent(filePath, v2);
			final report = sm.hotReload();
			check(sm, result, report);
			result.object.remove();
		});
	}

	static function itemWidth(result:BuilderResult):Int {
		return Std.int(findVisibleBitmapDescendants(result.object)[0].tile.width);
	}

	/** "WxH" of the first bitmap drawn under `root`, or "none". */
	static function sizeOf(root:h2d.Object):String {
		final bitmaps = findVisibleBitmapDescendants(root);
		if (bitmaps.length == 0)
			return "none";
		return Std.int(bitmaps[0].tile.width) + "x" + Std.int(bitmaps[0].tile.height);
	}

	/** Width of the bitmap drawn under `root` whose height is `height` (tells the bitmaps of a
	 *  host and of its children apart), or -1 when none is drawn. */
	static function widthOfDrawn(root:h2d.Object, height:Int):Int {
		for (b in findVisibleBitmapDescendants(root))
			if (Std.int(b.tile.height) == height)
				return Std.int(b.tile.width);
		return -1;
	}

	static function containsObject(root:h2d.Object, target:h2d.Object):Bool {
		if (root == target)
			return true;
		for (i in 0...root.numChildren)
			if (containsObject(root.getChildAt(i), target))
				return true;
		return false;
	}

	/** A host with its own 5-high bitmap (`hostWidth` wide) and a `bar` dynamicRef drawing a
	 *  12-high bitmap; `barBody` adds to bar's body. */
	static function hostWithBar(hostWidth:Int, barBody:String = ""):String {
		return "version: 1.0\n"
			+ "#bar programmable(w:uint=10) {\n\tbitmap(generated(color($w, 12, #ff0000))): 0, 0\n" + barBody + "}\n"
			+ "#host programmable() {\n\tbitmap(generated(color(" + hostWidth + ", 5, #0000ff))): 0, 0\n\tdynamicRef($bar, w=>10): 0, 20\n}\n";
	}

	/** A host that only places `bar` (w, h) with the given dynamicRef arguments. */
	static function barHost(args:String):String {
		return "version: 1.0\n"
			+ "#bar programmable(w:uint=10, h:uint=12) {\n\tbitmap(generated(color($w, $h, #ff0000))): 0, 0\n}\n"
			+ "#host programmable() {\n\tdynamicRef($bar, " + args + "): 0, 0\n}\n";
	}

	static function hostWH(w:Int, h:Int):String {
		return "version: 1.0\n#host programmable(w:uint=" + w + ", h:uint=" + h + ") {\n\tbitmap(generated(color($w, $h, #ff0000))): 0, 0\n}\n";
	}

	// ==================== What survives an in-place reload ====================

	@Test
	public function testInPlaceReloadAppliesAnEditedDefaultThatWasNeverSet():Void {
		final v1 = "version: 1.0\n#host programmable(w:uint=10) {\n\tbitmap(generated(color($w, 10, #ff0000))): 0, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable(w:uint=99) {\n\tbitmap(generated(color($w, 10, #ff0000))): 0, 0\n}\n";
		reloadInPlace("review-default-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals("99x10", sizeOf(result.object), "a default edited in the file applies to a value that was never set");
		});
	}

	@Test
	public function testInPlaceReloadKeepsAValueSetThroughSetParameterAndAppliesTheOtherEditedDefaults():Void {
		reloadInPlace("review-setparam-tmp.manim", hostWH(10, 10), hostWH(99, 20), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals("30x20", sizeOf(result.object),
				"w, set through setParameter, stays 30; h, never set, takes its edited default 20");
		}, null, result -> result.setParameter("w", 30));
	}

	@Test
	public function testInPlaceReloadKeepsABuildInputAndAppliesTheOtherEditedDefaults():Void {
		reloadInPlace("review-input-tmp.manim", hostWH(10, 10), hostWH(99, 20), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals("30x20", sizeOf(result.object),
				"w, passed to buildWithParameters, stays 30; h, never given, takes its edited default 20");
		}, ["w" => 30]);
	}

	@Test
	public function testInPlaceReloadAppliesAnEditedDynamicRefArgument():Void {
		reloadInPlace("review-refarg-tmp.manim", barHost("w=>10"), barHost("w=>99"), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals("99x12", sizeOf(result.object), "the dynamicRef argument edited in the file applies to the child");
		});
	}

	@Test
	public function testInPlaceReloadKeepsAValueSetOnADynamicRefChildAndAppliesItsOtherEditedArguments():Void {
		reloadInPlace("review-refset-tmp.manim", barHost("w=>10, h=>12"), barHost("w=>10, h=>20"), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals("30x20", sizeOf(result.object),
				"w, set on the child through setParameter, stays 30; h takes the argument edited in the file, 20");
		}, null, result -> result.getDynamicRef("bar").setParameter("w", 30));
	}

	@Test
	public function testInPlaceReloadKeepsAValueSetOnADynamicRefInsideADynamicRef():Void {
		function nested(hostWidth:Int):String {
			return "version: 1.0\n"
				+ "#leaf programmable(w:uint=10) {\n\tbitmap(generated(color($w, 12, #ff0000))): 0, 0\n}\n"
				+ "#mid programmable() {\n\tdynamicRef($leaf, w=>10): 0, 0\n}\n"
				+ "#host programmable() {\n\tbitmap(generated(color(" + hostWidth + ", 5, #0000ff))): 0, 0\n\tdynamicRef($mid): 0, 20\n}\n";
		}
		reloadInPlace("review-nested-tmp.manim", nested(5), nested(6), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals(6, widthOfDrawn(result.object, 5), "sanity: the host's edit shows");
			Assert.equals(30, widthOfDrawn(result.object, 12), "the value set on the inner child, two dynamicRefs down, survives the reload");
		}, null, result -> result.getDynamicRef("mid").getDynamicRef("leaf").setParameter("w", 30));
	}

	// ==================== Handles the game kept stay live ====================

	@Test
	public function testASlotHandleKeptFromBeforeAnInPlaceReloadStaysLive():Void {
		final v1 = "version: 1.0\n#host programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n\t#s slot: 0, 20\n}\n";
		final v2 = "version: 1.0\n#host programmable() {\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n\t#s slot: 0, 20\n}\n";
		var kept:Null<SlotHandle> = null;
		reloadInPlace("review-keptslot-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			final content = new h2d.Object();
			kept.setContent(content);
			Assert.isTrue(containsObject(result.object, content),
				"content put through a slot handle kept from before the reload shows under the live result");
			Assert.equals(content, result.getSlot("s").getContent(), "and the result's slot holds it");
		}, null, result -> kept = result.getSlot("s"));
	}

	@Test
	public function testADynamicRefHandleKeptFromBeforeAnInPlaceReloadStaysLive():Void {
		var kept:Null<BuilderResult> = null;
		reloadInPlace("review-keptref-tmp.manim", hostWithBar(5), hostWithBar(6), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			kept.setParameter("w", 50);
			Assert.equals(50, widthOfDrawn(result.object, 12),
				"setParameter on a dynamicRef child kept from before the reload changes what the live result draws");
		}, null, result -> kept = result.getDynamicRef("bar"));
	}

	@Test
	public function testSlotContentInsideADynamicRefChildSurvivesAnInPlaceReload():Void {
		final slot = "\t#s slot: 0, 20\n";
		final content = new h2d.Object();
		reloadInPlace("review-refslot-tmp.manim", hostWithBar(5, slot), hostWithBar(6, slot), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.isTrue(containsObject(result.object, content), "the content of a slot inside a dynamicRef child stays under the live result");
			Assert.equals(content, result.getDynamicRef("bar").getSlot("s").getContent(), "in the child's slot");
		}, null, result -> result.getDynamicRef("bar").getSlot("s").setContent(content));
	}

	@Test
	public function testAResultTheGamePutInASlotOfAnotherIsReloadedToo():Void {
		// item is no dynamicRef child of host: the game built it and put it in host's slot
		function file(hostWidth:Int, itemWidth:Int):String {
			return "version: 1.0\n"
				+ "#item programmable() {\n\tbitmap(generated(color(" + itemWidth + ", 12, #ff0000))): 0, 0\n}\n"
				+ "#host programmable() {\n\tbitmap(generated(color(" + hostWidth + ", 5, #0000ff))): 0, 0\n\t#s slot: 0, 20\n}\n";
		}
		final fileName = "review-slotted-tmp.manim";
		withTempManim(fileName, file(5, 10), filePath -> {
			final sm = newManager();
			final builder = sm.buildFromResourceName(fileName, false);
			final host = builder.buildWithParameters("host", new Map(), null, null, true);
			final item = builder.buildWithParameters("item", new Map(), null, null, true);
			host.getSlot("s").setContent(item.object);
			final stage = allocatedStage();
			stage.addChild(host.object);

			sys.io.File.saveContent(filePath, file(6, 99));
			final report = sm.hotReload();
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals(6, widthOfDrawn(host.object, 5), "sanity: the host's edit shows");
			Assert.equals(99, widthOfDrawn(item.object, 12), "the result in the slot is rebuilt from the edited file too");
			Assert.isTrue(containsObject(host.object, item.object), "and stays in the host's slot");
			host.object.remove();
		});
	}

	@Test
	public function testEachUnnamedDynamicRefOfARepeatKeepsItsOwnValuesAndSlotContent():Void {
		// three unnamed dynamicRef sites of one repeat share the key "bar": each child keeps its own
		function file(hostWidth:Int):String {
			return "version: 1.0\n"
				+ "#bar programmable(w:uint=10) {\n\tbitmap(generated(color($w, 12, #ff0000))): 0, 0\n\t#s slot: 0, 20\n}\n"
				+ "#host programmable() {\n\tbitmap(generated(color(" + hostWidth + ", 5, #0000ff))): 0, 0\n"
				+ "\trepeatable($i, step(3, dx: 100)) {\n\t\tdynamicRef($bar, w=>10): 0, 40\n\t}\n}\n";
		}
		final contents = [for (i in 0...3) new h2d.Object()];
		reloadInPlace("review-repeatrefs-tmp.manim", file(5), file(6), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals(6, widthOfDrawn(result.object, 5), "sanity: the host's edit shows");
			final children = result.dynamicRefs.get("bar");
			Assert.equals(3, children.length, "sanity: three children");
			for (i in 0...children.length) {
				Assert.equals(20 + i, widthOfDrawn(children[i].object, 12), 'child $i keeps the w set on it');
				Assert.equals(contents[i], children[i].getSlot("s").getContent(), 'child $i keeps its own slot content');
			}
		}, null, result -> {
			final children = result.dynamicRefs.get("bar");
			for (i in 0...children.length) {
				children[i].setParameter("w", 20 + i);
				children[i].getSlot("s").setContent(contents[i]);
			}
		});
	}

	@Test
	public function testOneNameInExclusiveArmsKeepsTheShownArmsValuesAndHandle():Void {
		// #panel in both arms, both built (each shown once): the reload builds the shown arm only
		function file(hostWidth:Int):String {
			return "version: 1.0\n"
				+ "#panelA programmable(w:uint=10) {\n\tbitmap(generated(color($w, 12, #ff0000))): 0, 0\n}\n"
				+ "#panelB programmable(v:uint=20) {\n\tbitmap(generated(color($v, 12, #00ff00))): 0, 0\n}\n"
				+ "#host programmable(mode:[a,b]=a) {\n\tbitmap(generated(color(" + hostWidth + ", 5, #0000ff))): 0, 0\n"
				+ "\t@(mode=>a) #panel dynamicRef($panelA): 0, 20\n\t@else #panel dynamicRef($panelB): 0, 20\n}\n";
		}
		var shown:Null<BuilderResult> = null;
		reloadInPlace("review-exclref-tmp.manim", file(5), file(6), "host", (sm, result, report) -> {
			Assert.isTrue(report.success, 'the reload succeeds (arm a\'s values are not set on arm b\'s panel): ${report.errors}');
			Assert.equals(6, widthOfDrawn(result.object, 5), "sanity: the host's edit shows");
			Assert.equals(33, widthOfDrawn(result.object, 12), "the shown arm's panel keeps the value set on it");
			Assert.equals(shown, result.getDynamicRef("panel"), "the handle the game kept is the one that answers");
			Assert.isTrue(containsObject(result.object, shown.object), "and it is drawn in the host");
		}, null, result -> {
			result.getDynamicRef("panel").setParameter("w", 15);
			result.setParameter("mode", "b");
			shown = result.getDynamicRef("panel");
			shown.setParameter("v", 33);
		});
	}

	@Test
	public function testAnImportedFilesDynamicRefChildKeepsItsArgumentsAndItsHost():Void {
		// bar comes from an imported file: reloading that file alone rebuilds the child on its own
		function bar(h:Int):String {
			return "version: 1.0\n#bar programmable(w:uint=10, h:uint=" + h + ") {\n\tbitmap(generated(color($w, $h, #ff0000))): 0, 0\n}\n";
		}
		final barFile = "review-imported-bar-tmp.manim";
		final hostFile = "review-imported-host-tmp.manim";
		final host = "version: 1.0\nimport \"" + barFile + "\" as \"w\"\n"
			+ "#host programmable(hw:uint=30) {\n\tdynamicRef(external(w), $bar, w=>$hw): 0, 0\n}\n";
		withTempManim(barFile, bar(12), barPath -> withTempManim(hostFile, host, _ -> {
			final sm = newManager();
			sm.buildFromResourceName(barFile, false);
			final result = sm.buildFromResourceName(hostFile, false).buildWithParameters("host", new Map(), null, null, true);
			final stage = allocatedStage();
			stage.addChild(result.object);
			Assert.equals(30, widthOfDrawn(result.object, 12), "precondition: the site passes w=30");

			sys.io.File.saveContent(barPath, bar(13));
			final report = sm.hotReload();
			Assert.isTrue(report.success, 'sanity: the reload succeeds: ${report.errors}');
			Assert.equals(30, widthOfDrawn(result.object, 13), "the edited default applies and the site's argument stays");

			result.setParameter("hw", 44);
			Assert.equals(44, widthOfDrawn(result.object, 13), "the host's forwarding reaches the rebuilt child");
			result.object.remove();
		}));
	}

	// ==================== A reload that fails part way ====================

	@Test
	public function testARebuildListenerThatThrowsFailsTheReloadWithoutStoppingIt():Void {
		final fileName = "review-listener-tmp.manim";
		withTempManim(fileName, ITEM_V1, filePath -> {
			final sm = newManager();
			final builder = sm.buildFromResourceName(fileName, false);
			final first = builder.buildWithParameters("item", new Map(), null, null, true);
			final second = builder.buildWithParameters("item", new Map(), null, null, true);
			first.addRebuildListener(() -> throw "boom");
			var started = 0;
			sm.addReloadListener(event -> switch event {
				case ReloadStarted(_, _): started++;
				default:
			});

			sys.io.File.saveContent(filePath, ITEM_V2);
			var thrown:Null<String> = null;
			var report:Null<ReloadReport> = null;
			try {
				report = sm.hotReload();
			} catch (e:Dynamic) {
				thrown = Std.string(e);
			}
			Assert.isNull(thrown, 'the error of a rebuild listener must not escape hotReload: $thrown');
			Assert.isTrue(report != null && !report.success, "the reload reports the failure");
			Assert.isTrue(report != null && report.errors.length > 0, "with an error for it");
			Assert.equals(99, itemWidth(second), "the other result from the file is rebuilt all the same");

			try {
				sm.hotReload();
			} catch (e:Dynamic) {}
			Assert.equals(2, started, "reloading the same text again is tried again, not reported as unchanged");
		});
	}

	@Test
	public function testAReloadOfSeveralFilesReportsTheFailureOfOneBesideTheRebuildOfTheOther():Void {
		final fileA = "review-multi-a-tmp.manim";
		final fileB = "review-multi-b-tmp.manim";
		withTempManim(fileA, ITEM_V1, pathA -> {
			withTempManim(fileB, ITEM_V1, pathB -> {
				final sm = newManager();
				sm.buildFromResourceName(fileA, false);
				final resultB = sm.buildFromResourceName(fileB, false).buildWithParameters("item", new Map(), null, null, true);
				sys.io.File.saveContent(pathA, ITEM_BROKEN);
				sys.io.File.saveContent(pathB, ITEM_V2);

				final report = sm.hotReload();

				Assert.equals(99, itemWidth(resultB), "sanity: the file that parses is reloaded");
				Assert.isFalse(report.success, "one of the files failed, whichever came last: the reload says so");
				var errorsOfA = 0;
				for (error in report.errors)
					if (error.file.indexOf(fileA) >= 0)
						errorsOfA++;
				Assert.isTrue(errorsOfA > 0, 'the report carries the error of $fileA, got: ${report.errors}');
				Assert.isTrue(report.rebuiltCount > 0, "and what the other file rebuilt");
			});
		});
	}

	// ==================== Reload handles of discarded results ====================

	@Test
	public function testInPlaceReloadsDoNotPileUpReloadHandlesOfDiscardedDynamicRefChildren():Void {
		final fileName = "review-handles-tmp.manim";
		final v1 = hostWithBar(5);
		final v2 = hostWithBar(6);
		withTempManim(fileName, v1, filePath -> {
			final sm = newManager();
			// Off screen, like UI the game has not shown yet: no reload sentinel ever fires
			final result = sm.buildFromResourceName(fileName, false).buildWithParameters("host", new Map(), null, null, true);
			final before = sm.hotReloadRegistry.getHandles(fileName).length;
			Assert.isTrue(before > 0, "sanity: the result is registered");
			for (round in 0...3) {
				sys.io.File.saveContent(filePath, round % 2 == 0 ? v2 : v1);
				final report = sm.hotReload();
				Assert.isTrue(report.success, 'sanity: reload ${round + 1} succeeds: ${report.errors}');
				final handles = sm.hotReloadRegistry.getHandles(fileName);
				Assert.equals(before, handles.length, 'after reload ${round + 1} the registry lists as many handles as before');
				final liveChild = result.getDynamicRef("bar");
				for (handle in handles)
					Assert.isTrue(handle.result == result || handle.result == liveChild,
						'after reload ${round + 1} a handle of "${handle.programmableName}" is the result or its live child, not a discarded one');
			}
		});
	}

	// ==================== A disposed manager ====================

	@Test
	public function testADisposedManagerDoesNotReloadWhenAFileItWatchedChanges():Void {
		final fileName = "review-watch-tmp.manim";
		final liveUpdate = hxd.res.Resource.LIVE_UPDATE;
		hxd.res.Resource.LIVE_UPDATE = true;
		var caught:Null<Dynamic> = null;
		try {
			withTempManim(fileName, ITEM_V1, filePath -> {
				final sm = newManager();
				final result = sm.buildFromResourceName(fileName, true).buildWithParameters("item", new Map(), null, null, true);
				final resource = sm.loadedResource(fileName);
				final entry:Null<hxd.fs.LocalFileSystem.LocalEntry> = resource == null ? null : Std.downcast(resource.entry,
					hxd.fs.LocalFileSystem.LocalEntry);
				Assert.notNull(entry, "sanity: the file is read from disk");
				if (entry == null)
					return;
				var failed:Null<Dynamic> = null;
				try {
					Assert.notNull(@:privateAccess entry.watchCallback, "sanity: loading with enableReload watches the file");
					sm.dispose();
					sys.io.File.saveContent(filePath, ITEM_V2);
					// What the file watch runs when the file changes on disk
					final onChanged = @:privateAccess entry.watchCallback;
					if (onChanged != null)
						onChanged();
					Assert.equals(10, itemWidth(result), "a change of a file the disposed manager watched does not reload what it built");
				} catch (e:Dynamic) {
					failed = e;
				}
				// No watch is left behind on the file, whatever the manager did
				resource.watch(null);
				if (failed != null)
					throw failed;
			});
		} catch (e:Dynamic) {
			caught = e;
		}
		hxd.res.Resource.LIVE_UPDATE = liveUpdate;
		if (caught != null)
			throw caught;
	}

	// ==================== DevBridge trace capture ====================

	static function countLines(lines:Array<String>, marker:String):Int {
		var n = 0;
		for (line in lines)
			if (line.indexOf(marker) >= 0)
				n++;
		return n;
	}

	@Test
	public function testTraceCaptureOfTwoBridgesChainsAndHandsBackTheOriginalTrace():Void {
		final before = haxe.Log.trace;
		// Stands in for the original trace, so it can be seen to still receive traces
		final printed:Array<String> = [];
		final original = (v:Dynamic, ?infos:haxe.PosInfos) -> {
			printed.push(Std.string(v));
		};
		haxe.Log.trace = original;
		var caught:Null<Dynamic> = null;
		try {
			final sm = newManager();
			final a = new DevBridge(sm, 0);
			final b = new DevBridge(sm, 0);
			a.installTraceCapture();
			b.installTraceCapture();
			a.restoreTrace();

			final first = "chained-trace-" + Std.random(1000000);
			trace(first);
			Assert.equals(1, countLines(b.traceBuffer, first), "the bridge still capturing hears a trace after the other bridge stopped");
			Assert.equals(0, countLines(a.traceBuffer, first), "the bridge that stopped hears no more");
			Assert.equals(1, countLines(printed, first), "and the original trace still prints it");

			b.restoreTrace();
			// (HashLink wraps a closure assigned to haxe.Log.trace, so the function cannot be compared
			// with `original` itself: the chain is checked empty, and the original still prints below)
			Assert.equals(0, DevBridge.traceHooks.length, "with both bridges stopped, no bridge's hook is left in haxe.Log.trace's chain");
			final second = "after-both-stopped-" + Std.random(1000000);
			trace(second);
			Assert.equals(1, countLines(printed, second), "tracing works: the original prints");
			Assert.equals(0, countLines(a.traceBuffer, second), "and no bridge captures");
			Assert.equals(0, countLines(b.traceBuffer, second));
		} catch (e:Dynamic) {
			caught = e;
		}
		haxe.Log.trace = before; // never leave a hook behind for the tests that follow
		if (caught != null)
			throw caught;
	}
}
#end
