package bh.ui;

import bh.base.MAObject.MultiAnimObjectData;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIComponentHost;
import bh.ui.UIInteractiveSource;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;

enum InteractiveState {
	Normal;
	Hover;
	Pressed;
	Disabled;
}

@:nullSafety
class UIRichInteractiveHelper {
	public static inline final RESERVED_KEY = "autoStatus";

	final screen:UIComponentHost;
	final bindings:Map<String, InteractiveBinding> = [];

	public function new(screen:UIComponentHost) {
		this.screen = screen;
	}

	/** Scan source.getInteractives() for metadataKey metadata, auto-wire state machines.
	 *  Optional prefix matches the one used in screen.addInteractives(source, prefix).
	 *  metadataKey defaults to "bind". The key "autoStatus" is reserved for screen auto-wiring.
	 *  NOTE: Only one helper should bind a given interactive ID. The collision check only guards
	 *  against conflicts with the screen's auto-helper (autoStatus). Two manual helpers binding
	 *  the same interactive with different keys will both drive setParameter(), last-writer-wins. */
	public function register(source:UIInteractiveSource, ?prefix:String, metadataKey:String = "bind"):Void {
		if (metadataKey == RESERVED_KEY)
			throw '"$RESERVED_KEY" is reserved for screen auto-wiring — use "bind" or a custom key';
		registerInternal(source, prefix, metadataKey);
	}

	/** Internal registration for screen auto-wiring. Uses the reserved "autoStatus" key. */
	@:allow(bh.ui.screens.UIScreenBase)
	function registerAutoStatus(source:UIInteractiveSource, ?prefix:String):Void {
		registerInternal(source, prefix, RESERVED_KEY);
	}

