package bh.test;

/**
	Two data blocks whose classes count their values' reads (`reads` in their `@:data`), for
	DataReadsTest; MultiProgrammable has the same blocks without it.
**/
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class DataReadsData extends bh.multianim.ProgrammableBuilder {
	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData", "bh.test.reads", reads)
	public var gameData;

	@:data("test/examples/62-dataBlock/dataTables.manim", "cards", "bh.test.reads", reads)
	public var cards;
}
