package bh.test.examples;

/**
 * Example: macro-generated programmable from .manim definition.
 *
 * The @:build macro reads the .manim file at compile time and generates:
 *   - public var hp(default, set):Int = 100
 *   - public var maxHp(default, set):Int = 100
 *   - public var status(default, set):Int = 0  (with STATUS_NORMAL=0, STATUS_POISONED=1, STATUS_DEAD=2)
 *   - public var label(default, set):String = "HP"
 *   - public function create(resourceLoader):h2d.Object
 *   - public function refresh():Void
 *   - Per-parameter setters that trigger targeted updates
 *
 * Usage:
 *   var bar = new MacroHealthBar();
 *   var obj = bar.create(resourceLoader);
 *   parent.addChild(obj);
 *   bar.hp = 50;            // triggers targeted update — instant
 *   bar.status = MacroHealthBar.STATUS_POISONED;  // toggles visibility
 */
@:build(bh.multianim.ProgrammableMacro.build("test/examples/25-programmableMacroDemo/programmableMacroDemo.manim", "macroHealthBar"))
class MacroHealthBar extends bh.multianim.ProgrammableBase {}
