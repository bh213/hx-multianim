package bh.base;

import h2d.Bitmap;
import hxd.BitmapData;

class PixelLines extends h2d.Bitmap {
	var data:BitmapData;
	var centerX:Float;
	var centerY:Float;

	public function new(width:Int, height:Int, ?parent:h2d.Object) {
		super(null, parent);
		this.data = new BitmapData(width, height);
		this.width = width;
		this.height = height;
		updateBitmap();
	}

	public function clear() {
		data.lock();
		data.clear(0);
	}

	public function line(x0, y0, x1, y1, colorARGB) {
		data.lock();
		data.line(x0, y0, x1, y1, colorARGB);
	}

	public function rect(x, y, width, height, colorARGB) {
        // TODO: handle overlap in case of alpha?
		data.lock();
		data.line(x, y, x + width, y, colorARGB);
		data.line(x, y, x, y + height, colorARGB);
		data.line(x + width, y, x + width, y + height, colorARGB);
		data.line(x, y + height, x + width, y + height, colorARGB);
	}

	public function filledRect(x:Int, y:Int, width:Int, height:Int, colorARGB) {
		data.lock();
		data.fill(x, y, width, height, colorARGB);
	}

	public function updateBitmap() {
		data.unlock();
		final pixels = data.getPixels();
		var tile = h2d.Tile.fromPixels(pixels);
		tile.setCenterRatio(centerX, centerY);
		this.tile = tile;
	}
}
