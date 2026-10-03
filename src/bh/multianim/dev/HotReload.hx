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
	// Owning registry — lets structural discard paths (which bypass the scene-removal
	// sentinel) unregister the handle directly
	registry:ReloadableRegistry,
	// Set by `unregister`: the result was discarded or replaced, so a sentinel still in its tree
	// must not bring the handle back when the object is added to the scene again.
	disposed:Bool,
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
// Invisible child placed inside a BuilderResult's root object. While the root is out of the
// scene its handle is detached from the registry (not a reload target, not listed by DevBridge);
// when the root comes back — a screen switched away and back, a dialog revived — it is attached
// again. Heaps fires onAdd/onRemove only for roots under an allocated scene.

class ReloadSentinel extends h2d.Object {
	var registry:ReloadableRegistry;
	var handle:ReloadableHandle;

	public function new(registry:ReloadableRegistry, handle:ReloadableHandle) {
		super();
		this.registry = registry;
		this.handle = handle;
		this.visible = false;
	}

	override function onAdd() {
		super.onAdd();
		registry.attach(handle);
	}

	override function onRemove() {
		super.onRemove();
		registry.detach(handle);
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
			registry: this,
			disposed: false,
		};
		attach(handle);

		// Plant sentinel child: detaches the handle while the root is out of the scene
		final sentinel = new ReloadSentinel(this, handle);
		result.object.addChild(sentinel);

		return handle;
	}

	/** Drop a handle for good: its result was discarded or replaced. */
	public function unregister(handle:ReloadableHandle):Void {
		handle.disposed = true;
		detach(handle);
	}

	/** List a handle (again) unless it was unregistered. Idempotent. */
	public function attach(handle:ReloadableHandle):Void {
		if (handle.disposed)
			return;
		var list = liveObjects.get(handle.sourcePath);
		if (list == null) {
			list = [];
			liveObjects.set(handle.sourcePath, list);
		}
		if (!list.contains(handle))
			list.push(handle);
	}

	/** Take a handle off the list while its root is out of the scene; `attach` brings it back. */
	public function detach(handle:ReloadableHandle):Void {
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
		// Per-key arrays hold one writer per `dynamicRef` site. For the non-collision case
		// (the common one — collisions are a build-time error users see immediately) the array
		// has length 1. For collision cases, snapshot the first writer's params: hot reload is
		// best-effort across pathological dev states, and `restoreDynamicRefs` reapplies the
		// same snapshot to every writer under the key on the way back.
		for (name => arr in result.dynamicRefs) {
			if (arr.length > 0)
				snapshot.set(name, captureParams(arr[0]));
		}
		return snapshot;
	}

	static function capturePlaceholders(result:BuilderResult):PlaceholderSnapshot {
		return result.devCapturedPlaceholders;
	}
}

// ---- StateRestorer ----

class StateRestorer {
	public static function restore(newResult:BuilderResult, snapshot:BuilderResultSnapshot):Void {
		restoreState(newResult, snapshot);
		moveSlotContents(newResult, snapshot);
	}

	/** The part of `restore` that can fail (a `setParameter` rejected by the new build) and moves
	 *  nothing out of the old result: parameters and dynamicRef children's parameters. */
	public static function restoreState(newResult:BuilderResult, snapshot:BuilderResultSnapshot):Void {
		restoreParams(newResult, snapshot.params);
		restoreDynamicRefs(newResult, snapshot.dynamicRefs);
	}

