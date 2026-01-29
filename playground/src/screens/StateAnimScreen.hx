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
import bh.stateanim.AnimationSM.AnimationFrameState;
import bh.stateanim.AnimationSM.animationFrameStateToString;
import h2d.Graphics;
import hxd.Key;


using StringTools;

enum abstract Colors(Int) {
	var white = 0xFFFFFFFF;
	var red = 0xFFFF0000;
	var green = 0xFF00FF00;
	var blue = 0xFF0000FF;
}

enum PointsElement {
	CROSS(x:Float, y:Float, color:Colors, time:Float);
	CIRCLE(x:Float, y:Float, radius:Int, color:Colors, time:Float);
}

// @:nullSafety

@:access(bh.stateanim.AnimationSM)
class StateAnimScreen extends UIScreenBase {
	final groupNameAnimStates = "animStatesGroup";
	var time = 0.0;
	var blink = 0.0;
	var points:Array<PointsElement> = [];
	var animSM:Null<AnimationSM>;
	var animSMStateSelector:AnimationStateSelector = [];
	var pointGraphics:Null<h2d.Graphics>;

	var spriteScale = 3.0;
	var speed = 1.0;
	var ctrl = false;
	var showBounds = true;

	var builder:Null<MultiAnimBuilder>;
	var stateAnimBuilder:Null<MultiAnimBuilder> = null;
	var stateAnimLayouts:Null<MultiAnimLayouts> = null;

	var pausedCheckbox:Null<UIStandardMultiCheckbox>;
	var showBoundsCheckbox:Null<UIStandardMultiCheckbox>;
	var animStatesCheckbox:Null<UIStandardMultiCheckbox>;
	var animCommandCheckbox:Null<UIStandardMultiCheckbox>;
	var speedSlider:UIStandardMultiAnimSlider;
	var statusBarResult:Null<BuilderResult>;
	var spriteStatus:Updatable;
	var statesText:Updatable;
	var commandsText:Updatable;

	var statesCombos:Map<String, {dropdown:UIStandardMultiAnimDropdown, values:Array<String>}> = [];

	var filename = "marine.anim";
	var spriteRoot:Updatable;
	var stdBuilder:bh.multianim.MultiAnimBuilder;

	function getFont() {
		return hxd.res.DefaultFont.get();
	}

	function reloadAnimSM(reinit = true) {
		var builder = this.stdBuilder;
		if (animSM != null)
			animSM.remove();
		if (pointGraphics != null)
			pointGraphics.clear();


		try {
			var parsed = screenManager.loader.loadAnimParser(filename);

			if (reinit) {
				animSMStateSelector = [];
				for (k => v in parsed.definedStates) {
					animSMStateSelector.set(k, v[0]);
				}
			}

			animSM = initAnim(parsed, animSMStateSelector);

			if (animSM.animationStates.exists("idle")) {
				animSM.play("idle");
			} else {
				var val = animSM.animationStates.keyValueIterator().next();
				animSM.play(val.key);
			}


			removeGroupElements(groupNameAnimStates);

			final animStatesIterator = stateAnimLayouts.getIterator("animStates");
			for (key => value in animSM.animationStates) {
				var button = addElementWithIterator(UIStandardMultiAnimButton.create(builder, "button", '${key}'), animStatesIterator, groupNameAnimStates);
				button.onClick = () -> {
					animSM.play(key);
				}
			}

			animSM.onAnimationEvent = (event) -> {
				switch event {
					case Trigger(name):
					case PointEvent(name, point):
						final globalpt = animSM.localToGlobal(point.toPoint());
						addPointsElement(CIRCLE(globalpt.x, globalpt.y, 5, green, time + 3));
				}
			}

			for (key => value in statesCombos) {
				removeElement(value.dropdown);
			}

			final statesIterator = stateAnimLayouts.getIterator("statesDropdowns");
			for (key => value in parsed.definedStates) {
				final currentIndex = value.indexOf(animSMStateSelector.get(key));
				var all = parsed.definedStates[key];

				var opts = Lambda.map(all, x -> ({name: x} : UIElementListItem));
				var el = addElementWithIterator(UIStandardMultiAnimDropdown.create(builder.createElementBuilder("dropdown"), builder.createElementBuilder("list-panel"), builder.createElementBuilder("list-item-120"), builder.createElementBuilder("scrollbar"), "scrollbar", opts, currentIndex), statesIterator);
				statesCombos.set(key, {dropdown: el, values: all});
			}
		} catch (e) {
			var errorMsg = '${e}}';
			trace(errorMsg);
			updateStatusBar('${errorMsg}', true);
			animSM = null;
		}
	}

