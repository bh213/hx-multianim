# Changelog

## [0.13-dev] - 2026-02-19

### Added
- **Parameterized slots** — `#name slot(param:type=default, ...)` for visual state management
  - Supports all parameter types: `uint`, `int`, `float`, `bool`, `string`, `color`, enum, range, flags
  - Conditionals (`@()`, `@else`, `@default`) and expressions (`$param`) work inside slot body
  - `SlotHandle.setParameter("name", value)` updates visuals via `IncrementalUpdateContext`
  - Content goes into separate `contentRoot` (decoration always visible, not hidden by `setContent`)
  - Codegen: warning emitted, `setParameter()` not supported (use runtime builder)
- **Enhanced SlotHandle API** — `isEmpty()`, `isOccupied()`, `data` field for arbitrary payload storage
- **UIElement double-click support** — `UIDoubleClick` event and double-click detection in UI elements
- **Progress bar component** — `UIMultiAnimProgressBar` display-only component
  - Uses full rebuild (not incremental) because `bitmap(generated(color(...)))` is not tracked
  - Screen helper: `addProgressBar(builder, settings, initialValue)`
- **Direct `$var` in text** — text elements can now use parameter references directly (e.g. `$w`)
- **Dropdown with scroll** — dropdown panel now supports scrollable content for long lists, moves panel to different layer
- **Slider custom float range** — `min`, `max`, `step` settings for sliders
  - Implements both `UIElementNumberValue` (int) and `UIElementFloatValue` (float)
  - Incremental mode for efficient redraws
  - Emits both `UIChangeValue(Int)` and `UIChangeFloatValue(Float)`
- **Draggable slot integration** — `UIMultiAnimDraggable` enhancements
  - `addDropZonesFromSlots("baseName", builderResult, ?accepts)` for batch drop zone creation
  - `createFromSlot(slot)` creates draggable from slot content, tracks `sourceSlot`
  - `swapMode` swaps contents when dropping onto an occupied slot
  - Zone highlight callbacks: `onDragStartHighlightZones`, `onDragEndHighlightZones`
  - Per-zone: `DropZone.onZoneHighlight` callback for hover state
- **Scrollable list scrollbar** — built with incremental mode, scroll events use `setParameter("scrollPosition", ...)` instead of full rebuild
- **Parser error tests** — `ParserErrorTest.hx` for comprehensive parser error validation
- **Inline easing in animatedPath curve slots** — `alphaCurve: easeInQuad` works directly without requiring a `curves{}` block
- **AnimatedPath `easing:` shorthand** — `easing: easeOutCubic` as shortcut for `0.0: progressCurve: easeOutCubic`
- **Multi-color curve stops** — per-segment color pairs in animatedPath: multiple `colorCurve` assignments at different rates, each with its own start/end colors (e.g. red→green at 0.0, green→blue at 0.5)
- **`pathGuide` force field** — `pathguide(pathName, attractStrength, flowStrength, radius)` attracts particles toward a named path and nudges them along its direction
- **`Path.getClosestRate(point)`** — reverse lookup to find the closest rate (0..1) on a path to a given world point; uses coarse sampling + golden-section refinement
- **`createProjectilePath()` helper** — `builder.createProjectilePath("name", startPoint, endPoint)` convenience method using Stretch normalization
- **AnimatedPath non-visual unit tests** — 15 new tests in BuilderUnitTest covering time/distance modes, inline easing, easing shorthand, events, loop, pingPong, seek, checkpoints, custom curves, multi-color stops, projectile helper, getClosestRate
- **Font metrics context** — `$ctx.font("name").lineHeight` and `$ctx.font("name").baseLine` for querying font metrics at build time (both builder and codegen)
- **Pixel data unit tests** — filledRect pixel verification and incremental pixel update sweep tests

### Fixed
- **Pixels position scaling** — `pixels` element position offset now scales correctly when `scale > 1` (previously offset was unscaled, causing misalignment)
- **Float precision in `setParameter`** — `IncrementalUpdateContext.setParameter` now preserves float values via `ValueF()` instead of truncating to `Int`
- **`${...}` expression parsing** — parser now correctly handles `${...}` expressions in `.manim` files
- **Static/dynamic ref inheritance** — fixed scope and inheritance issues between staticRef/dynamicRef
- **Button bug in `resolveExtraInput`** — fixed crash in button event resolution
- **`generated(cross())` rendering** — corrected cross generation in multiple files
- **Expression priority** — fixed operator precedence in conditional expressions