	function registerInternal(source:UIInteractiveSource, prefix:Null<String>, metadataKey:String):Void {
		for (obj in source.getInteractives()) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, identifier, meta):
					if (meta != null) {
						final brs = new BuilderResolvedSettings(meta);
						final paramName = brs.getStringOrDefault(metadataKey, "");
						if (paramName != "") {
							final fullId = prefix != null ? '$prefix.$identifier' : identifier;
							// Check for collision with screen's auto-helper
							if (metadataKey != RESERVED_KEY) {
								final autoHelper = screen.getAutoInteractiveHelper();
								if (autoHelper != null && autoHelper.hasBinding(fullId))
									throw 'interactive "$fullId" is already managed by screen auto-wiring ($RESERVED_KEY) — cannot also register with "$metadataKey"';
							}
							bind(fullId, source, paramName, prefix);
						}
					}
				default:
			}
		}
	}

	/** Remove all bindings associated with a source. */
	public function unregister(source:UIInteractiveSource):Void {
		final toRemove:Array<String> = [];
		for (id => binding in bindings) {
			if (binding.source == source)
				toRemove.push(id);
		}
		for (id in toRemove)
			bindings.remove(id);
	}

	/** Resync bindings for a source against its current interactives list. Removes bindings whose
	 *  ids no longer exist in source.getInteractives() (filtered by prefix), and adds bindings for
	 *  any new ids. Existing bindings are PRESERVED — their currentState is not reset.
	 *  Used after a SWITCH arm flip / REPEAT rebuild changes which interactives are present.
	 *  metadataKey must match what was used in the original register() call. */
	public function resync(source:UIInteractiveSource, ?prefix:String, metadataKey:String = "bind"):Void {
		// 1. Walk current interactives, build expected id set + collect new bindings to add
		final expectedIds = new Map<String, Bool>();
		final toAdd:Array<{id:String, paramName:String}> = [];
		for (obj in source.getInteractives()) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, identifier, meta):
					if (meta != null) {
						final brs = new BuilderResolvedSettings(meta);
						final paramName = brs.getStringOrDefault(metadataKey, "");
						if (paramName != "") {
							final fullId = prefix != null ? '$prefix.$identifier' : identifier;
							expectedIds.set(fullId, true);
							if (!bindings.exists(fullId))
								toAdd.push({id: fullId, paramName: paramName});
						}
					}
				default:
			}
		}

		// 2. Remove stale bindings scoped to (source, prefix) — exact prefix equality. Bindings
		//    registered with a different prefix on the same source are left alone (dual-prefix safe).
		final toRemove:Array<String> = [];
		for (id => binding in bindings) {
			if (binding.source != source) continue;
			if (binding.prefix != prefix) continue;
			if (!expectedIds.exists(id)) toRemove.push(id);
		}
		for (id in toRemove) bindings.remove(id);

		// 3. Add bindings for new ids only — existing bindings keep their currentState
		for (entry in toAdd)
			bind(entry.id, source, entry.paramName, prefix);
	}

	/** Internal accessor for screen auto-wiring resync — uses the reserved metadata key. */
	@:allow(bh.ui.screens.UIScreenBase)
	function resyncAutoStatus(source:UIInteractiveSource, ?prefix:String):Void {
		resync(source, prefix, RESERVED_KEY);
	}

	/** Remove all bindings with the given prefix. */
	public function unregisterByPrefix(prefix:String):Void {
		final dotPrefix = '$prefix.';
		final toRemove:Array<String> = [];
		for (id in bindings.keys()) {
			if (StringTools.startsWith(id, dotPrefix))
				toRemove.push(id);
		}
		for (id in toRemove)
			bindings.remove(id);
	}

	/** Check if a binding exists for the given interactive id. */
	public function hasBinding(interactiveId:String):Bool {
		return bindings.exists(interactiveId);
	}

	/** Manually bind an interactive to a source's parameter. `prefix` records the scope used when
	 *  the binding was created (from `register`/`registerAutoStatus`); it is consulted by `resync`
	 *  to avoid wiping bindings on the same source that were registered under a different prefix. */
	public function bind(interactiveId:String, source:UIInteractiveSource, stateParam:String = "status", ?prefix:String):Void {
		bindings.set(interactiveId, {
			source: source,
			prefix: prefix,
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
		binding.source.setParameter(binding.stateParam, "normal");
	}

	/** Set binding state to Hover and set the parameter to "hover".
	 *  Used by position-based hover detection that bypasses Interactive events. */
	public function setHoverState(interactiveId:String):Void {
		final binding = bindings.get(interactiveId);
		if (binding == null) return;
		binding.currentState = Hover;
		binding.source.setParameter(binding.stateParam, "hover");
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
			binding.source.setParameter(binding.stateParam, "disabled");
		} else {
			final isHovered = wrapper != null && wrapper.hovered;
			binding.currentState = isHovered ? Hover : Normal;
			binding.source.setParameter(binding.stateParam, isHovered ? "hover" : "normal");
		}
	}

	/** Forward a non-state parameter to the bound result. */
	public function setParameter(interactiveId:String, param:String, value:Dynamic):Void {
		final binding = bindings.get(interactiveId);
		if (binding != null)
			binding.source.setParameter(param, value);
	}

	/** Access the bound source for a given interactive. Returns the `UIInteractiveSource` that
	 *  owns the interactive — either a `BuilderResult` (runtime path) or a codegen instance. */
	public function getSource(interactiveId:String):Null<UIInteractiveSource> {
		final binding = bindings.get(interactiveId);
		return binding?.source;
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
					case UIEntering(_):
						if (binding.currentState == Normal) {
							binding.currentState = Hover;
							binding.source.setParameter(binding.stateParam, "hover");
						}
					case UIPush:
						if (binding.currentState == Hover || binding.currentState == Normal) {
							binding.currentState = Pressed;
							binding.source.setParameter(binding.stateParam, "pressed");
						}
					case UIClick:
						if (binding.currentState == Pressed) {
							// Touch: no prior hover, return to Normal. Mouse: return to Hover.
							binding.currentState = Hover;
							binding.source.setParameter(binding.stateParam, "hover");
						}
					case UILeaving:
						if (binding.currentState == Hover || binding.currentState == Pressed) {
							binding.currentState = Normal;
							binding.source.setParameter(binding.stateParam, "normal");
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
	source:UIInteractiveSource,
	prefix:Null<String>,
	stateParam:String,
	currentState:InteractiveState,
}
