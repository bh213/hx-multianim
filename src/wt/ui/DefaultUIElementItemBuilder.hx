package wt.ui;

import wt.multianim.MultiAnimMultiResult;
import wt.multianim.MultiAnimBuilder;
import wt.ui.UIElement.UIElementListItem;
import wt.ui.UIElement.StandardUIElementStates;
import wt.ui.UIElement.UIElementItemBuilder;

class DefaultUIElementItemBuilder implements UIElementItemBuilder {
    
    final builder:MultiAnimBuilder;
    final name:String;
	var builderParams(default, null):BuilderParameters;


    function new(builder, name) {
        this.builder = builder;
        this.name = name;
    }

    public static function create(builder, name) {
        return new DefaultUIElementItemBuilder(builder, name);

    }

	public function buildItem(index:Int, item:UIElementListItem, itemWidth:Int, itemHeight:Int):MultiAnimMultiResult {
		return builder.buildWithComboParameters(name, ["itemWidth"=>itemWidth,"index"=>index, "title"=>item.name, "tile"=>item.tileName], ["status", "selected", "disabled"],  builderParams);
	}
}