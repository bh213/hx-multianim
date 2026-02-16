package bh.multianim;

/**
 * Macro-safe replacements for h2d types used in the parser AST.
 * These enums mirror h2d.BlendMode and h2d.Flow.FlowLayout but can
 * be used in macro context where h2d is unavailable.
 */
enum MacroBlendMode {
	MBNone;
	MBAlpha;
	MBAdd;
	MBAlphaAdd;
	MBSoftAdd;
	MBMultiply;
	MBAlphaMultiply;
	MBErase;
	MBScreen;
	MBSub;
	MBMax;
	MBMin;
}

enum MacroFlowLayout {
	MFLHorizontal;
	MFLVertical;
	MFLStack;
}

enum MacroFlowOverflow {
	MFOExpand;
	MFOLimit;
	MFOScroll;
	MFOHidden;
}

#if !macro
class MacroCompatConvert {
	public static function toH2dBlendMode(m:MacroBlendMode):h2d.BlendMode {
		return switch m {
			case MBNone: None;
			case MBAlpha: Alpha;
			case MBAdd: Add;
			case MBAlphaAdd: AlphaAdd;
			case MBSoftAdd: SoftAdd;
			case MBMultiply: Multiply;
			case MBAlphaMultiply: AlphaMultiply;
			case MBErase: Erase;
			case MBScreen: Screen;
			case MBSub: Sub;
			case MBMax: Max;
			case MBMin: Min;
		}
	}

	public static function toH2dFlowLayout(m:MacroFlowLayout):h2d.Flow.FlowLayout {
		return switch m {
			case MFLHorizontal: Horizontal;
			case MFLVertical: Vertical;
			case MFLStack: Stack;
		}
	}

	public static function toH2dFlowOverflow(m:MacroFlowOverflow):h2d.Flow.FlowOverflow {
		return switch m {
			case MFOExpand: Expand;
			case MFOLimit: Limit;
			case MFOScroll: Scroll;
			case MFOHidden: Hidden;
		}
	}
}
#end
