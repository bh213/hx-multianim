import hxd.Key;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Text;
import h2d.Interactive;
import h2d.Graphics;
import h3d.mat.Texture;
import hxd.Pixels;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.AutotileDef;
import bh.multianim.MultiAnimParser.AutotileFormat;
import bh.multianim.MultiAnimParser.AutotileSource;
import bh.multianim.MultiAnimParser.NodeType;
import bh.multianim.MultiAnimParser.ReferenceableValue;
import bh.base.ResourceLoader;
import bh.base.Autotile;
import bh.base.FontManager;
import bh.base.MacroUtils;
import bh.multianim.MultiAnimBuilder;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.UIScreen;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimButton;
import bh.ui.UIMultiAnimSlider;

using StringTools;
using bh.base.Atlas2;

class AutotileMapper extends hxd.App {
	// CLI arguments (parsed in main before App construction)
	static var argManimFile:String;
	static var argAutotileName:Null<String>;

	var manimFile:String;
	var autotileName:Null<String>;
	var workingDir:String;

	// Parsed data
	var autotileDef:AutotileDef;
	var regionTiles:Array<Tile>;
	var regionSheetTile:Tile; // Full region as single tile
	var tileSize:Int;
	var tilesPerRow:Int;
	var tilesPerCol:Int;
	var totalTiles:Int;

	// Current mapping state
	var currentMapping:Map<Int, Int>;
	var autoDetectedTiles:Map<Int, Bool>; // Track which blob47 tiles were auto-detected

	// UI elements
	var regionDisplay:h2d.Object;
	var blob47Display:h2d.Object;
	var demoPreview:h2d.Object;
	var ratioPreview:h2d.Object;
	var exportText:Text;

	// Selection state
	var selectedRegionTile:Int = -1;
	var selectedBlob47Tile:Int = -1;
	var hoveredRegionTile:Int = -1;
	var hoveredBlob47Tile:Int = -1;

	// Drag and drop state
	var dragRegionTileIdx:Int = -1;
	var dragBitmap:Null<Bitmap> = null;
	var dragOverlay:Null<Graphics> = null;

	// Cross-highlight overlays
	var demoHighlight:Null<Graphics> = null;
	var regionHighlight:Null<Graphics> = null;
	var blob47Highlight:Null<Graphics> = null;
	var demoCellBlob47:Array<{x:Int, y:Int, blob47Idx:Int}> = [];
	var hoveredDemoBlob47:Int = -1;

	// Blob47 cell positions for grouped layout (tile index -> pixel position)
	var blob47CellPos:Array<{x:Float, y:Float}> = [];
	var blob47CellWidth:Float = 0;
	var blob47CellHeight:Float = 0;

	// Blob47 grouped layout: rows of {label, tiles}
	static var blob47Layout:Array<{label:String, tiles:Array<Int>}> = [
		{label: "1 card", tiles: [0, 1, 2, 5, 13]},
		{label: "2 opp", tiles: [6, 15]},
		{label: "2 adj", tiles: [3, 4, 7, 10, 18, 26, 14, 34]},
		{label: "N+E+S", tiles: [8, 9, 11, 12]},
		{label: "N+E+W", tiles: [16, 17, 35, 36]},
		{label: "E+S+W", tiles: [20, 23, 28, 31]},
		{label: "N+S+W", tiles: [19, 27, 37, 42]},
		{label: "NESW", tiles: [21, 22, 24, 25, 29, 30, 32, 33, 38, 39, 40, 41, 43, 44, 45, 46]},
	];

	// Display settings (mutable for zoom sliders, public for macro access)
	public var regionTileScale:Int = 4;
	public var blob47TileScale:Int = 8;
	public var demoPreviewScale:Int = 2;
	static inline var TILE_SPACING = 2;
	static inline var PAIR_SPACING = 10; // Gap between blob47 pairs (between mapped tile and next demo tile)


	// 3x3 subtile analysis settings (edge-middle-edge ratio, should sum to 100)
	public var subtileEdgeRatio:Int = 25; // % for edge bands (N, S, E, W)
	var subtileMiddleRatio:Int = 50; // % for middle (remaining after edges)

	// Resource loader and screen manager
	var resourceLoader:CachingResourceLoader;
	var screenManager:ScreenManager;
	var toolbarScreen:AutotileToolbarScreen;

	override function init() {
		// Copy static args parsed in main()
		manimFile = argManimFile;
		autotileName = argAutotileName;

		if (manimFile == null) {
			showError("Usage: hl autotile-mapper.hl <file.manim> [#autotileName]");
			return;
		}

		// Set working directory for relative paths
		workingDir = haxe.io.Path.directory(manimFile);
		if (workingDir == "") workingDir = ".";

		resourceLoader = createResourceLoader();

		// Initialize Heaps resource system (needed for atlas2, fonts)
		hxd.Res.initLocal();

		// Register fonts for std.manim UI components
		FontManager.registerFont("dd", hxd.Res.fonts.digitaldisco.toFont(), 0, -1);
		FontManager.registerFont("m6x11", hxd.Res.fonts.m6x11.toFont());

		try {
			loadAndParseManim();
		} catch (e) {
			showError('Error: ${e}');
			return;
		}

		// Set up ScreenManager with our resource loader (searches working dir for .manim files)
		// Must be created before buildUI() so containers from .manim are available
		screenManager = new ScreenManager(this, resourceLoader);
		toolbarScreen = new AutotileToolbarScreen(screenManager, this);
		screenManager.addScreen("toolbar", toolbarScreen);
		if (screenManager.isScreenFailed(toolbarScreen)) {
			trace('Toolbar screen failed: ${screenManager.getScreenFailedError(toolbarScreen)}');
		}
		screenManager.updateScreenMode(Single(toolbarScreen));

		try {
			buildUI();
		} catch (e) {
			showError('Error building UI: ${e}');
			return;
		}

		final window = hxd.Window.getInstance();
		window.resize(2560, 1440);
		s2d.scaleMode = AutoZoom(2560, 1440, true);

		window.addEventTarget(event -> {
			switch event.kind {
				case EKeyDown if (event.keyCode == Key.Q):
					Sys.exit(0);
				case EKeyDown if (event.keyCode == Key.A):
					autodetect();
				case EKeyDown if (event.keyCode == Key.E):
					exportMapping();
				case EKeyDown if (event.keyCode == Key.C):
					clearMapping();
				case EKeyDown if (event.keyCode == Key.R):
					reloadManim();
				case EMove:
					if (dragRegionTileIdx >= 0) {
						updateDrag(event.relX, event.relY);
					}
				case ERelease:
					if (dragRegionTileIdx >= 0) {
						endDrag(event.relX, event.relY);
					}
				case EReleaseOutside:
					cancelDrag();
				case EWheel:
					handleMouseWheel(event.relX, event.relY, event.wheelDelta);
				default:
			}
		});

		engine.backgroundColor = 0x303030;
	}

	override function update(dt:Float) {
		if (screenManager != null) {
			try {
				screenManager.update(dt);
			} catch (e) {
				trace('ScreenManager update error: $e');
				screenManager = null;
			}
		}
	}

	static function parseArguments() {
		final args = Sys.args();
		if (args.length >= 1) {
			argManimFile = args[0];
		}
		if (args.length >= 2) {
			argAutotileName = args[1];
			// Strip # prefix if present - parsed node names don't have it
			if (argAutotileName.startsWith("#")) {
				argAutotileName = argAutotileName.substr(1);
			}
		}
	}

	function createResourceLoader():CachingResourceLoader {
		final loader = new CachingResourceLoader();

		// Build list of directories to search for resources
		final searchPaths = [
			workingDir, // Directory containing the .manim file
			haxe.io.Path.join([workingDir, "res"]), // res subdirectory
			haxe.io.Path.directory(workingDir), // Parent directory
			haxe.io.Path.join([haxe.io.Path.directory(workingDir), "res"]), // Parent's res
			"../test/res", // Common test resource path
			"." // Current directory
		];

		function tryLoadFile(filename:String):Null<haxe.io.Bytes> {
			// Try each search path
			for (searchPath in searchPaths) {
				final fullPath = haxe.io.Path.join([searchPath, filename]);
				try {
					return sys.io.File.getBytes(fullPath);
				} catch (e) {
					// Continue to next path
				}
			}
			// Try as absolute path
			try {
				return sys.io.File.getBytes(filename);
			} catch (e) {
				return null;
			}
		}

		loader.loadTileImpl = filename -> {
			final bytes = tryLoadFile(filename);
			if (bytes == null) {
				throw 'Failed to load tile: $filename (searched in ${searchPaths.join(", ")})';
			}
			final resource = hxd.res.Any.fromBytes(filename, bytes);
			return resource.toTile();
		};

		loader.loadHXDResourceImpl = filename -> {
			final bytes = tryLoadFile(filename);
			if (bytes == null) {
				throw 'Failed to load resource: $filename';
			}
			return hxd.res.Any.fromBytes(filename, bytes);
		};

		loader.loadSheet2Impl = sheetName -> {
			return hxd.Res.load('${sheetName}.atlas2').toAtlas2();
		};

		loader.loadMultiAnimImpl = resourceFilename -> {
			// Try search paths first, then hxd.Res
			final bytes = tryLoadFile(resourceFilename);
			if (bytes != null) {
				final byteData = byte.ByteData.ofBytes(bytes);
				return MultiAnimBuilder.load(byteData, loader, resourceFilename);
			}
			// Fallback to hxd.Res
			final resBytes = hxd.Res.load(resourceFilename).entry.getBytes();
			return MultiAnimBuilder.load(byte.ByteData.ofBytes(resBytes), loader, resourceFilename);
		};

		loader.loadFontImpl = fontName -> {
			return FontManager.getFontByName(fontName);
		};

		return loader;
	}

