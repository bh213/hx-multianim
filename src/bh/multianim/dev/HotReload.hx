package bh.multianim.dev;

// Hot-reload infrastructure for live .manim file updates during development.
// This entire file only compiles when -D MULTIANIM_DEV is set.

#if MULTIANIM_DEV
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.ResolvedIndexParameters;
import bh.multianim.MultiAnimParser.ParametersDefinitions;
import bh.multianim.MultiAnimBuilder.SlotKey;
import bh.multianim.MultiAnimBuilder.PlaceholderValues;
import bh.multianim.MultiAnimBuilder.BuilderCallbackFunction;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimBuilder.BuilderParameters;

// ---- Enums ----

enum ReloadFileType {
	Manim;
	Anim;
}

enum ReloadErrorType {
	ParseError;
	BuildError;
	SignatureIncompatible;
}

enum ReloadEvent {
	ReloadStarted(file:String, fileType:ReloadFileType);
	ReloadSucceeded(report:ReloadReport);
	ReloadFailed(report:ReloadReport);
	ReloadNeedsRestart(report:ReloadReport);
}

// ---- Typedefs ----

typedef ReloadListener = (event:ReloadEvent) -> Void;

typedef ReloadError = {
	message:String,
	file:String,
	line:Int,
	col:Int,
	errorType:ReloadErrorType,
	context:Null<String>,
}

typedef ReloadReport = {
	success:Bool,
	file:String,
	fileType:ReloadFileType,
	programmablesRebuilt:Array<String>,
	paramsAdded:Array<String>,
	needsFullRestart:Null<String>,
	errors:Array<ReloadError>,
	rebuiltCount:Int,
	elapsedMs:Float,
}

typedef ReloadableHandle = {
	sourcePath:String,
	programmableName:String,
	result:BuilderResult,
}

typedef ParamSnapshot = Map<String, ResolvedIndexParameters>;
typedef SlotSnapshot = Array<{key:SlotKey, content:Null<h2d.Object>, data:Dynamic}>;
typedef DynamicRefSnapshot = Map<String, ParamSnapshot>;

typedef PlaceholderSnapshot = Array<{name:String, index:Null<Int>, object:h2d.Object}>;

typedef BuilderResultSnapshot = {
	params:ParamSnapshot,
	slots:SlotSnapshot,
	dynamicRefs:DynamicRefSnapshot,
	placeholders:PlaceholderSnapshot,
}

// ---- IBuilderConsumer ----

interface IBuilderConsumer {
	function onBuilderReplaced(sourcePath:String, newBuilder:MultiAnimBuilder):Void;
}

// ---- FileChangeDetector ----

class FileChangeDetector {
	var contentHashes:Map<String, Int> = new Map();

	public function new() {}

	public function hasChanged(path:String, content:String):Bool {
		final hash = computeHash(content);
		final stored = contentHashes.get(path);
		return stored == null || stored != hash;
	}

	public function updateHash(path:String, content:String):Void {
		contentHashes.set(path, computeHash(content));
	}

	public function invalidate(path:String):Void {
		contentHashes.remove(path);
	}

	public function storeInitialHash(path:String, content:String):Void {
		if (!contentHashes.exists(path))
			contentHashes.set(path, computeHash(content));
	}

	static function computeHash(s:String):Int {
		var h:Int = 0x811c9dc5; // FNV offset basis
		for (i in 0...s.length) {
			h ^= StringTools.fastCodeAt(s, i);
			h = h * 0x01000193;
		}
		return h;
	}
}

// ---- ReloadSentinel ----
// Invisible child placed inside a BuilderResult's root object.
// When the root is removed from scene, onRemove() fires, triggering auto-unregister.

class ReloadSentinel extends h2d.Object {
	var registry:ReloadableRegistry;
	var handle:ReloadableHandle;

	public function new(registry:ReloadableRegistry, handle:ReloadableHandle) {
		super();
		this.registry = registry;
		this.handle = handle;
		this.visible = false;
	}