	public function createCross(x:Float, y:Float, size:Float, color = white) {
		pointGraphics.lineStyle(1, cast color, 1.0);
		pointGraphics.moveTo(x - size, y);
		pointGraphics.lineTo(x + size, y);
		pointGraphics.moveTo(x, y - size);
		pointGraphics.lineTo(x, y + size);
	}

	public function createCircle(x:Float, y:Float, size:Float, color = white) {
		pointGraphics.lineStyle(1, cast color, 1.0);
		pointGraphics.beginFill(cast color, 1.0);
		pointGraphics.drawCircle(x, y, size);
		pointGraphics.endFill();
	}

	public function createRect(x:Float, y:Float, w:Float, h:Float, color = white) {
		pointGraphics.lineStyle(1, cast color, 1.0);
		pointGraphics.drawRect(x, y, w, h);
	}

	override function update(dt:Float) {
		super.update(dt);

		time += dt;
		blink += dt;
		while (blink > 0.5)
			blink -= 0.5;
		if (animSM == null)
			return;
		animSM.speed = speed;

		pointGraphics.clear();

		var bounds = animSM.getBounds();
		if (showBounds) {
			createRect(bounds.x, bounds.y, bounds.width, bounds.height);
		}

		final currentFrame = animSM.getCurrentFrame();
		if (currentFrame != null) {
			spriteStatus.updateText('${currentFrame.width}x${currentFrame.height}, scale ${spriteScale} speed ${speed}');
		} else
			spriteStatus.updateText('no frame');

		for (name in animSM.getExtraPointNames()) {
			var pt = animSM.getExtraPoint(name);

			if (pt != null) {
				var globalpt = animSM.localToGlobal(pt.toPoint());

				addPointsElement(CROSS(globalpt.x, globalpt.y, red, time + 2));
				// trace('${name} ${globalpt}');
			}
		}

		for (p in points) {
			switch p {
				case CROSS(x, y, color, time):
					final c = if (blink < 0.25) white else color;
					createCross(x, y, 15, c);
				case CIRCLE(x, y, radius, color, time):
					final c = if (blink < 0.25) white else color;
					createCircle(x, y, radius, c);
			}
		}

		points = Lambda.filter(points, p -> switch p {
			case CROSS(x, y, color, t): t > time;
			case CIRCLE(x, y, radius, color, t): t > time;
		});
		var c = animSM.current;
		if (c != null) {
			var s = "";
			for (index => state in c.states) {
				final startColor = index == animSM.currentStateIndex ? '<font color="#ffffff">' : "";
				final endColor = index == animSM.currentStateIndex ? "</font>" : "";
				var duration = switch state {
					case Frame(frame): '${frame.duration * 1000.0}ms';
					default: "";
				}

				s += '${startColor}${Std.string(index).rpad(" ", 3)}  ${animationFrameStateToString(state)} ${endColor}${duration}<br/>';
			}
			statesText.updateText('${c.name} - ${animSM.currentStateIndex}<br/>${s}');
		} else {
			statesText.updateText('state = null');
		}
	}

	function addPointsElement(element) {
		points.push(element);
	}

	function initAnim(parsed:AnimParserResult, selector):AnimationSM {
		var created:AnimationSM = parsed.createAnimSM(selector);
		spriteRoot.setObject(created);
		created.setScale(spriteScale);

		return created;
	}