	function loadAndParseManim() {
		// Read the .manim file
		final bytes = sys.io.File.getBytes(manimFile);
		final byteData = byte.ByteData.ofBytes(bytes);

		// Parse it
		final parsed = MultiAnimParser.parseFile(byteData, manimFile, resourceLoader);

		// Find autotile definitions
		var autotiles:Array<{name:String, def:AutotileDef}> = [];
		for (name => node in parsed.nodes) {
			switch node.type {
				case AUTOTILE(def):
					autotiles.push({name: name, def: def});
				default:
			}
		}

		if (autotiles.length == 0) {
			throw 'No autotile definitions found in $manimFile';
		}

		// Select the autotile
		if (autotileName != null) {
			var found = false;
			for (at in autotiles) {
				if (at.name == autotileName) {
					autotileDef = at.def;
					found = true;
					break;
				}
			}
			if (!found) {
				throw 'Autotile "$autotileName" not found. Available: ${[for (at in autotiles) at.name].join(", ")}';
			}
		} else if (autotiles.length == 1) {
			autotileName = autotiles[0].name;
			autotileDef = autotiles[0].def;
		} else {
			throw 'Multiple autotiles found. Please specify one: ${[for (at in autotiles) at.name].join(", ")}';
		}

		// Validate autotile has region
		if (autotileDef.region == null) {
			throw 'Autotile "$autotileName" does not have a region defined';
		}

		// Validate format
		if (autotileDef.format != Blob47) {
			throw 'Only blob47 format is supported for mapping. Got: ${autotileDef.format}';
		}

		// Extract tile info
		tileSize = resolveInt(autotileDef.tileSize);
		final region = autotileDef.region;
		final rx = resolveInt(region[0]);
		final ry = resolveInt(region[1]);
		final rw = resolveInt(region[2]);
		final rh = resolveInt(region[3]);

		tilesPerRow = Std.int(rw / tileSize);
		tilesPerCol = Std.int(rh / tileSize);
		totalTiles = tilesPerRow * tilesPerCol;

		// Load the tileset image
		var sourceTile:Tile = null;
		switch autotileDef.source {
			case ATSFile(filename):
				final fname = resolveString(filename);
				sourceTile = resourceLoader.loadTile(fname);
			default:
				throw "Only file: source is supported for region mapping";
		}

		// Extract full region as single tile for display
		regionSheetTile = sourceTile.sub(rx, ry, rw, rh);

		// Extract region tiles (individual)
		regionTiles = [];
		for (i in 0...totalTiles) {
			final tx = rx + (i % tilesPerRow) * tileSize;
			final ty = ry + Std.int(i / tilesPerRow) * tileSize;
			regionTiles.push(sourceTile.sub(tx, ty, tileSize, tileSize));
		}

		// Copy existing mapping or create empty
		currentMapping = new Map<Int, Int>();
		autoDetectedTiles = new Map<Int, Bool>();
		var outOfRange = 0;
		if (autotileDef.mapping != null) {
			trace('Loading mappings from file:');
			for (k => v in autotileDef.mapping) {
				trace('  blob47[$k] -> region[$v]');
				if (v >= totalTiles) {
					trace('    ^^^ OUT OF RANGE (max ${totalTiles - 1}), skipping');
					outOfRange++;
				} else {
					currentMapping.set(k, v);
				}
			}
		}

		trace('Loaded autotile "$autotileName": ${totalTiles} tiles in region (${tilesPerRow}x${tilesPerCol}), ${Lambda.count(currentMapping)} mappings loaded');
		if (outOfRange > 0) {
			trace('WARNING: $outOfRange mappings skipped (region tile index out of range 0-${totalTiles - 1})');
		}
	}

	function resolveInt(v:ReferenceableValue):Int {
		return switch v {
			case RVInteger(i): i;
			default: throw 'Expected integer, got $v';
		}
	}

	function resolveString(v:ReferenceableValue):String {
		return switch v {
			case RVString(s): s;
			default: throw 'Expected string, got $v';
		}
	}

	function buildUI() {
		// Build all display sections (content goes into containers positioned by .manim)
		buildRegionDisplay();
		buildBlob47Display();
		buildDemoPreview();
		buildRatioPreview();

		// Export preview area (hidden for now)
		exportText = new Text(hxd.res.DefaultFont.get(), s2d);
		exportText.maxWidth = 600;
		exportText.textColor = 0xCCCCCC;
		exportText.visible = false;
	}


	function buildRegionDisplay() {
		if (regionDisplay != null) regionDisplay.remove();
		final container = if (toolbarScreen != null) toolbarScreen.regionContainer else null;

		final scaledTileSize = tileSize * regionTileScale;

		regionDisplay = new h2d.Object(container != null ? container : s2d);

		// Display full region as single scaled bitmap
		final regionBmp = new Bitmap(regionSheetTile, regionDisplay);
		regionBmp.setScale(regionTileScale);

		// Overlay tile numbers and interactive areas
		for (i in 0...totalTiles) {
			final col = i % tilesPerRow;
			final row = Std.int(i / tilesPerRow);
			final tx = col * scaledTileSize;
			final ty = row * scaledTileSize;

			// Index label with shadow for visibility
			final indexLabel = new Text(hxd.res.DefaultFont.get(), regionDisplay);
			indexLabel.text = '$i';
			indexLabel.textColor = 0xFFFFFF;
			indexLabel.dropShadow = {dx: 1, dy: 1, color: 0, alpha: 1};
			indexLabel.setPosition(tx + 2, ty + 2);

			// Interactive overlay for each tile
			final inter = new Interactive(scaledTileSize, scaledTileSize, regionDisplay);
			inter.enableRightButton = true;
			inter.setPosition(tx, ty);
			final idx = i;
			inter.onOver = _ -> {
				hoveredRegionTile = idx;
				updateStatus();
				updateCrossHighlight();
			};
			inter.onOut = _ -> {
				if (hoveredRegionTile == idx) hoveredRegionTile = -1;
				updateStatus();
				updateCrossHighlight();
			};
			inter.onPush = e -> {
				if (e.button == 0) {
					// Left-click: start drag
					selectedRegionTile = idx;
					selectedBlob47Tile = -1;
					updateStatus();
					updateHighlights();
					updateRatioPreview();
					final absPos = regionDisplay.localToGlobal(new h2d.col.Point(tx + scaledTileSize * 0.5, ty + scaledTileSize * 0.5));
					startDrag(idx, absPos.x, absPos.y);
				} else if (e.button == 1) {
					// Right-click to remove any blob47 mappings using this region tile
					var removed = false;
					for (blob47Idx => regionIdx in currentMapping) {
						if (regionIdx == idx) {
							currentMapping.remove(blob47Idx);
							autoDetectedTiles.remove(blob47Idx);
							removed = true;
						}
					}
					if (removed) {
						rebuildBlob47Display();
						updateExportPreview();
						updateStatus();
					}
				}
			};
		}

		regionHighlight = new Graphics(regionDisplay);
	}

	function buildBlob47Display() {
		if (blob47Display != null) blob47Display.remove();
		final container = if (toolbarScreen != null) toolbarScreen.blob47Container else null;

		blob47Display = new h2d.Object(container != null ? container : s2d);

		final scaledTileSize = tileSize * blob47TileScale;
		final pairGap = 20;
		final separatorWidth = 2;
		final cellWidth = scaledTileSize * 2 + pairGap + PAIR_SPACING;
		final cellHeight = scaledTileSize + 20 + TILE_SPACING;
		blob47CellWidth = cellWidth;
		blob47CellHeight = cellHeight;

		// Row label width
		final labelColWidth = 70;

		// Build cells in grouped layout
		blob47CellPos = [];
		blob47CellPos.resize(47);

		var curY:Float = 0;
		for (group in blob47Layout) {
			// Row label
			final rowLabel = new Text(hxd.res.DefaultFont.get(), blob47Display);
			rowLabel.text = group.label;
			rowLabel.textColor = 0x888888;
			rowLabel.setPosition(0, curY + Std.int(scaledTileSize / 2) - 5);

			// Place tiles in this row
			for (col in 0...group.tiles.length) {
				final i = group.tiles[col];
				final tx = labelColWidth + col * cellWidth;
				final ty = curY;

				blob47CellPos[i] = {x: tx, y: ty};

				buildBlob47Cell(i, tx, ty, scaledTileSize, cellWidth, pairGap, separatorWidth);
			}

			curY += cellHeight;
		}

		blob47Highlight = new Graphics(blob47Display);
	}