### Changed
- **Slot storage refactored** — changed from `Map<String, SlotHandle>` to array-based `SlotKey` storage supporting `Named(name)` and `Indexed(name, index)` keys
- **Removed `PVObject` support for UI elements** — removed error-prone `PVObject` path; `PVFactory` is now the only supported approach for UI element parameters in `macroBuildWithParameters`
- **Animated path improvements** — better path normalization, enhanced speed/duration/easing support
- **Playground removed from repository** — moved to separate `../hx-multianim-playground` repository

## [0.12] - 2026-02-16

### Changed
- **BREAKING: `reference` → `staticRef`, `component` → `dynamicRef`** — DSL keywords, enum variants, and all Haxe API methods renamed
  - `.manim` syntax: `reference(...)` → `staticRef(...)`, `component(...)` → `dynamicRef(...)`
  - Builder API: `getComponent("name")` → `getDynamicRef("name")`, `components` map → `dynamicRefs`
  - Codegen API: `buildReference()` → `buildStaticRef()`, `buildComponent()` → `buildDynamicRef()`
  - Parser accepts both old and new keywords for backward compatibility
- **BREAKING: `.manim` version bump 0.3 → 0.5** — All `.manim` files must use `version: 0.5`

### Added
- **Interactive metadata** — `interactive()` now supports optional key=>value metadata with typed values
  - Syntax: `interactive(w, h, id [, debug] [, key => val, ...])`
  - Typed values matching settings system: `key => "str"`, `key:int => 100`, `key:float => 1.5`, `key:string => "text"`
  - Keys and values can be `$references` (resolved at build time)
  - Resolved metadata uses `ResolvedSettings` (`Map<String, SettingValue>`) with `RSVString/RSVInt/RSVFloat`
- **UIInteractiveWrapper** — Thin `UIElement` wrapper for interactive MAObjects
  - Implements `UIElement`, `StandardUIElementEvents`, `UIElementIdentifiable`
  - Exposes `id`, `prefix`, `metadata:BuilderResolvedSettings` for typed access
  - Emits standard `UIClick`/`UIEntering`/`UILeaving` — check `source` for `UIElementIdentifiable` to access `id`/`metadata`
- **UIElementIdentifiable** — New opt-in interface for UI elements that carry an identifier and metadata
  - `id:String`, `prefix:Null<String>`, `metadata:BuilderResolvedSettings`
- **Screen interactive management** — `UIScreenBase` methods for adding/removing interactive wrappers
  - `addInteractive(obj, prefix)` — wraps single MAObject
  - `addInteractives(result, prefix)` — wraps all interactives from a BuilderResult
  - `removeInteractives(prefix)` — removes wrappers by prefix (or all if null)
- **`@final` constants** — Declare immutable named constants in `.manim` to avoid repeating expressions
  - Syntax: `@final name = expression` — evaluated once, reusable via `$name`
  - All parameter types supported: uint, int, float, bool, string, color, arrays
  - Block scoping: every `{ }` creates a scope, constants cleaned up on exit
  - Works inside repeatable blocks (re-evaluated per iteration)
  - Chaining: `@final b = $a + 1` where `a` is also a `@final`
  - Error detection: duplicate names, parameter shadowing
  - Full macro codegen support (inlined at usage sites)
- **Easing system** — 12 named easing functions + cubic bezier for animation timing
  - `EasingType` enum: Linear, EaseIn/Out/InOutQuad, EaseIn/Out/InOutCubic, EaseIn/Out/InOutBack, EaseOutBounce, EaseOutElastic, CubicBezier(x1,y1,x2,y2)
  - All functions implemented in `FloatTools.applyEasing()` with Newton-Raphson solver for cubic bezier
- **1D Curves** — New `curves` top-level element for mapping 0→1 input to float output
  - Easing-based curves: `#name curve { easing: easeOutQuad }`
  - Point-based curves: `#name curve { points: [(0, 0.2), (0.5, 1.0), (1.0, 0.3)] }`
  - Runtime `Curve` class with `getValue(t):Float`
  - Macro codegen: `getCurve_<name>()` factory methods (easing-only curves baked inline at compile time)
- **AnimatedPath easing** — Duration+easing mode for animated paths
  - `animatedPath { easing: easeInOutQuad  duration: 0.8 }` syntax
  - `createWithDurationAndEasing()` factory alongside existing speed-based creation
  - Timed actions still fire at correct rates under easing
