package bh.test;

/**
	Two data blocks whose classes count their values' reads (`reads` in their `@:data`), for
	DataReadsTest; MultiProgrammable has the same blocks without it. Then a block of two records of
	one shape, merged and counting, and the same block merged without counting in another package.
**/
@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class DataReadsData extends bh.multianim.ProgrammableBuilder {
	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData", "bh.test.reads", reads)
	public var gameData;

	@:data("test/examples/62-dataBlock/dataTables.manim", "cards", "bh.test.reads", reads)
	public var cards;

	// counting first: were the two merged by shape alone, the one after it would take its type
	@:data("test/res/data-reads-merged.manim", "shapes", "bh.test.readsmerged", mergeTypes, reads)
	public var shapes;

	@:data("test/res/data-reads-merged.manim", "shapes", "bh.test.plainmerged", mergeTypes)
	public var shapesPlain;
}
