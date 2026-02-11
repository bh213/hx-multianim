package bh.test;

import bh.base.FontManager;
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
			return AnimParser.parseFile(ByteData.ofBytes(byteData), filename, loader);
		}

		loader.loadMultiAnimImpl = resourceFilename -> {
			if (debugMode) trace('Loading manim: ${resourceFilename}');
			// Try direct path first (for full paths like "test/examples/38-.../file.manim"),
			// then fall back to test/examples/ prefix
			var fullPath = if (FileSystem.exists(resourceFilename)) resourceFilename else 'test/examples/${resourceFilename}';
			if (!FileSystem.exists(fullPath)) {
				throw 'File not found: $resourceFilename (tried direct and test/examples/ prefix)';
			}
			final fileContent = ByteData.ofString(File.getContent(fullPath));
			return bh.multianim.MultiAnimBuilder.load(fileContent, loader, fullPath);
		}

		loader.loadFontImpl = fontName -> {
			if (debugMode) trace('Loading font: ${fontName}');
			return FontManager.getFontByName(fontName);
		}

		return loader;
	}
}
