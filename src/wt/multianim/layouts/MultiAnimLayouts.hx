package wt.multianim.layouts;

import wt.multianim.MultiAnimBuilder.BuilderParameters;
import wt.multianim.MultiAnimParser.LayoutsDef;
import wt.base.FPoint;
import wt.base.Point;
import wt.multianim.MultiAnimParser.ResolvedIndexParameters;
import wt.multianim.CoordinateSystems.Coordinates;
import wt.multianim.CoordinateSystems.GridCoordinateSystem;
import wt.multianim.CoordinateSystems.HexCoordinateSystem;

enum LayoutContent {
	LayoutPoint(pos:Coordinates);
}

enum LayoutsType {
	Single(content:LayoutContent);
	List(list:Array<LayoutContent>);
    Sequence(varName:String, from:Int, to:Int, content:LayoutContent);
}

@:nullSafety
typedef Layout = {
	name:String,
	type:LayoutsType,
    grid:Null<GridCoordinateSystem>,
	hex:Null<HexCoordinateSystem>,
	offset:Point
};

@:nullSafety
@:allow(wt.multianim.layouts.MultiAnimLayouts)
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

  @:allow(wt.multianim.layouts.LayoutPointIterator)
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
        }
    }

    public function getIterator(name:String):Iterator<FPoint> {
        return new LayoutPointIterator(getLayout(name), this);
    }
    
    public function getPointFromLayout(l:Layout, index:Int, ?builderParams:BuilderParameters):FPoint {
        if (index < 0) throw 'index < 0 for layout ${l.name}';
        return switch l.type {
            case Single(content):
                resolve(l.grid, l.hex, l.offset, content, "i", index, builderParams); 
            case List(list):
                if (list.length <= index) throw 'cannot get layout "${l.name}" point at $index because list is only ${list.length} long';
                resolve(l.grid, l.hex, l.offset,list[index], "i", 0, builderParams);
            case Sequence(variable, from, to, content):
                if (index > to - from) throw 'index > to - from for layout ${l.name}';
                resolve(l.grid, l.hex, l.offset, content, variable, from + index, builderParams); 
        }
    }

    public function getPoint(name:String, index:Int = 0):FPoint {
        
        final l = getLayout(name);
        return getPointFromLayout(l, index);
       
    }

}