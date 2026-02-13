# Design: Constant Declaration in .manim

## Decisions

- **Keyword: `@final`** - matches Haxe `final` keyword
- **No reassignment** - declared names are immutable constants
- **All parameter types supported** - uint, int, float, bool, string, color
- **Arrays supported** - constructed from expressions: `@final arr = [$x, $y, 15]`
- **Eager evaluation** - evaluate expression once when encountered, store computed value

## Motivation

Currently, complex expressions must be repeated inline every time they're used:

```manim
#panel programmable(x:uint=10, y:uint=10, w:uint=200, h:uint=100) {
    bitmap(...): $x + $w / 2 - 5, $y + $h / 2 - 5
    text(...):   $x + $w / 2 - 5, $y + $h / 2 - 5 + 12
    rect($w - $x * 2, $h - $y * 2): $x + $w / 2 - 5, $y + $h / 2 - 5
}
```

With constants, this becomes readable and DRY:

```manim
#panel programmable(x:uint=10, y:uint=10, w:uint=200, h:uint=100) {
    @final cx = $x + $w / 2 - 5
    @final cy = $y + $h / 2 - 5
    @final innerW = $w - $x * 2
    @final innerH = $h - $y * 2
    bitmap(...): $cx, $cy
    text(...):   $cx, $cy + 12
    rect($innerW, $innerH): $cx, $cy
}
```

## Syntax Options

### Chosen: `@final`

```manim
@final cx = $x + $w / 2
rect(10, 10): $cx, 0
```

- Matches Haxe `final` keyword semantics (immutable binding)
- Fits the `@` directive family (`@()`, `@else`, `@default`)
- Clear "once assigned, never changed"

## Detailed Syntax

```manim
# Basic numeric
@final centerX = $x + $w / 2

# Referencing other constants
@final centerY = $y + $h / 2
@final offset = $centerX + $centerY

# All arithmetic operators
@final scaled = $w * 2 + 1
@final halved = $h div 2
@final remainder = $w % 3

# String
@final label = "Player " + $name

# Color
@final bg = #FF0000

# Bool / ternary
@final isLarge = ?($size >= 100) 1 : 0
@final displaySize = ?($big) 100 : 50

# Array (constructed from expressions)
@final coords = [$x, $y, 15]
@final offsets = [$w / 2, $h / 2]

# Inside repeatable blocks (re-evaluated per iteration)
repeatable($i, step(5, dx: 20)) {
    @final angle = $i * 72
    @final radius = $i * 10 + 20
    bitmap(...): $radius, $angle
}

# Inside conditional blocks
@(mode => dark) {
    @final bg = #222222
    @final fg = #EEEEEE
}
```

### Errors

```manim
# ERROR: reassignment
@final x = 10
@final x = 20          // Error: 'x' is already declared

# ERROR: shadows parameter
#test programmable(width:uint=10) {
    @final width = 20   // Error: 'width' shadows parameter 'width'
}

# ERROR: undefined reference
@final y = $undefined  // Error: unknown reference 'undefined'
```

## Scoping Rules

Every `{ }` block creates a scope. Constants declared inside are cleaned up when leaving:

```manim
#test programmable(x:uint=5) {
    @final doubled = $x * 2          // scope: programmable block
    rect($doubled, $doubled): 0,0  // OK

    group {
        @final inner = $doubled + 1  // scope: group block. $doubled visible from outer
        rect($inner, 10): 0, 0      // OK
    }
    // $inner cleaned up here — NOT available

    rect($doubled, 10): 10, 10    // OK — $doubled still in scope
}
// $doubled cleaned up here
```

Repeatable creates a scope per iteration — constants are fresh each time:

```manim
repeatable($i, step(3, dx: 10)) {
    @final pos = $i * 30 + 5    // fresh binding each iteration
    bitmap(...): $pos, 0
}
// $pos NOT available here
```

## Type Handling: Eager Evaluation

Evaluate expression once when `@final` is encountered. Store computed value in `indexedParams`.
The result type is inferred from the expression. All types that parameters support work automatically.

## Implementation Plan

### 1. Parser Changes (`MultiAnimParser.hx`)

After parsing `@`, check if next token is `final` keyword before falling through to conditional parsing:

```
Parse rule: "@" "final" Identifier "=" Expression
Result: New NodeType FINAL(name:String, expression:ReferenceableValue)
```

Add `Kwd_Final` to `MPKeywords` enum and keyword map.

### 2. AST Changes (`MultiAnimParser.hx` or types file)

Add to `NodeType` enum:
```haxe
FINAL(name:String, value:ReferenceableValue);
```

### 3. Builder Changes (`MultiAnimBuilder.hx`)

Added `ExpressionAlias(expr:ReferenceableValue)` to `ResolvedIndexParameters` enum.

`evaluateAndStoreFinal(name, expr, node)` stores the expression as `ExpressionAlias`. Allows overwrite from repeatable re-iteration (same `@final` processed again), but errors if shadowing a programmable parameter.

Both `build()` and `buildTileGroup()` handle `FINAL_VAR` — store alias, return null (no visual output).

All `resolveAs*()` methods delegate through `ExpressionAlias`:
```haxe
case ExpressionAlias(expr): resolveAsInteger(expr);  // or resolveAsNumber, resolveAsString, etc.
```

Also added `ValueF` handling to `resolveAsInteger` and `ValueF` handling to `resolveAsString` for cross-type compatibility.

### 4. Scope Cleanup

`cleanupFinalVars(children, indexedParams)` scans resolved children for `FINAL_VAR` nodes and removes their names from `indexedParams`.

Called in 6 places — after every children-processing loop:
- `build()` main children loop
- `build()` REPEAT inner loop (per iteration)
- `build()` REPEAT2D inner loop (per iteration)
- `buildTileGroup()` main children loop
- `buildTileGroup()` REPEAT inner loop (per iteration)
- `buildTileGroup()` REPEAT2D inner loop (per iteration)

### 5. Macro Codegen (`MacroManimBuilder.hx`)

Generate local Haxe `var` in macro output. Map subsequent `$name` references to the generated local variable.

### 6. Error Handling

| Error | When |
|-------|------|
| Duplicate name | `@final x = 1` then `@final x = 2` in same scope |
| Shadows parameter | `@final width = ...` when `width` is a programmable parameter |
| Undefined reference | Expression references unknown `$name` |
| Forward reference | Using `$x` before `@final x = ...` (natural from sequential processing) |

### 7. Tests

- Basic declaration and usage (numeric, string, color, bool)
- Expressions (arithmetic, ternary, string concat)
- Chaining (`@final b = $a + 1` where `a` is also a `@final`)
- Inside repeatable (re-evaluated per iteration)
- Scoping (inner block doesn't leak to outer)
- Error: duplicate name
- Error: shadows parameter
- Macro codegen

## Resolved Questions

| Question | Decision |
|----------|----------|
| Keyword | `@final` — matches Haxe semantics |
| Reassignment | No — error on duplicate name in same scope |
| Types | All parameter types: uint, int, float, bool, string, color |
| Arrays | Yes — constructed from expressions: `@final arr = [$x, $y, 15]` |
