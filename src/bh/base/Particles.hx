package bh.base;

/**
	The particle emission pattern modes. See `ParticleGroup.emitMode`.
**/
enum PartEmitMode {
	/**
		A single Point, that emits in all directions.
		Parametrized with `emitDistance` and `emitDistanceRandom` which specify the distance from the emission point.
	**/
	Point(emitDistance:Float,  emitDistanceRandom:Float);
	/**
		A cone, parametrized with `emitAngle` and `emitDistance`.
	**/
	Cone(emitDistance:Float, emitDistanceRandom:Float, emitConeAngle:Float, emitConeAngleRandom:Float);
	/**
		A box, parametrized with `emitDist` and `emitDistY`.
	**/
	Box(width:Float, height:Float, emitConeAngle:Float, emitConeAngleRandom:Float);
	/**
		Emit from the edge of a circle/ring.
	**/
	Circle(radius:Float, radiusRandom:Float, emitConeAngle:Float, emitConeAngleRandom:Float);
	/**
		Emit along a named path. Particles spawn at random positions along the path.
	**/
	ManimPath(path:bh.paths.MultiAnimPaths.Path);
	/**
		Emit along a named path with velocity following the path tangent direction.
	**/
	ManimPathTangent(path:bh.paths.MultiAnimPaths.Path);
}

/**
	Force field types that can affect particles.
**/
enum ForceField {
	/**
		Attracts particles toward a point.
	**/
	Attractor(x:Float, y:Float, strength:Float, radius:Float);
	/**
		Repels particles from a point.
	**/
	Repulsor(x:Float, y:Float, strength:Float, radius:Float);
	/**
		Creates a spinning vortex effect.
	**/
	Vortex(x:Float, y:Float, strength:Float, radius:Float);
	/**
		Constant directional wind force.
	**/
	Wind(vx:Float, vy:Float);
	/**
		Turbulence/noise-based displacement.
	**/
	Turbulence(strength:Float, scale:Float, speed:Float);
	/**
		Guides particles toward a path and along its tangent direction.
		attractStrength pulls toward nearest point on path.
		flowStrength pushes along path's tangent direction.
	**/
	PathGuide(path:bh.paths.MultiAnimPaths.Path, attractStrength:Float, flowStrength:Float, radius:Float);
}

/**
	Sub-emitter trigger conditions.
**/
enum SubEmitTrigger {
	OnBirth;
	OnDeath;
	OnCollision;
	OnInterval(interval:Float);
}

/**
	Sub-emitter configuration.
**/
typedef SubEmitter = {
	var groupId:String;
	var trigger:SubEmitTrigger;
	var probability:Float;
	var inheritVelocity:Float;
	var offsetX:Float;
	var offsetY:Float;
}

/**
	Animation state for particles (pre-extracted tiles from AnimSM).
**/
typedef ParticleAnimState = {
	var name:String;
	var tiles:Array<h2d.Tile>;
	var fps:Float;
	var startLifeRate:Float;
}

/**
	Collision/bounds behavior.
**/
enum BoundsMode {
	None;
	Kill;
	Bounce(damping:Float);
	Wrap;
}

@:access(bh.base.Particles.ParticleGroup)
@:nullSafety(Strict)
private class Particle extends h2d.SpriteBatch.BatchElement {

	var group : ParticleGroup;
	public var vx : Float = 0;
	public var vy : Float = 0;
	public var vSize : Float = 0;
	public var vr : Float = 0;
	public var maxLife : Float = 1;
	public var life : Float = 0;
	public var delay : Float = 0;

	// For sub-emitter interval tracking
	public var lastSubEmitTime : Float = 0;

	// Unique seed for turbulence variation per particle
	public var noiseSeed : Float = 0;

	// Base scale for size curve calculations (per-particle)
	public var baseScaleX : Float = 1;
	public var baseScaleY : Float = 1;

	// Current AnimSM state index (for lifetime-driven animation states)
	public var currentAnimStateIndex : Int = 0;

	public function new(group:ParticleGroup) {
		super(null);
		this.group = group;
		this.noiseSeed = hxd.Math.random() * 1000;
	}

