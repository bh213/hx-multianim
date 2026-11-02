package bh.base;

import bh.multianim.MultiAnimParser.TilesetGridDef;

/** The three grids a tileset's tiles may be laid on (`grid:` in a tileset). **/
enum TileGridKind {
	Orthogonal;
	Isometric;
	Hex;
}

/**
	Where the cells of a tile map are on screen, for each grid a tileset may say (`grid:`): the
	square one, the isometric one (diamonds) and the hex one (pointy or flat, odd or even rows or
	columns pushed over). A map's rows are offset coordinates in every grid: cell (cx, cy) is column
	cx of row cy, a hex map typed row by row as a square one is.

	A cell's box is `tileWidth` by `tileHeight` pixels: the square, the diamond's or the hex's
	bounding box. `toPixel` is its top-left:

	- orthogonal: (cx * w, cy * h);
	- isometric: ((cx - cy - 1) * w / 2, (cx + cy) * h / 2), so cell (0, 0)'s top corner is at the
	  origin, cx running down to the right and cy down to the left;
	- hex, pointy: (cx * w + (pushed(cy) ? w / 2 : 0), cy * rowStep), rowStep = (h + side) / 2;
	- hex, flat: (cx * columnStep, cy * h + (pushed(cx) ? h / 2 : 0)), columnStep = (w + side) / 2;

	where `side` is the length of the hex's two sides that run across the push (upright on a pointy
	hex, level on a flat one), half the box when unsaid (a regular hex: a step of three quarters),
	and `pushed(n)` is n odd for `odd`, n even for `even`. `toCell` is the inverse, a point on a
	cell's edge going to either.

	Neighbours are numbered: on the square and isometric grids the 8 of `Autotile`'s masks in its
	bit order (0 N, 1 NE, 2 E, 3 SE, 4 S, 5 SW, 6 W, 7 NW, in cells: N is (0, -1) whatever the grid,
	which the isometric grid draws up and to the right); on the hex grid the 6 edges from the top,
	clockwise (pointy: 0 NE, 1 E, 2 SE, 3 SW, 4 W, 5 NW; flat: 0 N, 1 NE, 2 SE, 3 S, 4 SW, 5 NW).

	A frame is put on its cell (`frameX`, `frameY`): on the square grid from the box's top-left, as
	always; on the isometric and hex grids standing on it, its bottom on the box's bottom and its
	middle over the box's middle, as Tiled draws them; then moved by the tileset's `tileOffset`.
**/
class TileGrid {
	public final kind:TileGridKind;

	/** A cell's box, in pixels. **/
	public final tileWidth:Int;

	public final tileHeight:Int;

	/** Hex: the corners point up and down (rows are pushed); false, flat: left and right (columns are). **/
	public final pointy:Bool;

	/** Hex: the odd rows (pointy) or columns (flat) are pushed half a cell over; false: the even ones. **/
	public final odd:Bool;

	/** Hex: the length of the two sides across the push (upright on a pointy hex, level on a flat one). **/
	public final side:Int;

	/** Pixels from a column to the next, and from a row to the next, before any push. **/
	public final columnStep:Float;

	public final rowStep:Float;

	/** Pixels every frame is moved after it is put on its cell (the tileset's `tileOffset`). **/
	public final offsetX:Int;

	public final offsetY:Int;

	/** How many neighbours a cell has: 8, or 6 on the hex grid. **/
	public final neighbourCount:Int;

	// Hex: how far the box's corner triangles reach in from its top and bottom (pointy) or its
	// left and right (flat): the slanted edges' height (or width)
	final slant:Float;

