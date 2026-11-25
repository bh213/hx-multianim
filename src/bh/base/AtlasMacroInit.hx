package bh.base;

class AtlasMacroInit {
	public static function init() {
		hxd.res.Config.extensions.set("atlas2", "bh.base.Atlas2");
		#if macro
		// fragment shaders at highp where the GPU has it (a page's mediump may be 16 bits)
		HighPrecisionShaders.init();
		// a mask inside a filter clips where it is drawn (Heaps maps its zone through the screen)
		FilterRenderZone.init();
		#end
	}
}
