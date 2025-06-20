package wt.base;

import wt.base.FontManager;
import h2d.Font;
import h2d.Tile;
import h2d.Object;
import h2d.col.Bounds;

@:nullSafety
enum MultiAnimObjectData {
	MAInteractive(width:Int, height:Int, identifier:String);
}

@:nullSafety
class MAObject extends h2d.Object {
	public final multiAnimType:MultiAnimObjectData;

    
	public function new(maType, debug:Bool, ?parent) {
		super(parent);
		multiAnimType = maType;

        switch maType {
            case MAInteractive(width, height, identifier):
                if (debug) {
                    var bitmap = new h2d.Bitmap(Tile.fromColor(0xFFFF8000, width, height, 0.5), this);
                    var text = new h2d.Text(FontManager.getFontByName("default"), bitmap);
                    text.text = '${identifier}';
                    text.textAlign = Center;
                    text.y = height/2 - text.textHeight/2;
                    text.maxWidth = width;
                }
        }
        
	}

    override function getBoundsRec(relativeTo:Object, out:Bounds, forSize:Bool) {
        super.getBoundsRec(relativeTo, out, forSize);

        switch multiAnimType {
            case MAInteractive(width, height, identifier):
                addBounds(relativeTo, out, 0, 0, width, height);
        }
    }
}