	static final SQUARE_DX = [0, 1, 1, 1, 0, -1, -1, -1];
	static final SQUARE_DY = [-1, -1, 0, 1, 1, 1, 0, -1];
	// Pointy hexes, by direction (NE, E, SE, SW, W, NW): a row not pushed, and a pushed one
	static final POINTY_DX = [0, 1, 0, -1, -1, -1];
	static final POINTY_DY = [-1, 0, 1, 1, 0, -1];
	static final POINTY_PUSHED_DX = [1, 1, 1, 0, -1, 0];
	// Flat hexes, by direction (N, NE, SE, S, SW, NW): a column not pushed, and a pushed one
	static final FLAT_DY = [-1, -1, 0, 1, 0, -1];
	static final FLAT_PUSHED_DY = [-1, 0, 1, 1, 1, 0];
	static final FLAT_DX = [0, 1, 1, 0, -1, -1];

	static final SQUARE_NAMES = ["n", "ne", "e", "se", "s", "sw", "w", "nw"];
	static final POINTY_NAMES = ["ne", "e", "se", "sw", "w", "nw"];
	static final FLAT_NAMES = ["n", "ne", "se", "s", "sw", "nw"];

	public function new(kind:TileGridKind, tileWidth:Int, tileHeight:Int, pointy = true, odd = true, ?side:Int, offsetX = 0, offsetY = 0) {
		this.kind = kind;
		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
		this.pointy = pointy;
		this.odd = odd;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		switch kind {
			case Orthogonal:
				this.side = 0;
				columnStep = tileWidth;
				rowStep = tileHeight;
				slant = 0;
				neighbourCount = 8;
			case Isometric:
				this.side = 0;
				columnStep = tileWidth / 2;
				rowStep = tileHeight / 2;
				slant = 0;
				neighbourCount = 8;
			case Hex:
				final across = pointy ? tileHeight : tileWidth;
				final s:Int = side != null ? side : Std.int(across / 2);
				this.side = s;
				if (pointy) {
					columnStep = tileWidth;
					rowStep = (tileHeight + s) / 2;
				} else {
					columnStep = (tileWidth + s) / 2;
					rowStep = tileHeight;
				}
				slant = (across - s) / 2;
				neighbourCount = 6;
		}
	}

	/** The square grid of a cell of `size`, as `tileSize: n` says it. **/
	public static function square(size:Int):TileGrid {
		return new TileGrid(Orthogonal, size, size);
	}

	/** The grid a tileset says (`grid:`, else its `tileSize` square), with its `tileOffset`. **/
	public static function of(grid:Null<TilesetGridDef>, tileSize:Int, ?offsetX:Null<Int>, ?offsetY:Null<Int>):TileGrid {
		final ox = offsetX != null ? offsetX : 0;
		final oy = offsetY != null ? offsetY : 0;
		if (grid == null)
			return new TileGrid(Orthogonal, tileSize, tileSize, true, true, null, ox, oy);
		return switch grid.kind {
			case "isometric": new TileGrid(Isometric, grid.width, grid.height, true, true, null, ox, oy);
			case "hex": new TileGrid(Hex, grid.width, grid.height, grid.pointy != false, grid.odd != false, grid.side, ox, oy);
			default: new TileGrid(Orthogonal, grid.width, grid.height, true, true, null, ox, oy);
		};
	}

	/** The grid's name, as `grid:` writes it: `orthogonal`, `isometric`, `hex`. **/
	public function kindName():String {
		return switch kind {
			case Orthogonal: "orthogonal";
			case Isometric: "isometric";
			case Hex: "hex";
		};
	}

	/** What the DevBridge says of the grid: as `grid:` writes it, with the steps. **/
	public function describe():Dynamic {
		return switch kind {
			case Hex: {
					kind: "hex",
					width: tileWidth,
					height: tileHeight,
					orientation: pointy ? "pointy" : "flat",
					offset: odd ? "odd" : "even",
					side: side,
					columnStep: columnStep,
					rowStep: rowStep,
					tileOffset: [offsetX, offsetY],
				};
			default: {
					kind: kindName(),
					width: tileWidth,
					height: tileHeight,
					tileOffset: [offsetX, offsetY]
				};
		};
	}

