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

### 4. `${state}` interpolation with parse-time validation

Two changes in one — unify the interpolation syntax with .manim and add validation.

**Syntax:** Use `${stateName}` in sheet names, matching .manim's `${expr}` convention.

```anim
sheet: "marine_${direction}_idle"
```

**Validation:** After parsing a sheet name, scan for `${...}` patterns and verify each captured name exists in `definedStates`. Report a parse error with line number if not found — currently misspelled names silently produce broken sheet lookups at runtime.

## Medium Priority

### 5. Compact animation shorthand

Most game .anim files follow an identical pattern: name + sheet reference with state interpolation. A one-line shorthand would dramatically reduce file sizes (especially generated ones).

```anim
// Before (5 lines per animation)
animation {
    name: attack
    fps: 10
    playlist { sheet: "archer_attack_${color}_${direction}" }
}

// After (1 line)
anim attack: "archer_attack_${color}_${direction}"
anim idle fps:5 loop: "archer_idle_${color}_${direction}"
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

### 8. Comparison operators in conditionals

.manim supports `@(param >= 30)`, `@(param <= 30)`, `@(param > 30)`, `@(param < 30)`, and range match `@(param => 10..30)`. .anim only has `=>` (equals), `!=` (not equals), and `[a,b]` (multi-value).

```anim
// Already possible: != works for single-value exclusion
extrapoints {
    @(damage != destroyed) fire : 5, -12
}

// But multi-value exclusion still requires enumeration
extrapoints {
    @(damage=>[pristine, light, heavy]) fire : 5, -12
}
```

The real gap is comparison and range operators for numeric states:

```anim
states: level(1, 2, 3, 4, 5)

animation attack {
    @(level >= 3) playlist { sheet: "unit_attack_strong" }
    @else playlist { sheet: "unit_attack_weak" }
}
```

Reuse .manim's comparison operator parsing. Requires ordered state values (already declared in order in `states:` header).

### 9. Typed event data

.manim interactives support typed metadata (`key:int => 100`, `key:float => 1.5`, `key:bool => true`). .anim events carry no structured data — just a name and optional point/random.

```anim
// Current: event name only, game code must hard-code meaning
event hit random 0,-10, 10

// Proposed: typed key-value payload
event hit random 0,-10, 10 { damage:int => 5, element => "fire" }
event spawn { unit => "skeleton", count:int => 3 }
```

Game code would receive typed metadata alongside the event, removing the need for external lookup tables. Reuse the metadata parsing and `BuilderResolvedSettings` infrastructure from .manim.

## Low Priority

### 10. Remove newline

.anim treats newlines as significant tokens (statement terminators). .manim treats them as whitespace. This makes .anim more fragile — long sheet names can't be broken across lines. Remove newline as a token.


### 11. Color support in metadata

.manim has full color support (`#RGB`, `#RRGGBB`, named colors, `0xAARRGGBB`). .anim has none. Currently noted in TODO.md as "StateAnim: color replace". When color replace is implemented, metadata will need `MVColor` and the parser will need color literal parsing (reuse from .manim).

### 12. Filter declarations

.manim supports `outline`, `glow`, `replaceColor`, `replacePalette`, etc. .anim has no filter support — all visual post-processing is applied programmatically. Adding filter declarations to .anim would allow data-driven visual effects per animation state.

```anim
// Hypothetical
animation frozen {
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
| 4 | `${state}` interpolation + validation | No | Small |
| 5 | Compact shorthand | Yes (additive) | Medium |
| 6 | Float support | Yes | Small |
| 7 | Named constants | Yes (additive) | Medium |
| 8 | Comparison operators | Yes (additive) | Medium |
| 9 | Typed event data | Yes (additive) | Medium |
| 10 | Remove newlines | Yes (permissive) | Medium |
| 11 | Color metadata | Yes | Medium |
| 12 | Filter declarations | Yes (additive) | Large |
