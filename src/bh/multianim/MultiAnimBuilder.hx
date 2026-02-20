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
import bh.base.MAObject;
import bh.multianim.CoordinateSystems;
import bh.base.Hex.OffsetCoord;
import bh.base.Hex.DoubledCoord;
import bh.base.PixelLine;
import h2d.Object;
import bh.multianim.MultiAnimParser;
import bh.base.ResourceLoader;
import bh.base.Particles.ForceField;
import bh.base.Particles.BoundsMode;
import bh.base.Particles.SubEmitTrigger;
import bh.base.MacroUtils;
import bh.base.Atlas2.IAtlas2;
import bh.base.Atlas2.InlineAtlas2;
import bh.base.Atlas2.AtlasEntry;

using bh.base.MapTools;
using StringTools;
using bh.base.ColorUtils;

// Place this after imports, before any class definitions
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
			throw 'empty updatable';
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
						throw 'invalid updateText: expected HeapsText but got ${v.object}';
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
						throw 'invalid updateTile: expected HeapsBitmap but got ${v.object}';
			}
		}
	}

	public function setObject(newObject:h2d.Object) {
		if (updatables.length != 1)
			throw 'setObject needs exactly one updatable';
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
			throw 'addObject needs exactly one updatable';

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

class BuilderResolvedSettings {
	var settings:ResolvedSettings;

	public function new(settings) {
		this.settings = settings;
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
			case RSVFloat(f): '$f';
			case RSVBool(b): b ? "true" : "false";
		};
	}

	public function getStringOrException(settingName:String):String {
		if (settings == null)
			throw 'settings not found, was looking for $settingName';
		final r = settings[settingName];
		if (r == null)
			throw 'expected string setting ${settingName} to present but was not';
		return switch r {
			case RSVString(s): s;
			case RSVInt(i): '$i';
			case RSVFloat(f): '$f';
			case RSVBool(b): b ? "true" : "false";
		};
	}

	public function getIntOrException(settingName:String):Int {
		if (settings == null)
			throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null)
			throw 'expected int setting ${settingName} to present but was not';
		return switch r {
			case RSVInt(i): i;
			case RSVFloat(f): throw 'expected int setting ${settingName} to valid int number but was float $f';
			case RSVString(s): throw 'expected int setting ${settingName} to valid int number but was string $s';
			case RSVBool(b): b ? 1 : 0;
		};
	}

	public function getIntOrDefault(settingName:String, defaultValue:Int):Int {
		if (settings == null)
			throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null)
			return defaultValue;
		return switch r {
			case RSVInt(i): i;
			case RSVFloat(f): throw 'expected int setting ${settingName} to valid int number but was float $f';
			case RSVString(s): throw 'expected int setting ${settingName} to valid int number but was string $s';
			case RSVBool(b): b ? 1 : 0;
		};
	}

	public function getFloatOrException(settingName:String):Float {
		if (settings == null)
			throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null)
			throw 'expected float setting ${settingName} to present but was not';
		return switch r {
			case RSVFloat(f): f;
			case RSVInt(i): cast i;
			case RSVString(s): throw 'expected float setting ${settingName} to valid float number but was string $s';
			case RSVBool(b): b ? 1.0 : 0.0;
		};
	}

	public function getFloatOrDefault(settingName:String, defaultValue:Float):Float {
		if (settings == null)
			throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null)
			return defaultValue;
		return switch r {
			case RSVFloat(f): f;
			case RSVInt(i): cast i;
			case RSVString(s): throw 'expected float setting ${settingName} to valid float number but was string $s';
			case RSVBool(b): b ? 1.0 : 0.0;
		};
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
			case RSVFloat(f): f != 0;
			case RSVString(s):
				switch (s.toLowerCase()) {
					case "true" | "1" | "yes": true;
					case "false" | "0" | "no": false;
					default: throw 'could not parse setting "$s" as bool';
				};
		};
	}
}

class IncrementalUpdateContext {
	var builder:MultiAnimBuilder;
	var indexedParams:Map<String, ResolvedIndexParameters>;
	var builderParams:BuilderParameters;
	var conditionalEntries:Array<{object:h2d.Object, node:Node}> = [];
	var conditionalApplyEntries:Array<{
		parent:h2d.Object, node:Node, applied:Bool,
		savedFilter:Null<h2d.filter.Filter>, savedAlpha:Null<Float>,
		savedScaleX:Null<Float>, savedScaleY:Null<Float>,
		appliedPosX:Float, appliedPosY:Float,
	}> = [];
	var trackedExpressions:Array<{updateFn:Void->Void, paramRefs:Array<String>}> = [];
	var dynamicRefBindings:Array<{childContext:IncrementalUpdateContext, childParam:String, resolveFn:Void->Dynamic, referencedParams:Array<String>}> = [];
	var rootNode:Node;
	var batchMode:Bool = false;
	var changedParams:Map<String, Bool> = new Map();

	public function new(builder:MultiAnimBuilder, indexedParams:Map<String, ResolvedIndexParameters>,
			builderParams:BuilderParameters, rootNode:Node) {
		this.builder = builder;
		// Deep copy indexed params so they persist independently
		this.indexedParams = new Map();
		for (k => v in indexedParams)
			this.indexedParams.set(k, v);
		this.builderParams = builderParams;
		this.rootNode = rootNode;
	}

	public function trackConditional(object:h2d.Object, node:Node):Void {
		conditionalEntries.push({object: object, node: node});
	}

	public function trackExpression(updateFn:Void->Void, paramRefs:Array<String>):Void {
		trackedExpressions.push({updateFn: updateFn, paramRefs: paramRefs});
	}

	public function trackDynamicRef(childContext:IncrementalUpdateContext, childParam:String, resolveFn:Void->Dynamic, referencedParams:Array<String>):Void {
		dynamicRefBindings.push({childContext: childContext, childParam: childParam, resolveFn: resolveFn, referencedParams: referencedParams});
	}

	public function trackConditionalApply(parent:h2d.Object, node:Node, applied:Bool,
			savedFilter:Null<h2d.filter.Filter>, savedAlpha:Null<Float>,
			savedScaleX:Null<Float>, savedScaleY:Null<Float>,
			appliedPosX:Float, appliedPosY:Float):Void {
		conditionalApplyEntries.push({
			parent: parent, node: node, applied: applied,
			savedFilter: savedFilter, savedAlpha: savedAlpha,
			savedScaleX: savedScaleX, savedScaleY: savedScaleY,
			appliedPosX: appliedPosX, appliedPosY: appliedPosY,
		});
	}

	function applyConditionalApplyEntry(entry:{
		parent:h2d.Object, node:Node, applied:Bool,
		savedFilter:Null<h2d.filter.Filter>, savedAlpha:Null<Float>,
		savedScaleX:Null<Float>, savedScaleY:Null<Float>,
		appliedPosX:Float, appliedPosY:Float,
	}):Void {
		if (entry.applied) return;
		final parent = entry.parent;
		final node = entry.node;
		// Save current state before applying
		if (node.filter != null) entry.savedFilter = parent.filter;
		if (node.alpha != null) entry.savedAlpha = parent.alpha;
		if (node.scale != null) { entry.savedScaleX = parent.scaleX; entry.savedScaleY = parent.scaleY; }
		// Apply position
		final pos = builder.calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
		entry.appliedPosX = pos.x;
		entry.appliedPosY = pos.y;
		builder.addPosition(parent, pos.x, pos.y);
		// Apply properties
		builder.applyExtendedFormProperties(parent, node);
		entry.applied = true;
	}

	function unapplyConditionalApplyEntry(entry:{
		parent:h2d.Object, node:Node, applied:Bool,
		savedFilter:Null<h2d.filter.Filter>, savedAlpha:Null<Float>,
		savedScaleX:Null<Float>, savedScaleY:Null<Float>,
		appliedPosX:Float, appliedPosY:Float,
	}):Void {
		if (!entry.applied) return;
		final parent = entry.parent;
		final node = entry.node;
		// Restore saved state
		if (node.filter != null) parent.filter = entry.savedFilter;
		if (node.alpha != null && entry.savedAlpha != null) parent.alpha = entry.savedAlpha;
		if (node.scale != null && entry.savedScaleX != null && entry.savedScaleY != null) {
			parent.scaleX = entry.savedScaleX;
			parent.scaleY = entry.savedScaleY;
		}
		// Remove position offset
		parent.x -= entry.appliedPosX;
		parent.y -= entry.appliedPosY;
		entry.applied = false;
	}

	public function setParameter(name:String, value:Dynamic):Void {
		// Convert to ResolvedIndexParameters — preserve float precision for float values
		if (Std.isOfType(value, Int)) {
			indexedParams.set(name, Value(value));
		} else if (Std.isOfType(value, Float)) {
			indexedParams.set(name, ValueF(value));
		} else if (Std.isOfType(value, String)) {
			indexedParams.set(name, StringValue(cast value));
		} else if (Std.isOfType(value, Bool)) {
			indexedParams.set(name, Value(cast(value, Bool) ? 1 : 0));
		}
		changedParams.set(name, true);
		if (!batchMode)
			applyUpdates();
	}

	public function beginUpdate():Void {
		batchMode = true;
		changedParams = new Map();
	}

	public function endUpdate():Void {
		batchMode = false;
		if (Lambda.count(changedParams) > 0)
			applyUpdates();
		changedParams = new Map();
	}

	function applyUpdates():Void {
		builder.pushBuilderState();
		builder.indexedParams = indexedParams;
		builder.builderParams = builderParams;

		// Re-evaluate visibility for all conditional elements
		for (entry in conditionalEntries) {
			entry.object.visible = builder.isMatch(entry.node, indexedParams);
		}
		// Re-evaluate conditional apply entries
		for (entry in conditionalApplyEntries) {
			final shouldApply = builder.isMatch(entry.node, indexedParams);
			if (shouldApply) applyConditionalApplyEntry(entry);
			else unapplyConditionalApplyEntry(entry);
		}
		// Re-evaluate @else/@default chain visibility
		applyConditionalChains();

		// Re-evaluate tracked expressions
		for (tracked in trackedExpressions) {
			var relevant = false;
			for (ref in tracked.paramRefs) {
				if (changedParams.exists(ref)) {
					relevant = true;
					break;
				}
			}
			if (relevant || Lambda.count(changedParams) == 0) {
				tracked.updateFn();
			}
		}

		// Propagate to dynamic ref children
		for (binding in dynamicRefBindings) {
			var relevant = false;
			for (ref in binding.referencedParams) {
				if (changedParams.exists(ref)) {
					relevant = true;
					break;
				}
			}
			if (relevant) {
				binding.childContext.setParameter(binding.childParam, binding.resolveFn());
			}
		}

		builder.popBuilderState();
		changedParams = new Map();
	}

	public function applyConditionalChains():Void {
		// Walk the root node's children to resolve @else/@default chains with new params
		if (rootNode.children == null) return;
		resolveVisibilityForChildren(rootNode.children);
	}