	/** Hex: whether a row (pointy) or a column (flat) is pushed half a cell over. **/
	public inline function pushed(n:Int):Bool {
		return ((n & 1) == 1) == odd;
	}

	// ===================== Cells and pixels =====================

	/** A cell's box's left, in pixels. **/
	public function pixelX(cx:Int, cy:Int):Float {
		return switch kind {
			case Orthogonal: cx * tileWidth;
			case Isometric: (cx - cy - 1) * columnStep;
			case Hex: pointy ? cx * columnStep + (pushed(cy) ? tileWidth / 2 : 0) : cx * columnStep;
		};
	}

	/** A cell's box's top, in pixels. **/
	public function pixelY(cx:Int, cy:Int):Float {
		return switch kind {
			case Orthogonal: cy * tileHeight;
			case Isometric: (cx + cy) * rowStep;
			case Hex: pointy ? cy * rowStep : cy * rowStep + (pushed(cx) ? tileHeight / 2 : 0);
		};
	}

	/** A cell's box's top-left: where its tile is drawn from on the square grid. **/
	public function toPixel(cx:Int, cy:Int):h2d.col.Point {
		return new h2d.col.Point(pixelX(cx, cy), pixelY(cx, cy));
	}

	/** The middle of a cell's box: of its square, diamond or hex. **/
	public function center(cx:Int, cy:Int):h2d.col.Point {
		return new h2d.col.Point(pixelX(cx, cy) + tileWidth / 2, pixelY(cx, cy) + tileHeight / 2);
	}

	/** The cell a point is in (pixels; a point on an edge goes to either cell), into `out` when given. **/
	public function toCell(x:Float, y:Float, ?out:h2d.col.IPoint):h2d.col.IPoint {
		final p = out != null ? out : new h2d.col.IPoint();
		switch kind {
			case Orthogonal:
				p.set(Math.floor(x / tileWidth), Math.floor(y / tileHeight));
			case Isometric:
				final u = x / columnStep;
				final v = y / rowStep;
				p.set(Math.floor((v + u) / 2), Math.floor((v - u) / 2));
			case Hex:
				if (pointy) {
					var row = Math.floor(y / rowStep);
					final inRow = y - row * rowStep;
					var col = Math.floor((x - (pushed(row) ? tileWidth / 2 : 0)) / tileWidth);
					if (inRow < slant) {
						// in the band of corners: this row's top one, or the row above's bottom ones
						final along = x - (pushed(row) ? tileWidth / 2 : 0) - col * tileWidth;
						final half = tileWidth / 2;
						if (inRow < slant * Math.abs(along - half) / half) {
							row--;
							col = Math.floor((x - (pushed(row) ? tileWidth / 2 : 0)) / tileWidth);
						}
					}
					p.set(col, row);
				} else {
					var col = Math.floor(x / columnStep);
					final inColumn = x - col * columnStep;
					var row = Math.floor((y - (pushed(col) ? tileHeight / 2 : 0)) / tileHeight);
					if (inColumn < slant) {
						final along = y - (pushed(col) ? tileHeight / 2 : 0) - row * tileHeight;
						final half = tileHeight / 2;
						if (inColumn < slant * Math.abs(along - half) / half) {
							col--;
							row = Math.floor((y - (pushed(col) ? tileHeight / 2 : 0)) / tileHeight);
						}
					}
					p.set(col, row);
				}
		}
		return p;
	}

