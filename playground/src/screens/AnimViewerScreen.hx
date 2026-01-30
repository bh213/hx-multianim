package screens;

import bh.base.MacroUtils;
import bh.multianim.layouts.MultiAnimLayouts;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox.UIStandardMultiCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.screens.UIScreen;
import bh.stateanim.AnimParser;
import bh.stateanim.AnimParser.AnimationStateSelector;
import bh.stateanim.AnimationSM;
import h2d.Graphics;
import hxd.Key;
#if js
import js.Browser;
#end

using StringTools;

/**
 * Screen that displays all animations from a .anim file in a grid layout.
 * Each animation is shown with its name label below it.
 */
@:access(bh.stateanim.AnimationSM)
class AnimViewerScreen extends UIScreenBase {
	var filename = "marine.anim";
	var spriteScale = 2.0;
	var speed = 1.0;

	var animInstances:Array<AnimationSM> = [];
	var animContainers:Array<h2d.Object> = [];
	var stdBuilder:Null<MultiAnimBuilder>;
	var viewerBuilder:Null<MultiAnimBuilder>;
	var viewerLayouts:Null<MultiAnimLayouts>;

	var speedSlider:Null<UIStandardMultiAnimSlider>;
	var scaleSlider:Null<UIStandardMultiAnimSlider>;
	var statesCombos:Map<String, {dropdown:UIStandardMultiAnimDropdown, values:Array<String>}> = [];
	var animSMStateSelector:AnimationStateSelector = [];

	public function load() {
		this.stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);
		this.viewerBuilder = this.screenManager.buildFromResourceName("animviewer.manim", false);
		this.viewerLayouts = viewerBuilder.getLayouts();

		// Check if there's a current file selected in the JS playground loader
		#if js
		try {
			var currentFile:Null<String> = untyped js.Browser.window.playgroundLoader?.currentFile;
			if (currentFile != null && StringTools.endsWith(currentFile, ".anim")) {
				filename = currentFile;
			}
		} catch (e) {
			// Ignore errors, use default filename
		}
		#end

		// Build UI
		var loaderButton = UIStandardMultiAnimButton.create(this.stdBuilder, "button", 'Load');
		loaderButton.onClick = () -> {
			var files = [
				"arrows.anim",
				"dice.anim",
				"marine.anim",
				"shield.anim",
				"turret.anim"
			];
			var dialog = new screens.FileDialogScreen(screenManager, files);
			dialog.load();
			this.screenManager.modalDialog(dialog, this, "fileChange");
		};

		var res = MacroUtils.macroBuildWithParameters(viewerBuilder, "ui", [], [
			load => loaderButton,
			speedSlider => addSlider(stdBuilder, 50),
			scaleSlider => addSlider(stdBuilder, 40),
		]);

		var ui = res.builderResults;
		addBuilderResult(ui);
		this.speedSlider = res.speedSlider;
		this.scaleSlider = res.scaleSlider;

		reloadAnimFile(true);
	}

	function reloadAnimFile(reinit = true) {
		// Clear existing animations
		for (anim in animInstances) {
			anim.remove();
		}
		animInstances = [];

		// Clear containers
		for (container in animContainers) {
			container.remove();
		}
		animContainers = [];

		for (key => value in statesCombos) {
			removeElement(value.dropdown);
		}
		statesCombos = [];

		try {
			var parsed = screenManager.loader.loadAnimParser(filename);

			// Initialize state selector with first values
			if (reinit) {
				animSMStateSelector = [];
				for (k => v in parsed.definedStates) {
					animSMStateSelector.set(k, v[0]);
				}
			}

			// Create state dropdowns
			final statesIterator = viewerLayouts.getIterator("statesDropdowns");
			for (key => value in parsed.definedStates) {
				final currentIndex = value.indexOf(animSMStateSelector.get(key));
				var all = parsed.definedStates[key];
				var opts = Lambda.map(all, x -> ({name: x}:UIElementListItem));
				var el = addElementWithIterator(
					UIStandardMultiAnimDropdown.create(
						stdBuilder.createElementBuilder("dropdown"),
						stdBuilder.createElementBuilder("list-panel"),
						stdBuilder.createElementBuilder("list-item-120"),
						stdBuilder.createElementBuilder("scrollbar"),
						"scrollbar",
						opts,
						currentIndex
					),
					statesIterator
				);
				statesCombos.set(key, {dropdown: el, values: all});
			}

			// Create an AnimationSM for the file first to get animation names
			var tempAnimSM = parsed.createAnimSM(animSMStateSelector);
			var animNames:Array<String> = [];
			for (name => _ in tempAnimSM.animationStates) {
				animNames.push(name);
			}
			tempAnimSM.remove();

			// Sort animation names alphabetically
			animNames.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));

			// Create grid of animations
			final gridIterator = viewerLayouts.getIterator("animGrid");

			for (animName in animNames) {
				// Create a new AnimationSM instance for this animation
				var animSM = parsed.createAnimSM(animSMStateSelector);
				animSM.setScale(spriteScale);
				animSM.speed = speed;

				// Play this specific animation
				if (animSM.animationStates.exists(animName)) {
					animSM.play(animName);
				}

				animInstances.push(animSM);

				// Add to grid with label
				var container = new h2d.Object();
				container.addChild(animSM);

				// Add label below the animation
				var label = new h2d.Text(bh.base.FontManager.getFontByName("m6x11"));
				label.text = animName;
				label.textColor = 0xFFFFFF;
				label.textAlign = Center;
				label.y = 50; // Position below sprite
				container.addChild(label);

				animContainers.push(container);
				addObjectToLayerWithIterator(container, gridIterator);
			}

		} catch (e) {
			trace('Error loading anim file: ${e}');
		}
	}

	override function update(dt:Float) {
		super.update(dt);

		// Update all animation instances
		for (anim in animInstances) {
			anim.speed = speed;
		}
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIChangeValue(value):
				if (source == this.speedSlider) {
					this.speed = (value / 50.0) * 2.0;
				} else if (source == this.scaleSlider) {
					this.spriteScale = 1.0 + (value / 20.0);
					for (anim in animInstances) {
						anim.setScale(spriteScale);
					}
				}
			case UIChangeItem(index, items):
				for (key => value in statesCombos) {
					if (value.dropdown == source) {
						animSMStateSelector[key] = statesCombos.get(key).values[index];
						reloadAnimFile(false);
					}
				}
			case UIOnControllerEvent(result):
				switch result {
					case OnDialogResult(dialogName, result):
						if (dialogName == "fileChange" && result != false && result != null) {
							filename = '${result}';
							reloadAnimFile(true);
						}
					default:
				}
			default:
		}
	}
}
