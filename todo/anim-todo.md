# .anim Format Improvements

Consistency improvements to align `.anim` with `.manim` conventions, reduce boilerplate, and catch errors earlier.

## High Priority

### 1. `@else` / `@default` conditionals

.manim supports `@else`, `@else(condition)`, and `@default` fallback chains. .anim only supports explicit `@(state=>value)` matching, forcing users to enumerate all remaining states.

```anim
// Before: must list every direction
extrapoints {
    @(direction=>l) targeting : -1, -12
    @(direction=>r) targeting : 5, -12
}

// After: fallback for remaining states
extrapoints {
    @(direction=>l) targeting : -1, -12
    @else targeting : 5, -12
}
```

Works naturally with existing `findBestStateMatch()` scoring — an `@default` selector is an empty map (score 0, matches everything). Post-parse exhaustive validation already covers reachability.

Applies to: `animation`, `playlist`, `extrapoints` conditionals.

### 2. Name in animation header (not body)

Currently `name:` is a property inside the animation body. Moving it to the header aligns with .manim's `#name element { }` convention and removes a line per block.

```anim
// Current
animation {
    name: attack
    fps: 10
    playlist { ... }
}

// Proposed
animation attack {
    fps: 10
    playlist { ... }
}

// With conditional
animation attack @(direction=>l) {
    fps: 10
    playlist { sheet: "unit_l_attack" }
}
```

Backward compatible: keep parsing `name:` inside the body as a fallback. Combined with default fps (#3), a typical block shrinks from 5 lines to 3.

Also makes the compact shorthand (#5) a natural continuation — `animation attack { ... }` → `anim attack: "sheet"`.

### 3. File-level default `fps`

Every animation block must declare `fps:` even when most use the same value. A top-level `fps:` would set the default, with per-animation override.

```anim
// Before
animation { name: attack  fps: 10  playlist { ... } }
animation { name: die     fps: 10  playlist { ... } }
animation { name: idle    fps: 5   loop: yes  playlist { ... } }

// After
fps: 10

animation attack { playlist { ... } }
animation die { playlist { ... } }
animation idle { fps: 5  loop: yes  playlist { ... } }
```

### 4. Parse-time `$$state$$` validation

State variable interpolation in sheet names (`"marine_$$direction$$_idle"`) is handled at runtime via string replacement. Misspelled state names (e.g. `$$directon$$`) silently fail — error only surfaces when the sheet lookup fails at runtime.

Fix: after parsing a sheet name, scan for `$$...$$` patterns and verify each captured name exists in `definedStates`. Report parse error with line number if not found.

## Medium Priority

### 5. Compact animation shorthand

Most game .anim files follow an identical pattern: name + sheet reference with state interpolation. A one-line shorthand would dramatically reduce file sizes (especially generated ones).

```anim
// Before (5 lines per animation)
animation {
    name: attack
    fps: 10
    playlist { sheet: "archer_attack_$$color$$_$$direction$$" }
}

// After (1 line)
anim attack: "archer_attack_$$color$$_$$direction$$"
anim idle fps:5 loop: "archer_idle_$$color$$_$$direction$$"
```

Would reduce typical unit .anim files from 50-80 lines to ~10.

### 6. Float support in numbers

.anim lexer only tokenizes integers. This limits metadata values and coordinates to integers only.

- Add float token support to `AnimLexerHC` (detect decimal point in number parsing)
- Add `MVFloat(f:Float)` to `MetadataValue` enum
- Add `getFloatOrDefault()` / `getFloatOrException()` to `AnimMetadata`
- Allow float coordinates in `center:` and `extrapoints`

### 7. Named constants (`@final`)

.manim supports `@final name = expr` for immutable constants. .anim has no equivalent, leading to repeated magic numbers.

```anim
// Before
center: 32, 192
extrapoints {
    @(direction=>l) fire : -7, -11
    @(direction=>r) fire : 7, -11
}

// After
@final fireX = 7
@final fireY = -11
center: 32, 192
extrapoints {
    @(direction=>l) fire : -$fireX, $fireY
    @(direction=>r) fire : $fireX, $fireY
}
```

Requires basic expression support (at least `$ref` and unary minus).

## Low Priority

### 8. Relax newline sensitivity

.anim treats newlines as significant tokens (statement terminators). .manim treats them as whitespace. This makes .anim more fragile — long sheet names can't be broken across lines.

Consider treating newlines as whitespace (like .manim) and using `{`/`}` blocks as the structural delimiter. Would be a backward-compatible change if newlines are simply ignored where they currently act as separators.

### 9. Unify string interpolation syntax

.anim uses `$$stateName$$` (double-dollar delimiters). .manim uses `${expr}` in single-quoted strings. Two different interpolation syntaxes adds learning overhead.

Long-term goal: support `${stateName}` alongside `$$stateName$$` in .anim sheet names. Breaking change for `$$` removal — but since most .anim files are generated by the asset pipeline (`assets/`), migration is scriptable.

### 10. Color support in metadata

.manim has full color support (`#RGB`, `#RRGGBB`, named colors, `0xAARRGGBB`). .anim has none. Currently noted in TODO.md as "StateAnim: color replace". When color replace is implemented, metadata will need `MVColor` and the parser will need color literal parsing (reuse from .manim).

### 11. Filter declarations

.manim supports `outline`, `glow`, `replaceColor`, `replacePalette`, etc. .anim has no filter support — all visual post-processing is applied programmatically. Adding filter declarations to .anim would allow data-driven visual effects per animation state.

```anim
// Hypothetical
animation {
    name: frozen
    fps: 3
    filters { replaceColor: #FF0000 => #0000FF }
    playlist { sheet: "unit_frozen" }
}
```

Low priority since game code handles this adequately.

## Summary

| # | Item | Backward Compatible | Effort |
|---|------|-------------------|--------|
| 1 | `@else`/`@default` | Yes | Small |
| 2 | Name in header | Yes (fallback to `name:`) | Small |
| 3 | Default `fps` | Yes | Small |
| 4 | `$$state$$` validation | Yes | Small |
| 5 | Compact shorthand | Yes (additive) | Medium |
| 6 | Float support | Yes | Small |
| 7 | Named constants | Yes (additive) | Medium |
| 8 | Relax newlines | Yes (permissive) | Medium |
| 9 | Unify interpolation | No (`$$` deprecation) | Large |
| 10 | Color metadata | Yes | Medium |
| 11 | Filter declarations | Yes (additive) | Large |
