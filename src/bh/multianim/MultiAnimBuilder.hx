package bh.multianim;

import bh.multianim.MacroCompatTypes;
import h2d.Tile;
import bh.ui.UIElementBuilder;
import h2d.HtmlText;
import bh.paths.AnimatedPath;
import bh.paths.AnimatedPath.AnimatedPathMode;
import bh.paths.AnimatedPath.CurveSlot;
import bh.paths.MultiAnimPaths.Path;
import bh.stateanim.AnimationFrame;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationSM.AnimationFrameState;
import bh.base.FPoint;
import bh.base.Point;
import h2d.TileGroup;
import bh.base.filters.ReplacePaletteShader;
import bh.base.Palette;
import bh.base.filters.PixelOutline;
import h2d.Layers;
import h2d.Mask;
import bh.multianim.layouts.MultiAnimLayouts;
import bh.base.HeapsUtils.solidTile;
import bh.base.HeapsUtils.solidBitmap;
import bh.base.MAObject;
import bh.multianim.CoordinateSystems;
import bh.base.Hex.OffsetCoord;
import bh.base.Hex.DoubledCoord;
import bh.base.PixelLine;
import h2d.Object;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.SwitchArm;
import bh.multianim.BuilderError;
import bh.base.ResourceLoader;
import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenSequence;
import bh.base.TweenManager.TweenProperty;
import bh.base.Particles.ForceField;
import bh.base.Particles.BoundsMode;
import bh.base.Particles.SubEmitTrigger;
import bh.base.MacroUtils;
import bh.base.Atlas2.IAtlas2;
import bh.base.Atlas2.InlineAtlas2;
import bh.base.Atlas2.AtlasEntry;

using bh.base.MapTools;
using bh.multianim.ParseUtils;
using StringTools;
using bh.base.ColorUtils;

// Place this after imports, before any class definitions
@:nullSafety
private enum ComputedShape {
	Line(x1:Int, y1:Int, x2:Int, y2:Int, color:Int);
	Rect(x:Int, y:Int, w:Int, h:Int, color:Int, filled:Bool);
	Pixel(x:Int, y:Int, color:Int);
}


@:nullSafety
@:allow(bh.multianim.BuilderResult)
class Updatable implements IUpdatable {
	final updatables:Array<NamedBuildResult>;
	var lastObject:Null<h2d.Object> = null;

	function new(updatables:Array<NamedBuildResult>) {
		if (updatables == null || updatables.length == 0)
			throw BuilderError.of('empty updatable');
		this.updatables = updatables;
	}

	public function setVisibility(visible:Bool) {
		for (type in updatables) {
			type.getBuiltHeapsObject().toh2dObject().visible = visible;
		}
	}

	public function updateText(newText:String, throwIfAnyFails = true) {
		for (v in updatables) {
			switch v.object {
				case HeapsText(t):
					t.text = newText;
				default:
					if (throwIfAnyFails)
						throw BuilderError.of('invalid updateText: expected HeapsText but got ${v.object}');
			}
		}
	}

	public function updateTile(newTile:h2d.Tile, throwIfAnyFails = true) {
		for (v in updatables) {
			switch v.object {
				case HeapsBitmap(b):
					b.tile = newTile;
				default:
					if (throwIfAnyFails)
						throw BuilderError.of('invalid updateTile: expected HeapsBitmap but got ${v.object}');
			}
		}
	}

	public function setObject(newObject:h2d.Object) {
		if (updatables.length != 1)
			throw BuilderError.of('setObject needs exactly one updatable');
		if (lastObject == newObject)
			return; // nothing to do

		if (lastObject != null) {
			lastObject.remove();
			lastObject = null;
		}

		final parent = updatables[0].object.toh2dObject();
		parent.addChild(newObject);
		lastObject = newObject;
	}

	public function addObject(newObject:h2d.Object) {
		if (updatables.length != 1)
			throw BuilderError.of('addObject needs exactly one updatable');

		final parent = updatables[0].object.toh2dObject();
		parent.addChild(newObject);
		lastObject = newObject;
	}

	public function clearObjects() {
		for (v in updatables) {
			v.object.toh2dObject().removeChildren();
		}
		lastObject = null;
	}
}

@:nullSafety
class BuilderResolvedSettings {
	var settings:ResolvedSettings;

	public function new(settings) {
		this.settings = settings;
	}

	public function hasSettings():Bool {
		return settings != null;
	}

	/** Returns true if the given key exists in the settings. */
	public function has(key:String):Bool {
		if (settings == null)
			return false;
		return settings.exists(key);
	}

	public function getStringOrDefault(settingName:String, defaultString:String):String {
		if (settings == null)
			return defaultString;
		final r = settings[settingName];
		if (r == null)
			return defaultString;
		return switch r {
			case RSVString(s): s;
			case RSVInt(i): '$i';
			case RSVColor(c): '$c';
			case RSVFloat(f): '$f';
			case RSVBool(b): b ? "true" : "false";
		};
	}

	public function getStringOrException(settingName:String):String {
		if (settings == null)
			throw BuilderError.of('settings not found, was looking for $settingName');
		final r = settings[settingName];
		if (r == null)
			throw BuilderError.of('expected string setting ${settingName} to be present but was not');
		return switch r {
			case RSVString(s): s;
			case RSVInt(i): '$i';
			case RSVColor(c): '$c';
			case RSVFloat(f): '$f';
			case RSVBool(b): b ? "true" : "false";
		};
	}

	public function getIntOrException(settingName:String):Int {
		if (settings == null)
			throw BuilderError.of('settings not found, was looking for $settingName');
		var r = settings[settingName];
		if (r == null)
			throw BuilderError.of('expected int setting ${settingName} to be present but was not');
		return switch r {
			case RSVInt(i): i;
			case RSVColor(c): c;
			case RSVFloat(f): throw BuilderError.of('expected int setting ${settingName} to valid int number but was float $f');
			case RSVString(s): throw BuilderError.of('expected int setting ${settingName} to valid int number but was string $s');
			case RSVBool(b): b ? 1 : 0;
		};
	}

	public function getIntOrDefault(settingName:String, defaultValue:Int):Int {
		if (settings == null)
			return defaultValue;
		var r = settings[settingName];
		if (r == null)
			return defaultValue;
		return switch r {
			case RSVInt(i): i;
			case RSVColor(c): c;
			case RSVFloat(f): throw BuilderError.of('expected int setting ${settingName} to valid int number but was float $f');
			case RSVString(s): throw BuilderError.of('expected int setting ${settingName} to valid int number but was string $s');
			case RSVBool(b): b ? 1 : 0;
		};
	}

	public function getFloatOrException(settingName:String):Float {
		if (settings == null)
			throw BuilderError.of('settings not found, was looking for $settingName');
		var r = settings[settingName];
		if (r == null)
			throw BuilderError.of('expected float setting ${settingName} to be present but was not');
		return switch r {
			case RSVFloat(f): f;
			case RSVInt(i): cast i;
			case RSVColor(c): cast c;
			case RSVString(s): throw BuilderError.of('expected float setting ${settingName} to valid float number but was string $s');
			case RSVBool(b): b ? 1.0 : 0.0;
		};
	}

	public function getFloatOrDefault(settingName:String, defaultValue:Float):Float {
		if (settings == null)
			return defaultValue;
		var r = settings[settingName];
		if (r == null)
			return defaultValue;
		return switch r {
			case RSVFloat(f): f;
			case RSVInt(i): cast i;
			case RSVColor(c): cast c;
			case RSVString(s): throw BuilderError.of('expected float setting ${settingName} to valid float number but was string $s');
			case RSVBool(b): b ? 1.0 : 0.0;
		};
	}

	public function keys():Iterator<String> {
		if (settings == null)
			return [].iterator();
		return settings.keys();
	}

	public function getBoolOrDefault(settingName:String, defaultValue:Bool):Bool {
		if (settings == null)
			return defaultValue;
		var r = settings[settingName];
		if (r == null)
			return defaultValue;
		return switch r {
			case RSVBool(b): b;
			case RSVInt(i): i != 0;
			case RSVColor(c): c != 0;
			case RSVFloat(f): f != 0;
			case RSVString(s):
				switch (s.toLowerCase()) {
					case "true" | "1" | "yes": true;
					case "false" | "0" | "no": false;
					default: throw BuilderError.of('could not parse setting "$s" as bool');
				};
		};
	}
}

private typedef SavedFlowProperties = {
	horizontalAlign:Null<h2d.Flow.FlowAlign>,
	verticalAlign:Null<h2d.Flow.FlowAlign>,
	offsetX:Int, offsetY:Int,
	isAbsolute:Bool,
	minWidth:Null<Int>, minHeight:Null<Int>,
	paddingLeft:Int, paddingTop:Int, paddingRight:Int, paddingBottom:Int,
};

@:nullSafety
private typedef DynamicNameBinding = {
	paramName:String,
	container:h2d.Object,
	currentName:String,
	node:Node,
	parameters:Map<String, ReferenceableValue>,
	externalReference:Null<String>,
	internalResults:InternalBuilderResults,
};

@:nullSafety
class IncrementalUpdateContext {
	var builder:MultiAnimBuilder;
	var indexedParams:Map<String, ResolvedIndexParameters>;
	var builderParams:BuilderParameters;
	var conditionalEntries:Array<{object:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
		savedFlowProps:Null<SavedFlowProperties>}> = [];
	// Per-entry state is just the matched-flag. The parent's pre-apply baseline is
	// stored once per parent in `conditionalApplyBaselines` (captured lazily by the
	// first apply entry on that parent, before any inline apply runs). On any
	// apply/unapply the parent is reset to baseline and all currently-matched
	// entries for that parent are replayed in declaration order. This is what
	// lets overlapping applies (two `@(cond) apply { alpha: ... }` on the same
	// parent) compose correctly — per-entry save/restore can't, because the save
	// includes sibling applies' effects.
	var conditionalApplyEntries:Array<{parent:h2d.Object, node:Node, applied:Bool}> = [];
	var conditionalApplyBaselines:haxe.ds.ObjectMap<h2d.Object, {
		filter:Null<h2d.filter.Filter>, alpha:Float,
		scaleX:Float, scaleY:Float, rotation:Float, x:Float, y:Float,
	}> = new haxe.ds.ObjectMap();
	var trackedExpressions:Array<{updateFn:Void->Void, paramRefs:Array<String>, object:Null<h2d.Object>}> = [];
	var deferredEntries:Array<{
		wrapper:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
		gridCS:GridCoordinateSystem, hexCS:HexCoordinateSystem,
		internalResults:InternalBuilderResults, builderParams:BuilderParameters,
	}> = [];
	var dynamicRefBindings:Array<{childContext:IncrementalUpdateContext, childParam:String, resolveFn:Void->Dynamic, referencedParams:Array<String>, object:Null<h2d.Object>}> = [];
	var dynamicNameBindings:Array<DynamicNameBinding> = [];
	var rootNode:Node;
	var batchMode:Bool = false;
	var changedParams:Map<String, Bool> = new Map();
	var hasChanges:Bool = false;
	var transitionsDef:Null<Map<String, TransitionType>>;
	public var tweenManager:Null<TweenManager> = null;
	var activeTransitionTweens:Array<{obj:h2d.Object, tween:Null<Tween>, sequence:Null<TweenSequence>, savedAlpha:Float, savedScaleX:Float, savedScaleY:Float, savedX:Float, savedY:Float}> = [];
	var rebuildListeners:Array<Void -> Void> = [];
	// Params that appear in slots whose incremental updates are intentionally unsupported
	// (interactive id/metadata, stateanim selectors, ...). setParameter on one of these
	// throws — silent no-ops would leave the rendered state inconsistent with the param map.
	// Populated during trackIncrementalExpressions; keyed by param name, values are human-
	// readable reasons like `interactive id` or `stateanim selector "direction"`.
	var untrackedParams:Map<String, Array<String>> = new Map();

	public function new(builder:MultiAnimBuilder, indexedParams:Map<String, ResolvedIndexParameters>,
			builderParams:BuilderParameters, rootNode:Node) {
		this.builder = builder;
		// Deep copy indexed params so they persist independently
		this.indexedParams = new Map();
		for (k => v in indexedParams)
			this.indexedParams.set(k, v);
		this.builderParams = builderParams;
		this.rootNode = rootNode;
		this.transitionsDef = rootNode.transitions;
	}

	#if MULTIANIM_DEV
	public function snapshotParams():Map<String, ResolvedIndexParameters> {
		final copy:Map<String, ResolvedIndexParameters> = new Map();
		for (k => v in indexedParams)
			copy.set(k, v);
		return copy;
	}

	public function getBuilderParams():BuilderParameters {
		return builderParams;
	}

	#end

	/** Sync surviving @final constants (ExpressionAlias entries) from the live builder state
	 *  into the context's persistent indexedParams. Called after initial build so that
	 *  setParameter-triggered rebuilds can resolve references like `$RGB3` to their @final
	 *  expressions. @finals cleaned up at nested-scope exit (via cleanupFinalVars) are not
	 *  present in `live` and therefore not synced — matching their lexical scope. */
	public function syncFinalsFromBuilder(live:Map<String, ResolvedIndexParameters>):Void {
		for (name => v in live) {
			switch v {
				case ExpressionAlias(_):
					indexedParams.set(name, v);
				default:
			}
		}
	}

	public function trackConditional(object:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int):Void {
		conditionalEntries.push({object: object, node: node, sentinel: sentinel, parent: parent, layer: layer,
			savedFlowProps: saveFlowProperties(object, parent)});
	}

	public function trackDeferredConditional(wrapper:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			gridCS:GridCoordinateSystem, hexCS:HexCoordinateSystem,
			internalResults:InternalBuilderResults, builderParams:BuilderParameters):Void {
		conditionalEntries.push({object: wrapper, node: node, sentinel: sentinel, parent: parent, layer: layer,
			savedFlowProps: saveFlowProperties(wrapper, parent)});
		deferredEntries.push({
			wrapper: wrapper, node: node, sentinel: sentinel, parent: parent, layer: layer,
			gridCS: gridCS, hexCS: hexCS,
			internalResults: internalResults, builderParams: builderParams,
		});
	}

	/** Save Flow layout properties of an object so they can be restored when re-adding to a Flow parent. */
	function saveFlowProperties(object:h2d.Object, parent:h2d.Object):Null<SavedFlowProperties> {
		if (!Std.isOfType(parent, h2d.Flow)) return null;
		final flow:h2d.Flow = cast parent;
		final props = flow.getProperties(object);
		return {
			horizontalAlign: props.horizontalAlign,
			verticalAlign: props.verticalAlign,
			offsetX: props.offsetX, offsetY: props.offsetY,
			isAbsolute: props.isAbsolute,
			minWidth: props.minWidth, minHeight: props.minHeight,
			paddingLeft: props.paddingLeft, paddingTop: props.paddingTop,
			paddingRight: props.paddingRight, paddingBottom: props.paddingBottom,
		};
	}

	/** Restore saved Flow layout properties after re-adding a child to a Flow parent. */
	function restoreFlowProperties(object:h2d.Object, parent:h2d.Object, saved:Null<SavedFlowProperties>):Void {
		if (saved == null) return;
		if (!Std.isOfType(parent, h2d.Flow)) return;
		final flow:h2d.Flow = cast parent;
		final props = flow.getProperties(object);
		props.horizontalAlign = saved.horizontalAlign;
		props.verticalAlign = saved.verticalAlign;
		props.offsetX = saved.offsetX;
		props.offsetY = saved.offsetY;
		props.isAbsolute = saved.isAbsolute;
		props.minWidth = saved.minWidth;
		props.minHeight = saved.minHeight;
		props.paddingLeft = saved.paddingLeft;
		props.paddingTop = saved.paddingTop;
		props.paddingRight = saved.paddingRight;
		props.paddingBottom = saved.paddingBottom;
	}

	public function trackExpression(updateFn:Void->Void, paramRefs:Array<String>, ?object:h2d.Object):Void {
		trackedExpressions.push({updateFn: updateFn, paramRefs: paramRefs, object: object});
	}

	public function trackDynamicRef(childContext:IncrementalUpdateContext, childParam:String, resolveFn:Void->Dynamic, referencedParams:Array<String>, ?object:h2d.Object):Void {
		dynamicRefBindings.push({childContext: childContext, childParam: childParam, resolveFn: resolveFn, referencedParams: referencedParams, object: object});
	}

	public function trackDynamicName(binding:DynamicNameBinding):Void {
		dynamicNameBindings.push(binding);
	}

	/** Register a listener to be invoked once after each applyUpdates() cycle in which any structural
	 *  rebuild fired (i.e. parameter changes processed). Use this to resync external state — for
	 *  example, screen-side UIInteractiveWrapper maps that need to track new arms appearing after a
	 *  @switch flip. The listener fires AFTER all conditional/tracked updates and dynamic ref
	 *  propagation, so the BuilderResult collections are coherent when it runs. */
	public function addRebuildListener(fn:Void -> Void):Void {
		rebuildListeners.push(fn);
	}

	/** Remove a previously-added rebuild listener. No-op if not present. */
	public function removeRebuildListener(fn:Void -> Void):Void {
		rebuildListeners.remove(fn);
	}

	/** Drop all per-element bookkeeping for entries whose underlying h2d.Object is `container` itself
	 *  or a descendant of it. Called by SWITCH/REPEAT rebuild closures BEFORE container.removeChildren()
	 *  so parent links are still intact for the descendant walk.
	 *
	 *  Cleans:
	 *  - InternalBuilderResults (interactives/slots/dynamicRefs/names/htmlTextsWithLinks) via removeRegistrationsUnder
	 *  - dynamicRefBindings whose child context belongs to a removed dynamicRef (avoids forwarding to dead context)
	 *  - dynamicNameBindings whose container is under the destroyed subtree
	 *  - trackedExpressions whose object is a STRICT descendant of container (does not remove the rebuild
	 *    closure's own entry, which has object == container)
	 *  - conditionalEntries / conditionalApplyEntries / deferredEntries whose objects are under container
	 *  - activeTransitionTweens on objects under container (cancelled to avoid completion callbacks on dead objs)
	 */
	public function cleanupDestroyedSubtree(ir:InternalBuilderResults, container:h2d.Object):Void {
		// 1. Capture dynamicRef child contexts that will be removed, so we can drop their bindings afterwards.
		final removedChildContexts:Array<IncrementalUpdateContext> = [];
		for (_ => result in ir.dynamicRefs) {
			final obj = result.object;
			final isUnder = obj == container || (obj.parent != null && isDescendantOf(obj, container));
			if (isUnder && result.incrementalContext != null)
				removedChildContexts.push(result.incrementalContext);
		}

		// 2. Clean IR collections via the existing helper.
		MultiAnimBuilder.removeRegistrationsUnder(ir, container);

		// 3. Drop dynamicRefBindings whose childContext was just orphaned.
		if (removedChildContexts.length > 0) {
			var i = 0;
			while (i < dynamicRefBindings.length) {
				if (removedChildContexts.indexOf(dynamicRefBindings[i].childContext) >= 0)
					dynamicRefBindings.splice(i, 1);
				else i++;
			}
		}

		// 4. Drop dynamicNameBindings whose container is under the destroyed subtree.
		var ni = 0;
		while (ni < dynamicNameBindings.length) {
			final dnbContainer = dynamicNameBindings[ni].container;
			final isUnder = dnbContainer == container || isDescendantOf(dnbContainer, container);
			if (isUnder) dynamicNameBindings.splice(ni, 1);
			else ni++;
		}

		// 5. Drop trackedExpressions whose object is a STRICT descendant of container.
		//    The rebuild closure's own entry has object == container — keep it.
		var ti = 0;
		while (ti < trackedExpressions.length) {
			final obj = trackedExpressions[ti].object;
			if (obj != null && obj != container && isDescendantOf(obj, container))
				trackedExpressions.splice(ti, 1);
			else ti++;
		}

		// 6. Drop conditionalEntries whose object is under container.
		var ci = 0;
		while (ci < conditionalEntries.length) {
			final obj = conditionalEntries[ci].object;
			final isUnder = obj == container || (obj.parent != null && isDescendantOf(obj, container));
			if (isUnder) conditionalEntries.splice(ci, 1);
			else ci++;
		}

		// 7. Drop conditionalApplyEntries whose parent is under container, and drop
		//    the matching baseline entries (parent object is gone, map key dangles).
		var ai = 0;
		while (ai < conditionalApplyEntries.length) {
			final parent = conditionalApplyEntries[ai].parent;
			final isUnder = parent == container || (parent.parent != null && isDescendantOf(parent, container));
			if (isUnder) conditionalApplyEntries.splice(ai, 1);
			else ai++;
		}
		final baselineParents:Array<h2d.Object> = [];
		for (parent in conditionalApplyBaselines.keys()) baselineParents.push(parent);
		for (parent in baselineParents) {
			final isUnder = parent == container || (parent.parent != null && isDescendantOf(parent, container));
			if (isUnder) conditionalApplyBaselines.remove(parent);
		}

		// 8. Drop deferredEntries whose wrapper is under container.
		var di = 0;
		while (di < deferredEntries.length) {
			final wrapper = deferredEntries[di].wrapper;
			final isUnder = wrapper == container || (wrapper.parent != null && isDescendantOf(wrapper, container));
			if (isUnder) deferredEntries.splice(di, 1);
			else di++;
		}

		// 9. Cancel + drop active transition tweens on objects under container.
		var twi = 0;
		while (twi < activeTransitionTweens.length) {
			final obj = activeTransitionTweens[twi].obj;
			final isUnder = obj == container || (obj.parent != null && isDescendantOf(obj, container));
			if (isUnder) {
				final entry = activeTransitionTweens[twi];
				if (entry.tween != null) {
					entry.tween.onComplete = null;
					entry.tween.cancel();
				}
				if (entry.sequence != null) {
					entry.sequence.onComplete = null;
					entry.sequence.cancel();
				}
				activeTransitionTweens.splice(twi, 1);
			} else twi++;
		}
	}

	#if MULTIANIM_DEV
	/** Dev-only inspection: number of tracked expression closures currently registered. */
	public function getTrackedExpressionsCount():Int return trackedExpressions.length;

	/** Dev-only inspection: number of conditional entries currently registered. */
	public function getConditionalEntriesCount():Int return conditionalEntries.length;

	/** Dev-only inspection: number of conditional apply entries currently registered. */
	public function getConditionalApplyEntriesCount():Int return conditionalApplyEntries.length;

	/** Dev-only inspection: number of dynamic ref param-forwarding bindings. */
	public function getDynamicRefBindingsCount():Int return dynamicRefBindings.length;

	/** Dev-only inspection: number of dynamic name (template-name) bindings. */
	public function getDynamicNameBindingsCount():Int return dynamicNameBindings.length;
	#end

	public function trackConditionalApply(parent:h2d.Object, node:Node, applied:Bool):Void {
		conditionalApplyEntries.push({parent: parent, node: node, applied: applied});
	}

	/** Capture a parent's pre-apply baseline. Must be called before the first inline
	 *  conditional apply touches the parent; subsequent calls on the same parent are
	 *  no-ops so the baseline keeps the state as it was before ANY apply. */
	public function captureApplyBaseline(parent:h2d.Object):Void {
		if (conditionalApplyBaselines.exists(parent)) return;
		conditionalApplyBaselines.set(parent, {
			filter: parent.filter, alpha: parent.alpha,
			scaleX: parent.scaleX, scaleY: parent.scaleY, rotation: parent.rotation,
			x: parent.x, y: parent.y,
		});
	}

	/** Reset a parent to its captured baseline and replay every currently-matched
	 *  apply entry for that parent in declaration (push) order. Safe to call
	 *  whenever an entry's match state flips; composes overlapping applies correctly. */
	function reconcileApplyParent(parent:h2d.Object):Void {
		final baseline = conditionalApplyBaselines.get(parent);
		if (baseline == null) return;
		parent.filter = cast baseline.filter;
		parent.alpha = baseline.alpha;
		parent.scaleX = baseline.scaleX;
		parent.scaleY = baseline.scaleY;
		parent.rotation = baseline.rotation;
		parent.x = baseline.x;
		parent.y = baseline.y;
		for (entry in conditionalApplyEntries) {
			if (entry.parent != parent) continue;
			if (!entry.applied) continue;
			final node = entry.node;
			final pos = builder.calculatePosition(node.pos,
				MultiAnimParser.getGridCoordinateSystem(node),
				MultiAnimParser.getHexCoordinateSystem(node));
			builder.addPosition(parent, pos.x, pos.y);
			builder.applyExtendedFormProperties(parent, node);
		}
	}

	/** Add a conditional element back into the scene graph, positioned right after its sentinel. */
	function addToGraph(entry:{object:h2d.Object, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			?savedFlowProps:Null<SavedFlowProperties>}):Void {
		if (entry.object.parent != null) return; // already in graph
		final sentinel = entry.sentinel;
		final parent = entry.parent;
		if (Std.isOfType(parent, h2d.Layers) && entry.layer != -1) {
			final layersParent:h2d.Layers = cast parent;
			// Layers.add index is relative to layer start
			final sentinelIndex = layersParent.getChildIndexInLayer(sentinel);
			layersParent.add(entry.object, entry.layer, sentinelIndex + 1);
		} else {
			final sentinelIndex = parent.getChildIndex(sentinel);
			parent.addChildAt(entry.object, sentinelIndex + 1);
		}
		restoreFlowProperties(entry.object, parent, entry.savedFlowProps);
		// Re-fire tracked expressions to restore content lost on removeChild.
		// h2d.Graphics clears draw commands in onRemove(), so content must be re-drawn.
		refreshTrackedExpressionsFor(entry.object);
	}

	/** Remove a conditional element from the scene graph. Its sentinel stays. */
	function removeFromGraph(entry:{object:h2d.Object}):Void {
		if (entry.object.parent == null) return; // already removed
		entry.object.parent.removeChild(entry.object);
	}

	/** Check if a conditional element is currently in the scene graph. */
	static inline function isInGraph(obj:h2d.Object):Bool {
		return obj.parent != null;
	}

	/** Re-fire tracked expressions for elements within a subtree that was just re-added.
	    h2d.Graphics clears draw commands in onRemove(), so content must be re-drawn on re-add. */
	function refreshTrackedExpressionsFor(target:h2d.Object):Void {
		for (tracked in trackedExpressions) {
			final obj = tracked.object;
			if (obj == null) continue;
			if (obj == target || isDescendantOf(obj, target))
				tracked.updateFn();
		}
	}

	static function isDescendantOf(obj:h2d.Object, ancestor:h2d.Object):Bool {
		var p = obj.parent;
		while (p != null) {
			if (p == ancestor) return true;
			p = p.parent;
		}
		return false;
	}

	function applyConditionalApplyEntry(entry:{parent:h2d.Object, node:Node, applied:Bool}):Void {
		if (entry.applied) return;
		entry.applied = true;
		reconcileApplyParent(entry.parent);
	}

	function unapplyConditionalApplyEntry(entry:{parent:h2d.Object, node:Node, applied:Bool}):Void {
		if (!entry.applied) return;
		entry.applied = false;
		reconcileApplyParent(entry.parent);
	}

	public function markParamUntracked(paramName:String, reason:String):Void {
		var existing = untrackedParams.get(paramName);
		if (existing == null) {
			existing = [];
			untrackedParams.set(paramName, existing);
		}
		if (existing.indexOf(reason) < 0) existing.push(reason);
	}

	@:nullSafety(Off)
	public function setParameter(name:String, value:Dynamic):Void {
		final untrackedReasons = untrackedParams.get(name);
		if (untrackedReasons != null) {
			throw BuilderError.of('setParameter("$name", ...) rejected: this param is referenced in incremental-unsupported slot(s) [${untrackedReasons.join(", ")}]. Changing it would leave the rendered state inconsistent. Either rebuild the programmable or avoid runtime mutation of this param.',
				"untracked_param");
		}
		// Look up the parameter type definition for type-aware conversion (flags need special handling).
		// Unknown param names are silently skipped (not a throw): UI widgets (Button, Checkbox,
		// Slider, Tabs, TextInput) intentionally setParameter("disabled", ...) on every client
		// template, relying on a no-op when the template doesn't opt into that param. Throwing
		// here would break that contract. The stale-listener bug that H1 described was specific
		// to the case where we DID have declared tracking for the param but stored no value —
		// skipping `changedParams`/`hasChanges` for an unknown param avoids firing listeners
		// that have nothing to read anyway.
		final paramDef = getParamDefinition(name);
		if (paramDef == null)
			return;
		final paramType = paramDef.type;
		// Resolve the value shape first, THEN commit. If no branch matches we throw
		// instead of silently flagging `changedParams` — the old code fell through and
		// re-fired dependent listeners against a stale indexedParams entry.
		// Int-before-Float is load-bearing: Std.isOfType(42, Float) is true in Haxe.
		var converted:Null<ResolvedIndexParameters> = null;
		if (paramType != null && paramType.match(PPTFlags(_))) {
			converted = MultiAnimParser.dynamicValueToIndex(name, paramType, value, s -> throw s);
		} else if (Std.isOfType(value, Int)) {
			// Int is the final form for color params — Heaps AARRGGBB convention.
			// Use `0xFFRRGGBB` for opaque, `0x00RRGGBB`/`0` for transparent.
			converted = Value((value : Int));
		} else if (Std.isOfType(value, Float)) {
			converted = ValueF(value);
		} else if (Std.isOfType(value, String)) {
			converted = StringValue(cast value);
		} else if (Std.isOfType(value, Bool)) {
			converted = Value(cast(value, Bool) ? 1 : 0);
		} else if (Std.isOfType(value, ResolvedIndexParameters)) {
			converted = value;
		}
		#if !macro
		else if (Std.isOfType(value, h2d.Tile)) {
			converted = TileSourceValue(TSTile(value));
		}
		#end
		if (converted == null) {
			final typeDesc = value == null ? "null" : Type.getClassName(Type.getClass(value));
			if (typeDesc == null) {
				// Enum values and other non-class types land here — Type.getClass returns null.
				throw BuilderError.of('setParameter("$name", ...) rejected: value type not convertible to a parameter shape (got ${Std.string(value)}). Accepted: Int, Float, String, Bool, ResolvedIndexParameters, h2d.Tile.',
					"invalid_param_value");
			}
			throw BuilderError.of('setParameter("$name", ...) rejected: value type not convertible to a parameter shape (got $typeDesc). Accepted: Int, Float, String, Bool, ResolvedIndexParameters, h2d.Tile.',
				"invalid_param_value");
		}
		indexedParams.set(name, converted);
		changedParams.set(name, true);
		hasChanges = true;
		if (!batchMode)
			applyUpdates();
	}

	public function beginUpdate():Void {
		if (batchMode) throw BuilderError.of("beginUpdate: already in batch; nesting is not supported", "nested_begin_update");
		batchMode = true;
		changedParams.clear();
		hasChanges = false;
	}

	public function endUpdate():Void {
		if (!batchMode) throw BuilderError.of("endUpdate: no matching beginUpdate", "unbalanced_end_update");
		batchMode = false;
		if (hasChanges)
			applyUpdates();
		changedParams.clear();
		hasChanges = false;
	}

	function getParamDefinition(name:String):Null<{type:MultiAnimParser.DefinitionType, defaultValue:Null<ResolvedIndexParameters>}> {
		return switch rootNode.type {
			case PROGRAMMABLE(_, defs, _): defs.get(name);
			// Parameterized slots also own their own IncrementalUpdateContext. Non-parameterized
			// slots have `defs == null` — treated as "no declared params", matches PROGRAMMABLE
			// behavior for unknown names.
			case SLOT(defs, _): defs == null ? null : defs.get(name);
			default: null;
		};
	}

	public function setTweenManager(tm:TweenManager):Void {
		this.tweenManager = tm;
	}

	public function cancelAllTransitions():Void {
		for (entry in activeTransitionTweens) {
			if (entry.tween != null) {
				entry.tween.onComplete = null;
				entry.tween.cancel();
			}
			if (entry.sequence != null) {
				entry.sequence.onComplete = null;
				entry.sequence.cancel();
			}
			entry.obj.alpha = entry.savedAlpha;
			entry.obj.scaleX = entry.savedScaleX;
			entry.obj.scaleY = entry.savedScaleY;
			entry.obj.x = entry.savedX;
			entry.obj.y = entry.savedY;
		}
		activeTransitionTweens = [];
	}

	/** Pick the transition spec to apply when toggling `node`'s presence.
	 *
	 *  Restricted to the params that actually drive `node`'s visibility — without this filter
	 *  a batched setParameter() over multiple unrelated params would let any param's transition
	 *  spec leak onto an element it doesn't control (the old version returned the first hit in
	 *  StringMap iteration order). When several relevant params are changed together AND each
	 *  has its own spec, the alphabetically first param wins so the choice is stable across
	 *  runs/platforms. */
	function findTransitionSpec(node:Node):Null<TransitionType> {
		if (transitionsDef == null) return null;
		final relevant = getRelevantParamRefsForNode(node);
		if (relevant.length == 0) return null;
		var winnerName:Null<String> = null;
		for (paramName in relevant) {
			if (!changedParams.exists(paramName)) continue;
			if (!transitionsDef.exists(paramName)) continue;
			if (winnerName == null || paramName < winnerName) winnerName = paramName;
		}
		return winnerName == null ? null : transitionsDef.get(winnerName);
	}

	function getRelevantParamRefsForNode(node:Node):Array<String> {
		final refs = new haxe.ds.StringMap<Bool>();
		collectParamRefsFromNode(node, refs);
		return [for (k in refs.keys()) k];
	}

	function collectParamRefsFromNode(node:Node, refs:haxe.ds.StringMap<Bool>):Void {
		switch node.conditionals {
			case Conditional(values, _):
				for (k in values.keys()) refs.set(k, true);
			case ConditionalElse(extraConditions):
				if (extraConditions != null)
					for (k in extraConditions.keys()) refs.set(k, true);
				collectChainParamRefs(node, refs);
			case ConditionalDefault:
				collectChainParamRefs(node, refs);
			case NoConditional:
				// Always visible — no controlling params.
		}
	}

	/** Walk preceding siblings of `node` to collect param refs from the @() / @else chain
	 *  it belongs to. Stops at NoConditional (chain break) or at a ConditionalDefault from
	 *  an earlier chain. Mirrors the chain-resolution logic in resolveVisibilityForChildren. */
	function collectChainParamRefs(node:Node, refs:haxe.ds.StringMap<Bool>):Void {
		final p = node.parent;
		if (p == null || p.children == null) return;
		final siblings = p.children;
		var idx = -1;
		for (i in 0...siblings.length) if (siblings[i] == node) { idx = i; break; }
		if (idx <= 0) return;
		var i = idx - 1;
		while (i >= 0) {
			final sib = siblings[i];
			switch sib.conditionals {
				case Conditional(values, _):
					for (k in values.keys()) refs.set(k, true);
				case ConditionalElse(extraConditions):
					if (extraConditions != null)
						for (k in extraConditions.keys()) refs.set(k, true);
				case ConditionalDefault:
					return;
				case NoConditional:
					return;
			}
			i--;
		}
	}

	function cancelActiveTransition(obj:h2d.Object):Void {
		var i = 0;
		while (i < activeTransitionTweens.length) {
			if (activeTransitionTweens[i].obj == obj) {
				final entry = activeTransitionTweens[i];
				if (entry.tween != null) {
					entry.tween.onComplete = null; // Prevent delayed onComplete from TweenManager
					entry.tween.cancel();
				}
				if (entry.sequence != null) {
					entry.sequence.onComplete = null;
					entry.sequence.cancel();
				}
				// Restore pre-transition properties so the next transition starts from clean state
				obj.alpha = entry.savedAlpha;
				obj.scaleX = entry.savedScaleX;
				obj.scaleY = entry.savedScaleY;
				obj.x = entry.savedX;
				obj.y = entry.savedY;
				activeTransitionTweens.splice(i, 1);
			} else {
				i++;
			}
		}
	}

	function trackTransitionTween(obj:h2d.Object, tween:Tween, savedAlpha:Float, savedScaleX:Float, savedScaleY:Float, savedX:Float, savedY:Float):Void {
		activeTransitionTweens.push({obj: obj, tween: tween, sequence: null, savedAlpha: savedAlpha, savedScaleX: savedScaleX, savedScaleY: savedScaleY, savedX: savedX, savedY: savedY});
		final origOnComplete = tween.onComplete;
		tween.onComplete = () -> {
			var i = 0;
			while (i < activeTransitionTweens.length) {
				if (activeTransitionTweens[i].tween == tween) {
					activeTransitionTweens.splice(i, 1);
					break;
				}
				i++;
			}
			if (origOnComplete != null) origOnComplete();
		};
	}

	function trackTransitionSequence(obj:h2d.Object, seq:TweenSequence, savedAlpha:Float, savedScaleX:Float, savedScaleY:Float, savedX:Float, savedY:Float):Void {
		activeTransitionTweens.push({obj: obj, tween: null, sequence: seq, savedAlpha: savedAlpha, savedScaleX: savedScaleX, savedScaleY: savedScaleY, savedX: savedX, savedY: savedY});
		final origOnComplete = seq.onComplete;
		seq.onComplete = () -> {
			var i = 0;
			while (i < activeTransitionTweens.length) {
				if (activeTransitionTweens[i].sequence == seq) {
					activeTransitionTweens.splice(i, 1);
					break;
				}
				i++;
			}
			if (origOnComplete != null) origOnComplete();
		};
	}

	function hasActiveTransition(obj:h2d.Object):Bool {
		for (entry in activeTransitionTweens)
			if (entry.obj == obj) return true;
		return false;
	}

	/** Check if an object is effectively visible: in the scene graph and all ancestors visible. */
	static function isEffectivelyVisible(obj:h2d.Object):Bool {
		if (obj.parent == null) return false; // Not in scene graph
		var cur = obj;
		while (cur != null) {
			if (!cur.visible) return false;
			cur = cur.parent;
		}
		return true;
	}

	function setPresenceWithTransition(entry:{object:h2d.Object, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			?savedFlowProps:Null<SavedFlowProperties>}, newVisible:Bool, node:Node):Void {
		final obj = entry.object;
		final inGraph = isInGraph(obj);
		// Skip only if state matches AND no transition is in progress.
		if (inGraph == newVisible && !hasActiveTransition(obj)) return;

		final transSpec = findTransitionSpec(node);
		if (transSpec == null || tweenManager == null || transSpec.match(TransNone)) {
			cancelActiveTransition(obj);
			if (newVisible)
				addToGraph(entry);
			else
				removeFromGraph(entry);
			return;
		}

		cancelActiveTransition(obj);
		executePresenceTransition(entry, newVisible, transSpec);
	}