	function resolveVisibilityForChildren(children:Array<Node>):Void {
		var prevSiblingMatched = false;
		var anyConditionalSiblingMatched = false;

		for (childNode in children) {
			// Find the tracked object for this node
			var trackedObj:Null<h2d.Object> = null;
			for (entry in conditionalEntries) {
				if (entry.node == childNode) {
					trackedObj = entry.object;
					break;
				}
			}
			// Find conditional apply entry for this node (APPLY nodes have no tracked object)
			var trackedApply:Null<{
				parent:h2d.Object, node:Node, applied:Bool,
				savedFilter:Null<h2d.filter.Filter>, savedAlpha:Null<Float>,
				savedScaleX:Null<Float>, savedScaleY:Null<Float>,
				appliedPosX:Float, appliedPosY:Float,
			}> = null;
			if (trackedObj == null) {
				for (ae in conditionalApplyEntries) {
					if (ae.node == childNode) {
						trackedApply = ae;
						break;
					}
				}
			}

			switch childNode.conditionals {
				case Conditional(conditions, strict):
					var matched = builder.matchConditions(conditions, strict, indexedParams);
					prevSiblingMatched = matched;
					if (matched) anyConditionalSiblingMatched = true;
					if (trackedObj != null) trackedObj.visible = matched;
					if (trackedApply != null) {
						if (matched) applyConditionalApplyEntry(trackedApply);
						else unapplyConditionalApplyEntry(trackedApply);
					}

				case ConditionalElse(extraConditions):
					if (!prevSiblingMatched) {
						if (extraConditions == null) {
							prevSiblingMatched = true;
							anyConditionalSiblingMatched = true;
							if (trackedObj != null) trackedObj.visible = true;
							if (trackedApply != null) applyConditionalApplyEntry(trackedApply);
						} else {
							var matched = builder.matchConditions(extraConditions, false, indexedParams);
							prevSiblingMatched = matched;
							if (matched) anyConditionalSiblingMatched = true;
							if (trackedObj != null) trackedObj.visible = matched;
							if (trackedApply != null) {
								if (matched) applyConditionalApplyEntry(trackedApply);
								else unapplyConditionalApplyEntry(trackedApply);
							}
						}
					} else {
						prevSiblingMatched = true;
						if (trackedObj != null) trackedObj.visible = false;
						if (trackedApply != null) unapplyConditionalApplyEntry(trackedApply);
					}

				case ConditionalDefault:
					if (trackedObj != null) trackedObj.visible = !anyConditionalSiblingMatched;
					if (trackedApply != null) {
						if (!anyConditionalSiblingMatched) applyConditionalApplyEntry(trackedApply);
						else unapplyConditionalApplyEntry(trackedApply);
					}
					anyConditionalSiblingMatched = false;

				case NoConditional:
					prevSiblingMatched = false;
					anyConditionalSiblingMatched = false;
			}

			// Recurse into children
			if (childNode.children != null && childNode.children.length > 0)
				resolveVisibilityForChildren(childNode.children);
		}
	}
}

class SlotContentRoot extends h2d.Object {}

enum SlotKey {
	Named(name:String);
	Indexed(name:String, index:Int);
	Indexed2D(name:String, indexX:Int, indexY:Int);
}

class SlotHandle {
	public var container:h2d.Object;
	public var data:Dynamic = null;
	public var incrementalContext:Null<IncrementalUpdateContext> = null;

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
		} else if (hasParameters) {
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
			} else if (hasParameters) {
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
		if (incrementalContext == null)
			throw 'Slot has no parameters';
		incrementalContext.setParameter(name, value);
	}
}

@:nullSafety
@:structInit
class BuilderResult {
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

	public function setParameter(name:String, value:Dynamic):Void {
		if (incrementalContext == null)
			throw 'setParameter requires incremental mode — pass incremental:true to buildWithParameters';
		incrementalContext.setParameter(name, value);
	}

	public function beginUpdate():Void {
		if (incrementalContext == null)
			throw 'beginUpdate requires incremental mode';
		incrementalContext.beginUpdate();
	}

	public function endUpdate():Void {
		if (incrementalContext == null)
			throw 'endUpdate requires incremental mode';
		incrementalContext.endUpdate();
	}

	public function getNodeSettings(elementName:String):ResolvedSettings {
		final results = names[name];
		if (results == null || results.length != 1)
			throw 'Could not get single node for name $name';
		final settings = results[0].settings;
		if (settings == null)
			throw 'no settings specified for $name';
		return settings;
	}

	public function getSingleItemByName(name:String):NamedBuildResult {
		var items = this.names[name];
		if (items == null)
			throw 'builder result name ${name} not found';
		if (items.length != 1)
			throw 'builder result name ${name} expected single item but got ${items.length}';
		return items[0];
	}

	public function getUpdatable(name) {
		final namesArray = names[name];
		if (namesArray == null)
			throw 'Name ${name} not found in BuilderResult';
		return new Updatable(namesArray);
	}

	public function getUpdatableByIndex(name:String, index:Int):Updatable {
		return getUpdatable('${name}_${index}');
	}

	public function getDynamicRef(name:String):BuilderResult {
		if (dynamicRefs == null)
			throw 'No dynamicRefs in BuilderResult';
		final ref = dynamicRefs.get(name);
		if (ref == null)
			throw 'DynamicRef "$name" not found in BuilderResult';
		return ref;
	}

	public function getSlot(name:String, ?index:Null<Int>, ?indexY:Null<Int>):SlotHandle {
		if (slots == null)
			throw 'No slots in BuilderResult';
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
				throw 'Slot "$name" is 2D-indexed — use getSlot("$name", x, y)';
			for (entry in slots) {
				switch entry.key {
					case Indexed2D(n, ix, iy) if (n == name && ix == index && iy == indexY):
						return entry.handle;
					default:
				}
			}
			throw 'Slot "$name" index ($index, $indexY) not found';
		} else if (is1DIndexed) {
			if (index == null)
				throw 'Slot "$name" is indexed — use getSlot("$name", index)';
			for (entry in slots) {
				switch entry.key {
					case Indexed(n, i) if (n == name && i == index):
						return entry.handle;
					default:
				}
			}
			throw 'Slot "$name" index $index not found';
		} else {
			if (index != null)
				throw 'Slot "$name" is not indexed — use getSlot("$name") without index';
			for (entry in slots) {
				switch entry.key {
					case Named(n) if (n == name):
						return entry.handle;
					default:
				}
			}
			throw 'Slot "$name" not found in BuilderResult';
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

enum CallbackResult {
	CBRInteger(val:Int);
	CBRFloat(val:Float);
	CBRString(val:String);
	CBRObject(val:h2d.Object);
	CBRNoResult; // for default behaviors, e.g. for example of PLACEHOLDER
}

enum PlaceholderValues {
	PVObject(obj:h2d.Object);
	PVFactory(factoryMethod:ResolvedSettings->h2d.Object);
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
	dynamicRefs:Map<String, BuilderResult>
}

@:nullSafety
private typedef StoredBuilderState = {
	indexedParams:Map<String, ResolvedIndexParameters>,
	builderParams:BuilderParameters,
	currentNode:Null<Node>,
	incrementalMode:Bool,
	incrementalContext:Null<IncrementalUpdateContext>,
}

// @:nullSafety

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

	var indexedParams:Map<String, ResolvedIndexParameters> = [];
	var builderParams:BuilderParameters = {};
	var currentNode:Null<Node> = null;
	var stateStack:Array<StoredBuilderState> = [];
	var inlineAtlases:Map<String, IAtlas2> = [];
	var incrementalMode:Bool = false;
	var incrementalContext:Null<IncrementalUpdateContext> = null;

	/** Returns position string for error messages when MULTIANIM_TRACE is enabled */
	inline function currentNodePos():String {
		#if MULTIANIM_TRACE
		return if (currentNode != null) ' at ${currentNode.parserPos}' else '';
		#else
		return '';
		#end
	}

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
			throw 'builder state stack is empty, sourceName: ${sourceName}';

		this.indexedParams = state.indexedParams;
		this.builderParams = state.builderParams;
		this.currentNode = state.currentNode;
		this.incrementalMode = state.incrementalMode;
		this.incrementalContext = state.incrementalContext;
	}

