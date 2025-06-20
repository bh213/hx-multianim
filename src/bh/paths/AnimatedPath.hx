package bh.paths;

import h2d.col.Point;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder;
import bh.base.Particles;
import bh.multianim.MultiAnimParser.BuiltHeapsComponent;
import bh.multianim.MultiAnimParser.ParticlesDef;
import bh.paths.MultiAnimPaths.Path;


enum AnimatePathEvents {
    PathStart;
    PathEnd;
    Event(event:String);
}

enum AnimatePathCommands {
    ChangeSpeed(newSpeed:Float);
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
    var particles:Map<String, Particles> = [];

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
        var speed = path.totalLength / time;
        return new AnimatedPath(path, speed, object, positionMode, builder);
    }

    
    public static function createWithSpeed(path:Path, speed:Float, object:BuiltHeapsComponent, positionMode:AnimatedPathPositionMode, builder):AnimatedPath {
        return new AnimatedPath(path, speed, object, positionMode, builder);
    }
    function execute(animePathCommand:AnimatePathCommands) {

        switch animePathCommand {
            case ChangeSpeed(newSpeed): this.speed = newSpeed;
            case Event(e): onEvent(e);
            case AttachParticles(particlesName, particlesDef):
                final oldIndexed = builder.indexedParams;
		
                var newIndexedParams:Map<String, ResolvedIndexParameters> = [];
                newIndexedParams.set("angle", ValueF(hxd.Math.radToDeg(this.angleRad)));    
                trace(newIndexedParams);
                
                newIndexedParams.set("x", ValueF(currentPoint.x));
                newIndexedParams.set("y", ValueF(currentPoint.y));
                builder.indexedParams = newIndexedParams;
                var particles = builder.createParticleImpl(particlesDef, particlesName);
                activeParticles.set(particlesName, particles);
                h2dObject.addChild(particles);
                builder.indexedParams = oldIndexed;
            case RemoveParticles(particlesName):
            case ChangeAnimSMState(state):
        }
    }

    

    public inline function getAsRate():Float {
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
                var gp = parent.localToGlobal(new Point(currentPoint.x, currentPoint.y));
                gp = h2dObject.parent.globalToLocal(gp);
                h2dObject.setPosition(gp.x, gp.y);

            case Absolute:
                final newObjPos = h2dObject.parent.globalToLocal(new Point(currentPoint.x, currentPoint.y));
                h2dObject.setPosition(newObjPos.x, newObjPos.y);
    

        }
        
        // trace('current rate $currentRate pos:$newObjPos');

        switch object {
            case StateAnim(a):
            case Particles(p):
            default: 
        }


    }


}
