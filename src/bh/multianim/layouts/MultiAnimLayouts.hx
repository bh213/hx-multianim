package bh.multianim.layouts;

import bh.multianim.MultiAnimBuilder.BuilderParameters;
import bh.multianim.MultiAnimParser.LayoutsDef;
import bh.base.FPoint;
import bh.base.Point;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.CoordinateSystems.Coordinates;
import bh.multianim.CoordinateSystems.GridCoordinateSystem;
import bh.multianim.CoordinateSystems.HexCoordinateSystem;
import bh.multianim.layouts.LayoutTypes;

@:nullSafety
@:allow(bh.multianim.layouts.MultiAnimLayouts)
class LayoutPointIterator {
    var index:Int;
    final length:Int;
    final layout:Layout;
    final animLayout:MultiAnimLayouts;

    function new(layout, animLayout) {
      this.animLayout = animLayout;
      this.layout = layout;
      this.index = 0;
      this.length = animLayout.getLayoutSequenceLength(layout);
    }

    public function hasNext() {
      return index < length;
    }

    public function next() {
      return animLayout.getPointFromLayout(layout, index++);
    }
  }

  @:allow(bh.multianim.layouts.LayoutPointIterator)
class MultiAnimLayouts {

    final layoutsDef:LayoutsDef;
    final builder:MultiAnimBuilder;
    public function new(layoutsDef, builder) {
        this.layoutsDef = layoutsDef;
        this.builder = builder;

    }

    inline function getLayout(name:String) {
        var l = layoutsDef.get(name);
        if (l == null) throw 'layout $name not found';
        return l;
    }

    inline function generateParameters(name, i):Map<String, ResolvedIndexParameters> {
        return [name=>Value(i)];
    }

    inline function resolve(gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>, offset:Point, content:LayoutContent, indexName:String, index:Int, ?builderParams:BuilderParameters):FPoint {
        var pt = switch content {
            case LayoutPoint(pos):
                var oldIndexed = builder.indexedParams;
                builder.indexedParams = generateParameters(indexName, index);
                var pos = builder.calculatePosition(pos, gridCoordinateSystem, hexCoordinateSystem);
                builder.indexedParams = oldIndexed;
                pos;
        }
        pt.x += offset.x;
        pt.y += offset.y;
        return pt;
    }

    public function getLayoutSequenceLengthByLayoutName(layoutName:String):Int {
        return getLayoutSequenceLength(getLayout(layoutName));
    }

    function getLayoutSequenceLength(l:Layout):Int {
        return switch l.type {
            case Single(content):1;
            case List(list): list.length;
            case Sequence(varName, from, to, content): to - from + 1;
            case Grid(cols, rows, _, _): cols * rows;
        }
    }

    public function getIterator(name:String):Iterator<FPoint> {
        return new LayoutPointIterator(getLayout(name), this);
    }

    public function getPointFromLayout(l:Layout, index:Int, ?builderParams:BuilderParameters):FPoint {
        if (index < 0) throw 'index < 0 for layout ${l.name}';
        var pt = switch l.type {
            case Single(content):
                resolve(l.grid, l.hex, l.offset, content, "i", index, builderParams);
            case List(list):
                if (list.length <= index) throw 'cannot get layout "${l.name}" point at $index because list is only ${list.length} long';
                resolve(l.grid, l.hex, l.offset,list[index], "i", 0, builderParams);
            case Sequence(variable, from, to, content):
                if (index > to - from) throw 'index > to - from for layout ${l.name}';
                resolve(l.grid, l.hex, l.offset, content, variable, from + index, builderParams);
            case Grid(cols, rows, cellW, cellH):
                if (index >= cols * rows) throw 'index $index out of bounds for grid layout ${l.name} (${cols}x${rows})';
                var col = index % cols;
                var row = Std.int(index / cols);
                new FPoint(l.offset.x + col * cellW, l.offset.y + row * cellH);
        }
        return applyAlignment(pt, l);
    }

    function applyAlignment(pt:FPoint, l:Layout):FPoint {
        if (l.alignX == Left && l.alignY == Top) return pt;
        final scene = builder.builderParams.scene;
        if (scene == null) throw 'layout "${l.name}" uses align but no scene is available';
        if (l.alignX != Left) {
            pt.x = switch l.alignX {
                case Left: pt.x;
                case Center: scene.width / 2 + pt.x;
                case Right: scene.width - pt.x;
            }
        }
        if (l.alignY != Top) {
            pt.y = switch l.alignY {
                case Top: pt.y;
                case Center: scene.height / 2 + pt.y;
                case Bottom: scene.height - pt.y;
            }
        }
        return pt;
    }

    public function getPoint(name:String, index:Int = 0):FPoint {

        final l = getLayout(name);
        return getPointFromLayout(l, index);

    }

}
