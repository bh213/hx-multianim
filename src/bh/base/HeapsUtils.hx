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