	function buildBlob47Cell(i:Int, tx:Float, ty:Float, scaledTileSize:Int, cellWidth:Float, pairGap:Int, separatorWidth:Int) {
		// Background
		final bg = new Graphics(blob47Display);
		bg.setPosition(tx, ty);
		drawTileBackground(bg, i, cellWidth - PAIR_SPACING, scaledTileSize);

		// Demo tile (left)
		final demoTile = generateDemoTile(i);
		final demoBmp = new Bitmap(demoTile, blob47Display);
		demoBmp.setScale(blob47TileScale);
		demoBmp.setPosition(tx, ty);

		final demoBorder = new Graphics(blob47Display);
		demoBorder.setPosition(tx, ty);
		demoBorder.lineStyle(1, 0x666688);
		demoBorder.drawRect(0, 0, scaledTileSize, scaledTileSize);

		// Separator
		final sepX = tx + scaledTileSize + Std.int((pairGap - separatorWidth) / 2);
		final separator = new Graphics(blob47Display);
		separator.setPosition(sepX, ty);
		separator.beginFill(0x666666);
		separator.drawRect(0, 2, separatorWidth, scaledTileSize - 4);
		separator.endFill();

		// Arrow
		final arrow = new Text(hxd.res.DefaultFont.get(), blob47Display);
		arrow.text = ">";
		arrow.textColor = 0x888888;
		arrow.setPosition(tx + scaledTileSize + 4, ty + Std.int(scaledTileSize / 2) - 3);

		// Right side: mapped tile, fallback, or empty
		final mappedX = tx + scaledTileSize + pairGap;
		if (currentMapping.exists(i)) {
			final mappedIdx = currentMapping.get(i);
			if (mappedIdx >= 0 && mappedIdx < regionTiles.length) {
				final mappedBmp = new Bitmap(regionTiles[mappedIdx], blob47Display);
				mappedBmp.setScale(blob47TileScale);
				mappedBmp.setPosition(mappedX, ty);
				final mappedBorder = new Graphics(blob47Display);
				mappedBorder.setPosition(mappedX, ty);
				mappedBorder.lineStyle(1, 0x88AA88);
				mappedBorder.drawRect(0, 0, scaledTileSize, scaledTileSize);
			} else {
				final errGfx = new Graphics(blob47Display);
				errGfx.setPosition(mappedX, ty);
				errGfx.beginFill(0x660000);
				errGfx.drawRect(0, 0, scaledTileSize, scaledTileSize);
				errGfx.endFill();
				final errText = new Text(hxd.res.DefaultFont.get(), blob47Display);
				errText.text = "OOB";
				errText.textColor = 0xFF4444;
				errText.setPosition(mappedX + 2, ty + Std.int(scaledTileSize / 2) - 6);
			}
		} else {
			final fallbackIdx = Autotile.applyBlob47FallbackWithMap(i, currentMapping);
			if (fallbackIdx != i && currentMapping.exists(fallbackIdx)) {
				final fallbackRegionIdx = currentMapping.get(fallbackIdx);
				if (fallbackRegionIdx >= 0 && fallbackRegionIdx < regionTiles.length) {
					final fallbackBmp = new Bitmap(regionTiles[fallbackRegionIdx], blob47Display);
					fallbackBmp.setScale(blob47TileScale);
					fallbackBmp.setPosition(mappedX, ty);
					fallbackBmp.alpha = 0.5;
					final fbBorder = new Graphics(blob47Display);
					fbBorder.setPosition(mappedX, ty);
					fbBorder.lineStyle(1, 0x888844);
					fbBorder.drawRect(0, 0, scaledTileSize, scaledTileSize);
					final fbLabel = new Text(hxd.res.DefaultFont.get(), blob47Display);
					fbLabel.text = '~$fallbackIdx';
					fbLabel.textColor = 0xAAAA66;
					fbLabel.dropShadow = {dx: 1, dy: 1, color: 0, alpha: 1};
					fbLabel.setPosition(mappedX + 2, ty + Std.int(scaledTileSize / 2) - 6);
				} else {
					final emptyGfx = new Graphics(blob47Display);
					emptyGfx.setPosition(mappedX, ty);
					emptyGfx.lineStyle(1, 0x884444);
					emptyGfx.drawRect(0, 0, scaledTileSize, scaledTileSize);
					final qMark = new Text(hxd.res.DefaultFont.get(), blob47Display);
					qMark.text = "?";
					qMark.textColor = 0xCC4444;
					qMark.setPosition(mappedX + Std.int(scaledTileSize / 2) - 3, ty + Std.int(scaledTileSize / 2) - 6);
				}
			} else {
				final emptyGfx = new Graphics(blob47Display);
				emptyGfx.setPosition(mappedX, ty);
				emptyGfx.lineStyle(1, 0x884444);
				emptyGfx.drawRect(0, 0, scaledTileSize, scaledTileSize);
				emptyGfx.lineStyle(2, 0xCC4444);
				emptyGfx.moveTo(4, 4);
				emptyGfx.lineTo(scaledTileSize - 4, scaledTileSize - 4);
				emptyGfx.moveTo(scaledTileSize - 4, 4);
				emptyGfx.lineTo(4, scaledTileSize - 4);
				final qMark = new Text(hxd.res.DefaultFont.get(), blob47Display);
				qMark.text = "?";
				qMark.textColor = 0xCC4444;
				qMark.setPosition(mappedX + Std.int(scaledTileSize / 2) - 3, ty + Std.int(scaledTileSize / 2) - 6);
			}
		}

		// Index label
		final indexLabel = new Text(hxd.res.DefaultFont.get(), blob47Display);
		if (currentMapping.exists(i)) {
			indexLabel.text = '$i > ${currentMapping.get(i)}';
			indexLabel.textColor = 0x88FF88;
		} else {
			final fallbackIdx = Autotile.applyBlob47FallbackWithMap(i, currentMapping);
			if (fallbackIdx != i && currentMapping.exists(fallbackIdx)) {
				indexLabel.text = '$i ~> $fallbackIdx';
				indexLabel.textColor = 0xFFAA44;
			} else {
				indexLabel.text = '$i (empty)';
				indexLabel.textColor = 0xCC4444;
			}
		}
		indexLabel.dropShadow = {dx: 1, dy: 1, color: 0, alpha: 1};
		indexLabel.setPosition(tx, ty + scaledTileSize + 2);

		// Interactive overlay
		final inter = new Interactive(cellWidth - PAIR_SPACING, scaledTileSize, blob47Display);
		inter.enableRightButton = true;
		inter.setPosition(tx, ty);
		final idx = i;
		inter.onOver = _ -> {
			hoveredBlob47Tile = idx;
			updateStatus();
			updateCrossHighlight();
		};
		inter.onOut = _ -> {
			if (hoveredBlob47Tile == idx) hoveredBlob47Tile = -1;
			updateStatus();
			updateCrossHighlight();
		};
		inter.onClick = _ -> {
			if (selectedRegionTile >= 0) {
				currentMapping.set(idx, selectedRegionTile);
				selectedBlob47Tile = idx;
				updateStatus();
				rebuildBlob47Display();
				updateExportPreview();
			} else {
				selectedBlob47Tile = idx;
				if (currentMapping.exists(idx)) {
					selectedRegionTile = currentMapping.get(idx);
				}
				updateStatus();
				updateHighlights();
			}
		};
		inter.onPush = e -> {
			if (e.button == 1) {
				if (currentMapping.exists(idx)) {
					currentMapping.remove(idx);
					autoDetectedTiles.remove(idx);
					rebuildBlob47Display();
					updateExportPreview();
					updateStatus();
				}
			}
		};
	}

	function rebuildBlob47Display() {
		buildBlob47Display();
		buildDemoPreview();
	}

	public function setRegionZoom(scale:Int) {
		regionTileScale = Std.int(Math.max(1, scale));
		buildRegionDisplay();
		buildDemoPreview();
		buildRatioPreview();
	}

	public function setBlob47Zoom(scale:Int) {
		blob47TileScale = Std.int(Math.max(1, scale));
		buildBlob47Display();
	}

	public function setDemoZoom(scale:Int) {
		demoPreviewScale = Std.int(Math.max(1, scale));
		buildDemoPreview();
		buildRatioPreview();
	}

	function handleMouseWheel(mouseX:Float, mouseY:Float, delta:Float) {
		final step = if (delta > 0) -1 else 1;

		// Check which container the mouse is over using container absolute positions
		if (toolbarScreen == null) return;

		function isOverContainer(container:h2d.Object):Bool {
			if (container == null) return false;
			final localPt = container.globalToLocal(new h2d.col.Point(mouseX, mouseY));
			return localPt.x >= 0 && localPt.y >= 0;
		}

		if (isOverContainer(toolbarScreen.blob47Container)) {
			final newScale = Std.int(Math.max(1, Math.min(16, blob47TileScale + step)));
			if (newScale != blob47TileScale) {
				setBlob47Zoom(newScale);
				syncSliders();
			}
		} else if (isOverContainer(toolbarScreen.demoContainer)) {
			final newScale = Std.int(Math.max(1, Math.min(16, demoPreviewScale + step)));
			if (newScale != demoPreviewScale) {
				setDemoZoom(newScale);
				syncSliders();
			}
		} else if (isOverContainer(toolbarScreen.regionContainer)) {
			final newScale = Std.int(Math.max(1, Math.min(16, regionTileScale + step)));
			if (newScale != regionTileScale) {
				setRegionZoom(newScale);
				syncSliders();
			}
		}
	}

	function syncSliders() {
		if (toolbarScreen == null) return;
		if (toolbarScreen.regionZoomSlider != null)
			toolbarScreen.regionZoomSlider.setIntValue(AutotileToolbarScreen.scaleToSlider(regionTileScale));
		if (toolbarScreen.blob47ZoomSlider != null)
			toolbarScreen.blob47ZoomSlider.setIntValue(AutotileToolbarScreen.scaleToSlider(blob47TileScale));
		if (toolbarScreen.demoZoomSlider != null)
			toolbarScreen.demoZoomSlider.setIntValue(AutotileToolbarScreen.scaleToSlider(demoPreviewScale));
	}

	function buildDemoPreview() {
		if (demoPreview != null) demoPreview.remove();
		final container = if (toolbarScreen != null) toolbarScreen.demoContainer else null;

		demoPreview = new h2d.Object(container != null ? container : s2d);

		updateDemoPreview();
	}