- **Path normalization** — Scale any path to fit between arbitrary start/end points
  - `Path.normalize(startPoint, endPoint)` applies affine transform (scale + rotation + translation)
  - `SinglePath.transform()` handles all path types including arc radius/angle adjustment
  - `getPath(name, startPoint, endPoint)` applies normalization when both points provided
- **Paths/curves macro codegen** — ProgrammableCodeGen generates typed factory methods
  - `getPath_<name>(?startPoint, ?endPoint):Path` for each named path
  - `getPath(name, ?startPoint, ?endPoint):Path` generic accessor
  - `createAnimatedPath_<name>(path, speed, positionMode, object):AnimatedPath`
  - `getCurve_<name>():Curve` with compile-time baking for simple curves
- **Array parameter macro support** — `param:array=[val1,val2]` now fully supported in ProgrammableCodeGen macro codegen
  - Generates typed `Array<String>` fields with null-default + constructor fallback
  - `RVElementOfArray` resolves array element access (`$arr[$i]`) in expressions
  - `ArrayIterator` in `repeatable($i, array($val, $arr))` generates runtime pool loops with value variable
  - TEXT elements supported inside runtime repeat loops
- **`createFrom()` named-parameter factory method** — generated alongside `create()` for every `@:manim` programmable. Takes an anonymous struct with named fields matching the `.manim` parameter names. Optional parameters (those with defaults) can be omitted from the struct.
  ```haxe
  var dlg = ui.dialog.createFrom({w: 400, title: "My Dialog"});  // named params
  var dlg2 = ui.dialog.createFrom({});                            // all defaults
  ```
- **Data blocks** — New `#name data { }` root-level element for defining static typed data in `.manim` files
  - Scalar fields with type inference: `maxLevel: 5`, `name: "Warrior"`, `enabled: true`, `speed: 3.5`
  - Arrays: `costs: [10, 20, 40, 80]`
  - Named record types: `#tier record(name: string, cost: int, dmg: float)` with schema validation
  - Optional record fields: `?fieldName: type` — omitted fields generate `Null<T>`, can be skipped in record values
  - Record-typed fields: `defaultTier: tier { name: "None", cost: 0, dmg: 0.0 }`
  - Arrays of records: `tiers: tier[] [{ name: "Bronze", cost: 10, dmg: 1.0 }]`
  - Builder: `getData("name")` returns `Dynamic` with all fields
  - Macro: `@:data("file.manim", "name")` generates typed classes with `public final` fields and record typedefs
  - Exposed type naming: record types named `PascalCase(dataName) + PascalCase(recordName)` (e.g., `GameDataTier` for `#tier` in `#gameData`)
  - Custom type package: `@:data("file.manim", "name", "my.pkg")` puts generated record types in specified package
  - `mergeTypes` flag: `@:data("file.manim", "name", "pkg", mergeTypes)` deduplicates identical record types across multiple `@:data` fields
  - Type collision detection: fatal error if generated type name already exists
- **Flow improvements** — new optional parameters on `flow()`: `overflow` (expand/limit/scroll/hidden), `fillWidth`, `fillHeight`, `reverse`
  - New `spacer(width, height)` element for fixed spacing inside flows
- **Indexed named elements** — `#name[$i]` syntax inside `repeatable` creates per-iteration named entries
  - Builder: `result.getUpdatableByIndex("name", index)` for typed access
  - Codegen: generates `get_name(index:Int)` accessor methods
- **Slot element** — `#name slot { ... }` creates swappable containers with default content
  - Indexed variant `#name[$i] slot { ... }` inside repeatables creates per-iteration slots
  - `SlotHandle` API: `setContent(obj)`, `clear()`, `getContent()` for runtime replacement
  - Builder: `result.getSlot("name")` or `result.getSlot("name", index)` with mismatch validation
  - Codegen: generates `getSlot_name()`, `getSlot_name(index)`, and generic `getSlot("name", ?index)`
- **Builder incremental update** — opt-in mode for updating parameters without rebuilding the h2d tree
  - Enable via `buildWithParameters(..., incremental: true)`
  - `result.setParameter("name", value)` re-evaluates conditionals and expressions in-place
  - `beginUpdate()`/`endUpdate()` for batching multiple parameter changes
  - Tracks conditional visibility chains and expression-dependent properties
