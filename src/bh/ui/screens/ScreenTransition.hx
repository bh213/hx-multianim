package bh.ui.screens;

import bh.multianim.MultiAnimParser.EasingType;
import bh.base.TweenManager;

enum ScreenTransition {
	None;
	Fade(duration:Float, ?easing:EasingType);
	SlideLeft(duration:Float, ?easing:EasingType);
	SlideRight(duration:Float, ?easing:EasingType);
	SlideUp(duration:Float, ?easing:EasingType);
	SlideDown(duration:Float, ?easing:EasingType);
	Custom(fn:(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object, onComplete:Void -> Void) -> Void);
}
