# Visual Tests TODO

## Test 71 — `slotDemo`
What is this test actually testing? The purpose is unclear. Needs a clearer demonstration of the slot concept — what slots are, how they work, what states they can be in.

## Test 76 — `comboUnconditional`
Just write the statuses as text labels instead of relying on visual cues alone. Each button state (normal/hover/pressed x enabled/disabled) should have a clear text label showing its current state name.

## Test 81 — `slotParams`
Weird colors, elements not filled properly, something seems missing. Review the color assignments for each state (empty/filled/highlight) and make sure the visual output matches expectations. Possibly missing state transitions or default values not being applied correctly.

## Test 83 — `slot2dIndex`
Fill at least one slot with content at a different (x, y) position so we can visually confirm that 2D indexing actually works. Currently all slots look identical, which doesn't prove anything. The test should programmatically set content in a specific slot (e.g., slot[2,1]) to make it visually distinct from the defaults.
