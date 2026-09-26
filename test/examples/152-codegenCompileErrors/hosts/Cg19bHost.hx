// Isolated compile check for bitmap($tileParam) in a param-dependent repeat:
// the generated class references an undeclared _rt_tiles local until fixed.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class Cg19bHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg19b-tile.manim", "tileParamRepeat")
	public var tileParamRepeat;
}
