package wt.ui.screens;
import hxd.res.Resource;
import wt.multianim.MultiAnimBuilder;
import wt.stateanim.AnimParser;
import wt.ui.controllers.UIController;
import wt.ui.screens.UIScreen;
import wt.base.ResourceLoader;
import byte.ByteData;
import sys.io.File;
using wt.base.Atlas2;


private enum ScreenManagerMode {
    None;
    Single(single:UIScreen);
    MasterAndSingle(master:UIScreen, single:UIScreen);
    Dialog(dialog:UIScreen, caller:UIScreen, previousMode:ScreenManagerMode, dialogName:String);
}

@:nullSafety
@:allow(wt.ui.screens.UIScreen)
@:allow(wt.ui.ControllerEventHandler)
class ScreenManager {
    final loader:CachingResourceLoader;
	final handler:ControllerEventHandler;
    var mode:ScreenManagerMode = None;
    var activeScreens(default, null):Array<UIScreen> = [];
    var activeScreenControllers:Array<UIScreen> = [];
    final window:hxd.Window;
    final app:hxd.App;
    final configuredScreens:Map<String, UIScreen> = [];
    var builders:Map<hxd.res.Resource, MultiAnimBuilder> = [];

    public function new(app:hxd.App, ?loader) {
        this.app = app;
        this.loader = loader ?? createLoader();
        this.window = hxd.Window.getInstance();
        this.handler = new ControllerEventHandler(app.s2d, window, this);
    }


    static function createLoader() {
        final loader = new wt.base.ResourceLoader.CachingResourceLoader();
		loader.loadSheet2Impl = sheetName ->{
            return hxd.Res.load('${sheetName}.atlas2').toAtlas2();
		};

        loader.loadSheetImpl = sheetName-> {
            return hxd.Res.loader.loadCache('${sheetName}.atlas', hxd.res.Atlas);
        };
  
		loader.loadHXDResourceImpl = filename -> return hxd.Res.load(filename);
		loader.loadAnimSMImpl = filename -> {
			final byteData = ByteData.ofBytes(File.getBytes(filename)); 
			return AnimParser.parseFile(byteData, loader);

		}
		loader.loadFontImpl = filename -> wt.base.FontManager.getFontByName(filename);

        loader.loadMultiAnimImpl = s -> {
            var r = hxd.Res.load(s);
            if (r == null) throw 'failed to load multianim ${s}';
            final byteData = ByteData.ofBytes(r.entry.getBytes()); 
            return MultiAnimBuilder.load(byteData, loader, s);
        }

        return loader;
    }

    public dynamic function onReload(?resource:hxd.res.Resource) {

    }
    

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

    public function buildFromResource(resource:hxd.res.Resource, enableReload:Bool):MultiAnimBuilder {
        var built = builders.get(resource);
        if (built != null) return built;
        if (enableReload) resource.watch(()->onReload(resource));

        var built = loader.loadMultiAnim(resource.entry.path);
        if (built == null) throw 'failed to load multianim ${resource.name}';
        trace('Built ${resource.entry.name} with reload $enableReload');
        builders.set(resource, built);
        return built;
        
    }



    public function reload(?resource:hxd.res.Resource) {
        
        final oldBuilders = builders.copy();

        builders.clear();
        try {
            for (key => value in oldBuilders) {
                if (resource != null && key != resource) continue;
                trace('rebuild $key => $value');
                buildFromResource(key, true); // TODO: enable reload
            }
        }
        catch (e) {
            trace(e);
            loader.clearCache();
            builders = oldBuilders;
            throw e;
        }


        

        var reloadedScreenNames = [];
        
        loader.clearCache();
        
        for (name => screen in configuredScreens) {
            screen.clear();
            screen.load();
            reloadedScreenNames.push(name);
        }
        updateScreenMode(this.mode);
        trace('reloaded ${reloadedScreenNames.join(",")}');
    }


    public function addScreen(name:String, screen:UIScreen) {
        if (configuredScreens.exists(name)) throw 'screen ${name} already exists';
        configuredScreens[name] = screen;
        return screen;
    }

    public function getScreen(screenName:String):UIScreen {
                
        final screen = configuredScreens[screenName];
        if (screen == null) throw 'screen ${screenName} does not exist';
        return screen;
    }

    public function modalDialog(dialog:UIScreen, caller:UIScreen, dialogName:String) {
        updateScreenMode(Dialog(dialog, caller, mode, dialogName));
    }
 
	public function updateScreenMode(newScreenMode:ScreenManagerMode) {

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
                        addedScreens = [single=>layerMid];
					case MasterAndSingle(master, single):
                        addedScreens = [master=>layerBot, single=>layerMid];
					case Dialog(dialog, caller, previousMode, dialogName):
                        addedScreens = [dialog=>layerTop]; 
				}
			case Single(oldSingle):
                switch newScreenMode {
					case None:
                        removedScreens = [oldSingle];
					case Single(single):
                        if (single != oldSingle) {
                            removedScreens = [single];
                            addedScreens = [single=>layerMid];
                        }
					case MasterAndSingle(master, single):
                        if (single != oldSingle) {
                            removedScreens = [single];
                            addedScreens = [single=>layerMid];
                        }
                        if (master == oldSingle) throw 'Single -> MasterAndSingle: switching single with master';

					case Dialog(dialog, caller, previousMode, dialogName):
                        addedScreens = [dialog=>layerTop]; 
                        overrideActiveScreenControllers = [dialog];
				}
			case MasterAndSingle(oldMaster, oldSingle):
                switch newScreenMode {
                    case None:
                        removedScreens = [oldMaster, oldSingle];
                    case Single(single):
                        if (oldSingle != single) {
                            removedScreens = [oldSingle];
                            addedScreens = [single=>layerMid];
                        }
                        if (single == oldMaster) throw 'MasterAndSingle -> Single: switching master to single';
                        removedScreens.push(oldMaster);

                    case MasterAndSingle(master, single):
                        removedScreens = [];
                        addedScreens = [];
                        if (oldMaster != master) {
                            removedScreens = [oldMaster];
                            addedScreens = [master=>layerBot];
                        }
                        if (oldSingle != single) {
                            removedScreens.push(oldSingle);
                            addedScreens.set(single,layerMid);
                        }
                        if (single == oldMaster || master == oldSingle) throw 'MasterAndSingle -> MasterAndSingle: mismatching master/single';
                    case Dialog(dialog, caller, previousMode, dialogName):
                        addedScreens = [dialog=>layerTop]; 
                        overrideActiveScreenControllers = [dialog, oldMaster]; // TODO: optional?

                }

			case Dialog(oldDialog, caller, previousMode, dialogName):
                
				switch newScreenMode {
					case None:
                        removedScreens = [oldDialog];
                        
					case Single(single):
                        removedScreens = [oldDialog];
                        addedScreens = [single=>layerMid];
					case MasterAndSingle(master, single):
                        removedScreens = [oldDialog];
                        addedScreens = [single=>layerMid, master=>layerBot];

					case Dialog(dialog, caller, previousMode, dialogName):
                        removedScreens = [oldDialog];
                        addedScreens = [dialog=>layerTop];
                        overrideActiveScreenControllers = [dialog]; 
                        final result = dialog.getController().exitResponse;
						caller.onScreenEvent(UIOnControllerEvent(OnDialogResult(dialogName, result)), null);
						removeScreen(dialog);
				}
		}
        if (removedScreens != null) for (screen in removedScreens) {
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

        if (overrideActiveScreenControllers != null) activeScreenControllers = overrideActiveScreenControllers;
        
		mode = newScreenMode;
        
	}


}