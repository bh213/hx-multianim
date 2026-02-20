# Heaps BitmapData.fill() JS Bug

## Problem

`BitmapData.fill()` on the JS target ignores `lockImage` and always writes directly to the canvas context (`ctx.fillRect`). When `lock()` has been called, `unlock()` overwrites whatever `fill()` drew by putting the old `lockImage` back.

Other methods like `setPixel()` and `line()` correctly check for `lockImage` and write to it when locked.

## Affected File

`hxd/BitmapData.hx` — `fill()` method (line ~64)

## Current Code (broken)

```haxe
public function fill( x : Int, y : Int, width : Int, height : Int, color : Int ) {
    #if js
    ctx.fillStyle = 'rgba(${(color>>16)&0xFF}, ${(color>>8)&0xFF}, ${color&0xFF}, ${(color>>>24)/255})';
    ctx.fillRect(x, y, width, height);   // always writes to canvas ctx, ignores lockImage
    #else
    // native path — works fine
    #end
}
```

## Fix

Add a `lockImage` check, matching the pattern used by `setPixel()`:

```haxe
public function fill( x : Int, y : Int, width : Int, height : Int, color : Int ) {
    #if js
    if( lockImage != null ) {
        var i = lockImage;
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;
        var a = (color >>> 24) & 0xFF;
        for( dy in 0...height ) {
            for( dx in 0...width ) {
                var px = x + dx;
                var py = y + dy;
                if( px >= 0 && py >= 0 && px < this.width && py < this.height ) {
                    var off = (px + py * i.width) << 2;
                    i.data[off] = r;
                    i.data[off | 1] = g;
                    i.data[off | 2] = b;
                    i.data[off | 3] = a;
                }
            }
        }
    } else {
        ctx.fillStyle = 'rgba(${(color>>16)&0xFF}, ${(color>>8)&0xFF}, ${color&0xFF}, ${(color>>>24)/255})';
        ctx.fillRect(x, y, width, height);
    }
    #else
    // ... native path unchanged
    #end
}
```

## Workaround

In `PixelLine.hx`, `filledRect()` uses `setPixel()` loops instead of `data.fill()` to avoid the bug.
