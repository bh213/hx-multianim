package bh.multianim;

import bh.multianim.MultiAnimParser.CustomFilterArgType;

/**
	A parameter of a shader, or of any filter registered with `FilterManager.registerFilter`: what a
	tool needs to show it as a control. `min`, `max` and `step` are a slider's; `unit` follows the
	number (`px`, `°`, `s`); `label` is what a person reads; `choices` are a word parameter's words.
**/
typedef ShaderParamInfo = {
	name:String,
	type:CustomFilterArgType,
	?defaultValue:Dynamic,
	?min:Float,
	?max:Float,
	?step:Float,
	?unit:String,
	?label:String,
	?choices:Array<String>,
};

/**
	A shader the engine has built in: its name as written in a `.manim`, where it goes (`screen`, over
	the whole stage; `thing`, on one element; `ground`, drawn from nothing by `generated(shader(…))`),
	what it does in a line, whether it moves with the game's clock, and its parameters.
**/
typedef ShaderInfo = {
	name:String,
	places:Array<String>,
	says:String,
	time:Bool,
	params:Array<ShaderParamInfo>,
};

/**
	The built-in shaders, described: no Heaps here, so a tool reads it as the engine does (the studio's
	Shaders page, `ManimNeeds`, the LSP). The shaders themselves are `bh.base.shaders.BuiltinShaders`.

	Each is a filter, written as one: `filter: crt(curve: 0.15, scanlines: 0.4)`, by name or by
	position, every parameter left out at its default. `time` is never a parameter: a shader that
	moves is given the game's clock (`bh.base.ShaderClock`). Their noise is arithmetic, never `sin`
	of a large number, so they draw near alike on every GPU (a software renderer differs in a few pixels).
**/
class ShaderCatalog {
	/**
		The palette `paletteLock` holds a picture to when it is given none: Sweetie 16, sixteen colours
		by GrafxKid (lospec.com/palette-list/sweetie-16).
	**/
	public static final SWEETIE_16:Array<Int> = [
		0x1A1C2C, 0x5D275D, 0xB13E53, 0xEF7D57, 0xFFCD75, 0xA7F070, 0x38B764, 0x257179,
		0x29366F, 0x3B5DC9, 0x41A6F6, 0x73EFF7, 0xF4F4F4, 0x94B0C2, 0x566C86, 0x333C57,
	];

