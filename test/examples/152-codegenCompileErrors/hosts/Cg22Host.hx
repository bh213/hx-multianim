// Isolated compile check for .offset() around a runtime hex coordinate: the
// generated class references a never-synthesized _hexLayout field until fixed.
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class Cg22Host extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/152-codegenCompileErrors/cg22-hexoffset.manim", "hexOff")
	public var hexOff;
}
