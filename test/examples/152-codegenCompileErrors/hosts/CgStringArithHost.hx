// Isolated compile check for arithmetic in a string context with a number written
// out (`text(dd, $a * 2, ...)`): the generated class did not compile (`_a * "2"`)
// until such a number was read as one.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class CgStringArithHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg-string-arith.manim", "stringArith")
	public var stringArith;
}
