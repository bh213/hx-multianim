package bh.base.filters;



import h3d.Vector4;
import hxd.Pixels;
import hxd.BitmapData;
import h3d.Vector;
using StringTools;
using bh.base.ColorUtils;

class ReplacePaletteShader extends h3d.shader.ScreenShader {
  
  static var SRC = {
    
    @const @param var PALETTE_SIZE:Int;
    @const var TEST_ALPHA:Bool = false;
    @param var SRC_COL:Array<Vec4, PALETTE_SIZE>;
    @param var DST_COL:Array<Vec4, PALETTE_SIZE>;
    @param var texture:Sampler2D;

    // Epsilon-based comparison: half an 8-bit color step (~0.002)
    // Handles float precision differences across DX/GL backends
    function testeq(a:Vec4, b:Vec4):Bool {
      if (TEST_ALPHA) {
        return abs(a.r - b.r) < 2e-3 && abs(a.g - b.g) < 2e-3 &&
               abs(a.b - b.b) < 2e-3 && abs(a.a - b.a) < 2e-3;
      } else {
        return abs(a.r - b.r) < 2e-3 && abs(a.g - b.g) < 2e-3 &&
               abs(a.b - b.b) < 2e-3;
      }
    }
    
    function fragment() {
      var tc = texture.get(calculatedUV.xy);
      pixelColor = tc; // If no match
      for (i in 0...PALETTE_SIZE) {
        if (testeq(tc, SRC_COL[i])) {
          pixelColor = DST_COL[i];
          
          break;
        }
      }
      
    }
    
  }
  
  public function new(source:Array<Int>, replacement:Array<Int>) {
    super();
    if (source.length != replacement.length) throw 'source and destination palette sizes don\'t match ${source.length} != ${replacement.length}';
    PALETTE_SIZE = source.length;
    for (i in 0...PALETTE_SIZE) {
        SRC_COL[i] = new Vector4();
        SRC_COL[i].setColor(source[i].addAlphaIfNotPresent());
        DST_COL[i] = new Vector4();
        DST_COL[i].setColor(replacement[i].addAlphaIfNotPresent());

    }
  }

  public static function createAsPaletteFilter(palette:Palette, sourceRow:Int, replacementRow:Int) {
    return new h2d.filter.Shader(new ReplacePaletteShader(palette.getRow(sourceRow), palette.getRow(replacementRow)));
  }

  public static function createAsColorsFilter(sourceColors:Array<Int>, replacementColors:Array<Int>) {

    return new h2d.filter.Shader(new ReplacePaletteShader(sourceColors, replacementColors));
  }
  
  
 

}
