package bh.ui;

import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;

/**
	A display-only bar: its programmable takes `value` (0..100) and draws the fill; a HUD sets the
	value every frame. The programmable is built once, incrementally, and `setIntValue` changes its
	`value` in place (`getResult()` stays the same object); a design whose `value` the incremental
	context cannot follow (an `untracked_param` error on the first change: an interactive id or a
	stateanim selector in a param-dependent repeat) is rebuilt whole on every change instead.
**/
class UIMultiAnimProgressBar implements UIElement implements UIElementNumberValue implements UIElementSyncRedraw {
	var builder:MultiAnimBuilder;
	final buildName:String;
	var currentValue:Int;
	var root:h2d.Object;
	var currentResult:Null<BuilderResult> = null;
	var lastBuiltValue:Int = -1;
	/** False once the design proved it cannot follow `value` in place; it is rebuilt whole from then on. */
	public var incremental(default, null):Bool = true;

	public var requestRedraw(default, null):Bool = true;

	var extraParams:Null<Map<String, Dynamic>>;

	function new(builder:MultiAnimBuilder, name:String, initialValue:Int, ?extraParams:Null<Map<String, Dynamic>>) {
		this.root = new h2d.Object();
		this.builder = builder;
		this.buildName = name;
		this.currentValue = initialValue;
		this.extraParams = extraParams;
	}

	public static function create(builder:MultiAnimBuilder, name:String, initialValue:Int = 0, ?extraParams:Null<Map<String, Dynamic>>) {
		return new UIMultiAnimProgressBar(builder, name, initialValue, extraParams);
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.currentResult != null && incremental) {
			if (lastBuiltValue == currentValue)
				return;
			try {
				this.currentResult.setParameter("value", currentValue);
				lastBuiltValue = currentValue;
				return;
			} catch (e:BuilderError) {
				if (e.code != "untracked_param")
					throw e;
				incremental = false; // rebuilt whole below, and from now on
			}
		}
		if (this.currentResult != null && this.currentResult.object != null)
			this.currentResult.object.remove();
		var params:Map<String, Dynamic> = ["value" => currentValue];
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);
		this.currentResult = builder.buildWithParameters(buildName, params, null, null, incremental);
		if (this.currentResult == null)
			throw 'could not build #${buildName}';
		if (this.currentResult.object == null)
			throw 'build #${buildName} returned null object';
		lastBuiltValue = currentValue;
		root.addChild(this.currentResult.object);
	}

	/** The built programmable: the same object across value changes while `incremental`. */
	public function getResult():Null<BuilderResult> {
		return currentResult;
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
