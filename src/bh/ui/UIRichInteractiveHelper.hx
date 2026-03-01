package bh.ui;

import bh.base.MAObject.MultiAnimObjectData;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.screens.UIScreen;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;

enum InteractiveState {
	Normal;
	Hover;
	Pressed;
	Disabled;
}

@:nullSafety
class UIRichInteractiveHelper {
	final screen:UIScreenBase;
	final bindings:Map<String, InteractiveBinding> = [];

	public function new(screen:UIScreenBase) {
		this.screen = screen;
	}

	/** Scan result.interactives for bind metadata, auto-wire state machines.
	 *  Optional prefix matches the one used in screen.addInteractives(result, prefix). */
	public function register(result:BuilderResult, ?prefix:String):Void {
		for (obj in result.interactives) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, identifier, meta):
					if (meta != null) {
						final brs = new BuilderResolvedSettings(meta);
						final bindParam = brs.getStringOrDefault("bind", "");
						if (bindParam != "") {
							final fullId = prefix != null ? '$prefix.$identifier' : identifier;
							bind(fullId, result, bindParam);
						}
					}
				default:
			}
		}
	}

	/** Remove all bindings associated with a result. */
	public function unregister(result:BuilderResult):Void {
		final toRemove:Array<String> = [];
		for (id => binding in bindings) {
			if (binding.result == result)
				toRemove.push(id);
		}
		for (id in toRemove)
			bindings.remove(id);
	}

	/** Manually bind an interactive to a result's parameter. */
	public function bind(interactiveId:String, result:BuilderResult, stateParam:String = "status"):Void {
		bindings.set(interactiveId, {
			result: result,
			stateParam: stateParam,
			currentState: Normal,
		});
	}

	/** Remove a single binding. */
	public function unbind(interactiveId:String):Void {
		bindings.remove(interactiveId);
	}

	/** Remove all bindings. */
	public function unbindAll():Void {
		bindings.clear();
	}

	/** Reset binding state to Normal and set the parameter to "normal".
	 *  Used after external code (e.g. drag helpers) bypasses the normal state machine. */
	public function resetState(interactiveId:String):Void {
		final binding = bindings.get(interactiveId);
		if (binding == null) return;
		binding.currentState = Normal;
		binding.result.setParameter(binding.stateParam, "normal");
	}

	/** Set disabled state. Also disables the UIInteractiveWrapper to gate events. */
	public function setDisabled(interactiveId:String, disabled:Bool):Void {
		final binding = bindings.get(interactiveId);
		if (binding == null) return;

		final wrapper = screen.getInteractive(interactiveId);
		if (wrapper != null)
			wrapper.disabled = disabled;

		if (disabled) {
			binding.currentState = Disabled;
			binding.result.setParameter(binding.stateParam, "disabled");
		} else {
			binding.currentState = Normal;
			binding.result.setParameter(binding.stateParam, "normal");
		}
	}

	/** Forward a non-state parameter to the bound result. */
	public function setParameter(interactiveId:String, param:String, value:Dynamic):Void {
		final binding = bindings.get(interactiveId);
		if (binding != null)
			binding.result.setParameter(param, value);
	}

	/** Access the bound result for a given interactive. */
	public function getResult(interactiveId:String):Null<BuilderResult> {
		final binding = bindings.get(interactiveId);
		return binding?.result;
	}

	/**
	 * Handle interactive events. Call from onScreenEvent.
	 * Returns true if the event was for a bound interactive.
	 */
	public function handleEvent(event:UIScreenEvent):Bool {
		switch event {
			case UIInteractiveEvent(innerEvent, id, _):
				final binding = bindings.get(id);
				if (binding == null) return false;
				if (binding.currentState == Disabled) return true;

				switch innerEvent {
					case UIEntering:
						if (binding.currentState == Normal) {
							binding.currentState = Hover;
							binding.result.setParameter(binding.stateParam, "hover");
						}
					case UIPush:
						if (binding.currentState == Hover) {
							binding.currentState = Pressed;
							binding.result.setParameter(binding.stateParam, "pressed");
						}
					case UIClick:
						if (binding.currentState == Pressed) {
							binding.currentState = Hover;
							binding.result.setParameter(binding.stateParam, "hover");
						}
					case UILeaving:
						if (binding.currentState == Hover || binding.currentState == Pressed) {
							binding.currentState = Normal;
							binding.result.setParameter(binding.stateParam, "normal");
						}
					default:
				}
				return true;
			default:
				return false;
		}
	}
}

private typedef InteractiveBinding = {
	result:BuilderResult,
	stateParam:String,
	currentState:InteractiveState,
}