	function executePresenceTransition(entry:{object:h2d.Object, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			?savedFlowProps:Null<SavedFlowProperties>}, show:Bool, spec:TransitionType):Void {
		final obj = entry.object;
		final tm = tweenManager;
		if (tm == null) {
			if (show) addToGraph(entry); else removeFromGraph(entry);
			return;
		}

		// Capture pre-transition state for all properties (used by cancelActiveTransition to restore)
		final preAlpha = obj.alpha;
		final preScaleX = obj.scaleX;
		final preScaleY = obj.scaleY;
		final preX = obj.x;
		final preY = obj.y;

		switch (spec) {
			case TransFade(duration, easing):
				if (show) {
					addToGraph(entry);
					obj.alpha = 0.0;
					final t = tm.tween(obj, duration, [Alpha(preAlpha)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, duration, [Alpha(0.0)], easing);
					final capturedEntry = entry;
					t.onComplete = () -> {
						removeFromGraph(capturedEntry);
						capturedEntry.object.alpha = preAlpha;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransCrossfade(duration, easing):
				// Sequential: hide runs over `duration`, show waits `duration` then fades in.
				// Total visible transition = 2 * duration. The show branch uses a sequence
				// of [pause, fadeIn] so easing only applies to the fade-in phase — otherwise
				// non-linear easings skew the switchover point.
				if (show) {
					addToGraph(entry);
					obj.alpha = 0.0;
					final pause = tm.createTween(obj, duration, []);
					final fadeIn = tm.createTween(obj, duration, [Alpha(preAlpha)], easing);
					final seq = tm.sequence([pause, fadeIn]);
					trackTransitionSequence(obj, seq, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, duration, [Alpha(0.0)], easing);
					final capturedEntry = entry;
					t.onComplete = () -> {
						removeFromGraph(capturedEntry);
						capturedEntry.object.alpha = preAlpha;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransFlipX(duration, easing):
				// Sequential: hide shrinks over halfDuration, then show grows over
				// halfDuration. Total = duration. Show uses a [pause, grow] sequence so
				// it doesn't overlap the hide on the sibling element.
				final halfDuration = duration / 2.0;
				if (show) {
					addToGraph(entry);
					obj.scaleX = 0.0;
					final pause = tm.createTween(obj, halfDuration, []);
					final grow = tm.createTween(obj, halfDuration, [ScaleX(preScaleX)], easing);
					final seq = tm.sequence([pause, grow]);
					trackTransitionSequence(obj, seq, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, halfDuration, [ScaleX(0.0)], easing);
					final capturedEntry = entry;
					t.onComplete = () -> {
						removeFromGraph(capturedEntry);
						capturedEntry.object.scaleX = preScaleX;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransFlipY(duration, easing):
				final halfDuration = duration / 2.0;
				if (show) {
					addToGraph(entry);
					obj.scaleY = 0.0;
					final pause = tm.createTween(obj, halfDuration, []);
					final grow = tm.createTween(obj, halfDuration, [ScaleY(preScaleY)], easing);
					final seq = tm.sequence([pause, grow]);
					trackTransitionSequence(obj, seq, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, halfDuration, [ScaleY(0.0)], easing);
					final capturedEntry = entry;
					t.onComplete = () -> {
						removeFromGraph(capturedEntry);
						capturedEntry.object.scaleY = preScaleY;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransSlide(dir, duration, distance, easing):
				final slideOffset:Float = distance != null ? distance : 50.0;
				if (show) {
					addToGraph(entry);
					obj.alpha = 0.0;
					switch (dir) {
						case TDLeft: obj.x -= slideOffset;
						case TDRight: obj.x += slideOffset;
						case TDUp: obj.y -= slideOffset;
						case TDDown: obj.y += slideOffset;
					}
					final t = tm.tween(obj, duration, [X(preX), Y(preY), Alpha(preAlpha)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					var targetX = obj.x;
					var targetY = obj.y;
					switch (dir) {
						case TDLeft: targetX -= slideOffset;
						case TDRight: targetX += slideOffset;
						case TDUp: targetY -= slideOffset;
						case TDDown: targetY += slideOffset;
					}
					final t = tm.tween(obj, duration, [X(targetX), Y(targetY), Alpha(0.0)], easing);
					final capturedEntry = entry;
					t.onComplete = () -> {
						removeFromGraph(capturedEntry);
						capturedEntry.object.alpha = preAlpha;
						capturedEntry.object.x = preX;
						capturedEntry.object.y = preY;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransNone:
				if (show) addToGraph(entry); else removeFromGraph(entry);
		}
	}

	function findDeferred(obj:h2d.Object):Null<{
		wrapper:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
		gridCS:GridCoordinateSystem, hexCS:HexCoordinateSystem,
		internalResults:InternalBuilderResults, builderParams:BuilderParameters,
	}> {
		for (entry in deferredEntries)
			if (entry.wrapper == obj) return entry;
		return null;
	}

	function materializeDeferred(entry:{
		wrapper:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
		gridCS:GridCoordinateSystem, hexCS:HexCoordinateSystem,
		internalResults:InternalBuilderResults, builderParams:BuilderParameters,
	}):Void {
		// Build the deferred node's content into the wrapper (non-incremental, like repeatable rebuild).
		// Register a tracked expression to rebuild when referenced params change.
		entry.wrapper.removeChildren(); // Clear stale children from previous materialization
		rebuildDeferredContent(entry);
		// Collect param refs from node expressions for future rebuild tracking
		final paramRefs = builder.collectNodeParamRefs(entry.node);
		if (paramRefs.length > 0) {
			final capturedEntry = entry;
			trackedExpressions.push({
				updateFn: () -> {
					capturedEntry.wrapper.removeChildren();
					rebuildDeferredContent(capturedEntry);
				},
				paramRefs: paramRefs,
				object: entry.wrapper,
			});
		// Remove from deferred list — tracked expression handles future rebuilds
			deferredEntries.remove(entry);
		}
		// If no tracked expression, keep in deferredEntries so future show cycles re-materialize
	}

	function rebuildDeferredContent(entry:{
		wrapper:h2d.Object, node:Node,
		gridCS:GridCoordinateSystem, hexCS:HexCoordinateSystem,
		internalResults:InternalBuilderResults, builderParams:BuilderParameters,
	}):Void {
		builder.incrementalMode = false;
		builder.incrementalContext = null;
		builder.builderParams = entry.builderParams;
		builder.build(entry.node, ObjectMode(entry.wrapper), entry.gridCS, entry.hexCS, entry.internalResults, entry.builderParams);
		builder.incrementalMode = false;
		builder.incrementalContext = null;
	}

	@:nullSafety(Off)
	function rebuildDynamicNameRef(binding:DynamicNameBinding, newName:String):Void {
		// Remove old dynamic ref bindings that belonged to the previous child
		dynamicRefBindings = dynamicRefBindings.filter(b -> {
			// Remove bindings whose child context belongs to the old dynamicRef result
			final oldResult = binding.internalResults.dynamicRefs.get(binding.currentName);
			return oldResult == null || b.childContext != oldResult.incrementalContext;
		});

		// Clear the container
		binding.container.removeChildren();

		// Remove old entry from internalResults.dynamicRefs
		binding.internalResults.dynamicRefs.remove(binding.currentName);

		// Resolve the builder (external or local)
		var targetBuilder = if (binding.externalReference != null) {
			var b = builder.multiParserResult.imports?.get(binding.externalReference);
			if (b == null) throw BuilderError.of('could not find builder for external dynamicRef ${binding.externalReference}');
			b;
		} else builder;

		// Pass ReferenceableValue entries as Dynamic — buildWithParameters/updateIndexedParamsFromDynamicMap handles both
		final paramMap = new Map<String, Dynamic>();
		for (key => value in binding.parameters) {
			paramMap.set(key, cast value);
		}

		var result = targetBuilder.buildWithParameters(newName, paramMap, builderParams, indexedParams, true);
		if (result?.object == null)
			throw BuilderError.of('could not build dynamicRef "$newName"');

		binding.container.addChild(result.object);
		binding.currentName = newName;

		// Store the new result
		binding.internalResults.dynamicRefs.set(newName, result);

		// Re-register parameter bindings for the new child
		if (result.incrementalContext != null) {
			final childNode = targetBuilder.multiParserResult.nodes?.get(newName);
			final childDefs = childNode != null ? targetBuilder.getProgrammableParameterDefinitions(childNode) : new Map();
			for (childParam => value in binding.parameters) {
				final refs:Array<String> = [];
				MultiAnimBuilder.collectParamRefs(value, refs);
				if (refs.length > 0) {
					final capturedValue = value;
					final paramType = childDefs.get(childParam)?.type;
					final resolveFn:Void->Dynamic = switch paramType {
						case PPTString: () -> builder.resolveAsString(capturedValue);
						case PPTColor: () -> builder.resolveAsColorInteger(capturedValue);
						case PPTFloat: () -> builder.resolveAsNumber(capturedValue);
						default: () -> builder.resolveAsInteger(capturedValue);
					};
					trackDynamicRef(result.incrementalContext, childParam, resolveFn, refs, result.object);
				}
			}
		}
	}

	function setPresenceOrMaterialize(entry:{object:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			?savedFlowProps:Null<SavedFlowProperties>}, newVisible:Bool):Void {
		if (newVisible) {
			final deferred = findDeferred(entry.object);
			if (deferred != null && !isInGraph(entry.object)) {
				// First show or re-show after hide: materialize deferred content and add to graph
				addToGraph(entry);
				materializeDeferred(deferred);
				// Apply transition animation if configured
				final transSpec = findTransitionSpec(entry.node);
				if (transSpec != null && tweenManager != null && !transSpec.match(TransNone))
					executePresenceTransition(entry, true, transSpec);
				return;
			}
		}
		setPresenceWithTransition(entry, newVisible, entry.node);
	}

	function applyUpdates():Void {
		builder.pushBuilderState();
		builder.indexedParams = indexedParams;
		builder.builderParams = builderParams;

		// Re-evaluate presence for all conditional elements, including @else/@default
		// chain semantics. applyConditionalChains walks the full tree from rootNode
		// and handles Conditional, ConditionalElse, and ConditionalDefault for both
		// `conditionalEntries` (tracked objects) and `conditionalApplyEntries`
		// (sibling-scoped APPLY nodes) via uniqueNodeName lookup.
		//
		// A prior implementation ran a flat shouldBuildInFullMode() pass over conditionalEntries
		// and conditionalApplyEntries before this call. That was (a) redundant —
		// applyConditionalChains covers the same entries — and (b) wrong for
		// ConditionalElse/ConditionalDefault, since shouldBuildInFullMode() returns true for
		// them unconditionally (chain resolution happens only here). With a transition
		// spec active, the redundant pass could addToGraph an @else wrapper and
		// start a fade-in, then this pass would cancel it and start a fade-out,
		// leaving the wrapper in graph at alpha=savedAlpha for the fade duration
		// — a visible flash of an element whose chain decision never changed.
		applyConditionalChains();

		// Re-evaluate tracked expressions (skip for hidden objects)
		for (tracked in trackedExpressions) {
			// Skip expression evaluation for objects that are not effectively visible
			final obj = tracked.object;
			if (obj != null && !isEffectivelyVisible(obj))
				continue;
			var relevant = false;
			for (ref in tracked.paramRefs) {
				if (changedParams.exists(ref)) {
					relevant = true;
					break;
				}
			}
			if (relevant || !hasChanges) {
				tracked.updateFn();
			}
		}

		// Propagate to dynamic ref children. Skip bindings whose child subtree is not
		// effectively visible — same policy as trackedExpressions above. Propagating
		// into a detached subtree re-runs the child's applyUpdates (expression eval,
		// rebuild listeners) for something the user can't see.
		for (binding in dynamicRefBindings) {
			var relevant = false;
			for (ref in binding.referencedParams) {
				if (changedParams.exists(ref)) {
					relevant = true;
					break;
				}
			}
			if (!relevant) continue;
			final obj = binding.object;
			if (obj != null && !isEffectivelyVisible(obj)) continue;
			binding.childContext.setParameter(binding.childParam, binding.resolveFn());
		}

		// Rebuild dynamic name refs (template parameter changed)
		for (binding in dynamicNameBindings) {
			if (changedParams.exists(binding.paramName)) {
				final newName = builder.resolveAsString(RVReference(binding.paramName));
				if (newName != binding.currentName) {
					rebuildDynamicNameRef(binding, newName);
				}
			}
		}

		builder.popBuilderState();
		final firedRebuild = hasChanges;
		changedParams.clear();
		hasChanges = false;

		// Fire rebuild listeners AFTER state cleanup so listeners can safely call setParameter()
		// (re-entrancy enters a fresh applyUpdates cycle). Iterate over a snapshot in case a
		// listener removes itself or others during the callback.
		if (firedRebuild && rebuildListeners.length > 0) {
			final snapshot = rebuildListeners.copy();
			for (fn in snapshot) fn();
		}
	}

	public function applyConditionalChains():Void {
		// Walk the root node's children to resolve @else/@default chains with new params
		if (rootNode.children == null) return;
		// Build lookup maps keyed by uniqueNodeName for O(1) access in recursive walk
		final entryMap = new haxe.ds.StringMap<{object:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
			savedFlowProps:Null<SavedFlowProperties>}>();
		for (entry in conditionalEntries)
			entryMap.set(entry.node.uniqueNodeName, entry);
		final applyMap = new haxe.ds.StringMap<{parent:h2d.Object, node:Node, applied:Bool}>();
		for (ae in conditionalApplyEntries)
			applyMap.set(ae.node.uniqueNodeName, ae);
		resolveVisibilityForChildren(rootNode.children, entryMap, applyMap);
	}

	function resolveVisibilityForChildren(children:Array<Node>,
			entryMap:haxe.ds.StringMap<{object:h2d.Object, node:Node, sentinel:h2d.Object, parent:h2d.Object, layer:Int,
				savedFlowProps:Null<SavedFlowProperties>}>,
			applyMap:haxe.ds.StringMap<{parent:h2d.Object, node:Node, applied:Bool}>):Void {
		var prevSiblingMatched = false;
		var anyConditionalSiblingMatched = false;

		for (childNode in children) {
			// Find the tracked entry for this node via O(1) map lookup
			final nodeKey = childNode.uniqueNodeName;
			var trackedEntry = entryMap.get(nodeKey);
			// Find conditional apply entry for this node (APPLY nodes have no tracked object)
			var trackedApply = if (trackedEntry == null) applyMap.get(nodeKey) else null;

			switch childNode.conditionals {
				case Conditional(conditions, anyMode):
					var matched = builder.matchConditions(conditions, anyMode, indexedParams);
					prevSiblingMatched = matched;
					if (matched) anyConditionalSiblingMatched = true;
					if (trackedEntry != null) setPresenceOrMaterialize(trackedEntry, matched);
					if (trackedApply != null) {
						if (matched) applyConditionalApplyEntry(trackedApply);
						else unapplyConditionalApplyEntry(trackedApply);
					}

				case ConditionalElse(extraConditions):
					if (!prevSiblingMatched) {
						if (extraConditions == null) {
							prevSiblingMatched = true;
							anyConditionalSiblingMatched = true;
							if (trackedEntry != null) setPresenceOrMaterialize(trackedEntry, true);
							if (trackedApply != null) applyConditionalApplyEntry(trackedApply);
						} else {
							var matched = builder.matchConditions(extraConditions, false, indexedParams);
							prevSiblingMatched = matched;
							if (matched) anyConditionalSiblingMatched = true;
							if (trackedEntry != null) setPresenceOrMaterialize(trackedEntry, matched);
							if (trackedApply != null) {
								if (matched) applyConditionalApplyEntry(trackedApply);
								else unapplyConditionalApplyEntry(trackedApply);
							}
						}
					} else {
						prevSiblingMatched = true;
						if (trackedEntry != null) setPresenceOrMaterialize(trackedEntry, false);
						if (trackedApply != null) unapplyConditionalApplyEntry(trackedApply);
					}

				case ConditionalDefault:
					if (trackedEntry != null) setPresenceOrMaterialize(trackedEntry, !anyConditionalSiblingMatched);
					if (trackedApply != null) {
						if (!anyConditionalSiblingMatched) applyConditionalApplyEntry(trackedApply);
						else unapplyConditionalApplyEntry(trackedApply);
					}
					anyConditionalSiblingMatched = false;

				case NoConditional:
					prevSiblingMatched = false;
					anyConditionalSiblingMatched = false;
					// Unconditional apply entries are always applied; reconcile so
					// param-dependent expressions inside `apply { ... }` re-evaluate.
					if (trackedApply != null)
						reconcileApplyParent(trackedApply.parent);
			}

			// Recurse into children
			if (childNode.children != null && childNode.children.length > 0)
				resolveVisibilityForChildren(childNode.children, entryMap, applyMap);
		}
	}
}

@:nullSafety
class SlotContentRoot extends h2d.Object {}

@:nullSafety
enum SlotKey {
	Named(name:String);
	Indexed(name:String, index:Int);
	Indexed2D(name:String, indexX:Int, indexY:Int);
}

@:nullSafety
class SlotHandle {
	public var container:h2d.Object;
	public var data:Dynamic = null;
	public var incrementalContext:Null<IncrementalUpdateContext> = null;
	// Flipped to true by removeRegistrationsUnder when the slot's enclosing subtree
	// is torn down (SWITCH arm swap, repeatable shrinkage, ...). The IR entry is
	// evicted from ir.slots at the same site, but callers may still hold the
	// handle. setParameter checks this flag and throws — silently mutating the
	// now-stale incrementalContext would flip visibility on detached h2d.Objects
	// and leave the rendered state inconsistent with the logical param map.
	public var disposed:Bool = false;

	var defaultChildren:Array<h2d.Object>;
	var currentContent:Null<h2d.Object>;
	var contentRoot:Null<h2d.Object> = null;
	var contentTarget:Null<h2d.Object> = null;
	var hasParameters:Bool = false;

	public function new(container:h2d.Object, ?incrementalContext:IncrementalUpdateContext, ?contentTarget:h2d.Object) {
		this.container = container;
		this.contentTarget = contentTarget;
		this.defaultChildren = [];
		this.currentContent = null;
		for (i in 0...container.numChildren)
			this.defaultChildren.push(container.getChildAt(i));
		if (incrementalContext != null) {
			this.incrementalContext = incrementalContext;
			this.hasParameters = true;
			if (contentTarget == null) {
				this.contentRoot = new h2d.Object();
				container.addChild(this.contentRoot);
			}
		}
	}

	public function setContent(obj:h2d.Object):Void {
		clear();
		if (contentTarget != null) {
			currentContent = obj;
			contentTarget.addChild(obj);
		} else if (hasParameters && contentRoot != null) {
			currentContent = obj;
			contentRoot.addChild(obj);
		} else {
			for (child in defaultChildren)
				child.visible = false;
			currentContent = obj;
			container.addChild(obj);
		}
	}

	public function clear():Void {
		if (currentContent != null) {
			if (contentTarget != null) {
				contentTarget.removeChild(currentContent);
			} else if (hasParameters && contentRoot != null) {
				contentRoot.removeChild(currentContent);
			} else {
				container.removeChild(currentContent);
			}
			currentContent = null;
		}
		if (!hasParameters && contentTarget == null) {
			for (child in defaultChildren)
				child.visible = true;
		}
	}

	public function getContent():Null<h2d.Object> {
		return currentContent;
	}

	public function isEmpty():Bool {
		return currentContent == null;
	}

	public function isOccupied():Bool {
		return currentContent != null;
	}

	public function setParameter(name:String, value:Dynamic):Void {
		if (disposed)
			throw BuilderError.of('Slot disposed — enclosing subtree was rebuilt', "slot_disposed");
		if (incrementalContext == null)
			throw BuilderError.of('Slot has no parameters', "slot_no_parameters");
		incrementalContext.setParameter(name, value);
	}

	public function getScreenBounds():h2d.col.Bounds {
		return container.getBounds();
	}
}

@:nullSafety
@:structInit
class BuilderResult implements bh.ui.UIInteractiveSource {
	public var object:Object;
	public var name:String;
	public var names:Map<String, Array<NamedBuildResult>>;
	public var interactives:Array<MAObject>;
	public var layouts:Map<String, MultiAnimLayouts>;
	public var palettes:Map<String, Palette>;
	public var rootSettings:BuilderResolvedSettings;
	public var gridCoordinateSystem:Null<GridCoordinateSystem>;
	public var hexCoordinateSystem:Null<HexCoordinateSystem>;
	public var slots:Array<{key:SlotKey, handle:SlotHandle}>;
	public var dynamicRefs:Map<String, BuilderResult>;
	public var incrementalContext:Null<IncrementalUpdateContext>;
	public var htmlTextsWithLinks:Null<Array<h2d.HtmlText>>;
	#if MULTIANIM_DEV
	public var reloadable:Bool = true;
	public var reloadHandle:Null<bh.multianim.dev.HotReload.ReloadableHandle> = null;
	public var onReload:Null<(BuilderResult, bh.multianim.dev.HotReload.ReloadReport) -> Void> = null;
	// Stored for hot reload: allows rebuilding with same callback/placeholderObjects
	// even when original build was not incremental.
	public var devBuilderParams:Null<BuilderParameters> = null;
	// Captured placeholder objects for hot reload reuse
	public var devCapturedPlaceholders:Array<{name:String, index:Null<Int>, object:h2d.Object}> = [];

	// Adopt internals from another result, keeping this instance as the stable reference.
	// The scene graph object is swapped via SceneSwapper (caller responsibility).
	public function adoptFrom(other:BuilderResult):Void {
		// Preserve TweenManager reference across hot reload
		final prevTweenManager = if (this.incrementalContext != null) this.incrementalContext.tweenManager else null;
		this.object = other.object;
		this.name = other.name;
		this.names = other.names;
		this.interactives = other.interactives;
		this.layouts = other.layouts;
		this.palettes = other.palettes;
		this.rootSettings = other.rootSettings;
		this.gridCoordinateSystem = other.gridCoordinateSystem;
		this.hexCoordinateSystem = other.hexCoordinateSystem;
		this.slots = other.slots;
		this.dynamicRefs = other.dynamicRefs;
		this.incrementalContext = other.incrementalContext;
		this.htmlTextsWithLinks = other.htmlTextsWithLinks;
		this.devBuilderParams = other.devBuilderParams;
		this.devCapturedPlaceholders = other.devCapturedPlaceholders;
		// Re-inject TweenManager into new incremental context
		if (prevTweenManager != null && this.incrementalContext != null)
			this.incrementalContext.setTweenManager(prevTweenManager);
	}
	#end

	public function setTweenManager(tm:TweenManager):Void {
		if (incrementalContext == null)
			throw BuilderError.of('setTweenManager requires incremental mode');
		incrementalContext.setTweenManager(tm);
	}

	/** `UIInteractiveSource` implementation — returns a copy of the tracked interactives list.
	 *  The copy protects callers from mutations that may happen during structural rebuilds. */
	public function getInteractives():Array<bh.base.MAObject> {
		return interactives.copy();
	}

	/** `UIInteractiveSource` — true when this BuilderResult was built with `incremental: true`.
	 *  Static snapshots return false and cannot service rebuild listeners or `setParameter`. */
	public var isIncremental(get, never):Bool;
	inline function get_isIncremental():Bool return incrementalContext != null;

	/** `UIInteractiveSource` — register a listener fired after each rebuild cycle (parameter change
	 *  processed). Use to resync external state — e.g. screen-side wrapper maps after a `@switch`
	 *  arm flip. Throws on non-incremental results: callers must gate with `isIncremental` so that
	 *  the mismatch surfaces at wiring time instead of letting dependent `setParameter` calls blow
	 *  up later. */
	public function addRebuildListener(fn:Void -> Void):Void {
		if (incrementalContext == null)
			throw BuilderError.of('addRebuildListener requires incremental mode — gate on `isIncremental` or pass incremental:true to buildWithParameters');
		incrementalContext.addRebuildListener(fn);
	}

	/** Remove a previously-added rebuild listener. Throws on non-incremental (symmetric with
	 *  `addRebuildListener`). */
	public function removeRebuildListener(fn:Void -> Void):Void {
		if (incrementalContext == null)
			throw BuilderError.of('removeRebuildListener requires incremental mode');
		incrementalContext.removeRebuildListener(fn);
	}

	public function setParameter(name:String, value:Dynamic):Void {
		if (incrementalContext == null)
			throw BuilderError.of('setParameter requires incremental mode — pass incremental:true to buildWithParameters');
		incrementalContext.setParameter(name, value);
	}

	public function beginUpdate():Void {
		if (incrementalContext == null)
			throw BuilderError.of('beginUpdate requires incremental mode');
		incrementalContext.beginUpdate();
	}

	public function endUpdate():Void {
		if (incrementalContext == null)
			throw BuilderError.of('endUpdate requires incremental mode');
		incrementalContext.endUpdate();
	}

	public function getNodeSettings(elementName:String):ResolvedSettings {
		final results = names[elementName];
		if (results == null || results.length != 1)
			throw BuilderError.of('Could not get single node for name $elementName');
		final settings = results[0].settings;
		if (settings == null)
			throw BuilderError.of('no settings specified for $elementName');
		return settings;
	}

	public function getSingleItemByName(name:String):NamedBuildResult {
		var items = this.names[name];
		if (items == null)
			throw BuilderError.of('builder result name ${name} not found');
		if (items.length != 1)
			throw BuilderError.of('builder result name ${name} expected single item but got ${items.length}');
		return items[0];
	}

	public function getUpdatable(name) {
		final namesArray = names[name];
		if (namesArray == null)
			throw BuilderError.of('Name ${name} not found in BuilderResult');
		return new Updatable(namesArray);
	}

	public function hasName(name:String):Bool {
		return names.exists(name);
	}

	public function hasNameByIndex(name:String, index:Int):Bool {
		return names.exists('${name} ${index}');
	}

	public function getUpdatableByIndex(name:String, index:Int):Updatable {
		return getUpdatable('${name} ${index}');
	}

	public function getDynamicRef(name:String):BuilderResult {
		if (dynamicRefs == null)
			throw BuilderError.of('No dynamicRefs in BuilderResult');
		final ref = dynamicRefs.get(name);
		if (ref == null)
			throw BuilderError.of('DynamicRef "$name" not found in BuilderResult');
		return ref;
	}

	public function getSlot(name:String, ?index:Null<Int>, ?indexY:Null<Int>):SlotHandle {
		if (slots == null)
			throw BuilderError.of('No slots in BuilderResult');
		// Determine what kind of slot this is
		var is1DIndexed = false;
		var is2DIndexed = false;
		for (entry in slots) {
			switch entry.key {
				case Indexed(n, _) if (n == name):
					is1DIndexed = true;
					break;
				case Indexed2D(n, _, _) if (n == name):
					is2DIndexed = true;
					break;
				default:
			}
		}
		if (is2DIndexed) {
			if (index == null || indexY == null)
				throw BuilderError.of('Slot "$name" is 2D-indexed — use getSlot("$name", x, y)');
			for (entry in slots) {
				switch entry.key {
					case Indexed2D(n, ix, iy) if (n == name && ix == index && iy == indexY):
						return entry.handle;
					default:
				}
			}
			throw BuilderError.of('Slot "$name" index ($index, $indexY) not found');
		} else if (is1DIndexed) {
			if (index == null)
				throw BuilderError.of('Slot "$name" is indexed — use getSlot("$name", index)');
			for (entry in slots) {
				switch entry.key {
					case Indexed(n, i) if (n == name && i == index):
						return entry.handle;
					default:
				}
			}
			throw BuilderError.of('Slot "$name" index $index not found');
		} else {
			if (index != null)
				throw BuilderError.of('Slot "$name" is not indexed — use getSlot("$name") without index');
			for (entry in slots) {
				switch entry.key {
					case Named(n) if (n == name):
						return entry.handle;
					default:
				}
			}
			throw BuilderError.of('Slot "$name" not found in BuilderResult');
		}
	}
}

@:nullSafety
enum CallbackRequest {
	Name(name:String); // called when used in expression
	NameWithIndex(name:String, index:Int); // called when used in expression
	Placeholder(name:String); // called when used in placeholder
	PlaceholderWithIndex(name:String, index:Int); // when used in placeholder
}

@:nullSafety
enum CallbackResult {
	CBRInteger(val:Int);
	CBRFloat(val:Float);
	CBRString(val:String);
	CBRObject(val:h2d.Object);
	CBRNoResult; // for default behaviors, e.g. for example of PLACEHOLDER
}

@:nullSafety
enum PlaceholderValues {
	PVObject(obj:h2d.Object);
	PVFactory(factoryMethod:ResolvedSettings->h2d.Object);
	/** Higher-order component (e.g. Grid). Factory returns scene graph object, component holds the typed reference. */
	PVComponent(factoryMethod:ResolvedSettings->h2d.Object, component:Dynamic);
}

@:nullSafety
typedef BuilderParameters = {
	var ?callback:BuilderCallbackFunction;
	var ?placeholderObjects:Map<String, PlaceholderValues>;
	var ?scene:h2d.Scene;
}

@:nullSafety
private enum InternalBuildMode {
	RootMode;
	ObjectMode(current:h2d.Object);
	LayersMode(current:h2d.Layers);
	TileGroupMode(tg:h2d.TileGroup);
}

@:nullSafety
typedef BuilderCallbackFunction = CallbackRequest->CallbackResult;

@:nullSafety
private typedef InternalBuilderResults = {
	names:Map<String, Array<NamedBuildResult>>,
	interactives:Array<MAObject>,
	slots:Array<{key:SlotKey, handle:SlotHandle}>,
	dynamicRefs:Map<String, BuilderResult>,
	htmlTextsWithLinks:Array<h2d.HtmlText>
}

/** Persistent sink for results produced inside a @switch arm. One instance per switch ordinal in a codegen
 *  programmable instance; passed to rebuildSwitchArmByOrdinal so indexed names, slots, interactives, and
 *  dynamicRefs declared inside arms remain addressable after the initial build and after arm swaps. */
@:nullSafety
class SwitchArmResults {
	@:allow(bh.multianim.MultiAnimBuilder)
	var ir:InternalBuilderResults;

	public function new() {
		ir = {names: new Map(), interactives: [], slots: [], dynamicRefs: new Map(), htmlTextsWithLinks: []};
	}

	public function getUpdatable(name:String):Null<h2d.Object> {
		final arr = ir.names.get(name);
		if (arr == null || arr.length == 0) return null;
		return MultiAnimParser.toh2dObject(arr[0].object);
	}

	public function getUpdatableByIndex(name:String, index:Int):Null<h2d.Object> {
		return getUpdatable('${name} ${index}');
	}

	public function getUpdatable2D(name:String, x:Int, y:Int):Null<h2d.Object> {
		return getUpdatable('${name} ${x} ${y}');
	}

	public function getSlot(name:String, ?index:Null<Int>, ?indexY:Null<Int>):Null<SlotHandle> {
		for (entry in ir.slots) {
			final match = switch entry.key {
				case Named(n): index == null && indexY == null && n == name;
				case Indexed(n, i): index != null && indexY == null && n == name && i == index;
				case Indexed2D(n, ix, iy): index != null && indexY != null && n == name && ix == index && iy == indexY;
			};
			if (match) return entry.handle;
		}
		return null;
	}
}

@:nullSafety
private typedef StoredBuilderState = {
	indexedParams:Map<String, ResolvedIndexParameters>,
	builderParams:BuilderParameters,
	currentNode:Null<Node>,
	incrementalMode:Bool,
	incrementalContext:Null<IncrementalUpdateContext>,
	currentInternalResults:Null<InternalBuilderResults>,
}

@:nullSafety

@:allow(bh.multianim.layouts.MultiAnimLayouts)
@:allow(bh.paths.MultiAnimPaths)
@:allow(bh.paths.AnimatedPath)
@:allow(bh.multianim.MultiAnimParser)
@:allow(bh.multianim.ProgrammableBuilder)
@:allow(bh.multianim.IncrementalUpdateContext)
class MultiAnimBuilder {
	final resourceLoader:bh.base.ResourceLoader;
	public final sourceName:String;
	var multiParserResult:MultiAnimResult;

	/** 1x1 transparent tile shared across all builders, used as fallback for unresolvable tile params in incremental mode. */
	static var incrementalFallbackTile:Null<h2d.Tile> = null;

	var indexedParams:Map<String, ResolvedIndexParameters> = [];
	var builderParams:BuilderParameters = {};
	var currentNode:Null<Node> = null;
	var stateStack:Array<StoredBuilderState> = [];
	var inlineAtlases:Map<String, IAtlas2> = [];
	var incrementalMode:Bool = false;
	var incrementalContext:Null<IncrementalUpdateContext> = null;
	var currentInternalResults:Null<InternalBuilderResults> = null;
	/** When set, automatically injected into IncrementalUpdateContext for transition support. */
	public var tweenManager:Null<TweenManager> = null;
	#if MULTIANIM_DEV
	var devPlaceholderCapture:Array<{name:String, index:Null<Int>, object:h2d.Object}> = [];
	#end

	/** Returns position string for error messages when MULTIANIM_DEV is enabled */
	inline function currentNodePos():String {
		#if MULTIANIM_DEV
		return if (currentNode != null) ' at ${currentNode.parserPos}' else '';
		#else
		return '';
		#end
	}

	/** Constructs a `BuilderError` tagged with the current node (for source
	 *  position) and an optional `code` for programmatic filtering. Prefer
	 *  this over raw `throw 'message' + currentNodePos()` in new code. */
	inline function builderError(message:String, ?code:String):BuilderError
		return new BuilderError(message, currentNode, code);

	/** Like `builderError` but tags an explicit node — use at sites that
	 *  previously did `throw 'msg' + MacroUtils.nodePos(node)` where the node
	 *  in scope is not `currentNode` (e.g. macro-codegen helpers walking a
	 *  passed-in subtree). */
	inline function builderErrorAt(node:Null<Node>, message:String, ?code:String):BuilderError
		return new BuilderError(message, node, code);

	public function toString():String {
		return 'MultiAnimBuilder( multiParserResult: ${multiParserResult.nodes.keys()}, indexedParams: ${indexedParams}, builderParams: ${builderParams}, currentNode: ${currentNode}, stateStack: ${stateStack.length} items)';
	}

	private function new(data, resourceLoader, sourceName) {
		this.multiParserResult = data;
		this.resourceLoader = resourceLoader;
		this.sourceName = sourceName;
	}

	public function createElementBuilder(name:String) {
		return new UIElementBuilder(this, name);
	}

	function popBuilderState() {
		final state = stateStack.pop();
		if (state == null)
			throw builderError('builder state stack is empty, sourceName: ${sourceName}');

		this.indexedParams = state.indexedParams;
		this.builderParams = state.builderParams;
		this.currentNode = state.currentNode;
		this.incrementalMode = state.incrementalMode;
		this.incrementalContext = state.incrementalContext;
		this.currentInternalResults = state.currentInternalResults;
	}

	function pushBuilderState() {
		stateStack.push({
			indexedParams: this.indexedParams,
			builderParams: this.builderParams,
			currentNode: this.currentNode,
			incrementalMode: this.incrementalMode,
			incrementalContext: this.incrementalContext,
			currentInternalResults: this.currentInternalResults,
		});
		this.indexedParams = [];
		this.builderParams = {};
		this.currentNode = null;
	}

	/** Remove from `ir` any registration whose underlying h2d.Object is `container` itself or a descendant of it.
	 *  Used by SWITCH/REPEAT rebuild closures to drop stale entries from the previous arm/iteration before
	 *  rebuilding into the same container. Must be called BEFORE container.removeChildren() so parent links
	 *  are still intact for the descendant walk. */
	private static function removeRegistrationsUnder(ir:InternalBuilderResults, container:h2d.Object):Void {
		function isUnder(obj:Null<h2d.Object>):Bool {
			if (obj == null) return false;
			if (obj == container) return true;
			var p = obj.parent;
			while (p != null) {
				if (p == container) return true;
				p = p.parent;
			}
			return false;
		}

		// interactives: MAObject extends h2d.Object directly
		var i = 0;
		while (i < ir.interactives.length) {
			if (isUnder(ir.interactives[i])) ir.interactives.splice(i, 1);
			else i++;
		}

		// slots: handle.container is the slot's h2d.Object. Mark the handle
		// disposed before evicting — external callers still holding the
		// SlotHandle reference will get a loud BuilderError on setParameter
		// instead of silently mutating orphaned h2d.Objects via a stale
		// incrementalContext.
		var s = 0;
		while (s < ir.slots.length) {
			if (isUnder(ir.slots[s].handle.container)) {
				ir.slots[s].handle.disposed = true;
				ir.slots.splice(s, 1);
			} else s++;
		}

		// dynamicRefs: each value's .object is the embedded result's h2d.Object
		final keysToRemove:Array<String> = [];
		for (key => result in ir.dynamicRefs) {
			if (isUnder(result.object)) keysToRemove.push(key);
		}
		for (k in keysToRemove) ir.dynamicRefs.remove(k);

		// names: each NamedBuildResult.object is a BuiltHeapsComponent enum wrapping an h2d.Object
		final namesToRemove:Array<String> = [];
		for (name => arr in ir.names) {
			var ni = 0;
			while (ni < arr.length) {
				final entryObj = MultiAnimParser.toh2dObject(arr[ni].object);
				if (isUnder(entryObj)) arr.splice(ni, 1);
				else ni++;
			}
			if (arr.length == 0) namesToRemove.push(name);
		}
		for (n in namesToRemove) ir.names.remove(n);

		// htmlTextsWithLinks: each is h2d.HtmlText extends h2d.Object
		var h = 0;
		while (h < ir.htmlTextsWithLinks.length) {
			if (isUnder(ir.htmlTextsWithLinks[h])) ir.htmlTextsWithLinks.splice(h, 1);
			else h++;
		}
	}

	public static function load(byteData, resourceLoader, sourceName) {
		var parsed = MultiAnimParser.parseFile(byteData, sourceName, resourceLoader);
		return new MultiAnimBuilder(parsed, resourceLoader, sourceName);
	}

	function evaluateAndStoreFinal(name:String, expr:ReferenceableValue, node:Node):Void {
		final existing = indexedParams.get(name);
		if (existing != null) {
			switch existing {
				case ExpressionAlias(_): // Allow overwrite (repeatable re-iteration of same @final)
				default:
					throw builderErrorAt(node, '@final: \'$name\' shadows an existing parameter');
			}
		}
		indexedParams.set(name, ExpressionAlias(expr));
	}

	static function cleanupFinalVars(children:Array<Node>, indexedParams:Map<String, ResolvedIndexParameters>):Void {
		for (childNode in children) {
			switch childNode.type {
				case FINAL_VAR(name, _): indexedParams.remove(name);
				default:
			}
		}
	}

	function resolveAsArrayElement(v:ReferenceableValue):Dynamic {
		switch v {
			case RVElementOfArray(arrayRef, indexRef):
				final arrayVal = indexedParams.get(arrayRef);

				switch arrayVal {
					case ArrayString(arrayVal):
						var index = resolveAsInteger(indexRef);
						if (index < 0 || index >= arrayVal.length)
							throw builderError('index out of bounds ${index} for array ${arrayVal.toString()}');
						return arrayVal[index];
					case null: throw builderError('array reference ${arrayRef}[$indexRef] does not exist', "missing_ref");
					default: throw builderError('element of array reference ${arrayRef}[$indexRef] is not an array but ${arrayRef}');
				}
				case RVTernary(condition, ifTrue, ifFalse):
					return if (resolveAsBool(condition)) resolveAsArrayElement(ifTrue) else resolveAsArrayElement(ifFalse);
			default:
				throw builderError('expected array element but got ${v}');
		}
	}

	function resolveAsArray(v:ReferenceableValue):Dynamic {
		switch v {
			case RVArray(array):
				return [for (v in array) resolveAsString(v)];
			case RVArrayReference(refArr):
				final arrayVal = indexedParams.get(refArr);
				switch arrayVal {
					case ArrayString(strArray): return strArray;
					case ExpressionAlias(expr): return resolveAsArray(expr);
					default: throw builderError('array reference ${refArr} is not an array but ${arrayVal}');
				}
			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsArray(ifTrue) else resolveAsArray(ifFalse);
			default:
				throw builderError('expected array but got ${v}');
		}
	}

	function collectStateAnimFrames(animFilename:String, animationName:String, selector:Map<String, String>):Array<TileSource> {
		final animParser = resourceLoader.loadAnimParser(animFilename);
		final animSM = animParser.createAnimSM(selector);
		final descriptor = animSM.animationStates.get(animationName);
		if (descriptor == null) {
			throw builderError('animation "${animationName}" not found in "${animFilename}"', "missing_ref");
		}
		var result:Array<TileSource> = [];
		for (state in descriptor.states) {
			switch state {
				case Frame(frame):
					if (frame.tile != null) {
						result.push(TSTile(frame.tile));
					}
				case _: // Skip non-frame states (loops, events, etc.)
			}
		}
		return result;
	}

	function resolveAsColorInteger(v:ReferenceableValue):Int {
		function getBuilderWithExternal(externalReference:Null<String>) {
			if (externalReference == null)
				return this;
			var builder = multiParserResult.imports.get(externalReference);
			if (builder == null)
				throw builderError('could not find builder for external reference ${externalReference}', "missing_ref");
			return builder;
		}

		return switch v {
			case RVInteger(i): i;
			case RVString(s):
				final c = MacroManimParser.tryStringToColor(s);
				if (c != null) return c;
				final parsed = Std.parseInt(s);
				if (parsed != null) return parsed;
				throw builderError('cannot resolve color from string "$s"');
			case RVColorXY(externalReference, name, x, y):
				var builder = getBuilderWithExternal(externalReference);
				var palette = builder.getPalette(name);
				palette.getColor2D(resolveAsInteger(x), resolveAsInteger(y));
			case RVColor(externalReference, name, index):
				var builder = getBuilderWithExternal(externalReference);
				var palette = builder.getPalette(name);
				palette.getColorByIndex(resolveAsInteger(index));
			case RVReference(_): resolveAsInteger(v);

			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsColorInteger(ifTrue) else resolveAsColorInteger(ifFalse);

			default: throw builderError('expected color to resolve, got $v');
		}
	}

	function resolveRVPropertyAccess(ref:String, property:String):Float {
		switch (ref) {
			case "ctx":
				switch (property) {
					case "width":
						final scene = builderParams.scene;
						if (scene == null) throw builderError('$$ctx.width requires scene in BuilderParameters');
						return scene.width;
					case "height":
						final scene = builderParams.scene;
						if (scene == null) throw builderError('$$ctx.height requires scene in BuilderParameters');
						return scene.height;
					default: throw builderError('$ref.$property is not a known context property');
				}
			case "grid" | "ctx.grid":
				final node = currentNode;
				if (node == null) throw builderError('currentNode is null in resolveRVPropertyAccess');
				final gcs = MultiAnimParser.getGridCoordinateSystem(node);
				if (gcs == null) throw builderError('no grid coordinate system in scope for $ref.$property');
				switch (property) {
					case "width": return gcs.spacingX;
					case "height": return gcs.spacingY;
					default: throw builderError('$ref.$property is not a known grid property');
				}
			case "hex" | "ctx.hex":
				final node = currentNode;
				if (node == null) throw builderError('currentNode is null in resolveRVPropertyAccess');
				final hcs = MultiAnimParser.getHexCoordinateSystem(node);
				if (hcs == null) throw builderError('no hex coordinate system in scope for $ref.$property');
				switch (property) {
					case "width": return hcs.hexLayout.size.x;
					case "height": return hcs.hexLayout.size.y;
					default: throw builderError('$ref.$property is not a known hex property');
				}
			default:
				// Check named coordinate systems
				final node = currentNode;
				if (node == null) throw builderError('currentNode is null in resolveRVPropertyAccess');
				final namedCS = MultiAnimParser.getNamedCoordinateSystem(ref, node);
				if (namedCS != null) {
					switch (namedCS) {
						case NamedGrid(system):
							switch (property) {
								case "width": return system.spacingX;
								case "height": return system.spacingY;
								default: throw builderError('$ref.$property is not a known grid property');
							}
						case NamedHex(system):
							switch (property) {
								case "width": return system.hexLayout.size.x;
								case "height": return system.hexLayout.size.y;
								default: throw builderError('$ref.$property is not a known hex property');
							}
					}
				}
				throw builderError('unknown reference $ref for property access .$property');
		}
	}

	function resolveRVMethodCall(ref:String, method:String, args:Array<ReferenceableValue>):Float {
		switch (ref) {
			case "ctx":
				switch (method) {
					case "random":
						if (args.length != 2) throw builderError('$ref.$method() requires 2 arguments (min, max)');
						final min = resolveAsInteger(args[0]);
						final max = resolveAsInteger(args[1]);
						return min + Std.random(max - min);
					case "font":
						throw builderError('$$ctx.font() must be followed by .lineHeight or .baseLine');
					default: throw builderError('$ref.$method() is not a known context method');
				}
			default:
				throw builderError('unknown reference $ref for method call .$method()');
		}
	}

	/** Resolves a coordinate method call ($hex.corner(), $hex.edge(), $hex.cube(), $grid.pos(), $ref.extraPoint(), etc.) to an FPoint. */
	function resolveRVMethodCallToPoint(ref:String, method:String, args:Array<ReferenceableValue>):FPoint {
		final node = currentNode;
		if (node == null) throw builderError('currentNode is null in resolveRVMethodCallToPoint');
		// $ref.extraPoint("pointName" [, fallbackX, fallbackY]) — resolve extra point from named stateanim element
		if (method == "extraPoint") {
			if (args.length < 1) throw builderError('$$$ref.extraPoint() requires at least 1 argument (pointName)');
			final pointName = resolveAsString(args[0]);
			final fallback = if (args.length >= 3) OFFSET(args[1], args[2]) else null;
			return resolveExtraPointRef(ref, pointName, fallback, null, null);
		}
		final namedCS = if (ref != "grid" && ref != "ctx.grid" && ref != "hex" && ref != "ctx.hex") MultiAnimParser.getNamedCoordinateSystem(ref, node) else null;
		final isNamedGrid = switch (namedCS) { case NamedGrid(_): true; default: false; };
		// Grid methods
		if (ref == "grid" || ref == "ctx.grid" || isNamedGrid) {
			final gcs = if (ref == "grid" || ref == "ctx.grid") {
				MultiAnimParser.getGridCoordinateSystem(node);
			} else {
				switch (namedCS) {
					case NamedGrid(system): system;
					default: null;
				}
			};
			if (gcs == null) throw builderError('no grid coordinate system in scope for $$$ref.$method()');
			switch (method) {
				case "pos":
					if (args.length < 2) throw builderError('$$$ref.pos() requires at least 2 arguments (x, y)');
					final x = resolveAsInteger(args[0]);
					final y = resolveAsInteger(args[1]);
					if (args.length >= 4) {
						final ox = resolveAsInteger(args[2]);
						final oy = resolveAsInteger(args[3]);
						return gcs.resolveAsGrid(x, y, ox, oy);
					}
					return gcs.resolveAsGrid(x, y);
				default: throw builderError('$$$ref.$method() is not a known grid method');
			}
		}

		// Hex methods
		final hcs = if (ref == "hex" || ref == "ctx.hex") {
			MultiAnimParser.getHexCoordinateSystem(node);
		} else {
			switch (namedCS) {
				case NamedHex(system): system;
				default: null;
			}
		};
		if (hcs == null) throw builderError('no hex coordinate system in scope for $$$ref.$method()');

		switch (method) {
			case "corner":
				if (args.length < 1) throw builderError('$$$ref.corner() requires at least 1 argument (index)');
				final idx = resolveAsInteger(args[0]);
				final factor = if (args.length >= 2) resolveAsNumber(args[1]) else 1.0;
				return hcs.resolveAsHexCorner(idx, factor);
			case "edge":
				if (args.length < 1) throw builderError('$$$ref.edge() requires at least 1 argument (direction)');
				final dir = resolveAsInteger(args[0]);
				final factor = if (args.length >= 2) resolveAsNumber(args[1]) else 1.0;
				return hcs.resolveAsHexEdge(dir, factor);
			case "cube":
				if (args.length != 3) throw builderError('$$$ref.cube() requires 3 arguments (q, r, s)');
				return hcs.resolveHexCube(resolveAsNumber(args[0]), resolveAsNumber(args[1]), resolveAsNumber(args[2]));
			case "offset":
				if (args.length < 2) throw builderError('$$$ref.offset() requires at least 2 arguments (col, row)');
				final parity:OffsetParity = if (args.length >= 3) {
					final p = resolveAsString(args[2]);
					switch (p) { case "even": EVEN; case "odd": ODD; default: throw builderError('Expected "even" or "odd", got: $p'); }
				} else EVEN;
				return hcs.resolveHexOffset(resolveAsInteger(args[0]), resolveAsInteger(args[1]), parity);
			case "doubled":
				if (args.length != 2) throw builderError('$$$ref.doubled() requires 2 arguments (col, row)');
				return hcs.resolveHexDoubled(resolveAsInteger(args[0]), resolveAsInteger(args[1]));
			case "pixel":
				if (args.length != 2) throw builderError('$$$ref.pixel() requires 2 arguments (x, y)');
				return hcs.resolveHexPixel(resolveAsNumber(args[0]), resolveAsNumber(args[1]));
			default: throw builderError('$$$ref.$method() is not a known hex method');
		}
	}

	/** Resolves RVChainedMethodCall for .x/.y extraction from coordinate methods and font property access. */
	function resolveRVChainedMethodCall(base:ReferenceableValue, property:String):Float {
		// Font property access: $ctx.font("name").lineHeight / .baseLine
		if (property == "lineHeight" || property == "baseLine") {
			switch (base) {
				case RVMethodCall(ref, method, args):
					if (ref == "ctx" && method == "font") {
						if (args.length != 1) throw builderError('$$ctx.font() requires 1 argument (font name)');
						final fontName = resolveAsString(args[0]);
						final font = resourceLoader.loadFont(fontName);
						return if (property == "lineHeight") font.lineHeight else font.baseLine;
					}
				default:
			}
			throw builderError('unsupported base expression for .$property — use $$ctx.font("name").$property');
		}

		if (property != "x" && property != "y")
			throw builderError('unsupported chained property .$property — only .x, .y, .lineHeight, .baseLine are supported');

		switch (base) {
			case RVMethodCall(ref, method, args):
				final pt = resolveRVMethodCallToPoint(ref, method, args);
				return if (property == "x") pt.x else pt.y;
			default:
				throw builderError('unsupported base expression for .$property extraction');
		}
	}

	function resolveAsBool(v:ReferenceableValue):Bool {
		// Narrow the comparison fallback to "operands aren't numeric" — real
		// errors (missing refs, division by zero) re-throw instead of being
		// swallowed by an unrelated string comparison.
		inline function compareNumericOrString(e1, e2, numCmp:(Float, Float) -> Bool, strCmp:(String, String) -> Bool):Bool {
			try {
				return numCmp(resolveAsNumber(e1), resolveAsNumber(e2));
			} catch (err:BuilderError) {
				if (err.code != "not_a_number") throw err;
				return strCmp(resolveAsString(e1), resolveAsString(e2));
			}
		}

		return switch v {
			case EBinop(op, e1, e2):
				switch op {
					case OpEq:
						resolveAsString(e1) == resolveAsString(e2);
					case OpNotEq:
						resolveAsString(e1) != resolveAsString(e2);
					case OpLess:
						compareNumericOrString(e1, e2, (a, b) -> a < b, (a, b) -> a < b);
					case OpGreater:
						compareNumericOrString(e1, e2, (a, b) -> a > b, (a, b) -> a > b);
					case OpLessEq:
						compareNumericOrString(e1, e2, (a, b) -> a <= b, (a, b) -> a <= b);
					case OpGreaterEq:
						compareNumericOrString(e1, e2, (a, b) -> a >= b, (a, b) -> a >= b);
					case _: resolveAsInteger(v) != 0;
				}
			case RVTernary(condition, ifTrue, ifFalse):
				if (resolveAsBool(condition)) resolveAsBool(ifTrue) else resolveAsBool(ifFalse);
			case RVString(s):
				final boolValue = MultiAnimParser.tryStringToBool(s);
				if (boolValue != null) return boolValue;
				return MultiAnimParser.dynamicToInt(s, err -> throw err) != 0;
			case _: return resolveAsInteger(v) != 0;
		}
	}

	@:nullSafety(Off)
	function resolveAsInteger(v:ReferenceableValue) {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): val;
				case CBRNoResult:
					if (defaultValue != null) resolveAsInteger(defaultValue); else throw builderError('no default value for $input');

				case _: throw builderError('callback should return int but was ${result} for $input');
			}
		}

		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw builderError('RVArray not supported');
			case RVArrayReference(refArray): throw builderError('RVArrayReference not supported');
			case RVInteger(i): return i;
			case RVFloat(f): return Std.int(f);
			case RVString(s): return stringToInt(s);
			case RVColorXY(_, _, _) | RVColor(_, _): resolveAsColorInteger(v);
			case RVReference(ref):
				if (!indexedParams.exists(ref)) {
					throw builderError('reference ${ref} does not exist, available ${indexedParams}', "missing_ref");
				}

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case ValueF(val): return Std.int(val);
					case StringValue(s): stringToInt(s);
					case ExpressionAlias(expr): resolveAsInteger(expr);
					case null: throw builderError('reference ${ref} is null');
					default: throw builderError('reference ${ref} is not a value but ${val}');
				}
			case RVParenthesis(e): resolveAsInteger(e);
			case RVPropertyAccess(ref, property): Std.int(resolveRVPropertyAccess(ref, property));
			case RVMethodCall(ref, method, args): Std.int(resolveRVMethodCall(ref, method, args));
			case RVChainedMethodCall(base, property, _): Std.int(resolveRVChainedMethodCall(base, property));
			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsInteger(ifTrue) else resolveAsInteger(ifFalse);

			case RVCallbacks(name, defaultValue):
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);

			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);

			case EBinop(op, e1, e2):
				switch op {
					case OpAdd: resolveAsInteger(e1) + resolveAsInteger(e2);
					case OpMul: resolveAsInteger(e1) * resolveAsInteger(e2);
					case OpSub: resolveAsInteger(e1) - resolveAsInteger(e2);
					case OpDiv:
						final d = resolveAsInteger(e2);
						if (d == 0) throw builderError('Division by zero');
						Std.int(resolveAsInteger(e1) / d);
					case OpMod:
						final d = resolveAsInteger(e2);
						if (d == 0) throw builderError('Modulo by zero');
						Std.int(resolveAsInteger(e1) % d);
					case OpIntegerDiv:
						final d = resolveAsInteger(e2);
						if (d == 0) throw builderError('Division by zero');
						Std.int(resolveAsInteger(e1) / d);
					case OpEq: resolveAsInteger(e1) == resolveAsInteger(e2) ? 1 : 0;
					case OpNotEq: resolveAsInteger(e1) != resolveAsInteger(e2) ? 1 : 0;
					case OpLess: resolveAsInteger(e1) < resolveAsInteger(e2) ? 1 : 0;
					case OpGreater: resolveAsInteger(e1) > resolveAsInteger(e2) ? 1 : 0;
					case OpLessEq: resolveAsInteger(e1) <= resolveAsInteger(e2) ? 1 : 0;
					case OpGreaterEq: resolveAsInteger(e1) >= resolveAsInteger(e2) ? 1 : 0;
				}
			case EUnaryOp(op, e):
				switch op {
					case OpNeg: -resolveAsInteger(e);
				}
		}
	}

	@:nullSafety(Off)
	function resolveAsNumber(v:ReferenceableValue):Float {
		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw builderError('RVArray not supported');
			case RVArrayReference(refArray): throw builderError('RVArrayReference not supported');
			case RVInteger(i): i;
			case RVFloat(f): f;
			case RVString(s):
				final f = Std.parseFloat(s);
				if (Math.isNaN(f)) throw builderError('expected number, got ${s}', "not_a_number");
				f;
			case RVColorXY(_, _, _) | RVColor(_, _): throw builderError('reference is a color but needs to be float', "not_a_number");
			case RVReference(ref):
				if (!indexedParams.exists(ref))
					throw builderError('reference ${ref} does not exist (resolveAsNumber), available ${indexedParams}', "missing_ref");

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case ValueF(val): return val;
					case ExpressionAlias(expr): resolveAsNumber(expr);
					case null: throw builderError('reference ${ref} is null');
					default: throw builderError('reference ${ref} is not a value but ${val}');
				}
			case RVParenthesis(e): resolveAsNumber(e);
			case RVPropertyAccess(ref, property): resolveRVPropertyAccess(ref, property);
			case RVMethodCall(ref, method, args): resolveRVMethodCall(ref, method, args);
			case RVChainedMethodCall(base, property, _): resolveRVChainedMethodCall(base, property);
			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsNumber(ifTrue) else resolveAsNumber(ifFalse);
			case RVCallbacks(name, defaultValue):
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);

				switch result {
					case CBRInteger(val): cast(val, Float);
					case CBRString(val): throw builderError('callback should return number but was ${val}', "not_a_number");
					case CBRFloat(val): val;
					case CBRObject(_): throw builderError('callback should return number but was CBRObject for $input');
					case CBRNoResult: resolveAsNumber(defaultValue);
					case null: throw builderError('callback should return number but was null for $input');
				}
			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);
				switch result {
					case CBRInteger(val): cast(val, Float);
					case CBRString(val): throw builderError('callback should return number but was ${result} for $input', "not_a_number");
					case CBRFloat(val): val;
					case CBRNoResult: resolveAsNumber(defaultValue);
					case CBRObject(_): throw builderError('callback should return number but was CBRObject $result for $input');
					case null: throw builderError('callback should return number but was null');
				}

			case EBinop(op, e1, e2):
				switch op {
					case OpAdd: resolveAsNumber(e1) + resolveAsNumber(e2);
					case OpMul: resolveAsNumber(e1) * resolveAsNumber(e2);
					case OpSub: resolveAsNumber(e1) - resolveAsNumber(e2);
					case OpDiv:
						final d = resolveAsNumber(e2);
						if (d == 0) throw builderError('Division by zero');
						resolveAsNumber(e1) / d;
					case OpMod:
						final d = resolveAsNumber(e2);
						if (d == 0) throw builderError('Modulo by zero');
						resolveAsNumber(e1) % d;
					case OpIntegerDiv:
						final d = resolveAsInteger(e2);
						if (d == 0) throw builderError('Division by zero');
						Std.int(resolveAsInteger(e1) / d);
					case OpEq: resolveAsNumber(e1) == resolveAsNumber(e2) ? 1 : 0;
					case OpNotEq: resolveAsNumber(e1) != resolveAsNumber(e2) ? 1 : 0;
					case OpLess: resolveAsNumber(e1) < resolveAsNumber(e2) ? 1 : 0;
					case OpGreater: resolveAsNumber(e1) > resolveAsNumber(e2) ? 1 : 0;
					case OpLessEq: resolveAsNumber(e1) <= resolveAsNumber(e2) ? 1 : 0;
					case OpGreaterEq: resolveAsNumber(e1) >= resolveAsNumber(e2) ? 1 : 0;
				}
			case EUnaryOp(op, e):
				switch op {
					case OpNeg: -resolveAsNumber(e);
				}
		}
	}

	/** Resolve a programmable reference name from ReferenceableValue.
	 *  RVString: literal programmable name. RVReference: check if it's a parameter
	 *  of the current programmable — if yes, resolve its value as the name; if no,
	 *  fall back to literal (backward compat with $progName syntax). */
	function resolveRefName(rv:ReferenceableValue):String {
		return switch rv {
			case RVString(s): s;
			case RVReference(paramName):
				if (indexedParams.exists(paramName))
					resolveAsString(rv);
				else
					paramName; // Fallback: treat as literal programmable name
			default:
				throw builderError('unexpected ReferenceableValue for programmable reference: $rv');
		}
	}

	@:nullSafety(Off)
	function resolveAsString(v:ReferenceableValue):String {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): '${val}';
				case CBRFloat(val): '${val}';
				case CBRString(val): val;
				case CBRObject(_): throw builderError('callback should return string but was CBRObject for $input');
				case CBRNoResult:
					if (defaultValue != null) resolveAsString(defaultValue); else throw builderError('no default value for $input');
				case null: throw builderError('callback should return string but was null for $input');
			}
		}