	override function onRemove() {
		super.onRemove();
		registry.unregister(handle);
	}
}

// ---- ReloadableRegistry ----

class ReloadableRegistry {
	var liveObjects:Map<String, Array<ReloadableHandle>> = new Map();

	public function new() {}

	public function register(sourcePath:String, result:BuilderResult, programmableName:String):ReloadableHandle {
		final handle:ReloadableHandle = {
			sourcePath: sourcePath,
			programmableName: programmableName,
			result: result,
		};
		var list = liveObjects.get(sourcePath);
		if (list == null) {
			list = [];
			liveObjects.set(sourcePath, list);
		}
		list.push(handle);

		// Plant sentinel child for auto-unregister on scene removal
		final sentinel = new ReloadSentinel(this, handle);
		result.object.addChild(sentinel);

		return handle;
	}

	public function unregister(handle:ReloadableHandle):Void {
		final list = liveObjects.get(handle.sourcePath);
		if (list != null)
			list.remove(handle);
	}

	public function getHandles(sourcePath:String):Array<ReloadableHandle> {
		final list = liveObjects.get(sourcePath);
		return list != null ? list.copy() : [];
	}

	public function hasAnyFor(sourcePath:String):Bool {
		final list = liveObjects.get(sourcePath);
		return list != null && list.length > 0;
	}

	/** Returns all live handles across all source paths. Used by DevBridge. */
	public function getAllHandles():Array<ReloadableHandle> {
		var all:Array<ReloadableHandle> = [];
		for (_ => handles in liveObjects) {
			for (h in handles)
				all.push(h);
		}
		return all;
	}

	// Remove the ReloadSentinel child from an object (used before scene swap
	// to prevent stale auto-unregister when old root is removed).
	public static function removeSentinel(obj:h2d.Object):Void {
		var i = 0;
		while (i < obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, ReloadSentinel)) {
				child.remove();
				return;
			}
			i++;
		}
	}
}

// ---- SignatureChecker ----

class SignatureChecker {
	// Returns null if compatible, or a reason string if restart is needed.
	public static function check(oldDefs:ParametersDefinitions, newDefs:ParametersDefinitions):Null<String> {
		// Check for removed params
		for (name => _ in oldDefs) {
			if (!newDefs.exists(name))
				return 'Parameter "$name" was removed';
		}
		// Check for type changes (compare by constructor index only — enum values/ranges
		// may differ between parses due to Array reference inequality with Type.enumEq)
		for (name => oldDef in oldDefs) {
			final newDef = newDefs.get(name);
			if (newDef != null && Type.enumIndex(oldDef.type) != Type.enumIndex(newDef.type))
				return 'Parameter "$name" changed type';
		}
		return null;
	}

	public static function getAddedParams(oldDefs:ParametersDefinitions, newDefs:ParametersDefinitions):Array<String> {
		final added:Array<String> = [];
		for (name => _ in newDefs)
			if (!oldDefs.exists(name))
				added.push(name);
		return added;
	}
}

// ---- StateSnapshotter ----

class StateSnapshotter {
	public static function capture(result:BuilderResult):BuilderResultSnapshot {
		return {
			params: captureParams(result),
			slots: captureSlots(result),
			dynamicRefs: captureDynamicRefs(result),
			placeholders: capturePlaceholders(result),
		};
	}

	public static function captureParams(result:BuilderResult):ParamSnapshot {
		if (result.incrementalContext == null)
			return new Map();
		return result.incrementalContext.snapshotParams();
	}

	static function captureSlots(result:BuilderResult):SlotSnapshot {
		final snapshot:SlotSnapshot = [];
		if (result.slots == null)
			return snapshot;
		for (entry in result.slots) {
			snapshot.push({
				key: entry.key,
				content: entry.handle.getContent(),
				data: entry.handle.data,
			});
		}
		return snapshot;
	}

