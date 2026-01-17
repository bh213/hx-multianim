# Claude AI Instructions for hx-multianim

## Project Overview

**hx-multianim** is a Haxe library for creating animations and pixel art UI elements using the [Heaps](https://heaps.io/) framework. It provides a custom `.manim` language for defining state animations and programmable UI components.

## Key Technologies

- **Language**: Haxe
- **Framework**: Heaps (game/graphics framework)
- **Parser**: hxparse (stream-based lexer/parser) - **Modified fork from `github.com/bh213/hxparse`**, not official haxelib
- **Package Manager**: Lix (recommended)

## Project Structure

| Path | Description |
|------|-------------|
| `src/bh/multianim/MultiAnimParser.hx` | Parser for `.manim` animation files |
| `src/bh/multianim/MultiAnimBuilder.hx` | Builder for resolving parsed structures |
| `src/bh/stateanim/AnimParser.hx` | Parser for `.anim` state animation files |
| `playground/` | Web-based playground for testing |
| `playground/public/assets/` | Test `.manim` and `.anim` files |
| `test/` | Test suite |

## Build & Run Commands

```bash
# Compile the library
haxe ./hx-multianim.hxml

# Run tests (parsing and rendering verification)
test.bat run        # Run all tests
test.bat gen-refs   # Generate reference images
test.bat report     # Open test report in browser

# Run playground (requires Node.js)
cd playground
lix download
npm install
npm run dev
```

Playground runs at `http://localhost:3000`.

## Parser Pattern Matching (Important!)

When working with hxparse:
- Pattern matching only matches on the **first element** of a case pattern
- Use nested `switch` statements for multi-token matching
- For `[Token1, Token2, Token3]`, create separate switches for each token
- Reference: https://github.com/Simn/hxparse

## Workflow

1. **Parsing**: Converts `.manim`/`.anim` file text to AST with `Node` structures
2. **Building**: Resolves references, expressions, and type conversions

## File Formats

### `.manim` - Multi Animation / UI Elements
Used for programmable UI components, layouts, palettes, and paths.

### `.anim` - State Animations
Used for sprite state animations with playlists. Structure:

```anim
sheet: sheetName
states: stateName(value1, value2)
center: x,y
allowedExtraPoints: [point1, point2]

animation {
    name: animationName
    fps: 20
    loop: untilCommand | yes | <number>
    playlist {
        sheet: "sprite_$$state$$_name"
        loop <count> { ... }
        event <name> trigger | random x,y,radius | x,y
        command
        goto <animName>
    }
    extrapoints {
        @(state=>value) pointName: x,y
    }
}
```

**Key `.anim` features:**
- `$$stateName$$` - State variable interpolation in sheet names
- `loop untilCommand` - Loop until command queue has entry
- `extrapoints` - Named points for effects/interactions (bullets, particles, etc.)
- `goto` - Transition to another animation
- `command` - Execute next command from queue

## .manim Language Quick Reference

### Programmable Elements

```manim
#name programmable(param:type=default) {
  @(condition) element(params): x,y
}
```

**Parameter types**: `uint`, `int`, `bool`, `string`, `color`, enum (`[val1,val2]`), range (`1..5`), flags

### Common Elements

| Element | Description |
|---------|-------------|
| `bitmap(source, [center])` | Display image |
| `text(font, text, color, [align, maxWidth])` | Text element |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable |
| `placeholder(size, source)` | Dynamic placeholder |
| `reference($ref)` | Reference another programmable |
| `layers()` | Z-ordering container |
| `repeatable($var, iterator)` | Loop elements |
| `graphics(...)` | Vector graphics |
| `pixels(...)` | Pixel primitives |

### Conditionals

```manim
@(param=>value)           # Match when param equals value
@(!param=>value)          # Match when param NOT equals value
@(param=>[v1,v2])         # Match multiple values
@(param=>greaterThanOrEqual 30)  # Range comparisons
```

### Expressions

- Operators: `+`, `-`, `*`, `/`, `%`, `div`
- References: `$paramName`
- Ternary: `?(condition) trueValue : falseValue`
- Callbacks: `callback("name")`, `callback("name", $index)`

### Coordinate Systems

- Offset: `x,y`
- Grid: `grid(x, y [, offsetX, offsetY])`
- Hex: `hex(q, r, s)`, `hexCorner(index, scale)`, `hexEdge(index, scale)`
- Layout: `layout(layoutName [, index])`

### Filters

`outline`, `glow`, `blur`, `saturate`, `brightness`, `dropShadow`, `replacePalette`, `replaceColor`, `pixelOutline`, `group`

## UI Elements Notes

- **Dropdown**: Uses closed button + scrollable panel, moves panel to different layer
- **UIScreen**: If elements don't show or react to events, check if added to UIScreen's elements
- **Macros**: `MacroUtils.macroBuildWithParameters` maps `.manim` elements to Haxe code

## Guidelines for Modifications

1. **Always compile after changes**: `haxe hx-multianim.hxml`
2. **Run visual tests**: Verify with `test.bat run`
3. **Keep types consistent**: Use established enum/typedef patterns
4. **Document complex parsing**: Add comments explaining stream patterns
5. **Update related files**: Changes to parser may require builder/UI updates
6. **Add tests for new features**: See "Adding a New Test" section below

## Adding a New Test

Tests are visual screenshot comparisons. To add a new test:

1. **Create test directory**: `test/examples/<N>-<testName>/` (N = next number, e.g., `22-myFeatureDemo`)

2. **Create `.manim` file**: `test/examples/<N>-<testName>/<testName>.manim` with a programmable named after the test feature

3. **Add test method** in `test/src/bh/test/examples/AllExamplesTest.hx`:
   ```haxe
   @Test
   public function test<N>_<TestName>(async:utest.Async) {
       this.testName = "<testName>";
       this.referenceDir = "test/examples/<N>-<testName>";
       buildRenderScreenshotAndCompare("test/examples/<N>-<testName>/<testName>.manim", "<programmableName>", async, 1280, 720);
   }
   ```

4. **Add to `test.bat`** in the `gen_refs` section:
   ```batch
   if exist "%ROOT%test\screenshots\<testName>_actual.png" (
       copy /Y "%ROOT%test\screenshots\<testName>_actual.png" "%ROOT%test\examples\<N>-<testName>\reference.png" >nul
       echo   <N> - <testName>
   )
   ```

5. **Generate reference image**:
   - Run `test.bat run` to generate screenshot
   - Run `test.bat gen-refs` to copy as reference
   - Verify with `test.bat run` again (should pass)

## Debug Tracing

Enable debug traces by adding to HXML:
```hxml
-D MULTIANIM_TRACE
```

## Current TODO Items

### Fixes Needed
- Repeatable grid scale for dx/dy
- HTML text implementation
- Double reload issue
- Hex coordinate system offset support

### Next Features
- Conditionals ELSE support
- Particle system (loop, animSM, events)
- Animation paths with easing & events

## Playground

Interactive playground at: https://bh213.github.io/hx-multianim/

Features:
- Live examples of UI components
- Real-time `.manim` editing with preview
- Multiple example screens
- Live asset reloading
