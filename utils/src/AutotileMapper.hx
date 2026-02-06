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

using StringTools;

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
	var statusText:Text;
	var exportText:Text;

	// Calculated layout positions
	var regionSheetHeight:Int;

	// Selection state
	var selectedRegionTile:Int = -1;
	var selectedBlob47Tile:Int = -1;
	var hoveredRegionTile:Int = -1;
	var hoveredBlob47Tile:Int = -1;

	// Display settings
	static inline var REGION_TILE_SCALE = 4;
	static inline var BLOB47_TILE_SCALE = 8;
	static inline var TILE_SPACING = 2;
	static inline var REGION_START_X = 20;
	static inline var REGION_START_Y = 80;
	static inline var BLOB47_TILES_PER_ROW = 12;

	// 3x3 subtile analysis settings (edge-middle-edge ratio, should sum to 100)
	var subtileEdgeRatio:Int = 25; // % for edge bands (N, S, E, W)
	var subtileMiddleRatio:Int = 50; // % for middle (remaining after edges)

	// Resource loader
	var resourceLoader:CachingResourceLoader;

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

		try {
			loadAndParseManim();
			buildUI();
		} catch (e) {
			showError('Error: ${e}');
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
				case EKeyDown if (event.keyCode == Key.NUMBER_1):
					setSubtileRatio(10);
				case EKeyDown if (event.keyCode == Key.NUMBER_2):
					setSubtileRatio(20);
				case EKeyDown if (event.keyCode == Key.NUMBER_3):
					setSubtileRatio(25);
				case EKeyDown if (event.keyCode == Key.NUMBER_4):
					setSubtileRatio(30);
				case EKeyDown if (event.keyCode == Key.NUMBER_5):
					setSubtileRatio(35);
				default:
			}
		});

		engine.backgroundColor = 0x303030;
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
		if (autotileDef.mapping != null) {
			for (k => v in autotileDef.mapping) {
				currentMapping.set(k, v);
			}
		}

		trace('Loaded autotile "$autotileName": ${totalTiles} tiles in region, ${Lambda.count(currentMapping)} mappings defined');
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
		// Title
		final titleText = new Text(hxd.res.DefaultFont.get(), s2d);
		titleText.text = 'Autotile Mapper: $autotileName ($manimFile)';
		titleText.setScale(1.5);
		titleText.setPosition(10, 10);

		// Instructions (top right)
		final helpText = new Text(hxd.res.DefaultFont.get(), s2d);
		helpText.text = "[A] Autodetect  [E] Export  [C] Clear  [R] Reload  [1-5] Ratio  [Q] Quit  |  Click region, then blob47 to map";
		helpText.textColor = 0xAAAAAA;
		helpText.textAlign = Right;
		helpText.setPosition(2550, 10);

		// Status text
		statusText = new Text(hxd.res.DefaultFont.get(), s2d);
		statusText.textColor = 0x88FF88;
		statusText.setPosition(10, 35);

		// Region tiles display
		buildRegionDisplay();

		// Blob47 tiles display (positioned below region)
		buildBlob47Display();

		// Demo preview (bottom right)
		buildDemoPreview();

		// Export preview area (hidden for now)
		exportText = new Text(hxd.res.DefaultFont.get(), s2d);
		exportText.maxWidth = 600;
		exportText.textColor = 0xCCCCCC;
		exportText.visible = false;
	}

	function buildRegionDisplay() {
		if (regionDisplay != null) regionDisplay.remove();

		regionDisplay = new h2d.Object(s2d);
		regionDisplay.setPosition(REGION_START_X, REGION_START_Y);

		// Label
		final label = new Text(hxd.res.DefaultFont.get(), regionDisplay);
		label.text = 'Region Sheet (${totalTiles} tiles, ${tilesPerRow}x${tilesPerCol}):';
		label.setPosition(0, -20);

		// Display full region as single scaled bitmap
		final regionBmp = new Bitmap(regionSheetTile, regionDisplay);
		regionBmp.setScale(REGION_TILE_SCALE);

		final scaledTileSize = tileSize * REGION_TILE_SCALE;

		// Calculate region sheet height for positioning elements below
		regionSheetHeight = tilesPerCol * scaledTileSize;

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
			};
			inter.onOut = _ -> {
				if (hoveredRegionTile == idx) hoveredRegionTile = -1;
				updateStatus();
			};
			inter.onClick = _ -> {
				selectedRegionTile = idx;
				selectedBlob47Tile = -1;
				updateStatus();
				updateHighlights();
			};
			inter.onPush = e -> {
				if (e.button == 1) {
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

		// Highlight graphics for selection
		final highlightGfx = new Graphics(regionDisplay);
		highlightGfx.name = "regionHighlight";
	}

	function buildBlob47Display() {
		if (blob47Display != null) blob47Display.remove();

		blob47Display = new h2d.Object(s2d);
		// Position below the region sheet with some margin
		final blob47StartY = REGION_START_Y + regionSheetHeight + 40;
		blob47Display.setPosition(REGION_START_X, blob47StartY);

		// Label
		final label = new Text(hxd.res.DefaultFont.get(), blob47Display);
		label.text = "Blob47 Tiles (0-46) - Click to assign selected region tile:";
		label.setPosition(0, -20);

		// Each cell shows: demo tile (left) + mapped tile (right) + index label below
		final scaledTileSize = tileSize * BLOB47_TILE_SCALE;
		final pairGap = 12; // Gap between demo tile and mapped tile
		final cellWidth = scaledTileSize * 2 + pairGap + TILE_SPACING; // demo + gap + mapped + spacing
		final cellHeight = scaledTileSize + 16 + TILE_SPACING; // tile + label height + spacing

		for (i in 0...47) {
			final tx = (i % BLOB47_TILES_PER_ROW) * cellWidth;
			final ty = Std.int(i / BLOB47_TILES_PER_ROW) * cellHeight;

			// Background showing mapping status
			final bg = new Graphics(blob47Display);
			bg.setPosition(tx, ty);
			drawTileBackground(bg, i, cellWidth - TILE_SPACING, scaledTileSize);

			// Show demo tile shape (left side)
			final demoTile = generateDemoTile(i);
			final demoBmp = new Bitmap(demoTile, blob47Display);
			demoBmp.setScale(BLOB47_TILE_SCALE);
			demoBmp.setPosition(tx, ty);

			// If mapped, show the mapped tile on the right
			if (currentMapping.exists(i)) {
				final mappedIdx = currentMapping.get(i);
				if (mappedIdx >= 0 && mappedIdx < regionTiles.length) {
					final mappedBmp = new Bitmap(regionTiles[mappedIdx], blob47Display);
					mappedBmp.setScale(BLOB47_TILE_SCALE);
					mappedBmp.setPosition(tx + scaledTileSize + pairGap, ty);
				}
			}

			// Index and mapping label (below tiles)
			final indexLabel = new Text(hxd.res.DefaultFont.get(), blob47Display);
			final mappingText = currentMapping.exists(i) ? ' > ${currentMapping.get(i)}' : "";
			indexLabel.text = '$i$mappingText';
			indexLabel.textColor = currentMapping.exists(i) ? 0x88FF88 : 0x888888;
			indexLabel.dropShadow = {dx: 1, dy: 1, color: 0, alpha: 1};
			indexLabel.setPosition(tx, ty + scaledTileSize + 2);

			// Interactive overlay
			final inter = new Interactive(cellWidth - TILE_SPACING, scaledTileSize, blob47Display);
			inter.enableRightButton = true;
			inter.setPosition(tx, ty);
			final idx = i;
			inter.onOver = _ -> {
				hoveredBlob47Tile = idx;
				updateStatus();
			};
			inter.onOut = _ -> {
				if (hoveredBlob47Tile == idx) hoveredBlob47Tile = -1;
				updateStatus();
			};
			inter.onClick = _ -> {
				if (selectedRegionTile >= 0) {
					// Map the selected region tile to this blob47 index
					currentMapping.set(idx, selectedRegionTile);
					selectedBlob47Tile = idx;
					updateStatus();
					rebuildBlob47Display();
					updateExportPreview();
				} else {
					// Select this blob47 tile to see what it maps to
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
					// Right-click to remove mapping
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
	}

	function rebuildBlob47Display() {
		buildBlob47Display();
		updateDemoPreview();
	}

	function buildDemoPreview() {
		demoPreview = new h2d.Object(s2d);
		demoPreview.setPosition(1800, 800);

		// Label
		final label = new Text(hxd.res.DefaultFont.get(), demoPreview);
		label.text = "Demo Map (blob47 pattern):";
		label.setPosition(0, -20);

		updateDemoPreview();
	}

	function updateDemoPreview() {
		if (demoPreview == null) return;

		// Remove old children except label
		while (demoPreview.numChildren > 1) {
			demoPreview.getChildAt(1).remove();
		}

		// LARGE_SEA_GRID - Comprehensive blob47 test grid (16x12)
		// Designed to produce all 47 unique tiles.
		// 1 = terrain, 0 = empty
		final previewScale = 2;
		final previewTileSize = tileSize * previewScale;

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

		for (row in 0...mapHeight) {
			for (col in 0...mapWidth) {
				if (terrainMap[row][col] == 0) continue; // Skip empty cells

				// Calculate blob47 index from neighbors
				final blob47Idx = calculateBlob47Index(terrainMap, col, row, mapWidth, mapHeight);

				final tx = col * previewTileSize;
				final ty = row * previewTileSize;

				// Get the tile to display - mapped tile or demo tile
				var tileToDraw:Tile;
				if (currentMapping.exists(blob47Idx)) {
					final mappedIdx = currentMapping.get(blob47Idx);
					if (mappedIdx >= 0 && mappedIdx < regionTiles.length) {
						tileToDraw = regionTiles[mappedIdx];
					} else {
						tileToDraw = generateDemoTile(blob47Idx);
					}
				} else {
					tileToDraw = generateDemoTile(blob47Idx);
				}

				final bmp = new Bitmap(tileToDraw, demoPreview);
				bmp.setScale(previewScale);
				bmp.setPosition(tx, ty);
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
		if (currentMapping.exists(blob47Idx)) {
			if (autoDetectedTiles.exists(blob47Idx)) {
				g.beginFill(0x442244); // Purple/pink background for auto-detected
			} else {
				g.beginFill(0x225522); // Green for manual
			}
		} else {
			g.beginFill(0x444444);
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

	function updateStatus() {
		var status = "";
		if (selectedRegionTile >= 0) {
			status += 'Selected region tile: $selectedRegionTile  ';
		}
		if (hoveredBlob47Tile >= 0) {
			status += 'Hover blob47: $hoveredBlob47Tile';
			if (currentMapping.exists(hoveredBlob47Tile)) {
				status += ' -> ${currentMapping.get(hoveredBlob47Tile)}';
			}
		}
		if (hoveredRegionTile >= 0) {
			status += 'Hover region: $hoveredRegionTile';
		}
		statusText.text = status;
	}

	function updateHighlights() {
		// Could add visual highlights for selected tiles
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

	function autodetect() {
		trace("Running autodetection with LAB k-means clustering...");
		statusText.text = "Autodetecting...";
		statusText.textColor = 0xFFFF88;

		// Analyze each region tile using 3x3 subtile grid
		final subtileProfiles:Array<SubtileProfile> = [];
		for (i in 0...regionTiles.length) {
			subtileProfiles.push(analyzeSubtiles(regionTiles[i]));
		}

		// Collect all colors from manual mappings (not auto-detected) to train k-means
		// Filter out very dark colors (likely transparent/background)
		var referenceColors:Array<LabColor> = [];

		for (blob47Idx => regionIdx in currentMapping) {
			if (autoDetectedTiles.exists(blob47Idx)) continue; // Skip auto-detected
			if (regionIdx >= 0 && regionIdx < subtileProfiles.length) {
				final profile = subtileProfiles[regionIdx];
				// Add all 9 subtile colors, filtering out near-black
				for (c in profile.subtiles) {
					if (c.l > 5) { // Filter out very dark colors
						referenceColors.push(c);
					}
				}
			}
		}

		trace('Reference colors from manual mappings: ${referenceColors.length}');

		// If not enough reference colors, use all tiles' colors for clustering
		if (referenceColors.length < 4) {
			trace("Not enough manual mapping colors, using all region tiles for k-means");
			for (profile in subtileProfiles) {
				for (c in profile.subtiles) {
					if (c.l > 5) { // Filter out very dark colors
						referenceColors.push(c);
					}
				}
			}
		}

		trace('Total colors for k-means: ${referenceColors.length}');

		// Run k-means to find the two main colors
		final clusters = kMeansCluster2(referenceColors);

		// Determine which is edge vs fill by checking center subtile colors
		// The center subtile (index 4) should be fill color in most tiles
		var centerColorSum0 = 0.0;
		var centerColorSum1 = 0.0;
		var centerCount = 0;
		for (profile in subtileProfiles) {
			// Skip empty tiles
			var maxL = 0.0;
			for (st in profile.subtiles) if (st.l > maxL) maxL = st.l;
			if (maxL < 5) continue;

			final centerColor = profile.subtiles[4]; // Center subtile
			centerColorSum0 += labDistance(centerColor, clusters.cluster0);
			centerColorSum1 += labDistance(centerColor, clusters.cluster1);
			centerCount++;
		}

		// The color closer to center subtiles is the fill color
		var edgeColor:LabColor;
		var fillColor:LabColor;
		if (centerCount > 0 && centerColorSum0 > centerColorSum1) {
			// cluster1 is closer to centers, so it's fill
			edgeColor = clusters.cluster0;
			fillColor = clusters.cluster1;
		} else {
			// cluster0 is closer to centers, so it's fill
			edgeColor = clusters.cluster1;
			fillColor = clusters.cluster0;
		}

		// Check if clusters are too similar (k-means failed)
		final clusterDist = labDistance(edgeColor, fillColor);
		trace('K-means clusters - Edge: L=${Std.int(edgeColor.l)} a=${Std.int(edgeColor.a)} b=${Std.int(edgeColor.b)}, Fill: L=${Std.int(fillColor.l)} a=${Std.int(fillColor.a)} b=${Std.int(fillColor.b)}, Distance: $clusterDist');

		if (clusterDist < 10) {
			trace("Warning: Clusters too similar, autodetect may not work well. Try setting more manual mappings.");
			statusText.text = "Clusters too similar - set more manual mappings first";
			statusText.textColor = 0xFF8888;
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

		// Count patterns generated from region tiles for diagnostics
		var regionPatternCounts = new Map<Int, Int>();

		// Track which patterns have already been assigned to prevent duplicates
		var assignedPatterns = new Map<Int, Bool>();

		// Go over each unassigned region tile and try to find a blob47 match
		for (regionIdx in 0...subtileProfiles.length) {
			if (usedRegionTiles.exists(regionIdx)) continue;

			final profile = subtileProfiles[regionIdx];

			// Skip empty/transparent tiles (all subtiles have very low luminance)
			var maxLuminance = 0.0;
			for (st in profile.subtiles) {
				if (st.l > maxLuminance) maxLuminance = st.l;
			}
			if (maxLuminance < 5) {
				// This tile is empty/transparent, count it but skip processing
				regionPatternCounts.set(-1, (regionPatternCounts.exists(-1) ? regionPatternCounts.get(-1) : 0) + 1);
				continue;
			}

			// Classify each subtile: 0=edge, 1=fill
			// Subtile indices: 0=NW, 1=N, 2=NE, 3=W, 4=C, 5=E, 6=SW, 7=S, 8=SE
			var classes:Array<Int> = [];
			for (st in profile.subtiles) {
				classes.push(classifyColor(st, edgeColor, fillColor));
			}

			// Determine cardinal direction neighbors based on edge subtiles
			// N edge (index 1): if fill, has N neighbor
			// S edge (index 7): if fill, has S neighbor
			// E edge (index 5): if fill, has E neighbor
			// W edge (index 3): if fill, has W neighbor
			final hasN = classes[1] == 1;
			final hasS = classes[7] == 1;
			final hasE = classes[5] == 1;
			final hasW = classes[3] == 1;

			// Determine inner corners from corner subtiles
			// Inner corner exists when cardinal neighbors are present but corner pixel is edge color
			final hasInnerNE = hasN && hasE && classifyColor(profile.neCorner, edgeColor, fillColor) == 0;
			final hasInnerNW = hasN && hasW && classifyColor(profile.nwCorner, edgeColor, fillColor) == 0;
			final hasInnerSE = hasS && hasE && classifyColor(profile.seCorner, edgeColor, fillColor) == 0;
			final hasInnerSW = hasS && hasW && classifyColor(profile.swCorner, edgeColor, fillColor) == 0;

			// Build pattern - for blob47, inner corner bits are SET when corner IS present (no notch)
			var pattern = 0;
			if (hasN) pattern |= 1;
			if (hasS) pattern |= 2;
			if (hasE) pattern |= 4;
			if (hasW) pattern |= 8;
			// Inner corners: bit is set if corner IS filled (neighbor diagonal present)
			if (hasN && hasE && !hasInnerNE) pattern |= 16; // NE filled = no inner corner notch
			if (hasN && hasW && !hasInnerNW) pattern |= 32;
			if (hasS && hasE && !hasInnerSE) pattern |= 64;
			if (hasS && hasW && !hasInnerSW) pattern |= 128;

			// Count this pattern
			regionPatternCounts.set(pattern, (regionPatternCounts.exists(pattern) ? regionPatternCounts.get(pattern) : 0) + 1);

			// Find matching blob47 tile(s) - only assign if this pattern hasn't been used yet
			if (patternToBlob47.exists(pattern) && !assignedPatterns.exists(pattern)) {
				final candidates = patternToBlob47.get(pattern);
				for (blob47Idx in candidates) {
					if (currentMapping.exists(blob47Idx)) continue;

					currentMapping.set(blob47Idx, regionIdx);
					autoDetectedTiles.set(blob47Idx, true);
					usedRegionTiles.set(regionIdx, true);
					assignedPatterns.set(pattern, true); // Mark this pattern as used
					trace('Automap: region[$regionIdx] -> blob47[$blob47Idx] (pattern=$pattern N:$hasN S:$hasS E:$hasE W:$hasW)');
					autoCount++;
					break; // One region tile per blob47
				}
			}
		}

		// Count missing blob47 patterns
		var missingCount = 0;
		for (pattern => blob47Indices in patternToBlob47) {
			if (!regionPatternCounts.exists(pattern)) {
				for (idx in blob47Indices) {
					if (!currentMapping.exists(idx)) {
						missingCount++;
					}
				}
			}
		}

		// Count empty tiles (skipped due to low luminance)
		var emptyTileCount = regionPatternCounts.exists(-1) ? regionPatternCounts.get(-1) : 0;

		rebuildBlob47Display();
		updateExportPreview();

		// Build status message
		final totalMapped = Lambda.count(currentMapping);
		if (missingCount > 0) {
			statusText.text = 'Autodetected $autoCount tiles ($totalMapped/47 total). $missingCount patterns not found in region ($emptyTileCount empty tiles).';
			statusText.textColor = 0xFFAA44; // Orange warning
		} else {
			statusText.text = 'Autodetected $autoCount tiles ($totalMapped/47 total mapped)';
			statusText.textColor = 0x66FF66; // Green success
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

		// Calculate subtile boundaries based on ratio
		final edgeSize = subtileEdgeRatio / 100.0;
		final xEdge = Std.int(w * edgeSize);
		final yEdge = Std.int(h * edgeSize);
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

		for (y in 0...h) {
			for (x in 0...w) {
				final color = pixels.getPixel(x, y) & 0xFFFFFF;

				// Determine which subtile (0-8)
				var sx = if (x < xBounds[1]) 0 else if (x < xBounds[2]) 1 else 2;
				var sy = if (y < yBounds[1]) 0 else if (y < yBounds[2]) 1 else 2;
				final idx = sy * 3 + sx;
				subtileColors[idx].push(color);

				// Corner pixels (2x2 in each corner)
				if (x < 2 && y < 2) nwCornerColors.push(color);
				if (x >= w - 2 && y < 2) neCornerColors.push(color);
				if (x < 2 && y >= h - 2) swCornerColors.push(color);
				if (x >= w - 2 && y >= h - 2) seCornerColors.push(color);
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
			seCorner: rgbToLab(averageColor(seCornerColors))
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

	function exportMapping() {
		trace("\n========== EXPORT MAPPING ==========");
		trace("mapping: [");

		final keys = [for (k in currentMapping.keys()) k];
		keys.sort((a, b) -> a - b);

		for (k in keys) {
			final desc = describeBlob47(k);
			trace('    $k:${currentMapping.get(k)},    // $k: $desc');
		}
		trace("]");
		trace("=====================================\n");

		statusText.text = "Mapping exported to console";
		statusText.textColor = 0x88FF88;
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

	function clearMapping() {
		// First clear only removes auto-detected, second clears all
		if (Lambda.count(autoDetectedTiles) > 0) {
			// Clear only auto-detected mappings
			for (blob47Idx in autoDetectedTiles.keys()) {
				currentMapping.remove(blob47Idx);
			}
			autoDetectedTiles.clear();
			statusText.text = "Auto-detected mappings cleared";
			statusText.textColor = 0xFFAA88;
		} else {
			// Clear all mappings
			currentMapping.clear();
			statusText.text = "All mappings cleared";
			statusText.textColor = 0xFF8888;
		}
		rebuildBlob47Display();
		updateExportPreview();
	}

	function setSubtileRatio(edgePercent:Int) {
		subtileEdgeRatio = edgePercent;
		subtileMiddleRatio = 100 - 2 * edgePercent;
		statusText.text = 'Subtile ratio: $subtileEdgeRatio-$subtileMiddleRatio-$subtileEdgeRatio (press A to re-autodetect)';
		statusText.textColor = 0x88AAFF;
	}

	function reloadManim() {
		try {
			loadAndParseManim();
			buildUI();
			statusText.text = "Reloaded";
			statusText.textColor = 0x88FF88;
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
	seCorner:LabColor
};

typedef LabColor = {
	l:Float, // Lightness 0-100
	a:Float, // Green-Red -128 to 127
	b:Float // Blue-Yellow -128 to 127
};
