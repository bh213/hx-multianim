package bh.paths;

import h2d.col.Point;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder;
import bh.base.Particles;
import bh.multianim.MultiAnimParser.BuiltHeapsComponent;
import bh.multianim.MultiAnimParser.ParticlesDef;
import bh.paths.MultiAnimPaths.Path;
import bh.stateanim.AnimationSM.AnimationCommand.SwitchState;
import bh.stateanim.AnimationSM.CommandTrigger.ExecuteNow;


enum AnimatePathEvents {
    PathStart;
    PathEnd;
    Event(event:String);
}

enum AnimatePathCommands {
    ChangeSpeed(newSpeed:Float);
    Accelerate(acceleration:Float, duration:Float);
    Event(event:AnimatePathEvents);
    AttachParticles(particlesName:String, particlesDef:ParticlesDef);
    RemoveParticles(particlesName:String);
    ChangeAnimSMState(state:String);
}

@:structInit
private class TimedAction {
    public var atRateTime:Float;
    public var action:AnimatePathCommands;
}
enum AnimatedPathPositionMode {
    RelativeTo(parent:h2d.Object);
    Absolute;
}

@:allow(bh.multianim.MultiAnimBuilder)
@:nullSafety
class AnimatedPath {
    var path:Path;
    var time:Float = 0.;
    
    var distance:Float = 0.;
    var speed:Float;
    var acceleration:Float = 0.; // Current acceleration
    var accelerationStartTime:Float = 0.; // When current acceleration started
    var accelerationDuration:Float = 0.; // How long current acceleration should last
    var prevPoint:FPoint = FPoint.zero();
    var currentPoint:FPoint = FPoint.zero();
    var angleRad:Float;
    final pathLength:Float;
    final object:BuiltHeapsComponent;
    final builder:MultiAnimBuilder;
    var h2dObject:h2d.Object;
    final positionMode:AnimatedPathPositionMode;
    
    var activeParticles:Map<String, Particles> = [];
    var timedActions:Array<TimedAction> = [];
    var currentTimedActionIndex:Int = 0;
    var isDone = false;

    function new(path:Path, speed:Float, object:BuiltHeapsComponent, positionMode:AnimatedPathPositionMode, builder) {
        this.builder = builder;
        this.path = path;
        this.speed = speed;
        this.pathLength = path.totalLength;
        if (pathLength == 0) throw 'pathLength must be > 0';
        this.object = object;
        this.h2dObject = object.toh2dObject();
        this.angleRad = 0;
        if (h2dObject.parent == null) throw 'h2dObject must be added to the scene before creating AnimatedPath';
        this.positionMode = positionMode;
    }

    function onStart() {
        this.currentPoint = calculatePosition();
        this.prevPoint = currentPoint.clone();
        execute(Event(PathStart));
            
    }

    public function addAction(element:TimedAction):Void {
        var left = 0;
        var right = timedActions.length;
        var mid: Int;
    
        while (left < right) {
            mid = Std.int((left + right) / 2);
            if (timedActions[mid].atRateTime < element.atRateTime) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        timedActions.insert(left, element);
    }

    public static function createWithTime(path:Path, time:Float, object:BuiltHeapsComponent, positionMode:AnimatedPathPositionMode, builder):AnimatedPath {
        if (time <= 0) throw 'time must be > 0';
        var speed = path.totalLength / time;
        return new AnimatedPath(path, speed, object, positionMode, builder);
    }

    
    public static function createWithSpeed(path:Path, speed:Float, object:BuiltHeapsComponent, positionMode:AnimatedPathPositionMode, builder):AnimatedPath {
        return new AnimatedPath(path, speed, object, positionMode, builder);
    }
    function execute(animePathCommand:AnimatePathCommands) {

        switch animePathCommand {
            case ChangeSpeed(newSpeed): 
                this.speed = newSpeed;
                this.acceleration = 0.; // Reset acceleration when speed is set
                this.accelerationDuration = 0.;
            case Event(e): onEvent(e);
            case AttachParticles(particlesName, particlesDef):
                final oldIndexed = builder.indexedParams;
		
                var newIndexedParams:Map<String, ResolvedIndexParameters> = [];
                newIndexedParams.set("angle", ValueF(hxd.Math.radToDeg(this.angleRad)));    
                #if MULTIANIM_TRACE
                trace(newIndexedParams);
                #end
                
                newIndexedParams.set("x", ValueF(currentPoint.x));
                newIndexedParams.set("y", ValueF(currentPoint.y));
                builder.indexedParams = newIndexedParams;
                var particles = builder.createParticleImpl(particlesDef, particlesName);
                activeParticles.set(particlesName, particles);
                h2dObject.addChild(particles);
                builder.indexedParams = oldIndexed;
            case RemoveParticles(particlesName):
                if (activeParticles.exists(particlesName)) {
                    var particles = activeParticles.get(particlesName);
                    if (particles != null && particles.parent != null) {
                        particles.parent.removeChild(particles);
                    }
                    activeParticles.remove(particlesName);
                }
                        case ChangeAnimSMState(state):
                switch object {
                    case StateAnim(a):
                        a.addCommand(SwitchState(state), ExecuteNow);
 
                    default:
                        // No-op for non-StateAnim objects
                }
            case Accelerate(acceleration, duration):
                // New acceleration overwrites current acceleration
                this.acceleration = acceleration;
                this.accelerationStartTime = time;
                this.accelerationDuration = duration;
        }
    }

    

    public inline function getAsRate():Float {
        if (pathLength <= 0) return 0;
        return distance / pathLength;
    }

    public function calculatePosition():bh.base.FPoint {
        return this.path.getPoint(getAsRate());
    }

    public dynamic function onEvent(event:AnimatePathEvents) {
    }

    public function update(dt:Float) {
        if (isDone) return;
        if (dt == 0) throw 'dt must be > 0';

        if (time == 0.) {
            onStart();
        }

        // Apply acceleration if active
        if (acceleration != 0. && accelerationDuration > 0.) {
            var elapsedAccelTime = time - accelerationStartTime;
            if (elapsedAccelTime < accelerationDuration) {
                // Apply acceleration for this frame
                speed += acceleration * dt;
            } else {
                // Acceleration period is over, reset
                acceleration = 0.;
                accelerationDuration = 0.;
            }
        }

        var currentRate = getAsRate();
        while (currentTimedActionIndex < timedActions.length) {
            final action = timedActions[currentTimedActionIndex];
            if (action.atRateTime <= currentRate) {
                execute(action.action);
                currentTimedActionIndex++;
            } else break;
        }
        time += dt;
        distance += dt * this.speed;
        
        if (distance > pathLength) {
            distance = pathLength;
            execute(Event(PathEnd));
            isDone = true;
            return;
        }
        this.prevPoint = this.currentPoint;
        this.currentPoint = calculatePosition();
        
        this.angleRad = Math.atan2(currentPoint.y - prevPoint.y, currentPoint.x - prevPoint.x);
        switch positionMode {
            case RelativeTo(parent):
                if (parent != null) {
                    var gp = parent.localToGlobal(new Point(currentPoint.x, currentPoint.y));
                    gp = h2dObject.parent.globalToLocal(gp);
                    h2dObject.setPosition(gp.x, gp.y);
                }

            case Absolute:
                final newObjPos = h2dObject.parent.globalToLocal(new Point(currentPoint.x, currentPoint.y));
                h2dObject.setPosition(newObjPos.x, newObjPos.y);
        }
        
        // trace('current rate $currentRate pos:$newObjPos');

        // Removed empty switch statement that wasn't doing anything
    }


}