	override function update(dt:Float):Bool {
		if( delay > 0 ) {
			delay -= dt;
			if( delay <= 0 ){
				group.init(this);
				visible = true;
				// Trigger OnBirth sub-emitters
				group.triggerSubEmitters(this, OnBirth);
			}
			else {
				visible = false;
				return true;
			}
		}

		var timeNormalized = life / maxLife;

		// Apply velocity curve if defined
		var velocityMult = group.getVelocityCurveValue(timeNormalized);

		// Base velocity changes
		var dv = Math.pow(1 + group.speedIncr, dt);
		vx *= dv;
		vy *= dv;

		// Apply gravity
		vx += group.gravity * dt * group.sinGravityAngle;
		vy += group.gravity * dt * group.cosGravityAngle;

		// Apply force fields
		group.applyForceFields(this, dt);

		// Update position with velocity curve modifier
		var effectiveVx = vx * velocityMult;
		var effectiveVy = vy * velocityMult;

		x += effectiveVx * dt;
		y += effectiveVy * dt;
		life += dt;

		// Rotation
		if( group.rotAuto )
			rotation = Math.atan2(effectiveVy, effectiveVx) - group.forwardAngle + life * vr;
		else
			rotation += vr * dt;

		// Size with curve support
		var sizeMult = group.getSizeCurveValue(timeNormalized);
		if (group.incrX)
			baseScaleX *= Math.pow(1 + vSize, dt);
		if (group.incrY)
			baseScaleY *= Math.pow(1 + vSize, dt);
		// Apply curve multiplier to base scale
		scaleX = baseScaleX * sizeMult;
		scaleY = baseScaleY * sizeMult;

		// Alpha fade
		if( timeNormalized < group.fadeIn )
			alpha = Math.pow(timeNormalized / group.fadeIn, group.fadePower);
		else if( timeNormalized > group.fadeOut )
			alpha = Math.pow((1 - timeNormalized) / (1 - group.fadeOut), group.fadePower);
		else
			alpha = 1;

		// Color interpolation
		if (group.colorEnabled) {
			var col = group.evaluateColorCurve(timeNormalized);
			r = ((col >> 16) & 0xFF) / 255.0;
			g = ((col >> 8) & 0xFF) / 255.0;
			b = (col & 0xFF) / 255.0;
		}

		// Sprite animation
		if (group.animStates.length > 0) {
			// AnimSM-driven: find active state by lifetime rate
			var stateIdx = currentAnimStateIndex;
			// Advance state if we've passed the next state's start rate
			while (stateIdx + 1 < group.animStates.length && timeNormalized >= group.animStates[stateIdx + 1].startLifeRate) {
				stateIdx++;
			}
			currentAnimStateIndex = stateIdx;
			var animState = group.animStates[stateIdx];
			if (animState.tiles.length > 0) {
				// Compute local time within this state
				var stateStart = animState.startLifeRate;
				var stateEnd = if (stateIdx + 1 < group.animStates.length) group.animStates[stateIdx + 1].startLifeRate else 1.0;
				var localT = if (stateEnd <= stateStart) 0. else (timeNormalized - stateStart) / (stateEnd - stateStart);
				localT = Math.min(Math.max(localT, 0.), 1.);
				var frameIndex = Std.int(localT * animState.tiles.length) % animState.tiles.length;
				t = animState.tiles[frameIndex];
			}
		} else if (group.animationRepeat > 0 && group.tiles.length > 1) {
			var animProgress = timeNormalized * group.animationRepeat;
			var frameIndex = Std.int(animProgress * group.tiles.length) % group.tiles.length;
			t = group.tiles[frameIndex];
		}

		// Bounds checking
		if (group.boundsMode != None) {
			if (!group.checkBounds(this)) {
				return false;
			}
		}

		// Sub-emitter interval check
		group.checkIntervalSubEmitters(this, timeNormalized);

		// Lifecycle
		if( timeNormalized > 1 ) {
			// Trigger OnDeath sub-emitters
			group.triggerSubEmitters(this, OnDeath);

			if( group.emitLoop ) {
				group.init(this);
				delay = 0;
			} else
				return false;
		}
		return true;
	}

}

/**
	An emitter of a single particle group. Part of `Particles` simulation system.
**/
@:access(h2d.SpriteBatch)
@:access(h2d.Object)
@:allow(bh.base.Particles)
@:allow(bh.multianim.MultiAnimBuilder)
@:nullSafety(Strict)
class ParticleGroup {

	inline function srand():Float return hxd.Math.srand();
	inline function rand():Float return hxd.Math.random();

	final parts : Particles;
	final batch : h2d.SpriteBatch;
	var tiles : Array<h2d.Tile>;

	var started = false;
	var globalTime : Float = 0;
	/**
		The group name.
	**/
	public final id : String;
	/**
		Disabling the group immediately removes it from rendering and resets it's state.
	**/
	public var enabled(default, null) : Bool = true;
	/**
		Configures blending mode for this group.
	**/
	public var blendMode(default, set) : h2d.BlendMode = Alpha;

	/**
		Maximum number of particles alive at a time.
	**/
	public var nparts(default, null) : Int 		= 100;
	/**
		Initial particle X offset.
	**/
	public var dx(default, null) : Int 			= 0;
	/**
		Initial particle Y offset.
	**/
	public var dy(default, null) : Int 			= 0;