	function updateStatusBar(text:String, error:Bool = false) {
		if (this.statusBarResult != null)
			this.statusBarResult.object.remove();
		this.statusBarResult = stateAnimBuilder.buildWithParameters("mainStatusBar", ["statusText" => text, "error" => error]);
		var p = addBuilderResult(this.statusBarResult);
		var pt = stateAnimBuilder.getLayouts().getPoint("statusBar");
		p.object.setPosition(pt.x, pt.y);
	}

	public function load() {
		createGroup(groupNameAnimStates, false);
		this.stateAnimBuilder = this.screenManager.buildFromResourceName("stateanim.manim", false);
		this.stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);
		this.stateAnimLayouts = stateAnimBuilder.getLayouts();



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
		}


		var res = MacroUtils.macroBuildWithParameters(stateAnimBuilder, "ui", [], [
			pause=>addCheckbox(stdBuilder, true),
			bounds=>addCheckbox(stdBuilder, true),
			animStates=>addCheckbox(stdBuilder, true),
			animCommands=>addCheckbox(stdBuilder, true),
			load=>loaderButton,
			speedSlider => addSlider(stdBuilder,  0),
		]);
		var ui = res.builderResults;
		addBuilderResult(ui);
		this.pausedCheckbox = res.pause;
		this.showBoundsCheckbox = res.bounds;
		this.animStatesCheckbox = res.animStates;
		this.animCommandCheckbox = res.animCommands;
		this.speedSlider = res.speedSlider;

		this.spriteRoot = ui.getUpdatable("sprite");
		this.spriteStatus = ui.getUpdatable("spriteText");
		this.statesText = ui.getUpdatable("currentStatesText");
		this.commandsText = ui.getUpdatable("commandsText");

		this.animCommandCheckbox.onToggle = (checked ->  commandsText.setVisibility(checked));

		this.pointGraphics = new Graphics();
		getSceneRoot().add(pointGraphics, 10);

		reloadAnimSM(true);
		updateStatusBar("loaded");
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
			case UIToggle(pressed):
				if (source == pausedCheckbox) {
					if (animSM != null)
						animSM.paused = pressed;
				} else if (source == showBoundsCheckbox) {
					showBounds = pressed;
				} else if (source == animStatesCheckbox) {
					statesText.setVisibility(pressed);
				}

			case UIChangeValue(value):
				if (source == this.speedSlider) {
					this.speed = (value / 50.0) * 3.0;
				}
			case UIChangeItem(index, items):
				for (key => value in statesCombos) {
					if (value.dropdown == source) {
						animSMStateSelector[key] = statesCombos.get(key).values[index];
						reloadAnimSM(false);
					}
				}
			case UIKeyPress(keyCode, release):
				if (keyCode ==Key.CTRL) ctrl = !release;
				if (!release) {
					if(keyCode == Key.NUMBER_1) spriteScale = 1.0;
					else if(keyCode == Key.NUMBER_2) spriteScale = 2.0;
					else if(keyCode == Key.NUMBER_3) spriteScale = 3.0;
					else if(keyCode == Key.NUMBER_4) spriteScale = 4.0;
					else if(keyCode == Key.NUMBER_5) spriteScale = 5.0;
					else if(keyCode == Key.NUMBER_6) spriteScale = 6.0;
					else if(keyCode == Key.NUMBER_7) spriteScale = 7.0;
					else if(keyCode == Key.NUMBER_8) spriteScale = 8.0;
					if (animSM != null) animSM.setScale(spriteScale);
				}
			case UIOnControllerEvent(result):
				switch result {
					case Leaving:
					case Entering:
					case OnDialogResult(dialogName, result):
						if (dialogName == "fileChange" && result != false && result != null) {
							filename = '${result}';
							reloadAnimSM(true);
						}
				}
			case UICustomEvent(eventName, data):


		}
	}
}
