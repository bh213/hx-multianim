package bh.base;
using StringTools;

/** Detach object from parent without triggering onRemove().
 *  Heaps' onRemove() cascade destroys h2d.Graphics content,
 *  so we must bypass it when reparenting live scene objects.
 *  After safeDetach, the next addChild() restores allocated=true. */
@:access(h2d.Object.allocated)
function safeDetach(obj:h2d.Object):Void {
    if (obj.parent != null) {
        obj.allocated = false;
        obj.parent.removeChild(obj);
    }
}

/** Pixel-perfect solid-color tile. Color is strict-D 0xAARRGGBB — top byte is alpha.
 *  Top-byte=0 is treated as opaque (matches Heaps' Tile.fromColor default, keeps
 *  bare 0xRRGGBB callers working). For fully transparent, use Heaps' Tile.fromColor directly.
 *  Backed by a shared 1×1 GPU texture stretched to (w,h). */
function solidTile(color:Int, width:Int, height:Int):h2d.Tile {
    final top = color >>> 24;
    final alpha = top == 0 ? 1.0 : (top & 0xFF) / 255.0;
    return h2d.Tile.fromColor(color & 0xFFFFFF, width, height, alpha);
}

/** The points of a rounded rectangle's outline, x then y, round from the top side's right end: the
 *  same corners as Heaps' `drawRoundedRect` (so it fits a filled one), no point twice in a row and
 *  the last not the first again. What `strokeRoundedRect` draws. */
function roundedRectOutline(x:Float, y:Float, w:Float, h:Float, radius:Float, nsegments = 0):Array<Float> {
    var n = nsegments == 0 ? Math.ceil(Math.abs(radius * hxd.Math.degToRad(90) / 4)) : nsegments;
    if (n < 3) n = 3;
    final step = hxd.Math.degToRad(90) / (n - 1);
    final out:Array<Float> = [];
    inline function corner(cx:Float, cy:Float, start:Float) {
        for (i in 0...n) {
            final a = hxd.Math.degToRad(start) + i * step;
            final px = cx + Math.cos(a) * radius, py = cy + Math.sin(a) * radius;
            final at = out.length;
            if (at == 0 || Math.abs(px - out[at - 2]) > 1e-9 || Math.abs(py - out[at - 1]) > 1e-9) {
                out.push(px);
                out.push(py);
            }
        }
    }
    corner(x + w - radius, y + radius, 270);
    corner(x + w - radius, y + h - radius, 0);
    corner(x + radius, y + h - radius, 90);
    corner(x + radius, y + radius, 180);
    final last = out.length;
    if (last > 2 && Math.abs(out[last - 2] - out[0]) <= 1e-9 && Math.abs(out[last - 1] - out[1]) <= 1e-9) out.resize(last - 2);
    return out;
}

/** A rounded rectangle's outline, in the line style set on `g`. Heaps' `drawRoundedRect` gives each
 *  straight side's last point again as its corner's first, and a line of no length leaves the sides
 *  undrawn in WebGL: an outline showed only its four corners. Drawn from `roundedRectOutline`, the
 *  path closed where it began. */
function strokeRoundedRect(g:h2d.Graphics, x:Float, y:Float, w:Float, h:Float, radius:Float, nsegments = 0):Void {
    if (radius <= 0) {
        g.drawRect(x, y, w, h);
        return;
    }
    final p = roundedRectOutline(x, y, w, h, radius, nsegments);
    g.moveTo(p[0], p[1]);
    var i = 2;
    while (i < p.length) {
        g.lineTo(p[i], p[i + 1]);
        i += 2;
    }
    g.lineTo(p[0], p[1]);
}

/** Solid-color bitmap. Color is strict-D 0xAARRGGBB — top byte is alpha. */
function solidBitmap(color:Int, width:Int, height:Int, ?parent:h2d.Object):h2d.Bitmap {
    return new h2d.Bitmap(solidTile(color, width, height), parent);
}

/** Cross-in-a-box placeholder tile: rect border + 4 diagonals, repeated per
 *  thickness step. The same drawing the runtime builder uses for
 *  generated(cross(...)) — shared so codegen output renders identically. */
function crossTile(color:Int, width:Int, height:Int, thickness:Int):h2d.Tile {
    final pl = new bh.base.PixelLine.PixelLines(width, height);
    for (t in 0...thickness) {
        pl.rect(t, t, width - 1 - t * 2, height - 1 - t * 2, color);
        pl.line(t, 0, width - 1, height - 1 - t, color);
        pl.line(0, t, width - 1 - t, height - 1, color);
        pl.line(t, height - 1, width - 1, t, color);
        pl.line(0, height - 1 - t, width - 1 - t, 0, color);
    }
    pl.updateBitmap();
    return pl.tile;
}

private function displayH2dObjectNode(sb:StringBuf, obj:h2d.Object, indent:Int) {
    for (i in 0...indent*3) sb.add('-');
    sb.add(Std.string(obj));
    sb.add('\n');
    for (index in 0...obj.numChildren) {
        displayH2dObjectNode(sb, obj.getChildAt(index), indent + 1);
    }
}

function traceH2dObjectTreeString(obj:h2d.Object) {
    trace("\n" + getH2dObjectTreeString(obj));
}

function getH2dObjectTreeString(obj:h2d.Object):String {
    var sb = new StringBuf();
    displayH2dObjectNode(sb, obj, 0);
    return sb.toString();
}
