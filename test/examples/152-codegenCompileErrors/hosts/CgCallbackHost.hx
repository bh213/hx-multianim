// Isolated compile check for a callback with a LITERAL default in a numeric
// coordinate: the string-branch lowering feeds a String into the Float
// position argument of the generated class until fixed.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class CgCallbackHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg-callback-coord.manim", "cbCoordDefault")
	public var cbCoordDefault;
}
