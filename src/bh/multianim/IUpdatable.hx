package bh.multianim;

/**
 * Common interface for accessing named elements from `.manim` files,
 * regardless of whether they were built via the runtime builder (`Updatable`)
 * or the compile-time macro codegen (`ProgrammableUpdatable`).
 */
interface IUpdatable {
	function setVisibility(visible:Bool):Void;
	function updateText(newText:String, throwIfAnyFails:Bool = true):Void;
	function updateTile(newTile:h2d.Tile, throwIfAnyFails:Bool = true):Void;
	function setObject(newObject:h2d.Object):Void;
	function addObject(newObject:h2d.Object):Void;
	function clearObjects():Void;
}
