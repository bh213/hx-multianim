package bh.test;

import bh.base.ResourceLoader;
import bh.stateanim.AnimParser;
import byte.ByteData;
import sys.io.File;
import sys.FileSystem;

using bh.base.Atlas2;

/**
 * Resource loader for tests - uses CachingResourceLoader with file system access
 */
class TestResourceLoader {
	public static function createLoader(debugMode:Bool = false):bh.base.ResourceLoader.CachingResourceLoader {
		final loader = new bh.base.ResourceLoader.CachingResourceLoader();

		loader.loadSheet2Impl = sheetName -> {
			if (debugMode) trace('Loading atlas2: ${sheetName}.atlas2');
			// Use hxd.Res to load the atlas2 file so it can properly resolve the PNG
			return hxd.Res.load('${sheetName}.atlas2').toAtlas2();
		};

		loader.loadSheetImpl = sheetName -> {
			throw "loadSheet not implemented in test loader (use loadSheet2 instead)";
		};

		loader.loadHXDResourceImpl = filename -> {
			if (debugMode) trace('Loading hxd resource: ${filename}');
			return hxd.Res.load(filename);
		}

		loader.loadAnimSMImpl = filename -> {
			if (debugMode) trace('Loading stateanim: ${filename}');
			final byteData = hxd.Res.load(filename).entry.getBytes();
			if (debugMode) trace('Loaded ${byteData.length} bytes for ${filename}');
			return AnimParser.parseFile(ByteData.ofBytes(byteData), loader);
		}

		loader.loadMultiAnimImpl = resourceFilename -> {
			if (debugMode) trace('Loading manim: ${resourceFilename}');
			var fullPath = 'test/examples/${resourceFilename}';
			if (!FileSystem.exists(fullPath)) {
				throw 'File not found: $fullPath';
			}
			final fileContent = ByteData.ofString(File.getContent(fullPath));
			return bh.multianim.MultiAnimBuilder.load(fileContent, loader, fullPath);
		}

		loader.loadFontImpl = filename -> {
			if (debugMode) trace('Loading font: ${filename}');
			// For now, return default font for all test requests
			// Could be extended to use FontManager if needed
			return hxd.res.DefaultFont.get();
		}

		return loader;
	}
}