	/**
		If enabled, group will emit new particles indefinitely maintaining number of particles at `ParticleGroup.nparts`.
	**/
	public var emitLoop(default, null) : Bool 	= true;
	/**
		The pattern in which particles are emitted. See individual `PartEmitMode` values for more details.
	**/
	public var emitMode(default, null):PartEmitMode = Point(0., 50.);
	/**
		Initial particle position distance from emission point.
	**/
	// public var emitStartDist(default, null) : Float = 0.;
	/**
		Additional random particle position distance from emission point.
	**/
	// public var emitDist(default, null) : Float	= 50.;
	/**
		Secondary random position distance modifier (used by `Box` emitMode)
	**/
	// public var emitDistY(default, null) : Float	= 50.;
	/**
		Normalized particle emission direction angle.
	**/
	// public var emitAngle(default, null) : Float 	= -0.5;
	/**
		When enabled, particle rotation will match the particle movement direction angle.
	**/
	public var emitDirectionAsAngle(default, null) : Bool = false;
	/**
		Randomized synchronization delay before particle appears after being emitted.

		Usage note for non-relative mode: Particle will use configuration that was happened at time of emission, not when delay timer runs out.
	**/
	public var emitSync(default, null) : Float	= 0;
	/**
		Fixed delay before particle appears after being emitted.

		Usage note for non-relative mode: Particle will use configuration that was happened at time of emission, not when delay timer runs out.
	**/
	public var emitDelay(default, null) : Float	= 0;

	/**
		Initial particle size.
	**/
	public var size(default, null) : Float		= 1;
	/**
		If set, particle will change it's size with time.
	**/
	public var sizeIncr(default, null) : Float	= 0;
	/**
		If enabled, particle will increase on X-axis with `sizeIncr`.
	**/
	public var incrX(default, null) : Bool		= true;
	/**
		If enabled, particle will increase on Y-axis with `sizeIncr`.
	**/
	public var incrY(default, null) : Bool		= true;
	/**
		Additional random size increase when particle is created.
	**/
	public var sizeRand(default, null) : Float	= 0;

	/**
		Initial particle lifetime.
	**/
	public var life(default, null) : Float		= 1;
	/**
		Additional random lifetime increase when particle is created.
	**/
	public var lifeRand(default, null) : Float	= 0;

	/**
		Initial particle velocity.
	**/
	public var speed(default, null) : Float			= 50.;
	/**
		Additional random velocity increase when particle is created.
	**/
	public var speedRand(default, null) : Float		= 0;
	/**
		If set, particle velocity will change over time.
	**/
	public var speedIncr(default, null) : Float		= 0;
	/**
		Gravity applied to the particle.
	**/
	public var gravity(default, null) : Float		= 0;
	/**
		The gravity angle in radians. `0` points down.
	**/
	public var gravityAngle(default, set) : Float 	= 0;
	var cosGravityAngle : Float = 1.0;  // cos(0) = 1
	var sinGravityAngle : Float = 0.0;  // sin(0) = 0

	/**
		Initial particle rotation.
	**/
	public var rotInit(default, null) : Float	= 0;
	/**
		Initial rotation speed of the particle.
	**/
	public var rotSpeed(default, null) : Float	= 0;
	/**
		Additional random rotation speed when particle is created.
	**/
	public var rotSpeedRand(default, null):Float = 0;
	/**
		If enabled, particles will be automatically rotated in the direction of particle velocity.
	**/
	public var rotAuto							= false;
	/**
		Forward angle offset in radians for rotateAuto. Default 0 means sprite faces right.
	**/
	public var forwardAngle : Float				= 0;

	/**
		The time in seconds during which particle alpha fades in after being emitted.
	**/
	public var fadeIn : Float					= 0.2;
	/**
		The time in seconds at which particle will start to fade out before dying. Fade out time can be calculated with `lifetime - fadeOut`.
	**/
	public var fadeOut : Float					= 0.8;
	/**
		The exponent of the alpha transition speed on fade in and fade out.
	**/
	public var fadePower : Float				= 1;

	/**
		The amount of times the animations will loop during lifetime.
		Settings it to 0 will stop the animation playback and each particle will have a random frame assigned at emission time.
	**/
	public var animationRepeat(default,null) : Float	= 1;
	
	
	/**
		When enabled, causes particles to always render relative to the emitter position.
	**/
	public var isRelative(default, null) : Bool = true;

	// ========== NEW FEATURES ==========

	// ----- Color Interpolation -----
	/**
		Enable color interpolation over particle lifetime.
	**/
	public var colorEnabled(default, null) : Bool = false;
	/**
		Color curve segments sorted by startRate. Uses AnimatedPath-style per-segment interpolation.
	**/
	var colorCurveSegments : Array<{startRate:Float, curve:bh.paths.Curve.ICurve, startColor:Int, endColor:Int}> = [];

