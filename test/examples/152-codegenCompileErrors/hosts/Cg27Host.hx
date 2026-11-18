// Isolated compile check for untyped `key => true` in interactive metadata and element
// settings: the generated class lowered the inferred bool as RSVBool("true" != 0).
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class Cg27Host extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg27-untyped-bool.manim", "untypedBool")
	public var untypedBool;
}
