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
	var effectButtons:Array<UIStandardMultiAnimButton> = [];

	public static var effectNames:Array<String> = ["fire", "smoke", "sparkles", "vortex", "explosion", "rain", "magicTrail", "confetti", "plasma"];

	public function load() {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		this.particlesBuilder = this.screenManager.buildFromResourceName("particles-advanced.manim", false);

		var ui = MacroUtils.macroBuildWithParameters(particlesBuilder, "ui", [], [
			fireBtn => addButtonWithSingleBuilder(builder, "button", "Fire"),
			smokeBtn => addButtonWithSingleBuilder(builder, "button", "Smoke"),
			sparklesBtn => addButtonWithSingleBuilder(builder, "button", "Sparkles"),
			vortexBtn => addButtonWithSingleBuilder(builder, "button", "Vortex"),
			explosionBtn => addButtonWithSingleBuilder(builder, "button", "Explosion"),
			rainBtn => addButtonWithSingleBuilder(builder, "button", "Rain"),
			magicTrailBtn => addButtonWithSingleBuilder(builder, "button", "Magic"),
			confettiBtn => addButtonWithSingleBuilder(builder, "button", "Confetti"),
			plasmaBtn => addButtonWithSingleBuilder(builder, "button", "Plasma"),
		]);

		this.updatable = ui.builderResults.getUpdatable("particles1");
		this.effectNameText = ui.builderResults.getUpdatable("effectName");

		// Store buttons for event handling
		effectButtons = [
			ui.fireBtn,
			ui.smokeBtn,
			ui.sparklesBtn,
			ui.vortexBtn,
			ui.explosionBtn,
			ui.rainBtn,
			ui.magicTrailBtn,
			ui.confettiBtn,
			ui.plasmaBtn
		];

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

		effectNameText.updateText('Effect: $effectName');

		// Update button states - disable the selected one
		for (i in 0...effectButtons.length) {
			effectButtons[i].disabled = (i == currentEffectIndex);
		}
	}

	public override function update(dt:Float) {
		super.update(dt);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
				// Check which button was clicked
				for (i in 0...effectButtons.length) {
					if (source == effectButtons[i]) {
						showEffect(i);
						return;
					}
				}
			default:
		}
	}
}
