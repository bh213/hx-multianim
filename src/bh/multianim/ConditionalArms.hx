package bh.multianim;

import bh.multianim.MultiAnimParser.Node;

/** Which nodes of a programmable are never shown together. Shared by the builder (at build time)
 *  and the codegen macro: no Heaps, parse tree only. */
class ConditionalArms {
	/** True when `a` and `b` sit in different arms of one @()/@else/@default chain (themselves or
	 *  through an ancestor): only one of them is ever shown, so they may share an explicit `#name`
	 *  — the shown arm's registration answers. Two separate `@()` are not exclusive (both may
	 *  hold); an `@else` follows the `@()`/`@else` arms before it, a `@default` every arm since the
	 *  chain began. */
	public static function exclusive(a:Null<Node>, b:Null<Node>):Bool {
		if (a == null || b == null || a == b) return false;
		var x:Node = a;
		while (x.parent != null) {
			final p = x.parent;
			// the child of p that is b or holds b
			var y:Null<Node> = b;
			while (y != null && y.parent != p)
				y = y.parent;
			if (y != null) {
				if (y == x) return false; // b is under a: nested, not exclusive
				final siblings = p.children;
				var i = siblings.indexOf(x);
				var j = siblings.indexOf(y);
				if (i < 0 || j < 0) return false;
				if (i > j) {
					final t = i;
					i = j;
					j = t;
				}
				final first = siblings[i];
				final last = siblings[j];
				return switch last.conditionals {
					case ConditionalElse(_):
						if (first.conditionals.match(NoConditional | ConditionalDefault)) false else {
							var ok = true;
							for (k in i + 1...j)
								if (!siblings[k].conditionals.match(ConditionalElse(_))) {
									ok = false;
									break;
								}
							ok;
						}
					case ConditionalDefault:
						var ok = true;
						for (k in i...j)
							if (!siblings[k].conditionals.match(Conditional(_, _) | ConditionalElse(_))) {
								ok = false;
								break;
							}
						ok;
					default: false;
				};
			}
			x = p;
		}
		return false;
	}
}
