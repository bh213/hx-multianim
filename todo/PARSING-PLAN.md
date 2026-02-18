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

## Implementation

### File: `MacroManimParser.hx` (single file change)

**Location:** Lines 302-322, the re-lexing loop for interpolation code parts.

After re-lexing the code inside `${...}` with `MacroLexer`, transform the resulting tokens:
convert any `TIdentifier(s)` to `TReference(s)`.

```haxe
// After line 311 (after re-lexing codeTokens):
// Inside ${...}, bare identifiers are references (allow ${test} instead of ${$test})
for (i in 0...codeTokens.length) {
    switch (codeTokens[i].type) {
        case TIdentifier(s):
            codeTokens[i] = new Token(TReference(s), codeTokens[i].line, codeTokens[i].col);
        default:
    }
}
```

This is safe because inside `${...}`:
- There are no keywords or function calls — only values and operators
- `TIdentifier` would otherwise become `RVString(s)` (a literal), which is never useful here
- `TReference` tokens still go through `validateRef()` so typos are caught

### No changes needed elsewhere

- `parseStringOrReference()` already handles `TReference` correctly
- `MultiAnimBuilder.resolveAsString()` already evaluates `RVReference` correctly
- `ProgrammableCodeGen.hx` — macro codegen for `RVReference` is already implemented
- Runtime parser (`MultiAnimParser.hx`) — doesn't implement string interpolation, not affected

### Optionally update existing .manim files

Migrate existing usages to the cleaner syntax (not required, just cosmetic):

| File | Old | New |
|------|-----|-----|
| `playground/public/assets/atlas-test.manim:8` | `'yindex ${$indexY}'` | `'yindex ${indexY}'` |
| `test/examples/64-repeatRebuild/repeatRebuild.manim:12` | `'${$cx}x${$cy}'` | `'${cx}x${cy}'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:11` | `'${$value} / ${$maxValue}'` | `'${value} / ${maxValue}'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:26` | `'${$xp} / ${$xpMax} XP'` | `'${xp} / ${xpMax} XP'` |
| `test/examples/78-characterSheetDemo/characterSheetDemo.manim:90` | `'${$strStat + $dexStat + $intStat}'` | `'${strStat + dexStat + intStat}'` |

## Testing

- Run `test.bat run` — all existing tests should pass unchanged (backward compat)
- After migrating .manim files, run again to verify the new syntax produces identical results
- Add a parser error test for `${unknownVar}` to verify `validateRef` still catches typos

## Risk

Very low. The transform is scoped to the interpolation re-lexing context only. Normal `$ref` handling outside strings is untouched. Both syntaxes coexist.
