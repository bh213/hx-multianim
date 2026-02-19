# Plan: Simplify String Interpolation Syntax in .manim

## Goal

Allow `${test}` as shorthand for `${$test}` inside interpolated strings in `.manim` files.
Both syntaxes will work — old `${$test}` remains valid.

## Current Behavior

Inside single-quoted strings, `${...}` triggers interpolation:
- `'${$test}'` → value of parameter `test`
- `'${$test + 2}'` → value of `test` + 2
- `'${test}'` → literal string `"test"` (bug-like, nobody would want this)

The `$` inside `${...}` is redundant — the braces already signal "expression context".

## Proposed Change

Inside `${...}`, treat bare identifiers as parameter references automatically.

- `'${test}'` → value of parameter `test` (NEW)
- `'${test + 2}'` → value of `test` + 2 (NEW)
- `'${$test}'` → value of parameter `test` (unchanged, still works)
- `'${$test + $other}'` → still works (unchanged)
- `'${test + other}'` → same as above (NEW)
- `'${callback("name")}'` → still works (keyword preserved)
- `'${a div b}'` → integer division still works (keyword preserved)

## Implementation

### File: `MacroManimParser.hx` (single file change)

**Location:** Lines 302-322, the re-lexing loop for interpolation code parts.

After re-lexing the code inside `${...}` with `MacroLexer`, transform the resulting tokens:
convert `TIdentifier(s)` to `TReference(s)`, **except** for expression keywords.

```haxe
// After line 311 (after re-lexing codeTokens):
// Inside ${...}, bare identifiers are references (allow ${test} instead of ${$test})
// Preserve keywords that have meaning in expression contexts
for (i in 0...codeTokens.length) {
    switch (codeTokens[i].type) {
        case TIdentifier(s) if (!isInterpolationKeyword(s)):
            codeTokens[i] = new Token(TReference(s), codeTokens[i].line, codeTokens[i].col);
        default:
    }
}
```

Add a helper (near `isKeyword`):

```haxe
static final interpolationKeywords = ["callback", "function", "div", "true", "false", "yes", "no"];

static function isInterpolationKeyword(s:String):Bool {
    final lower = s.toLowerCase();
    for (kw in interpolationKeywords) if (lower == kw) return true;
    return false;
}
```

**Why keywords must be preserved:**
- `callback` — recognized in `parseStringOrReference()` (line 695) and `parseAnything()` (line 776)
- `function` — recognized in `parseAnything()` (line 779)
- `div` — recognized in `parseNextAnythingExpression()` (line 861) and other expression continuations
- `true`/`false`/`yes`/`no` — boolean literals in `parseBool()`
- Interpolated tokens are consumed by whichever parser function is active (could be `parseStringOrReference`, `parseAnything`, etc.), so all expression-level keywords must be preserved

Non-keyword `TIdentifier` tokens would otherwise become `RVString(s)` (a literal string), which is never useful inside `${...}`.

`TReference` tokens still go through `validateRef()` so typos are caught.

### No changes needed elsewhere

- `parseStringOrReference()` already handles `TReference` correctly (line 729)
- `MultiAnimBuilder.resolveAsString()` already evaluates `RVReference` correctly (line 1024)
- `ProgrammableCodeGen.hx` — macro codegen for `RVReference` is already implemented (lines 1094, 1391, 3655, 3780, 4570)
- Runtime parser (`MultiAnimParser.hx`) — doesn't implement string interpolation, not affected

### Optionally update existing .manim files

Migrate existing usages to the cleaner syntax (not required, just cosmetic):

**In hx-multianim (test files):**

| File | Old | New |
|------|-----|-----|
| `test/examples/64-repeatRebuild/repeatRebuild.manim:12` | `'${$cx}x${$cy}'` | `'${cx}x${cy}'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:11` | `'${$value} / ${$maxValue}'` | `'${value} / ${maxValue}'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:26` | `'${$xp} / ${$xpMax} XP'` | `'${xp} / ${xpMax} XP'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:90` | `'${$strStat + $dexStat + $intStat}'` | `'${strStat + dexStat + intStat}'` |

**In hx-multianim-playground (separate repo, `../hx-multianim-playground/`):**

| File | Old | New |
|------|-----|-----|
| `public/assets/atlas-test.manim:8` | `'yindex ${$indexY}'` | `'yindex ${indexY}'` |
| `public/assets/demos/gamelike/character-sheet.manim:11` | `'${$value} / ${$maxValue}'` | `'${value} / ${maxValue}'` |
| `public/assets/demos/gamelike/character-sheet.manim:26` | `'${$xp} / ${$xpMax} XP'` | `'${xp} / ${xpMax} XP'` |
| `public/assets/demos/gamelike/character-sheet.manim:90` | `'${$strStat + $dexStat + $intStat}'` | `'${strStat + dexStat + intStat}'` |
| `public/assets/demos/advanced/expressions.manim:55` | `'Value is ${$value}'` | `'Value is ${value}'` |
| `public/assets/demos/advanced/expressions.manim:61` | `'${$value} and ${$value + 10}'` | `'${value} and ${value + 10}'` |
| `public/assets/demos/layout/flow-layout.manim:155` | `'text ${$t}'` | `'text ${t}'` |
| `public/assets/demos/advanced/macro-performance.manim:18` | `'Lv.${$level}'` | `'Lv.${level}'` |
| `public/assets/demos/advanced/macro-performance.manim:22` | `'${$hp}/${$maxHp}'` | `'${hp}/${maxHp}'` |
| `public/assets/demos/advanced/macro-performance.manim:26` | `'${$mp}/${$maxMp}'` | `'${mp}/${maxMp}'` |
| `public/assets/demos/ui/progress-bar.manim:40` | `'${$value}%'` | `'${value}%'` |
| `public/assets/demos/gamelike/skill-tree.manim:130` | `'Skill Points: ${$pts}'` | `'Skill Points: ${pts}'` |

## Testing

- Run `test.bat run` — all existing tests should pass unchanged (backward compat)
- After migrating .manim files, run again to verify the new syntax produces identical results
- Add a parser error test for `${unknownVar}` to verify `validateRef` still catches typos
- Test `${callback("name")}` still works to confirm keyword preservation
- Test `${a div b}` if integer division in interpolation is used

## Risk

Low. The transform is scoped to the interpolation re-lexing context only. Normal `$ref` handling outside strings is untouched. Both syntaxes coexist. Keywords are explicitly preserved to avoid breaking existing expression syntax.