	/** Add a color curve segment with per-segment start/end colors. Sorted by startRate. */
	public function addColorCurveSegment(startRate:Float, curve:bh.paths.Curve.ICurve, startColor:Int, endColor:Int):Void {
		var left = 0;
		var right = colorCurveSegments.length;
		while (left < right) {
			var mid = Std.int((left + right) / 2);
			if (colorCurveSegments[mid].startRate < startRate)
				left = mid + 1;
			else
				right = mid;
		}
		colorCurveSegments.insert(left, {startRate: startRate, curve: curve, startColor: startColor, endColor: endColor});
		colorEnabled = true;
	}

	// ----- Force Fields -----
	/**
		Array of force fields affecting this particle group. Mutable at runtime.
	**/
	public var forceFields : Array<ForceField> = [];

	public function addForceField(ff:ForceField):Void {
		forceFields.push(ff);
	}

	public function removeForceFieldAt(index:Int):Void {
		forceFields.splice(index, 1);
	}

	public function clearForceFields():Void {
		forceFields = [];
	}

	// ----- Curves -----
	/**
		Velocity multiplier curve over lifetime. null = no curve (constant 1.0).
	**/
	public var velocityCurve : Null<bh.paths.Curve.ICurve> = null;
	/**
		Size multiplier curve over lifetime. null = no curve (constant 1.0).
	**/
	public var sizeCurve : Null<bh.paths.Curve.ICurve> = null;

	// ----- Bounds/Collision -----
	/**
		How particles behave at boundaries.
	**/
	public var boundsMode(default, null) : BoundsMode = None;
	/**
		Boundary rectangle - minX.
	**/
	public var boundsMinX(default, null) : Float = 0;
	/**
		Boundary rectangle - maxX.
	**/
	public var boundsMaxX(default, null) : Float = 800;
	/**
		Boundary rectangle - minY.
	**/
	public var boundsMinY(default, null) : Float = 0;
	/**
		Boundary rectangle - maxY.
	**/
	public var boundsMaxY(default, null) : Float = 600;
	/**
		Line bounds. Each line has endpoints (x1,y1)-(x2,y2) and a precomputed outward normal (nx,ny).
		Particles on the normal side are in-bounds; those on the opposite side are out-of-bounds.
	**/
	public var boundsLines : Array<{x1:Float, y1:Float, x2:Float, y2:Float, nx:Float, ny:Float}> = [];