	/**
		The pixel box around a rectangle of cells, columns `x0` to `x1` and rows `y0` to `y1`, the ends
		one past the last: around their boxes, not what their frames draw past them. For a chunk's
		culling.
	**/
	public function bounds(x0:Int, y0:Int, x1:Int, y1:Int, ?out:h2d.col.Bounds):h2d.col.Bounds {
		final b = out != null ? out : new h2d.col.Bounds();
		switch kind {
			case Orthogonal:
				b.set(x0 * tileWidth, y0 * tileHeight, (x1 - x0) * tileWidth, (y1 - y0) * tileHeight);
			case Isometric:
				// the corners of the rectangle in cells: top (x0, y0), right (x1, y0), bottom (x1, y1), left (x0, y1)
				final left = (x0 - y1) * columnStep;
				final top = (x0 + y0) * rowStep;
				b.set(left, top, (x1 - y0) * columnStep - left, (x1 + y1) * rowStep - top);
			case Hex:
				if (pointy) {
					final many = y1 - y0 >= 2;
					final minPush = many || !pushed(y0) ? 0 : tileWidth / 2;
					final maxPush = many || pushed(y0) ? tileWidth / 2 : 0;
					final left = x0 * columnStep + minPush;
					final top = y0 * rowStep;
					b.set(left, top, (x1 - 1) * columnStep + tileWidth + maxPush - left, (y1 - 1) * rowStep + tileHeight - top);
				} else {
					final many = x1 - x0 >= 2;
					final minPush = many || !pushed(x0) ? 0 : tileHeight / 2;
					final maxPush = many || pushed(x0) ? tileHeight / 2 : 0;
					final left = x0 * columnStep;
					final top = y0 * rowStep + minPush;
					b.set(left, top, (x1 - 1) * columnStep + tileWidth - left, (y1 - 1) * rowStep + tileHeight + maxPush - top);
				}
		}
		return b;
	}

	// ===================== Frames =====================

	/** Where a frame `frameWidth` wide is drawn from on a cell box's left `boxX`: on its left (square grid), else over its middle; then moved. **/
	public inline function frameLeft(boxX:Float, frameWidth:Float, boxWidth:Float):Float {
		return (kind == Orthogonal ? boxX : boxX + Std.int((boxWidth - frameWidth) / 2)) + offsetX;
	}

	/** Where a frame `frameHeight` high is drawn from on a cell box's top `boxY`: its top (square grid), else standing on its bottom; then moved. **/
	public inline function frameTop(boxY:Float, frameHeight:Float, boxHeight:Float):Float {
		return (kind == Orthogonal ? boxY : boxY + boxHeight - frameHeight) + offsetY;
	}

	/** Where a frame of that size is drawn from on cell (cx, cy): `frameLeft` of its box. **/
	public inline function frameX(cx:Int, cy:Int, frameWidth:Float):Float {
		return frameLeft(pixelX(cx, cy), frameWidth, tileWidth);
	}

	/** Where a frame of that size is drawn from on cell (cx, cy): `frameTop` of its box. **/
	public inline function frameY(cx:Int, cy:Int, frameHeight:Float):Float {
		return frameTop(pixelY(cx, cy), frameHeight, tileHeight);
	}

	/**
		The box of a corner autotile's tile at corner (cx, cy), the top-left corner of cell (cx, cy):
		a cell's box half a cell up and left (on the square grid, half a tile rounded down, as the
		autotile draws it; on the isometric grid, half a cell up). The hex grid has no corner format.
	**/
	public function cornerX(cx:Int, cy:Int):Float {
		return switch kind {
			case Isometric: pixelX(cx, cy);
			default: pixelX(cx, cy) - Std.int(tileWidth / 2);
		};
	}

	public function cornerY(cx:Int, cy:Int):Float {
		return switch kind {
			case Isometric: pixelY(cx, cy) - rowStep;
			default: pixelY(cx, cy) - Std.int(tileHeight / 2);
		};
	}

	// ===================== Neighbours =====================

	/** The column of a cell's neighbour in a direction (numbered as the class says). **/
	public function neighbourX(cx:Int, cy:Int, direction:Int):Int {
		return switch kind {
			case Hex: pointy ? cx + (pushed(cy) ? POINTY_PUSHED_DX[direction] : POINTY_DX[direction]) : cx + FLAT_DX[direction];
			default: cx + SQUARE_DX[direction];
		};
	}

