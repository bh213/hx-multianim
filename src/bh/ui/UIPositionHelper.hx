package bh.ui;

import bh.ui.UITooltipHelper.TooltipPosition;

@:nullSafety
class UIPositionHelper {
	/** Position `target` relative to `anchor` using the given side and pixel offset. */
	public static function position(target:h2d.Object, anchor:h2d.Object, position:TooltipPosition, offset:Int):Void {
		final anchorBounds = anchor.getBounds();
		final targetBounds = target.getSize();

		switch position {
			case Above:
				target.x = anchorBounds.x + (anchorBounds.width - targetBounds.width) / 2;
				target.y = anchorBounds.y - targetBounds.height - offset;
			case Below:
				target.x = anchorBounds.x + (anchorBounds.width - targetBounds.width) / 2;
				target.y = anchorBounds.y + anchorBounds.height + offset;
			case Left:
				target.x = anchorBounds.x - targetBounds.width - offset;
				target.y = anchorBounds.y + (anchorBounds.height - targetBounds.height) / 2;
			case Right:
				target.x = anchorBounds.x + anchorBounds.width + offset;
				target.y = anchorBounds.y + (anchorBounds.height - targetBounds.height) / 2;
		}
	}
}
