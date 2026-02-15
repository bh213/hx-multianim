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
- Pattern matching only matches on the **first element** of a case pattern, which is ok as long as you don't want to switch on later tokens.
    ok:
      switch stream {
            case [Token1, Token2, Token3]
            case _:
      }

    not ok:
      switch stream {
            case [Token1, Token2, Token3]
            case [Token1, Token4]:
      }
      Second case will not be considered. 
    Should use:
      switch stream {
            case [Token1]:
                switch stream {
                    case [Token2, Token3]:
                    case [Token4]:
                }
      }

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
    loop: yes | <number>
    playlist {
        sheet: "sprite_$$state$$_name"
        event <name> trigger | random x,y,radius | x,y
    }
    extrapoints {
        @(state=>value) pointName: x,y
        @(state != value) pointName: x,y
        @(state=>[v1,v2]) pointName: x,y
    }
}
```

**Key `.anim` features:**
- `$$stateName$$` - State variable interpolation in sheet names
- `extrapoints` - Named points for effects/interactions (bullets, particles, etc.)
- Conditionals: `@(state=>value)`, `@(state != value)` negation, `@(state=>[v1,v2])` multi-value, `@(state != [v1,v2])` negated multi-value

## .manim Language Quick Reference

### Programmable Elements

```manim
#name programmable(param:type=default) {
  @(condition) element(params): x,y
}
```

**Parameter types**: `uint`, `int`, `float`, `bool`, `string`, `color`, enum (`[val1,val2]`), range (`1..5`), flags

### Common Elements

| Element | Description |
|---------|-------------|
| `bitmap(source, [center])` | Display image |
| `text(font, text, color, [align, maxWidth])` | Text element |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable |
| `placeholder(size, source)` | Dynamic placeholder |
| `reference($ref)` | Reference another programmable |
| `interactive(w, h, id [, debug] [, key=>val ...])` | Hit-test region with optional metadata |
| `layers()` | Z-ordering container |
| `mask(w, h)` | Clipping mask rectangle |
| `flow(...)` | Layout flow container |
| `repeatable($var, iterator)` | Loop elements |
| `tilegroup(...)` | Optimized tile grouping |
| `stateanim construct(...)` | Inline state animation |
| `point` | Positioning point |
| `apply(...)` | Apply properties to parent |
| `graphics(...)` | Vector graphics |
| `pixels(...)` | Pixel primitives |
| `particles {...}` | Particle effects |

### Conditionals

```manim
@(param=>value)           # Match when param equals value
@if(param=>value)         # Explicit @if (same as @())
@ifstrict(param=>value)   # Strict matching (must match ALL params)
@(param != value)         # Match when param NOT equals value
@(param=>[v1,v2])         # Match multiple values
@(param >= 30)            # Greater than or equal
@(param <= 30)            # Less than or equal
@(param > 30)             # Strictly greater than
@(param < 30)             # Strictly less than
@(param => 10..30)        # Range match (10 <= param <= 30)
@else                     # Matches when preceding @() didn't match
@else(param=>value)       # Else-if with conditions
@default                  # Final fallback
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

### Particles Quick Reference

```manim
#effectName particles {
    count: 100
    emit: point(0, 0) | cone(dist, distRand, angle, angleRand) | box(w, h, angle, angleRand) | circle(r, rRand, angle, angleRand)
    tiles: file("particle.png")
    loop: true
    maxLife: 2.0
    speed: 50
    speedRandom: 0.3
    gravity: 100
    gravityAngle: 90
    size: 0.5
    sizeRandom: 0.2
    blendMode: add | alpha
    fadeIn: 0.1
    fadeOut: 0.8
    colorStart: #FF4400
    colorMid: #FFAA00
    colorMidPos: 0.4
    colorEnd: #FFFF88
    sizeCurve: [(0, 0.5), (0.5, 1.2), (1.0, 0.2)]
    velocityCurve: [(0, 1.0), (1.0, 0.3)]
    forceFields: [turbulence(30, 0.02, 2.0), wind(10, 0), vortex(0, 0, 100, 150), attractor(0, 0, 50, 100), repulsor(0, 0, 80, 120)]
    boundsMode: none | kill | bounce(0.6) | wrap
    boundsMinX: -100
    boundsMaxX: 300
    rotationSpeed: 90
    rotateAuto: true
    relative: true
    trailEnabled: true
    trailLength: 0.5
    trailFadeOut: true
    subEmitters: [{ groupId: "sparks", trigger: ondeath, probability: 0.8 }]
}
```

See `docs/manim.md` for full particles documentation.

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
- Repeatable step scale for dx/dy
- HTML text: standalone `HTMLTEXT` element type is deprecated/commented out (the `text(..., html: true)` parameter approach works)
- Double reload issue
- Hex coordinate system offset support

### Next Features
- Particle sub-emitters (parsing and building complete, runtime spawning in `Particles.hx` not yet implemented)

## UI Notes — Interactives

`interactive()` elements create hit-test regions with optional typed metadata:

```manim
interactive(200, 30, "myBtn")
interactive(200, 30, "myBtn", debug)
interactive(200, 30, "myBtn", action => "buy", label => "Buy Item")
interactive(200, 30, $idx, price:int => 100, weight:float => 1.5, action => "craft")
```

Metadata supports typed values matching the settings system: `key => val` (string default), `key:int => N`, `key:float => N`, `key:string => "s"`. Keys and values can be `$references`.

**UI integration:**
- `UIInteractiveWrapper` — thin wrapper implementing `UIElement`, `StandardUIElementEvents`, `UIElementIdentifiable`
- `UIElementIdentifiable` — opt-in interface with `id`, `prefix`, `metadata:BuilderResolvedSettings`
- Screen methods: `addInteractive()`, `addInteractives(result, prefix)`, `removeInteractives(prefix)`
- Events: emits standard `UIClick`, `UIEntering`, `UILeaving` — check `source` for `UIElementIdentifiable` to get `id`/`metadata`

## Playground

Interactive playground at: https://bh213.github.io/hx-multianim/

Features:
- Live examples of UI components
- Real-time `.manim` editing with preview
- Multiple example screens
- Live asset reloading
