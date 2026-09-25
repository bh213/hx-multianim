package bh.multianim.dev;

#if MULTIANIM_DEV
/**
	DevBridge settings, read by their environment-variable names so every target uses the same ones:
	`HX_DEV_PORT`, `HX_DEV_BIND`, `HX_DEV_READY_FILE`, `HX_DEV_TOKEN`, `HX_DEV_ORIGIN`,
	`HX_DEV_RELAY`, `HX_DEV_PAGE`, `HX_DEV_APP`.

	- System targets read the environment (`Sys.getEnv`), and so does Node (`process.env`).
	- A browser page has no environment. There, a setting comes from a `window.HX_DEV` object the
	  host page writes before the game's script runs (`window.HX_DEV = {HX_DEV_TOKEN: "abc"}`, the
	  short key `token` works too), or else from the page's query string under its short key: the
	  name lower-cased without the `HX_DEV_` prefix (`?token=abc`). `HX_DEV_RELAY` is `?devbridge=`:
	  `?devbridge=ws://127.0.0.1:9010&token=abc`.

	Only builds with `-D MULTIANIM_DEV` read any of this; a published build has no DevBridge.
**/
class DevBridgeConfig {
	public static function get(name:String):Null<String> {
		#if sys
		return Sys.getEnv(name);
		#elseif hxnodejs
		// Node is a js target without `sys`: its environment is process.env
		return js.Node.process.env.get(name);
		#elseif js
		return getInPage(name);
		#else
		return null;
		#end
	}

	/** The query-string key for a setting: `HX_DEV_TOKEN` → `token`, `HX_DEV_RELAY` → `devbridge`. */
	public static function shortKey(name:String):String {
		if (name == "HX_DEV_RELAY")
			return "devbridge";
		var lower = name.toLowerCase();
		return StringTools.startsWith(lower, "hx_dev_") ? lower.substr(7) : lower;
	}

	#if js
	static function getInPage(name:String):Null<String> {
		// Parenthesised: js.Syntax.code is pasted as is, and `!typeof window !== ...` is always true.
		if (!js.Syntax.code("(typeof window !== 'undefined')"))
			return null;
		final key = shortKey(name);
		final fromObject:Dynamic = js.Syntax.code("(window.HX_DEV && typeof window.HX_DEV === 'object') ? window.HX_DEV : null");
		if (fromObject != null) {
			var v:Dynamic = Reflect.field(fromObject, name);
			if (v == null)
				v = Reflect.field(fromObject, key);
			if (v != null)
				return Std.string(v);
		}
		final search:String = js.Syntax.code("(window.location && window.location.search) || ''");
		if (search == "")
			return null;
		final params = new js.html.URLSearchParams(search);
		return params.get(key);
	}
	#end
}
#end
