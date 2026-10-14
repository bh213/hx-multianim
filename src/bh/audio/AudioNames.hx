package bh.audio;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import bh.multianim.MacroManimParser;
import bh.multianim.MultiAnimParser.MultiAnimResult;
#end

/**
	Typed names for a file's sounds, tracks, buses, VCAs, snapshots and parameters, so a name
	misspelt in code does not compile:

	```haxe
	@:build(bh.audio.AudioNames.build("res/audio.manim"))
	class Sfx {}

	audio.play(Sfx.FX_HIT);            // "fx.hit"
	audio.playMusic(Sfx.MUSIC_TITLE);  // "music.title"
	audio.setVca(Sfx.VCA_MUSIC, 0.5);  // "Music"
	audio.snapshot(Sfx.SNAPSHOT_DIALOG, true);
	audio.set(Sfx.PARAM_SURFACE, "grass");
	```

	A constant per name: `<BLOCK>_<SOUND>` and `<BLOCK>_<TRACK>` hold the full name, `BUS_<name>`,
	`VCA_<name>`, `SNAPSHOT_<name>` and `PARAM_<name>` the bare one; upper case, anything that is
	not a letter or a digit an underscore. The file is read at compile time and the class is built
	again when it changes.
**/
class AudioNames {
	#if macro
	public static function build(manimPath:String):Array<Field> {
		final pos = Context.currentPos();
		final fields = Context.getBuildFields();
		final content = try sys.io.File.getContent(manimPath) catch (e:Dynamic) {
			Context.fatalError('AudioNames: could not read "$manimPath": $e', pos);
			return fields;
		};
		final result:MultiAnimResult = try MacroManimParser.parseFile(content, manimPath) catch (e:Dynamic) {
			Context.fatalError('AudioNames: parse error in "$manimPath": $e', pos);
			return fields;
		};
		Context.registerModuleDependency(Context.getLocalModule(), manimPath);

		final taken = new Map<String, String>();
		function add(prefix:String, name:String, value:String):Void {
			final fieldName = constantName(prefix, name);
			final was = taken.get(fieldName);
			if (was != null) {
				if (was != value)
					Context.fatalError('AudioNames: "$value" and "$was" would both be $fieldName in "$manimPath"', pos);
				return;
			}
			taken.set(fieldName, value);
			fields.push({
				name: fieldName,
				access: [APublic, AStatic, AInline, AFinal],
				kind: FVar(macro :String, macro $v{value}),
				pos: pos,
				doc: value,
			});
		}
		for (blockName => node in result.nodes) {
			switch node.type {
				case SOUNDS(def):
					for (s in def.sounds)
						add(blockName, s.name, '$blockName.${s.name}');
					for (p in def.params)
						add("PARAM", p.name, p.name);
				case MUSIC(def):
					for (t in def.tracks)
						add(blockName, t.name, '$blockName.${t.name}');
				case MIX(def):
					for (b in def.buses)
						add("BUS", b.name, b.name);
					for (v in def.vcas)
						add("VCA", v.name, v.name);
					for (s in def.snapshots)
						add("SNAPSHOT", s.name, s.name);
				default:
			}
		}
		return fields;
	}

	/** `fx` + `hit_1` is `FX_HIT_1`; a name that would start with a digit gets an underscore first. */
	static function constantName(prefix:String, name:String):String {
		final out = new StringBuf();
		for (part in [prefix, name]) {
			if (out.length > 0)
				out.add("_");
			for (i in 0...part.length) {
				final c = part.charCodeAt(i);
				final isAlnum = (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code);
				out.add(isAlnum ? part.charAt(i).toUpperCase() : "_");
			}
		}
		final s = out.toString();
		return (s.charCodeAt(0) >= '0'.code && s.charCodeAt(0) <= '9'.code) ? "_" + s : s;
	}
	#end
}
