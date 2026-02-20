# Heaps BitmapData.fill() JS Bug — RESOLVED

## Problem

`BitmapData.fill()` on the JS target ignores `lockImage` and always writes directly to the canvas context (`ctx.fillRect`). When `lock()` has been called, `unlock()` overwrites whatever `fill()` drew by putting the old `lockImage` back.

## Resolution

Bug fixed upstream in Heaps. `PixelLine.filledRect()` now uses `data.fill()` directly again.

`updateBitmap()` reordered to call `data.getPixels()` before `data.unlock()` as an extra safety measure — ensures pixel data is captured before the canvas state is restored.