	function updateDemoPreview() {
		if (demoPreview == null) return;

		// Remove all old children
		while (demoPreview.numChildren > 0) {
			demoPreview.getChildAt(0).remove();
		}
		demoHighlight = null;

		// LARGE_SEA_GRID - Comprehensive blob47 test grid (16x12)
		// Designed to produce all 47 unique tiles.
		// 1 = terrain, 0 = empty
		final previewTileSize = tileSize * demoPreviewScale;

		final terrainMap:Array<Array<Int>> = [
			[1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0],
			[0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0],
			[1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1],
			[1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1],
			[0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1],
			[0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1],
			[1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0],
			[1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0],
			[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1],
			[0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
			[1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1],
			[1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1]
		];

		final mapHeight = terrainMap.length;
		final mapWidth = terrainMap[0].length;

		demoCellBlob47 = [];
		for (row in 0...mapHeight) {
			for (col in 0...mapWidth) {
				if (terrainMap[row][col] == 0) continue; // Skip empty cells

				// Calculate blob47 index from neighbors
				final blob47Idx = calculateBlob47Index(terrainMap, col, row, mapWidth, mapHeight);

				final tx = col * previewTileSize;
				final ty = row * previewTileSize;

				demoCellBlob47.push({x: tx, y: ty, blob47Idx: blob47Idx});

				// Get the tile to display - mapped tile, fallback, or demo tile
				var tileToDraw:Tile;
				if (currentMapping.exists(blob47Idx)) {
					final mappedIdx = currentMapping.get(blob47Idx);
					if (mappedIdx >= 0 && mappedIdx < regionTiles.length) {
						tileToDraw = regionTiles[mappedIdx];
					} else {
						tileToDraw = generateDemoTile(blob47Idx);
					}
				} else {
					// Try fallback
					final fallbackIdx = Autotile.applyBlob47FallbackWithMap(blob47Idx, currentMapping);
					if (fallbackIdx != blob47Idx && currentMapping.exists(fallbackIdx)) {
						final mappedIdx = currentMapping.get(fallbackIdx);
						if (mappedIdx >= 0 && mappedIdx < regionTiles.length) {
							tileToDraw = regionTiles[mappedIdx];
						} else {
							tileToDraw = generateDemoTile(blob47Idx);
						}
					} else {
						tileToDraw = generateDemoTile(blob47Idx);
					}
				}

				final bmp = new Bitmap(tileToDraw, demoPreview);
				bmp.setScale(demoPreviewScale);
				bmp.setPosition(tx, ty);
			}
		}

		// Create highlight overlay on top
		demoHighlight = new Graphics(demoPreview);

		// Add interactives for hover on demo map cells
		for (cell in demoCellBlob47) {
			final inter = new Interactive(previewTileSize, previewTileSize, demoPreview);
			inter.setPosition(cell.x, cell.y);
			final b47 = cell.blob47Idx;
			inter.onOver = _ -> {
				hoveredDemoBlob47 = b47;
				updateStatus();
				updateCrossHighlight();
			};
			inter.onOut = _ -> {
				if (hoveredDemoBlob47 == b47) hoveredDemoBlob47 = -1;
				updateStatus();
				updateCrossHighlight();
			};
		}

		updateCrossHighlight();
	}

	// Highlight color constants
	static inline var COLOR_WHITE = 0xFFFFFF; // Expected tile (the one that should be used)
	static inline var COLOR_BLUE = 0x4488FF; // Actually selected (fallback result)
	static inline var COLOR_ORANGE = 0xFF8800; // Skipped in fallback chain (missing)
	static inline var COLOR_YELLOW = 0xFFFF00; // Default highlight (direct match, non-demo hover)

	function updateCrossHighlight() {
		// Color-coded blob47 highlights: tile -> color
		var blob47Colors = new Map<Int, Int>();
		var regionColors = new Map<Int, Int>();
		// Fallback chain for demo hover
		var activeFallbackChain:Null<{result:Int, skipped:Array<Int>}> = null;
		var activeBlob47:Int = -1;

		if (hoveredDemoBlob47 >= 0 || hoveredBlob47Tile >= 0) {
			activeBlob47 = if (hoveredDemoBlob47 >= 0) hoveredDemoBlob47 else hoveredBlob47Tile;
			if (currentMapping.exists(activeBlob47)) {
				// Directly mapped - white
				blob47Colors.set(activeBlob47, COLOR_WHITE);
				regionColors.set(currentMapping.get(activeBlob47), COLOR_WHITE);
			} else {
				// Get fallback chain
				final chain = Autotile.getBlob47FallbackChain(activeBlob47, currentMapping);
				activeFallbackChain = chain;
				// White = expected tile
				blob47Colors.set(activeBlob47, COLOR_WHITE);
				// Orange = skipped (missing) tiles in chain
				for (skipped in chain.skipped) {
					blob47Colors.set(skipped, COLOR_ORANGE);
				}
				// Blue = actually selected fallback
				if (chain.result != activeBlob47 && currentMapping.exists(chain.result)) {
					blob47Colors.set(chain.result, COLOR_BLUE);
					regionColors.set(currentMapping.get(chain.result), COLOR_BLUE);
				}
			}
		} else if (hoveredRegionTile >= 0) {
			regionColors.set(hoveredRegionTile, COLOR_YELLOW);
			for (b47 => regionIdx in currentMapping) {
				if (regionIdx == hoveredRegionTile) blob47Colors.set(b47, COLOR_YELLOW);
			}
		} else if (selectedBlob47Tile >= 0) {
			blob47Colors.set(selectedBlob47Tile, COLOR_YELLOW);
			if (currentMapping.exists(selectedBlob47Tile))
				regionColors.set(currentMapping.get(selectedBlob47Tile), COLOR_YELLOW);
		}

		// Demo map highlight
		if (demoHighlight != null) {
			demoHighlight.clear();
			if (activeBlob47 >= 0) {
				final previewTileSize = tileSize * demoPreviewScale;
				for (cell in demoCellBlob47) {
					if (cell.blob47Idx == activeBlob47) {
						// This is the hovered tile's type - white outline
						demoHighlight.lineStyle(2, COLOR_WHITE);
						demoHighlight.drawRect(cell.x, cell.y, previewTileSize, previewTileSize);
					} else if (activeFallbackChain != null) {
						// Check if this cell uses the fallback result
						if (!currentMapping.exists(cell.blob47Idx)) {
							final cellChain = Autotile.getBlob47FallbackChain(cell.blob47Idx, currentMapping);
							if (cellChain.result == activeFallbackChain.result && currentMapping.exists(cellChain.result)) {
								demoHighlight.lineStyle(1, COLOR_BLUE);
								demoHighlight.drawRect(cell.x, cell.y, previewTileSize, previewTileSize);
							}
						}
					}
				}
			} else if (Lambda.count(blob47Colors) > 0) {
				final previewTileSize = tileSize * demoPreviewScale;
				for (cell in demoCellBlob47) {
					if (blob47Colors.exists(cell.blob47Idx)) {
						demoHighlight.lineStyle(2, blob47Colors.get(cell.blob47Idx));
						demoHighlight.drawRect(cell.x, cell.y, previewTileSize, previewTileSize);
					}
				}
			}
		}

		// Region highlight
		if (regionHighlight != null) {
			regionHighlight.clear();
			if (Lambda.count(regionColors) > 0) {
				final scaledTileSize = tileSize * regionTileScale;
				for (regionIdx => color in regionColors) {
					regionHighlight.lineStyle(2, color);
					final col = regionIdx % tilesPerRow;
					final row = Std.int(regionIdx / tilesPerRow);
					regionHighlight.drawRect(col * scaledTileSize, row * scaledTileSize, scaledTileSize, scaledTileSize);
				}
			}
		}

		// Blob47 highlight
		if (blob47Highlight != null) {
			blob47Highlight.clear();
			if (Lambda.count(blob47Colors) > 0) {
				final scaledTileSize = tileSize * blob47TileScale;
				for (b47 => color in blob47Colors) {
					if (b47 < 0 || b47 >= blob47CellPos.length || blob47CellPos[b47] == null) continue;
					blob47Highlight.lineStyle(2, color);
					final pos = blob47CellPos[b47];
					blob47Highlight.drawRect(pos.x, pos.y, blob47CellWidth - PAIR_SPACING, scaledTileSize);
				}
			}
		}
	}

	// Calculate blob47 index from neighbor configuration
	function calculateBlob47Index(map:Array<Array<Int>>, x:Int, y:Int, w:Int, h:Int):Int {
		// Use Autotile.getNeighborMask8 to build the mask, then getBlob47Index
		final mask = Autotile.getNeighborMask8(map, x, y);
		return Autotile.getBlob47Index(mask);
	}

	function drawTileBackground(g:Graphics, blob47Idx:Int, width:Float, height:Float) {
		// Alternating background tint for every other pair
		final isOddPair = (blob47Idx % 2) == 1;
		final tintOffset = if (isOddPair) 0x0C else 0;

		if (currentMapping.exists(blob47Idx)) {
			if (autoDetectedTiles.exists(blob47Idx)) {
				g.beginFill(0x442244 + tintOffset * 0x010101); // Purple/pink background for auto-detected
			} else {
				g.beginFill(0x225522 + tintOffset * 0x010101); // Green for manual
			}
		} else {
			g.beginFill(if (isOddPair) 0x505050 else 0x3A3A3A);
		}
		g.drawRect(0, 0, width, height + 16); // +16 for label space
		g.endFill();

		// Pink border for auto-detected
		if (autoDetectedTiles.exists(blob47Idx)) {
			g.lineStyle(2, 0xFF66AA);
			g.drawRect(0, 0, width, height);
			g.lineStyle();
		}
	}

	function generateDemoTile(blob47Idx:Int):Tile {
		// Generate a simple demo tile showing the edge pattern
		final pixels = hxd.Pixels.alloc(tileSize, tileSize, hxd.PixelFormat.BGRA);
		final edges = getBlob47Edges(blob47Idx);

		final edgeColor = 0xFF44AA44; // Green edges (ARGB)
		final fillColor = 0xFF886644; // Brown fill (ARGB)

		for (y in 0...tileSize) {
			for (x in 0...tileSize) {
				var color = fillColor;

				// Check if this pixel is on an edge
				final isTop = y == 0;
				final isBottom = y == tileSize - 1;
				final isLeft = x == 0;
				final isRight = x == tileSize - 1;

				// Edge pixels - show edge color where there's NO neighbor
				if (isTop && !edges.n)
					color = edgeColor;
				if (isBottom && !edges.s)
					color = edgeColor;
				if (isLeft && !edges.w)
					color = edgeColor;
				if (isRight && !edges.e)
					color = edgeColor;

				// Corner pixels for inner corners (neighbor present but diagonal missing)
				if (isTop && isRight && edges.n && edges.e && !edges.innerNE)
					color = edgeColor;
				if (isTop && isLeft && edges.n && edges.w && !edges.innerNW)
					color = edgeColor;
				if (isBottom && isRight && edges.s && edges.e && !edges.innerSE)
					color = edgeColor;
				if (isBottom && isLeft && edges.s && edges.w && !edges.innerSW)
					color = edgeColor;

				pixels.setPixel(x, y, color);
			}
		}

		return Tile.fromPixels(pixels);
	}

	function getBlob47Edges(tileIndex:Int):{n:Bool, s:Bool, e:Bool, w:Bool, innerNE:Bool, innerNW:Bool, innerSE:Bool, innerSW:Bool} {
		// Get the neighbor mask for this blob47 tile
		final mask = getBlob47Mask(tileIndex);

		return {
			n: (mask & Autotile.N) != 0,
			e: (mask & Autotile.E) != 0,
			s: (mask & Autotile.S) != 0,
			w: (mask & Autotile.W) != 0,
			innerNE: (mask & Autotile.NE) != 0,
			innerNW: (mask & Autotile.NW) != 0,
			innerSE: (mask & Autotile.SE) != 0,
			innerSW: (mask & Autotile.SW) != 0
		};
	}

	function getBlob47Mask(tileIndex:Int):Int {
		// Reverse lookup: blob47 tile index -> 8-bit mask
		// This is the inverse of calculateBlob47Tile in Autotile.hx
		return switch tileIndex {
			case 0: 0; // isolated
			case 1: 1; // N only
			case 2: 4; // E only
			case 3: 5; // N+E
			case 4: 7; // N+NE+E
			case 5: 16; // S only
			case 6: 17; // N+S
			case 7: 20; // E+S
			case 8: 21; // N+E+S
			case 9: 23; // N+NE+E+S
			case 10: 28; // E+SE+S
			case 11: 29; // N+E+SE+S
			case 12: 31; // N+NE+E+SE+S
			case 13: 64; // W only
			case 14: 65; // N+W
			case 15: 68; // E+W
			case 16: 69; // N+E+W
			case 17: 71; // N+NE+E+W
			case 18: 80; // S+W
			case 19: 81; // N+S+W
			case 20: 84; // E+S+W
			case 21: 85; // N+E+S+W (center)
			case 22: 87; // N+NE+E+S+W
			case 23: 92; // E+SE+S+W
			case 24: 93; // N+E+SE+S+W
			case 25: 95; // N+NE+E+SE+S+W
			case 26: 112; // S+SW+W
			case 27: 113; // N+S+SW+W
			case 28: 116; // E+S+SW+W
			case 29: 117; // N+E+S+SW+W
			case 30: 119; // N+NE+E+S+SW+W
			case 31: 124; // E+SE+S+SW+W
			case 32: 125; // N+E+SE+S+SW+W
			case 33: 127; // N+NE+E+SE+S+SW+W
			case 34: 193; // N+W+NW
			case 35: 197; // N+E+W+NW
			case 36: 199; // N+NE+E+W+NW
			case 37: 209; // N+S+W+NW
			case 38: 213; // N+E+S+W+NW
			case 39: 215; // N+NE+E+S+W+NW
			case 40: 221; // N+E+SE+S+W+NW
			case 41: 223; // N+NE+E+SE+S+W+NW
			case 42: 241; // N+S+SW+W+NW
			case 43: 245; // N+E+S+SW+W+NW
			case 44: 247; // N+NE+E+S+SW+W+NW
			case 45: 253; // N+E+SE+S+SW+W+NW
			case 46: 255; // all neighbors
			default: 0;
		};
	}

	function setStatus(text:String, ?color:Int) {
		if (toolbarScreen != null) {
			toolbarScreen.updateNamedText("statusLabel", text);
		}
	}

	function updateStatus() {
		var status = "";
		if (selectedRegionTile >= 0) {
			status += 'Selected region tile: $selectedRegionTile  ';
		}
		if (hoveredDemoBlob47 >= 0) {
			status += 'Demo tile: blob47[$hoveredDemoBlob47] (${describeBlob47(hoveredDemoBlob47)})';
			if (currentMapping.exists(hoveredDemoBlob47)) {
				status += ' -> region[${currentMapping.get(hoveredDemoBlob47)}]';
			} else {
				status += ' (unmapped)';
			}
		} else if (hoveredBlob47Tile >= 0) {
			status += 'Hover blob47: $hoveredBlob47Tile';
			if (currentMapping.exists(hoveredBlob47Tile)) {
				status += ' -> ${currentMapping.get(hoveredBlob47Tile)}';
			}
		}
		if (hoveredRegionTile >= 0) {
			status += 'Hover region: $hoveredRegionTile';
		}
		setStatus(status);
	}

	function updateHighlights() {
		// Could add visual highlights for selected tiles
	}

	function startDrag(regionIdx:Int, startX:Float, startY:Float) {
		cancelDrag();
		dragRegionTileIdx = regionIdx;

		// Create floating tile bitmap that follows cursor
		dragBitmap = new Bitmap(regionTiles[regionIdx], s2d);
		dragBitmap.setScale(regionTileScale);
		dragBitmap.alpha = 0.7;
		dragBitmap.setPosition(startX - tileSize * regionTileScale * 0.5, startY - tileSize * regionTileScale * 0.5);

		// Highlight overlay to show valid drop targets
		dragOverlay = new Graphics(s2d);
		updateDragHighlight();
	}

	function updateDrag(mouseX:Float, mouseY:Float) {
		if (dragBitmap == null) return;
		dragBitmap.setPosition(mouseX - tileSize * regionTileScale * 0.5, mouseY - tileSize * regionTileScale * 0.5);
		updateDragHighlight(getBlob47IndexAtScreenPos(mouseX, mouseY));
	}

	function endDrag(mouseX:Float, mouseY:Float) {
		if (dragRegionTileIdx < 0) return;

		// Check if mouse is over a blob47 tile slot
		final blob47Idx = getBlob47IndexAtScreenPos(mouseX, mouseY);
		if (blob47Idx >= 0) {
			currentMapping.set(blob47Idx, dragRegionTileIdx);
			autoDetectedTiles.remove(blob47Idx);
			selectedRegionTile = dragRegionTileIdx;
			selectedBlob47Tile = blob47Idx;
			rebuildBlob47Display();
			updateExportPreview();
			updateStatus();
		}

		cancelDrag();
	}

	function cancelDrag() {
		dragRegionTileIdx = -1;
		if (dragBitmap != null) {
			dragBitmap.remove();
			dragBitmap = null;
		}
		if (dragOverlay != null) {
			dragOverlay.remove();
			dragOverlay = null;
		}
	}

	function updateDragHighlight(hoveredIdx:Int = -1) {
		if (dragOverlay == null || blob47Display == null) return;
		dragOverlay.clear();

		final scaledTileSize = tileSize * blob47TileScale;

		for (i in 0...47) {
			if (i >= blob47CellPos.length || blob47CellPos[i] == null) continue;
			final pos = blob47CellPos[i];
			final absPos = blob47Display.localToGlobal(new h2d.col.Point(pos.x, pos.y));

			if (i == hoveredIdx) {
				dragOverlay.beginFill(0x44FF44, 0.2);
				dragOverlay.lineStyle(3, 0x44FF44, 1.0);
				dragOverlay.drawRect(absPos.x, absPos.y, blob47CellWidth - PAIR_SPACING, scaledTileSize);
				dragOverlay.endFill();
			} else if (!currentMapping.exists(i)) {
				dragOverlay.lineStyle(1, 0x44FF44, 0.3);
				dragOverlay.drawRect(absPos.x, absPos.y, blob47CellWidth - PAIR_SPACING, scaledTileSize);
			}
		}
	}

	function getBlob47IndexAtScreenPos(screenX:Float, screenY:Float):Int {
		if (blob47Display == null) return -1;

		final scaledTileSize = tileSize * blob47TileScale;
		final localPt = blob47Display.globalToLocal(new h2d.col.Point(screenX, screenY));
		final lx = localPt.x;
		final ly = localPt.y;

		// Search through cell positions to find which tile the cursor is over
		for (i in 0...47) {
			if (i >= blob47CellPos.length || blob47CellPos[i] == null) continue;
			final pos = blob47CellPos[i];
			if (lx >= pos.x && lx < pos.x + blob47CellWidth - PAIR_SPACING && ly >= pos.y && ly < pos.y + scaledTileSize) {
				return i;
			}
		}
		return -1;
	}

	function updateExportPreview() {
		var preview = "Mapping preview:\n";
		preview += "mapping: [\n";

		// Sort keys for nice output
		final keys = [for (k in currentMapping.keys()) k];
		keys.sort((a, b) -> a - b);

		for (k in keys) {
			preview += '    $k:${currentMapping.get(k)},\n';
		}
		preview += "]\n";
		preview += '\n${keys.length} tiles mapped, ${47 - keys.length} unmapped';

		exportText.text = preview;
	}

	public function autodetect() {
		trace("Running autodetection with edge/center spatial color analysis...");
		setStatus("Autodetecting...");

		// Analyze each region tile using 3x3 subtile grid
		final subtileProfiles:Array<SubtileProfile> = [];
		for (i in 0...regionTiles.length) {
			subtileProfiles.push(analyzeSubtiles(regionTiles[i]));
		}

		// Use edge/center ratio to spatially split colors into edge-zone and center-zone sets
		// Edge zones: subtile indices 0(NW), 1(N), 2(NE), 3(W), 5(E), 6(SW), 7(S), 8(SE) - the 8 border zones
		// Center zone: subtile index 4(C) - the center zone
		final edgeIndices = [0, 1, 2, 3, 5, 6, 7, 8];
		final centerIndex = 4;

		var edgeZoneColors:Array<LabColor> = [];
		var centerZoneColors:Array<LabColor> = [];

		// Determine which tiles to use for training: manual mappings first, all tiles as fallback
		var trainingProfiles:Array<SubtileProfile> = [];

		for (blob47Idx => regionIdx in currentMapping) {
			if (autoDetectedTiles.exists(blob47Idx)) continue; // Skip auto-detected
			if (regionIdx >= 0 && regionIdx < subtileProfiles.length) {
				trainingProfiles.push(subtileProfiles[regionIdx]);
			}
		}

		trace('Training profiles from manual mappings: ${trainingProfiles.length}');

		final totalPixels = tileSize * tileSize;
		if (trainingProfiles.length < 2) {
			trace("Not enough manual mappings, using all non-empty region tiles");
			for (profile in subtileProfiles) {
				if (profile.opaquePixelCount >= totalPixels / 2) trainingProfiles.push(profile);
			}
		}

		// Collect edge and center colors separately based on spatial position
		for (profile in trainingProfiles) {
			// Skip empty/mostly-transparent tiles
			if (profile.opaquePixelCount < totalPixels / 2) continue;

			for (ei in edgeIndices) {
				final c = profile.subtiles[ei];
				if (c.l > 5) edgeZoneColors.push(c);
			}
			final cc = profile.subtiles[centerIndex];
			if (cc.l > 5) centerZoneColors.push(cc);
		}

		trace('Spatial split - Edge zone colors: ${edgeZoneColors.length}, Center zone colors: ${centerZoneColors.length}');

		if (edgeZoneColors.length < 2 || centerZoneColors.length < 2) {
			setStatus("Not enough color data - need more non-empty tiles");
			return;
		}

		// Compute initial centroids from spatial zones
		var edgeColor = averageLabColor(edgeZoneColors);
		var fillColor = averageLabColor(centerZoneColors);

		// Remove outliers: discard colors that are > 2 standard deviations from their centroid
		edgeZoneColors = removeLabOutliers(edgeZoneColors, edgeColor, 2.0);
		centerZoneColors = removeLabOutliers(centerZoneColors, fillColor, 2.0);

		// Recompute centroids after outlier removal
		edgeColor = averageLabColor(edgeZoneColors);
		fillColor = averageLabColor(centerZoneColors);

		trace('After outlier removal - Edge colors: ${edgeZoneColors.length}, Center colors: ${centerZoneColors.length}');

		// Check if clusters are too similar
		final clusterDist = labDistance(edgeColor, fillColor);
		trace('Spatial clusters - Edge: L=${Std.int(edgeColor.l)} a=${Std.int(edgeColor.a)} b=${Std.int(edgeColor.b)}, Fill: L=${Std.int(fillColor.l)} a=${Std.int(fillColor.a)} b=${Std.int(fillColor.b)}, Distance: $clusterDist');

		if (clusterDist < 10) {
			trace("Warning: Edge and fill colors too similar, autodetect may not work well. Try adjusting edge/center ratio or setting more manual mappings.");
			setStatus("Edge/fill colors too similar - adjust ratio or set more manual mappings");
			return;
		}

		// Build set of already used region tiles (from non-auto mappings)
		var usedRegionTiles = new Map<Int, Bool>();
		for (blob47Idx => regionIdx in currentMapping) {
			if (!autoDetectedTiles.exists(blob47Idx)) {
				usedRegionTiles.set(regionIdx, true);
			}
		}

		// Clear previous auto-detections before re-running
		for (blob47Idx in autoDetectedTiles.keys()) {
			currentMapping.remove(blob47Idx);
		}
		autoDetectedTiles.clear();

		// Build a map of blob47 patterns to indices for quick lookup
		// Pattern is encoded as: N*1 + S*2 + E*4 + W*8 + NE*16 + NW*32 + SE*64 + SW*128
		var patternToBlob47:Map<Int, Array<Int>> = new Map();
		for (i in 0...47) {
			final edges = getBlob47Edges(i);
			var pattern = 0;
			if (edges.n) pattern |= 1;
			if (edges.s) pattern |= 2;
			if (edges.e) pattern |= 4;
			if (edges.w) pattern |= 8;
			if (edges.innerNE) pattern |= 16;
			if (edges.innerNW) pattern |= 32;
			if (edges.innerSE) pattern |= 64;
			if (edges.innerSW) pattern |= 128;

			if (!patternToBlob47.exists(pattern)) {
				patternToBlob47.set(pattern, []);
			}
			patternToBlob47.get(pattern).push(i);
		}

		var autoCount = 0;
		var emptyTileCount = 0;

		// Score each region tile against each blob47 pattern.
		// For each blob47 tile, determine expected fill/edge for each of the 9 subtile zones
		// and 4 corner zones, then score how well each region tile matches.

		// Build expected classification for each blob47 tile
		// For each subtile zone and corner, whether it should be fill (1) or edge (0)
		var blob47Expected:Array<{subtiles:Array<Int>, corners:Array<Int>}> = [];
		for (i in 0...47) {
			final edges = getBlob47Edges(i);
			// Subtile indices: 0=NW, 1=N, 2=NE, 3=W, 4=C, 5=E, 6=SW, 7=S, 8=SE
			// Center is always fill
			// Cardinal edges: fill if neighbor present, edge if not
			// Corners: fill if both adjacent cardinals AND diagonal present
			final n = edges.n;
			final s = edges.s;
			final e = edges.e;
			final w = edges.w;
			// Corner subtile is fill only when both adjacent cardinals are present AND diagonal is present
			final nwFill = n && w && edges.innerNW;
			final neFill = n && e && edges.innerNE;
			final swFill = s && w && edges.innerSW;
			final seFill = s && e && edges.innerSE;

			blob47Expected.push({
				subtiles: [
					nwFill ? 1 : 0, // 0: NW
					n ? 1 : 0, // 1: N
					neFill ? 1 : 0, // 2: NE
					w ? 1 : 0, // 3: W
					1, // 4: Center - always fill
					e ? 1 : 0, // 5: E
					swFill ? 1 : 0, // 6: SW
					s ? 1 : 0, // 7: S
					seFill ? 1 : 0 // 8: SE
				],
				corners: [
					// Inner corners: 1 if there's a notch (edge color in corner when both cardinals present)
					// 0 if no notch (either filled or cardinals not both present)
					(n && w && !edges.innerNW) ? 1 : 0, // NW corner notch
					(n && e && !edges.innerNE) ? 1 : 0, // NE corner notch
					(s && w && !edges.innerSW) ? 1 : 0, // SW corner notch
					(s && e && !edges.innerSE) ? 1 : 0 // SE corner notch
				]
			});
		}

		// For each region tile, compute match scores against all blob47 patterns
		// Collect all (regionIdx, blob47Idx, score) triples, then greedily assign best matches
		var candidates:Array<{regionIdx:Int, blob47Idx:Int, score:Float}> = [];

		final totalPixelsPerTile = tileSize * tileSize;
		for (regionIdx in 0...subtileProfiles.length) {
			if (usedRegionTiles.exists(regionIdx)) continue;

			final profile = subtileProfiles[regionIdx];

			// Skip empty/transparent tiles (less than 50% opaque pixels)
			if (profile.opaquePixelCount < totalPixelsPerTile / 2) {
				emptyTileCount++;
				continue;
			}

			// Classify each subtile using soft scoring (distance ratio)
			for (blob47Idx in 0...47) {
				if (currentMapping.exists(blob47Idx)) continue;

				final expected = blob47Expected[blob47Idx];
				var score = 0.0;

				// Score subtile zones (9 zones)
				// Use distance to expected color + penalty when closer to wrong color
				for (si in 0...9) {
					final st = profile.subtiles[si];
					final distEdge = labDistance(st, edgeColor);
					final distFill = labDistance(st, fillColor);
					if (expected.subtiles[si] == 1) {
						// Expected fill: penalize if closer to edge than fill
						score += distFill;
						if (distFill > distEdge) score += (distFill - distEdge);
					} else {
						// Expected edge: penalize if closer to fill (center) than edge
						score += distEdge;
						if (distEdge > distFill) score += (distEdge - distFill);
					}
				}

				// Score corner zones (4 corners) - weighted higher for inner corner detection
				final cornerColors = [profile.nwCorner, profile.neCorner, profile.swCorner, profile.seCorner];
				for (ci in 0...4) {
					final cc = cornerColors[ci];
					final distEdge = labDistance(cc, edgeColor);
					final distFill = labDistance(cc, fillColor);
					if (expected.corners[ci] == 1) {
						// Expected notch (edge color in corner): penalize if closer to fill
						score += distEdge * 2;
						if (distEdge > distFill) score += (distEdge - distFill) * 2;
					} else {
						// No notch expected - should be fill: penalize if closer to edge
						score += distFill * 2;
						if (distFill > distEdge) score += (distFill - distEdge) * 2;
					}
				}

				candidates.push({regionIdx: regionIdx, blob47Idx: blob47Idx, score: score});
			}
		}

		// Sort by score (lower is better)
		candidates.sort((a, b) -> a.score < b.score ? -1 : a.score > b.score ? 1 : 0);

		// Greedily assign: best score first, skip if either side already assigned
		for (c in candidates) {
			if (currentMapping.exists(c.blob47Idx)) continue;
			if (usedRegionTiles.exists(c.regionIdx)) continue;

			currentMapping.set(c.blob47Idx, c.regionIdx);
			autoDetectedTiles.set(c.blob47Idx, true);
			usedRegionTiles.set(c.regionIdx, true);
			trace('Automap: region[${c.regionIdx}] -> blob47[${c.blob47Idx}] (score=${Std.int(c.score)})');
			autoCount++;
		}

		// Count still-missing blob47 tiles
		var missingCount = 0;
		for (i in 0...47) {
			if (!currentMapping.exists(i)) missingCount++;
		}

		rebuildBlob47Display();
		updateExportPreview();

		// Build status message
		final totalMapped = Lambda.count(currentMapping);
		if (missingCount > 0) {
			setStatus('Autodetected $autoCount tiles ($totalMapped/47 total). $missingCount patterns not found in region ($emptyTileCount empty tiles).');
		} else {
			setStatus('Autodetected $autoCount tiles ($totalMapped/47 total mapped)');
		}
	}

	// Capture pixels from a tile using the underlying texture's pixel data
	function capturePixelsFromTile(tile:Tile):Pixels {
		final w = Std.int(tile.width);
		final h = Std.int(tile.height);

		// Get the tile's position in the source texture using UV coordinates
		final tex = tile.getTexture();
		final texW = tex.width;
		final texH = tex.height;

		// Tile UV coordinates give us position in the texture
		final srcX = Std.int(@:privateAccess tile.u * texW);
		final srcY = Std.int(@:privateAccess tile.v * texH);

		// Capture pixels from the full texture and extract sub-region
		return tex.capturePixels().sub(srcX, srcY, w, h);
	}

	function analyzeTile(tile:Tile):TileColorProfile {
		final pixels = capturePixelsFromTile(tile);
		final w = Std.int(tile.width);
		final h = Std.int(tile.height);

		var nColors:Array<Int> = [];
		var sColors:Array<Int> = [];
		var eColors:Array<Int> = [];
		var wColors:Array<Int> = [];
		var centerColors:Array<Int> = [];

		for (y in 0...h) {
			for (x in 0...w) {
				final color = pixels.getPixel(x, y) & 0xFFFFFF;

				if (y == 0)
					nColors.push(color);
				if (y == h - 1)
					sColors.push(color);
				if (x == 0)
					wColors.push(color);
				if (x == w - 1)
					eColors.push(color);
				if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
					centerColors.push(color);
				}
			}
		}

		final nAvg = averageColor(nColors);
		final sAvg = averageColor(sColors);
		final eAvg = averageColor(eColors);
		final wAvg = averageColor(wColors);
		final edgeAvg = averageColor(nColors.concat(sColors).concat(eColors).concat(wColors));
		final centerAvg = averageColor(centerColors);

		return {
			edgeAvg: edgeAvg,
			centerAvg: centerAvg,
			nEdge: nAvg,
			sEdge: sAvg,
			eEdge: eAvg,
			wEdge: wAvg,
			edgeLum: colorToLuminance(edgeAvg),
			centerLum: colorToLuminance(centerAvg),
			nLum: colorToLuminance(nAvg),
			sLum: colorToLuminance(sAvg),
			eLum: colorToLuminance(eAvg),
			wLum: colorToLuminance(wAvg)
		};
	}

