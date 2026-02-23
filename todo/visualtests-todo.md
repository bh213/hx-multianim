# Visual Tests Improvement Plan

## Test 10 — `referenceDemo` (staticRef)
**Current state:** Shows 4 colored rectangles/triangles using `staticRef`. Background is dim gray. Has a rect and 3 triangles positioned sparsely. Uses 1280x720 grid at 1.0 scale.
**Problem:** Looks empty — lots of unused space, minimal visual content.
**Plan:**
- Add more `staticRef` instances with varied sizes, colors, and shapes to fill the canvas
- Add a row of small rects across the top, a cluster of triangles in different orientations
- Add labels (text elements) identifying each shape and its parameters (width, height, color)
- Add a title text at top: "staticRef Demo — Embedding Sub-Programmables"
- Consider adding a new shape option (e.g., `circle` via `pixels` with circle command, or `cross`) to the item programmable
- Use the grid to create a more organized layout

---

## Test 15 — `stateAnimConstructDemo` (inline stateAnim)
**Current state:** Shows one text label "state1", one `stateAnim construct` at scale 4, and a pink rect outline. Most of the 1280x720 canvas is empty.
**Problem:** Looks empty — only one animation instance with a label.
**Plan:**
- Add multiple `stateAnim construct` instances showing different states/configurations
- Add a second stateAnim in "state1" next to the "state2" one for visual comparison
- Add text labels explaining what each instance shows ("state1 — indexed tile, looping", "state2 — tile center, no loop")
- Add a pink/magenta rect outline around each stateAnim for framing
- Add a title: "stateAnim construct — Inline State Animations"
- Position instances in a structured grid layout using the 1280x720 space

---

## Test 32 — `namedFilterParams` (filters with named params)
**Current state:** Shows 7 small colored squares (40x40) with various filters (outline, blur, brightness, saturate) arranged in 2 rows. Very compact in top-left corner.
**Problem:** Small, hard to see filter effects at this scale. Lots of empty space.
**Plan:**
- Increase bitmap sizes (e.g., 80x80 or 100x100) so filter effects are more visible
- Add more filter types: `glow`, `dropShadow`, `grayscale`, `hue`, `pixelOutline`
- Add text labels below each square naming the filter and its params
- Add a "positional vs named" comparison section showing same filter both ways side-by-side
- Add a row showing combined/stacked filters (e.g., outline + blur)
- Add a title: "Named Filter Parameters"
- Use full canvas width with organized columns

---