	public static final shaders:Array<ShaderInfo> = [
		// ---- over a screen
		{
			name: "crt",
			places: ["screen"],
			says: "An old television: the picture curved, scan lines, dark corners, colours a little apart, a faint flicker",
			time: true,
			params: [
				{name: "curve", type: CFFloat, defaultValue: 0.12, min: 0, max: 0.5, step: 0.01, label: "Curve"},
				{name: "scanlines", type: CFFloat, defaultValue: 0.35, min: 0, max: 1, step: 0.01, label: "Scan lines"},
				{name: "lineSize", type: CFInt, defaultValue: 3, min: 2, max: 8, step: 1, unit: "px", label: "Line spacing"},
				{name: "vignette", type: CFFloat, defaultValue: 0.35, min: 0, max: 1, step: 0.01, label: "Dark corners"},
				{name: "shift", type: CFFloat, defaultValue: 1, min: 0, max: 4, step: 0.1, unit: "px", label: "Colour shift"},
				{name: "flicker", type: CFFloat, defaultValue: 0.03, min: 0, max: 0.3, step: 0.01, label: "Flicker"},
			],
		},
		{
			name: "scanlines",
			places: ["screen"],
			says: "Dark lines across the picture, as a screen's rows",
			time: false,
			params: [
				{name: "strength", type: CFFloat, defaultValue: 0.3, min: 0, max: 1, step: 0.01, label: "Strength"},
				{name: "spacing", type: CFInt, defaultValue: 3, min: 2, max: 8, step: 1, unit: "px", label: "Spacing"},
			],
		},
		{
			name: "vignette",
			places: ["screen"],
			says: "The edges darkened, the middle left as it is",
			time: false,
			params: [
				{name: "strength", type: CFFloat, defaultValue: 0.45, min: 0, max: 1, step: 0.01, label: "Strength"},
				{name: "radius", type: CFFloat, defaultValue: 0.75, min: 0.2, max: 1.5, step: 0.01, label: "Radius"},
				{name: "softness", type: CFFloat, defaultValue: 0.45, min: 0.05, max: 1, step: 0.01, label: "Softness"},
				{name: "color", type: CFColor, defaultValue: 0x000000, label: "Colour"},
			],
		},
		{
			name: "grade",
			places: ["screen", "thing"],
			says: "The colours graded: brighter or darker, more or less contrast and colour, a tint over all",
			time: false,
			params: [
				{name: "brightness", type: CFFloat, defaultValue: 1, min: 0, max: 2, step: 0.01, label: "Brightness"},
				{name: "contrast", type: CFFloat, defaultValue: 1, min: 0, max: 2, step: 0.01, label: "Contrast"},
				{name: "saturation", type: CFFloat, defaultValue: 1, min: 0, max: 2, step: 0.01, label: "Colour"},
				{name: "tint", type: CFColor, defaultValue: 0xFFFFFF, label: "Tint"},
				{name: "tintAmount", type: CFFloat, defaultValue: 0, min: 0, max: 1, step: 0.01, label: "Tint amount"},
			],
		},
		{
			name: "paletteLock",
			places: ["screen"],
			says: "Every colour held to a palette, the nearest of its colours, dithered if asked",
			time: false,
			params: [
				{name: "palette", type: CFPalette, defaultValue: SWEETIE_16, label: "Palette"},
				{name: "dither", type: CFFloat, defaultValue: 0, min: 0, max: 1, step: 0.01, label: "Dither"},
			],
		},
		{
			name: "pixelate",
			places: ["screen", "thing"],
			says: "Big pixels: the picture drawn in blocks",
			time: false,
			params: [
				{name: "size", type: CFInt, defaultValue: 4, min: 1, max: 32, step: 1, unit: "px", label: "Block size"},
			],
		},
		{
			name: "dither",
			places: ["screen"],
			says: "Fewer colours, the steps between them dithered in a pattern",
			time: false,
			params: [
				{name: "levels", type: CFInt, defaultValue: 4, min: 2, max: 16, step: 1, label: "Levels a colour"},
				{name: "size", type: CFInt, defaultValue: 1, min: 1, max: 4, step: 1, unit: "px", label: "Pattern size"},
			],
		},
		{
			name: "aberration",
			places: ["screen"],
			says: "The colours split apart towards the edges, as a cheap lens",
			time: false,
			params: [
				{name: "amount", type: CFFloat, defaultValue: 2, min: 0, max: 8, step: 0.1, unit: "px", label: "Amount"},
				{name: "angle", type: CFFloat, defaultValue: 0, min: 0, max: 360, step: 1, unit: "°", label: "Angle"},
			],
		},
		{
			name: "wave",
			places: ["screen", "thing"],
			says: "The picture waving: heat haze, under water",
			time: true,
			params: [
				{name: "amplitude", type: CFFloat, defaultValue: 2, min: 0, max: 16, step: 0.1, unit: "px", label: "Amplitude"},
				{name: "frequency", type: CFFloat, defaultValue: 4, min: 0.5, max: 20, step: 0.1, label: "Waves across"},
				{name: "speed", type: CFFloat, defaultValue: 1, min: 0, max: 10, step: 0.1, label: "Speed"},
			],
		},
		{
			name: "shockwave",
			places: ["screen"],
			says: "A ring that bends what is under it, from a point outwards (move its radius from the game)",
			time: false,
			params: [
				{name: "x", type: CFFloat, defaultValue: 0.5, min: 0, max: 1, step: 0.01, label: "Centre, across"},
				{name: "y", type: CFFloat, defaultValue: 0.5, min: 0, max: 1, step: 0.01, label: "Centre, down"},
				{name: "radius", type: CFFloat, defaultValue: 0.3, min: 0, max: 1.5, step: 0.01, label: "Radius"},
				{name: "thickness", type: CFFloat, defaultValue: 0.08, min: 0.01, max: 0.5, step: 0.01, label: "Thickness"},
				{name: "strength", type: CFFloat, defaultValue: 0.04, min: 0, max: 0.2, step: 0.005, label: "Strength"},
			],
		},
		{
			name: "fog",
			places: ["screen", "ground"],
			says: "Fog or smoke drifting over the picture, or drawn on its own as a ground",
			time: true,
			params: [
				{name: "color", type: CFColor, defaultValue: 0xC8D0D8, label: "Colour"},
				{name: "amount", type: CFFloat, defaultValue: 0.5, min: 0, max: 1, step: 0.01, label: "Amount"},
				{name: "scale", type: CFFloat, defaultValue: 6, min: 1, max: 40, step: 0.5, label: "Size"},
				{name: "speed", type: CFFloat, defaultValue: 0.2, min: 0, max: 2, step: 0.01, label: "Speed"},
			],
		},
		// ---- on a thing
		{
			name: "flash",
			places: ["thing"],
			says: "The thing flashed with a colour: a hit (move its amount from the game)",
			time: false,
			params: [
				{name: "color", type: CFColor, defaultValue: 0xFFFFFF, label: "Colour"},
				{name: "amount", type: CFFloat, defaultValue: 0, min: 0, max: 1, step: 0.01, label: "Amount"},
			],
		},
		{
			name: "dissolve",
			places: ["thing"],
			says: "The thing breaking up into grains, a burning edge at the front (move its amount from 0 to 1)",
			time: false,
			params: [
				{name: "amount", type: CFFloat, defaultValue: 0, min: 0, max: 1, step: 0.01, label: "Amount"},
				{name: "edge", type: CFFloat, defaultValue: 0.06, min: 0, max: 0.3, step: 0.01, label: "Edge width"},
				{name: "edgeColor", type: CFColor, defaultValue: 0xFF8A20, label: "Edge colour"},
				{name: "grain", type: CFFloat, defaultValue: 3, min: 1, max: 32, step: 0.5, unit: "px", label: "Grain size"},
				{name: "seed", type: CFFloat, defaultValue: 0, min: 0, max: 100, step: 1, label: "Seed"},
			],
		},
		{
			name: "shimmer",
			places: ["thing"],
			says: "A glint sweeping across the thing now and then: a pickup",
			time: true,
			params: [
				{name: "color", type: CFColor, defaultValue: 0xFFFFFF, label: "Colour"},
				{name: "strength", type: CFFloat, defaultValue: 0.6, min: 0, max: 1, step: 0.01, label: "Strength"},
				{name: "width", type: CFFloat, defaultValue: 0.15, min: 0.02, max: 0.6, step: 0.01, label: "Width"},
				{name: "every", type: CFFloat, defaultValue: 2, min: 0.3, max: 10, step: 0.1, unit: "s", label: "Every"},
			],
		},
		{
			name: "pulse",
			places: ["thing"],
			says: "The thing glowing with a colour and fading, again and again: something live",
			time: true,
			params: [
				{name: "color", type: CFColor, defaultValue: 0xFFFFFF, label: "Colour"},
				{name: "amount", type: CFFloat, defaultValue: 0.35, min: 0, max: 1, step: 0.01, label: "Amount"},
				{name: "speed", type: CFFloat, defaultValue: 1, min: 0.1, max: 8, step: 0.1, unit: "/s", label: "Pulses a second"},
			],
		},
		{
			name: "silhouette",
			places: ["thing"],
			says: "The thing as a flat shape of one colour: behind a wall, not known yet",
			time: false,
			params: [
				{name: "color", type: CFColor, defaultValue: 0x202028, label: "Colour"},
				{name: "amount", type: CFFloat, defaultValue: 1, min: 0, max: 1, step: 0.01, label: "Amount"},
			],
		},
		// ---- a ground, drawn from nothing
		{
			name: "water",
			places: ["ground"],
			says: "Water: ripples between a deep and a shallow colour, moving",
			time: true,
			params: [
				{name: "deep", type: CFColor, defaultValue: 0x1B4F8A, label: "Deep"},
				{name: "shallow", type: CFColor, defaultValue: 0x3FA7D6, label: "Shallow"},
				{name: "scale", type: CFFloat, defaultValue: 24, min: 4, max: 128, step: 1, unit: "px", label: "Ripple size"},
				{name: "speed", type: CFFloat, defaultValue: 0.6, min: 0, max: 4, step: 0.05, label: "Speed"},
			],
		},
		{
			name: "sky",
			places: ["ground"],
			says: "A sky from a top colour to a bottom one, with clouds drifting",
			time: true,
			params: [
				{name: "top", type: CFColor, defaultValue: 0x3A6EA5, label: "Top"},
				{name: "bottom", type: CFColor, defaultValue: 0xBFE3FF, label: "Bottom"},
				{name: "clouds", type: CFFloat, defaultValue: 0.4, min: 0, max: 1, step: 0.01, label: "Clouds"},
				{name: "scale", type: CFFloat, defaultValue: 96, min: 16, max: 512, step: 1, unit: "px", label: "Cloud size"},
				{name: "speed", type: CFFloat, defaultValue: 0.1, min: 0, max: 2, step: 0.01, label: "Speed"},
			],
		},
		{
			name: "stars",
			places: ["ground"],
			says: "A starfield on black, twinkling and drifting",
			time: true,
			params: [
				{name: "density", type: CFFloat, defaultValue: 0.25, min: 0, max: 1, step: 0.01, label: "Density"},
				{name: "twinkle", type: CFFloat, defaultValue: 0.5, min: 0, max: 1, step: 0.01, label: "Twinkle"},
				{name: "speed", type: CFFloat, defaultValue: 0.1, min: 0, max: 2, step: 0.01, label: "Drift"},
				{name: "color", type: CFColor, defaultValue: 0x05060C, label: "Background"},
			],
		},
	];

	/** A built-in shader by its name, as written or in any case: `paletteLock`, `palettelock`. **/
	public static function find(name:String):Null<ShaderInfo> {
		final lower = name.toLowerCase();
		for (shader in shaders)
			if (shader.name.toLowerCase() == lower)
				return shader;
		return null;
	}

	/** Whether a filter's name is one of the engine's shaders: a game may not register one by it. **/
	public static function isBuiltin(name:String):Bool {
		return find(name) != null;
	}

	/** The type's name as a tool says it: `float`, `color`, `bool`, `int`, `word`, `palette`. **/
	public static function typeName(type:CustomFilterArgType):String {
		return switch type {
			case CFFloat: "float";
			case CFColor: "color";
			case CFBool: "bool";
			case CFInt: "int";
			case CFWord: "word";
			case CFPalette: "palette";
		};
	}
}