	function colorToLuminance(color:Int):Float {
		final r = (color >> 16) & 0xFF;
		final g = (color >> 8) & 0xFF;
		final b = color & 0xFF;
		// Standard luminance formula
		return 0.299 * r + 0.587 * g + 0.114 * b;
	}

	function averageColor(colors:Array<Int>):Int {
		if (colors.length == 0)
			return 0;
		var r = 0, g = 0, b = 0;
		for (c in colors) {
			r += (c >> 16) & 0xFF;
			g += (c >> 8) & 0xFF;
			b += c & 0xFF;
		}
		r = Std.int(r / colors.length);
		g = Std.int(g / colors.length);
		b = Std.int(b / colors.length);
		return (r << 16) | (g << 8) | b;
	}

	function colorDistance(c1:Int, c2:Int):Float {
		final r1 = (c1 >> 16) & 0xFF;
		final g1 = (c1 >> 8) & 0xFF;
		final b1 = c1 & 0xFF;
		final r2 = (c2 >> 16) & 0xFF;
		final g2 = (c2 >> 8) & 0xFF;
		final b2 = c2 & 0xFF;
		return Math.sqrt((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2));
	}

	// ============== LAB Color Space Functions ==============

	function rgbToLab(color:Int):LabColor {
		// Extract RGB
		var r = ((color >> 16) & 0xFF) / 255.0;
		var g = ((color >> 8) & 0xFF) / 255.0;
		var b = (color & 0xFF) / 255.0;

		// RGB to XYZ (sRGB with D65 illuminant)
		r = if (r > 0.04045) Math.pow((r + 0.055) / 1.055, 2.4) else r / 12.92;
		g = if (g > 0.04045) Math.pow((g + 0.055) / 1.055, 2.4) else g / 12.92;
		b = if (b > 0.04045) Math.pow((b + 0.055) / 1.055, 2.4) else b / 12.92;

		r *= 100; g *= 100; b *= 100;

		final x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
		final y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
		final z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

		// XYZ to LAB (D65 reference white)
		var xn = x / 95.047;
		var yn = y / 100.000;
		var zn = z / 108.883;

		xn = if (xn > 0.008856) Math.pow(xn, 1/3) else (7.787 * xn) + (16/116);
		yn = if (yn > 0.008856) Math.pow(yn, 1/3) else (7.787 * yn) + (16/116);
		zn = if (zn > 0.008856) Math.pow(zn, 1/3) else (7.787 * zn) + (16/116);

		return {
			l: (116 * yn) - 16,
			a: 500 * (xn - yn),
			b: 200 * (yn - zn)
		};
	}