	static function captureDynamicRefs(result:BuilderResult):DynamicRefSnapshot {
		final snapshot:DynamicRefSnapshot = new Map();
		if (result.dynamicRefs == null)
			return snapshot;
		for (name => dynRef in result.dynamicRefs)
			snapshot.set(name, captureParams(dynRef));
		return snapshot;
	}

	static function capturePlaceholders(result:BuilderResult):PlaceholderSnapshot {
		return result.devCapturedPlaceholders;
	}
}

// ---- StateRestorer ----

class StateRestorer {
	public static function restore(newResult:BuilderResult, snapshot:BuilderResultSnapshot):Void {
		restoreParams(newResult, snapshot.params);
		restoreSlots(newResult, snapshot.slots);
		restoreDynamicRefs(newResult, snapshot.dynamicRefs);
	}

	// Clear slot contents from old result so h2d.Objects can be reparented.
	// Must be called BEFORE rebuilding.
	public static function detachSlots(oldResult:BuilderResult):Void {
		if (oldResult.slots == null)
			return;
		for (entry in oldResult.slots)
			entry.handle.clear();
	}

	static function restoreParams(result:BuilderResult, params:ParamSnapshot):Void {
		if (result.incrementalContext == null || params == null)
			return;
		result.beginUpdate();
		for (name => value in params) {
			final dynVal = resolvedToDynamic(value);
			if (dynVal != null)
				result.setParameter(name, dynVal);
		}
		result.endUpdate();
	}

	public static function resolvedToDynamic(p:ResolvedIndexParameters):Null<Dynamic> {
		return switch p {
			case Value(val): val;
			case ValueF(val): val;
			case StringValue(s): s;
			case Flag(f): f;
			case Index(_, name): name;
			case ArrayString(arr): arr;
			case ExpressionAlias(_): null;
			case TileSourceValue(_): null;
		};
	}

	static function restoreSlots(newResult:BuilderResult, slots:SlotSnapshot):Void {
		if (slots == null || newResult.slots == null)
			return;
		for (saved in slots) {
			if (saved.content == null)
				continue;
			final newHandle = findSlot(newResult, saved.key);
			if (newHandle != null) {
				newHandle.data = saved.data;
				newHandle.setContent(saved.content);
			}
		}
	}

	static function findSlot(result:BuilderResult, key:SlotKey):Null<SlotHandle> {
		for (entry in result.slots) {
			if (Type.enumEq(entry.key, key))
				return entry.handle;
		}
		return null;
	}

	static function restoreDynamicRefs(newResult:BuilderResult, drSnapshot:DynamicRefSnapshot):Void {
		if (drSnapshot == null || newResult.dynamicRefs == null)
			return;
		for (name => paramSnap in drSnapshot) {
			final dynRef = newResult.dynamicRefs.get(name);
			if (dynRef != null)
				restoreParams(dynRef, paramSnap);
		}
	}

	// Convert ParamSnapshot back to Map<String, Dynamic> for buildWithParameters input.
	public static function snapshotToInputMap(params:ParamSnapshot):Map<String, Dynamic> {
		final out:Map<String, Dynamic> = new Map();
		for (k => v in params) {
			final dyn = resolvedToDynamic(v);
			if (dyn != null)
				out.set(k, dyn);
		}
		return out;
	}
}

// ---- PlaceholderReuser ----
// Wraps BuilderParameters to reuse previously-captured placeholder objects
// instead of re-invoking callbacks/factories during hot reload rebuild.

@:access(h2d.Object.allocated)
class PlaceholderReuser {
	// Detach object from parent without triggering onRemove().
	// Heaps' onRemove() cascade destroys h2d.Graphics content,
	// so we must bypass it when reparenting live scene objects.
	static function safeDetach(obj:h2d.Object):Void {
		if (obj.parent != null) {
			obj.allocated = false;
			obj.parent.removeChild(obj);
			// Leave allocated=false so the builder can addChild to the
			// unallocated new tree without triggering onRemove again.
			// allocated is restored to true when SceneSwapper moves
			// children into the allocated oldRoot via addChild.
		}
	}

