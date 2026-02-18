package bh.ui;
import bh.multianim.MultiAnimMultiResult;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.MultiAnimParser.TileSource;
import bh.multianim.MultiAnimParser.GeneratedTileType;
import bh.multianim.MultiAnimParser.ReferenceableValue;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIElement.TileRef;

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
		var params:Map<String, Dynamic> = [
			"itemWidth" => itemWidth,
			"index" => index,
			"title" => item.name,
		];

		var tileSource:Null<TileSource> = null;
		if (item.tileRef != null) {
			tileSource = switch (item.tileRef) {
				case TRFile(filename): TSFile(RVString(filename));
				case TRSheet(sheet, tileName): TSSheet(RVString(sheet), RVString(tileName));
				case TRSheetIndex(sheet, tileName, idx): TSSheetWithIndex(RVString(sheet), RVString(tileName), RVInteger(idx));
				case TRGeneratedRect(w, h): TSGenerated(SolidColor(RVInteger(w), RVInteger(h), RVInteger(0x00000000)));
				case TRGeneratedRectColor(w, h, color): TSGenerated(SolidColor(RVInteger(w), RVInteger(h), RVInteger(color)));
				#if !macro
				case TRTile(tile): TSTile(tile);
				#end
			};
		} else if (item.tileName != null && item.tileName != "") {
			tileSource = TSFile(RVString(item.tileName));
		}

		if (tileSource != null) {
			params.set("tile", ResolvedIndexParameters.TileSourceValue(tileSource));
			params.set("images", "tile");
		} else {
			params.set("images", "none");
		}

		return builder.buildWithComboParameters(name, params, ["status", "selected", "disabled"], builderParams);
	}
}