	function labDistance(c1:LabColor, c2:LabColor):Float {
		// CIE76 Delta E
		final dl = c1.l - c2.l;
		final da = c1.a - c2.a;
		final db = c1.b - c2.b;
		return Math.sqrt(dl * dl + da * da + db * db);
	}

	function averageLabColor(colors:Array<LabColor>):LabColor {
		if (colors.length == 0) return {l: 0, a: 0, b: 0};
		var l = 0.0, a = 0.0, b = 0.0;
		for (c in colors) {
			l += c.l;
			a += c.a;
			b += c.b;
		}
		return {l: l / colors.length, a: a / colors.length, b: b / colors.length};
	}

	// Remove colors that are more than nStdDev standard deviations from the centroid
	function removeLabOutliers(colors:Array<LabColor>, centroid:LabColor, nStdDev:Float):Array<LabColor> {
		if (colors.length < 3) return colors;

		// Compute standard deviation of distances
		var sumDist = 0.0;
		var sumDist2 = 0.0;
		for (c in colors) {
			final d = labDistance(c, centroid);
			sumDist += d;
			sumDist2 += d * d;
		}
		final meanDist = sumDist / colors.length;
		final variance = sumDist2 / colors.length - meanDist * meanDist;
		final stdDev = Math.sqrt(Math.max(0, variance));
		final threshold = meanDist + nStdDev * stdDev;

		return [for (c in colors) if (labDistance(c, centroid) <= threshold) c];
	}

