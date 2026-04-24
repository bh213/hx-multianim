package bh.ui;

import bh.base.MAObject;

/** Abstraction over anything that can act as a source of interactive elements for
 *  `UIScreen.addInteractives` and `UIRichInteractiveHelper.register`.
 *
 *  Two implementations exist:
 *  - `bh.multianim.MultiAnimBuilder.BuilderResult` — runtime builder path, backed by
 *    `IncrementalUpdateContext` for rebuild notifications.
 *  - Codegen-generated programmable instance classes (`@:manim` via `ProgrammableCodeGen`) —
 *    walks the instance's scene graph for interactives and fires listeners from setters.
 *
 *  The four methods cover everything the screen/helper needs: scanning the current interactive
 *  set, subscribing to structural rebuilds (so wrappers can resync after a `@switch` arm flip),
 *  and forwarding typed parameter writes (so `UIRichInteractiveHelper` can drive Normal/Hover/
 *  Pressed/Disabled state machines via `setParameter("status", "hover")` etc.).
 */
@:nullSafety
interface UIInteractiveSource {
	/** Current set of interactive MAObjects. For codegen instances this walks the scene graph;
	 *  for BuilderResult it returns the tracked list directly. Each call returns a fresh array —
	 *  safe to iterate, mutate, or store. */
	function getInteractives():Array<MAObject>;

	/** True if this source supports dynamic rebuilds and parameter updates. Codegen instances
	 *  always return `true`. `BuilderResult` returns `true` only when built with `incremental: true`.
	 *  Static-snapshot BuilderResults return `false` — callers that need to wire rebuild listeners
	 *  or drive `setParameter` must branch on this, since those calls will throw otherwise. */
	var isIncremental(get, never):Bool;

	/** Register a callback fired once per rebuild cycle in which any parameter changed. Used by
	 *  `UIScreen.syncInteractivesFrom` to resync wrapper maps after `@switch` arm flips or
	 *  param-dependent `repeatable` rebuilds. Throws if `isIncremental` is false — gate the call
	 *  at wiring time rather than let the asymmetry with `setParameter` cause silent bugs. */
	function addRebuildListener(fn:Void -> Void):Void;

	/** Remove a previously-registered rebuild listener. No-op if not present. Throws if
	 *  `isIncremental` is false (symmetric with `addRebuildListener`). */
	function removeRebuildListener(fn:Void -> Void):Void;

	/** Set a parameter by name. Used by `UIRichInteractiveHelper` to drive state machines
	 *  (`setParameter("status", "hover")`). For BuilderResult this goes through
	 *  `IncrementalUpdateContext.setParameter`; for codegen instances this dispatches to the
	 *  typed setter for that param name (throws if the name is unknown). */
	function setParameter(name:String, value:Dynamic):Void;
}
