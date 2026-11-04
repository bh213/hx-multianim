// Isolated compile check for parameters named `stale` and `applying`: their backing fields took the
// names of the generated class's own fields.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class CgParamNamesHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg-param-names.manim", "paramNames")
	public var paramNames;
}
