package bh.ui.screens;

import hxd.fs.BytesFileSystem.BytesFileEntry;
import hxd.res.Resource;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser.InvalidSyntax;
import bh.multianim.MultiAnimParser.MultiAnimUnexpected;
import bh.multianim.MultiAnimParser.MPToken;
import bh.stateanim.AnimParser;
import bh.ui.controllers.UIController;
import bh.ui.screens.UIScreen;
import bh.base.ResourceLoader;
import byte.ByteData;
import haxe.io.Bytes;
#if hl
import sys.io.File;
#end
#if js
import haxe.Http;
#end

using bh.base.Atlas2;

#if js
@:native("FileLoader")
extern class FileLoader {
	public static function load(url:String):js.lib.ArrayBuffer;
}
#end

private enum ScreenManagerMode {
	None;
	Single(single:UIScreen);
	MasterAndSingle(master:UIScreen, single:UIScreen);
	Dialog(dialog:UIScreen, caller:UIScreen, previousMode:ScreenManagerMode, dialogName:String);
}

@:nullSafety
@:allow(bh.ui.screens.UIScreen)
@:allow(bh.ui.ControllerEventHandler)
class ScreenManager {
	final loader:CachingResourceLoader;
	final handler:ControllerEventHandler;
	var mode:ScreenManagerMode = None;
	var activeScreens(default, null):Array<UIScreen> = [];
	var activeScreenControllers:Array<UIScreen> = [];
	final window:hxd.Window;
	final app:hxd.App;
	final configuredScreens:Map<String, UIScreen> = [];
	final failedScreens:Map<String, String> = [];
	var builders:Map<hxd.res.Resource, MultiAnimBuilder> = [];
	#if MULTIANIM_DEV
	var hotReloadRegistry:bh.multianim.dev.HotReload.ReloadableRegistry = new bh.multianim.dev.HotReload.ReloadableRegistry();
	var fileChangeDetector:bh.multianim.dev.HotReload.FileChangeDetector = new bh.multianim.dev.HotReload.FileChangeDetector();
	var reloadListeners:Array<bh.multianim.dev.HotReload.ReloadListener> = [];
	var builderConsumers:Array<bh.multianim.dev.HotReload.IBuilderConsumer> = [];
	var screenSourceMap:Map<String, Array<UIScreen>> = []; // resource path → screens that loaded it
	var currentlyLoadingScreen:Null<UIScreen> = null;
	#end

	public function new(app:hxd.App, ?loader) {
		this.app = app;
		this.loader = loader ?? createLoader();
		this.window = hxd.Window.getInstance();
		this.handler = new ControllerEventHandler(app.s2d, window, this);
		#if MULTIANIM_DEV
		this.loader.hotReloadRegistry = hotReloadRegistry;
		this.loader.fileChangeDetector = fileChangeDetector;
		this.onReload = (?resource) -> {
			hotReload(resource);
		};
		#end
	}

