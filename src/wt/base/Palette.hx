package wt.base;
using StringTools;

@:nullSafety
class Palette {
    var width:Null<Int>;
    var colors:Array<Int>;
    public function new(colors, ?width) {
        this.colors = colors;
        this.width = width;
        if (width != null) {
            if (colors.length % width != 0) throw 'invalid width for palette2d: ${colors.length} % $width != 0';
        }
    }

    public function getColorByIndex(index:Int) {
        if (index < 0 || index >= colors.length) throw 'color index $index out of range [0, ${colors.length}]';
        return colors[index];
    }
    public function getColorByIndexWraparound(index:Int) {
        if (index >= 0) return colors[index % colors.length];
        return colors[(index % colors.length) + colors.length];
    }

    public function getColor2D(x:Int, y:Int) {
        if (width == null) throw 'palette is not 2d';
        if (x < 0 || x >= width) throw 'color index x =$x out of range [0, $width]';
        if (y * width >= colors.length) throw 'color index y = $y out of range [0, ${colors.length/width}]';
        return colors[x + y*width];
    }

    public function getRow(y:Int) {
        if (width == null) throw 'palette is not 2d';
        return colors.slice(y * width, (y+1) * width);
    }


}