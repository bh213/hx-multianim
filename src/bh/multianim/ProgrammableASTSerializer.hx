package bh.multianim;

#if !macro
/**
 * Standalone program that parses a .manim file and outputs the serialized AST.
 * Invoked by ProgrammableCodeGen via subprocess:
 *   haxe <libs> --run bh.multianim.ProgrammableASTSerializer <path.manim> <outputFile>
 */
class ProgrammableASTSerializer {
	static function main() {
		final args = Sys.args();
		if (args.length < 2) {
			Sys.stderr().writeString("Usage: ProgrammableASTSerializer <manim-path> <output-file>\n");
			Sys.exit(1);
			return;
		}

		final manimPath = args[0];
		final outputFile = args[1];

		try {
			final content = sys.io.File.getBytes(manimPath);
			final input = byte.ByteData.ofBytes(content);
			final result = MultiAnimParser.parseFileNoImports(input, manimPath);

			// Serialize the nodes map
			final serializer = new haxe.Serializer();
			serializer.useCache = true;
			serializer.useEnumIndex = false; // Use enum names for robustness
			serializer.serialize(result.nodes);

			sys.io.File.saveContent(outputFile, serializer.toString());
		} catch (e:Dynamic) {
			Sys.stderr().writeString('Error parsing "$manimPath": $e\n');
			Sys.exit(1);
		}
	}
}
#end
