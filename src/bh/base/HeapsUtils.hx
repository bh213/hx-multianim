package bh.base;
using StringTools;

private function displaH2dObjectNode(sb:StringBuf, obj:h2d.Object, indent:Int) {
    for (i in 0...indent*3) sb.add('-');
    sb.add(Std.string(obj));
    sb.add('\n');
    for (index in 0...obj.numChildren) {
        displaH2dObjectNode(sb, obj.getChildAt(index), indent + 1);
    }
}

function traceH2dObjectTreeString(obj:h2d.Object) {
    trace("\n" + getH2dObjectTreeString(obj));
}

function getH2dObjectTreeString(obj:h2d.Object):String {
    var sb = new StringBuf();
    displaH2dObjectNode(sb, obj, 0);
    return sb.toString();
}
