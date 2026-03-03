package bh.ui;

import bh.paths.AnimatedPath;

/**
 * A single floating text/object instance driven by an AnimatedPath.
 */
@:nullSafety
class FloatingTextInstance {
	public var object(default, null):h2d.Object;
	public var animPath(default, null):AnimatedPath;
	public var startX(default, null):Float;
	public var startY(default, null):Float;

	/** If true, animPath state.position IS the world position (Stretch-normalized paths).
	 *  If false, state.position is added as offset from (startX, startY). */
	public var absolutePosition:Bool;

	/** Called when the AnimatedPath completes. */
	public dynamic function onComplete():Void {}

	public function new(object:h2d.Object, animPath:AnimatedPath, startX:Float, startY:Float, absolutePosition:Bool) {
		this.object = object;
		this.animPath = animPath;
		this.startX = startX;
		this.startY = startY;
		this.absolutePosition = absolutePosition;
	}

	public var done(get, never):Bool;

	function get_done():Bool {
		return animPath.getState().done;
	}
}

/**
 * Manages multiple floating text/object instances, each driven by an AnimatedPath.
 *
 * Usage:
 * ```haxe
 * var helper = new FloatingTextHelper(overlayRoot);
 * var ap = builder.createAnimatedPath("dmgAnim", Stretch(startPos, endPos));
 * helper.spawn("-42", font, x, y, ap, 0xFF0000);
 * // In update loop:
 * helper.update(dt);
 * ```
 */
@:nullSafety
class FloatingTextHelper {
	var parent:Null<h2d.Object>;
	var instances:Array<FloatingTextInstance> = [];

	public var count(get, never):Int;

	function get_count():Int {
		return instances.length;
	}

	public function new(?parent:h2d.Object) {
		this.parent = parent;
	}

	/**
	 * Spawn a floating text driven by an AnimatedPath.
	 * @param absolutePosition If true, animPath state.position IS the world position (use with Stretch-normalized paths).
	 *        If false (default), state.position is added as offset from (x, y).
	 */
	public function spawn(text:String, font:h2d.Font, x:Float, y:Float, animPath:AnimatedPath, ?color:Int,
			absolutePosition:Bool = false):FloatingTextInstance {
		var textObj = new h2d.Text(font);
		textObj.text = text;
		textObj.textAlign = Center;
		if (color != null)
			textObj.textColor = color;
		textObj.setPosition(x, y);

		if (parent != null)
			parent.addChild(textObj);

		var inst = new FloatingTextInstance(textObj, animPath, x, y, absolutePosition);
		instances.push(inst);
		return inst;
	}

	/**
	 * Spawn with a pre-built h2d.Object instead of creating text.
	 * Useful for floating icons, sprites, or complex manim-built objects.
	 */
	public function spawnObject(obj:h2d.Object, x:Float, y:Float, animPath:AnimatedPath,
			absolutePosition:Bool = false):FloatingTextInstance {
		obj.setPosition(x, y);
		if (parent != null)
			parent.addChild(obj);

		var inst = new FloatingTextInstance(obj, animPath, x, y, absolutePosition);
		instances.push(inst);
		return inst;
	}

	/** Update all active instances. Completed instances are removed automatically. Call from game loop. */
	public function update(dt:Float):Void {
		var i = 0;
		while (i < instances.length) {
			var inst = instances[i];
			var state = inst.animPath.update(dt);

			// Apply AnimatedPath state to object
			if (inst.absolutePosition) {
				inst.object.setPosition(state.position.x, state.position.y);
			} else {
				inst.object.setPosition(inst.startX + state.position.x, inst.startY + state.position.y);
			}
			inst.object.alpha = state.alpha;
			inst.object.scaleX = state.scale;
			inst.object.scaleY = state.scale;
			inst.object.rotation = state.rotation;

			// Apply color if a colorCurve is active (non-default white)
			if (state.color != 0xFFFFFF) {
				if (Std.isOfType(inst.object, h2d.Text)) {
					(cast inst.object : h2d.Text).textColor = state.color;
				}
			}

			if (state.done) {
				inst.object.remove();
				inst.onComplete();
				// Swap-remove for O(1)
				instances[i] = instances[instances.length - 1];
				instances.pop();
			} else {
				i++;
			}
		}
	}

	/** Remove all active instances immediately. */
	public function clear():Void {
		for (inst in instances)
			inst.object.remove();
		instances.resize(0);
	}
}