- **Dynamic ref element** — `dynamicRef($ref, params)` (formerly `component`) embeds a programmable with incremental mode
  - Like `staticRef` but supports runtime parameter changes via `setParameter()`
  - Stored in BuilderResult: `result.getDynamicRef("name")` returns sub-`BuilderResult`
  - Supports `external()` references for cross-file dynamic refs
- **HTML report: unit test section** — test runner results now displayed in HTML report with expandable per-class/method details, pass/fail status, and failure messages
- **`tile` parameter type** — new `.manim` parameter type for passing tile sources at runtime
  - Syntax: `name:tile` — no default value allowed
  - Use with `bitmap($name)` to display caller-provided tiles
  - Macro codegen: maps to `Dynamic` (pass `h2d.Tile` at runtime)
  - Builder: pass via `TileHelper.sheet("atlas", "tile")`, `TileHelper.file("img.png")`, or `TileHelper.sheetIndex("atlas", "tile", idx)`
- **`TileRef` enum for `UIElementListItem`** — structured tile references replace plain `tileName` string
  - `TRFile(filename)`, `TRSheet(sheet, name)`, `TRSheetIndex(sheet, name, index)`, `TRTile(tile)`
  - `TRGeneratedRect(w, h)`, `TRGeneratedRectColor(w, h, color)` for generated solid-color rectangles
  - New `tileRef` field on `UIElementListItem`; legacy `tileName` still supported
  - `UIElementBuilder.buildItem()` now correctly sets the `images` parameter (fixes tile display in list items)
- **`TileHelper`** — static helper class for creating tile builder parameters
  - `TileHelper.file("img.png")`, `TileHelper.sheet("atlas", "tile")`, `TileHelper.sheetIndex("atlas", "tile", idx)`
  - `TileHelper.generatedRect(w, h)`, `TileHelper.generatedRectColor(w, h, color)` for solid-color tiles
  - Returns `ResolvedIndexParameters` for use with `buildWithParameters()` param maps

### Fixed
- **Codegen `generated(color())` division** — expressions using `/` in width/height (e.g. `$value * $barWidth / $maxValue`) now wrapped with `Std.int()` to produce correct `Int` arguments for `h2d.Tile.fromColor`
- **Codegen DCE stripping setters** — generated Instance classes now annotated with `@:keep` metadata to prevent dead code elimination from removing setter methods when instances are accessed through `Dynamic`

## [0.4]

### Added
- **ProgrammableCodeGen macro** — compile-time code generation for `.manim` programmable elements
  - `@:build(ProgrammableCodeGen.buildAll())` on a factory class with `@:manim("path", "name")` field annotations
  - Generates companion classes with typed `create()` factory and `setXxx()` parameter setters
  - Inline `MacroManimParser` parses `.manim` files at compile time (no subprocess)
  - Elements: bitmap, text, ninepatch, flow, layers, mask, point, interactive, staticRef, graphics, placeholder
  - Conditionals: `@(p=>v)`, `@(p!= v)`, `@(p=>[v1,v2])`, ranges, `@else`, `@default`
  - Full expression support: `$param`, arithmetic, ternary, comparisons
  - Properties: scale, alpha, blendMode, tint, filters — all with param-dependent runtime updates
  - All coordinate types: offset, grid, hex (position/corner/edge), layout
  - REPEAT/REPEAT2D: compile-time unroll (static) or runtime pool (param-dependent) for all iterator types
  - Placeholder delegation to `ProgrammableBuilder.buildPlaceholderVia*()` methods
  - Instance-based factory pattern: `mp.button.create(params)` instead of static `create(builder, params)`
  - All parameter types: enum, bool, int, uint, float, string, color, range, flags
  - 16 visual tests (builder vs macro screenshot comparison)
- **.anim conditionals: negation and multi-value** - Ported subset of .manim conditional system to .anim
  - `@(state != value)` - negation: match when state does NOT equal value
  - `@(state=>[v1,v2])` - multi-value: match when state is any of the listed values
  - `@(state != [v1,v2])` - negated multi-value: match when state is NOT any of the listed values
  - Works on animations, playlists, extrapoints, and metadata
- **Autotile region sheet visualization** - New `autotileRegionSheet` generated tile type for debugging autotile tilesets
  - Displays the complete region of an autotile with a numbered grid overlay
  - Helps visually identify which tile index corresponds to which visual tile in the source image
  - Syntax: `generated(autotileRegionSheet("autotileName", scale, "font", fontColor))`
  - Scales tiles but keeps font at original size for readability on small tiles (e.g., 8x8)
