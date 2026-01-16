package bh.ui.screens;

import hxparse.ParserError;
import hxparse.Unexpected;
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

	public function new(app:hxd.App, ?loader) {
		this.app = app;
		this.loader = loader ?? createLoader();
		this.window = hxd.Window.getInstance();
		this.handler = new ControllerEventHandler(app.s2d, window, this);
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
		return built;
	}

	public function reload(?resource:hxd.res.Resource = null, throwOnError:Bool = true):{
		success:Bool,
		error:Null<String>,
		file:Null<String>,
		pmin:Null<Int>,
		pmax:Null<Int>
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
					pmin: invalidSyntax.pos.pmin,
					pmax: invalidSyntax.pos.pmax,
				}
			}

			if (Std.isOfType(e, MultiAnimUnexpected)) {
				final multiAnimUnexpected = cast(e, MultiAnimUnexpected<Dynamic>);
				return {
					success: false,
					error: multiAnimUnexpected.toString(),
					file: multiAnimUnexpected.pos.psource,
					pmin: multiAnimUnexpected.pos.pmin,
					pmax: multiAnimUnexpected.pos.pmax,
				}
			}

			return {
				success: false,
				error: e.toString(),
				file: null,
				pmin: null,
				pmax: null,
			}
		}

		var reloadedScreenNames = [];

		loader.clearCache();

		for (name => screen in configuredScreens) {
			screen.clear();
			try {
				screen.load();
				failedScreens.remove(name);
			} catch (e) {
				failedScreens[name] = e.toString();
				trace('Failed to reload screen ${name}: ${e}');
				return {
					success: false,
					error: e.toString(),
					file: null,
					pmin: null,
					pmax: null,
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
			pmin: null,
			pmax: null,
		}
	}

	public function addScreen(name:String, screen:UIScreen) {
		if (configuredScreens.exists(name))
			throw 'screen ${name} already exists';
		configuredScreens[name] = screen;
		try {
			screen.load();
			failedScreens.remove(name);
		} catch (e) {
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

		final layerTop = 6;
		final layerMid = 4;
		final layerBot = 2;
		switch mode {
			case None:
				switch newScreenMode {
					case None:

					case Single(single):
						addedScreens = [single => layerMid];
					case MasterAndSingle(master, single):
						addedScreens = [master => layerBot, single => layerMid];
					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerTop];
				}
			case Single(oldSingle):
				switch newScreenMode {
					case None:
						removedScreens = [oldSingle];
					case Single(single):
						if (single != oldSingle) {
							removedScreens = [oldSingle];
							addedScreens = [single => layerMid];
						}
					case MasterAndSingle(master, single):
						if (single != oldSingle) {
							removedScreens = [oldSingle];
							addedScreens = [single => layerMid];
						}
						if (master == oldSingle) throw 'Single -> MasterAndSingle: switching single with master';

					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerTop];
						overrideActiveScreenControllers = [dialog];
				}
			case MasterAndSingle(oldMaster, oldSingle):
				switch newScreenMode {
					case None:
						removedScreens = [oldMaster, oldSingle];
					case Single(single):
						if (oldSingle != single) {
							removedScreens = [oldSingle];
							addedScreens = [single => layerMid];
						}
						if (single == oldMaster)
							throw 'MasterAndSingle -> Single: switching master to single';
						removedScreens.push(oldMaster);

					case MasterAndSingle(master, single):
						removedScreens = [];
						addedScreens = [];
						if (oldMaster != master) {
							removedScreens = [oldMaster];
							addedScreens = [master => layerBot];
						}
						if (oldSingle != single) {
							removedScreens.push(oldSingle);
							addedScreens.set(single, layerMid);
						}
						if (single == oldMaster || master == oldSingle) throw 'MasterAndSingle -> MasterAndSingle: mismatching master/single';
					case Dialog(dialog, caller, previousMode, dialogName):
						addedScreens = [dialog => layerTop];
						overrideActiveScreenControllers = [dialog, oldMaster]; // TODO: optional?
				}

			case Dialog(oldDialog, caller, previousMode, dialogName):
				switch newScreenMode {
					case None:
						removedScreens = [oldDialog];

					case Single(single):
						removedScreens = [oldDialog];
						addedScreens = [single => layerMid];
					case MasterAndSingle(master, single):
						removedScreens = [oldDialog];
						addedScreens = [single => layerMid, master => layerBot];

					case Dialog(dialog, caller, previousMode, dialogName):
						removedScreens = [oldDialog];
						addedScreens = [dialog => layerTop];
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
				screen.onScreenEvent(UIOnControllerEvent(Leaving), null);
				removeScreen(screen);
			}
		if (addedScreens != null) {
			for (screen => layerIndex in addedScreens) {
				final controller = screen.getController();
				addScreen(screen, layerIndex);
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
}
