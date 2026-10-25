// Isolated compile check for a root-level conditional `apply` over a `$param` root property beside a
// conditional element: the hidden-update gate read the root resave's missing field name.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class CgRootApplyHost extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg-root-apply.manim", "rootApply")
	public var rootApply;
}
