package bh.base;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.GeneratedTileType;
import bh.multianim.MultiAnimParser.PlaceholderTypes;
import bh.multianim.MultiAnimParser.AutotileFormat;
import h2d.Font;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimParser.AnimationStateSelector;
import hxd.res.Atlas;
import h2d.Tile;
import bh.stateanim.AnimParser;

enum ResolvedGeneratedTileType {
    Cross(width:Int, height:Int, color:Int);
	SolidColor(width:Int, height:Int, color:Int);
	SolidColorWithText(width:Int, height:Int, color:Int, text:String, textColor:Int, font:String);
	AutotileRef(format:AutotileFormat, tileIndex:Int, tileSize:Int, edgeColor:Int, fillColor:Int);
}

interface ResourceLoader {
    function loadSheet2(sheetName:String):bh.base.Atlas2;
    function loadSheet(sheetName:String):hxd.res.Atlas;
	function loadTile(filename:String):h2d.Tile;
    function loadMultiAnim(resourceFilename:String):MultiAnimBuilder;
    function loadHXDResource(filename:String):hxd.res.Any;
    function loadFont(font:String):h2d.Font;
    function loadAnimParser(filename:String):AnimParserResult;
    function createAnimSM(filename:String, selector:AnimationStateSelector):AnimationSM;
    function getOrCreatePlaceholder(key: ResolvedGeneratedTileType, builder:ResolvedGeneratedTileType->h2d.Tile):h2d.Tile;
}


class CachingResourceLoader implements ResourceLoader {


    var animSMCache:Map<String, AnimParserResult> = [];
    var multiAnimCache:Map<String, MultiAnimBuilder> = [];
    var tileCache:Map<String, h2d.Tile> = [];
    var placeholderCache:Map<ResolvedGeneratedTileType, h2d.Tile> = [];
    var atlas2Cache:Map<String, Atlas2> = [];
    var atlasCache:Map<String, Atlas> = [];
    var fontCache:Map<String, h2d.Font> = [];
    var multiAnimCycleDetection = [];
    public function new() {
    }

	
    public dynamic function loadSheet2Impl(sheetName:String):Atlas2 {
		throw new haxe.exceptions.NotImplementedException();
	}

	public dynamic function loadSheetImpl(sheetName:String):Atlas {
		throw new haxe.exceptions.NotImplementedException();
	}

	public dynamic function loadTileImpl(filename:String):Tile {
		var res:hxd.res.Any = loadHXDResourceImpl(filename);
        if (res == null) throw 'could not load resource "$filename';
        return res.toTile();
	}

    public dynamic function loadMultiAnimImpl(name:String):MultiAnimBuilder {
        throw new haxe.exceptions.NotImplementedException();
    }

    public dynamic function loadHXDResourceImpl(filename:String):hxd.res.Any {
		throw new haxe.exceptions.NotImplementedException();
	}

    public dynamic function loadFontImpl(font:String):h2d.Font {
		throw new haxe.exceptions.NotImplementedException();
	}

	public dynamic function loadAnimSMImpl(filename:String):AnimParserResult {
		throw new haxe.exceptions.NotImplementedException();
	}

    function  cachedGet<T, K>(cache:Map<K, T>, cacheKey:K, get:K->Null<T>) {
        var value = cache.get(cacheKey);
        if (value == null) {
            value = get(cacheKey);
            cache.set(cacheKey, value);
        }
        return value;
    }
    
    
    public function loadSheet2(sheetName:String):Atlas2 {
        return cachedGet(atlas2Cache, sheetName, sheetName->loadSheet2Impl(sheetName));
	}

	public function loadSheet(sheetName:String):Atlas {
        return cachedGet(atlasCache, sheetName, sheetName->loadSheetImpl(sheetName));
	}

	public function loadTile(filename:String):Tile {
        var tile = cachedGet(tileCache, filename, filename->loadTileImpl(filename));
        return tile.clone();
	}

    public function loadFont(fontName:String):h2d.Font {
        return cachedGet(fontCache, fontName, fontname->loadFontImpl(fontname));
	}

    public function loadAnimParser(filename:String):AnimParserResult {
        return cachedGet(animSMCache, filename, filename->loadAnimSMImpl(filename));
    }
	public function createAnimSM(filename:String, selector:AnimationStateSelector):AnimationSM {
        try {
            final parser = loadAnimParser(filename);
            return parser.createAnimSM(selector);
        } catch(e) {
            throw 'could not load animSM "$filename": $e';
        }
	}

    public function clearCache() {
        animSMCache.clear();
        tileCache.clear();
        atlasCache.clear();
        atlas2Cache.clear();
        fontCache.clear();
        placeholderCache.clear();
        multiAnimCache.clear();
        multiAnimCycleDetection = [];
    }

	public function getOrCreatePlaceholder(key:ResolvedGeneratedTileType, builderFunction:ResolvedGeneratedTileType -> Tile):Tile {
        return cachedGet(placeholderCache, key, builderFunction);
	}

	public function loadHXDResource(filename:String):hxd.res.Any {
		return loadHXDResourceImpl(filename);
	}

    public function loadMultiAnim(resourceFilename:String):MultiAnimBuilder {
    
        var key = resourceFilename;
        if (multiAnimCycleDetection.contains(key)) throw 'cyclic dependency in multiAnim $key: path ${multiAnimCycleDetection}';
        multiAnimCycleDetection.push(key);
        
        var retVal =  cachedGet(multiAnimCache, key, k ->loadMultiAnimImpl(k));
        
        multiAnimCycleDetection.remove(key);
        return retVal;
    }
}
