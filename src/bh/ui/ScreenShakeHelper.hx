package bh.ui;

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
	var originalX:Float;
	var originalY:Float;
	var shakes:Array<ShakeInstance> = [];
	var seed:Float = 0.0;

	public var isShaking(get, never):Bool;

	function get_isShaking():Bool {
		return shakes.length > 0;
	}

	public function new(target:h2d.Object) {
		this.target = target;
		this.originalX = target.x;
		this.originalY = target.y;
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
		if (shakes.length == 0)
			return;

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
			// Use time-seeded pseudo-random for deterministic per-frame offsets
			seed += dt * 1000.0 + i;
			var angle = hashToAngle(seed);
			totalX += Math.cos(angle) * s.intensity * factor * s.dirX;
			totalY += Math.sin(angle) * s.intensity * factor * s.dirY;
		}

		target.x = originalX + totalX;
		target.y = originalY + totalY;
	}

	/** Stop all shakes and reset position immediately. */
	public function stop():Void {
		shakes.resize(0);
		target.x = originalX;
		target.y = originalY;
	}

	/** Update the original (rest) position if the target has moved. */
	public function setOrigin(x:Float, y:Float):Void {
		originalX = x;
		originalY = y;
	}

	static inline function hashToAngle(v:Float):Float {
		// Fast deterministic hash → angle
		var n = Std.int(v * 12.9898) * 43758;
		return ((n & 0xFFFF) / 65535.0) * Math.PI * 2;
	}
}
