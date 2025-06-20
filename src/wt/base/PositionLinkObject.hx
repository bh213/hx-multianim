package wt.base;

@:nullSafety
class PositionLinkObject extends h2d.Object {

	
	public final destination : h2d.Object;
	public var linkVisibility = false;
	public var linkRemoval = false;

	public function new(destination : h2d.Object ) { 
		super(parent);
        this.destination = destination;
	}

    override function onRemove() {
        super.onRemove();
        if (linkRemoval) destination.remove();
    }

	function followObject() {
		var newPos = destination.parent.globalToLocal(new h2d.col.Point(this.absX, this.absY));
		if (destination.x != newPos.x || destination.y != newPos.y) {
			destination.setPosition(newPos.x, newPos.y);
		}

			
		


		if(linkVisibility) {
			var object = this.parent;
			while(object != null) {
				visible = visible && object.visible;
				object = object.parent;
			}
		}
	}
	override function calcAbsPos() {
		super.calcAbsPos();
		if (parent != null && destination.parent != null) followObject();
	}
	

}