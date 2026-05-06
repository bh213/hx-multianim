package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.base.FPoint;
import bh.base.Hex.FractionalHex;
import bh.base.TweenManager;
import bh.base.TweenManager.TweenPropertyEntry;
import bh.paths.AnimatedPath;
import bh.paths.AnimatedPath.AnimatedPathState;
import bh.paths.MultiAnimPaths.Path;
import bh.paths.MultiAnimPaths.SinglePath;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes;
import bh.ui.UICardHandTypes.CardLayoutPosition;
import bh.ui.UIMultiAnimGrid;
import bh.ui.UIMultiAnimGridTypes;
import bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory;
// `Hex` is also a GridType enum constructor in scope, so reference the Hex
// *class* via this alias when reading its allocation counter.
private typedef HexClass = bh.base.Hex.Hex;

/**
 * End-to-end allocation smoke test.
 *
 * Runs a representative scene (grid + card hand + tweens + animated paths)
 * for ~60 ticks and asserts total per-frame allocations stay within an
 * agreed budget. Catches per-frame regressions that slip past the
 * subsystem-specific watchdog tests because the subsystem is exercised
 * outside its dedicated test path.
 *
 * If a budget is exceeded, run the per-subsystem watchdog tests
 * (`testCellAtPoint*`, `testTweenPropertyEntry*`, `testApplyLayoutAnimated*`,
 * `testUpdateDoesNotAllocateAnimatedPathState`, `testParticleStep*`) to
 * isolate the regressing path.
 */
class AllocationSmokeTest extends BuilderTestBase {
	static final CARD_MANIM = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	static final HEX_CELL_MANIM = "
		#hexCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:[none,accept,reject]=none) {
			bitmap(generated(color(30, 30, #888888))): 0, 0
		}
	";

	static function makeHexGrid():UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(HEX_CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"}),
			originX: 0,
			originY: 0,
		});
		grid.addHexRegion(0, 0, 2);
		return grid;
	}

	static function makeCardHand():{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(CARD_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder);
		helper.setHand([
			{id: "a", buildName: "card"},
			{id: "b", buildName: "card"},
			{id: "c", buildName: "card"},
			{id: "d", buildName: "card"},
			{id: "e", buildName: "card"},
		]);
		return {helper: helper, screen: screen};
	}

	static function makeAnimatedPath():AnimatedPath {
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(100, 0), Line);
		var path = new Path([sp]);
		return new AnimatedPath(path, Time(2.0));
	}

	// Per-frame budget across the full scene. Each entry is (counter name, max
	// delta per frame). Subsystem watchdog tests assert exact zeros where
	// possible; this test asserts a TOTAL budget across the whole scene over
	// 60 ticks. The numbers below match measured behavior with the current
	// implementation, plus a small slack for non-allocating bookkeeping.
	@Test
	public function testRepresentativeScenePerFrameAllocationBudget():Void {
		final tickCount = 60;

		var grid = makeHexGrid();
		var hand = makeCardHand();
		var tweenMgr = new TweenManager();
		var animPath = makeAnimatedPath();

		// Seed a few tweens so the manager has work each frame. Use long
		// durations so they don't complete during the test (allocation pattern
		// should not change as they run).
		var obj1 = new h2d.Object();
		var obj2 = new h2d.Object();
		tweenMgr.tween(obj1, 100.0, [Alpha(0.5), X(50.0)]);
		tweenMgr.tween(obj2, 100.0, [Y(75.0), Rotation(1.0)]);

		// Warm-up tick — settle first-time allocations (matrix sync, lazy buffers).
		grid.cellAtPoint(0, 0);
		hand.helper.getCardIdAtPosition(50, 50);
		hand.helper.update(0.016);
		tweenMgr.update(0.016);
		animPath.update(0.016);

		final fpointBaseline = FPoint.creationCount;
		final hexBaseline = HexClass.creationCount;
		final fractionalHexBaseline = FractionalHex.creationCount;
		final cardLayoutPosBaseline = CardLayoutPosition.creationCount;
		final tweenEntryBaseline = TweenPropertyEntry.creationCount;
		final animStateBaseline = AnimatedPathState.creationCount;

		for (i in 0...tickCount) {
			// Cursor sweep across the grid + above the card hand.
			final sceneX = (i % 50) * 4.0;
			final sceneY = (i % 30) * 4.0;
			grid.cellAtPoint(sceneX, sceneY);
			hand.helper.getCardIdAtPosition(sceneX, 600.0);

			// Card hand layout pass (re-arranges, hover updates).
			hand.helper.update(0.016);

			// Tween manager step.
			tweenMgr.update(0.016);

			// Animated path step.
			animPath.update(0.016);
		}

		final fpointDelta = FPoint.creationCount - fpointBaseline;
		final hexDelta = HexClass.creationCount - hexBaseline;
		final fractionalHexDelta = FractionalHex.creationCount - fractionalHexBaseline;
		final cardLayoutPosDelta = CardLayoutPosition.creationCount - cardLayoutPosBaseline;
		final tweenEntryDelta = TweenPropertyEntry.creationCount - tweenEntryBaseline;
		final animStateDelta = AnimatedPathState.creationCount - animStateBaseline;

		// Budget rationale (per 60-tick run):
		//   FPoint: 0 — grid scratch, cardhand scratch, animated-path scratch all reuse.
		//   FractionalHex: 60 — one per cellAtPoint on the hex grid (1× pixelToHex).
		//                       Drops to 0 once pixelToHexInto() exists.
		//   Hex: 60 — one per cellAtPoint via FractionalHex.round().
		//             Drops to 0 once roundInto() exists.
		//   CardLayoutPosition: 0 — getCardIdAtPosition reuses _scratchPositions.
		//   TweenPropertyEntry: 0 — no new tweens created in the loop (tween durations
		//                            are 100s, never complete during 60 × 0.016s = 0.96s).
		//   AnimatedPathState: 0 — animated path mutates currentState in place.
		Assert.equals(0, fpointDelta, "FPoint per-frame budget exceeded: " + fpointDelta);
		Assert.equals(0, cardLayoutPosDelta, "CardLayoutPosition per-frame budget exceeded: " + cardLayoutPosDelta);
		Assert.equals(0, tweenEntryDelta, "TweenPropertyEntry per-frame budget exceeded: " + tweenEntryDelta);
		Assert.equals(0, animStateDelta, "AnimatedPathState per-frame budget exceeded: " + animStateDelta);
		// FractionalHex / Hex still allocate per cellAtPoint on hex grids — pinned
		// at known counts. If these drop, an Into-variant was added; flip to ==0.
		Assert.equals(tickCount, fractionalHexDelta,
			"FractionalHex per-frame budget exceeded: " + fractionalHexDelta + " (expected " + tickCount + ")");
		Assert.equals(tickCount, hexDelta,
			"Hex per-frame budget exceeded: " + hexDelta + " (expected " + tickCount + ")");

		grid.dispose();
	}
}
