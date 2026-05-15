package bh.test;

/** Lifecycle operation to perform on a built root between scene-add and screenshot.

	Used by `VisualTestBase.simpleMacroTest` (and related helpers) to exercise
	object-tree lifecycle paths that ordinary render tests skip — most notably
	detach/reattach, which triggers `onRemove`/`onAdd` chains where filter rebind
	and (for vanilla `h2d.Graphics`) vertex content wipe happen.

	Applied symmetrically to both builder and macro phases so the reference image
	is captured from a post-lifecycle state; any library code path that fails to
	survive the cycle surfaces as a similarity mismatch. */
enum LifecycleMode {
	/** No-op. Default — matches behavior of tests written before this hook existed. */
	None;

	/** `root.remove()` followed by re-adding to the same parent. Exercises the full
		`onRemove` / `onAdd` chain. Catches regressions in objects that reset state
		on remove (e.g. vanilla `h2d.Graphics.clear()`). */
	DetachReattach;

	/** Escape hatch for one-off lifecycle cases. Runs after the root is in the scene
		and before the screenshot is captured. */
	Custom(fn:(root:h2d.Object) -> Void);
}
