package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Repeat containers inside layers() must honor the declared @layer. The
 * builder routes every built container through its layer-aware addChild
 * closure; the codegen repeat helpers emit a bare addChild, so the wrapper
 * lands on the topmost existing layer (order-dependent) instead of the
 * declared one.
 *
 * Companion fixture: test/examples/145-codegenLayerAdd/layerAdd.manim
 * (green 40px bitmap at layer 1, red 16px repeat at layer 0 — red must sort
 * before green among the layers children)
 */
class CodegenContainerLayerTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/145-codegenLayerAdd/layerAdd.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function subtreeHasBitmapWidth(o:h2d.Object, w:Int):Bool {
		if (Std.isOfType(o, h2d.Bitmap) && Std.int((cast o : h2d.Bitmap).tile.width) == w)
			return true;
		for (i in 0...o.numChildren)
			if (subtreeHasBitmapWidth(o.getChildAt(i), w))
				return true;
		return false;
	}

	/** Find the h2d.Layers whose DIRECT children separate the two widths. */
	static function findLayersHosting(root:h2d.Object, wA:Int, wB:Int):Null<h2d.Layers> {
		if (Std.isOfType(root, h2d.Layers)) {
			final l:h2d.Layers = cast root;
			var idxA = -1;
			var idxB = -1;
			for (i in 0...l.numChildren) {
				final c = l.getChildAt(i);
				if (idxA == -1 && subtreeHasBitmapWidth(c, wA))
					idxA = i;
				if (idxB == -1 && subtreeHasBitmapWidth(c, wB))
					idxB = i;
			}
			if (idxA != -1 && idxB != -1 && idxA != idxB)
				return l;
		}
		for (i in 0...root.numChildren) {
			final r = findLayersHosting(root.getChildAt(i), wA, wB);
			if (r != null)
				return r;
		}
		return null;
	}

	static function directChildIndexContaining(l:h2d.Layers, w:Int):Int {
		for (i in 0...l.numChildren)
			if (subtreeHasBitmapWidth(l.getChildAt(i), w))
				return i;
		return -1;
	}

	static function assertRedBelowGreen(root:h2d.Object, backend:String):Void {
		final layers = findLayersHosting(root, 16, 40);
		Assert.notNull(layers, '$backend: expected a layers container separating the 16px repeat and the 40px bitmap');
		if (layers == null)
			return;
		final idxRed = directChildIndexContaining(layers, 16);
		final idxGreen = directChildIndexContaining(layers, 40);
		Assert.isTrue(idxRed < idxGreen,
			'$backend: the @layer(0) repeat container must sort below the @layer(1) bitmap '
			+ '(child index $idxRed must be < $idxGreen)');
	}

	/** Builder baseline: the repeat container is added at its declared layer. */
	@Test
	public function testLayerRepeat_Builder_ContainerAtDeclaredLayer():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "layerRepeat", null);
		assertRedBelowGreen(result.object, "builder");
	}

	/** Codegen: same layer ordering. */
	@Test
	public function testLayerRepeat_Codegen_ContainerAtDeclaredLayer():Void {
		final inst:Dynamic = createMp().layerRepeat.create();
		assertRedBelowGreen(cast inst, "codegen");
	}
}
