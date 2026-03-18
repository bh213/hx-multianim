# Claude AI Instructions for hx-multianim

## Project Overview

**hx-multianim** is a Haxe library for creating animations and pixel art UI elements using the [Heaps](https://heaps.io/) framework. It provides a custom `.manim` language for defining state animations and programmable UI components.

## Key Technologies

- **Language**: Haxe
- **Framework**: Heaps (game/graphics framework)
- **Parser**: Custom hand-written lexer/parser in `MacroManimParser.hx` using `peek()`/`advance()`/`match()`/`expect()` (runs both at compile-time and runtime). `.anim` parser in `AnimParser.hx` is separate.
- **Package Manager**: Lix (recommended)

## Project Structure

| Path | Description |
|------|-------------|
| `src/bh/multianim/MultiAnimParser.hx` | Parser facade — delegates to MacroManimParser |
| `src/bh/multianim/MultiAnimBuilder.hx` | Builder for resolving parsed structures |
| `src/bh/multianim/MacroManimParser.hx` | Main parser for `.manim` files (used at both compile-time and runtime) |
| `src/bh/multianim/ProgrammableCodeGen.hx` | Macro code generation for `@:manim`/`@:data` |
| `src/bh/multianim/ProgrammableBuilder.hx` | Base class for macro-generated factories |
| `src/bh/multianim/LayoutAlignRoot.hx` | Base class for codegen instances with aligned layouts |
| `src/bh/stateanim/AnimParser.hx` | Parser for `.anim` state animation files |
| `test/` | Test suite |
| `lsp/` | Language Server Protocol implementation (Haxe→JS) |
| `vscode/` | VS Code extension (syntax highlighting + LSP client) |

## Build & Run Commands

```bash
# Compile the library
haxe ./hx-multianim.hxml

# Run tests (parsing and rendering verification)
test.bat run        # Run all tests
test.bat run 7      # Run only test #7
test.bat gen-refs   # Generate reference images
test.bat report     # Open test report in browser
```

`test.bat` output is optimized for AI parsing (structured key-value results). Running `hl build/hl-test.hl` directly produces raw trace output not designed for automated consumption.

Playground lives in a separate repository: `../hx-multianim-playground`. Usually running at: http://localhost:3000, if not you can `npm run dev`

## Workflow

1. **Parsing**: `MacroManimParser` converts `.manim` file text to AST with `Node` structures
2. **Building**: `MultiAnimBuilder` resolves references, expressions, and type conversions (runtime)
3. **Macro codegen**: `MacroManimParser` parses `.manim` at compile time, `ProgrammableCodeGen` generates typed Haxe classes

## File Formats

### `.manim` - Multi Animation / UI Elements
Used for programmable UI components, layouts, palettes, and paths.

### `.anim` - State Animations
Used for sprite state animations with playlists. Free-form layout (newlines are whitespace). Structure:

```anim
sheet: sheetName
states: stateName(value1, value2)
center: x,y
allowedExtraPoints: [point1, point2]
fps: 20

@final OFFSET_X = 5

metadata {
    health: 100
    speed: 1.5
    tint: #FF0000
    @(state=>value) damage: 50
    @(state=>other) damage: 30
}

animation animationName {
    fps: 20
    loop: yes | <number>
    playlist {
        sheet: "sprite_${state}_name"
        event <name> trigger | random x,y,radius | x,y
        filter tint: #FF0000
        filter none
    }
    filters {
        tint: #FF0000
        brightness: 0.8
        @(state=>value) outline: 2.0, #FFFF00
        @else pixelOutline: #00FF00
        replaceColor: [#FF0000] => [#0000FF]
    }
    extrapoints {
        @(state=>value) pointName: x,y
        @(state != value) pointName: x,y
        @(state=>[v1,v2]) pointName: x,y
        @(state >= 3) pointName: x,y
        @(state => 1..5) pointName: x,y
        @else pointName: x,y
        @default pointName: x,y
    }
}
```

**Key `.anim` features:**
- `${stateName}` - State variable interpolation in sheet names (validated against defined states)
- `extrapoints` - Named points for effects/interactions (bullets, particles, etc.)
- Conditionals: `@(state=>value)`, `@(state != value)` negation, `@(state=>[v1,v2])` multi-value, `@(state != [v1,v2])` negated multi-value
- Comparison conditionals: `@(state >= N)`, `@(state <= N)`, `@(state > N)`, `@(state < N)`
- Range conditionals: `@(state => min..max)`
- `@else` / `@else(condition)` / `@default` conditionals in extrapoints, metadata, and playlists
- `@final` named constants: `@final X = 42`, usable as `$X` in coordinates
- Compact shorthand: `animation name { ... }` (name as keyword after `animation`)
- `anim` one-liner: `anim name(fps:N, loop:yes): "sheetName"` for simple single-sheet animations
- File-level defaults: `fps:`, `loop:`, `center:` can be set once at file level
- Metadata types: int, float, string, color (`#RRGGBB`)
- Event metadata: `event name { key:type => value, ... }` with typed payload (`TriggerData` event)
- Typed filters: `filters { }` block with `tint`, `brightness`, `saturate`, `grayscale`, `hue`, `outline`, `pixelOutline`, `replaceColor`, `none`. Supports state conditionals (`@()`, `@else`, `@default`). Applied at runtime via `AnimationSM`.
- Playlist filters: `filter tint: #FF0000` / `filter none` entries in playlist for per-frame filter changes
- `AnimMetadata` - Typed metadata access with state-aware matching: `getIntOrDefault(key, default, ?stateSelector)`, `getIntOrException(key, ?stateSelector)`, `getFloatOrDefault(key, default, ?stateSelector)`, `getFloatOrException(key, ?stateSelector)`, `getStringOrDefault(key, default, ?stateSelector)`, `getStringOrException(key, ?stateSelector)`, `getColorOrDefault(key, default, ?stateSelector)`, `getColorOrException(key, ?stateSelector)`. Accessed via `parsed.metadata`.

## Guidelines for Modifications

1. **Always compile after changes**: `haxe hx-multianim.hxml`
2. **Run visual tests**: Verify with `test.bat run`
3. **Keep types consistent**: Use established enum/typedef patterns
4. **Document complex parsing**: Add comments explaining parsing patterns
5. **Update related files**: Changes to parser may require builder/UI updates
6. **Add tests for new features**: See `.claude/rules/testing-and-debugging.md`

## Documentation References

- **`docs/manim.md`**: Full language documentation for `.manim` and `.anim` formats, particles, animated paths, UI components.
- **`docs/manim-reference.md`**: Comprehensive quick-lookup reference of ALL `.manim` elements, properties, and operations. **Always update this file** when adding/changing parser elements, builder features, filters, blend modes, coordinate systems, particle properties, path commands, or any other `.manim` language construct.
- **`docs/manim-cookbook.md`**: Practical pattern-based guide — buttons, tooltips, sidebars, panels, health bars, inventory grids, drag-drop, card hand, dialogue, skill trees, particles, animated paths, character sheets, status effects, data blocks, and Haxe wiring. **Consult this first** when building new screens or UI features.
- **Heaps framework**: https://heaps.io/documentation/home.html — Source: https://github.com/heapsIO/heaps

## Split Documentation

Detailed reference docs are in `.claude/rules/` (auto-loaded):

| File | Content |
|------|---------|
| `manim-language.md` | .manim quick reference: elements, conditionals, expressions, coordinates, filters, particles, animated paths |
| `ui-components.md` | UI element settings, interactives, slots, drag-drop, flow, dynamic refs |
| `testing-and-debugging.md` | Adding tests, testing pitfalls, debug tracing, Haxe pitfalls, environment notes, parser notes |
| `runtime-systems.md` | Card hand helper, TweenManager, screen transitions, modal dialog overlay |
