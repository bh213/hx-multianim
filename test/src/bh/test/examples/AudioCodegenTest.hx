package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.TestResourceLoader;

/**
 * The audio blocks beside codegen: a file with `sounds`, `mix` and `music` blocks builds its
 * programmables through `@:manim` as through the builder (the blocks are the builder's and the
 * screen manager's, the codegen leaves them be), and `AudioNames` gives typed names for them.
 */
class AudioCodegenTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/158-audioBlocks/audioBlocks.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testCodegenBuildsAProgrammableBesideTheAudioBlocks():Void {
		final inst:Dynamic = createMp().audioBlocks.create();
		Assert.notNull(inst, "the file parsed at compile time with its three blocks, and the programmable was generated");
		final builder = BuilderTestBase.builderFromFile(FIXTURE);
		final result = builder.buildWithParameters("audioBlocks", []);
		Assert.notNull(result.object, "and the builder builds the same programmable");
		Assert.equals("music.title", result.rootSettings.getStringOrDefault("music", ""), "its settings say its music");
	}

	@Test
	public function testTheBuilderSeesTheFilesBlocks():Void {
		final builder = BuilderTestBase.builderFromFile(FIXTURE);
		Assert.same(["fx"], builder.soundBlockNames());
		Assert.same(["main"], builder.mixBlockNames());
		Assert.same(["music"], builder.musicBlockNames());
		Assert.equals(3, builder.buildSounds("fx").sounds.length);
		Assert.equals(2, builder.buildMix("main").snapshots.length);
		Assert.equals(2, builder.buildMusic("music").tracks.length);
	}

	@Test
	public function testAudioNamesAreTheFilesNamesTyped():Void {
		Assert.equals("fx.hit", AudioBlockNames.FX_HIT);
		Assert.equals("fx.step", AudioBlockNames.FX_STEP, "a sound's variants are one name");
		Assert.equals("surface", AudioBlockNames.PARAM_SURFACE);
		Assert.equals("music", AudioBlockNames.BUS_MUSIC);
		Assert.equals("sfx", AudioBlockNames.BUS_SFX);
		Assert.equals("Music", AudioBlockNames.VCA_MUSIC);
		Assert.equals("Effects", AudioBlockNames.VCA_EFFECTS);
		Assert.equals("paused", AudioBlockNames.SNAPSHOT_PAUSED);
		Assert.equals("dialog", AudioBlockNames.SNAPSHOT_DIALOG);
		Assert.equals("music.title", AudioBlockNames.MUSIC_TITLE);
		Assert.equals("music.play", AudioBlockNames.MUSIC_PLAY);

		// and they are what the service plays by
		final log = new bh.audio.LogBackend();
		final audio = new bh.audio.Audio(log);
		audio.randomFunc = () -> 0.0;
		audio.addBanks(BuilderTestBase.builderFromFile(FIXTURE));
		audio.set(AudioBlockNames.PARAM_SURFACE, "grass");
		audio.play(AudioBlockNames.FX_STEP);
		Assert.equals("sound/step_grass.wav", log.plays()[0].path);
		audio.playMusic(AudioBlockNames.MUSIC_TITLE);
		Assert.equals(AudioBlockNames.MUSIC_TITLE, audio.musicPlaying);
		audio.setVca(AudioBlockNames.VCA_EFFECTS, 0.5);
		Assert.floatEquals(0.5, audio.busState(AudioBlockNames.BUS_SFX).volume);
	}
}

@:build(bh.audio.AudioNames.build("test/examples/158-audioBlocks/audioBlocks.manim"))
private class AudioBlockNames {}
