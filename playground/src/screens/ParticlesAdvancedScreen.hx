package screens;

import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.paths.*;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;


class ParticlesAdvancedScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var particlesBuilder:Null<MultiAnimBuilder>;
	var currentEffectIndex:Int = 0;
	var particles:Null<bh.base.Particles>;
	var updatable:Null<Updatable>;
	var effectNameText:Null<Updatable>;
	var nextButton:Null<UIStandardMultiAnimButton>;

	static var effectNames:Array<String> = ["fire", "smoke", "sparkles", "vortex", "explosion", "rain", "magicTrail", "confetti", "plasma"];

	public function load() {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		this.particlesBuilder = this.screenManager.buildFromResourceName("particles-advanced.manim", false);

		var ui = MacroUtils.macroBuildWithParameters(particlesBuilder, "ui", [], [
			nextButton => addButtonWithSingleBuilder(builder, "button", "Next Effect"),
		]);

		this.updatable = ui.builderResults.getUpdatable("particles1");
		this.effectNameText = ui.builderResults.getUpdatable("effectName");
		this.nextButton = ui.nextButton;

		// Start with fire effect
		showEffect(0);

		addBuilderResult(ui.builderResults);
	}

	function showEffect(index:Int) {
		currentEffectIndex = index;
		var effectName = effectNames[currentEffectIndex];

		// Create particles for this effect
		particles = particlesBuilder.createParticles(effectName);
		if (particles != null && updatable != null) {
			updatable.setObject(particles);
		} else throw 'could not build particles ${effectName}';

		// Update the effect name text
		if (effectNameText == null) throw 'Invalid effectNameText';

		effectNameText.updateText('Effect: $effectName (${currentEffectIndex + 1}/${effectNames.length})');

	}

	public override function update(dt:Float) {
		super.update(dt);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
				if (source == nextButton) {
					// Cycle to next effect
					var nextIndex = (currentEffectIndex + 1) % effectNames.length;
					showEffect(nextIndex);
				}
			default:
		}
	}
}
