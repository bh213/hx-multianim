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

/** Solid-color bitmap. Color is strict-D 0xAARRGGBB — top byte is alpha. */
function solidBitmap(color:Int, width:Int, height:Int, ?parent:h2d.Object):h2d.Bitmap {
    return new h2d.Bitmap(solidTile(color, width, height), parent);
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
