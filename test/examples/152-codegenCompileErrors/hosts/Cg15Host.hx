// Isolated compile check for the flow-scalar rvToExprInt bug: registering
// this fixture must FAIL to compile until the fix lands (Float into Int
// h2d.Flow fields in the generated class).
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class Cg15Host extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg15-flow.manim", "flowFloat")
	public var flowFloat;

	@:manim("test/examples/152-codegenCompileErrors/cg15-flow.manim", "flowSpacer")
	public var flowSpacer;
}