	/** Move the old result's slot contents into the new result's matching slots. Takes the objects
	 *  out of the old result, so it runs last, once nothing else can fail. */
	public static function moveSlotContents(newResult:BuilderResult, snapshot:BuilderResultSnapshot):Void {
		restoreSlots(newResult, snapshot.slots);
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
		// If the result is already in a batch (e.g. a dev callback triggered hot
		// reload from inside a beginUpdate/endUpdate window on this same result),
		// piggyback on the existing batch instead of opening a nested one — a
		// nested beginUpdate would throw `nested_begin_update` and crash the dev
		// session. The outer batch's endUpdate flushes our setParameter calls in
		// its own applyUpdates cycle.
		// Only params whose value differs: a result rebuilt from the snapshot already holds them, and
		// setParameter rejects a param used in an interactive id or a param-dependent repeat body
		// (`untracked_param`) whatever the value.
		final current = result.incrementalContext.snapshotParams();
		final opened = !result.batchMode;
		if (opened) result.beginUpdate();
		for (name => value in params) {
			final now = current.get(name);
			if (now != null && Type.enumEq(now, value))
				continue;
			final dynVal = resolvedToDynamic(value);
			if (dynVal != null)
				result.setParameter(name, dynVal);
		}
		if (opened) result.endUpdate();
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
			final arr = newResult.dynamicRefs.get(name);
			if (arr != null) {
				for (dynRef in arr) restoreParams(dynRef, paramSnap);
			}
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

typedef PlaceholderHome = {object:h2d.Object, parent:Null<h2d.Object>, layer:Int, index:Int, x:Float, y:Float};

class PlaceholderReuser {
	// Delegate to shared HeapsUtils.safeDetach — detaches object from parent
	// without triggering onRemove() cascade that destroys h2d.Graphics content.
	static inline function safeDetach(obj:h2d.Object):Void {
		bh.base.HeapsUtils.safeDetach(obj);
	}

	/** Where each captured placeholder sits now, so a failed rebuild that already borrowed some of
	 *  them (the wrapped callbacks move them into the new tree) can put them back. */
	public static function recordHomes(captured:PlaceholderSnapshot):Array<PlaceholderHome> {
		final homes:Array<PlaceholderHome> = [];
		for (entry in captured) {
			final obj = entry.object;
			final parent = obj.parent;
			var layer = -1;
			var index = -1;
			if (parent != null) {
				if (Std.isOfType(parent, h2d.Layers)) {
					final layers:h2d.Layers = cast parent;
					layer = layers.getChildLayer(obj);
					index = layers.getChildIndexInLayer(obj);
				} else {
					index = parent.getChildIndex(obj);
				}
			}
			homes.push({object: obj, parent: parent, layer: layer, index: index, x: obj.x, y: obj.y});
		}
		return homes;
	}

	/** Put borrowed placeholders back where `recordHomes` found them. */
	public static function putBack(homes:Array<PlaceholderHome>):Void {
		for (home in homes) {
			final parent = home.parent;
			if (parent == null || home.object.parent == parent)
				continue;
			safeDetach(home.object);
			if (Std.isOfType(parent, h2d.Layers))
				(cast parent : h2d.Layers).add(home.object, home.layer, home.index);
			else
				parent.addChildAt(home.object, home.index);
			home.object.setPosition(home.x, home.y);
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

	/** Show a rebuilt root inside the stable root object the game holds, in place of what it showed
	 *  before. The rebuilt tree is kept whole: its incremental context, conditional parents, `@layer`
	 *  order and root-level `$param` tracking all point at `newRoot`, which is now live, so later
	 *  updates and the root's own edited properties reach the screen.
	 *
	 *  `builderRootProps` names the properties the original build set on `stable` itself (non-empty
	 *  only on the first reload of a result, while `stable` is still that build's root). They move to
	 *  `newRoot`, so they are reset on `stable`; what the game set there (position, visibility, other
	 *  transforms) stays. */
	public static function nest(stable:h2d.Object, newRoot:h2d.Object, builderRootProps:Array<String>):Void {
		while (stable.numChildren > 0)
			stable.getChildAt(stable.numChildren - 1).remove();
		for (prop in builderRootProps) {
			switch prop {
				case "scale": stable.setScale(1.0);
				case "rotation": stable.rotation = 0.0;
				case "alpha": stable.alpha = 1.0;
				case "blendMode": stable.blendMode = Alpha;
				case "filter": stable.filter = null;
				default:
			}
		}
		stable.addChild(newRoot);
	}
}
#end