	// K-means clustering with k=2 to find edge and fill colors
	function kMeansCluster2(colors:Array<LabColor>, maxIterations:Int = 20):{cluster0:LabColor, cluster1:LabColor} {
		if (colors.length < 2) {
			final c = if (colors.length > 0) colors[0] else {l: 50.0, a: 0.0, b: 0.0};
			return {cluster0: c, cluster1: c};
		}

		// Initialize centroids: pick two colors with max distance
		var c0 = colors[0];
		var c1 = colors[0];
		var maxDist = 0.0;
		for (i in 0...colors.length) {
			for (j in (i + 1)...colors.length) {
				final d = labDistance(colors[i], colors[j]);
				if (d > maxDist) {
					maxDist = d;
					c0 = colors[i];
					c1 = colors[j];
				}
			}
		}

		// Iterate
		for (_ in 0...maxIterations) {
			// Assign colors to clusters
			var group0:Array<LabColor> = [];
			var group1:Array<LabColor> = [];

			for (color in colors) {
				if (labDistance(color, c0) < labDistance(color, c1)) {
					group0.push(color);
				} else {
					group1.push(color);
				}
			}

			// Update centroids
			final newC0 = if (group0.length > 0) averageLabColor(group0) else c0;
			final newC1 = if (group1.length > 0) averageLabColor(group1) else c1;

			// Check convergence
			if (labDistance(c0, newC0) < 0.1 && labDistance(c1, newC1) < 0.1) break;

			c0 = newC0;
			c1 = newC1;
		}

		// Return with lower L (darker) as cluster0 (typically edge)
		if (c0.l > c1.l) {
			return {cluster0: c1, cluster1: c0};
		}
		return {cluster0: c0, cluster1: c1};
	}

	// Analyze tile using 3x3 subtile grid
	function analyzeSubtiles(tile:Tile):SubtileProfile {
		final pixels = capturePixelsFromTile(tile);
		final w = Std.int(tile.width);
		final h = Std.int(tile.height);

		// Use pixel-snapped edge size
		final edgePx = getEdgePx();
		final xEdge = edgePx;
		final yEdge = edgePx;
		final xMid = w - 2 * xEdge;
		final yMid = h - 2 * yEdge;

		// Boundaries: [0, xEdge), [xEdge, xEdge+xMid), [xEdge+xMid, w)
		final xBounds = [0, xEdge, xEdge + xMid, w];
		final yBounds = [0, yEdge, yEdge + yMid, h];

		// Collect colors for each of 9 subtiles
		var subtileColors:Array<Array<Int>> = [for (_ in 0...9) []];
		// Corner pixels for inner corner detection
		var nwCornerColors:Array<Int> = [];
		var neCornerColors:Array<Int> = [];
		var swCornerColors:Array<Int> = [];
		var seCornerColors:Array<Int> = [];

		var opaqueCount = 0;
		for (y in 0...h) {
			for (x in 0...w) {
				final rawPixel = pixels.getPixel(x, y);
				final alpha = (rawPixel >>> 24) & 0xFF;
				if (alpha == 0) continue; // Skip fully transparent pixels
				opaqueCount++;
				final color = rawPixel & 0xFFFFFF;

				// Determine which subtile (0-8)
				var sx = if (x < xBounds[1]) 0 else if (x < xBounds[2]) 1 else 2;
				var sy = if (y < yBounds[1]) 0 else if (y < yBounds[2]) 1 else 2;
				final idx = sy * 3 + sx;
				subtileColors[idx].push(color);

				// Corner pixels (edgePx x edgePx in each corner)
				if (x < xEdge && y < yEdge) nwCornerColors.push(color);
				if (x >= w - xEdge && y < yEdge) neCornerColors.push(color);
				if (x < xEdge && y >= h - yEdge) swCornerColors.push(color);
				if (x >= w - xEdge && y >= h - yEdge) seCornerColors.push(color);
			}
		}

		// Convert to LAB averages
		var subtiles:Array<LabColor> = [];
		for (colors in subtileColors) {
			final avg = averageColor(colors);
			subtiles.push(rgbToLab(avg));
		}

		return {
			subtiles: subtiles,
			nwCorner: rgbToLab(averageColor(nwCornerColors)),
			neCorner: rgbToLab(averageColor(neCornerColors)),
			swCorner: rgbToLab(averageColor(swCornerColors)),
			seCorner: rgbToLab(averageColor(seCornerColors)),
			opaquePixelCount: opaqueCount
		};
	}

	// Classify a subtile as edge (0) or fill (1) based on cluster centroids
	function classifyColor(color:LabColor, edgeColor:LabColor, fillColor:LabColor):Int {
		return if (labDistance(color, edgeColor) < labDistance(color, fillColor)) 0 else 1;
	}

	function matchEdgePattern(profile:TileColorProfile, edges:{n:Bool, s:Bool, e:Bool, w:Bool, innerNE:Bool, innerNW:Bool, innerSE:Bool, innerSW:Bool},
			refEdge:Int, refFill:Int):Float {
		var score = 0.0;

		// Check N edge: if blob47 has N neighbor, region tile should have fill color on N
		// if blob47 has no N neighbor, region tile should have edge color on N
		if (edges.n) {
			score += colorDistance(profile.nEdge, refFill);
		} else {
			score += colorDistance(profile.nEdge, refEdge);
		}

		if (edges.s) {
			score += colorDistance(profile.sEdge, refFill);
		} else {
			score += colorDistance(profile.sEdge, refEdge);
		}

		if (edges.e) {
			score += colorDistance(profile.eEdge, refFill);
		} else {
			score += colorDistance(profile.eEdge, refEdge);
		}

		if (edges.w) {
			score += colorDistance(profile.wEdge, refFill);
		} else {
			score += colorDistance(profile.wEdge, refEdge);
		}

		return score;
	}

	public function exportMapping() {
		final keys = [for (k in currentMapping.keys()) k];
		keys.sort((a, b) -> a - b);

		// Build full autotile definition as single string
		final buf = new StringBuf();
		buf.add('#$autotileName autotile {\n');
		buf.add('    format: blob47\n');
		buf.add('    tileSize: $tileSize\n');
		switch autotileDef.source {
			case ATSFile(filename):
				buf.add('    file: "${resolveString(filename)}"\n');
			default:
		}
		final region = autotileDef.region;
		buf.add('    region: [${resolveInt(region[0])}, ${resolveInt(region[1])}, ${resolveInt(region[2])}, ${resolveInt(region[3])}]\n');
		buf.add('    allowPartialMapping: true\n');
		buf.add('    mapping: [\n');

		var outOfRange = 0;
		for (k in keys) {
			final regionIdx = currentMapping.get(k);
			final desc = describeBlob47(k);
			final comma = k == keys[keys.length - 1] ? "" : ",";
			if (regionIdx >= totalTiles) {
				buf.add('     $k:$regionIdx$comma    // $k: $desc  *** OUT OF RANGE ***\n');
				outOfRange++;
			} else {
				buf.add('     $k:$regionIdx$comma    // $k: $desc\n');
			}
		}
		buf.add(' ]\n');
		buf.add('}\n');

		trace(buf.toString());

		if (outOfRange > 0) {
			setStatus('WARNING: $outOfRange mappings have region tile indices out of range (max ${totalTiles - 1})!');
		} else {
			setStatus("Mapping exported to console (${keys.length}/${47} mapped)");
		}
	}

	function describeBlob47(idx:Int):String {
		final mask = getBlob47Mask(idx);
		var parts:Array<String> = [];
		if (mask & Autotile.N != 0)
			parts.push("N");
		if (mask & Autotile.NE != 0)
			parts.push("NE");
		if (mask & Autotile.E != 0)
			parts.push("E");
		if (mask & Autotile.SE != 0)
			parts.push("SE");
		if (mask & Autotile.S != 0)
			parts.push("S");
		if (mask & Autotile.SW != 0)
			parts.push("SW");
		if (mask & Autotile.W != 0)
			parts.push("W");
		if (mask & Autotile.NW != 0)
			parts.push("NW");
		return if (parts.length == 0) "isolated" else "has " + parts.join("+");
	}

	public function clearMapping() {
		// First clear only removes auto-detected, second clears all
		if (Lambda.count(autoDetectedTiles) > 0) {
			// Clear only auto-detected mappings
			for (blob47Idx in autoDetectedTiles.keys()) {
				currentMapping.remove(blob47Idx);
			}
			autoDetectedTiles.clear();
			setStatus("Auto-detected mappings cleared");
		} else {
			// Clear all mappings
			currentMapping.clear();
			setStatus("All mappings cleared");
		}
		rebuildBlob47Display();
		updateExportPreview();
	}

	function buildRatioPreview() {
		if (ratioPreview != null) ratioPreview.remove();
		final container = if (toolbarScreen != null) toolbarScreen.ratioContainer else null;

		ratioPreview = new h2d.Object(container != null ? container : s2d);

		updateRatioPreview();
	}

