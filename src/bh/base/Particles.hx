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
}



@:access(bh.base.Particles.ParticleGroup)
private class Particle extends h2d.SpriteBatch.BatchElement {

	var group : ParticleGroup;
	public var vx : Float;
	public var vy : Float;
	public var vSize : Float;
	public var vr : Float;
	public var maxLife : Float;
	public var life : Float;
	public var delay : Float;

	public function new(group) {
		super(null);
		this.group = group;
	}

	override function update(dt:Float) {
		if( delay > 0 ) {
			delay -= dt;
			if( delay <= 0 ){
				group.init(this);
				visible = true;
			}
			else {
				visible = false;
				return true;
			}
		}

		var dv = Math.pow(1 + group.speedIncr, dt);
		vx *= dv;
		vy *= dv;
		vx += group.gravity * dt * group.sinGravityAngle;
		vy += group.gravity * dt * group.cosGravityAngle;

		x += vx * dt;
		y += vy * dt;
		life += dt;

		if( group.rotAuto )
			rotation = Math.atan2(vy, vx) + life * vr + group.rotInit * Math.PI;
		else
			rotation += vr * dt;

		if (group.incrX)
			scaleX *= Math.pow(1 + vSize, dt);
		if (group.incrY)
			scaleY *= Math.pow(1 + vSize, dt);

		var timeNormalized = life / maxLife;
		if( timeNormalized < group.fadeIn )
			alpha = Math.pow(timeNormalized / group.fadeIn, group.fadePower);
		else if( timeNormalized > group.fadeOut )
			alpha = Math.pow((1 - timeNormalized) / (1 - group.fadeOut), group.fadePower);
		else
			alpha = 1;

		

		//if( group.animationRepeat > 0 )
			// TODO

		if( timeNormalized > 1 ) {
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
class ParticleGroup {

	inline function srand() return hxd.Math.srand();
	inline function rand() return hxd.Math.random();

	final parts : Particles;
	final batch : h2d.SpriteBatch;
	var tiles : Array<h2d.Tile>;

	var started = false;
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
	var cosGravityAngle : Float;
	var sinGravityAngle : Float;

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
		When enabled, causes particles to always render relative to the emitter position, moving along with it.
		Otherwise, once emitted, particles won't follow the emitter, and will render relative to the scene origin.

		Non-relative mode is useful for simulating something like a smoke coming from a moving object,
		while relative mode things like jet flame that have to stick to its emission source.
	**/
	public var isRelative(default, null) : Bool = true;


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
	public function new(id, p, tiles) {
		this.id = id;
		this.parts = p;
		this.tiles = tiles;
		batch = new h2d.SpriteBatch(null, p);
		batch.visible = false;
		batch.hasRotationScale = true;
		batch.hasUpdate = true;
	}

	

	function start() {
		batch.clear();
		started = true;
		for( i in 0...nparts ) {
			var p = new Particle(this);
			p.delay = rand() * life * (1 - emitSync) + emitDelay;
			batch.add(p);
			
		}
	}

	function init( p : Particle ) {

		inline function getAngleFromNormalized(a : Float, rand : Float = 1.) : Float {
			var newAngle = a * 0.5 * Math.PI * rand;
			if (a < 0) newAngle += Math.PI;
			return newAngle;
		};

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
				speed *= 1 / hxd.Math.sqrt(p.vx * p.vx + p.vy * p.vy);

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
		}

		p.scale = size;
		p.rotation = rot;
		p.vSize = g.sizeIncr;
		p.vr = vrot;
		// p.t = animationRepeat == 0 ? tiles[Std.random(tiles.length)] : tiles[0];
		p.t = tiles[Std.random(tiles.length)];
		p.vx *= speed;
		p.vy *= speed;
		p.life = 0;
		p.maxLife = life;

		var rot = emitDirectionAsAngle ? Math.atan2(p.vy, p.vx) : srand() * Math.PI * g.rotInit;
		p.rotation = rot;

		if ( !isRelative ) {
			// Less this.parts access
			var parts = this.parts;
			// calcAbsPos() was already called, because during both rebuild() and Particle.update()
			// called during sync() call which calls this function if required before any of this happens.
			//parts.syncPos();

			var px = p.x;
			p.x = px * parts.matA + p.y * parts.matC + parts.absX;
			p.y = px * parts.matB + p.y * parts.matD + parts.absY;
			p.scaleX = Math.sqrt((parts.matA * parts.matA) + (parts.matC * parts.matC)) * size;
			p.scaleY = Math.sqrt((parts.matB * parts.matB) + (parts.matD * parts.matD)) * size;
			var rot = Math.atan2(parts.matB / p.scaleY, parts.matA / p.scaleX);
			p.rotation += rot;

			// Also rotate velocity.
			var cos = Math.cos(rot);
			var sin = Math.sin(rot);
			px = p.vx;
			p.vx = px * cos - p.vy * sin;
			p.vy = px * sin + p.vy * cos;
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
class Particles extends h2d.Drawable {

	static inline var VERSION = 1;

	final groups : Map<String, ParticleGroup>;

	/**
		Create a new Particles instance.
		@param parent An optional parent `h2d.Object` instance to which Particles adds itself if set.
	**/
	public function new( ?parent ) {
		super(parent);
		groups = [];
	}




	/**
		Add new particle group to the Particles.

		@returns Added ParticleGroup instance.
	**/
	public function addGroup( g : ParticleGroup, ?index ) {
		if (groups.exists(g.id)) throw 'group ${g.id} already exists';
		groups.set(g.id, g);
		return g;
	}

	/**
		Removes the group from the Particles.
	**/
	public function removeGroup( id:String) {
		groups.remove(id);
	}

	/**
		Returns a group with a specified name or `null` if none found.
	**/
	public function getGroup( id : String ) {
		return groups.get(id);
	}

	override function sync(ctx:h2d.RenderContext) {
		super.sync(ctx);
		var isDone = true;
		for( g in groups ) {
			if ( !g.started && g.enabled ) g.start();
			if (g.batch.first != null) isDone = false;
		}
		if (isDone) onEnd();
	
	}
	
	public dynamic function onEnd() {
		this.remove();
	}

	override function draw(ctx:h2d.RenderContext) {
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
	public inline function getGroups() {
		return groups.iterator();
	}

}
