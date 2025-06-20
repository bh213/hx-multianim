package wt.stateanim;

import h2d.Object;
import h2d.col.Bounds;
import h2d.Drawable;
import h2d.Bitmap;

class GdxTile extends h2d.Object {
    var tile:h2d.Tile;
    var width:Int;
    var height:Int; 
    var offsetX:Int;
    var offsetY:Int;
    function new(tile, width, height, offsetX, offsetY, ?parent) {
        super(parent);
        this.tile = tile;
        this.width = width;
        this.height = height;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
    }

    public override function getBoundsRec(relativeTo:Object, out:Bounds, forSize:Bool) {
        super.getBoundsRec(relativeTo, out, forSize);
        if( tile != null ) addBounds(relativeTo, out, 0, 0, width, height);
    }
}