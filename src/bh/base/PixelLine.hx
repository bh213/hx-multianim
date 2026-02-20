package bh.base;

import h2d.Bitmap;
import hxd.BitmapData;

class PixelLines extends h2d.Bitmap {
	public var data:BitmapData;
	var centerX:Float = 0;
	var centerY:Float = 0;

	public function new(width:Int, height:Int, ?parent:h2d.Object) {
		super(null, parent);
		this.data = new BitmapData(width, height);
		this.width = width;
		this.height = height;
	}

	public function clear() {
		// clear before lock so the locked ImageData captures the cleared state
		data.clear(0);
		data.lock();
	}

	public function line(x0:Int, y0:Int, x1:Int, y1:Int, colorARGB:Int) {
		data.lock();
		data.line(x0, y0, x1, y1, colorARGB);
	}

	public function rect(x:Int, y:Int, width:Int, height:Int, colorARGB:Int) {
        // TODO: handle overlap in case of alpha?
		data.lock();
		data.line(x, y, x + width - 1, y, colorARGB);
		data.line(x, y, x, y + height - 1, colorARGB);
		data.line(x + width - 1, y, x + width - 1, y + height - 1, colorARGB);
		data.line(x, y + height - 1, x + width - 1, y + height - 1, colorARGB);
	}

	public function filledRect(x:Int, y:Int, width:Int, height:Int, colorARGB:Int) {
		data.lock();
		trace('${x}, ${y}, ${width}, ${height}');
		data.fill(x, y, width, height, colorARGB);
	}

	public function pixel(x:Int, y:Int, colorARGB:Int) {
		data.lock();
		data.setPixel(x, y, colorARGB);
	}

	public function updateBitmap() {
		data.unlock();
		final pixels = data.getPixels();
		var tile = h2d.Tile.fromPixels(pixels);
		tile.setCenterRatio(centerX, centerY);
		this.tile = tile;
	}
}