	/** Add a line boundary. The "out" side is the left side of the direction from (x1,y1) to (x2,y2). */
	public function addBoundsLine(x1:Float, y1:Float, x2:Float, y2:Float):Void {
		var dx = x2 - x1;
		var dy = y2 - y1;
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 1e-10) return;
		// Left-hand normal (outward = "kill" side)
		var nx = dy / len;
		var ny = -dx / len;
		boundsLines.push({x1: x1, y1: y1, x2: x2, y2: y2, nx: nx, ny: ny});
	}

	// ----- Sub-emitters -----
	/**
		Array of sub-emitter configurations.
	**/
	public var subEmitters(default, null) : Array<SubEmitter> = [];

	// ----- AnimSM Tile Source -----
	/**
		Animation states for particles, sorted by startLifeRate. When set, overrides simple tile animation.
	**/
	public var animStates : Array<ParticleAnimState> = [];
	/**
		Event-driven animation overrides. Maps trigger name ("onBounce", "onDeath") to anim state index.
	**/
	public var animEventOverrides : Map<String, Int> = new Map();

	// ----- AnimatedPath Integration -----
	/**
		Attached animated path — emitter position tracks this path.
	**/
	public var attachedPath : Null<bh.paths.AnimatedPath> = null;
	/**
		Spawn curve — modulates emission rate over attached path's lifetime.
	**/
	public var spawnCurve : Null<bh.paths.Curve.ICurve> = null;

	/** Accumulator for dynamic emission when spawnCurve is active. */
	var emissionAccumulator : Float = 0;

	inline function set_blendMode(v) { batch.blendMode = v; return blendMode = v; }
	
	inline function set_gravityAngle(v : Float) {
		cosGravityAngle = Math.cos(v);
		sinGravityAngle = Math.sin(v);
		return gravityAngle = v;
	}
	/**
		Create a new particle group instance.
		@param p The parent Particles instance. Group does not automatically adds itself to the Particles.
	**/
	@:nullSafety(Off)
	public function new(id:String, p:Particles, tiles:Array<h2d.Tile>) {
		this.id = id;
		this.parts = p;
		this.tiles = tiles;
		batch = new h2d.SpriteBatch(null, p);
		batch.visible = false;
		batch.hasRotationScale = true;
		batch.hasUpdate = true;
	}

	

	function start():Void {
		batch.clear();
		started = true;
		globalTime = 0;
		for( i in 0...nparts ) {
			var p = new Particle(this);
			p.delay = rand() * life * (1 - emitSync) + emitDelay;
			batch.add(p);
		}
	}

	/**
		Emit a burst of particles at a specific position with optional inherited velocity.
		Creates particles on-the-fly and adds them to the batch.
	**/
	public function emitBurstAt(atX:Float, atY:Float, inheritVx:Float, inheritVy:Float, count:Int):Void {
		if (!started) {
			batch.visible = true;
			started = true;
			globalTime = 0;
		}
		for (i in 0...count) {
			var p = new Particle(this);
			init(p);
			p.x += atX;
			p.y += atY;
			p.vx += inheritVx;
			p.vy += inheritVy;
			p.visible = true;
			batch.add(p);
		}
	}

	/**
		Emit a burst of particles at the emitter's current position.
	**/
	public function emitBurst(count:Int):Void {
		emitBurstAt(0, 0, 0, 0, count);
	}

	function init( p : Particle ):Void {
		var g = this;
		var size = g.size * (1 + srand() * g.sizeRand);
		var rot = srand() * Math.PI * g.rotInit;
		var vrot = g.rotSpeed * (1 + rand() * g.rotSpeedRand) * (srand() < 0 ? -1 : 1);
		var life = g.life * (1 + srand() * g.lifeRand);

		var speed = g.speed * (1 + srand() * g.speedRand);
		if( g.life == 0 )
			life = 1e10;
		p.x = dx;
		p.y = dy;

		switch( g.emitMode ) {

			case Point(emitDistance, emitdistanceRandom):
				p.vx = srand();
				p.vy = srand();
				var len = hxd.Math.sqrt(p.vx * p.vx + p.vy * p.vy);
				if (len > 0) speed *= 1 / len;

				final r = emitDistance + emitdistanceRandom * rand();
				p.x += p.vx * r;
				p.y += p.vy * r;

			case Cone(emitDistance, emitDistanceRandom, emitConeAngle, emitConeAngleRandom):
				final phi = hxd.Math.angle(emitConeAngle + emitConeAngleRandom * srand());
				p.vx = Math.cos(phi);
				p.vy = Math.sin(phi);

				final r = emitDistance + emitDistanceRandom * rand();
				p.x += p.vx * r;
				p.y += p.vy * r;

			case Box(width, height, emitConeAngle, emitConeAngleRandom):
				p.x += width * rand();
				p.y += height * rand();

				final phi = hxd.Math.angle(emitConeAngle + emitConeAngleRandom * srand());
				p.vx = Math.cos(phi);
				p.vy = Math.sin(phi);

			case ManimPath(path):
				var rate = rand();
				var pt = path.getPoint(rate);
				p.x += pt.x;
				p.y += pt.y;
				// Random velocity direction
				p.vx = srand();
				p.vy = srand();
				var len = hxd.Math.sqrt(p.vx * p.vx + p.vy * p.vy);
				if (len > 0) speed *= 1 / len;

			case ManimPathTangent(path):
				var rate = rand();
				var pt = path.getPoint(rate);
				p.x += pt.x;
				p.y += pt.y;
				// Velocity follows path tangent
				var tangent = path.getTangentAngle(rate);
				p.vx = Math.cos(tangent);
				p.vy = Math.sin(tangent);

			case Circle(radius, radiusRandom, emitConeAngle, emitConeAngleRandom):
				var angle = rand() * Math.PI * 2;
				var r = radius + radiusRandom * rand();
				p.x += Math.cos(angle) * r;
				p.y += Math.sin(angle) * r;

				// If emitConeAngle is 0, emit outward from circle center
				var phi:Float;
				if (emitConeAngle == 0 && emitConeAngleRandom == 0) {
					phi = angle; // Radial outward
				} else {
					phi = hxd.Math.angle(emitConeAngle + emitConeAngleRandom * srand());
				}
				p.vx = Math.cos(phi);
				p.vy = Math.sin(phi);
		}

		p.scale = size;
		p.baseScaleX = size;
		p.baseScaleY = size;
		p.rotation = rot;
		p.vSize = g.sizeIncr;
		p.vr = vrot;

		// Handle animation frame selection
		if (animationRepeat == 0 && tiles.length > 1) {
			// Random frame when animation is disabled
			p.t = tiles[Std.random(tiles.length)];
		} else {
			p.t = tiles[0];
		}

		p.vx *= speed;
		p.vy *= speed;
		p.life = 0;
		p.maxLife = life;
		p.lastSubEmitTime = 0;

		var initRot = emitDirectionAsAngle ? Math.atan2(p.vy, p.vx) : srand() * Math.PI * g.rotInit;
		p.rotation = initRot;

		// Initialize color from first color curve segment
		if (colorEnabled && colorCurveSegments.length > 0) {
			var initColor = colorCurveSegments[0].startColor;
			p.r = ((initColor >> 16) & 0xFF) / 255.0;
			p.g = ((initColor >> 8) & 0xFF) / 255.0;
			p.b = (initColor & 0xFF) / 255.0;
		}

		if ( !isRelative ) {
			var parts = this.parts;
			var px = p.x;
			p.x = px * parts.matA + p.y * parts.matC + parts.absX;
			p.y = px * parts.matB + p.y * parts.matD + parts.absY;
			var scX = Math.sqrt((parts.matA * parts.matA) + (parts.matC * parts.matC)) * size;
			var scY = Math.sqrt((parts.matB * parts.matB) + (parts.matD * parts.matD)) * size;
			p.scaleX = scX;
			p.scaleY = scY;
			p.baseScaleX = scX;
			p.baseScaleY = scY;
			var absRot = Math.atan2(parts.matB / scY, parts.matA / scX);
			p.rotation += absRot;

			var cos = Math.cos(absRot);
			var sin = Math.sin(absRot);
			px = p.vx;
			p.vx = px * cos - p.vy * sin;
			p.vy = px * sin + p.vy * cos;
		}
	}

	// ========== Helper Functions ==========

	/**
		Evaluate per-segment color curve at normalized lifetime.
	**/
	public function evaluateColorCurve(rate:Float):Int {
		// Find active segment: largest startRate <= rate
		var activeIndex = -1;
		for (i in 0...colorCurveSegments.length) {
			if (colorCurveSegments[i].startRate <= rate)
				activeIndex = i;
			else
				break;
		}

		if (activeIndex < 0) return 0xFFFFFF;

		var segment = colorCurveSegments[activeIndex];
		var segStart = segment.startRate;
		var segEnd = if (activeIndex + 1 < colorCurveSegments.length) colorCurveSegments[activeIndex + 1].startRate else 1.0;

		var localT = if (segEnd <= segStart) 0. else (rate - segStart) / (segEnd - segStart);
		localT = Math.min(Math.max(localT, 0.), 1.);

		var curveValue = segment.curve.getValue(localT);
		return lerpColor(segment.startColor, segment.endColor, curveValue);
	}

	inline function lerpColor(c1:Int, c2:Int, t:Float):Int {
		var r1 = (c1 >> 16) & 0xFF;
		var g1 = (c1 >> 8) & 0xFF;
		var b1 = c1 & 0xFF;
		var r2 = (c2 >> 16) & 0xFF;
		var g2 = (c2 >> 8) & 0xFF;
		var b2 = c2 & 0xFF;
		var r = Std.int(r1 + (r2 - r1) * t);
		var g = Std.int(g1 + (g2 - g1) * t);
		var b = Std.int(b1 + (b2 - b1) * t);
		return (r << 16) | (g << 8) | b;
	}

	/**
		Get velocity curve value at normalized time.
	**/
	public function getVelocityCurveValue(t:Float):Float {
		return velocityCurve != null ? velocityCurve.getValue(t) : 1.0;
	}

	/**
		Get size curve value at normalized time.
	**/
	public function getSizeCurveValue(t:Float):Float {
		return sizeCurve != null ? sizeCurve.getValue(t) : 1.0;
	}

	/**
		Apply all force fields to a particle.
	**/
	public function applyForceFields(p:Particle, dt:Float):Void {
		var fields = forceFields;
		if (fields == null || fields.length == 0) return;

		for (ff in fields) {
			switch (ff) {
				case Attractor(fx, fy, strength, radius):
					applyPointForce(p, fx, fy, strength, radius, dt, false);

				case Repulsor(fx, fy, strength, radius):
					applyPointForce(p, fx, fy, strength, radius, dt, true);

				case Vortex(fx, fy, strength, radius):
					var dx = fx - p.x;
					var dy = fy - p.y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist < radius && dist > 0) {
						var factor = (1 - dist / radius) * strength * dt;
						// Perpendicular force for rotation
						p.vx += -dy / dist * factor;
						p.vy += dx / dist * factor;
					}

				case Wind(wx, wy):
					p.vx += wx * dt;
					p.vy += wy * dt;

				case Turbulence(strength, scale, speed):
					// Simple noise-based turbulence using sine waves
					var time = globalTime * speed + p.noiseSeed;
					var noiseX = Math.sin(p.x * scale + time) * Math.cos(p.y * scale * 0.7 + time * 1.3);
					var noiseY = Math.cos(p.x * scale * 0.8 + time * 1.1) * Math.sin(p.y * scale + time);
					p.vx += noiseX * strength * dt;
					p.vy += noiseY * strength * dt;

				case PathGuide(path, attractStrength, flowStrength, radius):
					var closestRate = path.getClosestRate(new bh.base.FPoint(p.x, p.y));
					var closestPt = path.getPoint(closestRate);
					var dx = closestPt.x - p.x;
					var dy = closestPt.y - p.y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist < radius) {
						var falloff = (1.0 - dist / radius);
						// Attract toward path
						if (attractStrength != 0 && dist > 1e-6) {
							var af = falloff * attractStrength * dt / dist;
							p.vx += dx * af;
							p.vy += dy * af;
						}
						// Flow along tangent
						if (flowStrength != 0) {
							var tangent = path.getTangentAngle(closestRate);
							var ff = falloff * flowStrength * dt;
							p.vx += Math.cos(tangent) * ff;
							p.vy += Math.sin(tangent) * ff;
						}
					}
			}
		}
	}

	inline function applyPointForce(p:Particle, fx:Float, fy:Float, strength:Float, radius:Float, dt:Float, repel:Bool):Void {
		var dx = fx - p.x;
		var dy = fy - p.y;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (dist < radius && dist > 0) {
			var factor = (1 - dist / radius) * strength * dt / dist;
			if (repel) factor = -factor;
			p.vx += dx * factor;
			p.vy += dy * factor;
		}
	}

	/**
		Check bounds and handle collision/wrapping.
	**/
	public function checkBounds(p:Particle):Bool {
		switch (boundsMode) {
			case None:
				return true;

			case Kill:
				if (p.x < boundsMinX || p.x > boundsMaxX || p.y < boundsMinY || p.y > boundsMaxY) {
					triggerSubEmitters(p, OnCollision);
					return false;
				}
				// Check line bounds
				for (line in boundsLines) {
					var dot = (p.x - line.x1) * line.nx + (p.y - line.y1) * line.ny;
					if (dot < 0) {
						triggerSubEmitters(p, OnCollision);
						return false;
					}
				}
				return true;

			case Bounce(damping):
				var collided = false;
				if (p.x < boundsMinX) {
					p.x = boundsMinX;
					p.vx = -p.vx * damping;
					collided = true;
				} else if (p.x > boundsMaxX) {
					p.x = boundsMaxX;
					p.vx = -p.vx * damping;
					collided = true;
				}
				if (p.y < boundsMinY) {
					p.y = boundsMinY;
					p.vy = -p.vy * damping;
					collided = true;
				} else if (p.y > boundsMaxY) {
					p.y = boundsMaxY;
					p.vy = -p.vy * damping;
					collided = true;
				}
				// Check line bounds
				for (line in boundsLines) {
					var dot = (p.x - line.x1) * line.nx + (p.y - line.y1) * line.ny;
					if (dot < 0) {
						// Reflect velocity across line normal
						var vDot = p.vx * line.nx + p.vy * line.ny;
						p.vx = (p.vx - 2 * vDot * line.nx) * damping;
						p.vy = (p.vy - 2 * vDot * line.ny) * damping;
						// Push particle back to line surface
						p.x -= dot * line.nx;
						p.y -= dot * line.ny;
						collided = true;
					}
				}
				if (collided) {
					triggerSubEmitters(p, OnCollision);
					applyAnimEventOverride(p, "onBounce");
				}
				return true;

			case Wrap:
				var width = boundsMaxX - boundsMinX;
				var height = boundsMaxY - boundsMinY;
				if (p.x < boundsMinX) p.x += width;
				else if (p.x > boundsMaxX) p.x -= width;
				if (p.y < boundsMinY) p.y += height;
				else if (p.y > boundsMaxY) p.y -= height;
				// Line bounds don't apply to wrap mode
				return true;
		}
	}

	/**
		Trigger sub-emitters with matching trigger condition.
	**/
	public function triggerSubEmitters(p:Particle, trigger:SubEmitTrigger):Void {
		var emitters = subEmitters;
		if (emitters == null || emitters.length == 0) return;

		for (se in emitters) {
			if (!matchesTrigger(se.trigger, trigger)) continue;
			if (rand() > se.probability) continue;

			// Find the sub-emitter group
			var subGroup = parts.getGroup(se.groupId);
			if (subGroup == null) continue;

			// Spawn a particle from sub-group at parent particle's location
			subGroup.emitBurstAt(
				p.x + se.offsetX,
				p.y + se.offsetY,
				p.vx * se.inheritVelocity,
				p.vy * se.inheritVelocity,
				1
			);
		}
	}

	function matchesTrigger(configured:SubEmitTrigger, actual:SubEmitTrigger):Bool {
		return switch [configured, actual] {
			case [OnBirth, OnBirth]: true;
			case [OnDeath, OnDeath]: true;
			case [OnCollision, OnCollision]: true;
			case [OnInterval(_), OnInterval(_)]: true;
			case _: false;
		};
	}

	/**
		Apply an event-driven animation override to a particle.
		If the trigger matches a registered override, switches the particle to that anim state.
	**/
	public function applyAnimEventOverride(p:Particle, triggerName:String):Void {
		var stateIndex = animEventOverrides.get(triggerName);
		if (stateIndex != null && stateIndex < animStates.length) {
			p.currentAnimStateIndex = stateIndex;
			// Update tile immediately
			var animState = animStates[stateIndex];
			if (animState.tiles.length > 0) {
				p.t = animState.tiles[0];
			}
		}
	}

	/**
		Check and trigger interval-based sub-emitters.
	**/
	public function checkIntervalSubEmitters(p:Particle, timeNormalized:Float):Void {
		var emitters = subEmitters;
		if (emitters == null || emitters.length == 0) return;

		for (se in emitters) {
			switch (se.trigger) {
				case OnInterval(interval):
					if (p.life - p.lastSubEmitTime >= interval) {
						p.lastSubEmitTime = p.life;
						if (rand() <= se.probability) {
							var subGroup = parts.getGroup(se.groupId);
							if (subGroup != null) {
								subGroup.emitBurstAt(
									p.x + se.offsetX,
									p.y + se.offsetY,
									p.vx * se.inheritVelocity,
									p.vy * se.inheritVelocity,
									1
								);
							}
						}
					}
				case _:
			}
		}
	}

	/**
		Update global time, animated path tracking, and spawn curve emission.
	**/
	public function updateTime(dt:Float):Void {
		globalTime += dt;

		// Update attached animated path
		if (attachedPath != null) {
			var state = attachedPath.update(dt);
			dx = Std.int(state.position.x);
			dy = Std.int(state.position.y);

			// Dynamic emission via spawn curve
			if (spawnCurve != null) {
				var rate = spawnCurve.getValue(state.rate);
				emissionAccumulator += rate * nparts * dt / life;
				while (emissionAccumulator >= 1.0) {
					emissionAccumulator -= 1.0;
					emitBurst(1);
				}
			}
		}
	}

}