- **Negative range parameters** - Range definitions now support negative numbers (e.g., `param:-50..150`)
- **Symbolic conditional operators** - New concise syntax for conditional comparisons:
  - `@(param >= N)`, `@(param <= N)`, `@(param > N)`, `@(param < N)` - comparison operators
  - `@(param != value)` - not-equals operator
  - `@(param => N1..N2)` - bare range syntax (replaces `between` keyword)
  - Old keyword syntax (`greaterThanOrEqual`, `lessThanOrEqual`, `between`, `=>!`) still supported
- **@else / @default conditionals** - New conditional constructs for fallback logic:
  - `@else` — matches when no prior sibling's `@()` condition matched
  - `@else(conditions)` — like `@else` but with additional conditions
  - `@default` — always matches when no prior sibling matched (unconditional fallback)
  - Parser validates proper ordering (must follow a sibling with `@()` conditional)
- **Conditionals demo** - Comprehensive demo showing all conditional features:
  - `@(param=>value)` exact match, `@(param != value)` negation
  - `@(param=>[v1,v2])` multiple values, `@(p1=>v1, p2=>v2)` combined conditions
  - Range conditions: `>=`, `<=`, `>`, `<`, `N..N`
  - `@ifstrict` - requires ALL parameters to match (partial params = no match)
- **Autotile system** - New root-level element for procedural terrain generation
  - Formats: `cross` (13 tiles), `blob47` (47-tile full coverage)
  - Neighbor-based tile selection with inner/outer corner handling
  - Demo mode with `demo: edgeColor, fillColor` for placeholder tile visualization
- **Autotile reference syntax** - Reference autotile demo tiles in generated() expressions
  - By index: `generated(autotile("autotileName", 0))` - select tile by index
  - By edges: `generated(autotile("autotileName", N+E+S+W))` - select tile by neighbor flags
  - Edge flags: `N`, `E`, `S`, `W` (cardinals), `NE`, `SE`, `SW`, `NW` (corners)
- **Font management** - `FontManager.registerFont()` with optional X/Y offset for positioning normalization
- **Graphics coordinates** - `line()` and `polygon()` now support all coordinate types (hexCorner, hexEdge, grid, layout)
- **New fonts** - f3x5, m3x6, pixeled6, pixellari, peaberry-white, peaberry-white-outline
- **Test infrastructure** - HTML report generator with visual diffs, improved test runner

### Playground
- **Layout overhaul** - Canvas and console are now both always visible (vertical split), replacing the old tabbed layout
- **Triple-reload fix** - Selecting a screen no longer triggers 3 redundant reloads; consolidated to a single useEffect
- **Error handling** - Extracted shared error parsing into `errorUtils.ts`, removing ~100 lines of duplication
- **Data consolidation** - Single `SCREEN_DATA` array as source of truth for screens and manim files
- **Dead code cleanup** - Removed ~150 lines of unused CSS, dead DOM references, debug console.logs, unused interface
- **Example files improved** - Cleaned up all 8 weak/minimal .manim examples: added titles, descriptive comments, fixed invisible text colors (`#ffffff00` → `#ffffffaa`), removed commented-out code and unused layouts

### Fixed
- **GridDirection conditional validation** - Fixed `gridDirection` parameter validation in conditionals accepting only 0-3 instead of full 0-7 range (8 directions)
- **Anim parser negative frame indices** - Added validation to reject negative frame indices in `.anim` playlist `frames:` ranges
- **Text alignment with scale** - Center/right alignment now works correctly at any scale factor
- **Graphics line parsing** - `GELine` and `GEPolygon` use `Coordinates` type instead of individual floats

### Changed
- **Quiet test output** - Tests now only show errors by default; use `test.bat run -v` for verbose output
- **HTML report overlay** - Image lightbox now uses 100% opaque background
- Updated all test examples with consistent styling and smaller label fonts (m3x6)
- Improved hex coordinate demo showing both pointy and flat orientations with corner/edge labels
- **tilesIteration test cleanup** — scaled tile sections to 0.5x with 24-column layout so all tiles fit within viewport
- **codegenHexPos test cleanup** — reduced hex scale from 4x to 2x so both pointy and flat hexes are fully visible
