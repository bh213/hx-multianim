// Control for the isolated compile checks: static/int-safe shapes of the same
// elements. Must ALWAYS compile — proves the harness is sound.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class CgControlHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/control.manim", "ctrl")
	public var ctrl;
}