	static function createLoader() {
		final loader = new bh.base.ResourceLoader.CachingResourceLoader();

		loader.loadSheet2Impl = sheetName -> {
			#if hl
			return hxd.Res.load('${sheetName}.atlas2').toAtlas2();
			#elseif js
			var resourceName = '${sheetName}.atlas2';
			if (hxd.Res.loader.exists(resourceName)) {
				return hxd.Res.load(resourceName).toAtlas2();
			} else {
				var bytes = FileLoader.load(resourceName);
				var resource = hxd.res.Any.fromBytes(resourceName, Bytes.ofData(bytes));
				return resource.toAtlas2();
			}
			#else
			throw 'loadSheet2Impl not implemented for this target';
			#end
		};

		loader.loadSheetImpl = sheetName -> {
			#if hl
			return hxd.Res.loader.loadCache('${sheetName}.atlas', hxd.res.Atlas);
			#elseif js
			var resourceName = '${sheetName}.atlas';
			if (hxd.Res.loader.exists(resourceName)) {
				return hxd.Res.loader.loadCache(resourceName, hxd.res.Atlas);
			} else {
				var bytes = FileLoader.load(resourceName);
				var resource = hxd.res.Any.fromBytes(resourceName, Bytes.ofData(bytes));
				return resource.to(hxd.res.Atlas);
			}
			#else
			throw 'loadSheetImpl not implemented for this target';
			#end
		};

		loader.loadHXDResourceImpl = filename -> {
			#if hl
			return hxd.Res.load(filename);
			#elseif js
			if (hxd.Res.loader.exists(filename)) {
				return hxd.Res.load(filename);
			} else {
				var bytes = FileLoader.load(filename);
				return hxd.res.Any.fromBytes(filename, Bytes.ofData(bytes));
			}
			#else
			throw 'loadHXDResourceImpl not implemented for this target';
			#end
		};

		loader.loadAnimSMImpl = filename -> {
			var byteData:ByteData;
			#if hl
			byteData = ByteData.ofBytes(File.getBytes(filename));
			#elseif js
			// Use external JavaScript class to load file
			var bytes = FileLoader.load(filename);
			byteData = ByteData.ofBytes(Bytes.ofData(bytes));
			#else
			throw 'loadAnimSMImpl not implemented for this target - filename: $filename';
			#end
			return AnimParser.parseFile(byteData, filename, loader);
		}

		loader.loadFontImpl = filename -> bh.base.FontManager.getFontByName(filename);

		loader.loadMultiAnimImpl = s -> {
			var byteData:ByteData;
			#if hl
			var r = hxd.Res.load(s);
			if (r == null)
				throw 'failed to load multianim ${s}';
			byteData = ByteData.ofBytes(r.entry.getBytes());
			#elseif js
			if (hxd.Res.loader.exists(s)) {
				var r = hxd.Res.load(s);
				if (r == null)
					throw 'failed to load multianim ${s}';
				byteData = ByteData.ofBytes(r.entry.getBytes());
			} else {
				var bytes = FileLoader.load(s);
				byteData = ByteData.ofBytes(Bytes.ofData(bytes));
			}
			#else
			throw 'loadMultiAnimImpl not implemented for this target';
			#end
			return MultiAnimBuilder.load(byteData, loader, s);
		}

		return loader;
	}

	public dynamic function onReload(?resource:hxd.res.Resource) {}

	public function update(dt:Float):Void {
		for (screen in activeScreens) {
			final result = screen.getController().update(dt);
			switch result {
				case UIControllerRunning:
				case UIControllerFinished(result):
					switch mode {
						case Dialog(dialog, caller, previousMode, dialogName):
							caller.onScreenEvent(UIOnControllerEvent(OnDialogResult(dialogName, result)), null);
							updateScreenMode(previousMode);
						default: throw 'unhandled exit $result code in $mode';
					}
			}
			screen.update(dt);
		}
	}

	public function buildFromResourceName(resourceName:String, enableReload:Bool):MultiAnimBuilder {
		final resource = this.loader.loadHXDResource(resourceName);
		return buildFromResource(resource, enableReload);
	}

	public function buildFromResource(resource:hxd.res.Resource, enableReload:Bool):MultiAnimBuilder {
		var built = builders.get(resource);
		if (built != null)
			return built;
		if (enableReload)
			resource.watch(() -> onReload(resource));

		var built = loader.loadMultiAnim(resource.entry.path);
		if (built == null)
			throw 'failed to load multianim ${resource.name}';
		#if MULTIANIM_TRACE
		trace('Built ${resource.entry.name} with reload $enableReload');
		#end
		builders.set(resource, built);
		#if MULTIANIM_DEV
		try {
			#if hl
			final content = resource.entry.getBytes().toString();
			fileChangeDetector.storeInitialHash(resource.entry.path, content);
			#end
		} catch (_) {}
		if (currentlyLoadingScreen != null) {
			final path = resource.entry.path;
			var list = screenSourceMap.get(path);
			if (list == null) {
				list = [];
				screenSourceMap.set(path, list);
			}
			if (!list.contains(currentlyLoadingScreen))
				list.push(currentlyLoadingScreen);
		}
		#end
		return built;
	}

