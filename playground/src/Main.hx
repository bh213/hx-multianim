import screens.*;
import bh.ui.screens.ScreenManager;
import hxd.Key;
import bh.base.FontManager;
import bh.base.ResourceLoader;
import bh.stateanim.AnimParser;
import bh.multianim.MultiAnimBuilder;
import byte.ByteData;
import haxe.io.Bytes;
import h2d.Tile;

using StringTools;
using bh.base.Atlas2;

@:expose("PlaygroundMain")
class Main extends hxd.App {
	public static var defaultScreen:String = "stateAnim";
	public static var instance:Main = null;
	var errorText:h2d.Text;

	var screenManager:ScreenManager;

	function getFont() {
		return hxd.res.DefaultFont.get();
	}

	function error(text:String) {
		errorText.remove();
		errorText.text = text;
		s2d.add(errorText, 100);
		errorText.setPosition(30,30);
	}

	

	public function reload(?screen:String) {
		trace('haxe Reloading with screen: $screen');
			
			final res = screenManager.reload(null, false);
			if (!res.success) {
				trace('error loading main: ${res.error}');
				error('Error loading screen: ${res.error}');
				return res;
			}
			errorText.remove();
			screenManager.updateScreenMode(Single(screenManager.getScreen(screen ?? "particles")));
			return res;
	}

	override function init() {
		
		#if hl
			hxd.Res.initLocal();
			hxd.res.Resource.LIVE_UPDATE = true;
		#elseif js
			hxd.Res.initEmbed();
			
		#end

		// Register all fonts
		FontManager.registerFont("default", hxd.res.DefaultFont.get());
		FontManager.registerFont("m3x6", hxd.Res.fonts.m3x6.toFont());
		FontManager.registerFont("pixeled6", hxd.Res.fonts.pixeled_6.toFont());
		FontManager.registerFont("cnc_inet_12", hxd.Res.fonts.cnc_inet_12.toFont());
		FontManager.registerFont("m5x7", hxd.Res.fonts.m5x7.toFont());
		FontManager.registerFont("f7x5", hxd.Res.fonts.code_7x5_regular_6.toFont());
		FontManager.registerFont("m6x11", hxd.Res.fonts.m6x11.toFont());
		FontManager.registerFont("dd_thin", hxd.Res.fonts.digitaldisco_thin.toFont());
		FontManager.registerFont("dd", hxd.Res.fonts.digitaldisco.toFont());
		FontManager.registerFont("pixellari", hxd.Res.fonts.pixellari.toFont());
		
		// Register SDF fonts
		FontManager.registerFont("kreon_12", hxd.Res.fonts.kreon_30.toSdfFont(12, 3, 0.5, 0.1));
		FontManager.registerFont("kreon_16", hxd.Res.fonts.kreon_30.toSdfFont(16, 3, 0.5, 0.1));
		FontManager.registerFont("kreon_24", hxd.Res.fonts.kreon_30.toSdfFont(24, 3, 0.5, 0.1));
		FontManager.registerFont("kreon_30", hxd.Res.fonts.kreon_30.toSdfFont(30, 3, 0.55, 0.1));
		
		FontManager.registerFont("exo2_14", hxd.Res.fonts.exo2_30.toSdfFont(14, 3, 0.5, 2/32));
		FontManager.registerFont("exo2_16", hxd.Res.fonts.exo2_30.toSdfFont(16, 3, 0.5, 2/32));
		FontManager.registerFont("exo2_20", hxd.Res.fonts.exo2_30.toSdfFont(20, 3, 0.5, 2/32));
		FontManager.registerFont("exo2_30", hxd.Res.fonts.exo2_30.toSdfFont(30, 3, 0.5, 2/32));
		
		FontManager.registerFont("exo2_light_12", hxd.Res.fonts.exo2_light_30.toSdfFont(12, 3, 0.5, 0.1));
		FontManager.registerFont("exo2_light_14", hxd.Res.fonts.exo2_light_30.toSdfFont(14, 3, 0.5, 0.1));
		FontManager.registerFont("exo2_light_20", hxd.Res.fonts.exo2_light_30.toSdfFont(20, 3, 0.5, 0.05));
		FontManager.registerFont("exo2_light_30", hxd.Res.fonts.exo2_light_30.toSdfFont(30, 3, 0.5, 0.05));
		
		FontManager.registerFont("exo2_black_12", hxd.Res.fonts.exo2_black_30.toSdfFont(12, 3, 0.5, 0.1));
		FontManager.registerFont("exo2_black_16", hxd.Res.fonts.exo2_black_30.toSdfFont(16, 3, 0.5, 0.1));
		FontManager.registerFont("exo2_black_20", hxd.Res.fonts.exo2_black_30.toSdfFont(20, 3, 0.5, 0.1));
		FontManager.registerFont("exo2_black_30", hxd.Res.fonts.exo2_black_30.toSdfFont(30, 3, 0.5, 0.1));
		
		FontManager.registerFont("open_sans_12", hxd.Res.fonts.open_sans_30.toSdfFont(12, 3, 0.45, 0.1));
		FontManager.registerFont("open_sans_16", hxd.Res.fonts.open_sans_30.toSdfFont(16, 3, 0.45, 0.1));
		FontManager.registerFont("open_sans_20", hxd.Res.fonts.open_sans_30.toSdfFont(20, 3, 0.45, 0.1));
		FontManager.registerFont("open_sans_30", hxd.Res.fonts.open_sans_30.toSdfFont(30, 3, 0.45, 0.1));

		errorText = new h2d.Text(getFont());
		errorText.textColor = 0xFFFF8080;
		errorText.setScale(2);
		errorText.maxWidth = 1280/2;
		errorText.dropShadow = {
			dx: 1,
			dy:1,
			alpha: 0.5,
			color: 0
		};

		screenManager = new ScreenManager(this, createJSLoader());
		screenManager.onReload = (?res)->{
			// Don't call reload() again to prevent infinite recursion
			// Just update the error text if needed
			if (errorText != null) {
				errorText.remove();
			}
		};
		screenManager.addScreen("components", new screens.ComponentsTestScreen(screenManager));
		screenManager.addScreen("slider", new screens.SliderTestScreen(screenManager));
		screenManager.addScreen("checkbox", new screens.CheckboxTestScreen(screenManager));
		screenManager.addScreen("button", new screens.ButtonTestScreen(screenManager));
		screenManager.addScreen("scrollableList", new screens.ScrollableListTestScreen(screenManager));
		screenManager.addScreen("dialogStart", new DialogStartScreen(screenManager));
		screenManager.addScreen("stateAnim", new screens.StateAnimScreen(screenManager));
		#if hl
		screenManager.addScreen("settings", new SettingsScreen(screenManager));
		#end
		
		screenManager.addScreen("room1", new screens.Room1Screen(screenManager));
		
		screenManager.addScreen("examples1", new Examples1Screen(screenManager));

		screenManager.addScreen("paths", new PathsScreen(screenManager));
		screenManager.addScreen("particles", new ParticlesScreen(screenManager));
		screenManager.addScreen("fonts", new FontsScreen(screenManager));
		screenManager.addScreen("atlasTest", new screens.AtlasTestScreen(screenManager));
		
	
		

		// screenManager.updateScreenMode(MasterAndSingle(masterScreen, screenManager.getScreen("main")));
//		screenManager.gotoScreen(NormalStage, "dialog1");
		// screenManager.gotoScreen(NormalStage, "room1");
		

		 final window = hxd.Window.getInstance();
		 window.resize(1280, 720);
		// window.displayMode = Windowed;
		s2d.scaleMode = AutoZoom(1280, 720, true);
		
		//window.resize(1280, 720);

		// window.currentMonitorIndex = 1;
		window.addEventTarget(event -> {
			switch event.kind {
				case EKeyDown if (event.keyCode == Key.Q): 
					#if hl
					Sys.exit(0);
					#end
				case EKeyDown if (event.keyCode == Key.R): reload();
					
				default:
			}
			
			
		});
		
		
		engine.backgroundColor = 0x507050;
		// Default screen - synchronized with React frontend
		reload(defaultScreen);
	}

