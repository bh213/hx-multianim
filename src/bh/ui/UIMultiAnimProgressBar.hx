package bh.ui;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;

class UIMultiAnimProgressBar implements UIElement implements UIElementNumberValue implements UIElementSyncRedraw {
	var builder:MultiAnimBuilder;
	final buildName:String;
	var currentValue:Int;
	var root:h2d.Object;
	var currentResult:Null<BuilderResult> = null;

	public var requestRedraw(default, null):Bool = true;

	function new(builder:MultiAnimBuilder, name:String, initialValue:Int) {
		this.root = new h2d.Object();
		this.builder = builder;
		this.buildName = name;
		this.currentValue = initialValue;
	}

	public static function create(builder:MultiAnimBuilder, name:String, initialValue:Int = 0) {
		return new UIMultiAnimProgressBar(builder, name, initialValue);
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.currentResult != null && this.currentResult.object != null)
			this.currentResult.object.remove();
		this.currentResult = builder.buildWithParameters(buildName, ["value" => currentValue]);
		if (this.currentResult == null)
			throw 'could not build #${buildName}';
		if (this.currentResult.object == null)
			throw 'build #${buildName} returned null object';
		root.addChild(this.currentResult.object);
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	public function setIntValue(v:Int) {
		currentValue = Std.int(hxd.Math.clamp(v, 0, 100));
		this.requestRedraw = true;
	}

	public function getIntValue():Int {
		return currentValue;
	}

	public function clear() {
		this.currentResult = null;
		this.builder = null;
	}
}