/**
	A 2D particle system with wide range of customizability.

	The Particles instance can contain multiple `ParticleGroup` instances - each of which works independently from one another.

	To simplify designing of the particles [HIDE](https://github.com/HeapsIO/hide/) contains a dedicated 2D particle editor and
	stores the particle data in a JSON format, which then can be loaded with the `Particles.load` method:
	```haxe
	var part = new h2d.Particles();
	part.load(haxe.Json.parse(hxd.Res.my_parts_file.entry.getText()), hxd.Res.my_parts_file.entry.path);
	```
**/
@:access(h2d.SpriteBatch)
@:nullSafety(Strict)
class Particles extends h2d.Drawable {

	static inline var VERSION = 1;

	final groups : Map<String, ParticleGroup>;

	/**
		Create a new Particles instance.
		@param parent An optional parent `h2d.Object` instance to which Particles adds itself if set.
	**/
	public function new( ?parent:h2d.Object ) {
		super(parent);
		groups = [];
	}




	/**
		Add new particle group to the Particles.

		@returns Added ParticleGroup instance.
	**/
	public function addGroup( g : ParticleGroup, ?index:Int ):ParticleGroup {
		if (groups.exists(g.id)) throw 'group ${g.id} already exists';
		groups.set(g.id, g);
		return g;
	}