	function updateRatioPreview() {
		if (ratioPreview == null) return;

		// Remove all old children
		while (ratioPreview.numChildren > 0) {
			ratioPreview.getChildAt(0).remove();
		}

		final previewScale = 8;
		final previewSize = tileSize * previewScale;

		// Show the selected tile or a placeholder
		if (selectedRegionTile >= 0 && selectedRegionTile < regionTiles.length) {
			final bmp = new Bitmap(regionTiles[selectedRegionTile], ratioPreview);
			bmp.setScale(previewScale);
		} else {
			// Gray placeholder
			final placeholder = new Graphics(ratioPreview);
			placeholder.beginFill(0x555555);
			placeholder.drawRect(0, 0, previewSize, previewSize);
			placeholder.endFill();

			final hint = new Text(hxd.res.DefaultFont.get(), ratioPreview);
			hint.text = "Select a region tile";
			hint.textColor = 0x888888;
			hint.setPosition(4, previewSize / 2 - 6);
		}

		// Draw 3x3 grid overlay showing edge/center ratio (pixel-snapped)
		final gridGfx = new Graphics(ratioPreview);

		final edgePx = getEdgePx() * previewScale;
		final midPx = previewSize - 2 * edgePx;

		// Vertical lines
		gridGfx.lineStyle(2, 0xFF4444, 0.7);
		gridGfx.moveTo(edgePx, 0);
		gridGfx.lineTo(edgePx, previewSize);
		gridGfx.moveTo(edgePx + midPx, 0);
		gridGfx.lineTo(edgePx + midPx, previewSize);

		// Horizontal lines
		gridGfx.moveTo(0, edgePx);
		gridGfx.lineTo(previewSize, edgePx);
		gridGfx.moveTo(0, edgePx + midPx);
		gridGfx.lineTo(previewSize, edgePx + midPx);

		// Outer border
		gridGfx.lineStyle(1, 0xAAAAAA, 0.5);
		gridGfx.drawRect(0, 0, previewSize, previewSize);

		// Zone labels (NW, N, NE, W, C, E, SW, S, SE)
		final zoneNames = ["NW", "N", "NE", "W", "C", "E", "SW", "S", "SE"];
		final zoneX = [edgePx / 2, edgePx + midPx / 2, edgePx + midPx + edgePx / 2];
		final zoneY = [edgePx / 2, edgePx + midPx / 2, edgePx + midPx + edgePx / 2];
		for (zi in 0...9) {
			final zx = zoneX[zi % 3];
			final zy = zoneY[Std.int(zi / 3)];
			final zt = new Text(hxd.res.DefaultFont.get(), ratioPreview);
			zt.text = zoneNames[zi];
			zt.textColor = 0xFFFF44;
			zt.dropShadow = {dx: 1, dy: 1, color: 0, alpha: 1};
			zt.setPosition(Std.int(zx) - 4, Std.int(zy) - 6);
		}

		// Update ratio label via .manim updatable element
		if (toolbarScreen != null) {
			final snappedEdge = getEdgePx();
			toolbarScreen.updateNamedText("ratioLabel", 'Edge/Center: ${snappedEdge}px-${tileSize - 2 * snappedEdge}px-${snappedEdge}px');
		}
	}

	public function setSubtileRatio(edgePercent:Int) {
		// Snap to closest pixel boundary
		final edgePx = Math.round(tileSize * edgePercent / 100.0);
		final snappedPx = Std.int(Math.max(1, Math.min(edgePx, Std.int(tileSize / 2) - 1)));
		subtileEdgeRatio = Std.int(Math.round(snappedPx * 100.0 / tileSize));
		subtileMiddleRatio = 100 - 2 * subtileEdgeRatio;
		updateRatioPreview();
		setStatus('Edge: ${snappedPx}px / Center: ${tileSize - 2 * snappedPx}px (${subtileEdgeRatio}-${subtileMiddleRatio}-${subtileEdgeRatio}%)  Press A to re-autodetect');
	}

	// Get the snapped edge pixel size for the current ratio
	function getEdgePx():Int {
		return Std.int(Math.max(1, Math.round(tileSize * subtileEdgeRatio / 100.0)));
	}

	public function reloadManim() {
		try {
			loadAndParseManim();
			buildUI();
			setStatus("Reloaded");
		} catch (e) {
			showError('Reload error: $e');
		}
	}

	function showError(msg:String) {
		trace('ERROR: $msg');
		final errorText = new Text(hxd.res.DefaultFont.get(), s2d);
		errorText.text = msg;
		errorText.textColor = 0xFF4444;
		errorText.setScale(2);
		errorText.setPosition(50, 100);
	}

	public static function main() {
		parseArguments();
		trace('Starting AutotileMapper with file: $argManimFile, autotile: $argAutotileName');
		try {
			new AutotileMapper();
		} catch (e) {
			trace('FATAL ERROR: $e');
			Sys.exit(1);
		}
	}
}

typedef TileColorProfile = {
	edgeAvg:Int,
	centerAvg:Int,
	nEdge:Int,
	sEdge:Int,
	eEdge:Int,
	wEdge:Int,
	// Luminance values (0-255)
	edgeLum:Float,
	centerLum:Float,
	nLum:Float,
	sLum:Float,
	eLum:Float,
	wLum:Float
};

// 3x3 subtile color profile using LAB colors
typedef SubtileProfile = {
	// 3x3 grid of LAB colors: [NW, N, NE, W, C, E, SW, S, SE]
	subtiles:Array<LabColor>,
	// Corner colors for inner corner detection
	nwCorner:LabColor,
	neCorner:LabColor,
	swCorner:LabColor,
	seCorner:LabColor,
	// Number of opaque (alpha > 0) pixels in the tile
	opaquePixelCount:Int
};

typedef LabColor = {
	l:Float, // Lightness 0-100
	a:Float, // Green-Red -128 to 127
	b:Float // Blue-Yellow -128 to 127
};

// Toolbar screen using std.manim UI components
class AutotileToolbarScreen extends UIScreenBase {
	final mapper:AutotileMapper;

	var autodetectBtn:UIStandardMultiAnimButton;
	var exportBtn:UIStandardMultiAnimButton;
	var clearBtn:UIStandardMultiAnimButton;
	var reloadBtn:UIStandardMultiAnimButton;

	// Sliders (positioned by .manim layout)
	public var regionZoomSlider:UIStandardMultiAnimSlider;
	public var blob47ZoomSlider:UIStandardMultiAnimSlider;
	public var demoZoomSlider:UIStandardMultiAnimSlider;
	public var ratioSlider:UIStandardMultiAnimSlider;

	// Container objects for dynamic content (positioned by .manim layout)
	public var regionContainer:h2d.Object;
	public var blob47Container:h2d.Object;
	public var demoContainer:h2d.Object;
	public var ratioContainer:h2d.Object;

	// Builder result for accessing updatable elements
	var uiBuilderResult:bh.multianim.BuilderResult;

	// Convert slider value (0-100) to scale (1-16)
	static function sliderToScale(v:Int):Int {
		return Std.int(Math.max(1, 1 + v * 15 / 100));
	}

	// Convert scale (1-16) to slider value (0-100)
	public static function scaleToSlider(s:Int):Int {
		return Std.int((s - 1) * 100 / 15);
	}

	// Convert ratio slider (0-100) to edge percent (5-45)
	static function sliderToRatio(v:Int):Int {
		return Std.int(5 + v * 40 / 100);
	}

	static function ratioToSlider(r:Int):Int {
		return Std.int((r - 5) * 100 / 40);
	}

	public function new(screenManager:ScreenManager, mapper:AutotileMapper) {
		super(screenManager);
		this.mapper = mapper;
	}

	public function load():Void {
		final stdBuilder = screenManager.buildFromResourceName("std.manim", false);
		final uiBuilder = screenManager.buildFromResourceName("autotile-mapper-ui.manim", false);

		// Pre-create container objects for dynamic content (passed as h2d.Object to .manim placeholders)
		regionContainer = new h2d.Object();
		blob47Container = new h2d.Object();
		demoContainer = new h2d.Object();
		ratioContainer = new h2d.Object();

		// Build UI from .manim definition, mapping placeholders to controls
		var ui = MacroUtils.macroBuildWithParameters(uiBuilder, "mapperUI", [], [
			autodetectBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Autodetect"),
			exportBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Export"),
			clearBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Clear"),
			reloadBtn => addButtonWithSingleBuilder(stdBuilder, "button", "Reload"),
			regionZoomSlider => addSlider(stdBuilder, scaleToSlider(mapper.regionTileScale)),
			blob47ZoomSlider => addSlider(stdBuilder, scaleToSlider(mapper.blob47TileScale)),
			demoZoomSlider => addSlider(stdBuilder, scaleToSlider(mapper.demoPreviewScale)),
			ratioSlider => addSlider(stdBuilder, ratioToSlider(mapper.subtileEdgeRatio)),
			regionContainer => regionContainer,
			blob47Container => blob47Container,
			demoContainer => demoContainer,
			ratioContainer => ratioContainer,
		]);

		this.autodetectBtn = ui.autodetectBtn;
		this.exportBtn = ui.exportBtn;
		this.clearBtn = ui.clearBtn;
		this.reloadBtn = ui.reloadBtn;
		this.regionZoomSlider = ui.regionZoomSlider;
		this.blob47ZoomSlider = ui.blob47ZoomSlider;
		this.demoZoomSlider = ui.demoZoomSlider;
		this.ratioSlider = ui.ratioSlider;

		// Wire up button callbacks
		autodetectBtn.onClick = () -> mapper.autodetect();
		exportBtn.onClick = () -> mapper.exportMapping();
		clearBtn.onClick = () -> mapper.clearMapping();
		reloadBtn.onClick = () -> mapper.reloadManim();

		uiBuilderResult = addBuilderResult(ui.builderResults);
		trace("AutotileToolbarScreen.load() done, elements: " + elements.length);
	}

	public function updateNamedText(name:String, text:String) {
		if (uiBuilderResult != null) {
			uiBuilderResult.getUpdatable(name).updateText(text);
		}
	}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>) {
		switch event {
			case UIChangeValue(value):
				if (source == ratioSlider) {
					mapper.setSubtileRatio(sliderToRatio(value));
				} else if (source == regionZoomSlider) {
					mapper.setRegionZoom(sliderToScale(value));
				} else if (source == blob47ZoomSlider) {
					mapper.setBlob47Zoom(sliderToScale(value));
				} else if (source == demoZoomSlider) {
					mapper.setDemoZoom(sliderToScale(value));
				}
			default:
		}
	}
}
