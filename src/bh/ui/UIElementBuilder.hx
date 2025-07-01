package bh.ui;
import bh.multianim.MultiAnimMultiResult;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIElement.UIElementListItem;

class UIElementBuilder {
	public var name(default, null):String;
	public var builder(default, null):MultiAnimBuilder;
	var builderParams(default, null):BuilderParameters;

	public function new(builder:MultiAnimBuilder, name:String) {
		this.name = name;
		this.builder = builder;
		if (!builder.hasNode(name)) {
			throw 'builder does not have node $name, builder: ${builder.sourceName}';
		}
	}

	public static function create(builder:MultiAnimBuilder, name:String) {
		return new UIElementBuilder(builder, name);
	}

	public function withUpdatedName(name:String):UIElementBuilder {
		return new UIElementBuilder(this.builder, name);
	}

	public function buildItem(index:Int, item:UIElementListItem, itemWidth:Int, itemHeight:Int):MultiAnimMultiResult {
		return builder.buildWithComboParameters(name, [
			"itemWidth" => itemWidth,
			"index" => index,
			"title" => item.name,
			"tile" => item.tileName
		], ["status", "selected", "disabled"], builderParams);
	}
}