## Test 44 — `codegenReference` (codegen staticRef)
**Current state:** Three colored rectangles (red, green, blue) at 100x80, arranged horizontally at scale 4.0.
**Problem:** Extremely minimal — just 3 colored rects. Doesn't test much beyond basic staticRef in codegen.
**Analysis:** This overlaps significantly with test 10 (`referenceDemo`) which already tests `staticRef` more thoroughly.
**Plan (Option A — Improve):**
- Add nested references (staticRef inside a staticRef's programmable)
- Add references with conditional parameters
- Add references at different positions, scales, alphas
- Add text labels for each
**Plan (Option B — Mark as redundant):**
- If test 10 is improved to cover codegen path, this test may be removable
- Check if test 10 already uses `builderAndMacroScreenshotAndCompare` (it does) — so codegen IS tested there
- **Recommendation:** Keep but enhance — add nested refs and conditional params to differentiate from test 10

---

## Test 46 — `codegenGridPos` (layout repeatable in codegen)
**Current state:** Two sets of colored rectangles positioned via layouts — 4 blue ones from `posLayout` and 3 pink ones from `colLayout`.
**Problem:** Minimal test — just verifies basic layout positioning works in codegen. Not testing much unique functionality.
**Analysis:** Layout positioning is tested in several other tests (82, 86). This test specifically tests `layout("main", "posLayout")` syntax with named layouts.
**Plan:**
- This IS a useful test — it tests named layout references in codegen specifically
- Add more layout variations: different layout names, larger point counts
- Add overlapping layouts to test priority/ordering
- Add text at each layout point showing the index
- Add a third layout in a different arrangement (diagonal, circular pattern)
- Add title text explaining what's being tested

---

## Test 51 — `codegenParticles` (particle codegen)
**Current state:** Single cone emitter at center with 100 particles, seeded random for determinism. Shows particles mid-flight after 1.5s advance.
**Plan:**
- Add more particle configurations side-by-side:
  - `point` emitter (simple burst)
  - `box` emitter
  - `circle` emitter
  - Different blend modes (`add` vs `alpha`)
  - Different gravity directions
  - Color curves
- Use deterministic random (seed 42 already) — just add more groups
- Position each emitter group in a different quadrant of the 1280x720 canvas
- Add small text labels for each configuration
- Increase particle count slightly per group but keep total reasonable

---

## Test 56 — `codegenGridFunc` ($grid.width/height in codegen)
**Current state:** 3 green rectangles in a diagonal staircase pattern using `$grid.width` and `$grid.height` in expressions. Scale 4.0.
**Problem:** Very minimal — only tests `$grid.width/$grid.height` multiplication in one repeatable.
**Plan:**
- Add a second grid with different spacing (e.g., `grid: 40, 30` via a second programmable or named grid)
- Add named grids: `grid: #large 120, 80` and `grid: #small 40, 30` and reference both
- Use `$grid.width` and `$grid.height` in more complex expressions
- Add `repeatable2d` using grid spacing
- Add text showing computed values
- Create a checkerboard pattern or grid layout using `$grid` references
- Reference grids by name with `$grid("large")` syntax if supported, otherwise use named grid references

---

## Test 70 — `indexedNamed` (#name[$i] indexed elements)
**Current state:** 4 iterations showing index number text + brown square. Very small, at 1.0 scale, everything crammed in top-left.
**Problem:** Horrible — tiny, nothing meaningful to see. Doesn't demonstrate the power of indexed naming.
**Plan:**
- Switch to scale 4.0 or use larger elements
- Make each indexed element visually distinct (different colors per index using conditionals)
- Add multiple indexed element types: `#label[$i]`, `#icon[$i]`, `#bg[$i]`
- Show that elements can be accessed by index — use different colors: `@($i => 0) color1`, `@($i => 1) color2`, etc.
- Add a larger repeatable count (6-8 items) in a grid arrangement
- Add descriptive text: "Indexed Named Elements — #name[$i]"
- Include both horizontal and vertical repeatables to show 2D indexing potential

---

## Test 71 — `slotDemo` (basic slots)
**Current state:** 3 button-like ninepatch containers with gray slots and index labels, plus a footer slot with "default" text. Scale 1.0.
**Suggestions:**
- Add a section showing slots in different states (some with content, some empty) to visualize the slot concept better
- Add visual borders/outlines to slot areas to make the "slot" concept clearer
- Add text labels: "slot with default content", "indexed slot #0", etc.
- Show slot content replacement visually — have one slot with different default content (e.g., a colored icon instead of gray)
- Add a title and description text
- Increase scale or element sizes for better visibility
- Add a non-indexed `#single slot` alongside the indexed `#icon[$i] slot` for comparison

---

## Test 75 — `progressBarDemo` (progress bars)
**Current state:** Three different progress bar styles shown at multiple values using custom test code with `UIMultiAnimProgressBar`. Already quite comprehensive.
**Problem:** Bottom half of the screen has unused space.
**Plan:**
- Add descriptive text in the bottom half explaining what's being tested:
  - "Top row: Standard progress bar with value label"
  - "Middle rows: Compact bars with label prefix"
  - "Bottom rows: Centered value text, inner fill"
- Add text showing the color thresholds: "0-25: red, 26-60: orange, 61-100: green"
- Add a title: "Progress Bar Variants"
- Show edge cases: value=0, value=100 explicitly labeled

---

## Test 76 — `comboUnconditional` (unconditional children in conditional programmables)
**Current state:** Shows a button programmable in 6 states (normal/hover/pressed x enabled/disabled). Each has "Shared Text" and an orange square that should appear in all states. Has explanatory text at top.
**Problem:** "Shared Text" label on each button is confusing — what does it mean?
**Plan:**
- Rename "Shared Text" to something clearer like "Always Visible" or "Unconditional"
- Change the top description from "Shared Text" to explain: "Orange square + text are unconditional — they appear regardless of state"
- Add a visual indicator (arrow or bracket) pointing to the unconditional elements
- Consider adding a second programmable that does NOT have unconditional children for comparison
- Make the orange square more prominent (larger, or use a distinctive shape)

---

## Test 81 — `slotParams` (parameterized slots)
**Current state:** 3 indexed slots with state enum (empty/filled/highlight) showing as colored rectangles, plus a single bool slot. Scale 4.0. All showing default state.
**Problem:** Only shows default states — doesn't visually demonstrate parameter changes.
**Plan:**
- Add text inside each slot showing the current state name ("empty", "filled", "highlight")
- Set different initial states for each slot so all states are visible:
  - slot 0: `state=>empty` (gray)
  - slot 1: `state=>filled` (green)
  - slot 2: `state=>highlight` (orange)
- Add the `#single` slot with `active=>true` to show both states
- Add text at the bottom explaining what's being tested: "Parameterized Slots — each slot has state:enum parameter"
- Use `layout` with `align` to position explanatory text at bottom
- Include text showing expected colors for each state

---

## Test 82 — `layoutMultiChild` (layout bug fix — multiple children per iteration)
**Current state:** 6 positions in a 3x2 grid, each with a red rect + blue rect overlapping. Scale 4.0. Colors are all the same.
**Problem:** Plain colored rectangles, hard to see the "multiple children at same position" aspect.
**Plan:**
- Use more saturated/vivid colors (bright magenta, cyan, yellow instead of basic red/blue)
- Make the overlapping more visually clear — use semi-transparency or offset slightly
- Add index text (`$i`) in the center of each cell
- Add more children per iteration (3-4 elements) to really demonstrate the fix
- Add a descriptive title: "Layout Multi-Child: All children share same layout point"

---

## Test 83 — `slot2dIndex` (2D indexed slots)
**Current state:** 3x2 grid of gray slots, each showing "empty 2d slot" text and coordinates. Scale 4.0.
**Problem:** All slots look identical (all default state). Doesn't demonstrate that 2D indexing actually works.
**Plan:**
- Programmatically update slot [2,1] (or similar) in the test code to prove index addressing works
- Add a colored rect/circle into the updated slot to make it visually distinct
- Change the test from `simpleMacroTest` to custom test code that:
  1. Creates the programmable
  2. Gets slot at `result.getSlot("cell", 2, 1)` (or equivalent 2D index)
  3. Sets content to a brightly colored element
  4. Then screenshots
- Add different default colors per row or column using conditionals on `$x` or `$y`
- Add text at bottom: "Slot [2,1] programmatically updated"

---

## Priority Order

1. **High impact (most visually broken/empty):**
   - Test 70 — indexedNamed (horrible, nothing to see)
   - Test 10 — referenceDemo (mostly empty)
   - Test 15 — stateAnimConstructDemo (mostly empty)

2. **Medium impact (functional but could be much better):**
   - Test 83 — slot2dIndex (needs programmatic slot update)
   - Test 81 — slotParams (needs state text and varied states)
   - Test 82 — layoutMultiChild (needs saturated colors and text)
   - Test 56 — codegenGridFunc (needs more grid types)
   - Test 32 — namedFilterParams (small, needs larger elements)
   - Test 71 — slotDemo (needs better labeling)

3. **Lower impact (mostly polish/labeling):**
   - Test 76 — comboUnconditional ("Shared Text" rename)
   - Test 75 — progressBarDemo (add bottom-half text)
   - Test 51 — codegenParticles (add more emitter types)
   - Test 46 — codegenGridPos (add more layouts)
   - Test 44 — codegenReference (potentially redundant with test 10)