	public function reload(?resource:hxd.res.Resource = null, throwOnError:Bool = true):{
		success:Bool,
		error:Null<String>,
		file:Null<String>,
		line:Null<Int>,
		col:Null<Int>
	} {
		final oldBuilders = builders.copy();
		builders.clear();
		try {
			for (key => value in oldBuilders) {
				if (resource != null && key != resource)
					continue;
				#if MULTIANIM_TRACE
				trace('rebuild $key'); // don't trace $value, js gets stack overflow
				#end
				buildFromResource(key, true); // TODO: enable reload
			}
		} catch (e) {
			trace(e);
			loader.clearCache();
			builders = oldBuilders;
			if (throwOnError)
				throw e;

			if (Std.isOfType(e, InvalidSyntax)) {
				final invalidSyntax = cast(e, InvalidSyntax);
				return {
					success: false,
					error: invalidSyntax.toString(),
					file: invalidSyntax.pos.psource,
					line: invalidSyntax.pos.line,
					col: invalidSyntax.pos.col,
				}
			}

			if (Std.isOfType(e, MultiAnimUnexpected)) {
				final multiAnimUnexpected = cast(e, MultiAnimUnexpected<Dynamic>);
				return {
					success: false,
					error: multiAnimUnexpected.toString(),
					file: multiAnimUnexpected.pos.psource,
					line: multiAnimUnexpected.pos.line,
					col: multiAnimUnexpected.pos.col,
				}
			}

			return {
				success: false,
				error: e.toString(),
				file: null,
				line: null,
				col: null,
			}
		}

		var reloadedScreenNames = [];

		loader.clearCache();

		for (name => screen in configuredScreens) {
			screen.clear();
			try {
				#if MULTIANIM_DEV
				clearScreenFromSourceMap(screen);
				currentlyLoadingScreen = screen;
				#end
				screen.load();
				#if MULTIANIM_DEV
				currentlyLoadingScreen = null;
				#end
				failedScreens.remove(name);
			} catch (e) {
				#if MULTIANIM_DEV
				currentlyLoadingScreen = null;
				#end
				failedScreens[name] = e.toString();
				trace('Failed to reload screen ${name}: ${e}');
				return {
					success: false,
					error: e.toString(),
					file: null,
					line: null,
					col: null,
				}
			}
			reloadedScreenNames.push(name);
		}
		updateScreenMode(this.mode);
		#if MULTIANIM_TRACE
		trace('reloaded ${reloadedScreenNames.join(",")}');
		#end
		return {
			success: true,
			error: null,
			file: null,
			line: null,
			col: null,
		}
	}

	public function addScreen(name:String, screen:UIScreen) {
		if (configuredScreens.exists(name))
			throw 'screen ${name} already exists';
		configuredScreens[name] = screen;
		try {
			#if MULTIANIM_DEV
			currentlyLoadingScreen = screen;
			#end
			screen.load();
			#if MULTIANIM_DEV
			currentlyLoadingScreen = null;
			#end
			failedScreens.remove(name);
		} catch (e) {
			#if MULTIANIM_DEV
			currentlyLoadingScreen = null;
			#end
			failedScreens[name] = e.toString();
			trace('Failed to load screen ${name}: ${e}');
		}
		return screen;
	}

	public function getScreen(screenName:String):UIScreen {
		final screen = configuredScreens[screenName];
		if (screen == null)
			throw 'screen ${screenName} does not exist';
		return screen;
	}

	public function isScreenFailed(screen:UIScreen):Bool {
		return getScreenFailedError(screen) != null;
	}

	public function getScreenFailedError(screen:UIScreen):Null<String> {
		for (name => s in configuredScreens) {
			if (s == screen) {
				return failedScreens.get(name);
			}
		}
		return null;
	}

	function assertScreenNotFailed(screen:UIScreen) {
		final error = getScreenFailedError(screen);
		if (error != null) {
			for (name => s in configuredScreens) {
				if (s == screen) {
					throw 'cannot activate failed screen "${name}": ${error}';
				}
			}
		}
	}

	public function modalDialog(dialog:UIScreen, caller:UIScreen, dialogName:String) {
		dialog.load();
		updateScreenMode(Dialog(dialog, caller, mode, dialogName));
	}

