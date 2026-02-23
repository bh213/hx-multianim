package bh.multianim;

/**
 * h2d.Object subclass that defers layout alignment positioning to onAdd(),
 * when scene dimensions become available via getScene().
 * Used by macro-generated instance classes that have aligned layouts.
 */
class LayoutAlignRoot extends h2d.Object {
	var _alignEntries:Array<{
		target:h2d.Object,
		baseX:Float,
		baseY:Float,
		alignX:Int, // 0=Left, 1=Center, 2=Right
		alignY:Int, // 0=Top, 1=Center, 2=Bottom
		postOffsetX:Float,
		postOffsetY:Float
	}>;

	public function addAlignEntry(target:h2d.Object, baseX:Float, baseY:Float, alignX:Int, alignY:Int, postOffsetX:Float,
			postOffsetY:Float):Void {
		if (_alignEntries == null)
			_alignEntries = [];
		_alignEntries.push({
			target: target,
			baseX: baseX,
			baseY: baseY,
			alignX: alignX,
			alignY: alignY,
			postOffsetX: postOffsetX,
			postOffsetY: postOffsetY
		});
	}

	override function onAdd():Void {
		super.onAdd();
		if (_alignEntries == null)
			return;
		var scene = getScene();
		if (scene == null)
			return;
		for (e in _alignEntries) {
			var x:Float = switch (e.alignX) {
				case 1: scene.width / 2 + e.baseX; // Center
				case 2: scene.width - e.baseX; // Right
				default: e.baseX; // Left
			};
			var y:Float = switch (e.alignY) {
				case 1: scene.height / 2 + e.baseY; // Center
				case 2: scene.height - e.baseY; // Bottom
				default: e.baseY; // Top
			};
			e.target.setPosition(x + e.postOffsetX, y + e.postOffsetY);
		}
	}
}
