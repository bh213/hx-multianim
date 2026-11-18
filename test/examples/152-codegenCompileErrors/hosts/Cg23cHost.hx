// Isolated compile check for $ctx.random with a float arg: the generated
// class calls Std.random(Float) until the args go through rvToExprInt.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class Cg23cHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg23c-random.manim", "rnd")
	public var rnd;
}
