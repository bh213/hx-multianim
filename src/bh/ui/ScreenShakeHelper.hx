package bh.ui;

import hxd.Rand;

typedef ShakeInstance = {
	var time:Float;
	var duration:Float;
	var intensity:Float;
	var decayFn:Null<(Float) -> Float>;
	var dirX:Float;
	var dirY:Float;
};

/**
 * Lightweight screen shake helper. Supports multiple concurrent shakes (additive),
 * directional shakes, and custom decay curves.
 *
 * Applies offsets as deltas relative to the previous frame so the target's position
 * can be moved freely by gameplay (camera scroll, animation, layout) without the
 * shake snapping it back to a captured baseline.
 *
 * Usage:
 * ```haxe
 * var shake = new ScreenShakeHelper(root);
 * shake.shake(8.0, 0.4);                         // basic shake
 * shake.shakeDirectional(6.0, 0.2, 1.0, 0.0);    // horizontal recoil
 * shake.shakeWithCurve(10.0, 0.5, curve);         // custom decay
 * // In update loop:
 * shake.update(dt);
 * ```
 */
@:nullSafety
class ScreenShakeHelper {
	var target:h2d.Object;
	var shakes:Array<ShakeInstance> = [];
	var rand:Rand;
	// Last applied offset — we add (newDx - lastDx) each frame so gameplay motion
	// of the target is preserved instead of overwritten.
	var lastDx:Float = 0.0;
	var lastDy:Float = 0.0;

	public var isShaking(get, never):Bool;

	function get_isShaking():Bool {
		return shakes.length > 0;
	}

	public function new(target:h2d.Object) {
		this.target = target;
		this.rand = new Rand(Std.int(haxe.Timer.stamp() * 1000.0));
	}

	/** Quick one-shot shake with linear decay. */
	public function shake(intensity:Float = 5.0, duration:Float = 0.3):Void {
		shakes.push({time: 0, duration: duration, intensity: intensity, decayFn: null, dirX: 1.0, dirY: 1.0});
	}

	/** Directional shake (e.g. horizontal-only for recoil, vertical for landing). */
	public function shakeDirectional(intensity:Float, duration:Float, dirX:Float = 1.0, dirY:Float = 0.0):Void {
		shakes.push({time: 0, duration: duration, intensity: intensity, decayFn: null, dirX: dirX, dirY: dirY});
	}

	/** Shake with custom decay curve. Curve receives 0..1 (remaining ratio), returns intensity factor. */
	public function shakeWithCurve(intensity:Float, duration:Float, curve:(Float) -> Float):Void {
		shakes.push({time: 0, duration: duration, intensity: intensity, decayFn: curve, dirX: 1.0, dirY: 1.0});
	}

	/** Update all active shakes. Call from screen update(dt). */
	public function update(dt:Float):Void {
		if (shakes.length == 0) {
			// No active shake — ensure any leftover offset has been cleared.
			if (lastDx != 0.0 || lastDy != 0.0) {
				target.x -= lastDx;
				target.y -= lastDy;
				lastDx = 0.0;
				lastDy = 0.0;
			}
			return;
		}

		var totalX = 0.0;
		var totalY = 0.0;
		var i = shakes.length;
		while (--i >= 0) {
			var s = shakes[i];
			s.time += dt;
			if (s.time >= s.duration) {
				// Swap-remove for O(1)
				shakes[i] = shakes[shakes.length - 1];
				shakes.pop();
				continue;
			}
			var remaining = 1.0 - s.time / s.duration;
			var factor = s.decayFn != null ? s.decayFn(remaining) : remaining;
			var angle = rand.rand() * Math.PI * 2;
			totalX += Math.cos(angle) * s.intensity * factor * s.dirX;
			totalY += Math.sin(angle) * s.intensity * factor * s.dirY;
		}

		// Apply as delta so gameplay-driven motion of the target is preserved.
		target.x += totalX - lastDx;
		target.y += totalY - lastDy;
		lastDx = totalX;
		lastDy = totalY;
	}

	/** Stop all shakes and remove any residual offset. */
	public function stop():Void {
		shakes.resize(0);
		if (lastDx != 0.0 || lastDy != 0.0) {
			target.x -= lastDx;
			target.y -= lastDy;
			lastDx = 0.0;
			lastDy = 0.0;
		}
	}
}