	// Create wrapped BuilderParameters that returns captured objects for matching placeholders.
	// Falls through to original callback/factory for unmatched names (e.g. new placeholders added).
	public static function wrapBuilderParams(original:BuilderParameters, captured:PlaceholderSnapshot):BuilderParameters {
		if (captured.length == 0)
			return original;

		// Build lookup maps from captured placeholders
		final byName:Map<String, h2d.Object> = new Map();
		final byNameIndex:Map<String, h2d.Object> = new Map();
		for (entry in captured) {
			if (entry.index != null)
				byNameIndex.set('${entry.name}_${entry.index}', entry.object);
			else
				byName.set(entry.name, entry.object);
		}

		// Wrap placeholderObjects: convert PVFactory/PVComponent to PVObject for captured entries
		var wrappedPlaceholderObjects:Null<Map<String, PlaceholderValues>> = original.placeholderObjects;
		if (wrappedPlaceholderObjects != null) {
			final newMap = new Map<String, PlaceholderValues>();
			for (name => pv in wrappedPlaceholderObjects) {
				final cached = byName.get(name);
				if (cached != null) {
					// Don't call cached.remove() — addChild in builder handles reparenting
					// automatically, and remove() triggers onRemove() cascade that
					// invalidates GPU resources on descendants (grids, tilegroups).
					// Reset position: builder uses addPosition (+=), so stale x,y
					// from previous build would accumulate.
					safeDetach(cached);
					cached.x = 0;
					cached.y = 0;
					newMap.set(name, PVObject(cached));
				} else {
					newMap.set(name, pv);
				}
			}
			wrappedPlaceholderObjects = newMap;
		}

		// Wrap callback: return captured objects for Placeholder/PlaceholderWithIndex requests
		final originalCallback = original.callback;
		final wrappedCallback:BuilderCallbackFunction = (request) -> {
			switch request {
				case Placeholder(name):
					final cached = byName.get(name);
					if (cached != null) {
						safeDetach(cached);
						cached.x = 0;
						cached.y = 0;
						return CBRObject(cached);
					}
				case PlaceholderWithIndex(name, index):
					final cached = byNameIndex.get('${name}_${index}');
					if (cached != null) {
						safeDetach(cached);
						cached.x = 0;
						cached.y = 0;
						return CBRObject(cached);
					}
				default:
			}
			// Fall through to original callback
			if (originalCallback != null)
				return originalCallback(request);
			return CBRNoResult;
		};

		return {
			callback: wrappedCallback,
			placeholderObjects: wrappedPlaceholderObjects,
			scene: original.scene,
		};
	}
}

// ---- SceneSwapper ----

class SceneSwapper {
	// Replace children of oldRoot with children from newRoot.
	// oldRoot stays in the scene — game references remain valid.
	public static function replaceChildren(oldRoot:h2d.Object, newRoot:h2d.Object):Void {
		// Remove all old children
		while (oldRoot.numChildren > 0)
			oldRoot.getChildAt(oldRoot.numChildren - 1).remove();

		// Move all children from new root into old root.
		// Use addChild directly — it handles reparenting without triggering
		// onRemove(), which would destroy h2d.Graphics content.
		while (newRoot.numChildren > 0)
			oldRoot.addChild(newRoot.getChildAt(0));

		// Copy internal properties that the builder may have set on the root itself
		// (e.g. filter from `apply()` nodes), but NOT game-applied transforms
		// (x, y, scale, alpha, rotation, visible — those stay on oldRoot as-is)
		if (newRoot.filter != null) {
			oldRoot.filter = newRoot.filter;
			newRoot.filter = null;
		}
	}
}
#end