		return switch v {
			case RVElementOfArray(array, index):
				resolveAsArrayElement(v);
			case RVArray(refArray): throw builderError('RVArray not supported');
			case RVArrayReference(refArray): throw builderError('RVArrayReference not supported');
			case RVInteger(i): return '${i}';
			case RVFloat(f): return '${f}';
			case RVString(s): return s;
			case RVColorXY(_, _, _) | RVColor(_, _):
				var color = resolveAsColorInteger(v);
				'$color';

			case RVReference(ref):
				if (!indexedParams.exists(ref))
					throw builderError('reference ${ref} does not exist (resolveAsString), available ${indexedParams}', "missing_ref");

				final val:ResolvedIndexParameters = indexedParams.get(ref);
				switch val {
					case Value(val): return '${val}';
					case ValueF(val): return '${val}';
					case StringValue(s): return s;
					case Index(_, value): return value;
					case ExpressionAlias(expr): return resolveAsString(expr);
					default: throw builderError('invalid reference value ${ref}, expected string got ${val}');
				}
			case RVParenthesis(e):
				// Parenthesized expressions (from ${...} interpolation) should evaluate
				// arithmetically first, then convert to string. This ensures ${value + 10}
				// produces "87" not "7710". Only the "not_a_number" tag falls back to
				// string; real errors (missing refs, division by zero, unsupported ops)
				// re-throw.
				try {
					final n = resolveAsNumber(e);
					return n == Math.ffloor(n) ? Std.string(Std.int(n)) : Std.string(n);
				} catch (err:BuilderError) {
					if (err.code == "not_a_number") return resolveAsString(e);
					throw err;
				}
			case RVPropertyAccess(_, _) | RVMethodCall(_, _, _): '${resolveAsNumber(v)}';
			case RVChainedMethodCall(base, property, _): '${resolveRVChainedMethodCall(base, property)}';
			case RVCallbacks(name, defaultValue):
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);
			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);

				return handleCallback(result, input, defaultValue);
			case EBinop(op, e1, e2): switch op {
					case OpAdd:
						return resolveAsString(e1) + resolveAsString(e2);
					case OpMul, OpSub, OpDiv, OpMod, OpIntegerDiv:
						return '${resolveAsInteger(v)}';
					case OpEq:
						return resolveAsString(e1) == resolveAsString(e2) ? "1" : "0";
					case OpNotEq:
						return resolveAsString(e1) != resolveAsString(e2) ? "1" : "0";
					case OpLess:
						return resolveAsString(e1) < resolveAsString(e2) ? "1" : "0";
					case OpGreater:
						return resolveAsString(e1) > resolveAsString(e2) ? "1" : "0";
					case OpLessEq:
						return resolveAsString(e1) <= resolveAsString(e2) ? "1" : "0";
					case OpGreaterEq:
						return resolveAsString(e1) >= resolveAsString(e2) ? "1" : "0";
				}
			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsString(ifTrue) else resolveAsString(ifFalse);
			case EUnaryOp(op, e): 
				switch op {
					case OpNeg: return '-' + resolveAsString(e);
				}
		}
	}

	function generatePlaceholderBitmap(type:ResolvedGeneratedTileType):h2d.Tile {
		return switch type {
			case Cross(w, h, color, thickness):
				final c = color;
				final pl = new PixelLines(w, h);
				for (t in 0...thickness) {
					pl.rect(t, t, w - 1 - t * 2, h - 1 - t * 2, c);
					pl.line(t, 0, w - 1, h - 1 - t, c);
					pl.line(0, t, w - 1 - t, h - 1, c);
					pl.line(t, h - 1, w - 1, t, c);
					pl.line(0, h - 1 - t, w - 1 - t, 0, c);
				}
				pl.updateBitmap();
				pl.tile;

			case SolidColor(w, h, color):
				solidTile(color, w, h);

			case SolidColorWithText(w, h, bgColor, text, textColor, fontName):
				// Create a solid color tile with centered text using font rendering
				generateTileWithText(w, h, bgColor, text, textColor, fontName);

			case AutotileRef(format, tileIndex, tileSize, edgeColor, fillColor):
				// Generate autotile demo tile with diagonal corners
				generateAutotileDemoTile(format, tileIndex, tileSize, edgeColor, fillColor);

			case AutotileRegionSheet(baseTile, regionX, regionY, regionW, regionH, tileSize, tileCount, scale, font, fontColor):
				// Generate a visual tile sheet showing the region with numbered grid overlay
				generateAutotileRegionSheetTile(baseTile, regionX, regionY, regionW, regionH, tileSize, tileCount, scale, font, fontColor);

			case PreloadedTile(tile):
				// Return the pre-loaded tile directly
				tile;
		}
	}

	/**
	 * Resolve an autotile reference by looking up the autotile definition.
	 * For demo: source - gets format, tileSize, edgeColor, fillColor from the definition.
	 * For tiles: source - loads the tile at the specified index.
	 * Converts the selector (index or edges) to a tile index.
	 */
	function resolveAutotileRef(autotileName:ReferenceableValue, selector:AutotileTileSelector):ResolvedGeneratedTileType {
		final name = resolveAsString(autotileName);
		final node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('autotile reference: could not find autotile "$name"');

		final autotileDef:AutotileDef = switch node.type {
			case AUTOTILE(def): def;
			default: throw builderErrorAt(node, 'autotile reference: "$name" is not an autotile definition');
		};

		final format = autotileDef.format;

		// Convert selector to tile index (and keep edge mask for potential fallback)
		var edgeMask:Null<Int> = null;
		final tileIndex = switch selector {
			case ByIndex(index): resolveAsInteger(index);
			case ByEdges(edges):
				edgeMask = edges;
				// Convert edge mask to tile index using the appropriate format
				switch format {
					case Cross: bh.base.Autotile.getCrossIndex(edges);
					case Blob47: bh.base.Autotile.getBlob47Index(edges);
				};
		};

		// Handle different source types
		return switch autotileDef.source {
			case ATSDemo(edgeColor, fillColor):
				final tileSize = resolveAsInteger(autotileDef.tileSize);
				final edgeColorInt = resolveAsColorInteger(edgeColor);
				final fillColorInt = resolveAsColorInteger(fillColor);
				AutotileRef(format, tileIndex, tileSize, edgeColorInt, fillColorInt);

			case ATSTiles(tiles):
				// Use fallback for blob47 if tile is missing
				var actualIndex = tileIndex;
				if (format == Blob47 && actualIndex >= tiles.length) {
					actualIndex = bh.base.Autotile.applyBlob47Fallback(tileIndex, tiles.length);
				}
				if (actualIndex < 0 || actualIndex >= tiles.length)
					throw builderErrorAt(node, 'autotile reference: tile index $tileIndex out of bounds for "$name" (has ${tiles.length} tiles)');
				final tile = loadTileSource(tiles[actualIndex]);
				PreloadedTile(tile);

			case ATSFile(filename):
				// Load tile from file, apply region and mapping if present
				final tileSize = resolveAsInteger(autotileDef.tileSize);
				final baseTile = resourceLoader.loadTile(resolveAsString(filename));

				// Apply region if present (extract sub-region from the tileset)
				var regionTile = baseTile;
				var regionX = 0;
				var regionY = 0;
				final region = autotileDef.region;
				if (region != null) {
					regionX = resolveAsInteger(region[0]);
					regionY = resolveAsInteger(region[1]);
					final regionW = resolveAsInteger(region[2]);
					final regionH = resolveAsInteger(region[3]);
					regionTile = baseTile.sub(regionX, regionY, regionW, regionH);
				}

				// Apply mapping if present (remap the tile index)
				var mappedIndex = tileIndex;
				final mapping = autotileDef.mapping;
				if (mapping != null) {
					var actualIndex = tileIndex;
					// For blob47 with allowPartialMapping, apply fallback for missing tiles
					if (format == Blob47 && autotileDef.allowPartialMapping && !mapping.exists(actualIndex)) {
						actualIndex = bh.base.Autotile.applyBlob47FallbackWithMap(tileIndex, mapping);
					}
					if (!mapping.exists(actualIndex))
						throw builderErrorAt(node, 'autotile reference: tile index $tileIndex not found in mapping');
					mappedIndex = cast mapping.get(actualIndex);
				}

				// Calculate tile position within the region
				final cols = Std.int(regionTile.width / tileSize);
				final tileX = (mappedIndex % cols) * tileSize;
				final tileY = Std.int(mappedIndex / cols) * tileSize;

				// Extract the specific tile
				final tile = regionTile.sub(tileX, tileY, tileSize, tileSize);
				PreloadedTile(tile);

			case ATSAtlas(sheet, prefix):
				// Load tile from atlas using sheet and prefix
				final tileSize = resolveAsInteger(autotileDef.tileSize);
				final sheetName = resolveAsString(sheet);
				final prefixStr = resolveAsString(prefix);

				// Apply mapping if present
				var mappedIndex = tileIndex;
				final mapping2 = autotileDef.mapping;
				if (mapping2 != null) {
					var actualIndex = tileIndex;
					// For blob47 with allowPartialMapping, apply fallback for missing tiles
					if (format == Blob47 && autotileDef.allowPartialMapping && !mapping2.exists(actualIndex)) {
						actualIndex = bh.base.Autotile.applyBlob47FallbackWithMap(tileIndex, mapping2);
					}
					if (!mapping2.exists(actualIndex))
						throw builderErrorAt(node, 'autotile reference: tile index $tileIndex not found in mapping');
					mappedIndex = cast mapping2.get(actualIndex);
				}

				// Load tile from atlas with prefix and index
				final tileName = prefixStr + mappedIndex;
				final tile = loadTileImpl(sheetName, tileName).tile;
				PreloadedTile(tile);

			case ATSAtlasRegion(sheet, region):
				// Atlas region-based autotiles not yet supported for generated(autotile(...)) syntax
				throw builderErrorAt(node, 'autotile reference: "$name" uses sheet region - use tiles: or demo: syntax instead');
		};
	}

	/**
	 * Resolve autotileRegionSheet - displays the entire region of an autotile with numbered grid overlay.
	 * Only works with autotiles that have a region defined.
	 * @param scale Scale factor for the tiles (font is not scaled)
	 * @param font Font name for the tile numbers
	 * @param fontColor Color for the tile numbers
	 */
	function resolveAutotileRegionSheet(autotileName:ReferenceableValue, scale:ReferenceableValue, font:ReferenceableValue, fontColor:ReferenceableValue):ResolvedGeneratedTileType {
		final name = resolveAsString(autotileName);
		final scaleVal = resolveAsInteger(scale);
		final fontName = resolveAsString(font);
		final fontColorVal = resolveAsColorInteger(fontColor);

		final node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('autotileRegionSheet: could not find autotile "$name"');

		final autotileDef:AutotileDef = switch node.type {
			case AUTOTILE(def): def;
			default: throw builderErrorAt(node, 'autotileRegionSheet: "$name" is not an autotile definition');
		};

		final tileSize = resolveAsInteger(autotileDef.tileSize);
		final tileCount = switch autotileDef.format {
			case Cross: 13;
			case Blob47: 47;
		};

		// Handle different source types to get the base tile and region
		return switch autotileDef.source {
			case ATSFile(filename):
				final baseTile = resourceLoader.loadTile(resolveAsString(filename));
				if (autotileDef.region == null)
					throw builderErrorAt(node, 'autotileRegionSheet: autotile "$name" has no region defined');
				final r = autotileDef.region;
				final regionX = resolveAsInteger(r[0]);
				final regionY = resolveAsInteger(r[1]);
				final regionW = resolveAsInteger(r[2]);
				final regionH = resolveAsInteger(r[3]);
				AutotileRegionSheet(baseTile, regionX, regionY, regionW, regionH, tileSize, tileCount, scaleVal, fontName, fontColorVal);

			case ATSAtlasRegion(sheet, region):
				final baseTile = resourceLoader.loadTile(resolveAsString(sheet));
				final regionX = resolveAsInteger(region[0]);
				final regionY = resolveAsInteger(region[1]);
				final regionW = resolveAsInteger(region[2]);
				final regionH = resolveAsInteger(region[3]);
				AutotileRegionSheet(baseTile, regionX, regionY, regionW, regionH, tileSize, tileCount, scaleVal, fontName, fontColorVal);

			case ATSDemo(_, _):
				throw builderErrorAt(node, 'autotileRegionSheet: autotile "$name" uses demo source - no region to display');

			case ATSTiles(_):
				throw builderErrorAt(node, 'autotileRegionSheet: autotile "$name" uses explicit tiles - no region to display');

			case ATSAtlas(_, _):
				throw builderErrorAt(node, 'autotileRegionSheet: autotile "$name" uses atlas prefix - no region to display');
		};
	}

	/**
	 * Generate a tile with text using font-based rendering.
	 * Uses h2d.Object.drawTo to render to a texture.
	 */
	function generateTileWithText(w:Int, h:Int, bgColor:Int, text:String, textColor:Int, fontName:String):h2d.Tile {
		// Load the font
		final font = resourceLoader.loadFont(fontName);

		// Create container for background + text
		final container = new h2d.Object();

		// Add background
		final bg = solidBitmap(bgColor, w, h, container);

		// Create and configure text
		final textObj = new h2d.Text(font, container);
		textObj.text = text;
		textObj.textColor = textColor & 0xFFFFFF;
		textObj.maxWidth = w;
		textObj.textAlign = Center;

		// Center text vertically (use integer position for deterministic rendering)
		final textHeight = textObj.textHeight;
		textObj.x = 0;
		textObj.y = Math.floor((h - font.lineHeight) / 2);

		// Render to texture using drawTo
		final texture = new h3d.mat.Texture(w, h, [Target]);
		container.drawTo(texture);

		// Capture pixels from texture
		final pixels = texture.capturePixels();

		// Clean up
		container.remove();
		texture.dispose();

		// Create tile from pixels
		return h2d.Tile.fromPixels(pixels);
	}

	/**
	 * Generate a visual tile showing the autotile region with numbered grid overlay.
	 * Displays the complete region and draws tile indices over each tile position.
	 * @param scale Scale factor for the tiles (font is not scaled)
	 * @param fontName Font name for the tile numbers
	 * @param fontColor Color for the tile numbers
	 */
	function generateAutotileRegionSheetTile(baseTile:h2d.Tile, regionX:Int, regionY:Int, regionW:Int, regionH:Int, tileSize:Int, tileCount:Int, scale:Int, fontName:String, fontColor:Int):h2d.Tile {
		// Calculate scaled dimensions
		final scaledW = regionW * scale;
		final scaledH = regionH * scale;
		final scaledTileSize = tileSize * scale;

		// Create container for the region + grid overlay
		final container = new h2d.Object();

		// Extract and display the region (scaled)
		final regionTile = baseTile.sub(regionX, regionY, regionW, regionH);
		final regionBitmap = new h2d.Bitmap(regionTile, container);
		regionBitmap.scaleX = scale;
		regionBitmap.scaleY = scale;

		// Calculate grid dimensions
		final cols = Std.int(regionW / tileSize);
		final rows = Std.int(regionH / tileSize);

		// Draw grid lines using PixelLines (at scaled size)
		final pl = new PixelLines(scaledW, scaledH);
		final gridColor = 0xFFFFFFFF;  // White grid lines

		// Draw vertical grid lines
		for (col in 0...cols + 1) {
			final x = col * scaledTileSize;
			if (x < scaledW) {
				pl.line(x, 0, x, scaledH - 1, gridColor);
			}
		}

		// Draw horizontal grid lines
		for (row in 0...rows + 1) {
			final y = row * scaledTileSize;
			if (y < scaledH) {
				pl.line(0, y, scaledW - 1, y, gridColor);
			}
		}

		pl.updateBitmap();
		new h2d.Bitmap(pl.tile, container);

		// Add tile numbers using specified font (not scaled)
		final font = resourceLoader.loadFont(fontName);
		final fontColorRGB = fontColor & 0xFFFFFF;
		final totalTilesInRegion = cols * rows;
		for (i in 0...totalTilesInRegion) {
			final col = i % cols;
			final row = Std.int(i / cols);
			final x = col * scaledTileSize + 1;
			final y = row * scaledTileSize + 1;
			final numStr = Std.string(i);

			// Shadow text (black, offset by 1 pixel)
			final shadowText = new h2d.Text(font, container);
			shadowText.text = numStr;
			shadowText.textColor = 0x000000;
			shadowText.x = x + 1;
			shadowText.y = y + 1;

			// Main text (using specified font color)
			final mainText = new h2d.Text(font, container);
			mainText.text = numStr;
			mainText.textColor = fontColorRGB;
			mainText.x = x;
			mainText.y = y;
		}

		// Render container to texture (at scaled size)
		final texture = new h3d.mat.Texture(scaledW, scaledH, [Target]);
		container.drawTo(texture);

		// Capture pixels from texture
		final pixels = texture.capturePixels();

		// Clean up
		container.remove();
		texture.dispose();

		return h2d.Tile.fromPixels(pixels);
	}

	function loadTileSource(tileSource):h2d.Tile {
		final tile = switch tileSource {
			case TSFile(filename):
				final resolved = resolveAsString(filename);
				if (resolved == null || resolved.length == 0) {
					if (incrementalMode) {
						if (incrementalFallbackTile == null)
							incrementalFallbackTile = h2d.Tile.fromColor(0x00000000, 1, 1, 0.0);
						incrementalFallbackTile.clone();
					} else
						throw builderError('TSFile: empty filename');
				} else
					resourceLoader.loadTile(resolved);
			case TSSheet(sheet, name): loadTileImpl(resolveAsString(sheet), resolveAsString(name)).tile;
			case TSSheetWithIndex(sheet, name, index): loadTileImpl(resolveAsString(sheet), resolveAsString(name), resolveAsInteger(index)).tile;
			case TSGenerated(type):
				var resolvedType:ResolvedGeneratedTileType = switch type {
					case Cross(width, height, color, thickness): Cross(resolveAsInteger(width), resolveAsInteger(height), resolveAsColorInteger(color), resolveAsInteger(thickness));
					case SolidColor(width, height, color): SolidColor(resolveAsInteger(width), resolveAsInteger(height), resolveAsColorInteger(color));
					case SolidColorWithText(width, height, color, text, textColor, font): SolidColorWithText(resolveAsInteger(width), resolveAsInteger(height), resolveAsColorInteger(color), resolveAsString(text), resolveAsColorInteger(textColor), resolveAsString(font));
					case AutotileRef(autotileName, selector): resolveAutotileRef(autotileName, selector);
					case AutotileRegionSheet(autotileName, scale, font, fontColor): resolveAutotileRegionSheet(autotileName, scale, font, fontColor);
				}

				resourceLoader.getOrCreatePlaceholder(resolvedType, (resolvedType) -> generatePlaceholderBitmap(resolvedType));
			case TSTile(tile): tile;
			case TSReference(varName):
				// Resolve tile source from indexed params (e.g., $bitmap from stateanim/tiles iterator)
				final param = indexedParams.get(varName);
				if (param == null) {
					// In incremental mode, inactive conditional branches are pre-built for visibility toggling.
					// Tile params (tile:tile with no default) may not have a value yet — use a shared fallback tile.
					if (incrementalMode) {
						if (incrementalFallbackTile == null)
							incrementalFallbackTile = h2d.Tile.fromColor(0x00000000, 1, 1, 0.0);
						incrementalFallbackTile.clone();
					} else
						throw builderError('TileSource reference "$varName" not found in indexed params');
				} else switch param {
					case TileSourceValue(ts): loadTileSource(ts);
					case _: throw builderError('TileSource reference "$varName" is not a TileSourceValue, got: $param');
				}
			case TSPivot(px, py, inner):
				var t = loadTileSource(inner);
				t.setCenterRatio(px, py);
				t;
		}

		if (tile == null)
			throw builderError('could not load tile $tileSource');
		return tile;
	}

	function createHtmlText(font) {
		final t = new HtmlText(font);
		t.loadFont = (name) -> resourceLoader.loadFont(name);
		return t;
	}

	function applyAutoFit(t:h2d.Text, textDef:TextDef, node:Node):Void {
		final autoFitFonts = textDef.autoFitFonts;
		final autoFitMode = textDef.autoFitMode;
		if (autoFitFonts == null || autoFitMode == null) return;

		final scaleAdjust = if (node.scale != null) resolveAsNumber(node.scale) else 1.0;

		// Determine fit constraints
		var fitWidth:Null<Float> = null;
		var fitHeight:Null<Float> = null;
		switch autoFitMode {
			case AFWidth | AFFillWidth:
				fitWidth = if (t.maxWidth != null) t.maxWidth else null;
			case AFBox(w, h) | AFFillBox(w, h):
				fitWidth = resolveAsNumber(w) / scaleAdjust;
				fitHeight = resolveAsNumber(h) / scaleAdjust;
		}
		if (fitWidth == null) return;

		final isFill = switch autoFitMode {
			case AFFillWidth | AFFillBox(_, _): true;
			default: false;
		};

		// Build full font candidate list: primary font + fallback fonts
		var allFonts = new Array<h2d.Font>();
		allFonts.push(t.font);
		for (fontRef in autoFitFonts) {
			allFonts.push(resourceLoader.loadFont(resolveAsString(fontRef)));
		}

		if (isFill) {
			// Best-fit: try all fonts, pick largest that fits
			var bestFont:Null<h2d.Font> = null;
			var bestWidth:Float = -1;
			for (font in allFonts) {
				t.font = font;
				if (textFits(t, fitWidth, fitHeight)) {
					if (t.textWidth > bestWidth) {
						bestWidth = t.textWidth;
						bestFont = font;
					}
				}
			}
			t.font = if (bestFont != null) bestFont else allFonts[allFonts.length - 1];
		} else {
			// First-fit: use primary font if it fits, otherwise try fallbacks in order
			if (!textFits(t, fitWidth, fitHeight)) {
				for (fontRef in autoFitFonts) {
					t.font = resourceLoader.loadFont(resolveAsString(fontRef));
					if (textFits(t, fitWidth, fitHeight)) break;
				}
			}
		}
	}

	static function textFits(t:h2d.Text, fitWidth:Null<Float>, fitHeight:Null<Float>):Bool {
		if (fitWidth != null && t.textWidth > fitWidth) return false;
		if (fitHeight != null && t.textHeight > fitHeight) return false;
		return true;
	}

	function matchSingleCondition(condValue:ConditionalValues, currentValue:ResolvedIndexParameters):Bool {
		switch condValue {
			case CoNot(inner):
				return !matchSingleCondition(inner, currentValue);
			case CoAnyOf(values):
				for (cv in values) if (matchSingleCondition(cv, currentValue)) return true;
				return false;
			case CoEnums(a):
				switch currentValue {
					case Index(idx, v):
						if (!a.contains(v)) return false;
					case Value(val):
						if (!a.contains(Std.string(val))) return false;
					case StringValue(s):
						if (!a.contains(s)) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}
			case CoRange(from, to, fromExclusive, toExclusive):
				final fromF:Null<Float> = from != null ? resolveAsNumber(from) : null;
				final toF:Null<Float> = to != null ? resolveAsNumber(to) : null;
				switch currentValue {
					case Value(val):
						if (fromF != null && (fromExclusive ? val <= fromF : val < fromF)) return false;
						if (toF != null && (toExclusive ? val >= toF : val > toF)) return false;
					case ValueF(val):
						if (fromF != null && (fromExclusive ? val <= fromF : val < fromF)) return false;
						if (toF != null && (toExclusive ? val >= toF : val > toF)) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}

			case CoIndex(idx, value):
				switch currentValue {
					case Index(i, value): if (idx != i) return false;
					case StringValue(s): if (s != value) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}
			case CoValue(val):
				switch currentValue {
					case Value(iVal): if (val != iVal) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}
			case CoFlag(f):
				switch currentValue {
					case Flag(i): if (f & i != f) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}
			case CoAny:
			case CoStringValue(s):
				switch currentValue {
					case Index(idx, value): if (value != s) return false;
					case StringValue(sv): if (s != sv) return false;
					case Value(val): if (Std.string(val) != s) return false;
					default: throw builderError('invalid param types ${currentValue}, ${condValue}');
				}
		}
		return true;
	}

	function matchConditions(conditions:Map<String, ConditionalValues>, anyMode:Bool, indexedParams:Map<String, ResolvedIndexParameters>):Bool {
		if (anyMode) {
			// OR mode (@any): match if ANY listed condition matches
			for (paramName => condValue in conditions) {
				final paramValue = indexedParams[paramName];
				if (paramValue != null && matchSingleCondition(condValue, paramValue))
					return true;
			}
			return false;
		} else {
			// AND mode (@all / @() / @if): ALL listed conditions must match, unlisted ignored
			for (paramName => condValue in conditions) {
				final paramValue = indexedParams[paramName];
				if (paramValue == null) return false;
				if (!matchSingleCondition(condValue, paramValue)) return false;
			}
			return true;
		}
	}

	function resolveMatchedSwitchArm(paramName:String, arms:Array<SwitchArm>):Null<SwitchArm> {
		final paramValue = indexedParams.get(paramName);
		if (paramValue == null) return null;
		var defaultArm:Null<SwitchArm> = null;
		for (arm in arms) {
			if (arm.pattern == null) {
				defaultArm = arm;
			} else if (matchSingleCondition(arm.pattern, paramValue)) {
				return arm;
			}
		}
		return defaultArm;
	}

	// Build-time predicate: "should this node be built?" Intentionally trivial for chain nodes.
	// Full-build callers rely on resolveConditionalChildren having already dropped losing chain
	// nodes, so any @else/@default reaching here is a survivor → return true.
	// Incremental callers get the same passthrough; real chain resolution happens later in
	// applyConditionalChains, which walks siblings and sets visibility per chain position.
	// Do NOT treat the return value as "does this node's own @() condition match" — for chain
	// nodes it does not, and there is no single-node answer.
	function shouldBuildInFullMode(node:Node, indexedParams:Map<String, ResolvedIndexParameters>) {
		return switch node.conditionals {
			case Conditional(conditions, anyMode):
				matchConditions(conditions, anyMode, indexedParams);
			case ConditionalElse(_) | ConditionalDefault:
				true; // chain survivor (full mode) / passthrough — applyConditionalChains decides actual visibility (incremental)
			case NoConditional: return true;
		}
	}

	// Resolves @else/@default chains: returns only the children that should be built
	// given the current indexedParams state. Regular Conditional and NoConditional nodes
	// are always included (their shouldBuildInFullMode check happens later in build/buildTileGroup).
	// ConditionalElse and ConditionalDefault are filtered here based on chain logic.
	function resolveConditionalChildren(children:Array<Node>):Array<Node> {
		// In incremental mode, return ALL children so they're all built (visibility handled later)
		if (incrementalMode)
			return children;

		var result:Array<Node> = [];
		var prevSiblingMatched = false;
		var anyConditionalSiblingMatched = false;

		for (childNode in children) {
			switch childNode.conditionals {
				case Conditional(conditions, anyMode):
					var matched = matchConditions(conditions, anyMode, indexedParams);
					prevSiblingMatched = matched;
					if (matched) anyConditionalSiblingMatched = true;
					result.push(childNode);

				case ConditionalElse(extraConditions):
					if (!prevSiblingMatched) {
						if (extraConditions == null) {
							// Bare @else - always matches when previous didn't
							prevSiblingMatched = true;
							anyConditionalSiblingMatched = true;
							result.push(childNode);
						} else {
							// @else(cond) - "else if", check additional conditions
							var matched = matchConditions(extraConditions, false, indexedParams);
							prevSiblingMatched = matched;
							if (matched) anyConditionalSiblingMatched = true;
							if (matched) result.push(childNode);
						}
					} else {
						// Previous sibling matched - skip this @else
						prevSiblingMatched = true;
					}

				case ConditionalDefault:
					if (!anyConditionalSiblingMatched) {
						result.push(childNode);
					}
					// Reset tracking for next conditional group
					anyConditionalSiblingMatched = false;

				case NoConditional:
					// Unconditional node - always build, reset tracking
					prevSiblingMatched = false;
					anyConditionalSiblingMatched = false;
					result.push(childNode);
			}
		}
		return result;
	}

	/** Validate tileGroup descendants up front: reject any conditional whose predicate
	 *  key isn't in `loopVarScope`. `buildTileGroup` bakes the subtree into a single
	 *  drawable and is never re-entered by the incremental-update path, so a conditional
	 *  on a mutable param would silently freeze on first build. `@switch(param)` has the
	 *  same problem — the arm is resolved once via `resolveMatchedSwitchArm` and never
	 *  re-evaluated. `loopVarScope` carries the repeatable/repeatable2d loop-var names
	 *  that ARE safe because they iterate at build time. Note: @finals are also rejected
	 *  as conditional keys — `matchSingleCondition` has no `ExpressionAlias` case, so
	 *  keying a conditional on a @final is broken everywhere (not just inside tileGroup);
	 *  catching it here with a clear message is a better diagnostic than the generic
	 *  "invalid param types" later. Throws `BuilderError` with `code="tilegroup_conditional"`. */
	function validateTileGroupSubtree(node:Node, loopVarScope:Array<String>):Void {
		inline function requireLoopVar(paramName:String, source:String):Void {
			if (loopVarScope.indexOf(paramName) < 0) {
				final kind = switch (indexedParams.get(paramName)) {
					case ExpressionAlias(_): '@final';
					case null: 'name';
					default: 'parameter';
				};
				throw builderErrorAt(node, '$source inside tileGroup references $kind "$paramName"; tileGroup descendants are baked at build time and never re-evaluated. Only repeatable/repeatable2d loop variables (which iterate at build time) are safe as conditional keys here — move the conditional outside the tileGroup, or key it on a loop variable.', "tilegroup_conditional");
			}
		}

		switch node.conditionals {
			case Conditional(conds, _):
				for (name => _ in conds) requireLoopVar(name, '@($name => ...)');
			case ConditionalElse(extraConds) if (extraConds != null):
				for (name => _ in extraConds) requireLoopVar(name, '@else($name => ...)');
			case ConditionalElse(_) | ConditionalDefault | NoConditional:
		}

		switch node.type {
			case SWITCH(paramName, arms):
				requireLoopVar(paramName, '@switch($paramName)');
				for (arm in arms)
					for (child in arm.children)
						validateTileGroupSubtree(child, loopVarScope);
			case REPEAT(varName, _):
				final innerScope = loopVarScope.concat([varName]);
				for (child in node.children) validateTileGroupSubtree(child, innerScope);
			case REPEAT2D(varNameX, varNameY, _, _):
				final innerScope = loopVarScope.concat([varNameX, varNameY]);
				for (child in node.children) validateTileGroupSubtree(child, innerScope);
			default:
				for (child in node.children) validateTileGroupSubtree(child, loopVarScope);
		}
	}

	/** Collect parameter references from a ReferenceableValue tree */
	static function collectParamRefs(rv:ReferenceableValue, result:Array<String>):Void {
		if (rv == null) return;
		switch rv {
			case RVReference(ref): result.push(ref);
			case EBinop(_, e1, e2): collectParamRefs(e1, result); collectParamRefs(e2, result);
			case RVParenthesis(e): collectParamRefs(e, result);
			case RVTernary(cond, t, f): collectParamRefs(cond, result); collectParamRefs(t, result); collectParamRefs(f, result);
			case EUnaryOp(_, e): collectParamRefs(e, result);
			case RVElementOfArray(_, idx): collectParamRefs(idx, result);
			default:
		}
	}

	/** Collects parameter references from a ConditionalValues (e.g. $ref in CoRange bounds). */
	static function collectConditionalValueParamRefs(cv:ConditionalValues, result:Array<String>):Void {
		switch cv {
			case CoRange(from, to, _, _):
				if (from != null) collectParamRefs(from, result);
				if (to != null) collectParamRefs(to, result);
			case CoNot(inner):
				collectConditionalValueParamRefs(inner, result);
			case CoAnyOf(values):
				for (v in values) collectConditionalValueParamRefs(v, result);
			default: // CoEnums, CoIndex, CoValue, CoFlag, CoAny, CoStringValue — no RV refs
		}
	}

	/** Recursively collects parameter names referenced in conditions of a node and its descendants.
	    Includes both condition keys (param names) and value references (e.g. $level in CoRange bounds). */
	static function collectChildConditionalParamRefs(nodes:Array<Node>, result:Array<String>):Void {
		for (node in nodes) {
			switch node.conditionals {
				case Conditional(conditions, _):
					for (paramName => condValue in conditions) {
						if (result.indexOf(paramName) < 0) result.push(paramName);
						collectConditionalValueParamRefs(condValue, result);
					}
				case ConditionalElse(values):
					if (values != null)
						for (paramName => condValue in values) {
							if (result.indexOf(paramName) < 0) result.push(paramName);
							collectConditionalValueParamRefs(condValue, result);
						}
				case ConditionalDefault | NoConditional:
			}
			if (node.children != null)
				collectChildConditionalParamRefs(node.children, result);
		}
	}

	static function collectCoordinateParamRefs(coord:Coordinates, result:Array<String>):Void {
		if (coord == null) return;
		switch coord {
			case OFFSET(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_GRID_POSITION(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_HEX_CUBE(q, r, s): collectParamRefs(q, result); collectParamRefs(r, result); collectParamRefs(s, result);
			case SELECTED_HEX_OFFSET(col, row, _): collectParamRefs(col, result); collectParamRefs(row, result);
			case SELECTED_HEX_DOUBLED(col, row): collectParamRefs(col, result); collectParamRefs(row, result);
			case SELECTED_HEX_PIXEL(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_HEX_CORNER(count, factor): collectParamRefs(count, result); collectParamRefs(factor, result);
			case SELECTED_HEX_EDGE(dir, factor): collectParamRefs(dir, result); collectParamRefs(factor, result);
			case NAMED_COORD(_, coord): collectCoordinateParamRefs(coord, result);
			case WITH_OFFSET(base, offsetX, offsetY): collectCoordinateParamRefs(base, result); collectParamRefs(offsetX, result); collectParamRefs(offsetY, result);
			default:
		}
	}

	static function collectFilterParamRefs(filter:FilterType, result:Array<String>):Void {
		if (filter == null) return;
		switch (filter) {
			case FilterNone:
			case FilterGroup(filters):
				for (f in filters) collectFilterParamRefs(f, result);
			case FilterOutline(size, color):
				collectParamRefs(size, result);
				collectParamRefs(color, result);
			case FilterSaturate(v):
				collectParamRefs(v, result);
			case FilterBrightness(v):
				collectParamRefs(v, result);
			case FilterGrayscale(v):
				collectParamRefs(v, result);
			case FilterHue(v):
				collectParamRefs(v, result);
			case FilterGlow(color, alpha, radius, gain, quality, _, _):
				collectParamRefs(color, result);
				collectParamRefs(alpha, result);
				collectParamRefs(radius, result);
				collectParamRefs(gain, result);
				collectParamRefs(quality, result);
			case FilterBlur(radius, gain, quality, linear):
				collectParamRefs(radius, result);
				collectParamRefs(gain, result);
				collectParamRefs(quality, result);
				collectParamRefs(linear, result);
			case FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, _):
				collectParamRefs(distance, result);
				collectParamRefs(angle, result);
				collectParamRefs(color, result);
				collectParamRefs(alpha, result);
				collectParamRefs(radius, result);
				collectParamRefs(gain, result);
				collectParamRefs(quality, result);
			case FilterPixelOutline(mode, _):
				switch (mode) {
					case POKnockout(color, knockout):
						collectParamRefs(color, result);
						collectParamRefs(knockout, result);
					case POInlineColor(color, inlineColor):
						collectParamRefs(color, result);
						collectParamRefs(inlineColor, result);
				}
			case FilterPaletteReplace(_, sourceRow, replacementRow):
				collectParamRefs(sourceRow, result);
				collectParamRefs(replacementRow, result);
			case FilterColorListReplace(sourceColors, replacementColors):
				for (c in sourceColors) collectParamRefs(c, result);
				for (c in replacementColors) collectParamRefs(c, result);
			case FilterCustom(_, args):
				for (a in args) collectParamRefs(a.value, result);
		}
	}

	static function collectGraphicsElementParamRefs(element:GraphicsElement, result:Array<String>):Void {
		switch element {
			case GERect(color, style, width, height):
				collectParamRefs(color, result); collectParamRefs(width, result); collectParamRefs(height, result);
				collectGraphicsStyleParamRefs(style, result);
			case GEPolygon(color, style, points):
				collectParamRefs(color, result); collectGraphicsStyleParamRefs(style, result);
				for (p in points) collectCoordinateParamRefs(p, result);
			case GECircle(color, style, radius):
				collectParamRefs(color, result); collectParamRefs(radius, result);
				collectGraphicsStyleParamRefs(style, result);
			case GEEllipse(color, style, width, height):
				collectParamRefs(color, result); collectParamRefs(width, result); collectParamRefs(height, result);
				collectGraphicsStyleParamRefs(style, result);
			case GEArc(color, style, radius, startAngle, arcAngle):
				collectParamRefs(color, result); collectParamRefs(radius, result);
				collectParamRefs(startAngle, result); collectParamRefs(arcAngle, result);
				collectGraphicsStyleParamRefs(style, result);
			case GERoundRect(color, style, width, height, radius):
				collectParamRefs(color, result); collectParamRefs(width, result); collectParamRefs(height, result);
				collectParamRefs(radius, result); collectGraphicsStyleParamRefs(style, result);
			case GELine(color, lineWidth, start, end):
				collectParamRefs(color, result); collectParamRefs(lineWidth, result);
				collectCoordinateParamRefs(start, result); collectCoordinateParamRefs(end, result);
		}
	}

	static function collectGraphicsStyleParamRefs(style:GraphicsStyle, result:Array<String>):Void {
		switch style {
			case GSLineWidth(lw): collectParamRefs(lw, result);
			case GSFilled:
		}
	}

	static function collectTileSourceParamRefs(tileSource:TileSource, result:Array<String>):Void {
		switch tileSource {
			case TSFile(filename): collectParamRefs(filename, result);
			case TSSheet(sheet, name): collectParamRefs(sheet, result); collectParamRefs(name, result);
			case TSSheetWithIndex(sheet, name, index): collectParamRefs(sheet, result); collectParamRefs(name, result); collectParamRefs(index, result);
			case TSGenerated(type):
				switch type {
					case SolidColor(w, h, color): collectParamRefs(w, result); collectParamRefs(h, result); collectParamRefs(color, result);
					case Cross(w, h, color, thickness): collectParamRefs(w, result); collectParamRefs(h, result); collectParamRefs(color, result); collectParamRefs(thickness, result);
					case SolidColorWithText(w, h, color, text, textColor, font):
						collectParamRefs(w, result); collectParamRefs(h, result); collectParamRefs(color, result);
						collectParamRefs(text, result); collectParamRefs(textColor, result); collectParamRefs(font, result);
					default:
				}
			case TSReference(varName): result.push(varName);
			case TSPivot(_, _, inner): collectTileSourceParamRefs(inner, result);
			#if !macro
			case TSTile(_):
			#end
		}
	}

	static function collectPixelShapesParamRefs(shapes:Array<PixelShapes>, result:Array<String>):Void {
		for (s in shapes) {
			switch s {
				case LINE(line):
					collectCoordinateParamRefs(line.start, result);
					collectCoordinateParamRefs(line.end, result);
					collectParamRefs(line.color, result);
				case RECT(rect) | FILLED_RECT(rect):
					collectCoordinateParamRefs(rect.start, result);
					collectParamRefs(rect.width, result);
					collectParamRefs(rect.height, result);
					collectParamRefs(rect.color, result);
				case PIXEL(pixel):
					collectCoordinateParamRefs(pixel.pos, result);
					collectParamRefs(pixel.color, result);
			}
		}
	}

	/** Track param-dependent expressions for incremental updates */
	function trackIncrementalExpressions(node:Node, object:h2d.Object, builtObject:BuiltHeapsComponent):Void {
		final ctx = incrementalContext;
		if (ctx == null) return;

		switch node.type {
			case TEXT(textDef):
				final textRefs:Array<String> = [];
				collectParamRefs(textDef.text, textRefs);
				collectParamRefs(textDef.color, textRefs);
				if (textRefs.length > 0) {
					final t = switch builtObject { case HeapsText(t): t; default: null; };
					if (t != null) {
						final textDefCapture = textDef;
						final nodeCapture = node;
						ctx.trackExpression(() -> {
							t.text = resolveAsString(textDefCapture.text);
							t.textColor = resolveAsColorInteger(textDefCapture.color);
							if (textDefCapture.autoFitFonts != null)
								applyAutoFit(t, textDefCapture, nodeCapture);
						}, textRefs, object);
					}
				}
			case RICHTEXT(textDef):
				final textRefs:Array<String> = [];
				collectParamRefs(textDef.text, textRefs);
				collectParamRefs(textDef.color, textRefs);
				if (textDef.styles != null) {
					for (style in textDef.styles) {
						if (style.color != null) collectParamRefs(style.color, textRefs);
						if (style.fontName != null) collectParamRefs(style.fontName, textRefs);
					}
				}
				if (textDef.images != null) {
					for (img in textDef.images) {
						switch img.tileSource {
							case TSReference(varName): if (textRefs.indexOf(varName) < 0) textRefs.push(varName);
							default:
						}
					}
				}
				if (textRefs.length > 0) {
					final t = switch builtObject { case HeapsText(t): t; default: null; };
					if (t != null) {
						final textDefCapture = textDef;
						final nodeCapture = node;
						ctx.trackExpression(() -> {
							final rawText = resolveAsString(textDefCapture.text);
							t.text = TextMarkupConverter.convert(rawText);
							t.textColor = resolveAsColorInteger(textDefCapture.color);
							if (textDefCapture.styles != null) {
								final ht:HtmlText = cast t;
								for (style in textDefCapture.styles) {
									final c:Null<Int> = if (style.color != null) resolveAsColorInteger(style.color) & 0xFFFFFF else null;
									final f:Null<String> = if (style.fontName != null) resolveAsString(style.fontName) else null;
									ht.defineHtmlTag(style.name, c, f);
								}
							}
							if (textDefCapture.images != null) {
								final ht:HtmlText = cast t;
								final imageMap = new haxe.ds.StringMap<h2d.Tile>();
								for (img in textDefCapture.images) {
									imageMap.set(img.name, loadTileSource(img.tileSource));
								}
								ht.loadImage = (url) -> cast imageMap.get(url);
								ht.text = ht.text; // force re-render after image map change
							}
							if (textDefCapture.autoFitFonts != null)
								applyAutoFit(t, textDefCapture, nodeCapture);
						}, textRefs, object);
					}
				}
			case NINEPATCH(_, _, width, height):
				final npRefs:Array<String> = [];
				collectParamRefs(width, npRefs);
				collectParamRefs(height, npRefs);
				if (npRefs.length > 0) {
					final sg = switch builtObject { case NinePatch(sg): sg; default: null; };
					if (sg != null) {
						final wCapture = width;
						final hCapture = height;
						ctx.trackExpression(() -> {
							sg.width = resolveAsNumber(wCapture);
							sg.height = resolveAsNumber(hCapture);
						}, npRefs, object);
					}
				}
			case BITMAP(tileSource, hAlign, vAlign):
				final bmpRefs:Array<String> = [];
				collectTileSourceParamRefs(tileSource, bmpRefs);
				if (bmpRefs.length > 0) {
					final bmp = switch builtObject { case HeapsBitmap(bmp): bmp; default: null; };
					if (bmp != null) {
						switch tileSource {
							case TSGenerated(SolidColor(w, h, color)):
								final wCapture = w;
								final hCapture = h;
								final colorCapture = color;
								ctx.trackExpression(() -> {
									bmp.tile = solidTile(resolveAsColorInteger(colorCapture),
										resolveAsInteger(wCapture), resolveAsInteger(hCapture));
								}, bmpRefs, object);
							default:
								final tileSourceCapture = tileSource;
								final hAlignCapture = hAlign;
								final vAlignCapture = vAlign;
								ctx.trackExpression(() -> {
									final tile = loadTileSource(tileSourceCapture);
									final dh:Float = switch vAlignCapture {
										case Top: 0.;
										case Center: -(tile.height * .5);
										case Bottom: -tile.height;
									};
									final wh:Float = switch hAlignCapture {
										case Left: 0.;
										case Right: -tile.width;
										case Center: -(tile.width * .5);
									};
									bmp.tile = tile.sub(0, 0, tile.width, tile.height, wh, dh);
								}, bmpRefs, object);
						}
					}
				}
			case GRAPHICS(elements):
				// Always register redraw for Graphics — h2d.Graphics clears content on
				// onRemove(), so we need to re-draw after removeChild when a conditional
				// element is re-added to the scene graph.
				final gfxRefs:Array<String> = [];
				for (item in elements) {
					collectCoordinateParamRefs(item.pos, gfxRefs);
					collectGraphicsElementParamRefs(item.element, gfxRefs);
				}
				final g:Null<h2d.Graphics> = switch builtObject { case HeapsObject(obj) if (Std.isOfType(obj, h2d.Graphics)): cast obj; default: null; };
				if (g != null) {
					final elementsCapture = elements;
					final gridCapture = MultiAnimParser.getGridCoordinateSystem(node);
					final hexCapture = MultiAnimParser.getHexCoordinateSystem(node);
					ctx.trackExpression(() -> {
						g.clear();
						drawGraphicsElements(g, elementsCapture, gridCapture, hexCapture);
					}, gfxRefs, object);
				}
			case PIXELS(shapes):
				final pxRefs:Array<String> = [];
				collectPixelShapesParamRefs(shapes, pxRefs);
				if (pxRefs.length > 0) {
					final pl = switch builtObject { case Pixels(p): p; default: null; };
					if (pl != null) {
						final shapesCapture = shapes;
						final gridCapture = MultiAnimParser.getGridCoordinateSystem(node);
						final hexCapture = MultiAnimParser.getHexCoordinateSystem(node);
						final _nodeScale = node.scale;
						final pixelScaleCapture:Float = _nodeScale != null ? resolveAsNumber(_nodeScale) : 1.0;
						ctx.trackExpression(() -> {
							final result = drawPixels(shapesCapture, gridCapture, hexCapture);
							pl.tile = result.pixelLines.tile;
							pl.data = result.pixelLines.data;
							// Update constraint size so Bitmap doesn't stretch the new tile to the old canvas dimensions
							pl.width = result.pixelLines.tile.width;
							pl.height = result.pixelLines.tile.height;
							// Update position for new bounds (minX/minY change when shapes have dynamic widths)
							pl.setPosition(result.minX * pixelScaleCapture, result.minY * pixelScaleCapture);
						}, pxRefs, object);
					}
				}
			case MASK(width, height):
				final mRefs:Array<String> = [];
				collectParamRefs(width, mRefs);
				collectParamRefs(height, mRefs);
				if (mRefs.length > 0) {
					final m = switch builtObject { case HeapsMask(mm): mm; default: null; };
					if (m != null) {
						final wCapture = width;
						final hCapture = height;
						ctx.trackExpression(() -> {
							m.width = Math.round(resolveAsNumber(wCapture));
							m.height = Math.round(resolveAsNumber(hCapture));
						}, mRefs, object);
					}
				}
			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, _, paddingTop, paddingBottom, paddingLeft, paddingRight,
				horizontalSpacing, verticalSpacing, _, _, _, _, _, _, _, _, _, _):
				final f = switch builtObject { case HeapsFlow(ff): ff; default: null; };
				if (f != null) {
					inline function trackInt(rv:ReferenceableValue, apply:Int -> Void):Void {
						if (rv == null) return;
						final refs:Array<String> = [];
						collectParamRefs(rv, refs);
						if (refs.length == 0) return;
						final rvCapture = rv;
						ctx.trackExpression(() -> apply(resolveAsInteger(rvCapture)), refs, object);
					}
					trackInt(maxWidth,          v -> f.maxWidth = v);
					trackInt(maxHeight,         v -> f.maxHeight = v);
					trackInt(minWidth,          v -> f.minWidth = v);
					trackInt(minHeight,         v -> f.minHeight = v);
					trackInt(lineHeight,        v -> f.lineHeight = v);
					trackInt(colWidth,          v -> f.colWidth = v);
					trackInt(paddingTop,        v -> f.paddingTop = v);
					trackInt(paddingBottom,     v -> f.paddingBottom = v);
					trackInt(paddingLeft,       v -> f.paddingLeft = v);
					trackInt(paddingRight,      v -> f.paddingRight = v);
					trackInt(horizontalSpacing, v -> f.horizontalSpacing = v);
					trackInt(verticalSpacing,   v -> f.verticalSpacing = v);
				}
			case INTERACTIVE(width, height, id, _, metadata):
				// Track w/h only — id + metadata stay frozen at construction because
				// UIInteractiveWrapper caches them at registration time. Hit-test path
				// re-reads w/h from multiAnimType on every containsPoint() call, so
				// reassigning the enum with new dims propagates without wrapper rewiring.
				final iRefs:Array<String> = [];
				collectParamRefs(width, iRefs);
				collectParamRefs(height, iRefs);
				if (iRefs.length > 0) {
					final mao = switch builtObject { case HeapsObject(o) if (Std.isOfType(o, MAObject)): (cast o : MAObject); default: null; };
					if (mao != null) {
						final wCapture = width;
						final hCapture = height;
						ctx.trackExpression(() -> {
							final newW = resolveAsInteger(wCapture);
							final newH = resolveAsInteger(hCapture);
							switch mao.multiAnimType {
								case MAInteractive(_, _, keepId, keepMeta):
									mao.multiAnimType = MAInteractive(newW, newH, keepId, keepMeta);
								default:
							}
						}, iRefs, object);
					}
				}
				// Mark id + metadata value refs as incremental-unsupported.
				final idRefs:Array<String> = [];
				collectParamRefs(id, idRefs);
				for (r in idRefs) ctx.markParamUntracked(r, "interactive id");
				if (metadata != null) {
					for (entry in metadata) {
						final kRefs:Array<String> = [];
						collectParamRefs(entry.key, kRefs);
						for (r in kRefs) ctx.markParamUntracked(r, "interactive metadata key");
						final vRefs:Array<String> = [];
						collectParamRefs(entry.value, vRefs);
						for (r in vRefs) ctx.markParamUntracked(r, "interactive metadata value");
					}
				}
			case STATEANIM(_, initialState, selectorReferences):
				// Track initialState only. Selectors (which pick animation variants at load time)
				// and the filename itself stay frozen — changing them would require a full
				// detach/rebuild which is out of scope.
				final sRefs:Array<String> = [];
				collectParamRefs(initialState, sRefs);
				if (sRefs.length > 0) {
					final sm = switch builtObject { case StateAnim(a): a; default: null; };
					if (sm != null) {
						final initCapture = initialState;
						ctx.trackExpression(() -> {
							sm.play(resolveAsString(initCapture));
						}, sRefs, object);
					}
				}
				if (selectorReferences != null) {
					for (k => v in selectorReferences) {
						final selRefs:Array<String> = [];
						collectParamRefs(v, selRefs);
						for (r in selRefs) ctx.markParamUntracked(r, 'stateanim selector "$k"');
					}
				}
			case STATEANIM_CONSTRUCT(initialState, construct, _):
				final sRefs:Array<String> = [];
				collectParamRefs(initialState, sRefs);
				if (sRefs.length > 0) {
					final sm = switch builtObject { case StateAnim(a): a; default: null; };
					if (sm != null) {
						final initCapture = initialState;
						ctx.trackExpression(() -> {
							sm.play(resolveAsString(initCapture));
						}, sRefs, object);
					}
				}
				if (construct != null) {
					for (key => value in construct) {
						switch value {
							case IndexedSheet(_, animName, fps, _, _):
								final aRefs:Array<String> = [];
								collectParamRefs(animName, aRefs);
								for (r in aRefs) ctx.markParamUntracked(r, 'stateanim_construct animName "$key"');
								final fRefs:Array<String> = [];
								collectParamRefs(fps, fRefs);
								for (r in fRefs) ctx.markParamUntracked(r, 'stateanim_construct fps "$key"');
						}
					}
				}
			default:
		}

		// Track position if it references params
		final _pos = node.pos;
		if (_pos != null) {
			final posRefs:Array<String> = [];
			switch _pos {
				case OFFSET(x, y):
					collectParamRefs(x, posRefs);
					collectParamRefs(y, posRefs);
				case SELECTED_GRID_POSITION(gridX, gridY):
					collectParamRefs(gridX, posRefs);
					collectParamRefs(gridY, posRefs);
				case SELECTED_HEX_CORNER(count, factor):
					collectParamRefs(count, posRefs);
					collectParamRefs(factor, posRefs);
				case SELECTED_HEX_EDGE(direction, factor):
					collectParamRefs(direction, posRefs);
					collectParamRefs(factor, posRefs);
				case SELECTED_HEX_CUBE(q, r, s):
					collectParamRefs(q, posRefs);
					collectParamRefs(r, posRefs);
					collectParamRefs(s, posRefs);
				case SELECTED_HEX_OFFSET(col, row, _):
					collectParamRefs(col, posRefs);
					collectParamRefs(row, posRefs);
				case SELECTED_HEX_DOUBLED(col, row):
					collectParamRefs(col, posRefs);
					collectParamRefs(row, posRefs);
				case SELECTED_HEX_PIXEL(x, y):
					collectParamRefs(x, posRefs);
					collectParamRefs(y, posRefs);
				case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
					collectCoordinateParamRefs(cell, posRefs);
					collectParamRefs(cornerIndex, posRefs);
					collectParamRefs(factor, posRefs);
				case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
					collectCoordinateParamRefs(cell, posRefs);
					collectParamRefs(direction, posRefs);
					collectParamRefs(factor, posRefs);
				case NAMED_COORD(_, coord):
					collectCoordinateParamRefs(coord, posRefs);
				default:
			}
			if (posRefs.length > 0) {
				final posCapture = _pos;
				final gcs = MultiAnimParser.getGridCoordinateSystem(node);
				final hcs = MultiAnimParser.getHexCoordinateSystem(node);
				ctx.trackExpression(() -> {
					final p = calculatePosition(posCapture, gcs, hcs);
					object.x = p.x;
					object.y = p.y;
				}, posRefs, object);
			}
		}

		// Track scale/rotation/alpha/filter/tint if they reference params
		final extRefs:Array<String> = [];
		final _scale = node.scale; if (_scale != null) collectParamRefs(_scale, extRefs);
		final _rotation = node.rotation; if (_rotation != null) collectParamRefs(_rotation, extRefs);
		final _alpha = node.alpha; if (_alpha != null) collectParamRefs(_alpha, extRefs);
		final _tint = node.tint; if (_tint != null) collectParamRefs(_tint, extRefs);
		final _filter = node.filter; if (_filter != null) collectFilterParamRefs(_filter, extRefs);
		if (extRefs.length > 0) {
			ctx.trackExpression(() -> {
				applyExtendedFormProperties(object, node);
			}, extRefs, object);
		}
	}

	/** Collect all parameter references from a node's expressions (for deferred rebuild tracking). */
	function collectNodeParamRefs(node:Node):Array<String> {
		final refs:Array<String> = [];
		inline function addRef(ref:String) {
			if (refs.indexOf(ref) < 0) refs.push(ref);
		}
		inline function addRefs(arr:Array<String>) {
			for (r in arr) addRef(r);
		}
		// Type-specific refs
		switch node.type {
			case TEXT(textDef) | RICHTEXT(textDef):
				collectParamRefs(textDef.text, refs);
				collectParamRefs(textDef.color, refs);
			case NINEPATCH(_, _, width, height):
				collectParamRefs(width, refs);
				collectParamRefs(height, refs);
			case BITMAP(tileSource, _, _):
				collectTileSourceParamRefs(tileSource, refs);
			case GRAPHICS(elements):
				for (item in elements) {
					collectCoordinateParamRefs(item.pos, refs);
					collectGraphicsElementParamRefs(item.element, refs);
				}
			case PIXELS(shapes):
				collectPixelShapesParamRefs(shapes, refs);
			case REPEAT(_, repeatType):
				switch repeatType {
					case StepIterator(dirX, dirY, repeats):
						collectParamRefs(repeats, refs);
						if (dirX != null) collectParamRefs(dirX, refs);
						if (dirY != null) collectParamRefs(dirY, refs);
					case RangeIterator(start, end, step):
						collectParamRefs(start, refs);
						collectParamRefs(end, refs);
						collectParamRefs(step, refs);
					default:
				}
			case SWITCH(paramName, arms):
				addRef(paramName);
				for (arm in arms)
					for (child in arm.children)
						addRefs(collectNodeParamRefs(child));
			default:
		}
		// Position refs
		final _pos = node.pos;
		if (_pos != null) {
			final posRefs:Array<String> = [];
			collectCoordinateParamRefs(_pos, posRefs);
			addRefs(posRefs);
		}
		// Extended property refs
		if (node.scale != null) collectParamRefs(node.scale, refs);
		if (node.rotation != null) collectParamRefs(node.rotation, refs);
		if (node.alpha != null) collectParamRefs(node.alpha, refs);
		if (node.tint != null) collectParamRefs(node.tint, refs);
		if (node.filter != null) collectFilterParamRefs(node.filter, refs);
		// Recurse into children
		if (node.children != null) {
			for (child in node.children)
				addRefs(collectNodeParamRefs(child));
		}
		return refs;
	}

	function addPosition(obj:h2d.Object, x, y) {
		obj.x += x;
		obj.y += y;
	}

	@:nullSafety(Off)
	function calculatePosition(position, gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>):FPoint {
		inline function returnPosition(x:Float, y:Float):FPoint {
			return new FPoint(x, y);
		}

		if (builderParams == null)
			builderParams = {callback: defaultCallback};
		else if (builderParams.callback == null)
			builderParams.callback = defaultCallback;
		var pos:FPoint = switch position {
			case ZERO:
				returnPosition(0, 0);
			case OFFSET(x, y):
				returnPosition(resolveAsNumber(x), resolveAsNumber(y));
			case SELECTED_GRID_POSITION(gridX, gridY):
				if (gridCoordinateSystem == null)
					throw builderError('gridCoordinateSystem is null');
				gridCoordinateSystem.resolveAsGrid(resolveAsInteger(gridX), resolveAsInteger(gridY));
			case SELECTED_HEX_EDGE(direction, factor):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveAsHexEdge(resolveAsInteger(direction), resolveAsNumber(factor));
			case SELECTED_HEX_CORNER(count, factor):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveAsHexCorner(resolveAsInteger(count), resolveAsNumber(factor));
			case SELECTED_HEX_CUBE(q, r, s):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveHexCube(resolveAsNumber(q), resolveAsNumber(r), resolveAsNumber(s));
			case SELECTED_HEX_OFFSET(col, row, parity):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveHexOffset(resolveAsInteger(col), resolveAsInteger(row), parity);
			case SELECTED_HEX_DOUBLED(col, row):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveHexDoubled(resolveAsInteger(col), resolveAsInteger(row));
			case SELECTED_HEX_PIXEL(x, y):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				hexCoordinateSystem.resolveHexPixel(resolveAsNumber(x), resolveAsNumber(y));
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				final hex = resolveToHex(cell, hexCoordinateSystem);
				hexCoordinateSystem.resolveAsHexCellCorner(hex, resolveAsInteger(cornerIndex), resolveAsNumber(factor));
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				if (hexCoordinateSystem == null)
					throw builderError('hexCoordinateSystem is null');
				final hex = resolveToHex(cell, hexCoordinateSystem);
				hexCoordinateSystem.resolveAsHexCellEdge(hex, resolveAsInteger(direction), resolveAsNumber(factor));
			case LAYOUT(layoutName, index):
				var idx = 0;
				if (index != null)
					idx = resolveAsInteger(index);
				var pt = getLayouts(builderParams).getPoint(layoutName, idx);
				returnPosition(pt.x, pt.y);
			case NAMED_COORD(name, coord):
				final namedCS = MultiAnimParser.getNamedCoordinateSystem(name, currentNode);
				if (namedCS == null) throw builderError('unknown named coordinate system: $name');
				switch (namedCS) {
					case NamedGrid(system): calculatePosition(coord, system, hexCoordinateSystem);
					case NamedHex(system): calculatePosition(coord, gridCoordinateSystem, system);
				}
			case WITH_OFFSET(base, offsetX, offsetY):
				final basePt = calculatePosition(base, gridCoordinateSystem, hexCoordinateSystem);
				returnPosition(basePt.x + resolveAsNumber(offsetX), basePt.y + resolveAsNumber(offsetY));
			case EXTRA_POINT_REF(elementName, pointName, fallback):
				resolveExtraPointRef(elementName, pointName, fallback, gridCoordinateSystem, hexCoordinateSystem);
			case EXTRA_POINT_ANIM(filename, animName, pointName, selectorRefs, fallback):
				resolveExtraPointAnim(filename, animName, pointName, selectorRefs, fallback, gridCoordinateSystem, hexCoordinateSystem);
		}
		return pos;
	}

	function resolveExtraPointRef(elementName:String, pointName:String, fallback:Null<Coordinates>,
			gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>):FPoint {
		if (currentInternalResults == null)
			throw builderError('extraPoint reference $$${elementName}.extraPoint("$pointName"): no build context available');
		final named = currentInternalResults.names.get(elementName);
		if (named == null || named.length == 0)
			throw builderError('extraPoint reference $$${elementName}.extraPoint("$pointName"): element "$elementName" not found. '
				+ 'Ensure it is defined before this element');
		final animSM = switch named[0].object {
			case StateAnim(a): a;
			default: throw builderError('extraPoint reference $$${elementName}.extraPoint("$pointName"): "$elementName" is not a stateanim element');
		}
		final pt = animSM.getExtraPoint(pointName);
		if (pt != null)
			return new FPoint(pt.x, pt.y);
		if (fallback != null)
			return calculatePosition(fallback, gridCoordinateSystem, hexCoordinateSystem);
		throw builderError('extraPoint $$${elementName}.extraPoint("$pointName"): point "$pointName" not found in current animation '
			+ '"${animSM.current != null ? animSM.current.name : "(none)"}"');
	}

	function resolveExtraPointAnim(filename:String, animName:String, pointName:String,
			selectorRefs:Map<String, ReferenceableValue>, fallback:Null<Coordinates>,
			gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>):FPoint {
		final selector:Map<String, String> = [for (k => v in selectorRefs) k => resolveAsString(v)];
		final animSM = resourceLoader.createAnimSM(filename, selector);
		animSM.play(animName);
		final pt = animSM.getExtraPoint(pointName);
		if (pt != null)
			return new FPoint(pt.x, pt.y);
		if (fallback != null)
			return calculatePosition(fallback, gridCoordinateSystem, hexCoordinateSystem);
		throw builderError('extraPoint("$filename", "$animName", "$pointName"): point "$pointName" not found');
	}

	function resolveToHex(cell:Coordinates, hexCoordinateSystem:HexCoordinateSystem):bh.base.Hex {
		return switch cell {
			case SELECTED_HEX_CUBE(q, r, s):
				hexCoordinateSystem.resolveHexToHex(resolveAsNumber(q), resolveAsNumber(r), resolveAsNumber(s));
			case SELECTED_HEX_OFFSET(col, row, parity):
				final parityVal = switch (parity) { case EVEN: OffsetCoord.EVEN; case ODD: OffsetCoord.ODD; };
				switch (hexCoordinateSystem.hexLayout.orientation) {
					case POINTY: OffsetCoord.qoffsetToCube(parityVal, new OffsetCoord(resolveAsInteger(col), resolveAsInteger(row)));
					case FLAT: OffsetCoord.roffsetToCube(parityVal, new OffsetCoord(resolveAsInteger(col), resolveAsInteger(row)));
				};
			case SELECTED_HEX_DOUBLED(col, row):
				switch (hexCoordinateSystem.hexLayout.orientation) {
					case POINTY: DoubledCoord.qdoubledToCube(new DoubledCoord(resolveAsInteger(col), resolveAsInteger(row)));
					case FLAT: DoubledCoord.rdoubledToCube(new DoubledCoord(resolveAsInteger(col), resolveAsInteger(row)));
				};
			case SELECTED_HEX_PIXEL(x, y):
				hexCoordinateSystem.hexLayout.pixelToHex(new bh.base.FPoint(resolveAsNumber(x), resolveAsNumber(y))).round();
			case NAMED_COORD(name, coord):
				final node = currentNode;
				if (node == null) throw builderError('currentNode is null in resolveToHex');
				final namedCS = MultiAnimParser.getNamedCoordinateSystem(name, node);
				switch (namedCS) {
					case NamedHex(system): resolveToHex(coord, system);
					default: throw builderError('Named system $name is not a hex coordinate system');
				}
			default:
				throw builderError('Cannot resolve cell coordinates to hex: $cell');
		};
	}

	function drawPixels(shapes:Array<PixelShapes>, gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>) {
		var computedShapes:Array<ComputedShape> = [];
		var bounds = new h2d.col.IBounds();
		for (s in shapes) {
			switch s {
				case LINE(line):
					var startPos = calculatePosition(line.start, gridCoordinateSystem, hexCoordinateSystem);
					var endPos = calculatePosition(line.end, gridCoordinateSystem, hexCoordinateSystem);
					var x1 = Math.round(startPos.x);
					var y1 = Math.round(startPos.y);
					var x2 = Math.round(endPos.x);
					var y2 = Math.round(endPos.y);
				computedShapes.push(ComputedShape.Line(x1, y1, x2, y2, resolveAsColorInteger(line.color)));
					bounds.addPos(x1, y1);
					bounds.addPos(x2, y2);
				case RECT(rect) | FILLED_RECT(rect):
					var filled = switch s { case FILLED_RECT(_): true; default: false; };
					var start = calculatePosition(rect.start, gridCoordinateSystem, hexCoordinateSystem);
					var x = Math.round(start.x);
					var y = Math.round(start.y);
					var w = resolveAsInteger(rect.width);
					var h = resolveAsInteger(rect.height);
					computedShapes.push(ComputedShape.Rect(x, y, w, h, resolveAsColorInteger(rect.color), filled));
					bounds.addPos(x, y);
					bounds.addPos(x + w+1, y + h+1);
				case PIXEL(pixel):
					var pos = calculatePosition(pixel.pos, gridCoordinateSystem, hexCoordinateSystem);
					var x = Math.round(pos.x);
					var y = Math.round(pos.y);
					computedShapes.push(ComputedShape.Pixel(x, y, resolveAsColorInteger(pixel.color)));
					bounds.addPos(x, y);
			}
		}
		var minX:Int = bounds.xMin;
		var minY:Int = bounds.yMin;
		var width:Int = bounds.width +1;
		var height:Int = bounds.height + 1;
		var pl = new PixelLines(width,height);
		for (shape in computedShapes) {
			switch (shape) {
				case ComputedShape.Line(x1, y1, x2, y2, color):
					pl.line(x1 - minX, y1 - minY, x2 - minX, y2 - minY, color);
				case ComputedShape.Rect(x, y, w, h, color, filled):
					if (filled)
						pl.filledRect(x - minX, y - minY, w, h, color);
					else
						pl.rect(x - minX, y - minY, w, h, color);
				case ComputedShape.Pixel(x, y, color):
					pl.pixel(x - minX, y - minY, color);
			}
		}
		pl.updateBitmap();
		return {pixelLines: pl, minX: minX, minY: minY};
	}

	function drawGraphicsElements(g:h2d.Graphics, elements:Array<PositionedGraphicsElement>, gridCoordinateSystem, hexCoordinateSystem) {
		for (item in elements) {
			final elementPos = calculatePosition(item.pos, gridCoordinateSystem, hexCoordinateSystem).toPoint();
			g.lineStyle();
			switch item.element {
				case GERect(color, style, width, height):
					var resolvedColor = resolveAsColorInteger(color);
					switch style {
						case GSFilled:
							g.beginFill(resolvedColor);
							g.drawRect(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height));
							g.endFill();
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
							g.drawRect(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height));
							g.lineStyle();
					}
				case GEPolygon(color, style, points):
					var resolvedColor = resolveAsColorInteger(color);
					switch style {
						case GSFilled:
							g.beginFill(resolvedColor);
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
					}

					if (points.length > 0) {
						var firstPos = calculatePosition(points[0], gridCoordinateSystem, hexCoordinateSystem);
						var fx = firstPos.x + elementPos.x;
						var fy = firstPos.y + elementPos.y;
						g.moveTo(fx, fy);
						for (i in 1...points.length) {
							var pos = calculatePosition(points[i], gridCoordinateSystem, hexCoordinateSystem);
							g.lineTo(pos.x + elementPos.x, pos.y + elementPos.y);
						}
						g.lineTo(fx, fy);
					}

					switch style {
						case GSFilled: g.endFill();
						case GSLineWidth(_): g.lineStyle();
					}
				case GECircle(color, style, radius):
					var resolvedColor = resolveAsColorInteger(color);
					switch style {
						case GSFilled:
							g.beginFill(resolvedColor);
							g.drawCircle(elementPos.x, elementPos.y, resolveAsNumber(radius));
							g.endFill();
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
							g.drawCircle(elementPos.x, elementPos.y, resolveAsNumber(radius));
							g.lineStyle();
					}
				case GEEllipse(color, style, width, height):
					var resolvedColor = resolveAsColorInteger(color);
					switch style {
						case GSFilled:
							g.beginFill(resolvedColor);
							g.drawEllipse(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height));
							g.endFill();
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
							g.drawEllipse(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height));
							g.lineStyle();
					}
				case GEArc(color, style, radius, startAngle, arcAngle):
					var resolvedColor = resolveAsColorInteger(color);
					switch style {
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
							g.drawPie(elementPos.x, elementPos.y, resolveAsNumber(radius), hxd.Math.degToRad(resolveAsNumber(startAngle)), hxd.Math.degToRad(resolveAsNumber(arcAngle)));
							g.lineStyle();
						case GSFilled:
							// Arc doesn't support filled, treat as line
							g.lineStyle(1.0, resolvedColor);
							g.drawPie(elementPos.x, elementPos.y, resolveAsNumber(radius), hxd.Math.degToRad(resolveAsNumber(startAngle)), hxd.Math.degToRad(resolveAsNumber(arcAngle)));
							g.lineStyle();
					}
				case GERoundRect(color, style, width, height, radius):
					var resolvedColor = resolveAsColorInteger(color);
					var rad = resolveAsNumber(radius);
					switch style {
						case GSFilled:
							g.beginFill(resolvedColor);
							g.drawRoundedRect(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height), rad);
							g.endFill();
						case GSLineWidth(lw):
							g.lineStyle(resolveAsNumber(lw), resolvedColor);
							g.drawRoundedRect(elementPos.x, elementPos.y, resolveAsNumber(width), resolveAsNumber(height), rad);
							g.lineStyle();
					}
				case GELine(color, lineWidth, start, end):
					var resolvedColor = resolveAsColorInteger(color);
					var startPos = calculatePosition(start, gridCoordinateSystem, hexCoordinateSystem);
					var endPos = calculatePosition(end, gridCoordinateSystem, hexCoordinateSystem);
					g.lineStyle(resolveAsNumber(lineWidth), resolvedColor);
					g.moveTo(elementPos.x + startPos.x, elementPos.y + startPos.y);
					g.lineTo(elementPos.x + endPos.x, elementPos.y + endPos.y);
					g.lineStyle();
			}
		}
	}

	private function resolveTileGroupRepeatAxis(repeatType:RepeatType, node:Node, allowTileIterators:Bool):{
		dx:Int, dy:Int, repeatCount:Int,
		layoutName:Null<String>,
		arrayIterator:Array<String>, valueVariableName:Null<String>,
		rangeStart:Int, rangeStep:Int,
		tileSourceIterator:Array<TileSource>, tilenameIterator:Array<String>,
		bitmapVarName:Null<String>, tilenameVarName:Null<String>,
	} {
		var dx = 0;
		var dy = 0;
		var repeatCount = 0;
		var layoutName:Null<String> = null;
		var arrayIterator:Array<String> = [];
		var valueVariableName:Null<String> = null;
		var rangeStart = 0;
		var rangeStep = 1;
		var tileSourceIterator:Array<TileSource> = [];
		var tilenameIterator:Array<String> = [];
		var bitmapVarName:Null<String> = null;
		var tilenameVarName:Null<String> = null;

		switch repeatType {
			case StepIterator(dirX, dirY, repeats):
				repeatCount = resolveAsInteger(repeats);
				dx = dirX == null ? 0 : resolveAsInteger(dirX);
				dy = dirY == null ? 0 : resolveAsInteger(dirY);
			case LayoutIterator(ln):
				final l = getLayouts();
				repeatCount = l.getLayoutSequenceLengthByLayoutName(ln);
				layoutName = ln;
			case ArrayIterator(varName, arrayName):
				arrayIterator = resolveAsArray(RVArrayReference(arrayName));
				repeatCount = arrayIterator.length;
				valueVariableName = varName;
			case RangeIterator(start, end, step):
				rangeStart = resolveAsInteger(start);
				final rangeEnd = resolveAsInteger(end);
				rangeStep = resolveAsInteger(step);
				repeatCount = Math.ceil((rangeEnd - rangeStart) / rangeStep);
			case StateAnimIterator(bmpVarName, animFilename, animationName, selectorRefs):
				if (!allowTileIterators)
					throw builderErrorAt(node, 'StateAnimIterator not supported in REPEAT2D');
				final selector = [for (k => v in selectorRefs) k => resolveAsString(v)];
				final animName = resolveAsString(animationName);
				tileSourceIterator = collectStateAnimFrames(animFilename, animName, selector);
				repeatCount = tileSourceIterator.length;
				bitmapVarName = bmpVarName;
			case TilesIterator(bmpVarName, tnVarName, sheetName, tileFilter):
				if (!allowTileIterators)
					throw builderErrorAt(node, 'TilesIterator not supported in REPEAT2D');
				bitmapVarName = bmpVarName;
				tilenameVarName = tnVarName;
				final sheet = getOrLoadSheet(sheetName);
				if (tileFilter != null) {
					final frames = sheet.getAnim(tileFilter);
					if (frames == null) {
						throw builderErrorAt(node, 'Tile "${tileFilter}" not found in sheet "${sheetName}". The tile filter must be an exact tile name (key) in the atlas.');
					}
					for (frame in frames) {
						if (frame != null && frame.tile != null) {
							tileSourceIterator.push(TSTile(frame.tile));
						}
					}
				} else {
					for (tn => entries in sheet.getContents()) {
						for (entry in entries) {
							if (entry != null) {
								tileSourceIterator.push(TSTile(entry.t));
								tilenameIterator.push(tn);
							}
						}
					}
				}
				repeatCount = tileSourceIterator.length;
		}

		return {
			dx: dx, dy: dy, repeatCount: repeatCount,
			layoutName: layoutName,
			arrayIterator: arrayIterator, valueVariableName: valueVariableName,
			rangeStart: rangeStart, rangeStep: rangeStep,
			tileSourceIterator: tileSourceIterator, tilenameIterator: tilenameIterator,
			bitmapVarName: bitmapVarName, tilenameVarName: tilenameVarName,
		};
	}

	private function setTileGroupRepeatIterationParams(varName:String, repeatType:RepeatType, info:{
		rangeStart:Int, rangeStep:Int,
		arrayIterator:Array<String>, valueVariableName:Null<String>,
		tileSourceIterator:Array<TileSource>, tilenameIterator:Array<String>,
		bitmapVarName:Null<String>, tilenameVarName:Null<String>,
	}, count:Int):Void {
		final resolvedIndex = switch repeatType {
			case RangeIterator(_, _, _): info.rangeStart + count * info.rangeStep;
			case _: count;
		};
		indexedParams.set(varName, Value(resolvedIndex));
		if (info.valueVariableName != null)
			indexedParams.set(info.valueVariableName, StringValue(info.arrayIterator[count]));
		if (info.bitmapVarName != null)
			indexedParams.set(info.bitmapVarName, TileSourceValue(info.tileSourceIterator[count]));
		if (info.tilenameVarName != null && count < info.tilenameIterator.length)
			indexedParams.set(info.tilenameVarName, StringValue(info.tilenameIterator[count]));
	}

	private function cleanupTileGroupRepeatExtraVars(info:{bitmapVarName:Null<String>, tilenameVarName:Null<String>}):Void {
		if (info.bitmapVarName != null) indexedParams.remove(info.bitmapVarName);
		if (info.tilenameVarName != null) indexedParams.remove(info.tilenameVarName);
	}

	@:nullSafety(Off)
	function buildTileGroup(node:Node, tileGroup:h2d.TileGroup, currentPos:Point, gridCoordinateSystem:GridCoordinateSystem,
			hexCoordinateSystem:HexCoordinateSystem, builderParams:BuilderParameters):Void {
		if (shouldBuildInFullMode(node, indexedParams) == false)
			return;
		this.currentNode = node;

		var pos = calculatePosition(node.pos, gridCoordinateSystem, hexCoordinateSystem).toPoint();
		currentPos.add(pos.x, pos.y);
		var skipChildren = false;
		var tileGroupTile = switch node.type {
			case NINEPATCH(sheet, tilename, width, height):
				addNinePatchToTileGroup(node, sheet, tilename, width, height, currentPos, tileGroup);
				null;
			case BITMAP(tileSource, hAlign, vAlign):
				var tile = loadTileSource(tileSource);
				var height = tile.height;
				var width = tile.width;
				var dh = switch vAlign {
					case Top: 0.;
					case Center: -(height * .5);
					case Bottom: -height;
				}
				var wh = switch hAlign {
					case Left: 0.;
					case Right: -width;
					case Center: -(width * .5);
				}

				tile = tile.sub(0, 0, width, height, wh, dh);
				tile;
			case POINT:
				null;
			case SWITCH(paramName, arms):
				final matchedArm = resolveMatchedSwitchArm(paramName, arms);
				if (matchedArm != null) {
					for (child in matchedArm.children) {
						buildTileGroup(child, tileGroup, currentPos.clone(), gridCoordinateSystem, hexCoordinateSystem, builderParams);
					}
				}
				skipChildren = true;
				null;
			case REPEAT(varName, repeatType):
				final info = resolveTileGroupRepeatAxis(repeatType, node, true);
				final iterator = info.layoutName == null ? null : getLayouts().getIterator(info.layoutName);

				if (indexedParams.exists(node.updatableName.getNameString()))
					throw builderErrorAt(node, 'cannot use repeatable index param "$varName" as it is already defined');
				for (count in 0...info.repeatCount) {
					final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
					final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);
					setTileGroupRepeatIterationParams(varName, repeatType, info, count);
					final resolvedChildren = resolveConditionalChildren(node.children);
					// Resolve layout point once per iteration (not per child)
					var layoutPt:Null<FPoint> = iterator != null ? iterator.next() : null;
					for (childNode in resolvedChildren) {
						var iterPos = currentPos.clone();
						switch repeatType {
							case StepIterator(_, _, _):
								iterPos.add(info.dx * count, info.dy * count);
							case LayoutIterator(_):
								iterPos.add(cast layoutPt.x, cast layoutPt.y);
							default:
						}
						buildTileGroup(childNode, tileGroup, iterPos, gridCoordinateSystem, hexCoordinateSystem, builderParams);
					}
					cleanupFinalVars(resolvedChildren, indexedParams);
				}
				indexedParams.remove(varName);
				cleanupTileGroupRepeatExtraVars(info);
				skipChildren = true;
				null;
			case REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY):
				final xInfo = resolveTileGroupRepeatAxis(repeatTypeX, node, false);
				final yInfo = resolveTileGroupRepeatAxis(repeatTypeY, node, false);

				if (indexedParams.exists(varNameX) || indexedParams.exists(varNameY))
					throw builderErrorAt(node, 'cannot use repeatable2d index param "$varNameX" or "$varNameY" as it is already defined');
				var yIterator = yInfo.layoutName == null ? null : getLayouts().getIterator(yInfo.layoutName);
				for (yCount in 0...yInfo.repeatCount) {
					var yOffsetX = 0;
					var yOffsetY = 0;
					switch repeatTypeY {
						case StepIterator(_, _, _):
							yOffsetX = yInfo.dx * yCount;
							yOffsetY = yInfo.dy * yCount;
						case LayoutIterator(_):
							var pt = yIterator.next();
							yOffsetX = cast pt.x;
							yOffsetY = cast pt.y;
						default:
					}
					var xIterator = xInfo.layoutName == null ? null : getLayouts().getIterator(xInfo.layoutName);
					for (xCount in 0...xInfo.repeatCount) {
						var xOffsetX = 0;
						var xOffsetY = 0;
						switch repeatTypeX {
							case StepIterator(_, _, _):
								xOffsetX = xInfo.dx * xCount;
								xOffsetY = xInfo.dy * xCount;
							case LayoutIterator(_):
								var pt = xIterator.next();
								xOffsetX = cast pt.x;
								xOffsetY = cast pt.y;
							default:
						}
						setTileGroupRepeatIterationParams(varNameX, repeatTypeX, xInfo, xCount);
						setTileGroupRepeatIterationParams(varNameY, repeatTypeY, yInfo, yCount);
						final resolvedChildren = resolveConditionalChildren(node.children);
						for (childNode in resolvedChildren) {
							var iterPos = currentPos.clone();
							iterPos.add(xOffsetX + yOffsetX, xOffsetY + yOffsetY);
							buildTileGroup(childNode, tileGroup, iterPos, gridCoordinateSystem, hexCoordinateSystem, builderParams);
						}
						cleanupFinalVars(resolvedChildren, indexedParams);
					}
				}
				indexedParams.remove(varNameX);
				indexedParams.remove(varNameY);
				skipChildren = true;
				null;
			case PIXELS(shapes):
				final pixelsResult = drawPixels(shapes, gridCoordinateSystem, hexCoordinateSystem);
				pixelsResult.pixelLines.tile;
			case FINAL_VAR(name, expr):
				evaluateAndStoreFinal(name, expr, node);
				null;
			default: throw builderErrorAt(node, 'unsupported node ${node.uniqueNodeName} ${node.type} in tileGroup mode');
		}

		addToTileGroup(node, currentPos, tileGroupTile, tileGroup);

		if (!skipChildren) { // for repeatable, as children were already processed
			final resolvedChildren = resolveConditionalChildren(node.children);
			for (childNode in resolvedChildren) {
				buildTileGroup(childNode, tileGroup, currentPos.clone(), MultiAnimParser.getGridCoordinateSystem(childNode),
					MultiAnimParser.getHexCoordinateSystem(childNode), builderParams);
			}
			cleanupFinalVars(resolvedChildren, indexedParams);
		}
	}

	function addToTileGroup(node:Node, currentPos:Point, tileGroupTile:h2d.Tile, tileGroup:h2d.TileGroup) {
		if (tileGroupTile != null) {
			final scale = node.scale == null ? 1.0 : resolveAsNumber(node.scale);
			tileGroup.setDefaultColor(0xFFFFFF, node.alpha != null ? resolveAsNumber(node.alpha) : 1.0);
			if (node.filter != null && node.filter != FilterNone)
				throw builderErrorAt(node, 'tileGroup does not support filters for ${node.type}');
			if (node.blendMode != null && node.blendMode != MBAlpha)
				throw builderErrorAt(node, 'tileGroup does not support blendMode other than Alpha for ${node.type}');
			tileGroup.addTransform(currentPos.x, currentPos.y, scale, scale, 0, tileGroupTile);
		}
	}

	function addNinePatchToTileGroup(node:Node, sheet:String, tilename:String, widthRV:ReferenceableValue, heightRV:ReferenceableValue,
			currentPos:Point, tileGroup:h2d.TileGroup):Void {
		final atlasSheet = getOrLoadSheet(sheet);
		if (atlasSheet == null)
			throw builderError('sheet ${sheet} could not be loaded');
		final entries = atlasSheet.getContents().get(tilename);
		if (entries == null || entries.length == 0 || entries[0] == null)
			throw builderError('tile ${tilename} in sheet ${sheet} could not be loaded');
		final entry = entries[0];
		final srcTile = entry.t;
		if (entry.split == null || entry.split.length != 4)
			throw builderError('tile ${tilename} in sheet ${sheet} is not a valid 9-patch (needs split with 4 values)');

		final bl:Float = entry.split[0]; // border left
		final br:Float = entry.split[1]; // border right
		final bt:Float = entry.split[2]; // border top
		final bb:Float = entry.split[3]; // border bottom

		final targetW:Float = resolveAsNumber(widthRV);
		final targetH:Float = resolveAsNumber(heightRV);
		final scale:Float = node.scale == null ? 1.0 : resolveAsNumber(node.scale);

		if (node.filter != null && node.filter != FilterNone)
			throw builderErrorAt(node, 'tileGroup does not support filters for ${node.type}');
		if (node.blendMode != null && node.blendMode != MBAlpha)
			throw builderErrorAt(node, 'tileGroup does not support blendMode other than Alpha for ${node.type}');

		tileGroup.setDefaultColor(0xFFFFFF, node.alpha != null ? resolveAsNumber(node.alpha) : 1.0);

		final px:Float = currentPos.x;
		final py:Float = currentPos.y;

		// Source inner region dimensions
		final srcInnerW:Float = srcTile.width - bl - br;
		final srcInnerH:Float = srcTile.height - bt - bb;

		// Target inner region dimensions
		final innerW:Float = targetW - bl - br;
		final innerH:Float = targetH - bt - bb;

		// 4 corners (no stretching, rendered at native border sizes)
		if (bl > 0 && bt > 0) {
			final t = srcTile.sub(0, 0, bl, bt);
			tileGroup.addTransform(px, py, scale, scale, 0, t);
		}
		if (br > 0 && bt > 0) {
			final t = srcTile.sub(srcTile.width - br, 0, br, bt);
			tileGroup.addTransform(px + (targetW - br) * scale, py, scale, scale, 0, t);
		}
		if (bl > 0 && bb > 0) {
			final t = srcTile.sub(0, srcTile.height - bb, bl, bb);
			tileGroup.addTransform(px, py + (targetH - bb) * scale, scale, scale, 0, t);
		}
		if (br > 0 && bb > 0) {
			final t = srcTile.sub(srcTile.width - br, srcTile.height - bb, br, bb);
			tileGroup.addTransform(px + (targetW - br) * scale, py + (targetH - bb) * scale, scale, scale, 0, t);
		}

		// 4 edges (scaled in one direction to fill target dimensions)
		if (srcInnerW > 0 && bt > 0 && innerW > 0) {
			final t = srcTile.sub(bl, 0, srcInnerW, bt);
			t.scaleToSize(innerW, bt);
			tileGroup.addTransform(px + bl * scale, py, scale, scale, 0, t);
		}
		if (srcInnerW > 0 && bb > 0 && innerW > 0) {
			final t = srcTile.sub(bl, srcTile.height - bb, srcInnerW, bb);
			t.scaleToSize(innerW, bb);
			tileGroup.addTransform(px + bl * scale, py + (targetH - bb) * scale, scale, scale, 0, t);
		}
		if (bl > 0 && srcInnerH > 0 && innerH > 0) {
			final t = srcTile.sub(0, bt, bl, srcInnerH);
			t.scaleToSize(bl, innerH);
			tileGroup.addTransform(px, py + bt * scale, scale, scale, 0, t);
		}
		if (br > 0 && srcInnerH > 0 && innerH > 0) {
			final t = srcTile.sub(srcTile.width - br, bt, br, srcInnerH);
			t.scaleToSize(br, innerH);
			tileGroup.addTransform(px + (targetW - br) * scale, py + bt * scale, scale, scale, 0, t);
		}

		// Center (scaled in both directions)
		if (srcInnerW > 0 && srcInnerH > 0 && innerW > 0 && innerH > 0) {
			final t = srcTile.sub(bl, bt, srcInnerW, srcInnerH);
			t.scaleToSize(innerW, innerH);
			tileGroup.addTransform(px + bl * scale, py + bt * scale, scale, scale, 0, t);
		}
	}

	@:nullSafety(Off)
	function build(node:Node, buildMode:InternalBuildMode, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem,
			internalResults:InternalBuilderResults, builderParams:BuilderParameters):h2d.Object {
		final nodeVisible = shouldBuildInFullMode(node, indexedParams);
		if (!nodeVisible && !incrementalMode)
			return null;
		this.currentNode = node;
		this.currentInternalResults = internalResults;
		var skipChildren = false;
		var layersParent:Null<h2d.Layers> = null;

		var selectedBuildMode:Null<InternalBuildMode> = null;
		var current = switch buildMode {
			case RootMode: null;
			case ObjectMode(current):
				current;
			case LayersMode(current):
				current;
				layersParent = current;
				current;
			case TileGroupMode(tg):
				buildTileGroup(node, tg, new Point(0, 0), gridCoordinateSystem, hexCoordinateSystem, builderParams);
				return null;
		}

		function addChild(toAdd:h2d.Object) {
			if (node.layer != -1) {
				if (layersParent != null)
					layersParent.add(toAdd, node.layer);
				else
					throw builderErrorAt(node, 'No layers parent for ${node.uniqueNodeName}-${node.type}');
			} else if (current != null)
				current.addChild(toAdd);
			// else do not add as this is root node
		}

		// Deferred build: skip expression evaluation for non-visible conditional nodes (like repeatables).
		// APPLY and FINAL_VAR are excluded — APPLY modifies the parent (handled via conditionalApplyEntries),
		// FINAL_VAR defines constants with no visual output.
		if (!nodeVisible && incrementalMode && node.conditionals != NoConditional && incrementalContext != null
				&& !node.type.match(APPLY) && !node.type.match(FINAL_VAR(_, _))) {
			final sentinel = new h2d.Object();
			addChild(sentinel);
			var wrapper = new h2d.Object();
			addChild(wrapper);
			wrapper.name = node.uniqueNodeName;
			final deferParent = if (node.layer != -1 && layersParent != null) cast(layersParent, h2d.Object) else current;
			incrementalContext.trackDeferredConditional(wrapper, node, sentinel, deferParent, node.layer,
				gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			// Remove from graph — sentinel stays as position anchor
			if (deferParent != null) deferParent.removeChild(wrapper);
			return wrapper;
		}

		final builtObject:BuiltHeapsComponent = switch node.type {
			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight,
				horizontalSpacing, verticalSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse, hAlign, vAlign):
				var f = new h2d.Flow();

				if (maxWidth != null)
					f.maxWidth = resolveAsInteger(maxWidth);
				if (maxHeight != null)
					f.maxHeight = resolveAsInteger(maxHeight);
				if (minWidth != null)
					f.minWidth = resolveAsInteger(minWidth);
				if (minHeight != null)
					f.minHeight = resolveAsInteger(minHeight);

				if (lineHeight != null)
					f.lineHeight = resolveAsInteger(lineHeight);
				if (colWidth != null)
					f.colWidth = resolveAsInteger(colWidth);
				if (layout != null)
					f.layout = MacroCompatConvert.toH2dFlowLayout(layout);

				if (paddingTop != null)
					f.paddingTop = resolveAsInteger(paddingTop);
				if (paddingBottom != null)
					f.paddingBottom = resolveAsInteger(paddingBottom);
				if (paddingLeft != null)
					f.paddingLeft = resolveAsInteger(paddingLeft);
				if (paddingRight != null)
					f.paddingRight = resolveAsInteger(paddingRight);

				if (horizontalSpacing != null)
					f.horizontalSpacing = resolveAsInteger(horizontalSpacing);
				if (verticalSpacing != null)
					f.verticalSpacing = resolveAsInteger(verticalSpacing);

				f.debug = debug;
				f.multiline = multiline;
				f.overflow = if (overflow != null) MacroCompatConvert.toH2dFlowOverflow(overflow) else Limit;
				if (fillWidth) f.fillWidth = true;
				if (fillHeight) f.fillHeight = true;
				if (reverse) f.reverse = true;

				if (hAlign != null)
					f.horizontalAlign = MacroCompatConvert.toH2dFlowAlign(hAlign);
				if (vAlign != null)
					f.verticalAlign = MacroCompatConvert.toH2dFlowAlign(vAlign);

				if (bgSheet != null && bgTile != null) {
					final sg = load9Patch(resolveAsString(bgSheet), resolveAsString(bgTile));
					f.borderLeft = sg.borderLeft;
					f.borderRight = sg.borderRight;
					f.borderTop = sg.borderTop;
					f.borderBottom = sg.borderBottom;
					f.backgroundTile = sg.tile;
				}

				HeapsFlow(f);
			case LAYERS:
				final l = new Layers(current);
				selectedBuildMode = LayersMode(l);
				HeapsLayers(l);
			case MASK(width, height):
				final w = Math.round(resolveAsNumber(width));
				final h = Math.round(resolveAsNumber(height));
				final m = new Mask(w, h);
				HeapsMask(m);
			case SPACER(width, height):
				final obj = new h2d.Object();
				skipChildren = true;
				HeapsObject(obj);
			case SLOT(parameters, paramOrder):
				final container = new h2d.Object();
				HeapsObject(container);
			case SLOT_CONTENT:
				final obj = new SlotContentRoot();
				HeapsObject(obj);
			case NINEPATCH(sheet, tilename, width, height):
				var sg = load9Patch(sheet, tilename);

				sg.width = resolveAsNumber(width);
				sg.height = resolveAsNumber(height);
				sg.tileCenter = true;
				sg.tileBorders = true;
				sg.ignoreScale = false;
				NinePatch(sg);
			case BITMAP(tileSource, hAlign, vAlign):
				var tile = loadTileSource(tileSource);

				var height = tile.height;
				var width = tile.width;
				final hasPivot = tileSource.match(TSPivot(_, _, _));
				var dh = if (hasPivot) tile.dy else switch vAlign {
					case Top: 0.;
					case Center: -(height * .5);
					case Bottom: -height;
				}
				var wh = if (hasPivot) tile.dx else switch hAlign {
					case Left: 0.;
					case Right: -width;
					case Center: -(width * .5);
				}

				tile = tile.sub(0, 0, width, height, wh, dh);
				var b = new h2d.Bitmap(tile);
				HeapsBitmap(b);
			case TEXT(textDef):
				final font = resourceLoader.loadFont(resolveAsString(textDef.fontName));
				var t = new h2d.Text(font);
				t.textAlign = switch textDef.halign {
					case null: Left;
					case Left: Left;
					case Right: Right;
					case Center: Center;
				}
				if (textDef.textAlignWidth != null) {
					final scaleAdjust = if (node.scale != null) resolveAsNumber(node.scale) else 1.0;
					switch textDef.textAlignWidth {
						case TAWValue(value):
								t.maxWidth = resolveAsNumber(value) / scaleAdjust;
						case TAWGrid:
							if (gridCoordinateSystem != null)
								t.maxWidth = gridCoordinateSystem.spacingX / scaleAdjust;
						case TAWAuto:
							t.maxWidth = null;
					}
				}
				t.letterSpacing = textDef.letterSpacing;
				t.lineSpacing = textDef.lineSpacing;
				t.lineBreak = textDef.lineBreak;
				if (textDef.dropShadowXY != null) {
					t.dropShadow = {
						dx: textDef.dropShadowXY.x,
						dy: textDef.dropShadowXY.y,
						color: textDef.dropShadowColor,
						alpha: textDef.dropShadowAlpha,
					};
				}
				t.textColor = resolveAsColorInteger(textDef.color);
				t.text = resolveAsString(textDef.text);
				if (textDef.autoFitFonts != null)
					applyAutoFit(t, textDef, node);
				HeapsText(t);
			case RICHTEXT(textDef):
				final font = resourceLoader.loadFont(resolveAsString(textDef.fontName));
				final ht = createHtmlText(font);

				if (textDef.styles != null) {
					for (style in textDef.styles) {
						final color:Null<Int> = if (style.color != null) resolveAsColorInteger(style.color) & 0xFFFFFF else null;
						final fontStr:Null<String> = if (style.fontName != null) resolveAsString(style.fontName) else null;
						ht.defineHtmlTag(TextMarkupConverter.escapeStyleName(style.name), color, fontStr);
					}
				}
				if (textDef.images != null) {
					final imageMap = new haxe.ds.StringMap<h2d.Tile>();
					for (img in textDef.images) {
						imageMap.set(img.name, loadTileSource(img.tileSource));
					}
					ht.loadImage = (url) -> imageMap.get(url);
				}
				if (textDef.condenseWhite != null) {
					ht.condenseWhite = textDef.condenseWhite;
				}
				ht.onHyperlink = (url) -> {
					if (builderParams != null && builderParams.callback != null) {
						try builderParams.callback(Name("link:" + url)) catch(e:Dynamic) { trace('Hyperlink callback error: $e'); #if MULTIANIM_DEV throw e; #end };
					}
				};
				ht.onOverHyperlink = (url) -> {
					hxd.System.setCursor(Button);
				};
				ht.onOutHyperlink = (url) -> {
					hxd.System.setCursor(Default);
				};
				internalResults.htmlTextsWithLinks.push(ht);

				ht.textAlign = switch textDef.halign {
					case null: Left;
					case Left: Left;
					case Right: Right;
					case Center: Center;
				}
				if (textDef.textAlignWidth != null) {
					final scaleAdjust = if (node.scale != null) resolveAsNumber(node.scale) else 1.0;
					switch textDef.textAlignWidth {
						case TAWValue(value):
								ht.maxWidth = resolveAsNumber(value) / scaleAdjust;
						case TAWGrid:
							if (gridCoordinateSystem != null)
								ht.maxWidth = gridCoordinateSystem.spacingX / scaleAdjust;
						case TAWAuto:
							ht.maxWidth = null;
					}
				}
				ht.letterSpacing = textDef.letterSpacing;
				ht.lineSpacing = textDef.lineSpacing;
				ht.lineBreak = textDef.lineBreak;
				if (textDef.dropShadowXY != null) {
					ht.dropShadow = {
						dx: textDef.dropShadowXY.x,
						dy: textDef.dropShadowXY.y,
						color: textDef.dropShadowColor,
						alpha: textDef.dropShadowAlpha,
					};
				}

				ht.textColor = resolveAsColorInteger(textDef.color);
				final rawText = resolveAsString(textDef.text);
				ht.text = TextMarkupConverter.convert(rawText);
				if (textDef.autoFitFonts != null)
					applyAutoFit(ht, textDef, node);

				HeapsText(ht);
			// case HTMLTEXT(fontname, textRef, color, align, textAlignWidth):
			// 	final font = resourceLoader.loadFont(resolveAsString(fontname));
			// 	var t = new h2d.HtmlText(font);
			// 	t.loadFont = x->resourceLoader.loadFont(x);
			// 	t.loadImage = x->resourceLoader.loadTile(x);

			// 	t.text = resolveAsString(textRef);
			// 	t.textColor = resolveAsColorInteger(color);

			// 	t.textAlign = switch align {
			// 		case null: Left;
			// 		case Left: Left;
			// 		case Right: Right;
			// 		case Center: Center;
			// 	}
			// 	if (textAlignWidth != null) t.maxWidth = textAlignWidth;
			// 	HeapsText(t);

			case RELATIVE_LAYOUTS(_): throw builderErrorAt(node, 'layouts not allowed as non-root node');
			case ANIMATED_PATH(_): throw builderErrorAt(node, 'animatedPath not allowed as non-root node');
			case PATHS(_): throw builderErrorAt(node, 'paths not allowed as non-root node');
			case CURVES(_): throw builderErrorAt(node, 'curves not allowed as non-root node');
			case PARTICLES(particlesDef):
				Particles(createParticleImpl(particlesDef, node.uniqueNodeName));
			case PALETTE(_): throw builderErrorAt(node, 'palette not allowed as non-root node');
			case AUTOTILE(_): throw builderErrorAt(node, 'autotile not allowed as non-root node');
			case ATLAS2(_): throw builderErrorAt(node, 'atlas2 is a definition node, not a renderable element');
			case DATA(_): throw builderErrorAt(node, 'data is a definition node, not a renderable element');

			case PLACEHOLDER(type, source):
				var settings = resolveSettings(node);

				function getH2dObj(result:CallbackResult):Null<h2d.Object> {
					return switch result {
						case CBRObject(val): val;
						case CBRNoResult: null;
						case null: null;
						default: throw builderError('expected h2d.object but got $result');
					}
				}
				var callbackResultH2dObject:Null<h2d.Object> = switch source {
					case PRSCallback(callbackName):
						getH2dObj(builderParams.callback(Placeholder(resolveAsString(callbackName))));
					case PRSCallbackWithIndex(callbackName, index):
						getH2dObj(builderParams.callback(PlaceholderWithIndex(resolveAsString(callbackName), resolveAsInteger(index))));
					case PRSBuilderParameterSource(callbackName):
						if (builderParams.placeholderObjects == null) null; else {
							var param = builderParams.placeholderObjects.get(resolveAsString(callbackName));
							switch param {
								case null: null;
								case PVObject(obj):
									#if MULTIANIM_DEV
									if (settings != null)
										trace('Warning: PVObject placeholder "${resolveAsString(callbackName)}" ignores .manim settings — use PVFactory instead to receive settings');
									#end
									obj;
								case PVFactory(factoryMethod):
									factoryMethod(settings);
								case PVComponent(factoryMethod, _):
									factoryMethod(settings);
							}
						}
				}
				#if MULTIANIM_DEV
				// Track callback-provided objects for hot reload reuse
				if (callbackResultH2dObject != null) {
					switch source {
						case PRSCallback(callbackName):
							devPlaceholderCapture.push({name: resolveAsString(callbackName), index: null, object: callbackResultH2dObject});
						case PRSCallbackWithIndex(callbackName, index):
							devPlaceholderCapture.push({name: resolveAsString(callbackName), index: resolveAsInteger(index), object: callbackResultH2dObject});
						case PRSBuilderParameterSource(callbackName):
							devPlaceholderCapture.push({name: resolveAsString(callbackName), index: null, object: callbackResultH2dObject});
					}
				}
				#end

				if (callbackResultH2dObject == null) {
					switch type {
						case PHTileSource(source):
							final tile = loadTileSource(source);
							HeapsBitmap(new h2d.Bitmap(tile));
						case PHNothing: HeapsObject(new h2d.Object());
						case PHError: throw builderErrorAt(node, 'placeholder ${node.updatableName}, type ${node.type} configured in error mode, no input from $source');
					}
				} else {
					HeapsObject(callbackResultH2dObject);
				}

			case STATIC_REF(externalReference, progRefRV, parameters):
				final reference = resolveRefName(progRefRV);
				var builder = if (externalReference != null) {
					var builder = multiParserResult.imports?.get(externalReference);
					if (builder == null)
						throw builderErrorAt(node, 'could not find builder for external staticRef ${externalReference}');
					builder;
				} else this;

				var result = builder.buildWithParameters(reference, parameters, builderParams, indexedParams);
				var object = result?.object;
				if (object == null)
					throw builderErrorAt(node, 'could not build staticRef ${reference}');

				// When the referenced programmable has a non-zero pos, buildWithParameters wraps it:
				// holder(0,0) → retRoot(posX,posY) → children
				// Reference children should be added to retRoot so they inherit the position offset,
				// not to the holder which is at (0,0).
				if (object.numChildren == 1) {
					final inner = object.getChildAt(0);
					if (inner.x != 0 || inner.y != 0) {
						selectedBuildMode = ObjectMode(inner);
					}
				}

				HeapsObject(object);

			case DYNAMIC_REF(externalReference, progRefRV, parameters):
				final isDynamicName = progRefRV.match(RVReference(_)) && indexedParams.exists(switch progRefRV {
					case RVReference(r): r;
					default: "";
				});
				final reference = resolveRefName(progRefRV);
				var builder = if (externalReference != null) {
					var builder = multiParserResult.imports?.get(externalReference);
					if (builder == null)
						throw builderErrorAt(node, 'could not find builder for external dynamicRef ${externalReference}');
					builder;
				} else this;

				// Build with incremental: true so the dynamicRef supports setParameter
				var result = builder.buildWithParameters(reference, parameters, builderParams, indexedParams, true);
				var object = result?.object;
				if (object == null)
					throw builderErrorAt(node, 'could not build dynamicRef ${reference}');

				// For dynamic name refs, wrap in a container for easy rebuild
				final container = if (isDynamicName) {
					final c = new h2d.Object();
					c.addChild(object);
					c;
				} else null;

				// Store the sub-result for later access via getDynamicRef()
				internalResults.dynamicRefs.set(reference, result);

				// Register parameter bindings for incremental propagation
				if (incrementalMode && incrementalContext != null && result.incrementalContext != null) {
					final childNode = builder.multiParserResult.nodes?.get(reference);
					final childDefs = childNode != null ? builder.getProgrammableParameterDefinitions(childNode) : new Map();
					for (childParam => value in parameters) {
						final refs:Array<String> = [];
						collectParamRefs(value, refs);
						if (refs.length > 0) {
							final capturedValue = value;
							final paramType = childDefs.get(childParam)?.type;
							final resolveFn:Void->Dynamic = switch paramType {
								case PPTString: () -> resolveAsString(capturedValue);
								case PPTColor: () -> resolveAsColorInteger(capturedValue);
								case PPTFloat: () -> resolveAsNumber(capturedValue);
								default: () -> resolveAsInteger(capturedValue);
							};
							incrementalContext.trackDynamicRef(result.incrementalContext, childParam, resolveFn, refs, result.object);
						}
					}
				}

				// Track dynamic name for full rebuild when template param changes
				if (isDynamicName && incrementalMode && incrementalContext != null && container != null) {
					final paramName = switch progRefRV {
						case RVReference(r): r;
						default: "";
					};
					incrementalContext.trackDynamicName({
						paramName: paramName,
						container: container,
						currentName: reference,
						node: node,
						parameters: parameters,
						externalReference: externalReference,
						internalResults: internalResults,
					});
				}

				final outputObject = container != null ? container : object;

				if (outputObject.numChildren == 1) {
					final inner = outputObject.getChildAt(0);
					if (inner.x != 0 || inner.y != 0) {
						selectedBuildMode = ObjectMode(inner);
					}
				}

				HeapsObject(outputObject);

			case POINT:
				HeapsObject(new h2d.Object());
			case SWITCH(paramName, arms):
				final container = new h2d.Object();
				final matchedArm = resolveMatchedSwitchArm(paramName, arms);

				// Build active arm with incremental=false (children are a rebuild unit)
				final savedIncMode = incrementalMode;
				final savedIncCtx = incrementalContext;
				if (incrementalMode) incrementalMode = false;

				if (matchedArm != null) {
					for (child in matchedArm.children)
						build(child, ObjectMode(container), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
				}

				if (savedIncMode) {
					incrementalMode = savedIncMode;
					// Collect all param refs from all arms (any param change inside any arm triggers rebuild)
					final switchParamRefs:Array<String> = [paramName];
					for (arm in arms) {
						collectChildConditionalParamRefs(arm.children, switchParamRefs);
						for (child in arm.children) {
							final childRefs = collectNodeParamRefs(child);
							for (r in childRefs)
								if (switchParamRefs.indexOf(r) < 0) switchParamRefs.push(r);
						}
					}
					final capturedArms = arms;
					final capturedParamName = paramName;
					final capturedContainer = container;
					final capturedBP = builderParams;
					final capturedIR = internalResults;
					final capturedCtx = savedIncCtx;
					savedIncCtx.trackExpression(() -> {
						final newArm = resolveMatchedSwitchArm(capturedParamName, capturedArms);
						// Drop registrations + per-element bookkeeping from the previous arm before tearing
						// down its scene graph, then build the new arm into the parent internalResults so
						// its registrations are visible via the parent BuilderResult.
						capturedCtx.cleanupDestroyedSubtree(capturedIR, capturedContainer);
						capturedContainer.removeChildren();
						if (newArm != null) {
							// Mirror initial arm build: disable incremental tracking so arm children
							// don't register tracked expressions / dynamicRef bindings on the parent ctx.
							final savedMode = incrementalMode;
							final savedCtx = incrementalContext;
							incrementalMode = false;
							incrementalContext = null;
							final gcs = MultiAnimParser.getGridCoordinateSystem(node);
							final hcs = MultiAnimParser.getHexCoordinateSystem(node);
							for (child in newArm.children)
								build(child, ObjectMode(capturedContainer), gcs, hcs, capturedIR, capturedBP);
							incrementalMode = savedMode;
							incrementalContext = savedCtx;
						}
					}, switchParamRefs, container);
				}

				skipChildren = true;
				HeapsObject(container);
			case STATEANIM(filename, initialState, selectorReferences):
				var selector = [for (k => v in selectorReferences) k => resolveAsString(v)];
				var animSM = resourceLoader.createAnimSM(filename, selector);
				animSM.play(resolveAsString(initialState));

				StateAnim(animSM);
			case STATEANIM_CONSTRUCT(initialState, construct, externallyDriven):
				var animSM = new AnimationSM([]);
				for (key => value in construct) {
					switch value {
						case IndexedSheet(sheet, animName, fps, loop, center):
							final loadedSheet = getOrLoadSheet(sheet);
							final anim = loadedSheet.getAnim(resolveAsString(animName));
							if (center) {
								for (i in 0...anim.length) {
									anim[i] = anim[i].cloneWithNewTile(anim[i].tile.center());
								}
							}

							var animStates = [for (a in anim) Frame(a.cloneWithDuration(1.0 / resolveAsNumber(fps)))];
							var loopCount = loop ? -1 : 0; // -1 = forever, 0 = no loop

							animSM.addAnimationState(key, animStates, loopCount, new Map());
					}
				}
				final initialStateResolved = resolveAsString(initialState);
				if (animSM.animationStates.exists(initialStateResolved) == false)
					throw builderErrorAt(node, 'initialState ${initialStateResolved} does not exist in constructed stateanim');

				animSM.play(initialStateResolved);
				if (externallyDriven) animSM.externallyDriven = true;

				StateAnim(animSM);
			case REPEAT(varName, repeatType):
				var dx = 0;
				var dy = 0;
				var repeatCount = 0;
				var iterator = null;
				var arrayIterator:Array<String> = [];
				var rangeStart = 0;
				var rangeStep = 1;
				var tileSourceIterator:Array<TileSource> = [];
				var tilenameIterator:Array<String> = [];

				switch repeatType {
					case StepIterator(dirX, dirY, repeats):
						repeatCount = resolveAsInteger(repeats);
						dx = dirX == null ? 0 : resolveAsInteger(dirX);
						dy = dirY == null ? 0 : resolveAsInteger(dirY);
					case LayoutIterator(layoutName):
						final l = getLayouts();
						repeatCount = l.getLayoutSequenceLengthByLayoutName(layoutName);
						iterator = l.getIterator(layoutName);
					case ArrayIterator(variableName, arrayName):
						arrayIterator = resolveAsArray(RVArrayReference(arrayName));
						repeatCount = arrayIterator.length;
					case RangeIterator(start, end, step):
						rangeStart = resolveAsInteger(start);
						final rangeEnd = resolveAsInteger(end);
						rangeStep = resolveAsInteger(step);
						repeatCount = Math.ceil((rangeEnd - rangeStart) / rangeStep);
					case StateAnimIterator(bitmapVarName, animFilename, animationName, selectorRefs):
						final selector = [for (k => v in selectorRefs) k => resolveAsString(v)];
						final animName = resolveAsString(animationName);
						tileSourceIterator = collectStateAnimFrames(animFilename, animName, selector);
						repeatCount = tileSourceIterator.length;
					case TilesIterator(bitmapVarName, tilenameVarName, sheetName, tileFilter):
						final sheet = getOrLoadSheet(sheetName);
						if (tileFilter != null) {
							final frames = sheet.getAnim(tileFilter);
							if (frames == null) {
								throw builderErrorAt(node, 'Tile "${tileFilter}" not found in sheet "${sheetName}". The tile filter must be an exact tile name (key) in the atlas.');
							}
							for (frame in frames) {
								if (frame != null && frame.tile != null) {
									tileSourceIterator.push(TSTile(frame.tile));
								}
							}
						} else {
							for (tileName => entries in sheet.getContents()) {
								for (entry in entries) {
									if (entry != null) {
										tileSourceIterator.push(TSTile(entry.t));
										tilenameIterator.push(tileName);
									}
								}
							}
						}
						repeatCount = tileSourceIterator.length;
				}

				// Collect param refs for incremental tracking of param-dependent repeat counts
				final repeatParamRefs:Array<String> = [];
				switch repeatType {
					case StepIterator(dirX, dirY, repeats):
						collectParamRefs(repeats, repeatParamRefs);
						if (dirX != null) collectParamRefs(dirX, repeatParamRefs);
						if (dirY != null) collectParamRefs(dirY, repeatParamRefs);
					case RangeIterator(start, end, step):
						collectParamRefs(start, repeatParamRefs);
						collectParamRefs(end, repeatParamRefs);
						collectParamRefs(step, repeatParamRefs);
					default:
				}
				// Also collect param refs from conditions inside children (e.g. @($i < $level) references $level).
				// This ensures changing those params triggers a repeatable rebuild even if the count is constant.
				if (incrementalMode && incrementalContext != null) {
					collectChildConditionalParamRefs(node.children, repeatParamRefs);
					repeatParamRefs.remove(varName); // exclude loop variable — not a settable parameter
				}
				final hasIncrementalRepeat = incrementalMode && incrementalContext != null && repeatParamRefs.length > 0;

				// Only create a wrapper when children need relative positioning (non-zero step offsets or layout iterator).
				// Otherwise build directly into parent — this lets h2d.Flow see individual children.
				// Also force wrapper for param-dependent repeats in incremental mode (need container for removeChildren).
				final needsWrapper = (dx != 0 || dy != 0 || iterator != null || hasIncrementalRepeat);
				var object = needsWrapper ? new h2d.Object() : null;
				final buildTarget = needsWrapper ? object : current;
				final ownPos = needsWrapper ? null : calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));

				if (indexedParams.exists(node.updatableName.getNameString()))
					throw builderErrorAt(node, 'cannot use repeatable index param "$varName" as it is already defined');

				// Disable incremental tracking for children of param-dependent repeats
				// (they will be fully rebuilt when the tracked params change)
				final savedIncrementalMode = incrementalMode;
				final savedIncrementalCtx = incrementalContext;
				if (hasIncrementalRepeat) {
					// trackIncrementalExpressions is what normally calls markParamUntracked for
					// INTERACTIVE id/metadata + STATEANIM selectors; with incrementalMode=false it
					// won't fire. Mark untracked params up-front so setParameter on a param that
					// flows into (say) an interactive id inside a param-dep repeat throws
					// "untracked_param" instead of silently no-oping. Loop vars are excluded.
					for (childNode in node.children)
						markUntrackedParamsInSubtree(childNode, savedIncrementalCtx, varName);
					incrementalMode = false;
				}

				for (count in 0...repeatCount) {
					final resolvedIndex = switch repeatType {
						case RangeIterator(_, _, _): rangeStart + count * rangeStep;
						case _: count;
					};
					final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
					final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);
					indexedParams.set(varName, Value(resolvedIndex));
					switch repeatType {
						case ArrayIterator(valueVariableName, arrayName):
							indexedParams.set(valueVariableName, StringValue(arrayIterator[count]));
						case StateAnimIterator(bitmapVarName, _, _, _):
							indexedParams.set(bitmapVarName, TileSourceValue(tileSourceIterator[count]));
						case TilesIterator(bitmapVarName, tilenameVarName, _, _):
							indexedParams.set(bitmapVarName, TileSourceValue(tileSourceIterator[count]));
							if (tilenameVarName != null && count < tilenameIterator.length)
								indexedParams.set(tilenameVarName, StringValue(tilenameIterator[count]));
						default:
					}
					final resolvedChildren = resolveConditionalChildren(node.children);
					// Resolve layout point once per iteration (not per child)
					var layoutPt:Null<FPoint> = switch repeatType {
						case LayoutIterator(_): iterator.next();
						default: null;
					};
					for (childNode in resolvedChildren) {
						var obj = build(childNode, ObjectMode(buildTarget), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
						if (obj == null)
							continue;
						if (needsWrapper) {
							switch repeatType {
								case StepIterator(_, _, _):
									addPosition(obj, dx * count, dy * count);
								case LayoutIterator(_):
									addPosition(obj, layoutPt.x, layoutPt.y);
								default:
							}
						} else if (ownPos.x != 0 || ownPos.y != 0) {
							addPosition(obj, ownPos.x, ownPos.y);
						}
					}
					cleanupFinalVars(resolvedChildren, indexedParams);
				}

				indexedParams.remove(varName);
				switch repeatType {
					case StateAnimIterator(bitmapVarName, _, _, _):
						indexedParams.remove(bitmapVarName);
					case TilesIterator(bitmapVarName, tilenameVarName, _, _):
						indexedParams.remove(bitmapVarName);
						if (tilenameVarName != null) indexedParams.remove(tilenameVarName);
					case _:
				}

				// Restore incremental mode and register structural rebuild
				if (hasIncrementalRepeat) {
					incrementalMode = savedIncrementalMode;
					final capturedNode = node;
					final capturedObject = object;
					final capturedVarName = varName;
					final capturedRepeatType = repeatType;
					final capturedBP = builderParams;
					final capturedIR = internalResults;
					final capturedCtx = savedIncrementalCtx;
					savedIncrementalCtx.trackExpression(() -> {
						var newDx = 0;
						var newDy = 0;
						var newCount = 0;
						var newRangeStart = 0;
						var newRangeStep = 1;
						switch capturedRepeatType {
							case StepIterator(dirX, dirY, repeats):
								newCount = resolveAsInteger(repeats);
								newDx = dirX == null ? 0 : resolveAsInteger(dirX);
								newDy = dirY == null ? 0 : resolveAsInteger(dirY);
							case RangeIterator(start, end, step):
								newRangeStart = resolveAsInteger(start);
								final rangeEnd = resolveAsInteger(end);
								newRangeStep = resolveAsInteger(step);
								newCount = Math.ceil((rangeEnd - newRangeStart) / newRangeStep);
							default:
						}
						// Drop registrations + per-element bookkeeping from the previous iterations before
						// tearing down their scene graph, then build the new iterations into the parent
						// internalResults so their registrations are visible via the parent BuilderResult.
						capturedCtx.cleanupDestroyedSubtree(capturedIR, capturedObject);
						capturedObject.removeChildren();
						// Mirror initial repeat build: disable incremental tracking so iteration children
						// don't register tracked expressions / dynamicRef bindings on the parent ctx.
						final savedMode = incrementalMode;
						final savedCtx = incrementalContext;
						incrementalMode = false;
						incrementalContext = null;
						final gcs = MultiAnimParser.getGridCoordinateSystem(capturedNode);
						final hcs = MultiAnimParser.getHexCoordinateSystem(capturedNode);
						for (count in 0...newCount) {
							final resolvedIndex = switch capturedRepeatType {
								case RangeIterator(_, _, _): newRangeStart + count * newRangeStep;
								case _: count;
							};
							indexedParams.set(capturedVarName, Value(resolvedIndex));
							final resolvedChildren = resolveConditionalChildren(capturedNode.children);
							for (childNode in resolvedChildren) {
								var obj = build(childNode, ObjectMode(capturedObject), gcs, hcs, capturedIR, capturedBP);
								if (obj == null)
									continue;
								if (newDx != 0 || newDy != 0) {
									addPosition(obj, newDx * count, newDy * count);
								}
							}
							cleanupFinalVars(resolvedChildren, indexedParams);
						}
						indexedParams.remove(capturedVarName);
						incrementalMode = savedMode;
						incrementalContext = savedCtx;
					}, repeatParamRefs, capturedObject);
				}

				skipChildren = true;
				if (needsWrapper) {
					HeapsObject(object);
				} else {
					return null;
				}

			case REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY):
				var object = new h2d.Object();
				var xRepeatCount = 0;
				var yRepeatCount = 0;
				var xDx = 0;
				var xDy = 0;
				var yDx = 0;
				var yDy = 0;
				var xLayoutName:Null<String> = null;
				var yLayoutName:Null<String> = null;
				var xArrayIterator:Array<String> = [];
				var yArrayIterator:Array<String> = [];
				var xValueVariableName:Null<String> = null;
				var yValueVariableName:Null<String> = null;
				var xRangeStart = 0;
				var xRangeStep = 1;
				var yRangeStart = 0;
				var yRangeStep = 1;
				var layouts:Null<MultiAnimLayouts> = null;
				function getLayoutsIfNeeded() {
					if (layouts == null) layouts = getLayouts();
					return layouts;
				}

				switch repeatTypeX {
					case StepIterator(dirX, dirY, repeats):
						xRepeatCount = resolveAsInteger(repeats);
						xDx = dirX == null ? 0 : resolveAsInteger(dirX);
						xDy = dirY == null ? 0 : resolveAsInteger(dirY);
					case LayoutIterator(layoutName):
						final l = getLayoutsIfNeeded();
						xRepeatCount = l.getLayoutSequenceLengthByLayoutName(layoutName);
						xLayoutName = layoutName;
					case ArrayIterator(variableName, arrayName):
						xArrayIterator = resolveAsArray(RVArrayReference(arrayName));
						xRepeatCount = xArrayIterator.length;
						xValueVariableName = variableName;
					case RangeIterator(start, end, step):
						xRangeStart = resolveAsInteger(start);
						final rangeEnd = resolveAsInteger(end);
						xRangeStep = resolveAsInteger(step);
						xRepeatCount = Math.ceil((rangeEnd - xRangeStart) / xRangeStep);
						xDx = 0;
						xDy = 0;
					case StateAnimIterator(_, _, _, _):
						throw builderErrorAt(node, 'StateAnimIterator not supported in REPEAT2D');
					case TilesIterator(_, _, _, _):
						throw builderErrorAt(node, 'TilesIterator not supported in REPEAT2D');
				}

				switch repeatTypeY {
					case StepIterator(dirX, dirY, repeats):
						yRepeatCount = resolveAsInteger(repeats);
						yDx = dirX == null ? 0 : resolveAsInteger(dirX);
						yDy = dirY == null ? 0 : resolveAsInteger(dirY);
					case LayoutIterator(layoutName):
						final l = getLayoutsIfNeeded();
						yRepeatCount = l.getLayoutSequenceLengthByLayoutName(layoutName);
						yLayoutName = layoutName;
					case ArrayIterator(variableName, arrayName):
						yArrayIterator = resolveAsArray(RVArrayReference(arrayName));
						yRepeatCount = yArrayIterator.length;
						yValueVariableName = variableName;
					case RangeIterator(start, end, step):
						yRangeStart = resolveAsInteger(start);
						final rangeEnd = resolveAsInteger(end);
						yRangeStep = resolveAsInteger(step);
						yRepeatCount = Math.ceil((rangeEnd - yRangeStart) / yRangeStep);
						yDx = 0;
						yDy = 0;
					case StateAnimIterator(_, _, _, _):
						throw builderErrorAt(node, 'StateAnimIterator not supported in REPEAT2D');
					case TilesIterator(_, _, _, _):
						throw builderErrorAt(node, 'TilesIterator not supported in REPEAT2D');
				}

				if (indexedParams.exists(varNameX) || indexedParams.exists(varNameY))
					throw builderErrorAt(node, 'cannot use repeatable2d index param "$varNameX" or "$varNameY" as it is already defined');
				var yIterator = yLayoutName == null ? null : getLayoutsIfNeeded().getIterator(yLayoutName);
				for (yCount in 0...yRepeatCount) {
					final resolvedY = switch repeatTypeY {
						case RangeIterator(_, _, _): yRangeStart + yCount * yRangeStep;
						case _: yCount;
					};
					final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
					final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);
					var yOffsetX = 0.0;
					var yOffsetY = 0.0;
					switch repeatTypeY {
						case StepIterator(_, _, _):
							yOffsetX = yDx * yCount;
							yOffsetY = yDy * yCount;
						case LayoutIterator(_):
							var pt = yIterator.next();
							yOffsetX = pt.x;
							yOffsetY = pt.y;
						case RangeIterator(_, _, _):
						case ArrayIterator(_, _):
						case StateAnimIterator(_, _, _, _):
						case TilesIterator(_, _, _, _):
					}
					var xIterator = xLayoutName == null ? null : getLayoutsIfNeeded().getIterator(xLayoutName);
					for (xCount in 0...xRepeatCount) {
						final resolvedX = switch repeatTypeX {
							case RangeIterator(_, _, _): xRangeStart + xCount * xRangeStep;
							case _: xCount;
						};
						var xOffsetX = 0.0;
						var xOffsetY = 0.0;
						switch repeatTypeX {
							case StepIterator(_, _, _):
								xOffsetX = xDx * xCount;
								xOffsetY = xDy * xCount;
							case LayoutIterator(_):
								var pt = xIterator.next();
								xOffsetX = pt.x;
								xOffsetY = pt.y;
							case RangeIterator(_, _, _):
							case ArrayIterator(_, _):
							case StateAnimIterator(_, _, _, _):
							case TilesIterator(_, _, _, _):
						}
						// Set indexed params before resolving conditional children
						indexedParams.set(varNameX, Value(resolvedX));
						indexedParams.set(varNameY, Value(resolvedY));
						if (xValueVariableName != null) indexedParams.set(xValueVariableName, StringValue(xArrayIterator[xCount]));
						if (yValueVariableName != null) indexedParams.set(yValueVariableName, StringValue(yArrayIterator[yCount]));
						final resolvedChildren = resolveConditionalChildren(node.children);
						for (childNode in resolvedChildren) {
							var obj = build(childNode, ObjectMode(object), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
							if (obj == null)
								continue;
							addPosition(obj, xOffsetX + yOffsetX, xOffsetY + yOffsetY);
						}
						cleanupFinalVars(resolvedChildren, indexedParams);
					}
				}

				indexedParams.remove(varNameX);
				indexedParams.remove(varNameY);
				skipChildren = true;
				HeapsObject(object);

			case APPLY:
				if (current == null)
					throw builderErrorAt(node, 'apply not allowed as root node');
				if (incrementalMode && incrementalContext != null) {
					// Capture the parent's pre-apply baseline the first time an apply
					// entry is registered for it. Must happen before any inline apply
					// so later reconciles can reset to the true pre-apply state.
					// Unconditional applies also need tracking so param-dependent
					// expressions (e.g. `scale: $k`) re-apply on setParameter.
					incrementalContext.captureApplyBaseline(current);
					if (nodeVisible) {
						final pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
						addPosition(current, pos.x, pos.y);
						applyExtendedFormProperties(current, node);
					}
					incrementalContext.trackConditionalApply(current, node, nodeVisible);
				} else {
					var pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
					addPosition(current, pos.x, pos.y);
					applyExtendedFormProperties(current, node);
				}
				return null;

			case PROGRAMMABLE(_, _, _):
				throw builderErrorAt(node, 'invalid state, programmable should not be built');

			case PIXELS(shapes):
				final pixelsResult = drawPixels(shapes, gridCoordinateSystem, hexCoordinateSystem);
				// Scale the position offset so pixel content aligns correctly when scale > 1
				final pixelScale = node.scale != null ? resolveAsNumber(node.scale) : 1.0;
				
				pixelsResult.pixelLines.setPosition(pixelsResult.minX * pixelScale, pixelsResult.minY * pixelScale);
				Pixels(pixelsResult.pixelLines);
			case INTERACTIVE(width, height, id, debug, metadata):
				var resolvedMeta:ResolvedSettings = null;
				if (metadata != null) {
					resolvedMeta = [];
					for (entry in metadata) {
						resolvedMeta.set(resolveAsString(entry.key), switch entry.type {
							case SVTInt: RSVInt(resolveAsInteger(entry.value));
							case SVTFloat: RSVFloat(resolveAsNumber(entry.value));
							case SVTString: RSVString(resolveAsString(entry.value));
							case SVTColor: RSVColor(resolveAsColorInteger(entry.value));
							case SVTBool: RSVBool(resolveAsBool(entry.value));
						});
					}
				}
				var obj = new MAObject(MAInteractive(resolveAsInteger(width), resolveAsInteger(height), resolveAsString(id), resolvedMeta), debug);
				internalResults.interactives.push(obj);
				HeapsObject(obj);

			case GRAPHICS(elements):
				var g = new KeepGraphics();
				drawGraphicsElements(g, elements, gridCoordinateSystem, hexCoordinateSystem);
				HeapsObject(g);

			case TILEGROUP:
				// tileGroup bakes children into a single drawable at build time.
				// buildTileGroup() does NOT register with IncrementalUpdateContext,
				// so conditionals whose predicate references a programmable parameter
				// would silently freeze on first build (and in incremental mode they'd
				// also double-bake because resolveConditionalChildren returns all
				// @else/@default arms alongside the matching @() arm). Reject such
				// configurations up front. Loop vars introduced by a repeatable
				// INSIDE the tileGroup iterate at build time and are allowed.
				for (child in node.children)
					validateTileGroupSubtree(child, []);
				final tg = new TileGroup();
				selectedBuildMode = TileGroupMode(tg);
				HeapsObject(tg);
			case FINAL_VAR(name, expr):
				evaluateAndStoreFinal(name, expr, node);
				return null;
		}
		final updatableName = node.updatableName;

		final object = builtObject.toh2dObject();

		// In incremental mode: insert sentinel before conditional elements for position tracking
		var conditionalSentinel:Null<h2d.Object> = null;
		if (incrementalMode && node.conditionals != NoConditional && incrementalContext != null && current != null) {
			conditionalSentinel = new h2d.Object();
			addChild(conditionalSentinel);
		}

		addChild(object);
		object.name = node.uniqueNodeName;

		// Set flow properties for spacer and per-element flow annotations after addChild
		{
			final fp = node.flowProperties;
			final isSpacer = node.type.match(SPACER(_, _));

			if (isSpacer || fp != null) {
				final flowParent = Std.downcast(current, h2d.Flow);
				if (flowParent == null) {
					if (isSpacer)
						throw builderErrorAt(node, 'spacer used outside of flow');
					else
						throw builderErrorAt(node, 'per-element flow properties (@halign/@valign/@flowOffset/@absolute) used outside of flow');
				}
				final props = flowParent.getProperties(object);
				switch node.type {
					case SPACER(width, height):
						if (width != null) props.minWidth = resolveAsInteger(width);
						if (height != null) props.minHeight = resolveAsInteger(height);
					default:
				}
				if (fp != null) {
					if (fp.hAlign != null)
						props.horizontalAlign = MacroCompatConvert.toH2dFlowAlign(fp.hAlign);
					if (fp.vAlign != null)
						props.verticalAlign = MacroCompatConvert.toH2dFlowAlign(fp.vAlign);
					if (fp.offsetX != null)
						props.offsetX = resolveAsInteger(fp.offsetX);
					if (fp.offsetY != null)
						props.offsetY = resolveAsInteger(fp.offsetY);
					if (fp.isAbsolute)
						props.isAbsolute = true;
				}
			}
		}

		final n = updatableName.getNameString();
		if (n != null) {
			final names = internalResults.names;
			// For indexed names (#name[$i] or #name[$x,$y]), also store under name_N / name_X_Y key
			switch updatableName {
				case UNTIndexed(name, indexVar):
					final indexValue = indexedParams.get(indexVar);
					if (indexValue != null) {
						final idx = switch indexValue {
							case Value(v): v;
							default: 0;
						};
						final indexedKey = '${name} ${idx}';
						if (names.exists(indexedKey))
							names[indexedKey].push(toNamedResult(updatableName, builtObject, node));
						else
							names[indexedKey] = [toNamedResult(updatableName, builtObject, node)];
					}
				case UNTIndexed2D(name, indexVarX, indexVarY):
					final indexValueX = indexedParams.get(indexVarX);
					final indexValueY = indexedParams.get(indexVarY);
					if (indexValueX != null && indexValueY != null) {
						final idxX = switch indexValueX { case Value(v): v; default: 0; };
						final idxY = switch indexValueY { case Value(v): v; default: 0; };
						final indexedKey = '${name} ${idxX} ${idxY}';
						if (names.exists(indexedKey))
							names[indexedKey].push(toNamedResult(updatableName, builtObject, node));
						else
							names[indexedKey] = [toNamedResult(updatableName, builtObject, node)];
					}
				default:
			}
			if (names.exists(n))
				names[n].push(toNamedResult(updatableName, builtObject, node));
			else
				names[n] = [toNamedResult(updatableName, builtObject, node)];
		}

		// addPosition is used instead of setPosition as to not overwrite existing offsets (e.g. pixellines)

		var pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
		addPosition(object, pos.x, pos.y);
		applyExtendedFormProperties(object, node);

		// Track expressions for incremental updates
		if (incrementalMode && incrementalContext != null) {
			trackIncrementalExpressions(node, object, builtObject);
		}

		// In incremental mode: track conditional elements and remove non-visible ones from scene graph
		if (conditionalSentinel != null && incrementalContext != null && current != null) {
			final condParent = if (node.layer != -1 && layersParent != null) cast(layersParent, h2d.Object) else current;
			incrementalContext.trackConditional(object, node, conditionalSentinel, condParent, node.layer);
			if (!nodeVisible)
				condParent.removeChild(object);
		}

		if (selectedBuildMode == null)
			selectedBuildMode = ObjectMode(object);

		// For SLOT with parameters: set up incremental mode before building children
		var slotIncrementalCtx:Null<IncrementalUpdateContext> = null;
		var savedSlotIncrementalMode:Bool = false;
		var savedSlotIncrementalContext:Null<IncrementalUpdateContext> = null;
		var savedSlotIndexedParams:Null<Map<String, ResolvedIndexParameters>> = null;
		switch node.type {
			case SLOT(parameters, _) if (parameters != null):
				savedSlotIncrementalMode = this.incrementalMode;
				savedSlotIncrementalContext = this.incrementalContext;
				savedSlotIndexedParams = this.indexedParams;
				// Merge slot parameter defaults into a copy of current params
				final mergedParams:Map<String, ResolvedIndexParameters> = new Map();
				for (k => v in this.indexedParams)
					mergedParams.set(k, v);
				for (key => def in parameters) {
					if (def.defaultValue != null)
						mergedParams.set(key, def.defaultValue);
				}
				this.indexedParams = mergedParams;
				slotIncrementalCtx = new IncrementalUpdateContext(this, mergedParams, builderParams, node);
				this.incrementalMode = true;
				this.incrementalContext = slotIncrementalCtx;
			default:
		}

		if (!skipChildren) { // for repeatable, as children were already processed
			final resolvedChildren = resolveConditionalChildren(node.children);
			for (childNode in resolvedChildren) {
				build(childNode, selectedBuildMode, MultiAnimParser.getGridCoordinateSystem(childNode), MultiAnimParser.getHexCoordinateSystem(childNode),
					internalResults, builderParams);
			}
			cleanupFinalVars(resolvedChildren, indexedParams);
		}

		// Restore incremental state after slot children are built
		if (savedSlotIndexedParams != null) {
			this.incrementalMode = savedSlotIncrementalMode;
			this.incrementalContext = savedSlotIncrementalContext;
			this.indexedParams = savedSlotIndexedParams;
		}

		// Register slot handle after children are built
		switch node.type {
			case SLOT(parameters, _):
				// Find slotContent child if present
				var slotContentTarget:Null<h2d.Object> = null;
				for (i in 0...object.numChildren) {
					if (Std.downcast(object.getChildAt(i), SlotContentRoot) != null) {
						slotContentTarget = object.getChildAt(i);
						break;
					}
				}
				switch node.updatableName {
					case UNTIndexed(baseName, indexVar):
						final index = resolveAsString(RVReference(indexVar)).toInt();
						internalResults.slots.push({key: Indexed(baseName, index), handle: new SlotHandle(object, slotIncrementalCtx, slotContentTarget)});
					case UNTIndexed2D(baseName, indexVarX, indexVarY):
						final indexX = resolveAsString(RVReference(indexVarX)).toInt();
						final indexY = resolveAsString(RVReference(indexVarY)).toInt();
						internalResults.slots.push({key: Indexed2D(baseName, indexX, indexY), handle: new SlotHandle(object, slotIncrementalCtx, slotContentTarget)});
					case UNTObject(name) | UNTUpdatable(name):
						internalResults.slots.push({key: Named(name), handle: new SlotHandle(object, slotIncrementalCtx, slotContentTarget)});
					default:
				}
			default:
		}

		return object;
	}

	function resolveSettings(node:Node):ResolvedSettings {
		var currentSettings:Null<Map<String, ParsedSettingValue>> = null;
		var current:Null<Node> = node;
		while (current != null) {
			if (current.settings != null) {
				if (currentSettings == null)
					currentSettings = current.settings;
				else {
					for (key => value in current.settings) {
						if (!currentSettings.exists(key))
							currentSettings[key] = value;
					}
				}
			}
			current = current.parent;
		}

		if (currentSettings != null) {
			final retSettings:ResolvedSettings = [];
			for (key => settingValue in currentSettings) {
				retSettings[key] = switch settingValue.type {
					case SVTInt: RSVInt(resolveAsInteger(settingValue.value));
					case SVTFloat: RSVFloat(resolveAsNumber(settingValue.value));
					case SVTString: RSVString(resolveAsString(settingValue.value));
					case SVTColor: RSVColor(resolveAsColorInteger(settingValue.value));
					case SVTBool: RSVBool(resolveAsBool(settingValue.value));
				}
			}
			return retSettings;
		} else
			return null;
	}

	function toNamedResult(updatableNameType:UpdatableNameType, obj:BuiltHeapsComponent, node:Node):NamedBuildResult {
		return {
			type: updatableNameType,
			object: obj,
			settings: resolveSettings(node),
			hexCoordinateSystem: MultiAnimParser.getHexCoordinateSystem(node),
			gridCoordinateSystem: MultiAnimParser.getGridCoordinateSystem(node)
		}
	}

	function applyExtendedFormProperties(object:h2d.Object, node:Node) {
		if (node.scale != null)
			object.setScale(resolveAsNumber(node.scale));
		if (node.rotation != null)
			object.rotation = hxd.Math.degToRad(resolveAsNumber(node.rotation));
		if (node.alpha != null)
			object.alpha = resolveAsNumber(node.alpha);
		if (node.blendMode != null)
			object.blendMode = MacroCompatConvert.toH2dBlendMode(node.blendMode);
		if (node.filter != null) {
			final f = buildFilter(node.filter);
			if (f != null) object.filter = f;
		}
		if (node.tint != null) {
			if (Std.isOfType(object, h2d.Drawable)) {
				final d:h2d.Drawable = cast object;
				d.color.setColor(resolveAsColorInteger(node.tint));
			}
		}
	}

	function resolveColorList(colors:Array<ReferenceableValue>) {
		return [for (value in colors) resolveAsColorInteger(value)];
	}

	function buildFilter(type:FilterType):Null<h2d.filter.Filter> {
		return switch type {
			case FilterNone: null;
			case FilterGroup(filters):
				var ret = new h2d.filter.Group();
				for (f in filters) {
					final built = buildFilter(f);
					if (built != null) ret.add(built);
				}
				ret;
			case FilterOutline(size, color): new h2d.filter.Outline(resolveAsNumber(size), resolveAsColorInteger(color));
			case FilterPaletteReplace(paletteName, sourceRow, replacementRow):
				var palette = getPalette(paletteName);
				var srcRow = resolveAsInteger(sourceRow);
				var dstRow = resolveAsInteger(replacementRow);
				ReplacePaletteShader.createAsPaletteFilter(palette, srcRow, dstRow);

			case FilterColorListReplace(sourceColors, replacementColors):
				ReplacePaletteShader.createAsColorsFilter(resolveColorList(sourceColors), resolveColorList(replacementColors));
			case FilterSaturate(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorSaturate(resolveAsNumber(v));
				new h2d.filter.ColorMatrix(m);
			case FilterBrightness(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorLightness(resolveAsNumber(v));

				new h2d.filter.ColorMatrix(m);
			case FilterGrayscale(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorSaturate(-resolveAsNumber(v));
				new h2d.filter.ColorMatrix(m);
			case FilterHue(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorHue(resolveAsNumber(v));
				new h2d.filter.ColorMatrix(m);
			case FilterGlow(color, alpha, radius, gain, quality, smoothColor, knockout):
				final f = new h2d.filter.Glow(resolveAsColorInteger(color), resolveAsNumber(alpha), resolveAsNumber(radius), resolveAsNumber(gain), resolveAsNumber(quality), smoothColor);
				f.knockout = knockout;
				f;
			case FilterBlur(radius, gain, quality, linear):
				new h2d.filter.Blur(resolveAsNumber(radius), resolveAsNumber(gain), resolveAsNumber(quality), resolveAsNumber(linear));
			case FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor):
				new h2d.filter.DropShadow(resolveAsNumber(distance), hxd.Math.degToRad(resolveAsNumber(angle)), resolveAsColorInteger(color), resolveAsNumber(alpha), resolveAsNumber(radius), resolveAsNumber(gain), resolveAsNumber(quality), smoothColor);
			case FilterPixelOutline(mode, smoothColor):
				final resolvedMode = switch mode {
					case POKnockout(color, knockout): Knockout(resolveAsColorInteger(color), resolveAsNumber(knockout));
					case POInlineColor(color, inlineColor): InlineColor(resolveAsColorInteger(color), resolveAsColorInteger(inlineColor));
				};
				new PixelOutline(resolvedMode, smoothColor);
			case FilterCustom(name, args):
				final reg = bh.base.FilterManager.getFilter(name);
				if (reg == null)
					throw builderError('Unknown custom filter "$name". Register it via FilterManager.registerFilter().');
				final resolved = new Map<String, Dynamic>();
				for (i in 0...reg.params.length) {
					final paramDef = reg.params[i];
					if (i < args.length) {
						switch paramDef.type {
							case CFFloat: resolved[paramDef.name] = resolveAsNumber(args[i].value);
							case CFColor: resolved[paramDef.name] = resolveAsColorInteger(args[i].value);
							case CFBool: resolved[paramDef.name] = resolveAsNumber(args[i].value) != 0;
						}
					} else if (paramDef.defaultValue != null) {
						resolved[paramDef.name] = paramDef.defaultValue;
					} else {
						throw builderError('Custom filter "$name" missing required argument "${paramDef.name}"');
					}
				}
				reg.factory(resolved);
		}
	}

	function stringToInt(n:String):Int {
		return n.toInt();
	}

	public function hasMultiAnimWithName(name:String) {
		return multiParserResult.nodes.exists(name);
	}

	public dynamic function defaultCallback(input:CallbackRequest):CallbackResult {
		return CBRNoResult;
	}

	function getProgrammableParameterDefinitions(node:Node, throwIfNotProgrammable = false):ParametersDefinitions {
		switch node.type {
			case PROGRAMMABLE(_, d, _):
				return d;
			default:
				if (throwIfNotProgrammable)
					throw builderErrorAt(node, 'buildWithParameters require programmable node, was ${node.type}');
				else
					return [];
		}
		return [];
	}

	function startBuild(name:String, rootNode:Node, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem,
			builderParams:BuilderParameters):BuilderResult {
		var isProgrammable = false;
		var isTileGroup = false;
		switch rootNode.type {
			case PROGRAMMABLE(isTG, _, _):
				isProgrammable = true;
				isTileGroup = isTG;
			default:
		};

		var retRoot:h2d.Object;
		final internalResults:InternalBuilderResults = {
			names: [],
			interactives: [],
			slots: [],
			dynamicRefs: new Map(),
			htmlTextsWithLinks: [],
		}

		if (isTileGroup) {
			var root = new TileGroup();
			retRoot = root;
			this.currentNode = rootNode;

			root.setPosition(0, 0);
			applyExtendedFormProperties(root, rootNode);

			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);

			for (child in resolveConditionalChildren(rootNode.children)) {
				buildTileGroup(child, root, new Point(0, 0), gridCoordinateSystem, hexCoordinateSystem, builderParams);
			}
		} else if (isProgrammable) {
			final root = new h2d.Layers();
			retRoot = root;
			this.currentNode = rootNode;
			root.setPosition(0, 0);
			applyExtendedFormProperties(root, rootNode);

			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);

			for (child in resolveConditionalChildren(rootNode.children)) {
				build(child, LayersMode(root), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			}
		} else { // non-programmable
			final root = build(rootNode, RootMode, gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			retRoot = root;
			this.currentNode = rootNode;
			root.setPosition(0, 0);
			applyExtendedFormProperties(root, rootNode);

			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);

			for (child in resolveConditionalChildren(rootNode.children)) {
				build(child, ObjectMode(root), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			}
		}

		// Wrap in holder object if there's an offset
		
		final finalObject = if (retRoot.x != 0 || retRoot.y != 0) {
			final holder = new h2d.Object();
			holder.addChild(retRoot);
			retRoot.setPosition(retRoot.x, retRoot.y);
			holder;
		} else {
			retRoot;
		}
		
		return {
			object: finalObject,
			names: internalResults.names,
			name: name,
			interactives: internalResults.interactives,
			layouts: [],
			palettes: [],
			rootSettings: new BuilderResolvedSettings(resolveSettings(rootNode)),
			hexCoordinateSystem: hexCoordinateSystem,
			gridCoordinateSystem: gridCoordinateSystem,
			slots: internalResults.slots,
			dynamicRefs: internalResults.dynamicRefs,
			incrementalContext: null,
			htmlTextsWithLinks: if (internalResults.htmlTextsWithLinks.length > 0) internalResults.htmlTextsWithLinks else null,
		};
	}

	function getPalette(name:String) {
		return buildPalettes(name);
	}

	function buildPalettes(name:String):Palette {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get palette node #${name}');
		return switch node.type {
			case PALETTE(paletteType):
				return switch paletteType {
					case PaletteColors(colors): new Palette(resolveColorList(colors));
					case PaletteColors2D(colors, width): new Palette(resolveColorList(colors));
					case PaletteImageFile(filename):
						var filenameResolved = resolveAsString(filename);
						var res = resourceLoader.loadHXDResource(filenameResolved);
						if (res == null)
							throw builderErrorAt(node, 'could not load palette image $filename');
						var pixels = res.toImage().getPixels();
						var pixelArray = pixels.toVector().toArray();
						new Palette(pixelArray, pixels.width);
				}
			default: throw builderErrorAt(node, '$name has to be palette');
		}
	}

	function createParticleImpl(particlesDef, name, ?existingParticles:bh.base.Particles):bh.base.Particles {
		var particles = existingParticles != null ? existingParticles : new bh.base.Particles();
		final tiles = Lambda.map(particlesDef.tiles, x -> loadTileSource(x));
		var group = new bh.base.Particles.ParticleGroup(name, particles, tiles);

		if (particlesDef.count != null)
			group.nparts = resolveAsInteger(particlesDef.count);
		if (particlesDef.emitDelay != null)
			group.emitDelay = resolveAsNumber(particlesDef.emitDelay);
		if (particlesDef.emitSync != null)
			group.emitSync = resolveAsNumber(particlesDef.emitSync);
		if (particlesDef.maxLife != null)
			group.life = resolveAsNumber(particlesDef.maxLife);
		if (particlesDef.lifeRandom != null)
			group.lifeRand = resolveAsNumber(particlesDef.lifeRandom);
		if (particlesDef.size != null)
			group.size = resolveAsNumber(particlesDef.size);
		if (particlesDef.sizeRandom != null)
			group.sizeRand = resolveAsNumber(particlesDef.sizeRandom);
		if (particlesDef.speed != null)
			group.speed = resolveAsNumber(particlesDef.speed);
		if (particlesDef.speedRandom != null)
			group.speedRand = resolveAsNumber(particlesDef.speedRandom);
		if (particlesDef.speedIncrease != null)
			group.speedIncr = resolveAsNumber(particlesDef.speedIncrease);
		if (particlesDef.gravity != null)
			group.gravity = resolveAsNumber(particlesDef.gravity);
		if (particlesDef.gravityAngle != null)
			group.gravityAngle = hxd.Math.degToRad(resolveAsNumber(particlesDef.gravityAngle));

		if (particlesDef.fadeIn != null) {
			final f = resolveAsNumber(particlesDef.fadeIn);
			if (f < 0 || f > 1.0)
				throw builderError('fadeIn must be between 0 and 1');
			group.fadeIn = f;
		}
		if (particlesDef.fadeOut != null) {
			final f = resolveAsNumber(particlesDef.fadeOut);
			if (f < 0 || f > 1.0)
				throw builderError('fadeOut must be between 0 and 1');
			group.fadeOut = resolveAsNumber(particlesDef.fadeOut);
		}
		if (particlesDef.fadePower != null)
			group.fadePower = resolveAsNumber(particlesDef.fadePower);
		if (particlesDef.blendMode != null)
			group.blendMode = MacroCompatConvert.toH2dBlendMode(particlesDef.blendMode);
		if (particlesDef.loop != null)
			group.emitLoop = particlesDef.loop;
		if (particlesDef.relative != null)
			group.isRelative = particlesDef.relative;
		if (particlesDef.externallyDriven != null)
			group.externallyDriven = particlesDef.externallyDriven;

		if (particlesDef.rotationInitial != null)
			group.rotInit = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationInitial));
		if (particlesDef.rotationSpeed != null)
			group.rotSpeed = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationSpeed));
		if (particlesDef.rotationSpeedRandom != null)
			group.rotSpeedRand = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationSpeedRandom));
		if (particlesDef.rotateAuto != null)
			group.rotAuto = particlesDef.rotateAuto;
		if (particlesDef.forwardAngle != null)
			group.forwardAngle = hxd.Math.degToRad(resolveAsNumber(particlesDef.forwardAngle));

		// Animation repeat
		if (particlesDef.animationRepeat != null)
			group.animationRepeat = resolveAsNumber(particlesDef.animationRepeat);

		// Color stops (converted to color curve segments)
		if (particlesDef.colorStops != null) {
			group.colorEnabled = true;
			var stops:Array<ParticleColorStop> = particlesDef.colorStops;
			if (stops.length < 2)
				throw builderError('colorStops requires at least 2 stops');
			for (i in 0...stops.length - 1) {
				final s = stops[i];
				final next = stops[i + 1];
				var curve:bh.paths.Curve.ICurve;
				if (s.inlineEasing != null) {
					curve = new bh.paths.Curve(null, s.inlineEasing, null);
				} else if (s.curveName != null) {
					var curves = getCurves();
					var found = curves.get(s.curveName);
					if (found == null) {
						var easing = MacroManimParser.tryMatchEasingName(s.curveName);
						if (easing == null)
							throw builderError('color curve not found: ${s.curveName}');
						found = new bh.paths.Curve(null, easing, null);
						curves.set(s.curveName, found);
					}
					curve = found;
				} else {
					curve = new bh.paths.Curve(null, Linear, null);
				}
				group.addColorCurveSegment(resolveAsNumber(s.rate), curve, resolveAsColorInteger(s.color), resolveAsColorInteger(next.color));
			}
		}

		// Force fields
		if (particlesDef.forceFields != null) {
			group.forceFields = [];
			var forceFieldsArray:Array<ParticleForceFieldDef> = particlesDef.forceFields;
			for (ff in forceFieldsArray) {
				var converted:ForceField = switch ff {
					case FFAttractor(x, y, strength, radius):
						Attractor(resolveAsNumber(x), resolveAsNumber(y), resolveAsNumber(strength), resolveAsNumber(radius));
					case FFRepulsor(x, y, strength, radius):
						Repulsor(resolveAsNumber(x), resolveAsNumber(y), resolveAsNumber(strength), resolveAsNumber(radius));
					case FFVortex(x, y, strength, radius):
						Vortex(resolveAsNumber(x), resolveAsNumber(y), resolveAsNumber(strength), resolveAsNumber(radius));
					case FFWind(vx, vy):
						Wind(resolveAsNumber(vx), resolveAsNumber(vy));
					case FFTurbulence(strength, scale, speed):
						Turbulence(resolveAsNumber(strength), resolveAsNumber(scale), resolveAsNumber(speed));
					case FFPathGuide(pathName, attractStrength, flowStrength, radius):
						var pathObj = getPaths().getPath(pathName);
						PathGuide(pathObj, resolveAsNumber(attractStrength), resolveAsNumber(flowStrength), resolveAsNumber(radius));
				};
				group.forceFields.push(converted);
			}
		}

		// Velocity curve
		if (particlesDef.velocityCurve != null)
			group.velocityCurve = resolveParticleCurveRef(particlesDef.velocityCurve);

		// Size curve
		if (particlesDef.sizeCurve != null)
			group.sizeCurve = resolveParticleCurveRef(particlesDef.sizeCurve);

		// Bounds/collision
		if (particlesDef.boundsMode != null) {
			group.boundsMode = switch (particlesDef.boundsMode:ParticleBoundsModeDef) {
				case BMNone: BoundsMode.None;
				case BMKill: BoundsMode.Kill;
				case BMBounce(damping): BoundsMode.Bounce(resolveAsNumber(damping));
				case BMWrap: BoundsMode.Wrap;
			};
		}
		if (particlesDef.boundsMinX != null)
			group.boundsMinX = resolveAsNumber(particlesDef.boundsMinX);
		if (particlesDef.boundsMaxX != null)
			group.boundsMaxX = resolveAsNumber(particlesDef.boundsMaxX);
		if (particlesDef.boundsMinY != null)
			group.boundsMinY = resolveAsNumber(particlesDef.boundsMinY);
		if (particlesDef.boundsMaxY != null)
			group.boundsMaxY = resolveAsNumber(particlesDef.boundsMaxY);
		if (particlesDef.boundsLines != null) {
			var boundsLinesArray:Array<ParticleBoundsLineDef> = particlesDef.boundsLines;
			for (bl in boundsLinesArray) {
				group.addBoundsLine(resolveAsNumber(bl.x1), resolveAsNumber(bl.y1), resolveAsNumber(bl.x2), resolveAsNumber(bl.y2));
			}
		}

		// Sub-emitters
		if (particlesDef.subEmitters != null) {
			group.subEmitters = [];
			var subEmittersArray:Array<ParticleSubEmitterDef> = particlesDef.subEmitters;
			for (se in subEmittersArray) {
				var trigger:SubEmitTrigger = switch se.trigger {
					case SETOnBirth: OnBirth;
					case SETOnDeath: OnDeath;
					case SETOnCollision: OnCollision;
					case SETOnInterval(interval): OnInterval(resolveAsNumber(interval));
				};
				group.subEmitters.push({
					groupId: se.groupId,
					trigger: trigger,
					probability: resolveAsNumber(se.probability),
					inheritVelocity: se.inheritVelocity != null ? resolveAsNumber(se.inheritVelocity) : 0.0,
					offsetX: se.offsetX != null ? resolveAsNumber(se.offsetX) : 0.0,
					offsetY: se.offsetY != null ? resolveAsNumber(se.offsetY) : 0.0,
					burstCount: se.burstCount != null ? resolveAsInteger(se.burstCount) : 1
				});
			}
		}

		// Emit mode
		switch particlesDef.emit {
			case Point(emitDistance, emitDistanceRandom):
				group.emitMode = bh.base.PartEmitMode.Point(resolveAsNumber(emitDistance), resolveAsNumber(emitDistanceRandom));
			case Cone(emitDistance, emitDistanceRandom, emitConeAngle, emitConeAngleRandom):
				group.emitMode = bh.base.PartEmitMode.Cone(resolveAsNumber(emitDistance), resolveAsNumber(emitDistanceRandom), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)),
					hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)));
			case Box(width, height, emitConeAngle, emitConeAngleRandom, center):
				group.emitMode = bh.base.PartEmitMode.Box(resolveAsNumber(width), resolveAsNumber(height), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)),
					hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)), center);
			case Circle(radius, radiusRandom, emitConeAngle, emitConeAngleRandom):
				group.emitMode = bh.base.PartEmitMode.Circle(resolveAsNumber(radius), resolveAsNumber(radiusRandom), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)),
					hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)));
			case ManimPath(pathName):
				var path = getPaths().getPath(pathName);
				group.emitMode = bh.base.PartEmitMode.ManimPath(path);
			case ManimPathTangent(pathName):
				var path = getPaths().getPath(pathName);
				group.emitMode = bh.base.PartEmitMode.ManimPathTangent(path);
		}

		// AnimatedPath integration
		if (particlesDef.attachTo != null) {
			group.attachedPath = createAnimatedPath(particlesDef.attachTo);
		}
		if (particlesDef.spawnCurve != null)
			group.spawnCurve = resolveParticleCurveRef(particlesDef.spawnCurve);

		// AnimSM tile source
		if (particlesDef.animFile != null && particlesDef.animStates != null) {
			var selector:Map<String, String> = particlesDef.animSelector != null ? particlesDef.animSelector : new Map();
			final animParser = resourceLoader.loadAnimParser(particlesDef.animFile);
			final animSM = animParser.createAnimSM(selector);

			// Build anim states sorted by startLifeRate
			var animStatesArray:Array<ParticleAnimStateDef> = particlesDef.animStates;
			for (asDef in animStatesArray) {
				var animName = asDef.animName;
				var descriptor = animSM.animationStates.get(animName);
				if (descriptor == null)
					throw builderError('particle animation "${animName}" not found in "${particlesDef.animFile}"');

				// Extract tiles from animation frames
				var frameTiles:Array<h2d.Tile> = [];
				for (state in descriptor.states) {
					switch state {
						case Frame(frame):
							if (frame.tile != null) frameTiles.push(frame.tile);
						case _:
					}
				}

				group.animStates.push({
					name: animName,
					tiles: frameTiles,
					fps: 0,
					startLifeRate: resolveAsNumber(asDef.atRate)
				});
			}

			// Sort by startLifeRate
			group.animStates.sort((a, b) -> a.startLifeRate < b.startLifeRate ? -1 : a.startLifeRate > b.startLifeRate ? 1 : 0);

			// Build event overrides — map trigger name to index in animStates
			if (particlesDef.animEventOverrides != null) {
				var animEventOverridesArray:Array<ParticleAnimEventOverride> = particlesDef.animEventOverrides;
				for (eo in animEventOverridesArray) {
					// Find the animStates index matching this animation name
					var foundIndex = -1;
					for (i in 0...group.animStates.length) {
						if (group.animStates[i].name == eo.animName) {
							foundIndex = i;
							break;
						}
					}
					if (foundIndex < 0) {
						// The event override references an anim that wasn't added as a lifetime state — add it
						var descriptor = animSM.animationStates.get(eo.animName);
						if (descriptor == null)
							throw builderError('particle event animation "${eo.animName}" not found in "${particlesDef.animFile}"');

						var frameTiles:Array<h2d.Tile> = [];
						for (state in descriptor.states) {
							switch state {
								case Frame(frame):
									if (frame.tile != null) frameTiles.push(frame.tile);
								case _:
							}
						}

						foundIndex = group.animStates.length;
						group.animStates.push({
							name: eo.animName,
							tiles: frameTiles,
							fps: 0,
							startLifeRate: 1.0 // Event overrides don't have a natural startLifeRate
						});
					}
					group.animEventOverrides.set(eo.trigger, foundIndex);
				}
			}
		}

		// Shutdown configuration
		if (particlesDef.shutdown != null) {
			final sd = particlesDef.shutdown;
			if (sd.duration != null)
				group.shutdownDuration = resolveAsNumber(sd.duration);
			if (sd.curve != null)
				group.shutdownCountCurve = resolveParticleCurveRef(sd.curve);
			if (sd.alphaCurve != null)
				group.shutdownAlphaCurve = resolveParticleCurveRef(sd.alphaCurve);
			if (sd.sizeCurve != null)
				group.shutdownSizeCurve = resolveParticleCurveRef(sd.sizeCurve);
			if (sd.speedCurve != null)
				group.shutdownSpeedCurve = resolveParticleCurveRef(sd.speedCurve);
		}

		particles.addGroup(group);
		return particles;
	}

	public function createParticles(name:String, ?builderParams:BuilderParameters):bh.base.Particles {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get particles node #${name}');
		switch node.type {
			case PARTICLES(particlesDef):
				return createParticleImpl(particlesDef, name);

			default:
				throw builderErrorAt(node, '$name has to be particles');
		}
	}

	/** Add a particle group to an existing Particles container (for sub-emitters). */
	public function addParticleGroupTo(name:String, particles:bh.base.Particles):Void {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get particles node #${name}');
		switch node.type {
			case PARTICLES(particlesDef):
				createParticleImpl(particlesDef, name, particles);
			default:
				throw builderErrorAt(node, '$name has to be particles');
		}
	}

	/** Create particles from a ParticlesDef directly (used by ProgrammableBuilder) */
	public function createParticleFromDef(particlesDef:ParticlesDef, name:String):bh.base.Particles {
		return createParticleImpl(particlesDef, name);
	}

	/** Get a data block by name, returning its fields as a Dynamic object. */
	public function getData(name:String):Dynamic {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get data node #${name}');
		switch node.type {
			case DATA(dataDef):
				return resolveDataDef(dataDef);
			default:
				throw builderErrorAt(node, '$name has to be data');
		}
	}

	private function resolveDataDef(dataDef:DataDef):Dynamic {
		var result:Dynamic = {};
		for (field in dataDef.fields) {
			Reflect.setField(result, field.name, resolveDataValue(field.value));
		}
		return result;
	}

	private function resolveDataValue(value:DataValue):Dynamic {
		return switch (value) {
			case DVInt(v): v;
			case DVFloat(v): v;
			case DVString(v): v;
			case DVBool(v): v;
			case DVArray(elements):
				var arr:Array<Dynamic> = [for (e in elements) resolveDataValue(e)];
				arr;
			case DVRecord(_, fields):
				var obj:Dynamic = {};
				for (key => val in fields) {
					Reflect.setField(obj, key, resolveDataValue(val));
				}
				obj;
			case DVEnumValue(_, value): value;
		};
	}

	/** Create an AnimatedPath from a named definition.
	 *  Optional PathNormalization transform controls how the path is positioned/scaled. */
	public function createAnimatedPath(name:String, ?normalization:bh.paths.MultiAnimPaths.PathNormalization):bh.paths.AnimatedPath {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get animatedPath node #${name}');
		switch node.type {
			case ANIMATED_PATH(pathDef):
				// Resolve path from paths block, apply optional transforms
				var paths = getPaths();
				var path = paths.getPath(pathDef.pathName, normalization);

				// Determine mode
				var mode:AnimatedPathMode = switch (pathDef.mode) {
					case APTime | null if (pathDef.duration != null):
						Time(resolveAsNumber(pathDef.duration));
					case APDistance | null if (pathDef.speed != null):
						Distance(resolveAsNumber(pathDef.speed));
					case APTime:
						throw builderErrorAt(node, 'time mode requires duration');
					case APDistance:
						throw builderErrorAt(node, 'distance mode requires speed');
					case null:
						throw builderErrorAt(node, 'animatedPath requires either speed or duration');
				};

				var retVal = new bh.paths.AnimatedPath(path, mode);
				retVal.loop = pathDef.loop;
				retVal.pingPong = pathDef.pingPong;

				// Resolve curve references
				var allCurves:Null<Map<String, bh.paths.Curve.ICurve>> = null;
				for (ca in pathDef.curveAssignments) {
					var atRate:Float = switch ca.at {
						case Rate(r): resolveAsNumber(r);
						case Checkpoint(cpName): path.getCheckpoint(cpName);
					};
					// Resolve curve: inline easing takes precedence over named curve
					var curve:bh.paths.Curve.ICurve;
					if (ca.inlineEasing != null) {
						curve = new bh.paths.Curve(null, ca.inlineEasing, null);
					} else if (ca.curveName != null) {
						if (allCurves == null) allCurves = getCurves();
						var resolved = allCurves.get(ca.curveName);
						if (resolved == null) {
							var easing = MacroManimParser.tryMatchEasingName(ca.curveName);
							if (easing == null)
								throw builderErrorAt(node, 'curve not found: ${ca.curveName}');
							resolved = new bh.paths.Curve(null, easing, null);
							allCurves.set(ca.curveName, resolved);
						}
						curve = resolved;
					} else {
						throw builderErrorAt(node, 'curve assignment must have either curveName or inlineEasing');
					}
					switch ca.slot {
						case APSpeed: retVal.addCurveSegment(Speed, atRate, curve);
						case APScale: retVal.addCurveSegment(Scale, atRate, curve);
						case APAlpha: retVal.addCurveSegment(Alpha, atRate, curve);
						case APRotation: retVal.addCurveSegment(Rotation, atRate, curve);
						case APProgress: retVal.addCurveSegment(Progress, atRate, curve);
						case APColor(startColor, endColor):
							retVal.addColorCurveSegment(atRate, curve, resolveAsColorInteger(startColor), resolveAsColorInteger(endColor));
						case APCustom(customName): retVal.addCustomCurveSegment(customName, atRate, curve);
					}
				}

				// Add events
				for (ev in pathDef.events) {
					var atRate:Float = switch ev.at {
						case Rate(r): resolveAsNumber(r);
						case Checkpoint(cpName): path.getCheckpoint(cpName);
					};
					retVal.addEvent(atRate, ev.eventName);
				}

				return retVal;

			default:
				throw builderErrorAt(node, '$name has to be animatedPath');
		}
	}

	/** Convenience method for creating a projectile path: stretches the named path
	 *  from startPoint to endPoint using Stretch normalization. */
	public function createProjectilePath(name:String, startPoint:bh.base.FPoint, endPoint:bh.base.FPoint):bh.paths.AnimatedPath {
		return createAnimatedPath(name, bh.paths.MultiAnimPaths.PathNormalization.Stretch(startPoint, endPoint));
	}

	public function getLayouts(?builderParams:BuilderParameters):MultiAnimLayouts {
		var node = multiParserResult.nodes.get(MultiAnimParser.defaultLayoutNodeName);
		if (node == null)
			throw builderError('layouts block does not exist');
		switch node.type {
			case RELATIVE_LAYOUTS(layoutsDef):
				return new MultiAnimLayouts(layoutsDef, this);
			default:
				throw builderErrorAt(node, 'layouts block is of unexpected type ${node.type}');
		}
	}

	public function getPaths(?builderParams:BuilderParameters):bh.paths.MultiAnimPaths {
		var node = multiParserResult.nodes.get(MultiAnimParser.defaultPathNodeName);
		if (node == null)
			throw builderError('paths does not exist');
		switch node.type {
			case PATHS(pathsDef):
				return new bh.paths.MultiAnimPaths(pathsDef, this);
			default:
				throw builderErrorAt(node, 'paths is of unexpected type ${node.type}');
		}
	}

	public function getCurves():Map<String, bh.paths.Curve.ICurve> {
		var node = multiParserResult.nodes.get(MultiAnimParser.defaultCurveNodeName);
		if (node == null)
			throw builderError('curves does not exist');
		switch node.type {
			case CURVES(curvesDef):
				var result = new Map<String, bh.paths.Curve.ICurve>();
				var resolving = new Map<String, Bool>();

				var resolveCurve:String->bh.paths.Curve.ICurve = function(_:String):bh.paths.Curve.ICurve throw "unreachable";
				resolveCurve = function(name:String):bh.paths.Curve.ICurve {
					var existing = result.get(name);
					if (existing != null) return existing;

					if (resolving.exists(name))
						throw builderError('circular curve reference: $name');
					var def = curvesDef.get(name);
					if (def == null) {
						// Auto-resolve easing names as built-in curves
						var easing = MacroManimParser.tryMatchEasingName(name);
						if (easing == null)
							throw builderError('unknown curve reference: $name');
						var curve = new bh.paths.Curve(null, easing, null);
						result.set(name, curve);
						return curve;
					}

					resolving.set(name, true);

					var curve:bh.paths.Curve.ICurve;
					if (def.operation != null) {
						curve = switch (def.operation) {
							case Multiply(names):
								new bh.paths.Curve.MultiplyCurve([for (n in names) resolveCurve(n)]);
							case Compose(outerName, innerName):
								new bh.paths.Curve.ComposeCurve(resolveCurve(outerName), resolveCurve(innerName));
							case Invert(curveName):
								new bh.paths.Curve.InvertCurve(resolveCurve(curveName));
							case Scale(curveName, factor):
								new bh.paths.Curve.ScaleCurve(resolveCurve(curveName), resolveAsNumber(factor));
						};
					} else {
						var resolvedPoints:Null<Array<bh.paths.Curve.CurvePoint>> = null;
						if (def.points != null) {
							resolvedPoints = [];
							for (p in def.points) {
								resolvedPoints.push({time: resolveAsNumber(p.time), value: resolveAsNumber(p.value)});
							}
						}
						var resolvedSegments:Null<Array<bh.paths.Curve.CurveSegment>> = null;
						if (def.segments != null) {
							resolvedSegments = [];
							for (s in def.segments) {
								resolvedSegments.push({
									timeStart: resolveAsNumber(s.timeStart),
									timeEnd: resolveAsNumber(s.timeEnd),
									easing: s.easing,
									valueStart: resolveAsNumber(s.valueStart),
									valueEnd: resolveAsNumber(s.valueEnd)
								});
							}
						}
						curve = new bh.paths.Curve(resolvedPoints, def.easing, resolvedSegments);
					}

					resolving.remove(name);
					result.set(name, curve);
					return curve;
				};

				for (name => _ in curvesDef) resolveCurve(name);
				return result;
			default:
				throw builderErrorAt(node, 'curves is of unexpected type ${node.type}');
		}
	}

	public function getCurve(name:String):bh.paths.Curve.ICurve {
		var curves = getCurves();
		var curve = curves.get(name);
		if (curve == null) {
			var easing = MacroManimParser.tryMatchEasingName(name);
			if (easing == null)
				throw builderError('curve not found: $name');
			curve = new bh.paths.Curve(null, easing, null);
			curves.set(name, curve);
		}
		return curve;
	}

	function resolveParticleCurveRef(ref:MultiAnimParser.ParticleCurveRef):bh.paths.Curve.ICurve {
		if (ref.inlineEasing != null)
			return new bh.paths.Curve(null, ref.inlineEasing, null);
		if (ref.curveName != null) {
			var curves = getCurves();
			var curve = curves.get(ref.curveName);
			if (curve == null) {
				var easing = MacroManimParser.tryMatchEasingName(ref.curveName);
				if (easing == null)
					throw builderError('curve not found: ${ref.curveName}');
				curve = new bh.paths.Curve(null, easing, null);
				curves.set(ref.curveName, curve);
			}
			return curve;
		}
		throw builderError('curve reference must have either curveName or inlineEasing');
	}

	/**
	 * Build a TileGroup from autotile definition based on a binary grid.
	 * @param name The name of the autotile definition in the .manim file
	 * @param grid 2D array of 0/1 values where 1 = terrain present
	 * @return h2d.TileGroup populated with the correct autotiles
	 */
	public function buildAutotile(name:String, grid:Array<Array<Int>>):h2d.TileGroup {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get autotile node #${name}');
		switch node.type {
			case AUTOTILE(autotileDef):
				return buildAutotileImpl(autotileDef, grid, null);
			default:
				throw builderErrorAt(node, '$name has to be autotile');
		}
	}

	/**
	 * Build a TileGroup from autotile definition with elevation data.
	 * @param name The name of the autotile definition in the .manim file
	 * @param grid 2D array of elevation levels (0 = empty, 1+ = terrain at that elevation)
	 * @param baseY Base Y position for rendering
	 * @return h2d.TileGroup populated with the correct autotiles and depth
	 */
	public function buildAutotileElevation(name:String, grid:Array<Array<Int>>, baseY:Float):h2d.TileGroup {
		var node = multiParserResult.nodes.get(name);
		if (node == null)
			throw builderError('could not get autotile node #${name}');
		switch node.type {
			case AUTOTILE(autotileDef):
				return buildAutotileImpl(autotileDef, grid, baseY);
			default:
				throw builderErrorAt(node, '$name has to be autotile');
		}
	}

	private function buildAutotileImpl(autotileDef:AutotileDef, grid:Array<Array<Int>>, ?elevationBaseY:Null<Float>):h2d.TileGroup {
		final tileGroup = new h2d.TileGroup();
		final tiles = loadAutotileTiles(autotileDef);
		final tileSize = resolveAsInteger(autotileDef.tileSize);
		final _depth = autotileDef.depth; final depth = _depth != null ? resolveAsInteger(_depth) : 0;
		// For ATSFile with mapping, the mapping is applied during tile loading, so don't apply it here
		final mappingAppliedDuringLoading = switch autotileDef.source {
			case ATSFile(_): autotileDef.mapping != null;
			default: false;
		};
		final mapping = mappingAppliedDuringLoading ? null : autotileDef.mapping;

		final height = grid.length;
		if (height == 0)
			return tileGroup;
		final width = grid[0].length;

		for (y in 0...height) {
			for (x in 0...width) {
				if (grid[y][x] == 0)
					continue;

				final mask8 = bh.base.Autotile.getNeighborMask8(grid, x, y);
				var tileIndex = switch autotileDef.format {
					case Cross: bh.base.Autotile.getCrossIndex(mask8);
					case Blob47: bh.base.Autotile.getBlob47IndexWithFallback(mask8, tiles.length);
				};

				// Apply custom mapping if provided (Map<Int, Int>)
				if (mapping != null) {
					var actualIndex = tileIndex;
					// For blob47 with allowPartialMapping, apply fallback for missing tiles
					if (autotileDef.format == Blob47 && autotileDef.allowPartialMapping && !mapping.exists(actualIndex)) {
						actualIndex = bh.base.Autotile.applyBlob47FallbackWithMap(tileIndex, mapping);
					}
					final mapped = mapping.get(actualIndex);
					if (mapped != null) {
						tileIndex = mapped;
					}
				}

				if (tileIndex >= 0 && tileIndex < tiles.length) {
					final tile = tiles[tileIndex];
					final renderX = x * tileSize;
					var renderY = y * tileSize;

					// Handle elevation depth rendering
					if (elevationBaseY != null && depth > 0) {
						// Render depth/wall below the tile for edge tiles
						final hasS = (mask8 & bh.base.Autotile.S) == 0;
						if (hasS && tileIndex < tiles.length) {
							// This is a south-facing edge, render wall depth below
							for (d in 0...Std.int(depth / tileSize) + 1) {
								tileGroup.add(renderX, renderY + tileSize + d * tileSize, tile);
							}
						}
					}

					tileGroup.add(renderX, renderY, tile);
				}
			}
		}

		return tileGroup;
	}

	private function loadAutotileTiles(autotileDef:AutotileDef):Array<h2d.Tile> {
		final tileSize = resolveAsInteger(autotileDef.tileSize);

		return switch autotileDef.source {
			case ATSAtlas(sheet, prefix):
				final atlas = getOrLoadSheet(resolveAsString(sheet));
				final prefixStr = resolveAsString(prefix);
				final tileCount = switch autotileDef.format {
					case Cross: 13;
					case Blob47: 47;
				};
				[for (i in 0...tileCount) atlas.get(prefixStr + Std.string(i)).tile];

			case ATSAtlasRegion(sheet, region):
				// For region-based loading, we need to load the sheet's image file directly
				// This requires the sheet to have a loadable tile resource
				final sheetName = resolveAsString(sheet);
				final baseTile = resourceLoader.loadTile(sheetName);
				final rx = resolveAsInteger(region[0]);
				final ry = resolveAsInteger(region[1]);
				final rw = resolveAsInteger(region[2]);
				final rh = resolveAsInteger(region[3]);
				final tilesPerRow = Std.int(rw / tileSize);
				final tileCount = switch autotileDef.format {
					case Cross: 13;
					case Blob47: 47;
				};
				[
					for (i in 0...tileCount)
						baseTile.sub(rx + (i % tilesPerRow) * tileSize, ry + Std.int(i / tilesPerRow) * tileSize, tileSize, tileSize)
				];

			case ATSFile(filename):
				final baseTile = resourceLoader.loadTile(resolveAsString(filename));
				final tileCount = switch autotileDef.format {
					case Cross: 13;
					case Blob47: 47;
				};

				// If region is provided, extract tiles from that region only
				// Region format: [offsetX, offsetY, width, height]
				// Tile indices in mapping are relative to the region
				final _region = autotileDef.region;
				final regionX = _region != null ? resolveAsInteger(_region[0]) : 0;
				final regionY = _region != null ? resolveAsInteger(_region[1]) : 0;
				final regionW = _region != null ? resolveAsInteger(_region[2]) : Std.int(baseTile.width);
				final tilesPerRow = Std.int(regionW / tileSize);

				// If mapping is provided (Map<Int, Int>), load tiles from mapped positions
				// For allowPartialMapping, missing tiles will be filled with a placeholder and resolved at render time
				final _mapping = autotileDef.mapping;
				if (_mapping != null) {
					final result = new Array<h2d.Tile>();
					for (i in 0...tileCount) {
						// Get the mapped tileset index, using fallback for missing blob47 tiles
						var mappedIdx = 0;
						final mv = _mapping.get(i);
						if (mv != null) {
							mappedIdx = mv;
						} else if (autotileDef.format == Blob47 && autotileDef.allowPartialMapping) {
							// Find fallback tile and use its mapping
							final fallbackIdx = bh.base.Autotile.applyBlob47FallbackWithMap(i, _mapping);
							final fv = _mapping.get(fallbackIdx);
							mappedIdx = fv != null ? fv : 0;
						} else {
							throw builderError('autotile: tile index $i not found in mapping');
						}
						result.push(baseTile.sub(
							regionX + (mappedIdx % tilesPerRow) * tileSize,
							regionY + Std.int(mappedIdx / tilesPerRow) * tileSize,
							tileSize, tileSize
						));
					}
					result;
				}
				else {
					// Sequential tile extraction from the region
					[for (i in 0...tileCount) baseTile.sub(
						regionX + (i % tilesPerRow) * tileSize,
						regionY + Std.int(i / tilesPerRow) * tileSize,
						tileSize, tileSize
					)];
				}

			case ATSTiles(tiles):
				// Explicit tile list - load each tile source directly
				[for (ts in tiles) loadTileSource(ts)];

			case ATSDemo(edgeColor, fillColor):
				// Auto-generated demo tiles based on format
				final edge = resolveAsColorInteger(edgeColor);
				final fill = resolveAsColorInteger(fillColor);
				final tileCount = switch autotileDef.format {
					case Cross: 13;
					case Blob47: 47;
				};
				[for (i in 0...tileCount) generateAutotileDemoTile(autotileDef.format, i, tileSize, edge, fill)];
		};
	}

	/**
	 * Generate a single demo tile for autotiling visualization.
	 * Draws tiles with edge/fill colors showing which edges connect to neighbors.
	 * Outer corners get diagonal triangles for smoother appearance.
	 */
	private function generateAutotileDemoTile(format:AutotileFormat, tileIndex:Int, tileSize:Int, edgeColor:Int, fillColor:Int):h2d.Tile {
		final borderWidth = Std.int(Math.max(1, tileSize / 8));
		final cornerSize = Std.int(Math.max(2, tileSize / 2)); // Size of diagonal corner cut
		final pl = new PixelLines(tileSize, tileSize);

		// Fill entire tile with fill color
		pl.filledRect(0, 0, tileSize, tileSize, fillColor);

		// Get edge configuration for this tile index
		final edges = getAutotileEdges(format, tileIndex);

		// Draw borders on edges where there's no neighbor (edge = true means draw border)
		if (edges.n)
			pl.filledRect(0, 0, tileSize, borderWidth, edgeColor);
		if (edges.s)
			pl.filledRect(0, tileSize - borderWidth, tileSize, borderWidth, edgeColor);
		if (edges.w)
			pl.filledRect(0, 0, borderWidth, tileSize, edgeColor);
		if (edges.e)
			pl.filledRect(tileSize - borderWidth, 0, borderWidth, tileSize, edgeColor);

		// Draw outer corner triangles (diagonal cut) where two adjacent edges meet
		if (edges.n && edges.w) {
			// NW outer corner - triangle from (0,cornerSize) to (cornerSize,0)
			for (i in 0...cornerSize) {
				final lineLen = cornerSize - i;
				pl.filledRect(0, i, lineLen, 1, edgeColor);
			}
		}
		if (edges.n && edges.e) {
			// NE outer corner - triangle from (tileSize-cornerSize,0) to (tileSize,cornerSize)
			for (i in 0...cornerSize) {
				final lineLen = cornerSize - i;
				pl.filledRect(tileSize - lineLen, i, lineLen, 1, edgeColor);
			}
		}
		if (edges.s && edges.w) {
			// SW outer corner - triangle from (0,tileSize-cornerSize) to (cornerSize,tileSize)
			for (i in 0...cornerSize) {
				final lineLen = cornerSize - i;
				pl.filledRect(0, tileSize - 1 - i, lineLen, 1, edgeColor);
			}
		}
		if (edges.s && edges.e) {
			// SE outer corner - triangle from (tileSize-cornerSize,tileSize) to (tileSize,tileSize-cornerSize)
			for (i in 0...cornerSize) {
				final lineLen = cornerSize - i;
				pl.filledRect(tileSize - lineLen, tileSize - 1 - i, lineLen, 1, edgeColor);
			}
		}

		// Draw inner corners (triangular notches for diagonal-missing tiles)
		// Inner corners are the opposite of outer corners - they cut into the fill
		final innerCornerSize = Std.int(Math.max(2, tileSize / 4)); // Smaller than outer corners
		if (edges.innerNE) {
			// Inner NE corner - triangle at top-right cutting into fill
			for (i in 0...innerCornerSize) {
				final lineLen = innerCornerSize - i;
				pl.filledRect(tileSize - lineLen, i, lineLen, 1, edgeColor);
			}
		}
		if (edges.innerNW) {
			// Inner NW corner - triangle at top-left cutting into fill
			for (i in 0...innerCornerSize) {
				final lineLen = innerCornerSize - i;
				pl.filledRect(0, i, lineLen, 1, edgeColor);
			}
		}
		if (edges.innerSE) {
			// Inner SE corner - triangle at bottom-right cutting into fill
			for (i in 0...innerCornerSize) {
				final lineLen = innerCornerSize - i;
				pl.filledRect(tileSize - lineLen, tileSize - 1 - i, lineLen, 1, edgeColor);
			}
		}
		if (edges.innerSW) {
			// Inner SW corner - triangle at bottom-left cutting into fill
			for (i in 0...innerCornerSize) {
				final lineLen = innerCornerSize - i;
				pl.filledRect(0, tileSize - 1 - i, lineLen, 1, edgeColor);
			}
		}

		pl.updateBitmap();
		return pl.tile;
	}

	/**
	 * Get edge configuration for a tile index in a given format.
	 * Returns which edges/corners should have borders drawn.
	 */
	private function getAutotileEdges(format:AutotileFormat, tileIndex:Int):{n:Bool, s:Bool, e:Bool, w:Bool, innerNE:Bool, innerNW:Bool, innerSE:Bool, innerSW:Bool} {
		return switch format {
			case Cross: getCrossEdges(tileIndex);
			case Blob47: getBlob47Edges(tileIndex);
		};
	}

	/**
	 * Cross format edge configuration.
	 * Layout: 0=N 1=W 2=C 3=E 4=S / 5=NW 6=NE 7=SW 8=SE outer / 9-12=inner corners
	 */
	private function getCrossEdges(idx:Int):{n:Bool, s:Bool, e:Bool, w:Bool, innerNE:Bool, innerNW:Bool, innerSE:Bool, innerSW:Bool} {
		return switch idx {
			case 0: {n: true, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N edge
			case 1: {n: false, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // W edge
			case 2: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // Center
			case 3: {n: false, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // E edge
			case 4: {n: false, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // S edge
			case 5: {n: true, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // NW outer corner
			case 6: {n: true, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // NE outer corner
			case 7: {n: false, s: true, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // SW outer corner
			case 8: {n: false, s: true, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // SE outer corner
			case 9: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: false, innerSE: false, innerSW: false}; // inner-NE
			case 10: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: true, innerSE: false, innerSW: false}; // inner-NW
			case 11: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: true, innerSW: false}; // inner-SE
			case 12: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: true}; // inner-SW
			default: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};
		};
	}

	/**
	 * Blob47 edge configuration based on the reduced mask mapping.
	 * Maps each of the 47 tiles to its edge/corner configuration.
	 * Inner corners are drawn where diagonal is MISSING (not present).
	 * Comments show which neighbors ARE present.
	 */
	private function getBlob47Edges(idx:Int):{n:Bool, s:Bool, e:Bool, w:Bool, innerNE:Bool, innerNW:Bool, innerSE:Bool, innerSW:Bool} {
		return switch idx {
			// No cardinals - isolated or single edges (no inner corners possible)
			case 0: {n: true, s: true, e: true, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};     // isolated
			case 1: {n: false, s: true, e: true, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};    // N only
			case 2: {n: true, s: true, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};    // E only
			case 5: {n: true, s: false, e: true, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};    // S only
			case 13: {n: true, s: true, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};   // W only

			// Two adjacent cardinals - outer corners (no inner corners)
			case 3: {n: false, s: true, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};   // N+E (corner)
			case 4: {n: false, s: true, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};   // N+NE+E
			case 7: {n: true, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};   // E+S (corner)
			case 10: {n: true, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // E+SE+S
			case 14: {n: false, s: true, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // N+W (corner)
			case 18: {n: true, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // S+W (corner)
			case 26: {n: true, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // S+SW+W
			case 34: {n: false, s: true, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // N+W+NW

			// Two opposite cardinals - edges (no inner corners)
			case 6: {n: false, s: false, e: true, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};   // N+S
			case 15: {n: true, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // E+W
			case 19: {n: false, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+S+W
			case 27: {n: false, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+S+SW+W
			case 37: {n: false, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+S+W+NW
			case 42: {n: false, s: false, e: true, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+S+SW+W+NW

			// Three cardinals - T-shapes (no inner corners in missing direction)
			case 8: {n: false, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // N+E+S
			case 9: {n: false, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false};  // N+NE+E+S
			case 11: {n: false, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+E+SE+S
			case 12: {n: false, s: false, e: false, w: true, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+NE+E+SE+S
			case 16: {n: false, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+E+W
			case 17: {n: false, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+NE+E+W
			case 20: {n: true, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // E+S+W
			case 23: {n: true, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // E+SE+S+W
			case 28: {n: true, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // E+S+SW+W
			case 31: {n: true, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // E+SE+S+SW+W
			case 35: {n: false, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+E+W+NW
			case 36: {n: false, s: true, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // N+NE+E+W+NW

			// All four cardinals - inner corners where diagonals are MISSING
			case 21: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: true, innerSE: true, innerSW: true};    // N+E+S+W (all diagonals missing)
			case 22: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: true, innerSE: true, innerSW: true};   // N+NE+E+S+W (NE present)
			case 24: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: true, innerSE: false, innerSW: true};   // N+E+SE+S+W (SE present)
			case 25: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: true, innerSE: false, innerSW: true};  // N+NE+E+SE+S+W (NE+SE present)
			case 29: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: true, innerSE: true, innerSW: false};   // N+E+S+SW+W (SW present)
			case 30: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: true, innerSE: true, innerSW: false};  // N+NE+E+S+SW+W (NE+SW present)
			case 32: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: true, innerSE: false, innerSW: false};  // N+E+SE+S+SW+W (SE+SW present)
			case 33: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: true, innerSE: false, innerSW: false}; // N+NE+E+SE+S+SW+W (NE+SE+SW present)
			case 38: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: false, innerSE: true, innerSW: true};   // N+E+S+W+NW (NW present)
			case 39: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: true, innerSW: true};  // N+NE+E+S+W+NW (NE+NW present)
			case 40: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: false, innerSE: false, innerSW: true};  // N+E+SE+S+W+NW (SE+NW present)
			case 41: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: true}; // N+NE+E+SE+S+W+NW (NE+SE+NW present)
			case 43: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: false, innerSE: true, innerSW: false};  // N+E+S+SW+W+NW (SW+NW present)
			case 44: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: true, innerSW: false}; // N+NE+E+S+SW+W+NW (NE+SW+NW present)
			case 45: {n: false, s: false, e: false, w: false, innerNE: true, innerNW: false, innerSE: false, innerSW: false}; // N+E+SE+S+SW+W+NW (SE+SW+NW present)
			case 46: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false}; // all neighbors (none missing)
			default: {n: false, s: false, e: false, w: false, innerNE: false, innerNW: false, innerSE: false, innerSW: false};
		};
	}

	function updateIndexedParamsFromDynamicMap(node: Node, input:Map<String, Dynamic>, definitions:ParametersDefinitions,
			?extraInput:Map<String, ResolvedIndexParameters>, resolveExtraInput:Bool = false):Void {
		inline function getDefsType(key:String, value:Dynamic) {
			final type = definitions.get(key)?.type;
			if (type == null) {
				final availableParams = [for (k in definitions.keys()) k];
				throw builderErrorAt(node, 'Setting "$key" does not match any parameter of programmable "#${node.uniqueNodeName}". Available parameters: ${availableParams.join(", ")}');
			}
			return type;
		}

		function resolveReferenceableValue(ref:ReferenceableValue, type):Dynamic {
			return switch type {
				case null: throw builderErrorAt(node, 'type is null');
				case PPTHexDirection: resolveAsInteger(ref);
				case PPTGridDirection: resolveAsInteger(ref);
				case PPTFlags(_): resolveAsInteger(ref);
				case PPTEnum(_): resolveAsString(ref);
				case PPTRange(_, _): resolveAsInteger(ref);
				case PPTInt: resolveAsInteger(ref);
				case PPTFloat: resolveAsNumber(ref);
				// PPTBool must go through resolveAsBool — `staticRef(…, enabled=>true)` parses the
				// literal as RVString("true"), and resolveAsInteger would then try Std.parseInt("true")
				// and throw. resolveAsBool handles the string→bool conversion via tryStringToBool,
				// then dynamicValueToIndex stringifies the bool back to "true"/"false" and maps it
				// to Value(1)/Value(0).
				case PPTBool: resolveAsBool(ref);
				case PPTUnsignedInt: resolveAsInteger(ref);
				case PPTString: resolveAsString(ref);
				case PPTColor: resolveAsColorInteger(ref);
				case PPTArray: resolveAsArray(ref);
				case PPTTile: resolveAsString(ref);
			}
		}

		final retVal:Map<String, ResolvedIndexParameters> = [];
		if (input == null && extraInput == null) {
			this.indexedParams = retVal;
		}

		if (extraInput != null) {
			for (k => v in extraInput) {
				if (!indexedParams.exists(k))
					indexedParams.set(k, v);
			}
		}

		if (resolveExtraInput && extraInput != null) {
			for (key => value in extraInput) {
				if (retVal.exists(key))
					throw builderErrorAt(node, 'extra input "$key=>$value" already exists in input');
				if (Std.isOfType(value, ResolvedIndexParameters)) {
					retVal.set(key, value);
				} else if (Std.isOfType(value, ReferenceableValue)) {
					final ref:ReferenceableValue = cast value;
					final type = getDefsType(key, value);
					final resolved = resolveReferenceableValue(ref, type);
					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, resolved, s -> throw s));
				} else {
					final type = getDefsType(key, value);

					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, value, s -> throw s));
				}
			}
		}

		if (input != null)
			for (key => value in input) {
				if (Std.isOfType(value, ResolvedIndexParameters)) {
					retVal.set(key, value);
				} else if (Std.isOfType(value, ReferenceableValue)) {
					final ref:ReferenceableValue = value;
					final type = getDefsType(key, value);
					final resolved = resolveReferenceableValue(ref, type);
					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, resolved, s -> throw s));
				} else {
					final type = getDefsType(key, value);
					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, value, s -> throw s));
				}
			}
		for (key => value in definitions) {
			if (!retVal.exists(key) && value.defaultValue != null)
				retVal[key] = value.defaultValue;
		}

		this.indexedParams = retVal;
	}

	public function buildWithParameters(name:String, inputParameters:Map<String, Dynamic>, ?builderParams:BuilderParameters,
			?inheritedParameters:Map<String, ResolvedIndexParameters>, incremental:Bool = false):BuilderResult {
		pushBuilderState();
		if (builderParams == null)
			builderParams = {callback: defaultCallback};
		else if (builderParams.callback == null)
			builderParams.callback = defaultCallback;
		var node = multiParserResult.nodes.get(name);
		if (node == null) {
			final error = 'buildWithParameters ${inputParameters}: could find element "$name" to build';
			popBuilderState();
			throw error;
		}

		final hasParams = inputParameters != null && inputParameters.count() > 0;
		var definitions:ParametersDefinitions = getProgrammableParameterDefinitions(node, hasParams);

		updateIndexedParamsFromDynamicMap(node, inputParameters, definitions, inheritedParameters);
		this.builderParams = builderParams;

		// Enable incremental mode during build
		if (incremental) {
			this.incrementalMode = true;
			this.incrementalContext = new IncrementalUpdateContext(this, indexedParams, builderParams, node);
			// Auto-inject TweenManager for transition support
			if (tweenManager != null)
				this.incrementalContext.setTweenManager(tweenManager);
		}

		var retVal = startBuild(name, node, cast MultiAnimParser.getGridCoordinateSystem(node), cast MultiAnimParser.getHexCoordinateSystem(node), builderParams);

		if (incremental) {
			final ctx = this.incrementalContext;
			retVal.incrementalContext = ctx;
			if (ctx != null) {
				// @final constants at the programmable body scope survive the build and
				// must be persisted in the context so setParameter-triggered rebuilds can
				// re-resolve references like `$MY_CONST`. Nested @finals (inside point{},
				// repeatable, etc.) are already cleaned up by cleanupFinalVars and won't
				// appear in indexedParams here — so they're correctly excluded.
				ctx.syncFinalsFromBuilder(indexedParams);
				ctx.applyConditionalChains();
			}
			this.incrementalMode = false;
			this.incrementalContext = null;
		}

		#if MULTIANIM_DEV
		// Store builderParams and captured placeholders for hot reload
		retVal.devBuilderParams = builderParams;
		retVal.devCapturedPlaceholders = devPlaceholderCapture;
		devPlaceholderCapture = [];
		if (retVal.reloadable) {
			if (Std.isOfType(resourceLoader, bh.base.ResourceLoader.CachingResourceLoader)) {
				final cachingLoader = cast(resourceLoader, bh.base.ResourceLoader.CachingResourceLoader);
				if (cachingLoader.hotReloadRegistry != null) {
					retVal.reloadHandle = cachingLoader.hotReloadRegistry.register(sourceName, retVal, name);
				}
			}
		}
		#end

		popBuilderState();
		return retVal;
	}

	public function hasNode(name:String) {
		return multiParserResult.nodes?.get(name) != null;
	}

	/** Validate all custom filter references against registered FilterManager filters. */
	public function validateCustomFilters():Void {
		if (multiParserResult.customFilterRefs.length > 0) {
			bh.base.FilterManager.validateCustomFilters(multiParserResult.customFilterRefs);
		}
	}

	public function getParameterDefinitions(programmableName:String):ParametersDefinitions {
		final node = multiParserResult.nodes?.get(programmableName);
		if (node == null)
			return new Map();
		return getProgrammableParameterDefinitions(node);
	}

	/** Build a parameterized slot's children into its container with incremental mode.
	 *  Used by codegen (via ProgrammableBuilder) for parameterized slots. */
	public function buildSlotContent(programmableName:String, slotName:String,
			parentParams:Map<String, Dynamic>, container:h2d.Object):SlotHandle {
		final progNode = multiParserResult.nodes.get(programmableName);
		if (progNode == null)
			throw builderError('buildSlotContent: programmable "$programmableName" not found');
		final slotNode = findSlotNode(progNode, slotName);
		if (slotNode == null)
			throw builderError('buildSlotContent: slot "$slotName" not found in "$programmableName"');
		final slotParams = switch slotNode.type {
			case SLOT(params, _): params;
			default: null;
		};
		if (slotParams == null)
			throw builderError('buildSlotContent: slot "$slotName" has no parameters');

		// Capture parent context BEFORE pushBuilderState resets builderParams.
		// Slot children inherit the caller's callback/placeholderObjects and the
		// programmable's grid/hex coordinate systems (resolved via node parent chain).
		final parentBP = this.builderParams;
		final gridCS = MultiAnimParser.getGridCoordinateSystem(slotNode);
		final hexCS = MultiAnimParser.getHexCoordinateSystem(slotNode);
		pushBuilderState();

		// Build merged params: parent params converted to resolved + slot defaults
		final mergedParams:Map<String, ResolvedIndexParameters> = new Map();
		if (parentParams != null) {
			final progDefs = getProgrammableParameterDefinitions(progNode, false);
			for (key => value in parentParams) {
				final def = progDefs.get(key);
				if (def != null) {
					mergedParams.set(key, dynamicToResolvedWithDef(def.type, value));
				} else {
					mergedParams.set(key, dynamicToResolvedInferred(value));
				}
			}
		}
		// Merge slot parameter defaults
		for (key => def in slotParams) {
			if (def.defaultValue != null && !mergedParams.exists(key))
				mergedParams.set(key, def.defaultValue);
		}
		this.indexedParams = mergedParams;

		// Create incremental context for the slot
		final builderParams:BuilderParameters = {
			callback: (parentBP != null && parentBP.callback != null) ? parentBP.callback : defaultCallback,
			placeholderObjects: parentBP != null ? parentBP.placeholderObjects : null,
			scene: parentBP != null ? parentBP.scene : null,
		};
		this.builderParams = builderParams;
		final slotCtx = new IncrementalUpdateContext(this, mergedParams, builderParams, slotNode);
		this.incrementalMode = true;
		this.incrementalContext = slotCtx;

		// Build slot children into container
		final internalResults:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map(), htmlTextsWithLinks: []};
		for (childNode in resolveConditionalChildren(slotNode.children)) {
			build(childNode, ObjectMode(container), cast gridCS, cast hexCS, internalResults, builderParams);
		}

		popBuilderState();

		// Find slotContent child if present
		var slotContentTarget:Null<h2d.Object> = null;
		for (i in 0...container.numChildren) {
			if (Std.downcast(container.getChildAt(i), SlotContentRoot) != null) {
				slotContentTarget = container.getChildAt(i);
				break;
			}
		}
		return new SlotHandle(container, slotCtx, slotContentTarget);
	}

	private static function findSlotNode(node:Node, slotName:String):Null<Node> {
		for (child in node.children) {
			switch child.type {
				case SLOT(params, _) if (params != null):
					switch child.updatableName {
						case UNTObject(name) | UNTUpdatable(name) if (name == slotName):
							return child;
						case UNTIndexed(baseName, _) if (baseName == slotName):
							return child;
						case UNTIndexed2D(baseName, _, _) if (baseName == slotName):
							return child;
						default:
					}
				default:
					final found = findSlotNode(child, slotName);
					if (found != null) return found;
			}
		}
		return null;
	}

	private static function dynamicToResolvedWithDef(type:DefinitionType, value:Dynamic):ResolvedIndexParameters {
		return switch type {
			case PPTEnum(values):
				// Codegen passes enum index as Int — convert back to Index(idx, name)
				if (Std.isOfType(value, Int)) {
					final idx:Int = cast value;
					Index(idx, values[idx]);
				} else {
					// String value — look up index
					final s:String = cast value;
					Index(values.indexOf(s), s);
				}
			case PPTBool | PPTInt | PPTUnsignedInt | PPTRange(_, _) | PPTColor | PPTHexDirection | PPTGridDirection:
				Value(cast value);
			case PPTFloat:
				ValueF(cast value);
			case PPTString:
				StringValue(cast value);
			case PPTFlags(_):
				Flag(cast value);
			case PPTArray:
				ArrayString(cast value);
			case PPTTile:
				StringValue(Std.string(value));
		};
	}

	private static function dynamicToResolvedInferred(value:Dynamic):ResolvedIndexParameters {
		if (Std.isOfType(value, Int)) return Value(cast value);
		if (Std.isOfType(value, Float)) return ValueF(cast value);
		if (Std.isOfType(value, String)) return StringValue(cast value);
		return Value(cast value);
	}

	/** Rebuild a @switch arm into its container. Tears down the old arm and builds the new one.
	 *  Used by ProgrammableBuilder.rebuildSwitchArm for codegen lazy switch.
	 *  switchOrdinal is the N-th SWITCH node in DFS order of the programmable's tree.
	 *  When `sink` is provided, the arm's InternalBuilderResults are stored there instead of being
	 *  discarded — letting callers look up indexed names / slots / interactives declared inside arms.
	 *  On arm swap, the sink is cleaned up (removeRegistrationsUnder must run BEFORE removeChildren
	 *  so parent links are still intact). */
	function rebuildSwitchArmByOrdinal(programmableName:String, switchOrdinal:Int, armIndex:Int, container:h2d.Object,
			parentParams:Map<String, Dynamic>, ?sink:SwitchArmResults):Void {
		final progNode = multiParserResult.nodes.get(programmableName);
		if (progNode == null) throw builderError('programmable "$programmableName" not found');
		final switchNode = findNthSwitchNode(progNode, switchOrdinal);
		if (switchNode == null) throw builderError('switch node #$switchOrdinal not found in "$programmableName"');
		final arms = switch switchNode.type {
			case SWITCH(_, a): a;
			default: throw builderError('node #$switchOrdinal is not a SWITCH node');
		};
		// Drop registrations from the previous arm BEFORE removeChildren (needs intact parent chain).
		// Only IR collections are cleaned here — the arm build path runs with incrementalMode=false,
		// so there are no trackedExpressions or dynamicRefBindings to reap.
		if (sink != null)
			MultiAnimBuilder.removeRegistrationsUnder(sink.ir, container);
		container.removeChildren();
		if (armIndex >= 0 && armIndex < arms.length) {
			final arm = arms[armIndex];
			// Capture parent context BEFORE pushBuilderState resets builderParams.
			// Arm children inherit the caller's callback/placeholderObjects and the
			// programmable's grid/hex coordinate systems (resolved via node parent chain).
			final parentBP = this.builderParams;
			final gridCS = MultiAnimParser.getGridCoordinateSystem(switchNode);
			final hexCS = MultiAnimParser.getHexCoordinateSystem(switchNode);
			pushBuilderState();
			// Convert parent params to resolved index params
			final resolvedParams:Map<String, ResolvedIndexParameters> = new Map();
			final progDefs = getProgrammableParameterDefinitions(progNode, false);
			for (key => value in parentParams) {
				final def = progDefs.get(key);
				if (def != null)
					resolvedParams.set(key, dynamicToResolvedWithDef(def.type, value));
				else
					resolvedParams.set(key, dynamicToResolvedInferred(value));
			}
			this.indexedParams = resolvedParams;
			this.incrementalMode = false;
			this.incrementalContext = null;
			final bp:BuilderParameters = {
				callback: (parentBP != null && parentBP.callback != null) ? parentBP.callback : defaultCallback,
				placeholderObjects: parentBP != null ? parentBP.placeholderObjects : null,
				scene: parentBP != null ? parentBP.scene : null,
			};
			this.builderParams = bp;
			final ir:InternalBuilderResults = sink != null
				? sink.ir
				: {names: new Map(), interactives: [], slots: [], dynamicRefs: new Map(), htmlTextsWithLinks: []};
			for (child in arm.children)
				build(child, ObjectMode(container), cast gridCS, cast hexCS, ir, bp);
			popBuilderState();
		}
	}

	/** Find the N-th SWITCH node in DFS order within a node tree. */
	private static function findNthSwitchNode(node:Node, ordinal:Int):Null<Node> {
		var count = [0]; // boxed counter for recursion
		return findNthSwitchNodeImpl(node, ordinal, count);
	}

	private static function findNthSwitchNodeImpl(node:Node, ordinal:Int, count:Array<Int>):Null<Node> {
		switch node.type {
			case SWITCH(_, _):
				if (count[0] == ordinal) return node;
				count[0]++;
			default:
		}
		if (node.children != null) {
			for (child in node.children) {
				final found = findNthSwitchNodeImpl(child, ordinal, count);
				if (found != null) return found;
			}
		}
		return null;
	}

	/** Walk a subtree and mark `$param` refs inside incremental-unsupported slots (INTERACTIVE
	 *  id/metadata, STATEANIM / STATEANIM_CONSTRUCT selectors + animName/fps) as untracked on
	 *  the given context. Used when the main build walk runs with `incrementalMode=false` — e.g.
	 *  children of a param-dependent repeat — so `trackIncrementalExpressions` (the normal
	 *  caller of ctx.markParamUntracked) is skipped. Without this pass, setParameter on a param
	 *  that flows into an interactive id inside a param-dep repeat silently no-ops. `excludeVar`
	 *  is the repeat's loop-var name, which is never a user-settable parameter. */
	function markUntrackedParamsInSubtree(node:Null<Node>, ctx:IncrementalUpdateContext, excludeVar:Null<String>):Void {
		if (node == null || ctx == null) return;
		inline function markRefs(rv:ReferenceableValue, reason:String):Void {
			final refs:Array<String> = [];
			collectParamRefs(rv, refs);
			for (r in refs) if (r != excludeVar) ctx.markParamUntracked(r, reason);
		}
		switch node.type {
			case INTERACTIVE(_, _, id, _, metadata):
				markRefs(id, "interactive id");
				if (metadata != null) {
					for (entry in metadata) {
						markRefs(entry.key, "interactive metadata key");
						markRefs(entry.value, "interactive metadata value");
					}
				}
			case STATEANIM(_, _, selectorReferences):
				if (selectorReferences != null) {
					for (k => v in selectorReferences)
						markRefs(v, 'stateanim selector "$k"');
				}
			case STATEANIM_CONSTRUCT(_, construct, _):
				if (construct != null) {
					for (key => value in construct) {
						switch value {
							case IndexedSheet(_, animName, fps, _, _):
								markRefs(animName, 'stateanim_construct animName "$key"');
								markRefs(fps, 'stateanim_construct fps "$key"');
						}
					}
				}
			default:
		}
		if (node.children != null) {
			for (child in node.children)
				markUntrackedParamsInSubtree(child, ctx, excludeVar);
		}
	}

	/** Build a single node in isolation, returning the resulting h2d.Object.
	 *  Used by ProgrammableBuilder.buildNodeByUniqueName for forwarding unsupported
	 *  repeatable node types to the builder at runtime. */
	function buildSingleNode(node:Node):Null<h2d.Object> {
		final parent = new h2d.Object();
		final ir:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map(), htmlTextsWithLinks: []};
		build(node, ObjectMode(parent), cast null, cast null, ir, builderParams);
		return if (parent.numChildren > 0) parent.getChildAt(0) else null;
	}

	/** Build a single node with an explicit parent params map. Mirrors rebuildSwitchArmByOrdinal's
	 *  state setup so `$param` and loop-var refs inside the subtree resolve correctly. Used by the
	 *  codegen runtime-rebuild fallback in param-dependent repeatable bodies (INTERACTIVE, SLOT,
	 *  SWITCH, nested REPEAT, etc. — any kind that generateRuntimeChildExprs can't handle inline).
	 *
	 *  progNode carries the parameter type definitions; parentParams supplies the runtime values
	 *  (programmable params + current loop-var iteration). */
	public function buildSingleNodeWithParams(node:Node, progNode:Node, parentParams:Map<String, Dynamic>):Null<h2d.Object> {
		final parentBP = this.builderParams;
		final gridCS = MultiAnimParser.getGridCoordinateSystem(node);
		final hexCS = MultiAnimParser.getHexCoordinateSystem(node);
		pushBuilderState();
		final resolvedParams:Map<String, ResolvedIndexParameters> = new Map();
		final progDefs = getProgrammableParameterDefinitions(progNode, false);
		for (key => value in parentParams) {
			final def = progDefs.get(key);
			if (def != null)
				resolvedParams.set(key, dynamicToResolvedWithDef(def.type, value));
			else
				resolvedParams.set(key, dynamicToResolvedInferred(value));
		}
		this.indexedParams = resolvedParams;
		this.incrementalMode = false;
		this.incrementalContext = null;
		final bp:BuilderParameters = {
			callback: (parentBP != null && parentBP.callback != null) ? parentBP.callback : defaultCallback,
			placeholderObjects: parentBP != null ? parentBP.placeholderObjects : null,
			scene: parentBP != null ? parentBP.scene : null,
		};
		this.builderParams = bp;
		final parent = new h2d.Object();
		final ir:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map(), htmlTextsWithLinks: []};
		build(node, ObjectMode(parent), cast gridCS, cast hexCS, ir, bp);
		popBuilderState();
		return if (parent.numChildren > 0) parent.getChildAt(0) else null;
	}

	function loadTileImpl(sheetName:String, tilename:String, ?index:Int) {
		final sheet = getOrLoadSheet(sheetName);
		if (sheet == null)
			throw builderError('sheet ${sheetName} could not be loaded');

		final tile = if (index != null) {
			final arr = sheet.getAnim(tilename);
			if (arr == null)
				throw builderError('tile ${tilename}, index $index sheet ${sheetName} could not be loaded');
			if (index < 0 || index >= arr.length)
				throw builderError('tile $tilename from sheet $sheetName does not have tile index $index, should be [0, ${arr.length - 1}]');
			arr[index];
		} else {
			final t = sheet.get(tilename);
			if (t == null)
				throw builderError('tile ${tilename} in sheet ${sheetName} could not be loaded');
			t;
		}

		return tile;
	}

	function load9Patch(sheet, tilename) {
		final sheet = getOrLoadSheet(sheet);
		if (sheet == null)
			throw builderError('sheet ${sheet} could not be loaded');

		final ninePatch = sheet.getNinePatch(tilename);
		if (ninePatch == null)
			throw builderError('tile ${tilename} in sheet ${sheet} could not be loaded');
		return ninePatch;
	}

	function getOrLoadSheet(sheetName:String):IAtlas2 {
		// Check inline atlas2 definitions first
		var inlineAtlas = inlineAtlases.get(sheetName);
		if (inlineAtlas != null)
			return inlineAtlas;

		// Try to resolve from parsed ATLAS2 node
		inlineAtlas = resolveInlineAtlas(sheetName);
		if (inlineAtlas != null)
			return inlineAtlas;

		// Fall back to resource loader
		return resourceLoader.loadSheet2(sheetName);
	}

	function resolveInlineAtlas(name:String):Null<IAtlas2> {
		final node = multiParserResult.nodes.get(name);
		if (node == null) return null;

		switch node.type {
			case ATLAS2(atlas2Def):
				// Load source tile
				final sourceTile:h2d.Tile = switch atlas2Def.source {
					case A2SFile(filename):
						resourceLoader.loadTile(resolveAsString(filename));
					case A2SSheet(sheetName):
						final sheet = resourceLoader.loadSheet2(resolveAsString(sheetName));
						if (sheet == null)
							throw builderError('atlas2: could not load sheet "${resolveAsString(sheetName)}"');
						sheet.getSourceTile();
				}

				if (sourceTile == null)
					throw builderError('atlas2 "$name": could not load source tile');

				// Build contents map from entries
				final contents:Map<String, Array<AtlasEntry>> = [];
				for (entry in atlas2Def.entries) {
					final t = sourceTile.sub(entry.x, entry.y, entry.w, entry.h, 0, 0);
					final _idx = entry.index; final idx:Int = _idx != null ? _idx : 0;
					final _ox = entry.offsetX; final offsetX:Int = _ox != null ? _ox : 0;
					final _oy = entry.offsetY; final offsetY:Int = _oy != null ? _oy : 0;
					final _ow = entry.origW; final origW:Int = _ow != null ? _ow : entry.w;
					final _oh = entry.origH; final origH:Int = _oh != null ? _oh : entry.h;
					final _sp = entry.split; final split:Array<Int> = _sp != null ? _sp : [];

					var tl = contents.get(entry.name);
					if (tl == null) {
						tl = [];
						contents.set(entry.name, tl);
					}
					tl[idx] = { t: t, width: origW, height: origH, offsetX: offsetX, offsetY: offsetY, split: split };
				}

				// Remove leading null if index started at 1
				for (tl in contents)
					if (tl.length > 1 && tl[0] == null) tl.shift();

				final inlineAtlas = new InlineAtlas2(contents);
				inlineAtlases.set(name, inlineAtlas);
				return inlineAtlas;
			default:
				return null;
		}
	}
}