	#if js
	static function createJSLoader() {
		final loader = new bh.base.ResourceLoader.CachingResourceLoader();

		function isManimOrAnim(filename:String):Bool {
			return StringTools.endsWith(filename, ".manim") || StringTools.endsWith(filename, ".anim");
		}

		loader.loadSheet2Impl = sheetName -> {
			var resourceName = '${sheetName}.atlas2';
			if (isManimOrAnim(resourceName)) {
				// JS first, then Haxe
				try {
					var bytes = FileLoader.load(resourceName);
					var resource = hxd.res.Any.fromBytes(resourceName, haxe.io.Bytes.ofData(bytes));
					return resource.toAtlas2();
				} catch (e) {
					if (hxd.Res.loader.exists(resourceName)) {
						return hxd.Res.load(resourceName).toAtlas2();
					} else {
						throw e;
					}
				}
			} else {
				// Haxe first, then JS
				if (hxd.Res.loader.exists(resourceName)) {
					return hxd.Res.load(resourceName).toAtlas2();
				} else {
					try {
						var bytes = FileLoader.load(resourceName);
						var resource = hxd.res.Any.fromBytes(resourceName, haxe.io.Bytes.ofData(bytes));
						return resource.toAtlas2();
					} catch (e) {
						throw e;
					}
				}
			}
		};

		loader.loadSheetImpl = sheetName -> {
			var resourceName = '${sheetName}.atlas';
			if (isManimOrAnim(resourceName)) {
				// JS first, then Haxe
				try {
					var bytes = FileLoader.load(resourceName);
					var resource = hxd.res.Any.fromBytes(resourceName, haxe.io.Bytes.ofData(bytes));
					return resource.to(hxd.res.Atlas);
				} catch (e) {
					if (hxd.Res.loader.exists(resourceName)) {
						return hxd.Res.loader.loadCache(resourceName, hxd.res.Atlas);
					} else {
						throw e;
					}
				}
			} else {
				// Haxe first, then JS
				if (hxd.Res.loader.exists(resourceName)) {
					return hxd.Res.loader.loadCache(resourceName, hxd.res.Atlas);
				} else {
					try {
						var bytes = FileLoader.load(resourceName);
						var resource = hxd.res.Any.fromBytes(resourceName, haxe.io.Bytes.ofData(bytes));
						return resource.to(hxd.res.Atlas);
					} catch (e) {
						throw e;
					}
				}
			}
		};

		loader.loadHXDResourceImpl = filename -> {
			if (isManimOrAnim(filename)) {
				// JS first, then Haxe
				try {
					var bytes = FileLoader.load(filename);
					return hxd.res.Any.fromBytes(filename, haxe.io.Bytes.ofData(bytes));
				} catch (e) {
					if (hxd.Res.loader.exists(filename)) {
						return hxd.Res.load(filename);
					} else {
						throw e;
					}
				}
			} else {
				// Haxe first, then JS
				if (hxd.Res.loader.exists(filename)) {
					return hxd.Res.load(filename);
				} else {
					try {
						var bytes = FileLoader.load(filename);
						return hxd.res.Any.fromBytes(filename, haxe.io.Bytes.ofData(bytes));
					} catch (e) {
						throw e;
					}
				}
			}
		};

		loader.loadAnimSMImpl = filename -> {
			// Always JS first for .anim/.manim
			if (isManimOrAnim(filename)) {
				try {
					var bytes = FileLoader.load(filename);
					var byteData = byte.ByteData.ofBytes(haxe.io.Bytes.ofData(bytes));
					return bh.stateanim.AnimParser.parseFile(byteData, loader);
				} catch (e) {
					throw 'loadAnimSMImpl failed for filename: $filename - ${e}';
				}
			} else {
				// Haxe first, then JS (shouldn't happen for anim, but for completeness)
				if (hxd.Res.loader.exists(filename)) {
					var resource = hxd.Res.load(filename);
					var byteData = byte.ByteData.ofBytes(resource.entry.getBytes());
					return bh.stateanim.AnimParser.parseFile(byteData, loader);
				} else {
					try {
						var bytes = FileLoader.load(filename);
						var byteData = byte.ByteData.ofBytes(haxe.io.Bytes.ofData(bytes));
						return bh.stateanim.AnimParser.parseFile(byteData, loader);
					} catch (e) {
						throw 'loadAnimSMImpl failed for filename: $filename - ${e}';
					}
				}
			}
		};

		loader.loadFontImpl = filename -> bh.base.FontManager.getFontByName(filename);

		loader.loadMultiAnimImpl = s -> {
			if (isManimOrAnim(s)) {
				// JS first, then Haxe
				try {
					var bytes = FileLoader.load(s);
					var byteData = byte.ByteData.ofBytes(haxe.io.Bytes.ofData(bytes));
					return bh.multianim.MultiAnimBuilder.load(byteData, loader, s);
				} catch (e) {
					if (hxd.Res.loader.exists(s)) {
						var r = hxd.Res.load(s);
						if (r == null) throw 'failed to load multianim ${s}';
						var byteData = byte.ByteData.ofBytes(r.entry.getBytes());
						return bh.multianim.MultiAnimBuilder.load(byteData, loader, s);
					} else {
						throw e;
					}
				}
			} else {
				// Haxe first, then JS
				if (hxd.Res.loader.exists(s)) {
					var r = hxd.Res.load(s);
					if (r == null) throw 'failed to load multianim ${s}';
					var byteData = byte.ByteData.ofBytes(r.entry.getBytes());
					return bh.multianim.MultiAnimBuilder.load(byteData, loader, s);
				} else {
					try {
						var bytes = FileLoader.load(s);
						var byteData = byte.ByteData.ofBytes(haxe.io.Bytes.ofData(bytes));
						return bh.multianim.MultiAnimBuilder.load(byteData, loader, s);
					} catch (e) {
						throw e;
					}
				}
			}
		};

		loader.loadTileImpl = filename -> {
			if (isManimOrAnim(filename)) {
				// JS first, then Haxe
				try {
					var bytes = FileLoader.load(filename);
					var resource = hxd.res.Any.fromBytes(filename, haxe.io.Bytes.ofData(bytes));
					return resource.toTile();
				} catch (e) {
					if (hxd.Res.loader.exists(filename)) {
						return hxd.Res.load(filename).toTile();
					} else {
						throw e;
					}
				}
			} else {
				// Haxe first, then JS
				if (hxd.Res.loader.exists(filename)) {
					return hxd.Res.load(filename).toTile();
				} else {
					try {
						var bytes = FileLoader.load(filename);
						var resource = hxd.res.Any.fromBytes(filename, haxe.io.Bytes.ofData(bytes));
						return resource.toTile();
					} catch (e) {
						throw e;
					}
				}
			}
		};

		return loader;
	}
	#end

	override  function update(dt:Float) {
		super.update(dt);
		screenManager.update(dt);
	}


	public static function main() {
		Main.instance = new Main();
	}
}
