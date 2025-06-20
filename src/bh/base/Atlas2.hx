package bh.base;

// https://www.codeandweb.com/texturepacker/documentation/custom-exporter#preparations-before-creating-your-own-exporter
import h2d.ScaleGrid;
import bh.stateanim.AnimationSM.AnimationFrame;

class Atlas2 extends hxd.res.Resource.Resource {

	var contents : Map<String,Array<{ t : h2d.Tile, width : Int, height : Int, offsetX: Int, offsetY:Int, split:Array<Int> }>>;

    function toAnimationFrame(content) {
        return  new AnimationFrame(content.t, 0, content.offsetX, content.offsetY, content.width, content.height);
    }

	 public static function toAtlas2(resource:hxd.res.Any) {
		return hxd.Res.loader.loadCache(resource.entry.path, bh.base.Atlas2);
	 }
	

	public function get( name : String) : AnimationFrame {
		var c = getContents().get(name);
		if( c == null )
			return null;
		var t = c[0];
		if( t == null )
			return null;
		return toAnimationFrame(t);
	}

	public function getNinePatch( name : String) : ScaleGrid {
		var c = getContents().get(name);
		if( c == null )
			return null;
		var t = c[0];
		if( t == null )
			return null;

		var splitLen = t.split.length;
		if (splitLen > 0) {
			if (splitLen != 4)  throw '${name} has invalid 9-patch: ${t.split}';
			return new ScaleGrid(t.t, t.split[0], t.split[2], t.split[1], t.split[3]);
		}

		throw '${name} is not a 9-patch';
	}

	public function getAnim( ?name : String) : Array<AnimationFrame> {
		if( name == null ) {
			var cont = getContents().keys();
			name = cont.next();
			if( cont.hasNext() )
				throw "Altas has several items in it " + Lambda.array( contents );
		}
		var c = getContents().get(name);
		if( c == null )
			return null;
		return [for( t in c ) if( t == null ) null else toAnimationFrame(t)];
	}


	public function getContents() {
		if( contents != null )
			return contents;

		contents = new Map();
		var lines = entry.getText().split("\n");

		var basePath = entry.path.split("/");
		basePath.pop();
		var basePath = basePath.join("/");
		if( basePath.length > 0 ) basePath += "/";
		while( lines.length > 0 ) {
			var line = StringTools.trim(lines.shift());
			if ( line == "" ) continue;
            final tileFilename = basePath + line;
			var tileFile = hxd.res.Loader.currentInstance.load(tileFilename).toTile();
			while( lines.length > 0 ) {
				if( lines[0].indexOf(":") < 0 ) break;
				var line = StringTools.trim(lines.shift()).split(": ");
				switch( line[0] ) {
				case "size":
					var wh = line[1].split(",");
					var parsedWidth = Std.parseInt(wh[0]);
                    var parsedHeight = Std.parseInt(wh[1]);
					if (parsedWidth != tileFile.width || parsedHeight != tileFile.height) throw 'file ${tileFilename} does not match';
				default:
				}
			}
			while( lines.length > 0 ) {
				var line = StringTools.trim(lines.shift());
				if( line == "" ) break;
				var prop = line.split(": ");
				if( prop.length > 1 ) continue;
				var key = line;
				var tileX = 0, tileY = 0, tileW = 0, tileH = 0, origW = 0, origH = 0, index = 0, offsetX = 0, offsetY = 0;
				var split:Array<Int> = [];
				while( lines.length > 0 ) {
					var line = StringTools.trim(lines.shift());
					var prop = line.split(": ");
					if( prop.length == 1 ) {
						lines.unshift(line);
						break;
					}
					var v = prop[1];
					switch( prop[0] ) {
					case "rotate":
						if( v == "true" ) throw "Rotation not supported in atlas";
					case "xy":
						final vals = v.split(", ");
						tileX = Std.parseInt(vals[0]);
						tileY = Std.parseInt(vals[1]);
					case "size":
						final vals = v.split(", ");
						tileW = Std.parseInt(vals[0]);
						tileH = Std.parseInt(vals[1]);
					case "offset":
						final vals = v.split(", ");
						offsetX = Std.parseInt(vals[0]);
						offsetY = Std.parseInt(vals[1]);
					case "orig":
						final vals = v.split(", ");
						origW = Std.parseInt(vals[0]);
						origH = Std.parseInt(vals[1]);
					case "split":
						split = v.split(", ").map(x->{
							var num = Std.parseInt(x);
							if (num == null) throw 'not a number ${x}';
							return cast (num, Int);
						});
					case "index":
						index = Std.parseInt(v);
						if( index < 0 ) index = 0;
					default:
						trace("Unknown prop " + prop[0]);
					}
				}

				var t = tileFile.sub(tileX, tileY, tileW, tileH, 0, 0);
				var tl = contents.get(key);
				if( tl == null ) {
					tl = [];
					contents.set(key, tl);
				}
				tl[index] = { t : t, width : origW, height : origH, offsetX:offsetX, offsetY:offsetY, split:split };
			}
		}

		// remove first element if index started at 1 instead of 0
		for( tl in contents )
			if( tl.length > 1 && tl[0] == null ) tl.shift();
		return contents;
	}
 
}