	public function updateScreenMode(newScreenMode:ScreenManagerMode) {
		// Validate that no failed screens are being activated
		switch newScreenMode {
			case None:
			case Single(single):
				assertScreenNotFailed(single);
			case MasterAndSingle(master, single):
				assertScreenNotFailed(master);
				assertScreenNotFailed(single);
			case Dialog(dialog, caller, previousMode, dialogName):
				assertScreenNotFailed(dialog);
		}

		function addScreen(newScreen, layer) {
			app.s2d.add(newScreen.getSceneRoot(), layer);
			this.activeScreens.push(newScreen);
		}
		function removeScreen(screen:UIScreen) {
			this.activeScreens.remove(screen);
			screen.getSceneRoot().remove();
		}

		var addedScreens:Null<Map<UIScreen, Int>> = null;
		var removedScreens:Null<Array<UIScreen>> = null;
		var overrideActiveScreenControllers:Null<Array<UIScreen>> = null;

		// Global scene layer indices (added to app.s2d)
		// layerContent: main game screen (e.g. CombatScreen) - bottom
		// layerMaster: persistent overlay screen (e.g. top bar) - above content
		// layerDialog: modal dialog screens - above everything
		final layerContent = 2;
		final layerMaster = 4;
		final layerDialog = 6;
		switch mode {
			case None:
				switch newScreenMode {
					case None:

					case Single(single):
						addedScreens = [single => layerContent];
					case MasterAndSingle(master, single):
						addedScreens = [master => layerMaster, single => layerContent];
					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerDialog];
				}
			case Single(oldSingle):
				switch newScreenMode {
					case None:
						removedScreens = [oldSingle];
					case Single(single):
						if (single != oldSingle) {
							removedScreens = [oldSingle];
							addedScreens = [single => layerContent];
						}
					case MasterAndSingle(master, single):
						if (master == oldSingle) throw 'Single -> MasterAndSingle: switching single with master';
						removedScreens = [];
						addedScreens = [master => layerMaster];
						if (single != oldSingle) {
							removedScreens.push(oldSingle);
							addedScreens.set(single, layerContent);
						}

					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerDialog];
						overrideActiveScreenControllers = [dialog];
				}
			case MasterAndSingle(oldMaster, oldSingle):
				switch newScreenMode {
					case None:
						removedScreens = [oldMaster, oldSingle];
					case Single(single):
						if (oldSingle != single) {
							removedScreens = [oldSingle];
							addedScreens = [single => layerContent];
						}
						if (single == oldMaster)
							throw 'MasterAndSingle -> Single: switching master to single';
						removedScreens.push(oldMaster);

					case MasterAndSingle(master, single):
						removedScreens = [];
						addedScreens = [];
						if (oldMaster != master) {
							removedScreens = [oldMaster];
							addedScreens = [master => layerMaster];
						}
						if (oldSingle != single) {
							removedScreens.push(oldSingle);
							addedScreens.set(single, layerContent);
						}
						if (single == oldMaster || master == oldSingle) throw 'MasterAndSingle -> MasterAndSingle: mismatching master/single';
					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerDialog];
						overrideActiveScreenControllers = [dialog, oldMaster]; // TODO: optional?
				}

			case Dialog(oldDialog, caller, previousMode, dialogName):
				switch newScreenMode {
					case None:
						removedScreens = [oldDialog];

					case Single(single):
						removedScreens = [oldDialog];
						addedScreens = [single => layerContent];
					case MasterAndSingle(master, single):
						removedScreens = [oldDialog];
						addedScreens = [single => layerContent, master => layerMaster];

					case Dialog(dialog, caller, previousMode, dialogName):
						removedScreens = [oldDialog];
						addedScreens = [dialog => layerDialog];
						overrideActiveScreenControllers = [dialog];
						final result = dialog.getController().exitResponse;
						caller.onScreenEvent(UIOnControllerEvent(OnDialogResult(dialogName, result)), null);
						removeScreen(dialog);
				}
		}
		if (removedScreens != null)
			for (screen in removedScreens) {
				screen.getController().lifecycleEvent(LifecycleControllerFinished);
				this.activeScreenControllers.remove(screen);
				screen.onScreenEvent(UILeaving, null);
				screen.onScreenEvent(UIOnControllerEvent(Leaving), null);
				removeScreen(screen);
			}
		if (addedScreens != null) {
			for (screen => layerIndex in addedScreens) {
				final controller = screen.getController();
				addScreen(screen, layerIndex);
				screen.onScreenEvent(UIEntering, null);
				screen.onScreenEvent(UIOnControllerEvent(Entering), null);
				controller.lifecycleEvent(LifecycleControllerStarted);
				if (overrideActiveScreenControllers == null) {
					this.activeScreenControllers.push(screen);
				}
			}
		}

		if (overrideActiveScreenControllers != null)
			activeScreenControllers = overrideActiveScreenControllers;

		mode = newScreenMode;
	}

	#if MULTIANIM_DEV
	@:nullSafety(Off)
	public function hotReload(?resource:hxd.res.Resource):bh.multianim.dev.HotReload.ReloadReport {
		final startTime = haxe.Timer.stamp();

		// Determine which files to process
		var filesToProcess:Array<{resource:hxd.res.Resource, path:String}> = [];
		for (key => _ in builders) {
			if (resource != null && key != resource)
				continue;
			filesToProcess.push({resource: key, path: key.entry.path});
		}

		var lastReport:Null<bh.multianim.dev.HotReload.ReloadReport> = null;

		for (fileEntry in filesToProcess) {
			final path = fileEntry.path;

			// 1. Read file content via Heaps entry (uses absolute path internally)
			#if hl
			var content:String;
			try {
				content = fileEntry.resource.entry.getBytes().toString();
			} catch (_) {
				continue;
			}

			// 2. Content hash check — skip if unchanged
			if (!fileChangeDetector.hasChanged(path, content))
				continue;

			// 3. Notify ReloadStarted
			notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadStarted(path, bh.multianim.dev.HotReload.ReloadFileType.Manim));

			// 4. Try re-parse
			var newBuilder:MultiAnimBuilder;
			try {
				final byteData = ByteData.ofString(content);
				newBuilder = MultiAnimBuilder.load(byteData, loader, path);
			} catch (e) {
				final report = makeHotReloadFailReport(path, e);
				notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadFailed(report));
				lastReport = report;
				continue;
			}

			// 5. Signature check for each live handle
			final handles = hotReloadRegistry.getHandles(path);
			final oldBuilder = builders.get(fileEntry.resource);
			var needsRestart:Null<String> = null;
			var paramsAdded:Array<String> = [];

			if (oldBuilder != null) {
				for (handle in handles) {
					final oldDefs = oldBuilder.getParameterDefinitions(handle.programmableName);
					final newDefs = newBuilder.getParameterDefinitions(handle.programmableName);
					final restartReason = bh.multianim.dev.HotReload.SignatureChecker.check(oldDefs, newDefs);
					if (restartReason != null) {
						needsRestart = restartReason;
						break;
					}
					for (added in bh.multianim.dev.HotReload.SignatureChecker.getAddedParams(oldDefs, newDefs))
						if (!paramsAdded.contains(added))
							paramsAdded.push(added);
				}
			}

			if (needsRestart != null) {
				final restartMsg:String = needsRestart;
				final report:bh.multianim.dev.HotReload.ReloadReport = {
					success: false,
					file: path,
					fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
					programmablesRebuilt: [],
					paramsAdded: [],
					needsFullRestart: restartMsg,
					errors: [{
						message: restartMsg,
						file: path,
						line: 0,
						col: 0,
						errorType: bh.multianim.dev.HotReload.ReloadErrorType.SignatureIncompatible,
						context: null,
					}],
					rebuiltCount: 0,
					elapsedMs: 0,
				};
				notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadNeedsRestart(report));
				lastReport = report;
				continue;
			}

			// 6. Replace cached builder
			builders.set(fileEntry.resource, newBuilder);
			loader.replaceMultiAnim(path, newBuilder);

			// 7. Update content hash
			fileChangeDetector.updateHash(path, content);

			// 8. Notify transient-build consumers
			for (consumer in builderConsumers)
				consumer.onBuilderReplaced(path, newBuilder);

			// 9. Determine reload strategy: per-file nuclear for screens, in-place for non-screen handles
			final screensForFile = screenSourceMap.get(path);
			final hasScreens = screensForFile != null && screensForFile.length > 0;

			if (hasScreens) {
				// Per-file nuclear: clear + reload only affected screens
				trace('[HotReload] Reloading ${screensForFile.length} screen(s) for ${path}');

				// Unregister all handles for this path to prevent stale sentinel firing during clear
				for (handle in handles)
					hotReloadRegistry.unregister(handle);

				loader.clearCache();
				var screenErrors:Array<bh.multianim.dev.HotReload.ReloadError> = [];
				for (screen in screensForFile) {
					for (name => s in configuredScreens) {
						if (s == screen) {
							screen.clear();
							clearScreenFromSourceMap(screen);
							currentlyLoadingScreen = screen;
							try {
								screen.load();
								failedScreens.remove(name);
							} catch (e) {
								failedScreens[name] = e.toString();
								trace('[HotReload] Failed to reload screen ${name}: ${e}');
								screenErrors.push(makeHotReloadFailError(path, 'screen:${name}', e));
							}
							currentlyLoadingScreen = null;
							break;
						}
					}
				}
				updateScreenMode(this.mode);

				final elapsed = (haxe.Timer.stamp() - startTime) * 1000;
				lastReport = {
					success: screenErrors.length == 0,
					file: path,
					fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
					programmablesRebuilt: [],
					paramsAdded: paramsAdded,
					needsFullRestart: null,
					errors: screenErrors,
					rebuiltCount: 0,
					elapsedMs: elapsed,
				};
				notifyReloadListeners(screenErrors.length == 0
					? bh.multianim.dev.HotReload.ReloadEvent.ReloadSucceeded(lastReport)
					: bh.multianim.dev.HotReload.ReloadEvent.ReloadFailed(lastReport));
				continue;
			}

			if (handles.length == 0) {
				// No screens and no handles: transient builds only, builder already replaced
				trace('[HotReload] Builder replaced for ${path} (no screens or handles)');
				final elapsed = (haxe.Timer.stamp() - startTime) * 1000;
				lastReport = {
					success: true,
					file: path,
					fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
					programmablesRebuilt: [],
					paramsAdded: paramsAdded,
					needsFullRestart: null,
					errors: [],
					rebuiltCount: 0,
					elapsedMs: elapsed,
				};
				notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadSucceeded(lastReport));
				continue;
			}

			// 10. In-place rebuild for non-screen incremental handles
			final rebuiltNames:Array<String> = [];
			var buildErrors:Array<bh.multianim.dev.HotReload.ReloadError> = [];
			var pendingCallbacks:Array<bh.multianim.dev.HotReload.ReloadReport->Void> = [];

			for (handle in handles) {
				final oldResult = handle.result;

				// Snapshot state
				final snapshot = bh.multianim.dev.HotReload.StateSnapshotter.capture(oldResult);

				// Detach slot contents so they can be reparented
				bh.multianim.dev.HotReload.StateRestorer.detachSlots(oldResult);

				// Remove old sentinel to prevent stale auto-unregister during swap
				bh.multianim.dev.HotReload.ReloadableRegistry.removeSentinel(oldResult.object);
				hotReloadRegistry.unregister(handle);

				// Try rebuild with new builder, preserving original builderParams
				var newResult:BuilderResult;
				final oldBuilderParams = oldResult.incrementalContext != null ? oldResult.incrementalContext.getBuilderParams() : null;
				try {
					newResult = newBuilder.buildWithParameters(
						handle.programmableName,
						bh.multianim.dev.HotReload.StateRestorer.snapshotToInputMap(snapshot.params),
						oldBuilderParams,
						null,
						true
					);
				} catch (e) {
					buildErrors.push(makeHotReloadFailError(path, handle.programmableName, e));
					continue;
				}

				// Restore snapshot into new result
				bh.multianim.dev.HotReload.StateRestorer.restore(newResult, snapshot);

				// The new result auto-registered itself — unregister it and
				// remove its sentinel before we move children.
				if (newResult.reloadHandle != null) {
					bh.multianim.dev.HotReload.ReloadableRegistry.removeSentinel(newResult.object);
					hotReloadRegistry.unregister(newResult.reloadHandle);
				}

				// Replace children of stable root with rebuilt children.
				// oldResult.object stays in the scene — game references remain valid.
				bh.multianim.dev.HotReload.SceneSwapper.replaceChildren(oldResult.object, newResult.object);

				// Adopt non-scene internals (incrementalContext, names, slots, etc.)
				// but keep oldResult.object unchanged — it's the stable scene node.
				final stableObject = oldResult.object;
				oldResult.adoptFrom(newResult);
				oldResult.object = stableObject;

				// Re-register the stable result (plants sentinel on oldResult.object)
				oldResult.reloadHandle = hotReloadRegistry.register(path, oldResult, handle.programmableName);

				// Fire onReload callback if set (for any extra game-side bookkeeping)
				final reloadCb = oldResult.onReload;
				if (reloadCb != null) {
					final stableResult = oldResult;
					pendingCallbacks.push((report) -> {
						try {
							reloadCb(stableResult, report);
						} catch (cbError) {
							trace('[HotReload] onReload callback threw: ${cbError}');
						}
					});
				}

				rebuiltNames.push(handle.programmableName);
			}

			final elapsed = (haxe.Timer.stamp() - startTime) * 1000;
			lastReport = {
				success: buildErrors.length == 0,
				file: path,
				fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
				programmablesRebuilt: rebuiltNames,
				paramsAdded: paramsAdded,
				needsFullRestart: null,
				errors: buildErrors,
				rebuiltCount: rebuiltNames.length,
				elapsedMs: elapsed,
			};

			// Fire deferred onReload callbacks with final report
			for (cb in pendingCallbacks)
				cb(lastReport);

			if (lastReport.success)
				notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadSucceeded(lastReport));
			else
				notifyReloadListeners(bh.multianim.dev.HotReload.ReloadEvent.ReloadFailed(lastReport));
			#end // hl
		}

		if (lastReport == null)
			lastReport = {
				success: true,
				file: "",
				fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
				programmablesRebuilt: [],
				paramsAdded: [],
				needsFullRestart: null,
				errors: [],
				rebuiltCount: 0,
				elapsedMs: 0,
			};

		return lastReport;
	}

	public function addReloadListener(listener:bh.multianim.dev.HotReload.ReloadListener):Void {
		reloadListeners.push(listener);
	}

	public function removeReloadListener(listener:bh.multianim.dev.HotReload.ReloadListener):Void {
		reloadListeners.remove(listener);
	}

	public function addBuilderConsumer(consumer:bh.multianim.dev.HotReload.IBuilderConsumer):Void {
		builderConsumers.push(consumer);
	}

	public function removeBuilderConsumer(consumer:bh.multianim.dev.HotReload.IBuilderConsumer):Void {
		builderConsumers.remove(consumer);
	}

	function notifyReloadListeners(event:bh.multianim.dev.HotReload.ReloadEvent):Void {
		for (l in reloadListeners)
			l(event);
	}

	@:nullSafety(Off)
	function makeHotReloadFailError(path:String, context:String, e:Dynamic):bh.multianim.dev.HotReload.ReloadError {
		if (Std.isOfType(e, InvalidSyntax)) {
			final ex = cast(e, InvalidSyntax);
			return {
				message: ex.toString(),
				file: ex.pos.psource,
				line: ex.pos.line,
				col: ex.pos.col,
				errorType: bh.multianim.dev.HotReload.ReloadErrorType.ParseError,
				context: context,
			};
		} else if (Std.isOfType(e, MultiAnimUnexpected)) {
			final ex:MultiAnimUnexpected<Dynamic> = cast e;
			return {
				message: ex.toString(),
				file: ex.pos.psource,
				line: ex.pos.line,
				col: ex.pos.col,
				errorType: bh.multianim.dev.HotReload.ReloadErrorType.ParseError,
				context: context,
			};
		} else {
			final ex = Std.downcast(e, haxe.Exception);
			final msg = ex != null ? '${ex.message}\n${ex.stack}' : Std.string(e);
			return {
				message: msg,
				file: path,
				line: 0,
				col: 0,
				errorType: bh.multianim.dev.HotReload.ReloadErrorType.BuildError,
				context: context,
			};
		}
	}

	@:nullSafety(Off)
	function makeHotReloadFailReport(path:String, e:Dynamic):bh.multianim.dev.HotReload.ReloadReport {
		return {
			success: false,
			file: path,
			fileType: bh.multianim.dev.HotReload.ReloadFileType.Manim,
			programmablesRebuilt: [],
			paramsAdded: [],
			needsFullRestart: null,
			errors: [makeHotReloadFailError(path, "parse", e)],
			rebuiltCount: 0,
			elapsedMs: 0,
		};
	}

	function clearScreenFromSourceMap(screen:UIScreen):Void {
		for (path => list in screenSourceMap) {
			list.remove(screen);
			if (list.length == 0)
				screenSourceMap.remove(path);
		}
	}
	#end
}
