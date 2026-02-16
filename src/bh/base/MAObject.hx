package bh.base;

import bh.base.FontManager;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import h2d.Font;
import h2d.Tile;
import h2d.Object;
import h2d.col.Bounds;

@:nullSafety
enum MultiAnimObjectData {
	MAInteractive(width:Int, height:Int, identifier:String, metadata:ResolvedSettings);
    MADraggable(width:Int, height:Int);
}

@:nullSafety
class MAObject extends h2d.Object {
	public final multiAnimType:MultiAnimObjectData;

    
	public function new(maType, debug:Bool, ?parent) {
		super(parent);
		multiAnimType = maType;

        switch maType {
            case MAInteractive(width, height, identifier, _):
                if (debug) {
                    var bitmap = new h2d.Bitmap(Tile.fromColor(0xFFFF8000, width, height, 0.5), this);
                    var font = hxd.res.DefaultFont.get();
                    var text = new h2d.Text(font, bitmap);
                    text.text = 'interactive ${identifier}';
                    text.textAlign = Center;
                    text.y = height/2 - text.textHeight/2;
                    text.maxWidth = width;
                }
            case MADraggable(width, height):
                if (debug) {
                    var bitmap = new h2d.Bitmap(Tile.fromColor(0xFFFF8000, width, height, 0.5), this);
                    var font = hxd.res.DefaultFont.get();
                    var text = new h2d.Text(font, bitmap);
                    text.text = 'draggable';
                    text.textAlign = Center;
                    text.y = height/2 - text.textHeight/2;
                    text.maxWidth = width;
                }
        }
        
	}

    override function getBoundsRec(relativeTo:Object, out:Bounds, forSize:Bool) {
        super.getBoundsRec(relativeTo, out, forSize);

        switch multiAnimType {
            case MAInteractive(width, height, _, _):
                addBounds(relativeTo, out, 0, 0, width, height);
            case MADraggable(width, height):
                
        }
    }
}
