package screens;

import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.UIMultiAnimRadioButtons;
import bh.ui.*;
import bh.ui.screens.UIScreen;

class ParticlesAdvancedScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var particlesBuilder:Null<MultiAnimBuilder>;
	var currentEffectIndex:Int = 0;
	var updatable:Null<Updatable>;
	var effectNameText:Null<Updatable>;
	var speedText:Null<Updatable>;
	var sizeText:Null<Updatable>;
	var gravityText:Null<Updatable>;
	var fadeOutText:Null<Updatable>;

	// Current control state
	var speedPercent:Int = 100;
	var sizePercent:Int = 100;
	var gravityPercent:Int = 100;
	var fadeOutPercent:Int = 100;
	var loopEnabled:Bool = true;
	var rotateAutoEnabled:Bool = false;
	var relativeEnabled:Bool = true;
	var blendModeIndex:Int = 0; // 0=Add, 1=Alpha
	var countMultiplier:Float = 1.0;

	public static var effectNames:Array<String> = [
		"fire", "smoke", "sparkles", "vortex", "explosion",
		"rain", "magicTrail", "confetti", "plasma"
	];

	public function load() {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		this.particlesBuilder = this.screenManager.buildFromResourceName("particles-advanced.manim", false);

		final effectItems:Array<UIElementListItem> = [for (effectName in effectNames) {name: effectName}];
		final blendModes:Array<UIElementListItem> = [{name: "Add"}, {name: "Alpha"}];
		final countOptions:Array<UIElementListItem> = [{name: "Low"}, {name: "Normal"}, {name: "High"}, {name: "Max"}];

		var ui = MacroUtils.macroBuildWithParameters(particlesBuilder, "ui", [], [
			effectDropdown => addDropdownWithSingleBuilder(builder, "dropdown", "list-panel", "list-item-120", "scrollbar", "scrollbar", effectItems, 0),
			speedSlider => addSlider(builder, 50),
			sizeSlider => addSlider(builder, 50),
			gravitySlider => addSlider(builder, 50),
			fadeOutSlider => addSlider(builder, 50),
			loopCheckbox => addCheckbox(builder, true),
			rotateCheckbox => addCheckbox(builder, false),
			relativeCheckbox => addCheckbox(builder, true),
			blendRadio => addRadio(builder, blendModes, false, 0),
			countRadio => addRadio(builder, countOptions, false, 1),
			restartButton => addButtonWithSingleBuilder(builder, "button", "Restart"),
		]);

		this.updatable = ui.builderResults.getUpdatable("particles1");
		this.effectNameText = ui.builderResults.getUpdatable("effectName");
		this.speedText = ui.builderResults.getUpdatable("speedVal");
		this.sizeText = ui.builderResults.getUpdatable("sizeVal");
		this.gravityText = ui.builderResults.getUpdatable("gravityVal");
		this.fadeOutText = ui.builderResults.getUpdatable("fadeOutVal");

		// Effect dropdown
		ui.effectDropdown.onItemChanged = (newIndex, items) -> {
			currentEffectIndex = newIndex;
			showEffect();
		};

		// Speed slider: 0-100 maps to 0%-200%
		ui.speedSlider.onChange = (value, wrapper) -> {
			speedPercent = value * 2;
			if (speedText != null) speedText.updateText('${speedPercent}%');
			showEffect();
		};

		// Size slider: 0-100 maps to 0%-200%
		ui.sizeSlider.onChange = (value, wrapper) -> {
			sizePercent = value * 2;
			if (sizeText != null) sizeText.updateText('${sizePercent}%');
			showEffect();
		};

		// Gravity slider: 0-100 maps to 0%-200%
		ui.gravitySlider.onChange = (value, wrapper) -> {
			gravityPercent = value * 2;
			if (gravityText != null) gravityText.updateText('${gravityPercent}%');
			showEffect();
		};

		// FadeOut slider: 0-100 maps to 0.0-1.0
		ui.fadeOutSlider.onChange = (value, wrapper) -> {
			fadeOutPercent = value;
			if (fadeOutText != null) fadeOutText.updateText('${value}%');
			showEffect();
		};

		// Loop checkbox
		ui.loopCheckbox.onToggle = (checked) -> {
			loopEnabled = checked;
			showEffect();
		};

		// Rotate Auto checkbox
		ui.rotateCheckbox.onToggle = (checked) -> {
			rotateAutoEnabled = checked;
			showEffect();
		};

		// Relative checkbox
		ui.relativeCheckbox.onToggle = (checked) -> {
			relativeEnabled = checked;
			showEffect();
		};

		// Blend mode radio (Add / Alpha)
		ui.blendRadio.onItemChanged = (newIndex, items) -> {
			blendModeIndex = newIndex;
			showEffect();
		};

		// Count radio
		ui.countRadio.onItemChanged = (newIndex, items) -> {
			countMultiplier = switch newIndex {
				case 0: 0.25;
				case 1: 1.0;
				case 2: 2.0;
				case 3: 4.0;
				default: 1.0;
			};
			showEffect();
		};

		// Restart button
		ui.restartButton.onClick = () -> {
			showEffect();
		};

		showEffect();
		addBuilderResult(ui.builderResults);
	}

	function showEffect() {
		var effectName = effectNames[currentEffectIndex];
		if (effectNameText != null) effectNameText.updateText('Effect: $effectName');

		var particles = particlesBuilder.createParticles(effectName);
		if (particles == null || updatable == null) throw 'could not build particles $effectName';

		particles.onEnd = () -> {};

		// Get the single group and apply control overrides before it starts
		var it = particles.getGroups();
		if (it.hasNext()) {
			var group = it.next();
			var dg:Dynamic = group;

			dg.speed = group.speed * speedPercent / 100.0;
			dg.size = group.size * sizePercent / 100.0;
			dg.gravity = group.gravity * gravityPercent / 100.0;
			dg.fadeOut = group.fadeOut * fadeOutPercent / 100.0;
			dg.nparts = Std.int(group.nparts * countMultiplier);
			if (group.nparts < 1) dg.nparts = 1;
			dg.emitLoop = loopEnabled;
			group.rotAuto = rotateAutoEnabled;
			dg.isRelative = relativeEnabled;
			group.blendMode = blendModeIndex == 0 ? h2d.BlendMode.Add : h2d.BlendMode.Alpha;
		}

		updatable.setObject(particles);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {}
}