	/** The row of a cell's neighbour in a direction. **/
	public function neighbourY(cx:Int, cy:Int, direction:Int):Int {
		return switch kind {
			case Hex: pointy ? cy + POINTY_DY[direction] : cy + (pushed(cx) ? FLAT_PUSHED_DY[direction] : FLAT_DY[direction]);
			default: cy + SQUARE_DY[direction];
		};
	}

	/** A cell's neighbours, in their directions' order: 8, or 6 on the hex grid. **/
	public function neighbours(cx:Int, cy:Int):Array<h2d.col.IPoint> {
		return [for (d in 0...neighbourCount) new h2d.col.IPoint(neighbourX(cx, cy, d), neighbourY(cx, cy, d))];
	}

	/** A direction's name: n, ne, e, se, s, sw, w, nw (the hex grid's six of them). **/
	public function directionName(direction:Int):String {
		return switch kind {
			case Hex: pointy ? POINTY_NAMES[direction] : FLAT_NAMES[direction];
			default: SQUARE_NAMES[direction];
		};
	}

	/**
		The direction a rise's `toward:` faces, -1 for `down` on the isometric and hex grids (every
		face toward a lower neighbour below, as `below` gives them) and for a name the grid has not.
		On the square grid down, up, left, right; on the isometric one se is E (cx + 1) and sw is S
		(cy + 1), the two faces it shows; on the hex one se, sw and, flat, s.
	**/
	public function towardDirection(toward:String):Int {
		return switch kind {
			case Orthogonal: switch toward {
					case "up": 0;
					case "right": 2;
					case "left": 6;
					default: 4;
				};
			case Isometric: switch toward {
					case "se": 2;
					case "sw": 4;
					default: -1;
				};
			case Hex: switch toward {
					case "se": 2;
					case "sw": pointy ? 3 : 4;
					case "s": pointy ? -1 : 3;
					default: -1;
				};
		};
	}

	/**
		The directions a raised cell shows a face toward, its lower edges on screen: down on the square
		grid; se and sw on the isometric one; se and sw on a pointy hex, se, s and sw on a flat one.
	**/
	public function below():Array<Int> {
		return switch kind {
			case Orthogonal: [4];
			case Isometric: [2, 4];
			case Hex: pointy ? [2, 3] : [2, 3, 4];
		};
	}

	/**
		Which side of a cell's bottom a face below it is on (`direction`, one of `below()`): 1 right of
		it (se), -1 left of it (sw), 0 the bottom itself (a flat hex's s, and the square grid's down).
	**/
	public function faceSide(direction:Int):Int {
		return switch kind {
			case Orthogonal: 0;
			case Isometric: direction == 2 ? 1 : (direction == 4 ? -1 : 0);
			case Hex: direction == 2 ? 1 : ((pointy && direction == 3) || (!pointy && direction == 4) ? -1 : 0);
		};
	}

	/**
		Where a piece `frameWidth` wide drawn on one face of a raised cell is drawn from: against the
		right of the cell's box for a face right of its bottom (se), against its left for one left of it
		(sw), over its middle for the bottom one; then moved. A piece as wide as the cell is where
		`frameX` puts a frame, so a face drawn alone and a whole cell's frame with the other face clear
		both land where they belong.
	**/
	public function faceX(cx:Int, cy:Int, direction:Int, frameWidth:Float):Float {
		return switch faceSide(direction) {
			case 1: pixelX(cx, cy) + tileWidth - frameWidth + offsetX;
			case -1: pixelX(cx, cy) + offsetX;
			default: frameX(cx, cy, frameWidth);
		};
	}

	/** Whether a frame may be drawn turned a quarter (only a square's turn is a square). **/
	public inline function turns():Bool {
		return kind == Orthogonal && tileWidth == tileHeight;
	}
}