	function pushBuilderState() {
		stateStack.push({
			indexedParams: this.indexedParams,
			builderParams: this.builderParams,
			currentNode: this.currentNode,
			incrementalMode: this.incrementalMode,
			incrementalContext: this.incrementalContext,
		});
		this.indexedParams = [];
		this.builderParams = {};
		this.currentNode = null;
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
					throw '@final: \'$name\' shadows an existing parameter' + MacroUtils.nodePos(node);
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
							throw 'index out of bounds ${index} for array ${arrayVal.toString()}' + currentNodePos();
						return arrayVal[index];
					case null: throw 'array reference ${arrayRef}[$indexRef] does not exist' + currentNodePos();
					default: throw 'element of array reference ${arrayRef}[$indexRef] is not an array but ${arrayRef}' + currentNodePos();
				}
				case RVTernary(condition, ifTrue, ifFalse):
					return if (resolveAsBool(condition)) resolveAsArrayElement(ifTrue) else resolveAsArrayElement(ifFalse);
			default:
				throw 'expected array element but got ${v}' + currentNodePos();
		}
	}

	function resolveAsArray(v:ReferenceableValue):Dynamic {
		switch v {
			case RVArray(array):
				return [for (v in array) resolveAsString(v)];
			case RVArrayReference(refArr):
				final arrayVal = indexedParams.get(refArr);
				#if MULTIANIM_TRACE
				trace(indexedParams);
				#end
				switch arrayVal {
					case ArrayString(strArray): return strArray;
					case ExpressionAlias(expr): return resolveAsArray(expr);
					default: throw 'array reference ${refArr} is not an array but ${arrayVal}' + currentNodePos();
				}
			case RVTernary(condition, ifTrue, ifFalse):
				return if (resolveAsBool(condition)) resolveAsArray(ifTrue) else resolveAsArray(ifFalse);
			default:
				throw 'expected array but got ${v}' + currentNodePos();
		}
	}

	function collectStateAnimFrames(animFilename:String, animationName:String, selector:Map<String, String>):Array<TileSource> {
		final animParser = resourceLoader.loadAnimParser(animFilename);
		final animSM = animParser.createAnimSM(selector);
		final descriptor = animSM.animationStates.get(animationName);
		if (descriptor == null) {
			throw 'animation "${animationName}" not found in "${animFilename}"' + currentNodePos();
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
		function getBuilderWithExternal(externalReference:String) {
			if (externalReference == null)
				return this;
			var builder = multiParserResult?.imports?.get(externalReference);
			if (builder == null)
				throw 'could not find builder for external reference ${externalReference}' + currentNodePos();
			return builder;
		}

		return switch v {
			case RVInteger(i): i;
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

			default: throw 'expected color to resolve, got $v' + currentNodePos();
		}
	}

	function resolveRVPropertyAccess(ref:String, property:String):Float {
		switch (ref) {
			case "ctx":
				switch (property) {
					case "width":
						if (builderParams.scene == null) throw '$$ctx.width requires scene in BuilderParameters' + currentNodePos();
						return builderParams.scene.width;
					case "height":
						if (builderParams.scene == null) throw '$$ctx.height requires scene in BuilderParameters' + currentNodePos();
						return builderParams.scene.height;
					default: throw '$ref.$property is not a known context property' + currentNodePos();
				}
			case "grid" | "ctx.grid":
				final gcs = if (ref == "ctx.grid") MultiAnimParser.getGridCoordinateSystem(currentNode) else MultiAnimParser.getGridCoordinateSystem(currentNode);
				if (gcs == null) throw 'no grid coordinate system in scope for $ref.$property' + currentNodePos();
				switch (property) {
					case "width": return gcs.spacingX;
					case "height": return gcs.spacingY;
					default: throw '$ref.$property is not a known grid property' + currentNodePos();
				}
			case "hex" | "ctx.hex":
				final hcs = MultiAnimParser.getHexCoordinateSystem(currentNode);
				if (hcs == null) throw 'no hex coordinate system in scope for $ref.$property' + currentNodePos();
				switch (property) {
					case "width": return hcs.hexLayout.size.x;
					case "height": return hcs.hexLayout.size.y;
					default: throw '$ref.$property is not a known hex property' + currentNodePos();
				}
			default:
				// Check named coordinate systems
				final namedCS = MultiAnimParser.getNamedCoordinateSystem(ref, currentNode);
				if (namedCS != null) {
					switch (namedCS) {
						case NamedGrid(system):
							switch (property) {
								case "width": return system.spacingX;
								case "height": return system.spacingY;
								default: throw '$ref.$property is not a known grid property' + currentNodePos();
							}
						case NamedHex(system):
							switch (property) {
								case "width": return system.hexLayout.size.x;
								case "height": return system.hexLayout.size.y;
								default: throw '$ref.$property is not a known hex property' + currentNodePos();
							}
					}
				}
				throw 'unknown reference $ref for property access .$property' + currentNodePos();
		}
	}

	function resolveRVMethodCall(ref:String, method:String, args:Array<ReferenceableValue>):Float {
		switch (ref) {
			case "ctx":
				switch (method) {
					case "random":
						if (args.length != 2) throw '$ref.$method() requires 2 arguments (min, max)' + currentNodePos();
						final min = resolveAsInteger(args[0]);
						final max = resolveAsInteger(args[1]);
						return min + Std.random(max - min);
					case "font":
						throw '$$ctx.font() must be followed by .lineHeight or .baseLine' + currentNodePos();
					default: throw '$ref.$method() is not a known context method' + currentNodePos();
				}
			default:
				throw 'unknown reference $ref for method call .$method()' + currentNodePos();
		}
	}

	/** Resolves a coordinate method call ($hex.corner(), $hex.edge(), $hex.cube(), $grid.pos(), etc.) to an FPoint. */
	function resolveRVMethodCallToPoint(ref:String, method:String, args:Array<ReferenceableValue>):FPoint {
		final namedCS = if (ref != "grid" && ref != "ctx.grid" && ref != "hex" && ref != "ctx.hex") MultiAnimParser.getNamedCoordinateSystem(ref, currentNode) else null;
		final isNamedGrid = switch (namedCS) { case NamedGrid(_): true; default: false; };
		// Grid methods
		if (ref == "grid" || ref == "ctx.grid" || isNamedGrid) {
			final gcs = if (ref == "grid" || ref == "ctx.grid") {
				MultiAnimParser.getGridCoordinateSystem(currentNode);
			} else {
				switch (namedCS) {
					case NamedGrid(system): system;
					default: null;
				}
			};
			if (gcs == null) throw 'no grid coordinate system in scope for $$$ref.$method()' + currentNodePos();
			switch (method) {
				case "pos":
					if (args.length < 2) throw '$$$ref.pos() requires at least 2 arguments (x, y)' + currentNodePos();
					final x = resolveAsInteger(args[0]);
					final y = resolveAsInteger(args[1]);
					if (args.length >= 4) {
						final ox = resolveAsInteger(args[2]);
						final oy = resolveAsInteger(args[3]);
						return gcs.resolveAsGrid(x, y, ox, oy);
					}
					return gcs.resolveAsGrid(x, y);
				default: throw '$$$ref.$method() is not a known grid method' + currentNodePos();
			}
		}

		// Hex methods
		final hcs = if (ref == "hex" || ref == "ctx.hex") {
			MultiAnimParser.getHexCoordinateSystem(currentNode);
		} else {
			switch (namedCS) {
				case NamedHex(system): system;
				default: null;
			}
		};
		if (hcs == null) throw 'no hex coordinate system in scope for $$$ref.$method()' + currentNodePos();

		switch (method) {
			case "corner":
				if (args.length < 1) throw '$$$ref.corner() requires at least 1 argument (index)' + currentNodePos();
				final idx = resolveAsInteger(args[0]);
				final factor = if (args.length >= 2) resolveAsNumber(args[1]) else 1.0;
				return hcs.resolveAsHexCorner(idx, factor);
			case "edge":
				if (args.length < 1) throw '$$$ref.edge() requires at least 1 argument (direction)' + currentNodePos();
				final dir = resolveAsInteger(args[0]);
				final factor = if (args.length >= 2) resolveAsNumber(args[1]) else 1.0;
				return hcs.resolveAsHexEdge(dir, factor);
			case "cube":
				if (args.length != 3) throw '$$$ref.cube() requires 3 arguments (q, r, s)' + currentNodePos();
				return hcs.resolveHexCube(resolveAsNumber(args[0]), resolveAsNumber(args[1]), resolveAsNumber(args[2]));
			case "offset":
				if (args.length < 2) throw '$$$ref.offset() requires at least 2 arguments (col, row)' + currentNodePos();
				final parity:OffsetParity = if (args.length >= 3) {
					final p = resolveAsString(args[2]);
					switch (p) { case "even": EVEN; case "odd": ODD; default: throw 'Expected "even" or "odd", got: $p' + currentNodePos(); }
				} else EVEN;
				return hcs.resolveHexOffset(resolveAsInteger(args[0]), resolveAsInteger(args[1]), parity);
			case "doubled":
				if (args.length != 2) throw '$$$ref.doubled() requires 2 arguments (col, row)' + currentNodePos();
				return hcs.resolveHexDoubled(resolveAsInteger(args[0]), resolveAsInteger(args[1]));
			case "pixel":
				if (args.length != 2) throw '$$$ref.pixel() requires 2 arguments (x, y)' + currentNodePos();
				return hcs.resolveHexPixel(resolveAsNumber(args[0]), resolveAsNumber(args[1]));
			default: throw '$$$ref.$method() is not a known hex method' + currentNodePos();
		}
	}

	/** Resolves RVChainedMethodCall for .x/.y extraction from coordinate methods and font property access. */
	function resolveRVChainedMethodCall(base:ReferenceableValue, property:String):Float {
		// Font property access: $ctx.font("name").lineHeight / .baseLine
		if (property == "lineHeight" || property == "baseLine") {
			switch (base) {
				case RVMethodCall(ref, method, args):
					if (ref == "ctx" && method == "font") {
						if (args.length != 1) throw '$$ctx.font() requires 1 argument (font name)' + currentNodePos();
						final fontName = resolveAsString(args[0]);
						final font = resourceLoader.loadFont(fontName);
						return if (property == "lineHeight") font.lineHeight else font.baseLine;
					}
				default:
			}
			throw 'unsupported base expression for .$property — use $$ctx.font("name").$property' + currentNodePos();
		}

		if (property != "x" && property != "y")
			throw 'unsupported chained property .$property — only .x, .y, .lineHeight, .baseLine are supported' + currentNodePos();

		switch (base) {
			case RVMethodCall(ref, method, args):
				final pt = resolveRVMethodCallToPoint(ref, method, args);
				return if (property == "x") pt.x else pt.y;
			default:
				throw 'unsupported base expression for .$property extraction' + currentNodePos();
		}
	}

	function resolveAsBool(v:ReferenceableValue):Bool {
		return switch v {
			case EBinop(op, e1, e2):
				switch op {
					case OpEq: 
						resolveAsString(e1) == resolveAsString(e2);
					case OpNotEq:
						resolveAsString(e1) != resolveAsString(e2);
					case OpLess:
						// Try numeric comparison first, fall back to string
						try {
							resolveAsNumber(e1) < resolveAsNumber(e2);
						} catch (e) {
							resolveAsString(e1) < resolveAsString(e2);
						}
					case OpGreater:
						// Try numeric comparison first, fall back to string
						try {
							resolveAsNumber(e1) > resolveAsNumber(e2);
						} catch (e) {
							resolveAsString(e1) > resolveAsString(e2);
						}
					case OpLessEq:
						try {
							resolveAsNumber(e1) <= resolveAsNumber(e2);
						} catch (e) {
							resolveAsString(e1) <= resolveAsString(e2);
						}
					case OpGreaterEq:
						try {
							resolveAsNumber(e1) >= resolveAsNumber(e2);
						} catch (e) {
							resolveAsString(e1) >= resolveAsString(e2);
						}
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

	function resolveAsInteger(v:ReferenceableValue) {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): val;
				case CBRNoResult:
					if (defaultValue != null) resolveAsInteger(defaultValue); else throw 'no default value for $input' + currentNodePos();

				case _: throw 'callback should return int but was ${result} for $input' + currentNodePos();
			}
		}

		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported' + currentNodePos();
			case RVArrayReference(refArray): throw 'RVArrayReference not supported' + currentNodePos();
			case RVInteger(i): return i;
			case RVFloat(f): return Std.int(f);
			case RVString(s): return stringToInt(s);
			case RVColorXY(_, _, _) | RVColor(_, _): resolveAsColorInteger(v);
			case RVReference(ref):
				if (!indexedParams.exists(ref)) {
					throw 'reference ${ref} does not exist, available ${indexedParams}' + currentNodePos();
				}

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case ValueF(val): return Std.int(val);
					case StringValue(s): stringToInt(s);
					case ExpressionAlias(expr): resolveAsInteger(expr);
					case null: throw 'reference ${ref} is null' + currentNodePos();
					default: throw 'reference ${ref} is not a value but ${val}' + currentNodePos();
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
					case OpDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
					case OpMod: Std.int(resolveAsInteger(e1) % resolveAsInteger(e2));
					case OpIntegerDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
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

	function resolveAsNumber(v:ReferenceableValue):Float {
		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported' + currentNodePos();
			case RVArrayReference(refArray): throw 'RVArrayReference not supported' + currentNodePos();
			case RVInteger(i): i;
			case RVFloat(f): f;
			case RVString(s):
				final f = Std.parseFloat(s);
				if (Math.isNaN(f)) throw 'expected number, got ${s}' + currentNodePos();
				f;
			case RVColorXY(_, _, _) | RVColor(_, _): throw 'reference is a color but needs to be float' + currentNodePos();
			case RVReference(ref):
				if (!indexedParams.exists(ref))
					throw 'reference ${ref} does not exist (resolveAsNumber), available ${indexedParams}' + currentNodePos();

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case ValueF(val): return val;
					case ExpressionAlias(expr): resolveAsNumber(expr);
					case null: throw 'reference ${ref} is null' + currentNodePos();
					default: throw 'reference ${ref} is not a value but ${val}' + currentNodePos();
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
					case CBRString(val): throw 'callback should return number but was ${val}' + currentNodePos();
					case CBRFloat(val): val;
					case CBRObject(_): throw 'callback should return number but was CBRObject for $input' + currentNodePos();
					case CBRNoResult: resolveAsNumber(defaultValue);
					case null: throw 'callback should return number but was null for $input' + currentNodePos();
				}
			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);
				switch result {
					case CBRInteger(val): cast(val, Float);
					case CBRString(val): throw 'callback should return number but was ${result} for $input' + currentNodePos();
					case CBRFloat(val): val;
					case CBRNoResult: resolveAsNumber(defaultValue);
					case CBRObject(_): throw 'callback should return number but was CBRObject $result for $input' + currentNodePos();
					case null: throw 'callback should return number but was null' + currentNodePos();
				}

			case EBinop(op, e1, e2):
				switch op {
					case OpAdd: resolveAsNumber(e1) + resolveAsNumber(e2);
					case OpMul: resolveAsNumber(e1) * resolveAsNumber(e2);
					case OpSub: resolveAsNumber(e1) - resolveAsNumber(e2);
					case OpDiv: resolveAsNumber(e1) / resolveAsNumber(e2);
					case OpMod: resolveAsNumber(e1) % resolveAsNumber(e2);
					case OpIntegerDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
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

	function resolveAsString(v:ReferenceableValue):String {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): '${val}';
				case CBRFloat(val): '${val}';
				case CBRString(val): val;
				case CBRObject(_): throw 'callback should return string but was CBRObject for $input' + currentNodePos();
				case CBRNoResult:
					if (defaultValue != null) resolveAsString(defaultValue); else throw 'no default value for $input' + currentNodePos();
				case null: throw 'callback should return string but was null for $input' + currentNodePos();
			}
		}

		return switch v {
			case RVElementOfArray(array, index):
				resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported' + currentNodePos();
			case RVArrayReference(refArray): throw 'RVArrayReference not supported' + currentNodePos();
			case RVInteger(i): return '${i}';
			case RVFloat(f): return '${f}';
			case RVString(s): return s;
			case RVColorXY(_, _, _) | RVColor(_, _):
				var color = resolveAsColorInteger(v);
				'$color';

			case RVReference(ref):
				if (!indexedParams.exists(ref))
					throw 'reference ${ref} does not exist (resolveAsString), available ${indexedParams}' + currentNodePos();

				final val:ResolvedIndexParameters = indexedParams.get(ref);
				switch val {
					case Value(val): return '${val}';
					case ValueF(val): return '${val}';
					case StringValue(s): return s;
					case Index(_, value): return value;
					case ExpressionAlias(expr): return resolveAsString(expr);
					default: throw 'invalid reference value ${ref}, expected string got ${val}' + currentNodePos();
				}
			case RVParenthesis(e):
				// Parenthesized expressions (from ${...} interpolation) should evaluate
				// arithmetically first, then convert to string. This ensures ${value + 10}
				// produces "87" not "7710".
				try {
					final n = resolveAsNumber(e);
					return n == Math.ffloor(n) ? Std.string(Std.int(n)) : Std.string(n);
				} catch (_:Dynamic) {
					return resolveAsString(e);
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

	function generatePlaceholderBitmap(type:ResolvedGeneratedTileType) {
		return switch type {
			case Cross(w, h, color, thickness):
				final c = color.addAlphaIfNotPresent();
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
				h2d.Tile.fromColor(color.addAlphaIfNotPresent(), w, h);

			case SolidColorWithText(w, h, bgColor, text, textColor, fontName):
				// Create a solid color tile with centered text using font rendering
				generateTileWithText(w, h, bgColor.addAlphaIfNotPresent(), text, textColor.addAlphaIfNotPresent(), fontName);

			case AutotileRef(format, tileIndex, tileSize, edgeColor, fillColor):
				// Generate autotile demo tile with diagonal corners
				generateAutotileDemoTile(format, tileIndex, tileSize, edgeColor.addAlphaIfNotPresent(), fillColor.addAlphaIfNotPresent());

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
		final node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'autotile reference: could not find autotile "$name"' + currentNodePos();

		final autotileDef:AutotileDef = switch node.type {
			case AUTOTILE(def): def;
			default: throw 'autotile reference: "$name" is not an autotile definition' + MacroUtils.nodePos(node);
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
					throw 'autotile reference: tile index $tileIndex out of bounds for "$name" (has ${tiles.length} tiles)' + MacroUtils.nodePos(node);
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
				if (autotileDef.region != null) {
					final r = autotileDef.region;
					regionX = resolveAsInteger(r[0]);
					regionY = resolveAsInteger(r[1]);
					final regionW = resolveAsInteger(r[2]);
					final regionH = resolveAsInteger(r[3]);
					regionTile = baseTile.sub(regionX, regionY, regionW, regionH);
				}

				// Apply mapping if present (remap the tile index)
				var mappedIndex = tileIndex;
				if (autotileDef.mapping != null) {
					var actualIndex = tileIndex;
					// For blob47 with allowPartialMapping, apply fallback for missing tiles
					if (format == Blob47 && autotileDef.allowPartialMapping && !autotileDef.mapping.exists(actualIndex)) {
						actualIndex = bh.base.Autotile.applyBlob47FallbackWithMap(tileIndex, autotileDef.mapping);
					}
					if (!autotileDef.mapping.exists(actualIndex))
						throw 'autotile reference: tile index $tileIndex not found in mapping' + MacroUtils.nodePos(node);
					mappedIndex = autotileDef.mapping.get(actualIndex);
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
				if (autotileDef.mapping != null) {
					var actualIndex = tileIndex;
					// For blob47 with allowPartialMapping, apply fallback for missing tiles
					if (format == Blob47 && autotileDef.allowPartialMapping && !autotileDef.mapping.exists(actualIndex)) {
						actualIndex = bh.base.Autotile.applyBlob47FallbackWithMap(tileIndex, autotileDef.mapping);
					}
					if (!autotileDef.mapping.exists(actualIndex))
						throw 'autotile reference: tile index $tileIndex not found in mapping' + MacroUtils.nodePos(node);
					mappedIndex = autotileDef.mapping.get(actualIndex);
				}

				// Load tile from atlas with prefix and index
				final tileName = prefixStr + mappedIndex;
				final tile = loadTileImpl(sheetName, tileName).tile;
				PreloadedTile(tile);

			case ATSAtlasRegion(sheet, region):
				// Atlas region-based autotiles not yet supported for generated(autotile(...)) syntax
				throw 'autotile reference: "$name" uses sheet region - use tiles: or demo: syntax instead' + MacroUtils.nodePos(node);
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

		final node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'autotileRegionSheet: could not find autotile "$name"' + currentNodePos();

		final autotileDef:AutotileDef = switch node.type {
			case AUTOTILE(def): def;
			default: throw 'autotileRegionSheet: "$name" is not an autotile definition' + MacroUtils.nodePos(node);
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
					throw 'autotileRegionSheet: autotile "$name" has no region defined' + MacroUtils.nodePos(node);
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
				throw 'autotileRegionSheet: autotile "$name" uses demo source - no region to display' + MacroUtils.nodePos(node);

			case ATSTiles(_):
				throw 'autotileRegionSheet: autotile "$name" uses explicit tiles - no region to display' + MacroUtils.nodePos(node);

			case ATSAtlas(_, _):
				throw 'autotileRegionSheet: autotile "$name" uses atlas prefix - no region to display' + MacroUtils.nodePos(node);
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
		final bg = new h2d.Bitmap(h2d.Tile.fromColor(bgColor, w, h), container);

		// Create and configure text
		final textObj = new h2d.Text(font, container);
		textObj.text = text;
		textObj.textColor = textColor & 0xFFFFFF;
		textObj.maxWidth = w;
		textObj.textAlign = Center;

		// Center text vertically (use integer position for deterministic rendering)
		final textHeight = textObj.textHeight;
		textObj.x = 0;
		textObj.y = Math.floor((h - textHeight) / 2);

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
			case TSFile(filename): resourceLoader.loadTile(resolveAsString(filename));
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
				if (param == null)
					throw 'TileSource reference "$varName" not found in indexed params' + currentNodePos();
				switch param {
					case TileSourceValue(ts): loadTileSource(ts);
					case _: throw 'TileSource reference "$varName" is not a TileSourceValue, got: $param' + currentNodePos();
				}
		}

		if (tile == null)
			throw 'could not load tile $tileSource' + currentNodePos();
		return tile;
	}

	function createHtmlText(font) {
		final t = new HtmlText(font);
		t.loadFont = (name) -> resourceLoader.loadFont(name);
		return t;
	}

	function matchSingleCondition(condValue:ConditionalValues, currentValue:ResolvedIndexParameters):Bool {
		switch condValue {
			case CoNot(inner):
				return !matchSingleCondition(inner, currentValue);
			case CoEnums(a):
				switch currentValue {
					case Index(idx, v):
						if (!a.contains(v)) return false;
					case Value(val):
						if (!a.contains(Std.string(val))) return false;
					case StringValue(s):
						if (!a.contains(s)) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}
			case CoRange(from, to, fromExclusive, toExclusive):
				switch currentValue {
					case Value(val):
						if (from != null && (fromExclusive ? val <= from : val < from)) return false;
						if (to != null && (toExclusive ? val >= to : val > to)) return false;
					case ValueF(val):
						if (from != null && (fromExclusive ? val <= from : val < from)) return false;
						if (to != null && (toExclusive ? val >= to : val > to)) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}

			case CoIndex(idx, value):
				switch currentValue {
					case Index(i, value): if (idx != i) return false;
					case StringValue(s): if (s != value) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}
			case CoValue(val):
				switch currentValue {
					case Value(iVal): if (val != iVal) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}
			case CoFlag(f):
				switch currentValue {
					case Flag(i): if (f & i != f) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}
			case CoAny:
			case CoStringValue(s):
				switch currentValue {
					case Index(idx, value): if (value != s) return false;
					case StringValue(sv): if (s != sv) return false;
					default: throw 'invalid param types ${currentValue}, ${condValue}' + currentNodePos();
				}
		}
		return true;
	}

	function matchConditions(conditions:Map<String, ConditionalValues>, strict:Bool, indexedParams:Map<String, ResolvedIndexParameters>):Bool {
		for (key => value in conditions) {
			if (indexedParams[key] == null)
				return false;
		}
		for (currentName => currentValue in indexedParams) {
			final condValue = conditions[currentName];
			if (condValue == null)
				if (strict)
					return false
				else
					continue;
			if (!matchSingleCondition(condValue, currentValue))
				return false;
		}
		return true;
	}

	function isMatch(node:Node, indexedParams:Map<String, ResolvedIndexParameters>) {
		return switch node.conditionals {
			case Conditional(conditions, strict):
				matchConditions(conditions, strict, indexedParams);
			case ConditionalElse(_) | ConditionalDefault:
				true; // Pre-filtered by resolveConditionalChildren
			case NoConditional: return true;
		}
	}

	// Resolves @else/@default chains: returns only the children that should be built
	// given the current indexedParams state. Regular Conditional and NoConditional nodes
	// are always included (their isMatch check happens later in build/buildTileGroup).
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
				case Conditional(conditions, strict):
					var matched = matchConditions(conditions, strict, indexedParams);
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

	static function collectCoordinateParamRefs(coord:Coordinates, result:Array<String>):Void {
		if (coord == null) return;
		switch coord {
			case OFFSET(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_GRID_POSITION(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_GRID_POSITION_WITH_OFFSET(x, y, ox, oy): collectParamRefs(x, result); collectParamRefs(y, result); collectParamRefs(ox, result); collectParamRefs(oy, result);
			case SELECTED_HEX_CUBE(q, r, s): collectParamRefs(q, result); collectParamRefs(r, result); collectParamRefs(s, result);
			case SELECTED_HEX_OFFSET(col, row, _): collectParamRefs(col, result); collectParamRefs(row, result);
			case SELECTED_HEX_DOUBLED(col, row): collectParamRefs(col, result); collectParamRefs(row, result);
			case SELECTED_HEX_PIXEL(x, y): collectParamRefs(x, result); collectParamRefs(y, result);
			case SELECTED_HEX_CORNER(count, factor): collectParamRefs(count, result); collectParamRefs(factor, result);
			case SELECTED_HEX_EDGE(dir, factor): collectParamRefs(dir, result); collectParamRefs(factor, result);
			case NAMED_COORD(_, coord): collectCoordinateParamRefs(coord, result);
			default:
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
		if (incrementalContext == null) return;

		switch node.type {
			case TEXT(textDef):
				final textRefs:Array<String> = [];
				collectParamRefs(textDef.text, textRefs);
				collectParamRefs(textDef.color, textRefs);
				if (textRefs.length > 0) {
					final t = switch builtObject { case HeapsText(t): t; default: null; };
					if (t != null) {
						final textDefCapture = textDef;
						incrementalContext.trackExpression(() -> {
							t.text = resolveAsString(textDefCapture.text);
							t.textColor = resolveAsColorInteger(textDefCapture.color);
						}, textRefs);
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
						incrementalContext.trackExpression(() -> {
							sg.width = resolveAsNumber(wCapture);
							sg.height = resolveAsNumber(hCapture);
						}, npRefs);
					}
				}
			case BITMAP(tileSource, _, _):
				switch tileSource {
					case TSGenerated(type):
						switch type {
							case SolidColor(w, h, color):
								final bmpRefs:Array<String> = [];
								collectParamRefs(w, bmpRefs);
								collectParamRefs(h, bmpRefs);
								collectParamRefs(color, bmpRefs);
								if (bmpRefs.length > 0) {
									final bmp = switch builtObject { case HeapsBitmap(bmp): bmp; default: null; };
									if (bmp != null) {
										final wCapture = w;
										final hCapture = h;
										final colorCapture = color;
										incrementalContext.trackExpression(() -> {
											bmp.tile = h2d.Tile.fromColor(resolveAsColorInteger(colorCapture).addAlphaIfNotPresent(),
												resolveAsInteger(wCapture), resolveAsInteger(hCapture));
										}, bmpRefs);
									}
								}
							default:
						}
					default:
				}
			case GRAPHICS(elements):
				final gfxRefs:Array<String> = [];
				for (item in elements) {
					collectCoordinateParamRefs(item.pos, gfxRefs);
					collectGraphicsElementParamRefs(item.element, gfxRefs);
				}
				if (gfxRefs.length > 0) {
					final g:h2d.Graphics = switch builtObject { case HeapsObject(obj): Std.downcast(obj, h2d.Graphics); default: null; };
					if (g != null) {
						final elementsCapture = elements;
						final gridCapture = MultiAnimParser.getGridCoordinateSystem(node);
						final hexCapture = MultiAnimParser.getHexCoordinateSystem(node);
						incrementalContext.trackExpression(() -> {
							g.clear();
							drawGraphicsElements(g, elementsCapture, gridCapture, hexCapture);
						}, gfxRefs);
					}
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
						final pixelScaleCapture:Float = node.scale != null ? resolveAsNumber(node.scale) : 1.0;
						incrementalContext.trackExpression(() -> {
							final result = drawPixels(shapesCapture, gridCapture, hexCapture);
							pl.tile = result.pixelLines.tile;
							pl.data = result.pixelLines.data;
							// Update constraint size so Bitmap doesn't stretch the new tile to the old canvas dimensions
							pl.width = result.pixelLines.tile.width;
							pl.height = result.pixelLines.tile.height;
							// Update position for new bounds (minX/minY change when shapes have dynamic widths)
							pl.setPosition(result.minX * pixelScaleCapture, result.minY * pixelScaleCapture);
						}, pxRefs);
					}
				}
			default:
		}

		// Track position if it references params
		if (node.pos != null) {
			final posRefs:Array<String> = [];
			switch node.pos {
				case OFFSET(x, y):
					collectParamRefs(x, posRefs);
					collectParamRefs(y, posRefs);
				case SELECTED_GRID_POSITION(gridX, gridY):
					collectParamRefs(gridX, posRefs);
					collectParamRefs(gridY, posRefs);
				case SELECTED_GRID_POSITION_WITH_OFFSET(gridX, gridY, offsetX, offsetY):
					collectParamRefs(gridX, posRefs);
					collectParamRefs(gridY, posRefs);
					collectParamRefs(offsetX, posRefs);
					collectParamRefs(offsetY, posRefs);
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
				final posCapture = node.pos;
				final gcs = MultiAnimParser.getGridCoordinateSystem(node);
				final hcs = MultiAnimParser.getHexCoordinateSystem(node);
				incrementalContext.trackExpression(() -> {
					final p = calculatePosition(posCapture, gcs, hcs);
					object.x = p.x;
					object.y = p.y;
				}, posRefs);
			}
		}
	}

	function addPosition(obj:h2d.Object, x, y) {
		obj.x += x;
		obj.y += y;
	}

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
					throw 'gridCoordinateSystem is null' + currentNodePos();
				gridCoordinateSystem.resolveAsGrid(resolveAsInteger(gridX), resolveAsInteger(gridY));
			case SELECTED_GRID_POSITION_WITH_OFFSET(gridX, gridY, offsetX, offsetY):
				if (gridCoordinateSystem == null)
					throw 'gridCoordinateSystem is null' + currentNodePos();
				gridCoordinateSystem.resolveAsGrid(resolveAsInteger(gridX), resolveAsInteger(gridY), resolveAsInteger(offsetX), resolveAsInteger(offsetY));
			case SELECTED_HEX_EDGE(direction, factor):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveAsHexEdge(resolveAsInteger(direction), resolveAsNumber(factor));
			case SELECTED_HEX_CORNER(count, factor):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveAsHexCorner(resolveAsInteger(count), resolveAsNumber(factor));
			case SELECTED_HEX_CUBE(q, r, s):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveHexCube(resolveAsNumber(q), resolveAsNumber(r), resolveAsNumber(s));
			case SELECTED_HEX_OFFSET(col, row, parity):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveHexOffset(resolveAsInteger(col), resolveAsInteger(row), parity);
			case SELECTED_HEX_DOUBLED(col, row):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveHexDoubled(resolveAsInteger(col), resolveAsInteger(row));
			case SELECTED_HEX_PIXEL(x, y):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				hexCoordinateSystem.resolveHexPixel(resolveAsNumber(x), resolveAsNumber(y));
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
				final hex = resolveToHex(cell, hexCoordinateSystem);
				hexCoordinateSystem.resolveAsHexCellCorner(hex, resolveAsInteger(cornerIndex), resolveAsNumber(factor));
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				if (hexCoordinateSystem == null)
					throw 'hexCoordinateSystem is null' + currentNodePos();
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
				if (namedCS == null) throw 'unknown named coordinate system: $name' + currentNodePos();
				switch (namedCS) {
					case NamedGrid(system): calculatePosition(coord, system, hexCoordinateSystem);
					case NamedHex(system): calculatePosition(coord, gridCoordinateSystem, system);
				}
		}
		return pos;
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
				hexCoordinateSystem.hexLayout.pixelToHex(new h2d.col.Point(resolveAsNumber(x), resolveAsNumber(y))).round();
			case NAMED_COORD(name, coord):
				final namedCS = MultiAnimParser.getNamedCoordinateSystem(name, currentNode);
				switch (namedCS) {
					case NamedHex(system): resolveToHex(coord, system);
					default: throw 'Named system $name is not a hex coordinate system' + currentNodePos();
				}
			default:
				throw 'Cannot resolve cell coordinates to hex: $cell' + currentNodePos();
		};
	}

	function drawPixels(shapes:Array<PixelShapes>, gridCoordinateSystem, hexCoordinateSystem) {
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
					computedShapes.push(ComputedShape.Line(x1, y1, x2, y2, resolveAsColorInteger(line.color).addAlphaIfNotPresent()));
					bounds.addPos(x1, y1);
					bounds.addPos(x2, y2);
				case RECT(rect) | FILLED_RECT(rect):
					var filled = switch s { case FILLED_RECT(_): true; default: false; };
					var start = calculatePosition(rect.start, gridCoordinateSystem, hexCoordinateSystem);
					var x = Math.round(start.x);
					var y = Math.round(start.y);
					var w = resolveAsInteger(rect.width);
					var h = resolveAsInteger(rect.height);
					computedShapes.push(ComputedShape.Rect(x, y, w, h, resolveAsColorInteger(rect.color).addAlphaIfNotPresent(), filled));
					bounds.addPos(x, y);
					bounds.addPos(x + w+1, y + h+1);
				case PIXEL(pixel):
					var pos = calculatePosition(pixel.pos, gridCoordinateSystem, hexCoordinateSystem);
					var x = Math.round(pos.x);
					var y = Math.round(pos.y);
					computedShapes.push(ComputedShape.Pixel(x, y, resolveAsColorInteger(pixel.color).addAlphaIfNotPresent()));
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					var resolvedColor = resolveAsColorInteger(color).addAlphaIfNotPresent();
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
					throw 'StateAnimIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
				final selector = [for (k => v in selectorRefs) k => resolveAsString(v)];
				final animName = resolveAsString(animationName);
				tileSourceIterator = collectStateAnimFrames(animFilename, animName, selector);
				repeatCount = tileSourceIterator.length;
				bitmapVarName = bmpVarName;
			case TilesIterator(bmpVarName, tnVarName, sheetName, tileFilter):
				if (!allowTileIterators)
					throw 'TilesIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
				bitmapVarName = bmpVarName;
				tilenameVarName = tnVarName;
				final sheet = getOrLoadSheet(sheetName);
				if (tileFilter != null) {
					final frames = sheet.getAnim(tileFilter);
					if (frames == null) {
						throw 'Tile "${tileFilter}" not found in sheet "${sheetName}". The tile filter must be an exact tile name (key) in the atlas.'
							+ MacroUtils.nodePos(node);
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

	function buildTileGroup(node:Node, tileGroup:h2d.TileGroup, currentPos:Point, gridCoordinateSystem:GridCoordinateSystem,
			hexCoordinateSystem:HexCoordinateSystem, builderParams:BuilderParameters):Void {
		if (isMatch(node, indexedParams) == false)
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
			case REPEAT(varName, repeatType):
				final info = resolveTileGroupRepeatAxis(repeatType, node, true);
				final iterator = info.layoutName == null ? null : getLayouts().getIterator(info.layoutName);

				if (indexedParams.exists(node.updatableName.getNameString()))
					throw 'cannot use repeatable index param "$varName" as it is already defined' + MacroUtils.nodePos(node);
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
					throw 'cannot use repeatable2d index param "$varNameX" or "$varNameY" as it is already defined' + MacroUtils.nodePos(node);
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
			default: throw 'unsupported node ${node.uniqueNodeName} ${node.type} in tileGroup mode' + MacroUtils.nodePos(node);
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
				throw 'tileGroup does not support filters for ${node.type}' + MacroUtils.nodePos(node);
			if (node.blendMode != null && node.blendMode != MBAlpha)
				throw 'tileGroup does not support blendMode other than Alpha for ${node.type}' + MacroUtils.nodePos(node);
			tileGroup.addTransform(currentPos.x, currentPos.y, scale, scale, 0, tileGroupTile);
		}
	}

	function addNinePatchToTileGroup(node:Node, sheet:String, tilename:String, widthRV:ReferenceableValue, heightRV:ReferenceableValue,
			currentPos:Point, tileGroup:h2d.TileGroup):Void {
		final atlasSheet = getOrLoadSheet(sheet);
		if (atlasSheet == null)
			throw 'sheet ${sheet} could not be loaded' + currentNodePos();
		final entries = atlasSheet.getContents().get(tilename);
		if (entries == null || entries.length == 0 || entries[0] == null)
			throw 'tile ${tilename} in sheet ${sheet} could not be loaded' + currentNodePos();
		final entry = entries[0];
		final srcTile = entry.t;
		if (entry.split == null || entry.split.length != 4)
			throw 'tile ${tilename} in sheet ${sheet} is not a valid 9-patch (needs split with 4 values)' + currentNodePos();

		final bl:Float = entry.split[0]; // border left
		final br:Float = entry.split[1]; // border right
		final bt:Float = entry.split[2]; // border top
		final bb:Float = entry.split[3]; // border bottom

		final targetW:Float = resolveAsNumber(widthRV);
		final targetH:Float = resolveAsNumber(heightRV);
		final scale:Float = node.scale == null ? 1.0 : resolveAsNumber(node.scale);

		if (node.filter != null && node.filter != FilterNone)
			throw 'tileGroup does not support filters for ${node.type}' + MacroUtils.nodePos(node);
		if (node.blendMode != null && node.blendMode != MBAlpha)
			throw 'tileGroup does not support blendMode other than Alpha for ${node.type}' + MacroUtils.nodePos(node);

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

	function build(node:Node, buildMode:InternalBuildMode, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem,
			internalResults:InternalBuilderResults, builderParams:BuilderParameters):h2d.Object {
		final nodeVisible = isMatch(node, indexedParams);
		if (!nodeVisible && !incrementalMode)
			return null;
		this.currentNode = node;
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
			// TODO: handle UIElementCustomAddToLayer
			if (node.layer != -1) {
				if (layersParent != null)
					layersParent.add(toAdd, node.layer);
				else
					throw 'No layers parent for ${node.uniqueNodeName}-${node.type}' + MacroUtils.nodePos(node);
			} else if (current != null)
				current.addChild(toAdd);
			// else do not add as this is root node
		}

		final builtObject:BuiltHeapsComponent = switch node.type {
			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight,
				horizontalSpacing, verticalSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse):
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
				var b = new h2d.Bitmap(tile);
				HeapsBitmap(b);
			case TEXT(textDef):
				final font = resourceLoader.loadFont(resolveAsString(textDef.fontName));
				var t = if (textDef.isHtml) {
					createHtmlText(font);
				} else {
					new h2d.Text(font);
				}

				t.textAlign = switch textDef.halign {
					case null: Left;
					case Left: Left;
					case Right: Right;
					case Center: Center;
				}
				if (textDef.textAlignWidth != null) {
					// When text has scale applied, maxWidth needs to be divided by scale
					// so that alignment (center/right) is calculated correctly before scaling
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

				HeapsText(t);
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

			case RELATIVE_LAYOUTS(_): throw 'layouts not allowed as non-root node' + MacroUtils.nodePos(node);
			case ANIMATED_PATH(_): throw 'animatedPath not allowed as non-root node' + MacroUtils.nodePos(node);
			case PATHS(_): throw 'paths not allowed as non-root node' + MacroUtils.nodePos(node);
			case CURVES(_): throw 'curves not allowed as non-root node' + MacroUtils.nodePos(node);
			case PARTICLES(particlesDef):
				Particles(createParticleImpl(particlesDef, node.uniqueNodeName));
			case PALETTE(_): throw 'palette not allowed as non-root node' + MacroUtils.nodePos(node);
			case AUTOTILE(_): throw 'autotile not allowed as non-root node' + MacroUtils.nodePos(node);
			case ATLAS2(_): throw 'atlas2 is a definition node, not a renderable element' + MacroUtils.nodePos(node);
			case DATA(_): throw 'data is a definition node, not a renderable element' + MacroUtils.nodePos(node);

			case PLACEHOLDER(type, source):
				var settings = resolveSettings(node);

				function getH2dObj(result:CallbackResult):Null<h2d.Object> {
					return switch result {
						case CBRObject(val): val;
						case CBRNoResult: null;
						default: throw 'expected h2d.object but got $result' + currentNodePos();
						case null: null;
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
									if (settings != null)
										trace('Warning: PVObject placeholder "${resolveAsString(callbackName)}" ignores .manim settings — use PVFactory instead to receive settings');
									obj;
								case PVFactory(factoryMethod):
									var res = factoryMethod(settings);
									// trace('FACTORY', settings, res, type, source);
									res;
							}
						}
				}
				if (callbackResultH2dObject == null) {
					switch type {
						case PHTileSource(source):
							final tile = loadTileSource(source);
							HeapsBitmap(new h2d.Bitmap(tile));
						case PHNothing: HeapsObject(new h2d.Object());
						case PHError: throw 'placeholder ${node.updatableName}, type ${node.type} configured in error mode, no input from $source' + MacroUtils.nodePos(node);
					}
				} else {
					HeapsObject(callbackResultH2dObject);
				}

			case STATIC_REF(externalReference, reference, parameters):
				var builder = if (externalReference != null) {
					var builder = multiParserResult?.imports?.get(externalReference);
					if (builder == null)
						throw 'could not find builder for external staticRef ${externalReference}' + MacroUtils.nodePos(node);
					builder;
				} else this;

				#if MULTIANIM_TRACE
				trace('build staticRef ${reference} with parameters ${parameters} and builderParams ${builderParams} and indexedParams ${indexedParams}');
				#end

				var result = builder.buildWithParameters(reference, parameters, builderParams, indexedParams);
				var object = result?.object;
				if (object == null)
					throw 'could not build staticRef ${reference}' + MacroUtils.nodePos(node);

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

			case DYNAMIC_REF(externalReference, reference, parameters):
				var builder = if (externalReference != null) {
					var builder = multiParserResult?.imports?.get(externalReference);
					if (builder == null)
						throw 'could not find builder for external dynamicRef ${externalReference}' + MacroUtils.nodePos(node);
					builder;
				} else this;

				// Build with incremental: true so the dynamicRef supports setParameter
				var result = builder.buildWithParameters(reference, parameters, builderParams, indexedParams, true);
				var object = result?.object;
				if (object == null)
					throw 'could not build dynamicRef ${reference}' + MacroUtils.nodePos(node);

				// Store the sub-result for later access via getDynamicRef()
				internalResults.dynamicRefs.set(reference, result);

				// Register parameter bindings for incremental propagation
				if (incrementalMode && incrementalContext != null && result.incrementalContext != null) {
					final childNode = builder.multiParserResult?.nodes?.get(reference);
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
							incrementalContext.trackDynamicRef(result.incrementalContext, childParam, resolveFn, refs);
						}
					}
				}

				if (object.numChildren == 1) {
					final inner = object.getChildAt(0);
					if (inner.x != 0 || inner.y != 0) {
						selectedBuildMode = ObjectMode(inner);
					}
				}

				HeapsObject(object);

			case POINT:
				HeapsObject(new h2d.Object());
			case STATEANIM(filename, initialState, selectorReferences):
				var selector = [for (k => v in selectorReferences) k => resolveAsString(v)];
				var animSM = resourceLoader.createAnimSM(filename, selector);
				animSM.play(resolveAsString(initialState));

				StateAnim(animSM);
			case STATEANIM_CONSTRUCT(initialState, construct):
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
					throw 'initialState ${initialStateResolved} does not exist in constructed stateanim' + MacroUtils.nodePos(node);

				animSM.play(initialStateResolved);

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
								throw 'Tile "${tileFilter}" not found in sheet "${sheetName}". The tile filter must be an exact tile name (key) in the atlas.' + MacroUtils.nodePos(node);
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
				final hasIncrementalRepeat = incrementalMode && incrementalContext != null && repeatParamRefs.length > 0;

				// Only create a wrapper when children need relative positioning (non-zero step offsets or layout iterator).
				// Otherwise build directly into parent — this lets h2d.Flow see individual children.
				// Also force wrapper for param-dependent repeats in incremental mode (need container for removeChildren).
				final needsWrapper = (dx != 0 || dy != 0 || iterator != null || hasIncrementalRepeat);
				var object = needsWrapper ? new h2d.Object() : null;
				final buildTarget = needsWrapper ? object : current;
				final ownPos = needsWrapper ? null : calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));

				if (indexedParams.exists(node.updatableName.getNameString()))
					throw 'cannot use repeatable index param "$varName" as it is already defined' + MacroUtils.nodePos(node);

				// Disable incremental tracking for children of param-dependent repeats
				// (they will be fully rebuilt when the tracked params change)
				final savedIncrementalMode = incrementalMode;
				final savedIncrementalCtx = incrementalContext;
				if (hasIncrementalRepeat) {
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
						capturedObject.removeChildren();
						final gcs = MultiAnimParser.getGridCoordinateSystem(capturedNode);
						final hcs = MultiAnimParser.getHexCoordinateSystem(capturedNode);
						final ir:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map()};
						for (count in 0...newCount) {
							final resolvedIndex = switch capturedRepeatType {
								case RangeIterator(_, _, _): newRangeStart + count * newRangeStep;
								case _: count;
							};
							indexedParams.set(capturedVarName, Value(resolvedIndex));
							final resolvedChildren = resolveConditionalChildren(capturedNode.children);
							for (childNode in resolvedChildren) {
								var obj = build(childNode, ObjectMode(capturedObject), gcs, hcs, ir, capturedBP);
								if (obj == null)
									continue;
								if (newDx != 0 || newDy != 0) {
									addPosition(obj, newDx * count, newDy * count);
								}
							}
							cleanupFinalVars(resolvedChildren, indexedParams);
						}
						indexedParams.remove(capturedVarName);
					}, repeatParamRefs);
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
						throw 'StateAnimIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
					case TilesIterator(_, _, _, _):
						throw 'TilesIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
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
						throw 'StateAnimIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
					case TilesIterator(_, _, _, _):
						throw 'TilesIterator not supported in REPEAT2D' + MacroUtils.nodePos(node);
				}

				if (indexedParams.exists(varNameX) || indexedParams.exists(varNameY))
					throw 'cannot use repeatable2d index param "$varNameX" or "$varNameY" as it is already defined' + MacroUtils.nodePos(node);
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
					throw 'apply not allowed as root node' + MacroUtils.nodePos(node);
				if (incrementalMode && node.conditionals != NoConditional && incrementalContext != null) {
					// In incremental mode with conditional: track for toggling on parameter changes
					if (nodeVisible) {
						// Save state before applying
						final savedFilter = node.filter != null ? current.filter : null;
						final savedAlpha = node.alpha != null ? current.alpha : null;
						final savedScaleX = node.scale != null ? current.scaleX : null;
						final savedScaleY = node.scale != null ? current.scaleY : null;
						final pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
						addPosition(current, pos.x, pos.y);
						applyExtendedFormProperties(current, node);
						incrementalContext.trackConditionalApply(current, node, true, savedFilter, savedAlpha, savedScaleX, savedScaleY, pos.x, pos.y);
					} else {
						incrementalContext.trackConditionalApply(current, node, false, null, null, null, null, 0, 0);
					}
				} else {
					var pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
					addPosition(current, pos.x, pos.y);
					applyExtendedFormProperties(current, node);
				}
				return null;

			case PROGRAMMABLE(_, _, _):
				throw 'invalid state, programmable should not be built' + MacroUtils.nodePos(node);

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
							case SVTBool: RSVBool(resolveAsBool(entry.value));
						});
					}
				}
				var obj = new MAObject(MAInteractive(resolveAsInteger(width), resolveAsInteger(height), resolveAsString(id), resolvedMeta), debug);
				internalResults.interactives.push(obj);
				HeapsObject(obj);

			case GRAPHICS(elements):
				var g = new h2d.Graphics();
				drawGraphicsElements(g, elements, gridCoordinateSystem, hexCoordinateSystem);
				HeapsObject(g);

			case TILEGROUP:
				final tg = new TileGroup();
				selectedBuildMode = TileGroupMode(tg);
				HeapsObject(tg);
			case FINAL_VAR(name, expr):
				evaluateAndStoreFinal(name, expr, node);
				return null;
		}
		final updatableName = node.updatableName;

		final object = builtObject.toh2dObject();
		addChild(object);
		object.name = node.uniqueNodeName;

		// In incremental mode: set visibility and track conditional elements
		if (incrementalMode) {
			object.visible = nodeVisible;
			if (node.conditionals != NoConditional && incrementalContext != null) {
				incrementalContext.trackConditional(object, node);
			}
		}

		// Set flow properties for spacer elements after addChild
		switch node.type {
			case SPACER(width, height):
				final flowParent = Std.downcast(current, h2d.Flow);
				if (flowParent != null) {
					final props = flowParent.getProperties(object);
					if (width != null) props.minWidth = resolveAsInteger(width);
					if (height != null) props.minHeight = resolveAsInteger(height);
				}
			default:
		}
		//		trace(object.name);

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
						final indexedKey = '${name}_${idx}';
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
						final indexedKey = '${name}_${idxX}_${idxY}';
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
						final index = Std.parseInt(resolveAsString(RVReference(indexVar)));
						if (index == null)
							throw 'Slot "$baseName" indexed variable did not resolve to an integer';
						internalResults.slots.push({key: Indexed(baseName, index), handle: new SlotHandle(object, slotIncrementalCtx, slotContentTarget)});
					case UNTIndexed2D(baseName, indexVarX, indexVarY):
						final indexX = Std.parseInt(resolveAsString(RVReference(indexVarX)));
						final indexY = Std.parseInt(resolveAsString(RVReference(indexVarY)));
						if (indexX == null || indexY == null)
							throw 'Slot "$baseName" 2D indexed variables did not resolve to integers';
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
		var current = node;
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
		if (node.alpha != null)
			object.alpha = resolveAsNumber(node.alpha);
		if (node.blendMode != null)
			object.blendMode = MacroCompatConvert.toH2dBlendMode(node.blendMode);
		if (node.filter != null)
			object.filter = buildFilter(node.filter);
		if (node.tint != null) {
			var d = Std.downcast(object, h2d.Drawable);
			if (d != null)
				d.color.setColor(resolveAsColorInteger(node.tint).addAlphaIfNotPresent());
		}
	}

	function resolveColorList(colors:Array<ReferenceableValue>) {
		return [for (value in colors) resolveAsColorInteger(value)];
	}

	function buildFilter(type:FilterType):h2d.filter.Filter {
		return switch type {
			case FilterNone: null;
			case FilterGroup(filters):
				var ret = new h2d.filter.Group();
				for (f in filters)
					ret.add(buildFilter(f));
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
		}
	}

	function stringToInt(n) {
		var i = Std.parseInt(n);
		if (i != null)
			return i;
		return throw 'expected integer, got ${n}';
	}

	public function hasMultiAnimWithName(name) {
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
					throw 'buildWithParameters require programmable node, was ${node.type}' + MacroUtils.nodePos(node);
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
		};
	}

	function getPalette(name:String) {
		return buildPalettes(name);
	}

	function buildPalettes(name:String):Palette {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get palette node #${name}' + currentNodePos();
		return switch node.type {
			case PALETTE(paletteType):
				return switch paletteType {
					case PaletteColors(colors): new Palette(resolveColorList(colors));
					case PaletteColors2D(colors, width): new Palette(resolveColorList(colors));
					case PaletteImageFile(filename):
						var filenameResolved = resolveAsString(filename);
						var res = resourceLoader.loadHXDResource(filenameResolved);
						if (res == null)
							throw 'could not load palette image $filename' + MacroUtils.nodePos(node);
						var pixels = res.toImage().getPixels();
						var pixelArray = pixels.toVector().toArray();
						new Palette(pixelArray, pixels.width);
				}
			default: throw '$name has to be palette' + MacroUtils.nodePos(node);
		}
	}

	function createParticleImpl(particlesDef, name, ?existingParticles:bh.base.Particles) {
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
				throw 'fadeIn must be between 0 and 1' + currentNodePos();
			group.fadeIn = f;
		}
		if (particlesDef.fadeOut != null) {
			final f = resolveAsNumber(particlesDef.fadeOut);
			if (f < 0 || f > 1.0)
				throw 'fadeOut must be between 0 and 1' + currentNodePos();
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

		// Color curves
		if (particlesDef.colorCurves != null) {
			group.colorEnabled = true;
			var colorCurvesArray:Array<ParticleColorCurveSegment> = particlesDef.colorCurves;
			for (cc in colorCurvesArray) {
				var curve:bh.paths.Curve.ICurve;
				if (cc.inlineEasing != null) {
					curve = new bh.paths.Curve(null, cc.inlineEasing, null);
				} else if (cc.curveName != null) {
					var curves = getCurves();
					var found = curves.get(cc.curveName);
					if (found == null)
						throw 'color curve not found: ${cc.curveName}' + currentNodePos();
					curve = found;
				} else {
					throw 'color curve must have either curveName or inlineEasing' + currentNodePos();
				}
				group.addColorCurveSegment(resolveAsNumber(cc.atRate), curve, resolveAsInteger(cc.startColor), resolveAsInteger(cc.endColor));
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
			case Box(width, height, emitConeAngle, emitConeAngleRandom):
				group.emitMode = bh.base.PartEmitMode.Box(resolveAsNumber(width), resolveAsNumber(height), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)),
					hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)));
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
					throw 'particle animation "${animName}" not found in "${particlesDef.animFile}"' + currentNodePos();

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
							throw 'particle event animation "${eo.animName}" not found in "${particlesDef.animFile}"' + currentNodePos();

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

		particles.addGroup(group);
		return particles;
	}

	public function createParticles(name:String, ?builderParams:BuilderParameters):bh.base.Particles {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get particles node #${name}' + currentNodePos();
		switch node.type {
			case PARTICLES(particlesDef):
				return createParticleImpl(particlesDef, name);

			default:
				throw '$name has to be particles' + MacroUtils.nodePos(node);
		}
	}

	/** Add a particle group to an existing Particles container (for sub-emitters). */
	public function addParticleGroupTo(name:String, particles:bh.base.Particles):Void {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get particles node #${name}' + currentNodePos();
		switch node.type {
			case PARTICLES(particlesDef):
				createParticleImpl(particlesDef, name, particles);
			default:
				throw '$name has to be particles' + MacroUtils.nodePos(node);
		}
	}

	/** Create particles from a ParticlesDef directly (used by ProgrammableBuilder) */
	public function createParticleFromDef(particlesDef:ParticlesDef, name:String):bh.base.Particles {
		return createParticleImpl(particlesDef, name);
	}

	/** Get a data block by name, returning its fields as a Dynamic object. */
	public function getData(name:String):Dynamic {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get data node #${name}' + currentNodePos();
		switch node.type {
			case DATA(dataDef):
				return resolveDataDef(dataDef);
			default:
				throw '$name has to be data' + MacroUtils.nodePos(node);
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
		};
	}

	/** Create an AnimatedPath from a named definition.
	 *  Optional PathNormalization transform controls how the path is positioned/scaled. */
	public function createAnimatedPath(name:String, ?normalization:bh.paths.MultiAnimPaths.PathNormalization):bh.paths.AnimatedPath {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get animatedPath node #${name}' + currentNodePos();
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
						throw 'time mode requires duration' + MacroUtils.nodePos(node);
					case APDistance:
						throw 'distance mode requires speed' + MacroUtils.nodePos(node);
					case null:
						throw 'animatedPath requires either speed or duration' + MacroUtils.nodePos(node);
				};

				var retVal = new bh.paths.AnimatedPath(path, mode);
				retVal.loop = pathDef.loop;
				retVal.pingPong = pathDef.pingPong;

				// Resolve curve references
				var allCurves:Null<Map<String, bh.paths.Curve.ICurve>> = null;
				for (ca in pathDef.curveAssignments) {
					var atRate = switch ca.at {
						case Rate(r): resolveAsNumber(r);
						case Checkpoint(cpName): path.getCheckpoint(cpName);
					};
					// Resolve curve: inline easing takes precedence over named curve
					var curve:bh.paths.Curve.ICurve;
					if (ca.inlineEasing != null) {
						curve = new bh.paths.Curve(null, ca.inlineEasing, null);
					} else if (ca.curveName != null) {
						if (allCurves == null) allCurves = getCurves();
						curve = allCurves.get(ca.curveName);
						if (curve == null)
							throw 'curve not found: ${ca.curveName}' + MacroUtils.nodePos(node);
					} else {
						throw 'curve assignment must have either curveName or inlineEasing' + MacroUtils.nodePos(node);
					}
					switch ca.slot {
						case APSpeed: retVal.addCurveSegment(Speed, atRate, curve);
						case APScale: retVal.addCurveSegment(Scale, atRate, curve);
						case APAlpha: retVal.addCurveSegment(Alpha, atRate, curve);
						case APRotation: retVal.addCurveSegment(Rotation, atRate, curve);
						case APProgress: retVal.addCurveSegment(Progress, atRate, curve);
						case APColor(startColor, endColor):
							retVal.addColorCurveSegment(atRate, curve, Std.int(resolveAsNumber(startColor)), Std.int(resolveAsNumber(endColor)));
						case APCustom(customName): retVal.addCustomCurveSegment(customName, atRate, curve);
					}
				}

				// Add events
				for (ev in pathDef.events) {
					var atRate = switch ev.at {
						case Rate(r): resolveAsNumber(r);
						case Checkpoint(cpName): path.getCheckpoint(cpName);
					};
					retVal.addEvent(atRate, ev.eventName);
				}

				return retVal;

			default:
				throw '$name has to be animatedPath' + MacroUtils.nodePos(node);
		}
	}

	/** Convenience method for creating a projectile path: stretches the named path
	 *  from startPoint to endPoint using Stretch normalization. */
	public function createProjectilePath(name:String, startPoint:bh.base.FPoint, endPoint:bh.base.FPoint):bh.paths.AnimatedPath {
		return createAnimatedPath(name, bh.paths.MultiAnimPaths.PathNormalization.Stretch(startPoint, endPoint));
	}

	public function getLayouts(?builderParams:BuilderParameters):MultiAnimLayouts {
		var node = multiParserResult?.nodes.get(MultiAnimParser.defaultLayoutNodeName);
		if (node == null)
			throw 'relativeLayouts does not exist' + currentNodePos();
		switch node.type {
			case RELATIVE_LAYOUTS(layoutsDef):
				return new MultiAnimLayouts(layoutsDef, this);
			default:
				throw 'relativeLayouts is of unexpected type ${node.type}' + MacroUtils.nodePos(node);
		}
	}

	public function getPaths(?builderParams:BuilderParameters):bh.paths.MultiAnimPaths {
		var node = multiParserResult?.nodes.get(MultiAnimParser.defaultPathNodeName);
		if (node == null)
			throw 'paths does not exist';
		switch node.type {
			case PATHS(pathsDef):
				return new bh.paths.MultiAnimPaths(pathsDef, this);
			default:
				throw 'paths is of unexpected type ${node.type}' + MacroUtils.nodePos(node);
		}
	}

	public function getCurves():Map<String, bh.paths.Curve.ICurve> {
		var node = multiParserResult?.nodes.get(MultiAnimParser.defaultCurveNodeName);
		if (node == null)
			throw 'curves does not exist';
		switch node.type {
			case CURVES(curvesDef):
				var result = new Map<String, bh.paths.Curve.ICurve>();
				for (name => def in curvesDef) {
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
				result.set(name, new bh.paths.Curve(resolvedPoints, def.easing, resolvedSegments));
				}
				return result;
			default:
				throw 'curves is of unexpected type ${node.type}' + MacroUtils.nodePos(node);
		}
	}

	public function getCurve(name:String):bh.paths.Curve.ICurve {
		var curves = getCurves();
		var curve = curves.get(name);
		if (curve == null)
			throw 'curve not found: $name';
		return curve;
	}

	function resolveParticleCurveRef(ref:MultiAnimParser.ParticleCurveRef):bh.paths.Curve.ICurve {
		if (ref.inlineEasing != null)
			return new bh.paths.Curve(null, ref.inlineEasing, null);
		if (ref.curveName != null) {
			var curves = getCurves();
			var curve = curves.get(ref.curveName);
			if (curve == null)
				throw 'curve not found: ${ref.curveName}' + currentNodePos();
			return curve;
		}
		throw 'curve reference must have either curveName or inlineEasing' + currentNodePos();
	}

	/**
	 * Build a TileGroup from autotile definition based on a binary grid.
	 * @param name The name of the autotile definition in the .manim file
	 * @param grid 2D array of 0/1 values where 1 = terrain present
	 * @return h2d.TileGroup populated with the correct autotiles
	 */
	public function buildAutotile(name:String, grid:Array<Array<Int>>):h2d.TileGroup {
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get autotile node #${name}' + currentNodePos();
		switch node.type {
			case AUTOTILE(autotileDef):
				return buildAutotileImpl(autotileDef, grid, null);
			default:
				throw '$name has to be autotile' + MacroUtils.nodePos(node);
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
		var node = multiParserResult?.nodes.get(name);
		if (node == null)
			throw 'could not get autotile node #${name}' + currentNodePos();
		switch node.type {
			case AUTOTILE(autotileDef):
				return buildAutotileImpl(autotileDef, grid, baseY);
			default:
				throw '$name has to be autotile' + MacroUtils.nodePos(node);
		}
	}

	private function buildAutotileImpl(autotileDef:AutotileDef, grid:Array<Array<Int>>, ?elevationBaseY:Null<Float>):h2d.TileGroup {
		final tileGroup = new h2d.TileGroup();
		final tiles = loadAutotileTiles(autotileDef);
		final tileSize = resolveAsInteger(autotileDef.tileSize);
		final depth = autotileDef.depth != null ? resolveAsInteger(autotileDef.depth) : 0;
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
					if (mapping.exists(actualIndex)) {
						tileIndex = mapping.get(actualIndex);
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
				final regionX = autotileDef.region != null ? resolveAsInteger(autotileDef.region[0]) : 0;
				final regionY = autotileDef.region != null ? resolveAsInteger(autotileDef.region[1]) : 0;
				final regionW = autotileDef.region != null ? resolveAsInteger(autotileDef.region[2]) : Std.int(baseTile.width);
				final tilesPerRow = Std.int(regionW / tileSize);

				// If mapping is provided (Map<Int, Int>), load tiles from mapped positions
				// For allowPartialMapping, missing tiles will be filled with a placeholder and resolved at render time
				if (autotileDef.mapping != null) {
					final result = new Array<h2d.Tile>();
					for (i in 0...tileCount) {
						// Get the mapped tileset index, using fallback for missing blob47 tiles
						var mappedIdx = 0;
						if (autotileDef.mapping.exists(i)) {
							mappedIdx = autotileDef.mapping.get(i);
						} else if (autotileDef.format == Blob47 && autotileDef.allowPartialMapping) {
							// Find fallback tile and use its mapping
							final fallbackIdx = bh.base.Autotile.applyBlob47FallbackWithMap(i, autotileDef.mapping);
							mappedIdx = autotileDef.mapping.exists(fallbackIdx) ? autotileDef.mapping.get(fallbackIdx) : 0;
						} else {
							throw 'autotile: tile index $i not found in mapping' + currentNodePos();
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
				final edge = resolveAsColorInteger(edgeColor).addAlphaIfNotPresent();
				final fill = resolveAsColorInteger(fillColor).addAlphaIfNotPresent();
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
				throw 'Setting "$key" does not match any parameter of programmable "#${node.uniqueNodeName}". Available parameters: ${availableParams.join(", ")}' + MacroUtils.nodePos(node);
			}
			return type;
		}

		function resolveReferenceableValue(ref:ReferenceableValue, type):Dynamic {
			return switch type {
				case null: throw 'type is null' + MacroUtils.nodePos(node);
				case PPTHexDirection: resolveAsInteger(ref);
				case PPTGridDirection: resolveAsInteger(ref);
				case PPTFlags(_): resolveAsInteger(ref);
				case PPTEnum(_): resolveAsString(ref);
				case PPTRange(_, _): resolveAsInteger(ref);
				case PPTInt: resolveAsInteger(ref);
				case PPTFloat: resolveAsNumber(ref);
				case PPTBool: resolveAsInteger(ref);
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
					throw 'extra input "$key=>$value" already exists in input' + MacroUtils.nodePos(node);
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
		var node = multiParserResult?.nodes.get(name);
		if (node == null) {
			final error = 'buildWithParameters ${inputParameters}: could find element "$name" to build';
			trace(error);
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
		}

		var retVal = startBuild(name, node, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node), builderParams);

		if (incremental) {
			retVal.incrementalContext = this.incrementalContext;
			this.incrementalContext.applyConditionalChains();
			this.incrementalMode = false;
			this.incrementalContext = null;
		}

		popBuilderState();
		return retVal;
	}

	public function hasNode(name:String) {
		return multiParserResult?.nodes?.get(name) != null;
	}

	/** Build a parameterized slot's children into its container with incremental mode.
	 *  Used by codegen (via ProgrammableBuilder) for parameterized slots. */
	public function buildSlotContent(programmableName:String, slotName:String,
			parentParams:Map<String, Dynamic>, container:h2d.Object):SlotHandle {
		final progNode = multiParserResult?.nodes.get(programmableName);
		if (progNode == null)
			throw 'buildSlotContent: programmable "$programmableName" not found';
		final slotNode = findSlotNode(progNode, slotName);
		if (slotNode == null)
			throw 'buildSlotContent: slot "$slotName" not found in "$programmableName"';
		final slotParams = switch slotNode.type {
			case SLOT(params, _): params;
			default: null;
		};
		if (slotParams == null)
			throw 'buildSlotContent: slot "$slotName" has no parameters';

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
		final builderParams:BuilderParameters = {callback: defaultCallback};
		this.builderParams = builderParams;
		final slotCtx = new IncrementalUpdateContext(this, mergedParams, builderParams, slotNode);
		this.incrementalMode = true;
		this.incrementalContext = slotCtx;

		// Build slot children into container
		final internalResults:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map()};
		for (childNode in resolveConditionalChildren(slotNode.children)) {
			build(childNode, ObjectMode(container), null, null, internalResults, builderParams);
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

	/** Build a single node in isolation, returning the resulting h2d.Object.
	 *  Used by ProgrammableBuilder.buildNodeByUniqueName for forwarding unsupported
	 *  repeatable node types to the builder at runtime. */
	function buildSingleNode(node:Node):Null<h2d.Object> {
		final parent = new h2d.Object();
		final ir:InternalBuilderResults = {names: [], interactives: [], slots: [], dynamicRefs: new Map()};
		build(node, ObjectMode(parent), null, null, ir, builderParams);
		return if (parent.numChildren > 0) parent.getChildAt(0) else null;
	}

	public function buildWithComboParameters(name:String, inputParameters:Map<String, Dynamic>, allCombos:Array<String>, ?builderParams:BuilderParameters) {
		pushBuilderState();
		try {
			if (builderParams == null)
				builderParams = {callback: defaultCallback};
			else if (builderParams.callback == null)
				builderParams.callback = defaultCallback;

			final node = multiParserResult?.nodes?.get(name);
			if (node == null) {
				throw 'buildWithComboParameters ${allCombos}: could not build ${name} with parameters ${inputParameters} and builderParameters ${builderParams}' + currentNodePos();
			}
			if (inputParameters.count() + allCombos.length == 0) {
				throw 'parameters are required for buildWithComboParameters ${name}' + MacroUtils.nodePos(node);
			}

			final definitions = getProgrammableParameterDefinitions(node, true);

			var allOptions:Map<String, Array<String>> = [];
			var totalStates = 1;

			var comboCounts = [];
			var comboNames = [];

			for (prop in allCombos) {
				if (!definitions.exists(prop))
					throw 'definition for "${prop}" does not exist' + MacroUtils.nodePos(node);
				if (inputParameters.exists(prop))
					throw 'Prop "${prop}" set both as parameter and combo' + MacroUtils.nodePos(node);
				if (allOptions.exists(prop))
					throw 'Duplicate combo "${prop}"' + MacroUtils.nodePos(node);
				var def = definitions[prop];
				var allValues = switch def.type {
					case PPTHexDirection: [for (i in 0...6) '$i}'];
					case PPTGridDirection: [for (i in 0...8) '$i}'];
					case PPTFlags(bits): [for (i in 0...bits) '$i}'];
					case PPTEnum(values): values;
					case PPTBool: ["0", "1"];
					case PPTRange(from, to):
						if (Math.abs(from - to) > 50)
							trace('WARNING: range ${from}..${to} is very large');
						[for (i in from...to) '$i}'];
					case PPTInt: throw 'Prop "${prop}" is int and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTUnsignedInt: throw 'Prop "${prop}" is uint and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTString: throw 'Prop "${prop}" is string and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTColor: throw 'Prop "${prop}" is color and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTFloat: throw 'Prop "${prop}" is float and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTArray: throw 'Prop "${prop}" is array and cannot be used as combo' + MacroUtils.nodePos(node);
					case PPTTile: throw 'Prop "${prop}" is tile and cannot be used as combo' + MacroUtils.nodePos(node);
				}
				allOptions.set(prop, allValues);
				totalStates *= allValues.length;
				comboNames.push(prop);
				comboCounts.push(allValues.length);

				if (totalStates > 32)
					trace('more than 100 combination for build all');
				else if (totalStates > 1000)
					throw 'more than 1000 combinations for buildAll' + MacroUtils.nodePos(node);
			}
			final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
			final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);

			var result = new MultiAnimMultiResult(name, allCombos);
			for (i in 0...totalStates) {
				final comboParams:Map<String, ResolvedIndexParameters> = [];
				var ci = i;
				for (ki in 0...comboNames.length) {
					final vi = ci % comboCounts[ki];
					ci = Std.int(ci / comboCounts[ki]);
					var key = comboNames[ki];
					comboParams.set(key, StringValue(allOptions[key][vi]));
				}

				updateIndexedParamsFromDynamicMap(node, inputParameters, definitions, comboParams, true);
				this.builderParams = builderParams;
				var c = startBuild(name, node, gridCoordinateSystem, hexCoordinateSystem, builderParams);
				result.addResult(c, [
					for (combo in allCombos) {
						switch comboParams[combo] {
							case StringValue(s):
								s;
							default:
								throw 'comboParams [${combo}] is not string' + MacroUtils.nodePos(node);
						}
					}
				]);
			}
			popBuilderState();
			return result;
		} catch (e) {
			popBuilderState();
			throw e;
		}
	}

	function loadTileImpl(sheet, tilename, ?index:Int) {
		final sheet = getOrLoadSheet(sheet);
		if (sheet == null)
			throw 'sheet ${sheet} could not be loaded' + currentNodePos();

		final tile = if (index != null) {
			final arr = sheet.getAnim(tilename);
			if (arr == null)
				throw 'tile ${tilename}, index $index sheet ${sheet} could not be loaded' + currentNodePos();
			if (index < 0 || index >= arr.length)
				throw 'tile $tilename from sheet $sheet does not have tile index $index, should be [0, ${arr.length - 1}]' + currentNodePos();
			arr[index];
		} else {
			final t = sheet.get(tilename);
			if (t == null)
				throw 'tile ${tilename} in sheet ${sheet} could not be loaded' + currentNodePos();
			t;
		}

		return tile;
	}

	function load9Patch(sheet, tilename) {
		final sheet = getOrLoadSheet(sheet);
		if (sheet == null)
			throw 'sheet ${sheet} could not be loaded' + currentNodePos();

		final ninePatch = sheet.getNinePatch(tilename);
		if (ninePatch == null)
			throw 'tile ${tilename} in sheet ${sheet} could not be loaded' + currentNodePos();
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
		final node = multiParserResult?.nodes?.get(name);
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
							throw 'atlas2: could not load sheet "${resolveAsString(sheetName)}"' + currentNodePos();
						sheet.getSourceTile();
				}

				if (sourceTile == null)
					throw 'atlas2 "$name": could not load source tile' + currentNodePos();

				// Build contents map from entries
				final contents:Map<String, Array<AtlasEntry>> = [];
				for (entry in atlas2Def.entries) {
					final t = sourceTile.sub(entry.x, entry.y, entry.w, entry.h, 0, 0);
					final idx = entry.index != null ? entry.index : 0;
					final offsetX = entry.offsetX != null ? entry.offsetX : 0;
					final offsetY = entry.offsetY != null ? entry.offsetY : 0;
					final origW = entry.origW != null ? entry.origW : entry.w;
					final origH = entry.origH != null ? entry.origH : entry.h;
					final split:Array<Int> = entry.split != null ? entry.split : [];

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