	/**
		Removes the group from the Particles.
	**/
	public function removeGroup( id:String ):Void {
		groups.remove(id);
	}

	/**
		Returns a group with a specified name or `null` if none found.
	**/
	public function getGroup( id : String ):Null<ParticleGroup> {
		return groups.get(id);
	}

	override function sync(ctx:h2d.RenderContext):Void {
		super.sync(ctx);
		var isDone = true;
		var dt = ctx.elapsedTime;
		for( g in groups ) {
			if ( !g.started && g.enabled ) g.start();
			g.updateTime(dt);
			if (g.batch.first != null) isDone = false;
		}
		if (isDone) onEnd();
	}

	public dynamic function onEnd():Void {
		this.remove();
	}

	override function draw(ctx:h2d.RenderContext):Void {
		var old = blendMode;
		var realX : Float = absX;
		var realY : Float = absY;
		var realA : Float = matA;
		var realB : Float = matB;
		var realC : Float = matC;
		var realD : Float = matD;

		for( g in groups )
			if( g.enabled ) {
				blendMode = g.batch.blendMode;
				if ( g.isRelative ) {
					g.batch.drawWith(ctx, this);
				} else {
					matA = 1;
					matB = 0;
					matC = 0;
					matD = 1;
					absX = 0;
					absY = 0;
					g.batch.drawWith(ctx, this);
					matA = realA;
					matB = realB;
					matC = realC;
					matD = realD;
					absX = realX;
					absY = realY;
				}
			}
		blendMode = old;
	}

	/**
		Returns an Iterator of particle groups within Particles.
	**/
	public inline function getGroups():Iterator<ParticleGroup> {
		return groups.iterator();
	}

}
